require(tidyverse)
require(jsonlite)
require(lubridate)

load("../data/raster-2-cleaned.R")
load("../data/dat-status-per-day-2-cleaned.R")
load("../data/facilities.R")

# Map data

## daily inactive moments per elevator in October 2019
inactivePerDay <- dat.status.per.day %>% 
  filter(date(createdAt) >= "2019-10-01", date(createdAt) <= "2019-10-31") %>% 
  select(createdAt, equipmentnumber, INACTIVE) %>% 
  group_by(equipmentnumber) %>%
  summarise(inactivePerDay = list(INACTIVE))

## inactive moments on "2019-11-12" per elevator: 0 = active, 1 = inactive
inactivePerMoment <-raster %>% 
  filter(date(createdAt) == "2019-11-12") %>% 
  gather("equipmentnumber", "state", -createdAt) %>%
  mutate(equipmentnumber = as.numeric(equipmentnumber)) %>%
  group_by(equipmentnumber, hour(createdAt)) %>% 
  count(state) %>%
  mutate(inactivePerMoment = ("INACTIVE" %in% state) * 1) %>% 
  distinct(equipmentnumber, inactivePerMoment) %>% 
  group_by(equipmentnumber) %>%
  mutate(previous.state = c(1, lag(inactivePerMoment)[-1]),
         inactivePerMoment = ifelse(inactivePerMoment == 1 & previous.state == 0,
                                    2,
                                    inactivePerMoment)) %>% 
  summarise(inactivePerMoment = list(inactivePerMoment)) 
  

## state at moment "2019-11-12 06:00:00": 0 = active, 1 = inactive
inactiveAtMoment <- raster %>% 
  filter(createdAt == "2019-11-12 06:00:00") %>% 
  gather("equipmentnumber", "state", -createdAt) %>%
  mutate(equipmentnumber = as.numeric(equipmentnumber)) %>% 
  mutate(state = (state %in% c("ACTIVE", "UNKNOWN")) * 0 + (state == "INACTIVE") * 1) %>%
  select(-createdAt) %>% 
  rename(inactiveAtMoment = state)

## inactive sum in days per elevator
inactiveAtYear <- dat.status.per.day %>%
  group_by(equipmentnumber) %>% 
  summarise(inactiveAtYear = floor(sum(INACTIVE) / 192))

## inactive at "2019-06-26"
inactiveAtDay <- dat.status.per.day %>% 
  filter(createdAt == "2019-06-26") %>% 
  select(equipmentnumber, inactiveAtDay = INACTIVE)

## Verfügbarkeit
available <- dat.status.per.day %>% 
  group_by(equipmentnumber) %>% 
  summarise(ACTIVE = sum(ACTIVE), INACTIVE = sum(INACTIVE), UNKNOWN = sum(UNKNOWN)) %>% 
  rowwise() %>% 
  mutate(available = (1 - (INACTIVE / sum(ACTIVE, INACTIVE, UNKNOWN))) %>% round(3)) %>%
  select(equipmentnumber, available)

## 365 days - Calendar

calendar <- dat.status.per.day %>% 
  select(createdAt, equipmentnumber, INACTIVE) %>% 
  group_by(equipmentnumber) %>%
  summarise(calendar = list(INACTIVE))

map.data <- inactivePerMoment %>% 
  # left_join(inactivePerDay) %>% 
  left_join(inactiveAtMoment) %>% 
  left_join(inactiveAtYear) %>% 
  left_join(inactiveAtDay) %>% 
  left_join(available) %>% 
  # left_join(calendar) %>% 
  left_join(facilities %>% 
              # if description is empty: take alternative description
              mutate(description = ifelse(is.na(description),
                                          bezeichnung.aufzug.ort,
                                          description)) %>% 
              # if alternative description is also empty: numerise
              group_by(bezeichnung.bhf) %>% 
              mutate(description = ifelse(is.na(description),
                                          paste0(bezeichnung.bhf, " ", row_number()),
                                          description)) %>% 
              select(equipmentnumber,
                     station = bezeichnung.bhf,
                     description))

map.data %>%
  toJSON(pretty = F) %>%
  write(file = "../data/map-data.json")

calendar %>%
  toJSON(pretty = F) %>%
  write(file = "../data/calendar-data.json")
