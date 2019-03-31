#Prep the updated data set to be able to run an xgboost model on the data set

library(dplyr)
library(xgboost)
library(caret)
library(data.table)

setwd("C:/Users/James/Documents/James/DataScience/SantanderPrediction/Kaggle_Santander_ProdRec/data")
NewFeatures<-readRDS("NewFeatures1.rds")
train1<-readRDS("trainplus_label.rds")


#drop where cancelled - build model to focus on those selling
train1<-train1[train1$Changed %in% c(0,1),]

#Clean up variables 
#117 country of residence - too many for a random forest - focus if in Spain or not
#top_countries<-as.data.frame(table(train1$pais_residencia))

# top_countries<-top_countries[order(-top_countries$Freq),]
# #restrict to 10 to reduce the size of the matrix-given over 95% of countries are Spain
# top_countries<-top_countries[1:10,1]
# saveRDS(top_countries,"top_countries.rds")
top_countries<-readRDS("top_countries.rds")
train1$CountryRes<-ifelse(train1$pais_residencia %in% top_countries, train1$pais_residencia, "OTH")

#163 different initial sales channels - rf accepts only 53
# chans<-as.data.frame(table(train1$canal_entrada))
# chans<-chans[order(-chans$Freq),]
# View(chans)
# #put in a top 12 as these are over 5000 each
# topchan<-as.character(chans[1:12,1])

topchan<- readRDS("topchannels.rds")
train1$Channel<-ifelse(train1$canal_entrada %in% topchan,train1$canal_entrada,"OTH")

#these are all dates in the training month - transform to be if blank, 0, else 1
train1$NotPrimaryinMonth<-ifelse(train1$ult_fec_cli_1t=="",0,1)

#clean up age 
train1<-train1[train1$age %in% 18:85,]
train0<-merge(train1, NewFeatures, by ="ncodpers", all.x = TRUE)
#drop other variables which cannot be used in prediction

nam<-c("fecha_dato","ncodpers","fecha_alta",
       "canal_entrada","pais_residencia","ult_fec_cli_1t")
train2<-select(train0,-nam)

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

#Create a summary of if there were different products previously
train3$DiffProds_minus3<-rowSums(train3[,52:75])
train3$DiffProds_minus6<-rowSums(train3[,95:118])
train3$DiffProds_minus9<-rowSums(train3[,139:162])
train3$DiffProds_minus12<-rowSums(train3[,183:206])

#Drop renta as I have new variables included
train4<-select(train3,-renta)
train4[] <- lapply(train4, as.numeric)

#reduce data size to allow for computation
#randomly select 100,000 cases, check proportions
#leave proportion in 1:20 ish

set.seed(7463)
random<-sample(1:100,nrow(train4),replace=TRUE)
train4$random<-random

#adding even more data - 194k data training
train5_3<-train4[train4$random %in% 25:45,]

train_label_3<-train5_3$Changed
train6_3<-select(train5_3,-c(Changed,random,renta_mean) )
trainmatrix_3<-data.matrix(train6_3)

dtrain_3 <- xgb.DMatrix(data = trainmatrix_3, label= train_label_3)


#set up test data
test<-train4[train4$random %in% 80:100,]
test_label<-test$Changed
test<-select(test,-c(Changed,random,renta_mean) )
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

set.seed(7896)
xgb2_3 <- xgboost(data = dtrain_3, # the data   
                   max.depth = 10,
                   nround = 100, # max number of boosting iterations
                   objective = "binary:logistic",
                   scale_pos_weight = (negative_cases*0.5)/postive_cases)

gen_results(xgb2_3,dtest,0.5)
        #sens 7,5%
        # prev detection 3,96
        #pos pred value =9,49%




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
importance_matrix <- xgb.importance(names(trainmatrix_3), model = xgb2_3)

head(importance_matrix,20)
# and plot it!
xgb.plot.importance(head(importance_matrix,15))
pl<-xgb.ggplot.importance(head(importance_matrix,15))
pl+ggtitle("Importance Plot of XGBoost")
#interesting that renta is the most important when I set 20% of this data to -99 as missing
        #consider how to imput
#antiguedad - how long the customer has been there and where from seem to be important
#Owning some products drove an impact
#Change in previous months had limited impact but might be worth looking at

