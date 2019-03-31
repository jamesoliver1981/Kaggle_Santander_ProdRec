##Further data prep
#Cleaned my data so now need to extend the data set to the history and 
library(dplyr)
library(data.table)
library(scales)
setwd("C:/Users/James/Documents/James/DataScience/SantanderPrediction/Kaggle_Santander_ProdRec/data")
traindata<-readRDS("train_clean.rds")

snapshot<-readRDS("dec15_clean.rds")
jj<-3
#build as function, which takes one of the above snapshots, and compares to train and id a difference 
#and append - only a variance to the current month, vs different to what was there in the prior snapshot
createchange<-function(traindata=train,snapshot,jj) {
#merge the train & snapshot, keep all.x - ensures all aligned for doing diff
        snapshot1<-snapshot
        colnames(snapshot1)<-paste(colnames(snapshot1),jj,sep="_")
#which column should this be in
        colnames(snapshot1)[2]<-"ncodpers"
        traindata1<-traindata
        train1<-merge(traindata1,snapshot1,by="ncodpers", all.x=TRUE)
#split the data up
        snapshot2<-train1[,22:41]
        snapshot2$ncodpers<-train1$ncodpers
#align data
        train1<-select(train1,ncodpers, everything())
        snapshot2<-select(snapshot2,ncodpers, everything())
        train2<-train1[,1:21]
        
#create a change
        change_1<-ifelse(train2==snapshot2,0,1)
        change_2<-as.data.frame(change_1)
        colnames(change_2)<-paste(colnames(change_2),"pr",jj,sep="_")
        #need to recreate ncodpers and then merge
        colnames(change_2)[1]<-"ncodpers"
        change_2$ncodpers<-train2$ncodpers
        #no need for change in date - it always changes - overwrite with if
        #customer is a new customer at this point or not
        colnames(change_2)[2]<-paste("ExistingCust_at_pr",jj,sep="")
        change_2[2]<-ifelse(is.na(change_2[2]),0,1)
        change_2[is.na(change_2)]<- -1
        traindata<-merge(traindata,change_2,by="ncodpers",all.x = TRUE)
        #Variables which don't vary month to month and should be dropped
        nam<-c("renta","nomprov","indrel","antiguedad","indext","antiguedad_lt12","antiguedad_peak",
               "CountryRes","NumProds")
        namplus<-paste0(nam,"_pr_",jj)
        
        traindata<-select(traindata,-namplus)
        #add in specific number of products had and create a diff
        snapshot3<-select(snapshot, c(ncodpers,NumProds))
        colnames(snapshot3)[2]<-paste0(colnames(snapshot3)[2],"_pr_",jj)
        traindata_upd<<-merge(traindata, snapshot3, by="ncodpers",all.x = TRUE)
        
}

createchange(traindata=traindata, snapshot=snapshot,jj=3)
traindata_upd$DiffNumProds_pr_3<-traindata_upd$NumProds-traindata_upd$NumProds_pr_3

traindata_upd$DiffNumProds_pr_3[is.na(traindata_upd$DiffNumProds_pr_3)]<- -99


tc<-readRDS("trainchange1.rds")
tc<-select(tc,c(ncodpers, Changed))
train2<-merge(traindata_upd,tc,by="ncodpers",all.x = TRUE)
TopProds<-as.data.frame(table(train2$AllProds))
TopProds<-TopProds[order(-TopProds$Freq),]

TopProds2<-TopProds[TopProds$Freq>1000,1]
saveRDS(TopProds2,"TopProds.rds")

train2$TopProds<-ifelse(train2$AllProds %in% TopProds2,train2$AllProds,"OTH")
train3<-select(train2, -AllProds)
saveRDS(train3,"train_clean_minus3.rds")

sep15<-readRDS("sep15_clean.rds")

createchange(traindata=traindata, snapshot=sep15,jj=6)

traindata_upd$DiffNumProds_pr_6<-traindata_upd$NumProds-traindata_upd$NumProds_pr_6
traindata_upd$DiffNumProds_pr_6[is.na(traindata_upd$DiffNumProds_pr_6)]<- -99
sep_upd<-traindata_upd[,c(1,22:34)]

jun15<-readRDS("jun15_clean.rds")
createchange(traindata=traindata, snapshot=jun15,jj=9)

traindata_upd$DiffNumProds_pr_9<-traindata_upd$NumProds-traindata_upd$NumProds_pr_9
traindata_upd$DiffNumProds_pr_9[is.na(traindata_upd$DiffNumProds_pr_9)]<- -99
jun_upd<-traindata_upd[,c(1,22:34)]

mar15<-readRDS("mar15_clean.rds")
createchange(traindata=traindata, snapshot=mar15,jj=12)

traindata_upd$DiffNumProds_pr_12<-traindata_upd$NumProds-traindata_upd$NumProds_pr_12
traindata_upd$DiffNumProds_pr_12[is.na(traindata_upd$DiffNumProds_pr_12)]<- -99
mar_upd<-traindata_upd[,c(1,22:34)]


train_clean_minus3<-readRDS("train_clean_minus3.rds")
train_clean_minus36<-merge(train_clean_minus3,sep_upd,by="ncodpers",all.x = TRUE)
train_clean_minus369<-merge(train_clean_minus36,jun_upd,by="ncodpers",all.x = TRUE)
train_clean_minus36912<-merge(train_clean_minus369,mar_upd,by="ncodpers",all.x = TRUE)

saveRDS(train_clean_minus36912,"train_clean_minus36912.rds")
