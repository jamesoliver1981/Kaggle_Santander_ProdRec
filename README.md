# Playing with Kaggles' Santander Production Recommendation Dataset

This page is where I will document the progress of playing with the aforementioned dataset.  This competition ran back in 2016 and provided Kagglers with approximately 1m customer records, with monthly snapshots going back over 18 months.
The data and information can be found [here](https://www.kaggle.com/c/santander-product-recommendation)

# Data
The train data is about 2.3GB in size.  You can see how I read it in in the script /DataPrep/dataprep.R.
On a machine with 2 cores & 8GB RAM, this took 15 minutes to load.  To enable you to follow along, I created a couple of monthly snapshots of data, and saved these.  These are in the /data folder.

Essentially what I am doing here is taking a month (March 2016) as my training base, and then adding in what changed in the following month.  This is then my basic training set.

Whilst I'm here, I identify exactly what has been changed (ie which products have been purchased) to see if there is a majority to focus on, which might help to identify next steps for feature selection.

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
## Welcome to GitHub Pages

You can use the [editor on GitHub](https://github.com/jamesoliver1981/Kaggle_Santander_ProdRec/edit/master/README.md) to maintain and preview the content for your website in Markdown files.

Whenever you commit to this repository, GitHub Pages will run [Jekyll](https://jekyllrb.com/) to rebuild the pages in your site, from the content in your Markdown files.

### Markdown

Markdown is a lightweight and easy-to-use syntax for styling your writing. It includes conventions for

```markdown
Syntax highlighted code block

# Header 1
## Header 2
### Header 3

- Bulleted
- List

1. Numbered
2. List

**Bold** and _Italic_ and `Code` text

[Link](url) and ![Image](src)
```

For more details see [GitHub Flavored Markdown](https://guides.github.com/features/mastering-markdown/).

### Jekyll Themes

Your Pages site will use the layout and styles from the Jekyll theme you have selected in your [repository settings](https://github.com/jamesoliver1981/Kaggle_Santander_ProdRec/settings). The name of this theme is saved in the Jekyll `_config.yml` configuration file.

### Support or Contact

Having trouble with Pages? Check out our [documentation](https://help.github.com/categories/github-pages-basics/) or [contact support](https://github.com/contact) and we’ll help you sort it out.
