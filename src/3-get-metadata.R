library(lubridate)
library(rpostgis)
library(RPostgreSQL)
library(tidyverse)

# load("../data/facilities-0-orig.R")
load("../data/dat-status-per-day-2-cleaned.R")
facilities <- read_csv("../data/facilities-0-orig.csv")

s_bahn_stations <- read_delim("../data/s-bahn-stations.csv", ";", escape_double = FALSE, trim_ws = TRUE) %>% 
  filter(!`S-Bahnstationsname` == "Frankfurt (Main) Hauptbahnhof tief")

# elevators overview from DB
db.elevators <- read_delim("../data/Open Data/DBSuS-Uebersicht_Aufzuege-Stand2018-11_V2.csv",
                           ";",
                           col_types = cols(`Techn. Platz (Bhf)` = col_integer()),
                           escape_double = FALSE,
                           locale = locale(encoding = "latin1"),
                           trim_ws = TRUE) %>%
  # fill empty (NA) cells
  mutate_at(c("Region (Bhf)", "Techn. Platz (Bhf)", "Bezeichnung (Bhf)"),
            zoo::na.locf)

# elevators overview from DB
db.stations <- readr::read_delim("../data/Open Data/DBSuS-Uebersicht_Bahnhoefe-Stand2019-03.csv",
                                 ";",
                                 escape_double = FALSE,
                                 trim_ws = TRUE)

db.stations <- db.stations %>% left_join(s_bahn_stations, by = c("Bf DS 100 Abk." = "Abkuerzung"))


# merge facilities and metadata 
facilities <- facilities %>%
  left_join(db.elevators, by = c("equipmentnumber" = "Equipment (EQ)")) %>% 
  left_join(db.stations, by = c("stationnumber" = "Bf. Nr."))

# select and rename columns
facilities <- facilities %>% 
  select(equipmentnumber,
         description,
         bezeichnung.aufzug = `Bezeichnung (EQ)`,
         stationnumber,
         bezeichnung.bhf = `Bezeichnung (Bhf)`,
         `S-Bahnnetz`,
         station = Station,
         kategorie = `Kat. Vst`,
         createdAt,
         lng = x,
         lat = y,
         region = `Region (Bhf)`,
         bundesland = Bundesland,
         bezeichnung.aufzug.ort = `Bezeichn. TP (EQ)`,
         plz = `Postleitzahl (EQ)`,
         ort = `Ort (Bhf)`,
         standort = `Standort EQ`,
         hersteller = `Hersteller (EQ)`,
         traeger = Aufgabenträger,
         baujahr = `Baujahr (EQ)`,
         antriebsart = ANTRIEBSART,
         DS100 = `Bf DS 100 Abk.`)

facilities <- facilities %>% filter(equipmentnumber %in% unique(dat.status.per.day$equipmentnumber))

save(facilities, file = "../data/facilities.R")
