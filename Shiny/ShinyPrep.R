library(dplyr)

setwd("C:/Users/James/Documents/James/DataScience/SantanderPrediction/Kaggle_Santander_ProdRec/data")
df<-readRDS("trainchange1.rds")

#drop values which do not work in shiny (look like dates)
df2<-select(df,-c(fecha_alta,fecha_dato))
rand<-sample(1:100,nrow(df2),replace = TRUE)
#Limit to 10% of data set and see what comes out
        #still then have 5k of cancellors
samp<-df2[rand %in% 1:10,]
saveRDS(samp,"samp.rds")
