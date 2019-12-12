# 0. get facilities from database
# 1. Connect to Postgres session
# 2. Read, filter and transform data into R in 3 chunks

require(DBI)
require(rpostgis)
require(tidyverse)
require(feather)

# 0. get facilities from database
con <- dbConnect(RPostgreSQL::PostgreSQL(),
                 dbname="fasta",
                 host="localhost",
                 port=5432)

facilities <- pgGetGeom(con,
                        name="facilities",
                        geom = "location",
                        gid = "equipmentnumber") %>%
  as.data.frame() %>%
  filter(type == "ELEVATOR") %>% 
  arrange(equipmentnumber)

dbDisconnect(con)

# 2. Read data
con <- dbConnect(RPostgres::Postgres(),
                 dbname = "fasta", 
                 host = "localhost",
                 port = 5432)

raster.fields <- c("createdAt", facilities$equipmentnumber)
raster <- data.frame(matrix(ncol = length(raster.fields), nrow = 0))
colnames(raster) <- raster.fields

# A chunk at a time
res <- dbSendQuery(con, "SELECT * FROM facility_statuses")
while(!dbHasCompleted(res)){
  chunk <- dbFetch(res, n = 100000000)
  raster <- bind_rows(raster,
                  chunk %>%
                    filter(equipmentnumber %in% facilities$equipmentnumber) %>% 
                    select(equipmentnumber, state, createdAt) %>% 
                    spread(equipmentnumber, state))
}
dbClearResult(res)

dbDisconnect(con)

rm(res, con)

write_feather(raster, path = "../data/raster-0-orig.feather")
save(raster, file = "../data/raster-0-orig.R")
save(facilities, file = "../data/facilities-0-orig.R")
