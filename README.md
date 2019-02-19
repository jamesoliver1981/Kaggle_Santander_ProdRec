# Playing with Kaggles' Santander Production Recommendation Dataset

This page is where I will document the progress of playing with the aforementioned dataset.  This competition ran back in 2016 and provided Kagglers with approximately customer records, with monthly snapshots going back over 18 months.  There are approximately 1million unique customers over the 18 month period, and the majority appear in each month.
The competition was actually based on if a customer were to purchase a product, what would they buy.  I will instead focus on creating a model which predicts who will buy a new product of any description.  This restricts my ability to just lift from existing Kaggle submissions.
The data and information can be found [here](https://www.kaggle.com/c/santander-product-recommendation)

# Data
The train data is about 2.3GB in size.  You can see how I read it in in the script /DataPrep/dataprep.R.
On a machine with 2 cores & 8GB RAM, this took 15 minutes to load.  To enable you to follow along, I created a couple of monthly snapshots of data, and saved these.  These are in the /data folder.

Essentially what I am doing here is taking a month (March 2016) as my training base, and then adding in what changed in the following month.  This is then my basic training set.  This then consists of 1 record per customer, with their characteristics in March 2016, and whether they changed their product combinations in April 2016.

Whilst I'm here, I identify exactly what has been changed from one month to the next (ie which products have been changed from March to April) to see if there is a majority to focus on, which might help to identify next steps for feature selection.  

The below is a which shows how many customers made a change from March to Aril 2016.

<img src="Images/SummaryChangedStatus.png" alt="hi" class="inline"/>

This is therefore a sparse dataset.  There are 900k customers, and just under 50k made a change ie 5%.  0.15% closed their accounts.  
 - This suggests a couple of approaches will need to be considered.
	 - **Rebalancing the data set:** - the dataset is approximately 95:5 in favour of no change, which might allow a model to have 95% accuracy by predicting none change.  This can be overcome by changing the proportion in the training set (not the test data set).  This is known as rebalancing.
	 - **Using a Boosting approach:**  Boosting is a type of Machine Learning algorithm which takes weak classifiers and combines them to make a stronger prediction.  This is also a typical approach with a sparse data set.

Below is a chart showing how the ~50k changes split up into how many new products were picked up.
<img src="Images/Num_Changes.png" alt="hi" class="inline"/>

It is interesting to note that about 73% of the time 1 product is added.  It would be interesting to see if there are different customer segments behind this.

/dataprep/dataprep_test.R is a replication of what has been done to the train dataset for the test data set, so that predictions can be run.  Again all data is provided in the /data folder.

# Free Lunch...
There is no such thing as a free lunch, but sometimes it's worth seeing how much information is already provided in the data set.  Therefore my Free lunch scripts (under /modelling), run a number a Machine Learning algorithms on the data before I do any Feature Engineering.

I used an AWS 2xLarge machine to run these models.  Initially, I attempted to run models on the ~1m customer records but this continually ran out of memory, so I changed tack and created numerous downsized data sets of 100k rather than 1m.

  1. 100k observations: Randomly selected with the same proportions to
        the original data (95% no change, 5% change)
 2. 100k observations: Using the    [ROSE](https://cran.r-project.org/web/packages/ROSE/ROSE.pdf)        package, created an equally balanced (50 50 split) of the data 
			 *- ROSE creates rebalances the dataset, using synthetic data.  More
        details are available in the link above.* 
 3. 100k observations: Using the ROSE package, created an less balanced (75: 25 No Change:    Change split) of the data 
 4. 100k observations: Randomly selected
    overweighting which had a 50 50 weighting


For each of these 4 models, I ran a classification random forest with 200 trees, and nodesize of at least 20 to avoid overfitting. 

The ideal scenario would be to run the model on the whole dataset.  However, this proved too computationally heavy, therefore option 1 is the most representative option, as it maintains the structure of the data.

<img src="Images/rf_basic.PNG" alt="hi" class="inline"/>

 *- Initial results here were very high accuracy, but when looking at the Out of Bag (OOB) results (generated on the train set) and the confusion matrix on the test, everything was predicted to "Not Change."  This was an expected result, and leads to looking at rebalancing the train set.*
 
The ROSE package rebalances the dataset, and creates synthetic data which represents the entire data set.  This is a package I have successfully used previously to enhance results.  The downside to rebalancing the training set is that one is adjusting the prior probabilities going into the model, and this needs to be considered when using the probabilities to find an optimal cutoff.

In the second round, I used ROSE to create a balanced data set (50 50 No Changed vs Change), and run the results.  
 *- Results here were completely opposite to the previous model, and classified almost everything as changed*

Given the complete opposites of the spectrum from the previous 2 results, I attempted a halfway house, where the dataset was a ROSE rebalanced dataset of 75% non changed, and 25% changed.

 *- Sadly results here were almost exactly the same here as they were for the other ROSE attempt, with every customer being predicted to change.*

ROSE apparently doesn't work here and so I attempted a final rebalanced dataset, but defining this manually.
<img src="Images/rf_5050.PNG" alt="hi" class="inline"/>
 - The results here were more dispersed, however on closer inspection, it became clear that the model was guessing as in each class the prediction was split 80:20.
 - Below is the variable importance plot of this last model.  Given the results, this likely doesn't contain much information.

<img src="Images/varimp_rf5050.png" alt="hi" class="inline"/>

These results are not particularly surprising.  Taking data and throwing at a model was unlikely to give a good result.
# xgboost Results post 1st Feature Engineering

Initially I started with a ~20k dataset, that was not rebalanced.  This predicted almost everything to not change as per the initial random forest model.  However xgboost provides the option to reweight the positive class.  This gave immediate gains over the best random forest model.
Below is the confusion matrix of this model.

<img src="Images/xgb2_10d_100n_1weight.PNG" alt="hi" class="inline"/>

Comparing the key statistics show the improvement.


|             | xgboost | Random Forest |  
|-------------|---------|----|
| *Sensitivity* | 20.2%     |23.9%    | 
| *Prevelance Detection*|         14%|24.6%    | 
| *Posive Predictive Value*         |  7.5%       |5.2%    |



*Sensitivity* is of those that are actually positive, how many are predicted to be positive.  Here this is slightly reduced.
*Prevelance Detection* looks at the total proportion of cases that are predicted as positive.  The real result is 3.5%.  This reduction is therefore a significant improvement.
*The Positive Predictive Value* is of those that are predicted to be positive, what proportion are actually positive.  Here a higher value is better.  The xgboost model has a 50% improvement and if those that were predicted as positive were taken as a campaign group, then the success would be more than double of chance (7.5%/3.5%).

These results are replicable via Modelling/Model_post_feature_eng_v1.

I then adjust a number of the hyper parameters to see what the impacts here are.
	#Increasing the number of rounds has minimal impact
	#Increasing the weights doesn't improve the model - theory being that the value to Santander would be much greater than the reweighting
	#Flexing the cutoff point generally reduces the Positive Predictive Value

However the best results came from 2 approaches.  Reducing the weights by 50% and increasing the amount of data that is being fed into the model to 194k observations.  The confusion matrix of these results is below.

<img src="Images/xgb10_3_10d_100n_halfweight.PNG" alt="hi" class="inline"/>

Comparing the key statistics show the improvement.


|             | xgboost Baseline | xgboost Base + Data + Decrease Weighting |  |
|-------------|:---------:|:----:|--|
| *Sensitivity* | 20.2%     |19.7%    | 
| *Prevelance Detection*|         14%|12.1%    | 
| *Posive Predictive Value*         |  7.5%       |8.4%    |

So a slightly reduced amount are highlighted as positive, but of those that are the prediction is more accurate.  Looking at what the main drivers of this are is interesting.

<img src="Images/Imp_plot_XGboost_n100_d10_190k.png" alt="hi" class="inline"/>

Renta is the total household income and is the strongest predictor.  Antiguedad is the length of time that the customer has been with Santander in months.  
Renta is very interesting because about 20% of the data was originally missing values, and these were set to -99.  This needs to be investigated.
Additionally all of this data needs to be investigated to see what groups of people tend to add products, and those who don't.

# Next Steps
I will build a shiny app to visualise the data and identify what features to build, and if any further cleaning needs to be done.  
The first feature I will look at will be the renta variable and see if there is a better imputted value to use which can give the model more information.

The Shiny app is deployed [here](https://jamesoliver1981.shinyapps.io/santander_distributions_and_pivots/) and I am conducting explorative analysis at present.

***# To be continued...***
