#Prep the updated data set to be able to run an xgboost model on the data set

library(dplyr)
library(xgboost)
library(caret)

setwd("C:/Users/James/Documents/James/DataScience/SantanderPrediction/Kaggle_Santander_ProdRec/data")
train1<-readRDS("train_clean_minus36912.rds")


#drop where cancelled - build model to focus on those selling
train1<-train1[train1$Changed %in% c(0,1),]

nam<-c("fecha_dato","ncodpers","fecha_alta","NumProds_pr_3","NumProds_pr_6","NumProds_pr_9","NumProds_pr_12")
train1<-select(train1,-nam)


#couple of variables have missing values
#do one model for where renta is known - then fix renta later
train2<-train1[complete.cases(train1$renta),]
# train2<-train1
# train2$renta[is.na(train2$renta)]<- -99
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


#Ensure all is numeric
train3[] <- lapply(train3, as.numeric)

#reduce data size to allow for computation
#randomly select 100,000 cases, check proportions
#leave proportion in 1:20 ish

set.seed(7463)
random<-sample(1:100,nrow(train3),replace=TRUE)
train3$random<-random

#adding even more data - 194k data training
train5_3<-train3[train3$random %in% 25:45,]

train_label_3<-train5_3$Changed
train6_3<-select(train5_3,-c(Changed,random) )
trainmatrix_3<-data.matrix(train6_3)

dtrain_3 <- xgb.DMatrix(data = trainmatrix_3, label= train_label_3)


#set up test data
test<-train3[train3$random %in% 80:100,]
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

#rebalancing
negative_cases <- sum(train_label_3 == 0)
postive_cases <- sum(train_label_3 == 1)


###NO RENTA - & only 3 months old####
set.seed(7896)
xgb10_3 <- xgboost(data = dtrain_3, # the data   
                   max.depth = 10,
                   nround = 100, # max number of boosting iterations
                   objective = "binary:logistic",
                   scale_pos_weight = (negative_cases*0.5)/postive_cases)

gen_results(xgb10_3,dtest,0.5)

###NO RENTA - & 3-6-9-12 months old####
set.seed(7896)
xgb1_3 <- xgboost(data = dtrain_3, # the data   
                   max.depth = 15,
                   nround = 500, # max number of boosting iterations
                   objective = "binary:logistic",
                   scale_pos_weight = (negative_cases)*0.1/postive_cases,
                  gamma = 0.5)

gen_results(xgb1_3,dtest,0.2)

#consider trying a reweighted approach
#consider trying to rf - adding in the prediction and reweight them including this information


#without renta
        #sens 7,5% vs 19,7%
        #Prev Detection 3,9% vs 12,1%
        #Pos Pred Value 9,6% vs 8,4%

#picking up only the top 7.5% of cancellors but at twice the rate

# set.seed(7896)
# xgb2_3 <- xgboost(data = dtrain_3, # the data   
#                    max.depth = 10,
#                    nround = 200, # max number of boosting iterations
#                    objective = "binary:logistic",
#                    scale_pos_weight = (negative_cases/2)/postive_cases)
# 
# gen_results(xgb2_3,dtest,0.3)


# #just for reference, adding more rounds has a limit
# set.seed(7896)
# xgb11_3 <- xgboost(data = dtrain_3, # the data   
#                    max.depth = 10,
#                    nround = 150, # max number of boosting iterations
#                    objective = "binary:logistic",
#                    scale_pos_weight = (negative_cases*0.5)/postive_cases)
# gen_results(xgb11_3,dtest,0.5)
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
xgb.ggplot.importance(head(importance_matrix,15))
pl<-xgb.ggplot.importance(head(importance_matrix,15))
pl+ggtitle("Importance Plot of XGBoost")
#interesting that renta is the most important when I set 20% of this data to -99 as missing
        #consider how to imput
#antiguedad - how long the customer has been there and where from seem to be important
#Owning some products drove an impact
#Change in previous months had limited impact but might be worth looking at

