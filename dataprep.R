## This takes the Santander Dataset and preps it for initial analysis
## data can be sourced here https://www.kaggle.com/c/santander-product-recommendation


library(data.table)
library(tidyr)
library(dplyr)
library(microbenchmark)
library(shiny)

setwd("C:/Users/James/Documents/James/Data Science/SantanderPrediction/doublecheck/")

#note that this data set is just under 3GB and takes upto 15 minutes to load
        #it is almost 1m customer records for 18 months
zipdf<-unzip("train_ver2.csv.zip")
df<-fread("train_ver2.csv",nrows=-1)

#we are informed that we have monthly cuts of customer data from Jan 2015 and 
#we need to predict what they would have in June 2016
#given this is being run outside of the competition, we set the test set as 
#May 2015 instead

test<-df[df$fecha_dato=="2016-05-28",]
        #saved so you can follow my process but already loaded                
        saveRDS(test,"test.rds")

#setting up the train data set


#The original comp was asking who would purchase a new product, 
#There are two options to do this
        #1 take the month prior to test as the basis of training and 
                #try to use the past to predict
        #2 take 2 months prior to test as base and look forward
                #this gives the flexibility of being able to not only id if the
                #customer bought something new, but if they cancelled

#Number 2 gives more options and is what I do below

train<-df[df$fecha_dato=="2016-03-28",]
        #saved so you can follow my process but already loaded        
        #saveRDS(train,"train.rds")
#labelled as minus 1 but is actually lookng forwards
minus1_1<-df[df$fecha_dato=="2016-04-28",]
        #saved so you can follow my process but already loaded        
        #saveRDS(minus1_1,"minus1_1.rds")
        
#relabel the columns to be able to merge the data for one row per customer
        #minus1_1<-minus1
colnames(minus1_1)<-paste(colnames(minus1_1),"1",sep="_")

minus1_2<-rename(minus1_1, ncodpers  = ncodpers_1)

#merge and keep all in train to keep those who cancel
train1<-merge(train, minus1_2, by="ncodpers", all.x = TRUE)

#focus only on the products from the future month
minus1_red<-train1[,49:95]
minus1_red$ncodpers<-train1$ncodpers

#align structures of data to be able to identify what changes from 
#one month to the next
train1<-select(train1,ncodpers, everything())
minus1_red<-select(minus1_red,ncodpers, everything())
train2<-train1[,1:48]

change_1<-ifelse(train2==minus1_red,0,1)
change_2<-as.data.frame(change_1)

change_2$row<-rownames(change_2)

#clean up the environment
rm(change_1,minus1_1,minus1_2,minus1_red,train1, train2)
        

#Summarise what has changed and how much changed
change_2$Changed<-ifelse(rowSums(change_2[,25:48])>=1,1,0)
change_2$Num_changes<-rowSums(change_2[,25:48])

#Clean column names for the changes
colnames(change_2)<-paste(colnames(train),"change",sep = "_")
nam<-c("row","Changed","Num_Changes")
colnames(change_2)[49:51]<-nam
colnames(change_2)[2]<-"ncodpers"

#the change data doesn't have the customer number so its added backhere
change_2$ncodpers<-train$ncodpers

#combine changes to the original train data set, all x so keep cancellors
trainchange<-merge(train, change_2, by="ncodpers", all.x = TRUE)

#saving the data work to date
        # saveRDS(trainchange,file="trainchange.rds")
        # trainchange<-readRDS(file="trainchange.rds")

#for those who boght something new, id what they purchased
df2<-trainchange[trainchange$Changed==1,]
#focus on the products they bought
Prods<-df2[,72:95]

#each product is a binary if they bought it
#this enters the columns name into NewProds if it was bought
NewProds = do.call(
        paste,
        c(mapply(ifelse,
                 Prods,
                 names(Prods),
                 MoreArgs = list(no = ""),
                 SIMPLIFY = FALSE),
          sep = "//"))

df2$NewProds<-NewProds

#Newprods adds in splits (//)even when no new product has been purchased.  
#This means NewProds as is, is not very legible.  This code improves the 
#legibility of the variable

for (i in 3:24){
        val<-paste(rep("/",i),collapse = "")
        df2$NewProds<-gsub(val,"//",df2$NewProds)
}
for (i in 3:4){
        val<-paste(rep("/",i),collapse = "")
        df2$NewProds<-gsub(val,"",df2$NewProds)
}

#merging the data which shows the NewProds where purchased and cleaning up 
#the NAs
df2_red<-select(df2,c("ncodpers","NewProds"))
trainchange1<-merge(trainchange,df2_red, by="ncodpers",all.x = TRUE)
trainchange1$Num_Changes[is.na(trainchange1$ind_pres_fin_ult1_change)]<-(-1)
trainchange1$Changed[is.na(trainchange1$ind_pres_fin_ult1_change)]<-(-1)
trainchange1$NewProds[is.na(trainchange1$ind_pres_fin_ult1_change)]<-c("Lost_Cust")
trainchange1$NewProds[is.na(trainchange1$NewProds)]<-c("No_Change")

saveRDS(trainchange1,"trainchange1.rds")


