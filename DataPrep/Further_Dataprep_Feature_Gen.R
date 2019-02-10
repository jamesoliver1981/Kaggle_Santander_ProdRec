##Further data prep
#There is no free lunch so now need to create more data to see if there are
# characteristics which explain change

#Most simple way to do this will be to grab data which is prior to the trainset
#and see how things have changed in the past and if they explain the change

#Have 18 month of data - take 3 month snapshots of data, find difference, append
#read in the data and get create and save data sets to speed up replicability
library(dplyr)
library(data.table)
setwd("C:/Users/James/Documents/James/DataScience/SantanderPrediction")
train<-readRDS("train.rds")

df<-fread("train_ver2.csv",nrows=-1)

dec15<-df[df$fecha_dato=="2015-12-28",]
sep15<-df[df$fecha_dato=="2015-09-28",]
jun15<-df[df$fecha_dato=="2015-06-28",]
mar15<-df[df$fecha_dato=="2015-03-28",]

#repeat for April as need for test set
jan16<-df[df$fecha_dato=="2016-01-28",]
oct15<-df[df$fecha_dato=="2015-10-28",]
jul15<-df[df$fecha_dato=="2015-07-28",]
apr15<-df[df$fecha_dato=="2015-04-28",]

setwd("C:/Users/James/Documents/James/DataScience/SantanderPrediction/Kaggle_Santander_ProdRec/data")
#save files so can source them later for ease
saveRDS(dec15,"dec15.rds")
saveRDS(sep15,"sep15.rds")
saveRDS(jun15,"jun15.rds")
saveRDS(mar15,"mar15.rds")
saveRDS(jan16,"jan16.rds")
saveRDS(oct15,"oct15.rds")
saveRDS(jul15,"jul15.rds")
saveRDS(apr15,"apr15.rds")

train<-readRDS("train.rds")
dec15<-readRDS("dec15.rds")
sep15<-readRDS("sep15.rds")
jun15<-readRDS("jun15.rds")
mar15<-readRDS("mar15.rds")

#build as function, which takes one of the above snapshots, 
createchange<-function(traindata=train,snapshot,jj) {
#merge the train & snapshot, keep all.x - ensures all aligned for doing diff
        colnames(snapshot)<-paste(colnames(snapshot),jj,sep="_")
#which column should this be in
        colnames(snapshot)[2]<-"ncodpers"
        traindata1<-traindata[,1:48]
        train1<-merge(traindata1,snapshot,by="ncodpers", all.x=TRUE)
#split the data up
        snapshot1<-train1[,49:95]
        snapshot1$ncodpers<-train1$ncodpers
#align data
        train1<-select(train1,ncodpers, everything())
        snapshot1<-select(snapshot1,ncodpers, everything())
        train2<-train1[,1:48]
        
#create a change
        change_1<-ifelse(train2==snapshot1,0,1)
        change_2<-as.data.frame(change_1)
        colnames(change_2)<-paste(colnames(change_2),"pr",jj,sep="_")
        #need to recreate ncodpers and then merge
        colnames(change_2)[1]<-"ncodpers"
        change_2$ncodpers<-train2$ncodpers
        #no need for change in date - it always changes - overwrite with if
        #customer is a new customer at this point or not
        colnames(change_2)[2]<-paste("ExistingCust_at_pr",jj,sep="")
        change_2[2]<-ifelse(is.na(change_2[2]),0,1)
        
        train<<-merge(train,change_2,by="ncodpers",all.x = TRUE)
}
createchange(traindata=train, snapshot=dec15,jj=3)
createchange(traindata=train, snapshot=sep15,jj=6)
createchange(traindata=train, snapshot=jun15,jj=9)
createchange(traindata=train, snapshot=mar15,jj=12)
saveRDS(train,"train_with_history.rds")

#start investigating what could drive the change
#split customers into those who have changed and those who haven't
#and look at distributions


