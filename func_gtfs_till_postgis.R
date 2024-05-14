uppkoppling_db <- function(
    service_name = "rd_geodata",
    db_host = "WFALMITVS526.ltdalarna.se",
    db_port = 5432,
    db_name = "praktik",                    # Ändra till "geodata" sen
    db_options = "-c search_path=public"
) {
  
  tryCatch({
    # Etablera anslutningen
    con <- dbConnect(          
      RPostgres::Postgres(),
      bigint = "integer",  
      user = key_list(service = service_name)$username,
      password = key_get(service_name, key_list(service = service_name)$username),
      host = db_host,
      port = db_port,
      dbname = db_name,
      options=db_options)
    
    # Returnerar anslutningen om den lyckas
    return(con)
  }, error = function(e) {
    # Skriver ut felmeddelandet och returnerar NULL
    print(paste("Ett fel inträffade vid anslutning till databasen:", e$message))
    return(NULL)
  })
  
}