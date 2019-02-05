#There is no such thing as a free lunch.  Features will need to be generated to 
#create an accurate prediction.  However, running a few algorithms might show where
#to initially look (plus demonstrate knowledge and ability of algorithms)

library(ROSE)
library(caret)
library(randomForest)
library(dplyr)

setwd("C:/Users/James/Documents/James/DataScience/SantanderPrediction/")

train<-readRDS("trainchange1.rds")
#drop the change variables for now as won't know this when making the prediction
train1<-select(train, -contains("change"))
train1$Changed<-train$Changed
table(train1$Changed)

#drop where cancelled - build model to focus on those selling
train1<-train1[train1$Changed %in% c(0,1),]

#Clean up variables which won't work for a Random forest
#117 country of residence - too many for a random forest - focus if in Spain or not
train1$Spanish_res<-ifelse(train1$pais_residencia=="ES",1,0)

#163 different initial sales channels - rf accepts only 53
chans<-as.data.frame(table(train1$canal_entrada))
chans<-chans[order(-chans$Freq),]
topchan<-as.character(chans[1:52,1])
saveRDS(topchan,"topchannels.rds")
train1$Channel<-ifelse(train1$canal_entrada %in% topchan,train1$canal_entrada,"OTH")

#drop other variables which cannot be used in prediction

nam<-c("fecha_dato","row","NewProds","ncodpers","fecha_alta",
       "canal_entrada","pais_residencia")
train2<-select(train1,-nam)

#couple of variables have missing values
train2$renta[is.na(train2$renta)]<- -99
train2$cod_prov[is.na(train2$cod_prov)]<-99

#Final check on variables with missing values
colSums(is.na(train2))

#Character Variables need to be converted to factors
chars<-train2 %>% 
        select_if(is.character)
fact<-as.data.frame(sapply(chars,as.factor))

#grab the numeric variables and bind with factor variables
nums<-train2 %>%  
        select_if(is.numeric)
train3<-cbind(nums,fact)

#For a random forest classification, target variable must be a Non numeric factor
train3$Changed<-ifelse(train3$Changed==0,"No","Yes")
train3$Changed<-as.factor(train3$Changed)
train3<-select(train3,Changed, everything())
x<-train3[,2:46]

start_time <- Sys.time()
set.seed(7845)
rf_mod<-randomForest(x,train3$Changed, importance=TRUE, ntree=500, 
                     nodesize = 20,  replace=TRUE,keep.forest=TRUE)
end_time <- Sys.time()

#show results against test & evaluate
#confusion matrix
#variable importance - save plot & table

#use ROSE to create a rebalanced data set - down & up
#note some concerns with the approach

#Consider running PCA

#run xgboost 
#run NN

#compare results

#run kmeans and evaluate