# 1. Round time (floor) in 5 Minutes intervals to rasterize timestamps
# 2. Delete measurements that were taken less than 5 minutes after another
# 3. Write measurements into an empty grid of 5 minute-intervals that covers the whole period of time

require(tidyverse)
require(lubridate)
require(feather)

#load("../data/raster-0-orig.R")
raster <- read_csv("../data/raster-0-orig.csv")

# 1. & 2. Floor time and delete duplicates

## check duplicate datetimes
raster %>% 
  select(createdAt) %>% 
  mutate(createdAt.floor = floor_date(createdAt, "5 minutes")) %>% 
  group_by(createdAt.floor) %>% 
  filter(n() > 1) %>% 
  #count(createdAt.floor) %>% 
  View()
# found 25 datetime duplicates => take first entry

floor.and.filter.datetime.duplicate <- function(d) { 
  d %>%
    mutate(createdAt = floor_date(createdAt, "5 minutes")) %>% 
    group_by(createdAt) %>% 
    filter(row_number() == 1)
}
raster <- floor.and.filter.datetime.duplicate(raster)
rm(floor.and.filter.datetime.duplicate)

# 3. Write measurements into empty grid

## create complete (empty) grid
first.datetime <- min(raster$createdAt)
last.datetime <- max(raster$createdAt)

grid <- data.frame(createdAt = seq(first.datetime, last.datetime, "5 min"))
rm(first.datetime, last.datetime)

raster <- left_join(grid, raster) %>% 
  mutate_at(-1, ~replace(., is.na(.), "NODATA"))

save(raster, file = "../data/raster-1-prepared.R")
