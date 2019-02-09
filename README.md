# Playing with Kaggles' Santander Production Recommendation Dataset

This page is where I will document the progress of playing with the aforementioned dataset.  This competition ran back in 2016 and provided Kagglers with approximately 1m customer records, with monthly snapshots going back over 18 months.
The data and information can be found [here](https://www.kaggle.com/c/santander-product-recommendation)

# Data
The train data is about 2.3GB in size.  You can see how I read it in in the script /DataPrep/dataprep.R.
On a machine with 2 cores & 8GB RAM, this took 15 minutes to load.  To enable you to follow along, I created a couple of monthly snapshots of data, and saved these.  These are in the /data folder.

Essentially what I am doing here is taking a month (March 2016) as my training base, and then adding in what changed in the following month.  This is then my basic training set.

Whilst I'm here, I identify exactly what has been changed from one to the other (ie which customers have changed their products from March to April) to see if there is a majority to focus on, which might help to identify next steps for feature selection.  

The below is a which shows how many customers made a change from March to Aril 2016.

<img src="Images/SummaryChangedStatus.png" alt="hi" class="inline"/>
/dataprep/dataprep_test.R is a replication of this for the test data set.  Again all data is provided in the /data folder.

# Free Lunch...
There is no such thing as a free lunch, but sometimes it's worth seeing how much information is already provided in the data set.  Therefore my Free lunch scripts (under /modelling), run a number a Machine Learning algorithms on the data before I do any Feature Engineering.

I used an AWS 2xLarge machine to run these models.  Initially, I attempted to run models on the ~1m customer records but this continually ran out of memory, so I changed tack and created numerous downsized data sets.

 1. 100k observations: Randomly selected with the same proportions to the original data (95% no change, 5% change)
 2. 100k observations: Using the ROSE package, created an equally balanced (50 50 split) of the data
 3. 100k observations: Using the ROSE package, created an less balanced (75: 25 No Change: Change split) of the data
 4. 100k observations: Randomly selected overweighting which had a 50 50 weighting


For each of these 4 models, I ran a classification random forest with 200 trees, and nodesize of at least 20 to avoid overfitting. 

The ideal scenario would be to run the model on the whole dataset.  However, this proved too computationally heavy, therefore option 1 is the most representative option, as it maintains the structure of the data.

 *- Results here were very high accuracy, but when looking at the OOB results and the confusion matrix, everything was predicted to "Not Change."  This was an expected result, and leads to looking at rebalancing the test set.*
 
The ROSE package rebalances the dataset, and creates synthetic data which represents the entire data set.  This is a package I have successfully used previously to enhance results.  The downside to rebalancing the training set is that one is adjusting the prior probabilities going into the model, and this needs to be considered when using the probabilities to find an optimal cutoff.

In the second round, I used ROSE to create a balanced data set (50 50 No Changed vs Change), and run the results.  
 *- Results here were completely opposite to the previous model, and classified almost everything as changed*

Given the complete opposites of the spectrum from the previous 2 results, I attempted a halfway house, where the dataset was a ROSE rebalanced dataset of 75% non changed, and 25% changed.

 *- Sadly results here were almost exactly the same here as they were for the other ROSE attempt, with every customer being predicted to change.*

ROSE apparently doesn't work here and so I attempted a final rebalanced dataset, but defining this manually.

 - The results here were more dispersed, however on closer inspection, it became clear that the model was guessing as in each class the prediction was split 80:20.

These results are not particularly surprising.  Taking data and throwing at a model was unlikely to give a good result.
# Next Steps
Given this is sparse data, I will attempt xgboost as this is very good with sparse data and weak classifiers.  I hope this will also indicate which features to look more closely at.
I will build a shiny app to visualise the data and identify what features to build.  Thus far, I have only used the current months' data to predict if the customer will add a new product.  I will look to add more months to the data set and see what differentiators there are.

***# To be continued...***
