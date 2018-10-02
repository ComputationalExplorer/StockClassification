# StockClassification

# Objectives
Apply unsupervised learning algorithms to look for 'natural' stock classifications when considering various return statistics
Compare the resulting classifications to the standard GICS sector classification

# Methodology

We consider the following data:

i) Stock price series, using Quandl (www.quandl.com) as a source, for 
*   500 dates (about 2 years of business days) and 
*   250 stocks, chosen as those stocks with the highest value traded among all the available stocks.

ii) GICS sector classification

iii) 4 Economic data series : oil prices (WTI), S&P 500 Futures (E-mini), 10 year bond yield (US), Effective Fed funds rate 

To classify the stocks, we apply 2 clustering algorithms :
1) k-means
2) Hierarchical clustering (agglomerative, using the 'complete' method)

The distances used in the algorithms are based on the values of 13 variables :
* 5 return distribution statistics (mean, standard deviation, Sharpe ratio, skewness and kurtosis), 
* correlations and betas with the 4 econonomic data series 
These values are all scaled (centered around the mean and divided by one standard deviation) before being used in the clustering algorithms.

# Results

Here is a table

## K-means versus GICS
![alt text](https://github.com/ComputationalExplorer/StockClassification/blob/master/figures/comp_table_km_gics.png "k-means vs GICS")
Note : the labels for the k-means clusters and the GICS classification have been ordered to try to put the highest values on the diagonal, in order to improve readability.

## Hierarchical clustering versus GICS
![alt text](https://github.com/ComputationalExplorer/StockClassification/blob/master/figures/comp_table_hclust_gics.png "h-clustering vs GICS")


An often used method to determine an "optimal" number of clusters is to look at a plot of the total sum of squares, per number of centroids used and look for an "elbow" shape. 
![alt text](https://github.com/ComputationalExplorer/StockClassification/blob/master/figures/kmeans_tot_ss.png "Total sum of squares for k-means")


## Projection on the first 2 PCA components
Finally, we extract the principal components using PCA, and then show the 3 classifications (k-means, hclust and GICS) by the color of the points viewed as projections on the first and second principal components. These components do not necessarily have a simple financial interpretation, but they are useful here to represent the 13 dimensional data points in 2 dimensions.

![alt text](https://github.com/ComputationalExplorer/StockClassification/blob/master/figures/pca12_gics.png "k-means vs GICS")
![alt text](https://github.com/ComputationalExplorer/StockClassification/blob/master/figures/pca12_km.png "k-means projection")
![alt text](https://github.com/ComputationalExplorer/StockClassification/blob/master/figures/pca12_hclust.png "k-means vs GICS")


# Running the code

The code files should be run in the following order: 

1) 'sc_parameters.R' : contains general parameters (such as file names) and should be launched first.

2) 'sc_preprocessing.R' : extracts the raw data from the data sources, processes it, and saves the results to file.

3) 'sc_learning.R' : using the results of the preprocessing steps as input data, the classification algorithms are applied.
