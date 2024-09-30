#--------- Läs in funktionerna ------------
source("func_gtfs_till_postgis_ny.R")

# Lägg hela processen inom ett tryCatch()-block för att avbryta om något gått fel under en del av processen
# Logga sedan antingen att körningen har genomförts eller att den avbrutits och isf var
tryCatch({
  # Skapa uppkoppling
  con <- uppkoppling_db()
  # print("Uppkopplingen klar.")
  # Ladda hem, packa upp och lägg alla tabeller från GTFS i dataframes som returneras i en lista gtfs_data
  gtfs_data <- ladda_hem_gtfs()
  # print("GTFS-data inläst.")
  
  # Påbörja transaktion
  dbBegin(con)
  # print("Transaktion påbörjad.")
  
  # Skapa tabeller om det inte redan är gjort
  skapa_tabeller(con)
  # print("Tabeller skapade.")
  
  # Kontrollera ifall en ny version behöver skapas och gammal data versionshanteras
  versionshantering(con, gtfs_data)
  
  # Kontroller a ifall gamla versioner kan raderas - den andra parametern anger antalet år innan äldre versioner skall raderas
  radera_gamla_versioner(con, 3)
  
  # Ladda upp till databasen
  ladda_upp_till_databas(con, gtfs_data)
  
  # Skapa och fyll tabellen linjeklassificering
  # OBS!!!! - Om klassificeringen ändras/nya linjer tillkommer se till att ändra i funktionen
  skapa_tabell_linjeklassificering(con)
  
  # Skapa vyer
  skapa_vyer_hallplats(con)
  skapa_vyer_linjer(con)
  
  # Skapandet/uppadeteringen av historiska vyer sker i funktionen versionshantering
  
  # Om allt gått bra, committa
  dbCommit(con)
  # print("Commit klar.")
  
  log_file <- paste0(getwd(), "/logg/logg.txt")
  
  # Logga framgång
  logga_event("Data uppladdad och versioner hanterade framgångsrikt.", log_file)
  print("Allt gick bra, loggfilen uppdaterad")
  
}, error = function(e) {
  # Ångra alla ändringar om något går fel
  # print(paste("Felmeddelande: ", e$message))
  
  dbRollback(con)
  # Logga felmeddelande
  logga_event(paste("Körningen har avbrutits: ", e$message), log_file)
  print(paste("Något blev fel, loggfilen uppdaterad:", e$message))
}, finally = {
  # Avsluta uppkopplingen
  dbDisconnect(con)
  #print("Uppkopplingen avslutad.")
})
