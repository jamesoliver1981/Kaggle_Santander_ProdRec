#Prep the updated data set to be able to run an xgboost model on the data set

library(dplyr)
library(xgboost)
library(caret)

setwd("C:/Users/James/Documents/James/DataScience/SantanderPrediction/Kaggle_Santander_ProdRec/data")

train1<-readRDS("trainplus_label.rds")

#drop where cancelled - build model to focus on those selling
train1<-train1[train1$Changed %in% c(0,1),]

#Clean up variables 
#117 country of residence - too many for a random forest - focus if in Spain or not
top_countries<-as.data.frame(table(train1$pais_residencia))

top_countries<-top_countries[order(-top_countries$Freq),]
#restrict to 10 to reduce the size of the matrix-given over 95% of countries are Spain
top_countries<-top_countries[1:10,1]
saveRDS(top_countries,"top_countries.rds")
top_countries<-readRDS("top_countries.rds")
train1$CountryRes<-ifelse(train1$pais_residencia %in% top_countries, train1$pais_residencia, "OTH")

#163 different initial sales channels - rf accepts only 53
chans<-as.data.frame(table(train1$canal_entrada))
chans<-chans[order(-chans$Freq),]
View(chans)
#put in a top 12 as these are over 5000 each
topchan<-as.character(chans[1:12,1])
saveRDS(topchan,"topchannels.rds")
topchan<- readRDS("topchannels.rds")
train1$Channel<-ifelse(train1$canal_entrada %in% topchan,train1$canal_entrada,"OTH")

#these are all dates in the training month - transform to be if blank, 0, else 1
train1$NotPrimaryinMonth<-ifelse(train1$ult_fec_cli_1t=="",0,1)


#drop other variables which cannot be used in prediction

nam<-c("fecha_dato","ncodpers","fecha_alta",
       "canal_entrada","pais_residencia","ult_fec_cli_1t")
train2<-select(train1,-nam)

#couple of variables have missing values
train2$renta[is.na(train2$renta)]<- -99
train2$cod_prov[is.na(train2$cod_prov)]<-99

#Final check on variables with missing values
checkforNA<-data.frame(ColA=colSums(is.na(train2)))
checkforNA[checkforNA$ColA!=0,]

#Character Variables need to be converted to factors
chars<-train2 %>% 
        select_if(is.character)
fact<-model.matrix(~.-1,chars)
fact2<-as.data.frame(fact)

#grab the numeric variables and bind with factor variables
nums<-train2 %>%  
        select_if(is.numeric)
train3<-cbind(nums,fact2)
train3<-train3[train3$Changed %in% c(0,1),]


train3$DiffProds_minus3<-rowSums(train3[,52:75])
train3$DiffProds_minus6<-rowSums(train3[,95:118])
train3$DiffProds_minus9<-rowSums(train3[,139:162])
train3$DiffProds_minus12<-rowSums(train3[,183:206])

train4<-train3
train4[] <- lapply(train4, as.numeric)

#reduce data size to allow for computation
#randomly select 100,000 cases, check proportions
#leave proportion in 1:20 ish

set.seed(7463)
random<-sample(1:100,nrow(train4),replace=TRUE)
train4$random<-random
#randomly select approx 100k cases
train5<-train4[train4$random %in% 25:26,]
#quick double check on proportions: OK
table(train6$Changed)

train_label<-train5$Changed
train6<-select(train5,-c(Changed,random) )
trainmatrix<-data.matrix(train6)

dtrain <- xgb.DMatrix(data = trainmatrix, label= train_label)
getwd()
saveRDS(dtrain,"train_xgb.rds")
dtrain<-readRDS("train_xgb.rds")

#set up test data
test<-train4[train4$random %in% 80:100,]
test_label<-test$Changed
test<-select(test,-c(Changed,random) )
testmatrix<-data.matrix(test)
dtest <- xgb.DMatrix(data = testmatrix, label= test_label)

#write a function to test on data that the model has never seen
gen_results<-function(mod, testset=dtest,cutoff=0.5){
        pred <- predict(mod, testset)
        
        #Overall error rate
        err <- mean(as.numeric(pred > 0.5) != test_label)
        print(paste("test-error=", err))
        
        results<-data.frame(TestData = test_label,Prediction=pred)
        results$PredClass<-as.numeric(results$Prediction > cutoff)
        
        assign(paste("out_",deparse(substitute(mod)),sep=""), 
               confusionMatrix(as.factor(results$PredClass),as.factor(results$TestData),positive = "1"), 
               envir=.GlobalEnv)
        confusionMatrix(as.factor(results$PredClass),as.factor(results$TestData),positive = "1")
}


#Values to look at here are 
        #the Positive Predicted Value - of those predicted as positive, how many true - high as poss
        #Detection Prevelence - proportion predicted as positive
        #Sensitivity - of those who are positive, how many are correctly predicted
#
set.seed(7896)
xgb1 <- xgboost(data = dtrain, # the data   
                max.depth = 10,
                nround = 100, # max number of boosting iterations
                objective = "binary:logistic")

gen_results(xgb1,dtest,0.5)
        #sens 0,2%
        #Prev Detection 5,2%
        #Pos Pred Value 24,6%
#Model basically predicts all are not going to change- doesn't help - need to rebalance the data to get 
#better view

#rebalancing data - use proportion to reweight positives 
negative_cases <- sum(train_label == 0)
postive_cases <- sum(train_label == 1)

set.seed(7896)
xgb2 <- xgboost(data = dtrain, # the data   
                max.depth = 10,
                nround = 100, # max number of boosting iterations
                objective = "binary:logistic",
                scale_pos_weight = negative_cases/postive_cases)
gen_results(xgb2,dtest,0.5)
        #sens 20,2%
        #Prev Detection 14%
        #Pos Pred Value 7,5%
#Vastly improved results however in theory, the knowledge of who will buy new products is far 
#more valuable than 17:1 
        # try flexing the weighting
set.seed(7896)
xgb5 <- xgboost(data = dtrain, # the data   
                max.depth = 10,
                nround = 100, # max number of boosting iterations
                objective = "binary:logistic",
                scale_pos_weight = negative_cases*2/postive_cases)

gen_results(xgb5,dtest,0.5)
        #sens 11,6%
        #Prev Detection 8,7%
        #Pos Pred Value 6,9%
#id less of the opportunities, and less overall and pos pred value decrease

#try an extreme weight*10
set.seed(7896)
xgb6 <- xgboost(data = dtrain, # the data   
                max.depth = 10,
                nround = 100, # max number of boosting iterations
                objective = "binary:logistic",
                scale_pos_weight = negative_cases*10/postive_cases)

gen_results(xgb6,dtest,0.5)
        #sens 23,5%
        #Prev Detection 19,8%
        #Pos Pred Value 6,1%

#the previous RF was
        #sens 23,9%
        #Prev Detection 24,6%
        #Pos Pred Value 5,2%
                #allocates more to predicted but has a worse positive predictive value


#go back to the best model in terms of positive pred value- go back to straight weights - not increasing
#try playing with the cut off
set.seed(7896)
xgb8 <- xgboost(data = dtrain, # the data   
                max.depth = 10,
                nround = 100, # max number of boosting iterations
                objective = "binary:logistic",
                scale_pos_weight = negative_cases/postive_cases)

gen_results(xgb8,dtest,0.4)
        #sens 11,2%
        #Prev Detection 8,2%
        #Pos Pred Value 7,1%

#better results therefore try reducing the weights
set.seed(7896)
xgb9 <- xgboost(data = dtrain, # the data   
                max.depth = 10,
                nround = 100, # max number of boosting iterations
                objective = "binary:logistic",
                scale_pos_weight = (negative_cases*0.75)/postive_cases)

gen_results(xgb9,dtest,0.4)
        #sens 9,1%
        #Prev Detection 6,5%
        #Pos Pred Value 7,2%

#less identified, but same positive value - could further reduce the cut off
set.seed(7896)
xgb10 <- xgboost(data = dtrain, # the data   
                max.depth = 10,
                nround = 100, # max number of boosting iterations
                objective = "binary:logistic",
                scale_pos_weight = (negative_cases*0.5)/postive_cases)

gen_results(xgb10,dtest,0.4)
        #sens 6%
        #Prev Detection 4,2%
        #Pos Pred Value 7,4%

#This is all fringe work // its getting slighlty better results - could come back to this and take 
#double in prediction if of value... and then build a diff model when exclude those

#does the model improve when we add more data? 94k obs as training
train5_2<-train4[train4$random %in% 25:34,]

train_label_2<-train5_2$Changed
train6_2<-select(train5_2,-c(Changed,random) )
trainmatrix_2<-data.matrix(train6_2)

dtrain_2 <- xgb.DMatrix(data = trainmatrix_2, label= train_label_2)

set.seed(7896)
xgb10_2 <- xgboost(data = dtrain_2, # the data   
                 max.depth = 10,
                 nround = 100, # max number of boosting iterations
                 objective = "binary:logistic",
                 scale_pos_weight = (negative_cases*0.5)/postive_cases)

gen_results(xgb10_2,dtest,0.4)
        #sens 14,4%
        #Prev Detection 9,3%
        #Pos Pred Value 7,9%
#tripled sensitivty, minimal increase in overall detection.  Best pos pred value

#adding even more data - 194k data training
train5_3<-train4[train4$random %in% 25:45,]

train_label_3<-train5_3$Changed
train6_3<-select(train5_3,-c(Changed,random) )
trainmatrix_3<-data.matrix(train6_3)

dtrain_3 <- xgb.DMatrix(data = trainmatrix_3, label= train_label_3)

set.seed(7896)
xgb10_3 <- xgboost(data = dtrain_3, # the data   
                   max.depth = 10,
                   nround = 100, # max number of boosting iterations
                   objective = "binary:logistic",
                   scale_pos_weight = (negative_cases*0.5)/postive_cases)

gen_results(xgb10_3,dtest,0.4)
        #sens 19,7%
        #Prev Detection 12,1%
        #Pos Pred Value 8,4%

saveRDS(xgb10_3,"xgb_10d_100n_halfweight_194k.rds")

#just for reference, adding more rounds has a limit
set.seed(7896)
xgb11_3 <- xgboost(data = dtrain_3, # the data   
                   max.depth = 10,
                   nround = 150, # max number of boosting iterations
                   objective = "binary:logistic",
                   scale_pos_weight = (negative_cases*0.5)/postive_cases)
gen_results(xgb11_3,dtest,0.4)
        #sens 17,7%
        #Prev Detection 10,9%
        #Pos Pred Value 8,4%
                #back to fringes

#model appears to get better when playing with more data - sparse so can get a better read-
        #consider adding even more in later

#should I be playing with overfitting parameters as the error rates are very diff - 4%  vs 8%
        #have I compared to in model though?
        #is there cross validation I can do to reduce this

# look at feature importance and see what this is telling me though...

# get information on how important each feature is
importance_matrix <- xgb.importance(names(trainmatrix_3), model = xgb10_3)

head(importance_matrix)
# and plot it!
xgb.plot.importance(head(importance_matrix,15))
pl<-xgb.ggplot.importance(head(importance_matrix,15))
pl+ggtitle("Importance Plot of XGBoost")
#interesting that renta is the most important when I set 20% of this data to -99 as missing
        #consider how to imput
#antiguedad - how long the customer has been there and where from seem to be important
#Owning some products drove an impact
#Change in previous months had limited impact but might be worth looking at

