##Same approach as model_post_feature eng v2 but when renta is known and unknown

train3<-readRDS("train3.rds")



#Restrict to only with real renta values and then compare to local averages
#train4<-select(train3,-renta)
train4<-train3[train3$renta != -99,]
train4$rel_rent_mean<-train4$renta/train4$renta_mean
train4$rel_rent_med<-train4$renta/train4$renta_median
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
#train6_3<-select(train5_3,-c(Changed,random,renta_mean) )
train6_3<-select(train5_3,-c(Changed,random) )
trainmatrix_3<-data.matrix(train6_3)

dtrain_3 <- xgb.DMatrix(data = trainmatrix_3, label= train_label_3)


#set up test data
test<-train4[train4$random %in% 80:100,]
test_label<-test$Changed
#test<-select(test,-c(Changed,random,renta_mean) )
test<-select(test,-c(Changed,random) )
testmatrix<-data.matrix(test)
dtest <- xgb.DMatrix(data = testmatrix, label= test_label)

#write a function to test on data that the model has never seen
gen_results<-function(mod, testset=dtest,cutoff=0.5,test_label=test_label){
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



# set.seed(7896)
# xgb10_3 <- xgboost(data = dtrain_3, # the data
#                    max.depth = 10,
#                    nround = 100, # max number of boosting iterations
#                    objective = "binary:logistic",
#                    scale_pos_weight = (negative_cases*0.5)/postive_cases)
# 
# gen_results(xgb10_3,dtest,0.5)
#sens 19,7%
#Prev Detection 12,1%
#Pos Pred Value 8,4%

set.seed(7896)
xgb_rent <- xgboost(data = dtrain_3, # the data   
                  max.depth = 10,
                  nround = 100, # max number of boosting iterations
                  objective = "binary:logistic",
                  scale_pos_weight = (negative_cases*0.5)/postive_cases)

gen_results(xgb_rent,dtest,0.5)
#sens 7,2%
#Prev Detection 3,7%
#Pos Pred Value 9,75%


imp_mat_rent <- xgb.importance(names(trainmatrix_3), model = xgb_rent)

newtrain<-train5_3
newtrain$pred2<-predict(xgb_rent,dtrain_3)
newtrain$Pred2Class<-ifelse(newtrain$pred2>0.5,1,0)
confusionMatrix(as.factor(newtrain$Pred2Class),as.factor(newtrain$Changed),positive = "1")
        #overfitting badly - this thinks its great


set.seed(7896)
xgb_rent2 <- xgboost(data = dtrain_3, # the data   
                    max.depth = 6,
                    nround = 100, # max number of boosting iterations
                    objective = "binary:logistic",
                    scale_pos_weight = (negative_cases*0.5)/postive_cases)
#weighting 9447/871

gen_results(xgb_rent2,dtest,0.4,test_label )
gen_results(xgb_rent2,dtest,0.3,test_label )
#what does my over fit look like?
newtrain$pred<-predict(xgb_rent2,dtrain_3)
newtrain$PredClass<-ifelse(newtrain$pred>0.4,1,0)
confusionMatrix(as.factor(newtrain$PredClass),as.factor(newtrain$Changed),positive = "1")


set.seed(7896)
xgb_rent3 <- xgboost(data = dtrain_3, # the data   
                     max.depth = 4,
                     nround = 200, # max number of boosting iterations
                     objective = "binary:logistic",
                     scale_pos_weight = (negative_cases*0.5)/postive_cases)
#weighting 9447/871
gen_results(xgb_rent3,dtest,0.4,test_label )
gen_results(xgb_rent3,dtest,0.3,test_label )

newtrain$pred3<-predict(xgb_rent3,dtrain_3)
newtrain$Pred3Class<-ifelse(newtrain$pred3>0.4,1,0)
confusionMatrix(as.factor(newtrain$PredClass),as.factor(newtrain$Changed),positive = "1")

set.seed(7896)
xgb_rent4 <- xgboost(data = dtrain_3, # the data   
                     max.depth = 8,
                     nround = 100, # max number of boosting iterations
                     objective = "binary:logistic",
                     scale_pos_weight = (negative_cases*0.5)/postive_cases)
#weighting 9447/871
gen_results(xgb_rent4,dtest,0.4,test_label )

newtrain$pred4<-predict(xgb_rent4,dtrain_3)
newtrain$Pred4Class<-ifelse(newtrain$pred4>0.4,1,0)


newtest<-train4[train4$random %in% 80:100,]
test_label<-newtest$Changed
newtest$pred2<-predict(xgb_rent,dtest)
newtest$Pred2Class<-ifelse(newtest$pred2>0.5,1,0)

newtest$pred<-predict(xgb_rent2,dtest)
newtest$PredClass<-ifelse(newtest$pred>0.4,1,0)
newtest$pred3<-predict(xgb_rent3,dtest)
newtest$Pred3Class<-ifelse(newtest$pred3>0.4,1,0)
newtest$pred4<-predict(xgb_rent4,dtest)
newtest$Pred4Class<-ifelse(newtest$pred4>0.4,1,0)
newtest<-select(newtest,-c(Changed,random))

##build a model with the predictions included

newtrain_label<-newtrain$Changed
#train6_3<-select(train5_3,-c(Changed,random,renta_mean) )
newtrain2<-select(newtrain,-c(Changed,random) )
newtrainmatrix<-data.matrix(newtrain2)

dnewtrain <- xgb.DMatrix(data = newtrainmatrix, label= newtrain_label)


#set up test data

#test<-select(test,-c(Changed,random,renta_mean) )
newtestmatrix<-data.matrix(newtest)
dnewtest <- xgb.DMatrix(data = newtestmatrix, label= test_label)


set.seed(7896)
xgb_preds <- xgboost(data = dnewtrain, # the data   
                     max.depth = 3,
                     nround = 50, # max number of boosting iterations
                     objective = "binary:logistic",
                     scale_pos_weight = (negative_cases*0.5)/postive_cases)
#weighting 9447/871
gen_results(xgb_preds,dnewtest,0.5,test_label )



#what will be its own prediction on its own data - is it overfitting
newtrain$p<-predict(xgb_preds,dnewtrain)
newtrain$PClass<-ifelse(newtrain$p>0.5,1,0)
confusionMatrix(as.factor(newtrain$PClass),as.factor(newtrain$Changed),positive = "1")


importance_matrix <- xgb.importance(names(newtrain_matrix), model = xgb_spec)

head(importance_matrix,20)



#are there instances where depth 10 predicts correctly and the others don't
nrow(newtrain[newtrain$Pred2Class==1 & newtrain$Changed ==1 & newtrain$PredClass==0 &newtrain$Pred3Class==0,])
nrow(newtrain[newtrain$Pred2Class==0 & newtrain$Changed ==1 & newtrain$PredClass==1 &newtrain$Pred3Class==0,])
#split out the positive scores based on 0,4 cut off

pred<-predict(xgb_rent,dtest)
newtrain<-test
newtrain$Changed<-test_label
newtrain$pred<-pred

newtrain$PredClass<-as.numeric(newtrain$pred > 0.4)
#check that I do get the same results -ok
confusionMatrix(as.factor(newtrain$PredClass),as.factor(newtrain$Changed),positive = "1")

#restrict to data where this was predicted to be a mover
newtrain1<-newtrain[newtrain$PredClass==1,]
#Create a variable which ids if the previous prediction was correct

set.seed(1452)
rand<-sample(1:100,nrow(newtrain1),replace = TRUE)
newtrain2<-newtrain1[rand %in% 1:70,]

newtrain_label<-newtrain2$Changed
#train6_3<-select(train5_3,-c(Changed,random,renta_mean) )
newtrain3<-select(newtrain2,-c(Changed) )
newtrain_matrix<-data.matrix(newtrain3)

dtrain_res <- xgb.DMatrix(data = newtrain_matrix, label= newtrain_label)


#set up test data
newtest<-newtrain1[rand %in% 71:100,]
newtest_label<-newtest$Changed
#test<-select(test,-c(Changed,random,renta_mean) )
newtest<-select(newtest,-c(Changed) )
newtestmatrix<-data.matrix(newtest)
newdtest <- xgb.DMatrix(data = newtestmatrix, label= newtest_label)

#rebalancing
negative_cases <- sum(newtrain_label == 0)
postive_cases <- sum(newtrain_label == 1)

set.seed(7896)
xgb_spec <- xgboost(data = dtrain_res, # the data   
                    max.depth = 10,
                    nround = 100, # max number of boosting iterations
                    objective = "binary:logistic",
                    scale_pos_weight = (negative_cases*0.5)/postive_cases)

gen_results(xgb_spec,newdtest,0.5,test_label=newtest_label)
#sens 7,2%
#Prev Detection 3,7%
#Pos Pred Value 9,75%


importance_matrix <- xgb.importance(names(newtrain_matrix), model = xgb_spec)

head(importance_matrix,20)

