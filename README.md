# GTFS to PostGIS

## Overview
This project automates the download, processing, and storage of General Transit Feed Specification (GTFS) data into a PostgreSQL/PostGIS database. It enables users to visualize and analyze transit data in GIS applications, providing an automated pipeline for maintaining up-to-date public transportation datasets.

The project includes:
- Automatic GTFS data download via API
- Storage in PostgreSQL with PostGIS support
- Version control for historical data
- Materialized views for performance optimization
- Robust error handling and logging

## Requirements
### Software:
- R (>= 4.0.0)
- PostgreSQL (>= 12)
- PostGIS extension

### R Packages:
Ensure the following R packages are installed:
```r
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, sf, httr, keyring, RPostgres, glue, dplyr)
```

## Installation & Setup
1. Clone this repository:
   ```bash
   git clone https://github.com/mikael-leonidsson/gtfs_till_postgis.git
   cd gtfs_till_postgis
   ```

2. Set up PostgreSQL database:
   ```sql
   CREATE DATABASE gtfs_data;
   CREATE EXTENSION postgis;
   ```

3. Update database connection settings in `func_gtfs_till_postgis.R`:
   ```r
   db_host = "your_database_host"
   db_port = 5432
   db_name = "gtfs_data"
   keyring_service_name = "your_keyring_service"
   ```
   Ensure credentials are stored securely using the `keyring` package.

## Usage
1. Run the main script in R:
   ```r
   source("gtfs_till_postgis.R")
   ```

2. The script performs the following steps:
   - Downloads GTFS data from the API
   - Connects to the PostgreSQL database
   - Creates necessary tables and schemas
   - Manages versioning of GTFS datasets
   - Loads GTFS data into the database
   - Creates materialized views for GIS analysis

3. The database now contains up-to-date GTFS transit data, accessible via SQL queries or GIS software (e.g., QGIS, ArcGIS).

## Database Structure
### Schemas:
- **gtfs**: Contains the latest GTFS dataset
- **gtfs_historisk**: Stores historical versions of GTFS data

### Key Tables:
- `gtfs.routes` - Stores route details
- `gtfs.trips` - Contains trip information
- `gtfs.stop_times` - Defines stop sequences
- `gtfs.shapes_line` - Stores route geometries
- `gtfs.vy_hallplats_avgangar` - Materialized view summarizing departures per stop
- `gtfs.vy_linjer_avgangar_alla` - Materialized view summarizing route geometries

## Versioning System
A new GTFS version is created when:
- The latest GTFS file contains an updated service period.
- Old data is archived in `gtfs_historisk`.
- Versions older than 3 years are deleted (configurable).

## Error Handling
The script uses `tryCatch` for robust error handling:
- Errors trigger database rollback to prevent corruption.
- Issues are logged for debugging.
- Logs can be stored in a dedicated file for monitoring.

## Future Improvements
- Email notifications for failed updates.
- Additional filtering and analysis capabilities in GIS.
- Support for real-time GTFS feeds.

For questions or contributions, feel free to open an issue or submit a pull request!

---
Developed by Mikael Leonidsson
Avesta, June 2024

