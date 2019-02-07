# Playing with Kaggles' Santander Production Recommendation Dataset

This page is where I will document the progress of playing with the aforementioned dataset.  This competition ran back in 2016 and provided Kagglers with approximately 1m customer records, with monthly snapshots going back over 18 months.
The data and information can be found [here](https://www.kaggle.com/c/santander-product-recommendation)

# Data
The train data is about 2.3GB in size.  You can see how I read it in in the script /DataPrep/dataprep.R.
On a machine with 2 cores & 8GB RAM, this took 15 minutes to load.  To enable you to follow along, I created a couple of monthly snapshots of data, and saved these.  These are in the /data folder.

Essentially what I am doing here is taking a month (March 2016) as my training base, and then adding in what changed in the following month.  This is then my basic training set.

Whilst I'm here, I identify exactly what has been changed (ie which products have been purchased) to see if there is a majority to focus on, which might help to identify next steps for feature selection.

/dataprep/dataprep_test.R is a replication of this for the test data set.  Again all data is provided in the /data folder.


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
