# StockClassification

# Objectives
-Apply unsupervised learning algorithms to look for 'natural' stock classifications when considering various return statistics
-Compare the resulting classifications to the standard GICS sector classification

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

Scree plot (x2) : for k-means and for h-clustering

Comparison of the 2 sets of clusters by a confusion matrix.
Same comparison, but with the GICS sectors (x2)

Extract the principal components using PCA, and then show the 3 classifications (k-means, hclust and GICS) by the color of the 
We consider the results on the first and second principal components 


# Running the code

The code files should be run in the following order: 

1) 'sc_parameters.R' : contains general parameters (such as file names) and should be launched first.

2) 'sc_preprocessing.R' : extracts the raw data from the data sources, processes it, and saves the results to file.

3) 'sc_learning.R' : using the results of the preprocessing steps as input data, the classification algorithms are applied.
