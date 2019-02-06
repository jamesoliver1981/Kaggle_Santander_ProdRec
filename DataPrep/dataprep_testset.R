##do to test what done to training so can predict
################
#read in test data set and create variables which are required to run test
#test is April and seeing if there was a change in May
setwd("C:/Users/James/Documents/James/DataScience/SantanderPrediction/")

minus1_1<-readRDS("test.rds")
test_set<-readRDS("minus1_1.rds")

#repeat what done for train here for test
colnames(minus1_1)<-paste(colnames(minus1_1),"1",sep="_")

minus1_2<-rename(minus1_1, ncodpers  = ncodpers_1)

#merge and keep all in train to keep those who cancel
test1<-merge(test_set, minus1_2, by="ncodpers", all.x = TRUE)

#focus only on the products from the future month
minus1_red<-test1[,49:95]
minus1_red$ncodpers<-test1$ncodpers

#align structures of data to be able to identify what changes from 
#one month to the next
test1<-select(test1,ncodpers, everything())
minus1_red<-select(minus1_red,ncodpers, everything())
test2<-test1[,1:48]

change_1<-ifelse(test2==minus1_red,0,1)
change_2<-as.data.frame(change_1)

change_2$row<-rownames(change_2)

#clean up the environment
rm(change_1,minus1_1,minus1_2,minus1_red,test1, test2)


#Summarise what has changed and how much changed
change_2$Changed<-ifelse(rowSums(change_2[,25:48])>=1,1,0)
change_2$Num_changes<-rowSums(change_2[,25:48])

#Clean column names for the changes
colnames(change_2)<-paste(colnames(test_set),"change",sep = "_")
nam<-c("row","Changed","Num_Changes")
colnames(change_2)[49:51]<-nam
colnames(change_2)[2]<-"ncodpers"

#the change data doesn't have the customer number so its added backhere
change_2$ncodpers<-test_set$ncodpers

#combine changes to the original train data set, all x so keep cancellors
test_set_change<-merge(test_set, change_2, by="ncodpers", all.x = TRUE)
saveRDS(test_set_change,"test_set_change.rds")


#### Adjustments made to test to be able to predict on it

test_set_change<-readRDS("test_set_change.rds")
#drop the change variables for now as won't know this when making the prediction
test1<-select(test_set_change, -contains("change"))
test1$Changed<-test_set_change$Changed

#drop where cancelled - build model to focus on those selling
test1<-test1[test1$Changed %in% c(0,1),]

#Clean up variables which won't work for a Random forest
#117 country of residence - too many for a random forest - focus if in Spain or not
test1$Spanish_res<-ifelse(test1$pais_residencia=="ES",1,0)

#163 different initial sales channels - rf accepts only 53
topchan<-readRDS("topchannels.rds")
test1$Channel<-ifelse(test1$canal_entrada %in% topchan,test1$canal_entrada,"OTH")

#drop other variables which cannot be used in prediction

nam<-c("fecha_dato","row","ncodpers","fecha_alta",
       "canal_entrada","pais_residencia")
test2<-select(test1,-nam)

#couple of variables have missing values
test2$renta[is.na(test2$renta)]<- -99
test2$cod_prov[is.na(test2$cod_prov)]<-99

#Final check on variables with missing values
colSums(is.na(test2))

#Character Variables need to be converted to factors
chars<-test2 %>% 
        select_if(is.character)
fact_test<-as.data.frame(sapply(chars,as.factor))

colnames(fact)==colnames(fact_test)
for (i in 1:length(fact)){
fact_test[,i]<-factor(fact_test[,i],levels=levels(fact[,i]))
}
nums<-test2 %>%  
        select_if(is.numeric)
test3<-cbind(nums,fact_test)

#For a random forest classification, target variable must be a Non numeric factor
test3$Changed<-ifelse(test3$Changed==0,"No","Yes")
test3$Changed<-as.factor(test3$Changed)

#some NA's need to be removed - remove 1500 cases
test3<-test3[complete.cases(test3$ult_fec_cli_1t),]

saveRDS(test3, "testsetforRF.rds")
