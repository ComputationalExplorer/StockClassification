setwd('C:/Users/Admin/Documents/ComputationalExplorer/StockClassification')

# Get your API key from quandl.com
quandl_api = "PCFbavNJ5piNhxkmaNVN" # MYAPIKEY"


# Target nb of clusters 
nb_clusters <- 11

# Dates for the data series
data_start_date <- '2015-03-27' 
data_end_date <- '2018-03-27' 

nb_tickers <- 250 #100
nb_dates <- 500

# File names
price_data_file_name <- "./data/raw_ticker_data250.csv"
sector_data_file_name  <- "./data/SP500 GICS Sectors - Wikipedia 20180806.csv"
stock_data_file_name <- "./data/stock_data.csv"
figures_dir <- "./figures/"
