library(dplyr)
library(ggplot2)
library(gridExtra)

##################
# Learning
##################

# Table reordering function : Try to put largest elements on the diagonal, recursively
reordered_table <- function(target_table, target_index) {
	if (target_index == nb_clusters) {
		# Nothing left to do!
		return(target_table)
	}  else { 
		idx_rng <- target_index:nb_clusters
		sub_table <- target_table[idx_rng, idx_rng]
		max_info <- which(sub_table == max(sub_table), arr.ind = TRUE)
		
		max_row_no <- max_info[1, 1] + target_index - 1
		max_col_no <- max_info[1, 2] + target_index - 1
		
		row_ind <- 1:nb_clusters
		row_ind[target_index] <- max_row_no
		row_ind[max_row_no] <- target_index

		col_ind <- 1:nb_clusters
		col_ind[target_index] <- max_col_no
		col_ind[max_col_no] <- target_index	
		
		new_table <- target_table[row_ind, col_ind]
		return(reordered_table(new_table, target_index + 1))
	}
}
#######################

stock_data <- read.csv(file = stock_data_file_name) #, row.names=FALSE)

# GICS Sector data
raw_ticker_data = read.csv(price_data_file_name, header=TRUE)
raw_sector_data = read.csv(sector_data_file_name, header=TRUE, sep=";")

ticker_sector_data <- raw_sector_data[c("Ticker.symbol", "GICS.Sector")]
colnames(ticker_sector_data) <- c("ticker", "GICS_sector")

# Get all tickers and redefine 'ticker' factor levels
combined_tickers <- sort(union(levels(raw_ticker_data$ticker), levels(ticker_sector_data$ticker)))
ticker_sector_data <- mutate(ticker_sector_data, ticker=factor(ticker, levels=combined_tickers))
	  
# Get GICS sectors vector
stock_data_w_sectors <- left_join(stock_data, ticker_sector_data, by = "ticker")
stock_data.GICS_sector <- stock_data_w_sectors$GICS_sector


# Clustering Algos ##############################################

# Scale the stock_data 
data.scaled <- scale(stock_data[,-1])

#1 : Hierarchical clustering ##################################

# Calculate the (Euclidean) distances: data.dist
data.dist <- dist(data.scaled)

# Create a hierarchical clustering model: stock_data.hclust
stock_data.hclust<- hclust(data.dist, method = 'complete')

# Dendogram representation
# dend <- as.dendrogram(stock_data.hclust)
# plot(dend)

# Cut tree so that it has 10 clusters: stock_data.hclust.clusters
stock_data.hclust.clusters <- cutree(stock_data.hclust, k = nb_clusters)

#2: k-means ##############################################
kmeans_tot_ss <- function(input_data, k) {
  km <- kmeans(input_data, centers = k, nstart = 100)
  v <- km$tot.withinss
  return (v)
}

# Note : Optimal number of clusters not obvious (no elbow)..
km.tot.ss = c()
for (k in 1:15) {
	km.tot.ss[k] = kmeans_tot_ss(data.scaled, k)
}

png(paste0(figures_dir, 'kmeans_tot_ss.png'))
plot(km.tot.ss)
dev.off()

# Create the k-means model used for comparisons
stock_data.km <- kmeans(data.scaled, centers = nb_clusters, nstart = 100)

# Comparisons #################################################

# Compare k-means to hierarchical clustering
png(paste0(figures_dir, 'comp_table_km_hclust.png'))
comp_table <- table(stock_data.km$cluster, stock_data.hclust.clusters) 
reord_comp_table <- reordered_table(comp_table, 1) %>% 
  addmargins(FUN = list(Total = sum), quiet = TRUE) %>% 
  grid.table
dev.off()


# Compare to GICS --------
# hclust vs GICS
png(paste0(figures_dir, 'comp_table_hclust_gics.png'))
comp_table_hclust_gics <- table(stock_data.GICS_sector, stock_data.hclust.clusters) 
reord_comp_table_hclust_gics <- reordered_table(comp_table_hclust_gics, 1) %>% 
  addmargins(FUN = list(Total = sum), quiet = TRUE) %>% 
  grid.table
dev.off()
# km vs GICS
png(paste0(figures_dir, 'comp_table_km_gics.png'))
comp_table_km_gics <- table(stock_data.GICS_sector, stock_data.km$cluster)
reord_comp_table_km_gics <- reordered_table(comp_table_km_gics, 1)   %>% 
  addmargins(FUN = list(Total = sum), quiet = TRUE) %>% 
  grid.table
dev.off()

# PCA ********
stock_data.pr <- prcomp(stock_data[,-1], scale = TRUE)
# stock_data.pr$rotation 
# summary(stock_data.pr)


# Plot the projection of the data on the first 2 PCA components,
# representing the different categories by different colors 
results <- data.frame( data=stock_data.pr$x[,1:3]) # , stock_data.km$cluster)

# par(mfrow=c(1,2)) 

png(paste0(figures_dir, 'pca12_km.png'))
qplot(x=data.PC1, y=data.PC2, data=results, colour=factor(stock_data.km$cluster)) #+ theme(legend.position="none")
dev.off()

png(paste0(figures_dir, 'pca12_hclust.png'))
qplot(x=data.PC1, y=data.PC2, data=results, colour=factor(stock_data.hclust.clusters)) #+ theme(legend.position="none")
dev.off()

png(paste0(figures_dir, 'pca12_gics.png'))
qplot(x=data.PC1, y=data.PC2, data=results, colour=factor(stock_data.GICS_sector)) #+ theme(legend.position="none")
dev.off()
#grid.arrange(p1, p2, nrow = 1)

