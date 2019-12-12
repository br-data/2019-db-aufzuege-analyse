# Some elevators changed their equipmentnumber during our meassurement period. 
# We matched these eqs manually.
# 1. Match old and new numbers and merges data in the old eq
# 2. Filters days with more than 50% UNKNOWN or NODATA
# 3. Filters days (keeps last 365) and time (6-22)
# 4. Filter elevators that didn't send for more than 14 of 365 days (6:00 - 22:00)

require(tidyverse)
require(lubridate)

load("../output/raster-1-prepared.RData")

# 1. match changing equipmentnumbers
elevator_duplicates_manual_match <- read_delim("../data/elevator_duplicates_manual_match.csv", 
                                               ";", escape_double = FALSE, trim_ws = TRUE)

match.equipmentnumbers<- function(d, eq.match.frame) {
  
  # we have metadata for all of the old numbers in csv from db open data
  # however some of the new numbers are also in csv => same elevator twice in csv 
  # in that case we keep the old number
  
  if(!eq.match.frame$alt %in% names(d) | !eq.match.frame$neu %in% names(d)) return(d)
  
  old.eq.data <- d[, as.character(eq.match.frame$alt)]
  new.eq.data <- d[, as.character(eq.match.frame$neu)]
  
  last.old.index <- which(!old.eq.data == "NODATA") %>% tail(1)
  first.new.index <- which(!new.eq.data == "NODATA")[1]
  
  if(last.old.index < first.new.index) {
    merged.eq <- c(old.eq.data[1:(first.new.index - 1)], new.eq.data[first.new.index: length(new.eq.data)])
    
    d[, as.character(eq.match.frame$alt)] <- merged.eq
    d[, as.character(eq.match.frame$neu)] <- NULL    
  }
  return(d)
}

for (i in 1:nrow(elevator_duplicates_manual_match)) {
  raster <- match.equipmentnumbers(raster, elevator_duplicates_manual_match[i,])
}

# 2. Filter days with less than 50% data

count.status.per.day <- function(d) {
  d %>% 
    gather("equipmentnumber", "state", - createdAt) %>%
    mutate(createdAt = date(createdAt)) %>%
    count(createdAt, equipmentnumber, state) %>% 
    spread(state, n, fill = 0) %>% 
    mutate(equipmentnumber = as.numeric(equipmentnumber))
}
dat.status.per.day <- count.status.per.day(raster)

save(dat.status.per.day, file = "../data/dat-status-per-day-1-prepared.RData")
load("../data/dat-status-per-day-1-prepared.RData")

dat.status.per.day <- dat.status.per.day %>%
  rowwise() %>% 
  mutate(postive.data = sum(ACTIVE, INACTIVE),
         negative.data = sum(UNKNOWN, NODATA)) %>% 
  ungroup()

## filter days where the majority (2000) of elevators has less than 50% data.

nodata.days <- dat.status.per.day %>%
  group_by(createdAt) %>% 
  count(less50 = negative.data > postive.data) %>% # View()
  filter(less50 == T, n > 1999) %>%
  pull(createdAt)

raster <- raster %>% filter(!date(createdAt) %in% nodata.days)

# 3. filter date (last 365 days) and time (6-22)

filter.daytime = function(d, min.hour = 6, max.hour = 22) {
  d %>% filter(hour(createdAt) >= 6,
               hour(createdAt) < 22)
}

raster <- filter.daytime(raster)

filter.last.365.days <- function(d) {
  # remove last day, since it is usually not complete
  last.365.days <- unique(date(raster$createdAt)) %>% sort() %>% tail(366) %>% head(-1)
  d %>% filter(date(createdAt) %in% last.365.days)
}

raster <- filter.last.365.days(raster)

dat.status.per.day <- count.status.per.day(raster)

# 4. Filter elevators that didn't send for more than 5% of 365 days (6:00 - 22:00)
units.per.day <- 16 * 60 / 5

# remove elevators that didn't send data for more than 14 days
used.elevators <- dat.status.per.day %>%
  filter(!NODATA == units.per.day) %>%
  group_by(equipmentnumber) %>%
  summarise(n = n_distinct(createdAt)) %>%
  filter(n > 365 - 14) %>%
  pull(equipmentnumber)


raster <- raster[, c("createdAt", as.character(used.elevators))]

dat.status.per.day <- dat.status.per.day %>% filter(equipmentnumber %in% used.elevators)

# save files

save(raster, file = "../output/raster-2-cleaned.RData")
save(dat.status.per.day, file = "../output/dat-status-per-day-2-cleaned.RData")
