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

#Cannot create a RF on an 2xXL machine on AWS (8 cores & 32GB RAM), so approach
#bottom up with a rescaled set of data - 100,000 cases.  Scaled down to be 50 50
train4<-ROSE(Changed ~.,data = train3, N=100000,p=0.5, seed=4785)$data

x<-train4[,2:46]

start_time <- Sys.time()
set.seed(7845)
rf_mod<-randomForest(x,train4$Changed, importance=TRUE, ntree=200, mtry = 10,
                     nodesize = 20,  replace=TRUE,keep.forest=TRUE)
end_time <- Sys.time()
write.csv(start_time,"starttime.csv")
saveRDS(rf_mod,"rf_mod_500_100kROSE.rds")

#OOB looks alsmost perfect which suggests overfitting
rf_mod


#source data for prediction and create prediction
testRF<-readRDS("testsetforRF.rds")
testRF$pred<-predict(rf_mod,newdata = testRF)

table(testRF$pred,testRF$Changed)

#interestingly, this completely overstates the change liklihood
#re run the prediction with the probability and adjust the roc curve

#try a different resampling method, randomly select 100,000 cases, check proportions
#leave proportion in 1:20 ish

random<-sample(1:100,nrow(train3),replace=TRUE)
train3$random<-random
#randomly select approx 100k cases
train5<-train3[train3$random %in% 10:20,]
#quick double check on proportions: OK
table(train5$Changed)

#run same RF
x<-train5[,2:46]
start_time <- Sys.time()
set.seed(7845)
rf_mod_down<-randomForest(x,train5$Changed, importance=TRUE, ntree=200, mtry = 10,
                          nodesize = 20,  replace=TRUE,keep.forest=TRUE)
end_time <- Sys.time()
write.csv(start_time,"starttime.csv")
saveRDS(rf_mod_down,"rf_mod_200_100kdown.rds")

#look at oob & predict the new model on the test data
rf_mod_down
testRF$pred_down<-predict(rf_mod_down,newdata = testRF)
table(testRF$pred_down,testRF$Changed)

#these results are much more as expected, model says predominate
#is no change as are the priors
#interesting that it the total opposite of the ROSE model - is there a middle ground?
#test by upscaling the Yes proportion in the data set
train3<-select(train3,-random)
train_Rose25<-ROSE(Changed~., data=train3, N=100000,p=0.25,seed=1236)$data

x<-train_Rose25[,2:46]
start_time <- Sys.time()
set.seed(7845)
rf_mod_ROSE25<-randomForest(x,train_Rose25$Changed, importance=TRUE, ntree=200, mtry = 10,
                            nodesize = 20,  replace=TRUE,keep.forest=TRUE)
end_time <- Sys.time()
write.csv(start_time,"starttime.csv")
saveRDS(rf_mod_ROSE25,"rf_mod_200_1111ROSE25.rds")
rf_mod_ROSE25

testRF$pred_ROSE25<-predict(rf_mod_ROSE25,newdata = testRF)
table(testRF$pred_ROSE25,testRF$Changed)
#in this instance, it appears that ROSE overstates the chances of a Yes

#final version of RF, self determine under sampled data set
train7_Yes<-train3[train3$Changed=="Yes",]
train7_No<-train3[train3$Changed=="No",]
random<-sample(1:100,nrow(train7_No),replace = TRUE)
train7_No$random<-random
train7_No_2<-train7_No[train7_No$random %in% 35:41,]
train7_No_2<-select(train7_No_2,-random)
train7<-rbind(train7_No_2,train7_Yes)

x<-train7[,2:46]
start_time <- Sys.time()
set.seed(7845)
rf_mod_under5050<-randomForest(x,train7$Changed, importance=TRUE, ntree=200, mtry = 10,
                               nodesize = 20,  replace=TRUE,keep.forest=TRUE)
end_time <- Sys.time()
write.csv(start_time,"starttime.csv")
saveRDS(rf_mod_under5050,"rf_mod_200_under5050.rds")
rf_mod_under5050
#The OOB representation here is very mixed.  The majority classes are correct but
#accuracy is poor.  This is unlikely to give a good result.

testRF$pred_under5050<-predict(rf_mod_under5050,newdata = testRF)
table(testRF$pred_under5050,testRF$Changed)

#These results give a broader distribution of definitions, but appear to be roughly 
#equal in their errors - ie 20% are in predicted as Yes regardless of if it is 
#No or Yes.  This as per the OOB estimate suggests there is insufficient information
#for the model to identify a split.  
#As expected, there is no Free Lunch.  This leads me to Feature engineering...


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