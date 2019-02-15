##Further data prep
#There is no free lunch so now need to create more data to see if there are
# characteristics which explain change

#Most simple way to do this will be to grab data which is prior to the trainset
#and see how things have changed in the past and if they explain the change

#Have 18 month of data - take 3 month snapshots of data, find difference, append
#read in the data and get create and save data sets to speed up replicability
library(dplyr)
library(data.table)
library(scales)
setwd("C:/Users/James/Documents/James/DataScience/SantanderPrediction/Kaggle_Santander_ProdRec/data")
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


#build as function, which takes one of the above snapshots, and compares to train and id a difference 
#and append - only a variance to the current month, vs different to what was there in the prior snapshot
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
        change_2[is.na(change_2)]<- -1
        train<<-merge(train,change_2,by="ncodpers",all.x = TRUE)
}
createchange(traindata=train, snapshot=dec15,jj=3)
createchange(traindata=train, snapshot=sep15,jj=6)
createchange(traindata=train, snapshot=jun15,jj=9)
createchange(traindata=train, snapshot=mar15,jj=12)
saveRDS(train,"train_with_history.rds")
trainplus<-readRDS("train_with_history.rds")


#start investigating what could drive the change
#split customers into those who have changed and those who haven't
#and look at distributions

#Features to look at
#have the values for certain things like renta and age etc changed
        #renta create an appropriate inputted values

#Identify those variables which never change and drop them
m2m<-colSums(trainplus[,49:236]==0)
m2m<-as.data.frame(m2m)

#Number of change is limited to the max of those who were in existance then
MaxVal<-as.data.frame(colSums(trainplus[,49:236] !=-1))
m2m$MaxVal<-MaxVal$`colSums(trainplus[, 49:236] != -1)`
m2m$DropVars<-ifelse(m2m$m2m==m2m$MaxVal,"Drop","OK")
m2m$Vars<-rownames(m2m)

m2m$prop_Same<-percent(m2m$m2m/m2m$MaxVal)
DropVars<-m2m$Vars[m2m$DropVars=="Drop"]
DropVars
#customer classification never changes, and neither does their joint income - assume gathered when join
# customers address type doesn't ever change either
#surprising
        #Gender changes - do other changes happen here?
        #Date when customer became a customer of the bank
dim(trainplus[trainplus$sexo_pr_6==1,])[1]
dim(trainplus[trainplus$fecha_alta==1,])[1]

#additional to drop -
        #antiguedad - customer seniority in months - will always grow


trainplus2<-select(trainplus,-DropVars)
trainplus2<-trainplus2 %>% select(-starts_with("antiguedad_pr"))
#dropped a bunch
#shows that there are a lot of new customers  - maybe that is something to
#look at and understand how many people change from whether they are new 
#or older

#given inability of models to use factors - probably need to find a way of encoding the first customer date
        #currently a date - rise to too many factors

#Given number of na's in renta is over 25%, some cleaning/imputting will be needed
sapply(trainplus2[,1:48], function(y) sum(length(which(is.na(y)))))


#create a view on how often changed - up and down for products - 
        #how to get a cleaner view of this so model doesn't need so many variables

#how near to birthday? Do people change at certain times in their life?  Age range yes no?

#What products are bought together?  Does this highlight types of groups?

#read in trainchange as this has the label for if something changed in the subsequent month
trainchange1<-readRDS("trainchange1.rds")

trainlabel<-select(trainchange1, c("ncodpers","Changed"))

trainplus3<-merge(trainplus2,trainlabel,by="ncodpers",all.x = TRUE)
saveRDS(trainplus3,"trainplus_label.rds")



