library(plyr)
library(dplyr)
library(reshape2)
library(e1071) 

# Quandl package must be installed
library(Quandl)

# Add the key to the Quandl keychain
Quandl.api_key(quandl_api)

#####################################
# Function definitions ##############
#####################################

load_quandl_ticker_data <- function(nb_tickers, nb_dates) {
  # Get list of dates (from ticker "A" - arbitrary)
  available_dates <- Quandl.datatable('WIKI/PRICES', ticker = 'A', qopts.columns= "Date")
  
  # Get latest available tickers (at latest dates)
  last_date <- head(available_dates$date, 1)
  latest_available_tickers <- Quandl.datatable('WIKI/PRICES', date = last_date)
  
  # Make a list of most traded tickers
  latest_available_tickers$traded_value = latest_available_tickers$volume * latest_available_tickers$close
  most_traded_tickers <- latest_available_tickers[order(latest_available_tickers$traded_value),]
  most_traded_tickers <- tail(most_traded_tickers$ticker, nb_tickers)
  
  # Get last trading dates for these tickers
  expt_dates <- head(available_dates$date, nb_dates)
  load_quandl_ticker_data <- Quandl.datatable('WIKI/PRICES', date = paste(expt_dates, collapse = ','), ticker = paste(most_traded_tickers, collapse = ','), paginate=TRUE)
}

series_at_common_dates <- function(series1, series2) {
	# Assume series are Data Frames with 2 columns : Dates and Values
		series_at_common_dates <- left_join(series1, series2, by = "date")
}

get_ts_diff <- function(ts1, ts2) {
	# Merges 2 time series, keeping only the common dates.
	# Then computes the diffs
	
	ts_common <- series_at_common_dates(ts1, ts2 )
	ts_common <- ts_common[complete.cases(ts_common),]

	get_ts_diff <- lapply(ts_common, diff)
}

# Compute Beta
factor_beta <- function(target_series, index_series) {
	ts_diff <- get_ts_diff(target_series, index_series)
	correlation <- cov(ts_diff[[2]], ts_diff[[3]]) / var(ts_diff[[3]])
}

# Compute Correlation of differences between 2 time series
diff_correlation_ts <- function(ts1, ts2) {
	ts_diff <- get_ts_diff(ts1, ts2)
	correlation <- cor(ts_diff[[2]], ts_diff[[3]])
}

ts_ticker <- function(ticker_label, data_source) {
  # Using "adj_close" to take splits and dividends into account
	ts_ticker <- data_source  %>% filter(ticker == ticker_label) %>% ungroup() %>% select(date, adj_close)
}

# Compute Correlation of differences between 2 time series
diff_correlation_ticker <- function(ticker1, ticker2, data_source) {
	ts1 <- ts_ticker(ticker1, data_source)
	ts2 <- ts_ticker(ticker2, data_source)	
	correlation <- diff_correlation_ts(ts1, ts2)
}

correl_ticker_series <- function(ticker, ts_data) {
	correl_ticker_series <- diff_correlation_ts(ts_data, ts_ticker(ticker, complete_data))
}

beta_ticker_series <- function(ticker, ts_data) {
	beta_ticker_series <- factor_beta(ts_data, ts_ticker(ticker, complete_data))
}

#####################################
# Main data pre-precessing ##########
#####################################

if(!file.exists(price_data_file_name)){
  raw_ticker_data <- load_quandl_ticker_data(nb_tickers, nb_dates)
  write.csv(raw_ticker_data, file=price_data_file_name, row.names=FALSE)
} else {
  raw_ticker_data = read.csv(price_data_file_name, header=TRUE)
}

# Remove symbol "AFL" : 2:1 split not correctly treated at 2018-03-16 in Quandl data
raw_ticker_data<-raw_ticker_data[raw_ticker_data$ticker!='AFL',]

# GICS Sector data
raw_sector_data = read.csv(sector_data_file_name, header=TRUE, sep=";")
# Other source of sector data
# https://datahub.io/core/s-and-p-500-companies#resource-constituents

# Data for exposure to market factors
# WTI oil prices :
wti_data <- Quandl('CHRIS/CME_CL1', start_date=data_start_date, end_date=data_end_date)
#CHRIS/CME_ES1 : E-mini S&P 500 Futures, Continuous Contract #1 (ES1) (Front Month)
es1_data <- Quandl('CHRIS/CME_ES1', start_date=data_start_date, end_date=data_end_date)
#FRED/THREEFY10 : Fitted Yield on a 10 Year Zero Coupon Bond
yld10y_data <- Quandl('FRED/THREEFY10', start_date=data_start_date, end_date=data_end_date)
#FRED/DFF : Effective Federal Funds Rate
effr_data <- Quandl('FRED/DFF', start_date=data_start_date, end_date=data_end_date)

ticker_sector_data <- raw_sector_data[c("Ticker.symbol", "GICS.Sector")]
colnames(ticker_sector_data) <- c("ticker", "GICS_sector")

# Get all tickers and redefine 'ticker' factor levels
combined_tickers <- sort(union(levels(raw_ticker_data$ticker), levels(ticker_sector_data$ticker)))
ticker_sector_data <- mutate(ticker_sector_data, ticker=factor(ticker, levels=combined_tickers))
raw_ticker_data <- mutate(raw_ticker_data, ticker=factor(ticker, levels=combined_tickers))

# Compute 1d returns
raw_ticker_data <- raw_ticker_data %>% 
  group_by(ticker) %>% 
  mutate(rtn_1d = (adj_close - lag(adj_close))/lag(adj_close))
raw_ticker_data$date <- as.Date(format(raw_ticker_data$date))

complete_data <- raw_ticker_data[complete.cases(raw_ticker_data[,c("ticker","rtn_1d")]),] %>%
               left_join(ticker_sector_data, by = "ticker")

ticker_stats <- complete_data %>% 
  group_by(ticker) %>% 
  summarise(avg = mean(rtn_1d), sdev = sd(rtn_1d)) %>%
  mutate(sharpe =  avg / sdev)

complete_data <- left_join(complete_data, ticker_stats, by = "ticker")  %>% 
                mutate(rtn_1d_norm = (rtn_1d - avg / sdev))

# Basic data frame
stock_data <- complete_data %>%
  ddply(c("ticker"), summarise,
       skew = moment(rtn_1d_norm, order = 3, center = TRUE),
       kurt = moment(rtn_1d_norm, order = 4, center = TRUE)
       )	  %>%
  left_join(ticker_stats, by = "ticker")

	  
# Get GICS sectors vector
stock_data_with_gics_sector <- left_join(stock_data, ticker_sector_data, by = "ticker")
stock_data.gics <- stock_data_with_gics_sector$GICS_sector

# Extract economic data as vector
ts_wti <- wti_data %>% select(Date, Settle)  %>% rename(date = Date)
ts_es1 <- es1_data %>% select(Date, Settle)  %>% rename(date = Date)
ts_yld10y <- yld10y_data %>% select(Date, Value)  %>% rename(date = Date)
ts_effr <- effr_data %>% select(Date, Value)  %>% rename(date = Date)

# Correlations with stock return series
cor_wti <- mapply(correl_ticker_series, stock_data$ticker, list(ts_wti))
cor_es1 <- mapply(correl_ticker_series, stock_data$ticker, list(ts_es1))
cor_yld10y <- mapply(correl_ticker_series, stock_data$ticker, list(ts_yld10y))
cor_effr <- mapply(correl_ticker_series, stock_data$ticker, list(ts_effr))

# Betas of stock return series
beta_wti <- mapply(beta_ticker_series, stock_data$ticker, list(ts_wti))
beta_es1 <- mapply(beta_ticker_series, stock_data$ticker, list(ts_es1))
beta_yld10y <- mapply(beta_ticker_series, stock_data$ticker, list(ts_yld10y))
beta_effr <- mapply(beta_ticker_series, stock_data$ticker, list(ts_effr))

# Data frame including market factors
stock_data_with_mkt_factors <- stock_data %>% 
  mutate(cor_wti = cor_wti,
  cor_es1 = cor_es1,
  cor_yld10y = cor_yld10y,
  cor_effr = cor_effr,
  beta_wti = beta_wti,
  beta_es1 = beta_es1,
  beta_yld10y = beta_yld10y,
  beta_effr = beta_effr
  ) 

# Data is ready! Write to CSV for later analysis
write.csv(stock_data_with_mkt_factors, file = stock_data_file_name, row.names=FALSE)
  