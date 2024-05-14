#--------- Läs in funktionerna ------------
#source("https://raw.githubusercontent.com/mikael-leonidsson/funktioner_rd/main/func_GIS.R")
source("func_gtfs_till_postgis.R")

#--------- Läs in gtfs till df ------------

# avoid scientific notation
options(scipen=999)

options(dplyr.summarise.inform = FALSE)


# libraries
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, 
               sf, 
               mapview,
               httr)


#Sökvägen till mappen för nedladdning - ändra sen till "icke" getwd()
data_input <- paste0(getwd(), "/data")

### url for GTFS
# Specify RKM. 

# ange operatör
rkm = "dt" # !!!!!! Specify RKM. Available values : sl, ul, sormland, otraf, krono, klt, gotland, blekinge, skane, halland, vt, varm, orebro, vl, dt, xt, dintur, sj

# dagens datum
datum <- str_remove_all(Sys.Date(), "-")


# ELLER datum senaste nedladdning
datum <- "20240514"

# skapa hela sökvägen
sokvag_datum <- paste0(data_input, "/trafiklab_", rkm, "_", datum)

# skapa sökvägen till den nedladddade GTFS-filen med rkm och datum
gtfs_regional_fil <- paste0(sokvag_datum, ".zip")

# skapa och hämta url:en till gtfs-feeden
url_regional <- paste0("https://opendata.samtrafiken.se/gtfs/", rkm, "/", rkm, ".zip?key=", key_get("API_trafiklab_token", "GTFS_Regional"))

GET(url_regional, write_disk(gtfs_regional_fil, overwrite=TRUE))

# Zippa upp csv-filerna och lägg i undermapp
unzip(gtfs_regional_fil, exdir = sokvag_datum)

#Läs in filerna, kolla om det inte går att göra automagiskt - glöm inte colClasses = 'character' för att undvika problem med IDn

routes = read.csv2(paste0(sokvag_datum, "/routes.txt"), 
                   sep = ",", encoding="UTF-8", stringsAsFactors=FALSE, colClasses = 'character')

stops = read.csv2(paste0(sokvag_datum, "/stops.txt"), 
                  sep = ",", encoding="UTF-8", stringsAsFactors=FALSE, colClasses = 'character')

stop_times = read.csv2(paste0(sokvag_datum, "/stop_times.txt"), 
                       sep = ",", encoding="UTF-8", stringsAsFactors=FALSE, colClasses = 'character')

trips = read.csv2(paste0(sokvag_datum, "/trips.txt"), 
                  sep = ",", encoding="UTF-8", stringsAsFactors=FALSE, colClasses = 'character')

calendar_dates = read.csv2(paste0(sokvag_datum, "/calendar_dates.txt"), 
                           sep = ",", encoding="UTF-8", stringsAsFactors=FALSE)

shapes = read.csv2(paste0(sokvag_datum, "/shapes.txt"), 
                   sep = ",", encoding="UTF-8", stringsAsFactors=FALSE, colClasses = 'character')

agency = read.csv2(paste0(sokvag_datum, "/agency.txt"), 
                   sep = ",", encoding="UTF-8", stringsAsFactors=FALSE, colClasses = 'character')

calendar = read.csv2(paste0(sokvag_datum, "/calendar.txt"), 
                     sep = ",", encoding="UTF-8", stringsAsFactors=FALSE, colClasses = 'character')

feed_info = read.csv2(paste0(sokvag_datum, "/feed_info.txt"), 
                      sep = ",", encoding="UTF-8", stringsAsFactors=FALSE, colClasses = 'character')

# TEsta att läsa in nya feeden och kolla 
feed2 <- read.csv2(paste0(sokvag_datum, "/feed_info.txt"), 
                   sep = ",", encoding="UTF-8", stringsAsFactors=FALSE, colClasses = 'character')

# TEsta att läsa in nya feeden och kolla 
stops2 <- read.csv2(paste0(sokvag_datum, "/stops.txt"), 
                    sep = ",", encoding="UTF-8", stringsAsFactors=FALSE, colClasses = 'character')

# Fixa till feed_info så den innehåller feed_file och feed_download_date
if (!"feed_file" %in% colnames(feed_info)) {
  feed_info$feed_file <- "test.zip"  # Ersätt test.zip med en sammansatt sträng med datum då feeden blev nedladdad och annan info
}

# Skapa datbaskoppling
con <- uppkoppling_db()
dbListTables(con)
#---------------- Lägg till feed_info ----------
# Starta transaktionen



dbDisconnect(con)


# Lägg till stops

sf_stops <- st_as_sf(stops, coords = c("stop_lon", "stop_lat"), crs = 4326, remove = FALSE) %>% 
  st_transform(3006) %>% 
  st_set_geometry("geom")

sf_stops <- st_as_sf(stops2, coords = c("stop_lon", "stop_lat"), crs = 4326, remove = FALSE) %>% 
  st_transform(3006) %>% 
  st_set_geometry("geom")
con <- connect_to_db()
# Skriv till databasen
st_write(obj = sf_stops, dsn = con, Id(schema = "gtfs", table = "stops"), geomtype = "POINT") # Använd overwrite med försiktighet
dbDisconnect(con)

# Hämta och visa stops
con <- connect_to_db()
test <- st_read(con, "stops", geometry_column = 'geom')
dbDisconnect(con)




#Test med func_postgis
#Kör ej
# function(inlas_sf,
#          inlas_tabellnamn,   # de tabellnamn de nya filerna ska få i postgis
#          schema_karta = "karta",
#          postgistabell_id_kol,
#          postgistabell_geo_kol,
#          postgistabell_till_crs,
#          pg_db_user = key_list(service = "rd_geodata")$username,
#          pg_db_pwd = key_get("rd_geodata", key_list(service = "rd_geodata")$username),
#          pg_db_host = "WFALMITVS526.ltdalarna.se",
#          pg_db_port = 5432,
#          pg_db_name_db = "geodata")
#   

# workaround för att den inte kan skapa geometrier, verkar vara som om postgis automatiskt inte läggs till till scheman

# OBS! Varannan gång lägger den in tabellen och varannan gång droppar den tabellen (om den redan finns)
skriv_geosf_till_postgis_skapa_spatialt_index(
  sf_stops,
  "test_stops",
  "test_routing",
  "stop_id",
  "geom",
  3006,
  key_list(service = "db_connect")$username,
  key_get("db_connect", key_list(service = "db_connect")$username),
  "WFALMITVS526.ltdalarna.se",
  5432,
  "praktik")
