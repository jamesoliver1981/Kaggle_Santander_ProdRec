#Clean Data script
#Create function for one month - based on findings from explorative analysis

library(dplyr)

setwd("C:/Users/James/Documents/James/DataScience/SantanderPrediction/Kaggle_Santander_ProdRec/data")
list.files()
dataset<-readRDS("train.rds")
dataset<-sep15
cleanme<- function(dataset){
        
        #reduce to likely ages
                dataset<-dataset[dataset$age %in% 18:85,]
        #those under 25 seem to change more- create var to help model spot this
                dataset$Under25<-ifelse(dataset$age<25,1,0)
        #antiguedad is very peaky - highlight where this is 
        #if in first year
                dataset$antiguedad_lt12<-ifelse(dataset$antiguedad<12,1,0)
        #peaks
                dataset$antiguedad_peak<-ifelse(dataset$antiguedad %in% c(3:9,15:20,27:32,39:44),1,0)
        #if stopped being primary in month
                dataset$StopPrimary<-ifelse(dataset$ult_fec_cli_1t=="",1,0)
        # #restrict to 10 to reduce the size of the matrix-given over 95% of countries are Spain       
                top_countries<-readRDS("top_countries.rds")
                dataset$CountryRes<-ifelse(dataset$pais_residencia %in% top_countries, dataset$pais_residencia, "OTH")
                
        # #put in a top 12 as these are over 5000 each
                topchan<- readRDS("topchannels.rds")
                dataset$Channel<-ifelse(dataset$canal_entrada %in% topchan,dataset$canal_entrada,"OTH")
                
        #convert segmento to factor 
                dataset$segmento<-as.factor(dataset$segmento)
                
        #Num of Prods in portfolio
                dataset$NumProds<-rowSums(dataset[,25:48])
        #Create a variable showing what groups of products customers had
                Prods<-dataset[,25:48]
                
                #each product is a binary if they bought it
                #this enters the columns name into NewProds if it was bought
                AllProods = do.call(
                        paste,
                        c(mapply(ifelse,
                                 Prods,
                                 names(Prods),
                                 MoreArgs = list(no = ""),
                                 SIMPLIFY = FALSE),
                          sep = "//"))
                
                dataset$AllProds<-AllProods
                
                #Newprods adds in splits (//)even when no new product has been purchased.  
                #This means NewProds as is, is not very legible.  This code improves the 
                #legibility of the variable
                
                for (i in 3:24){
                        val<-paste(rep("/",i),collapse = "")
                        dataset$AllProds<-gsub(val,"//",dataset$AllProds)
                }
                for (i in 3:4){
                        val<-paste(rep("/",i),collapse = "")
                        dataset$AllProds<-gsub(val,"",dataset$AllProds)
                }
                
        #drop variables
                #ind_empleado is an employee - minimal
                #indrel_mes - duplicated by indrei,
                #ult_fec_cliu_1t - when cust stop being primary in month
                #tiprel_1mes less clean version of ind_activitdad
                #indresi - foreign resident - duplicate and less informative as pais res
                #conyuemp - spouse as employee 99% no
                #replaced with CountryRes
                #canal_entrada - keep those with most
                #indfall deceased - irrelevant for new prods
                #tipdom - is 100% (primary address)
                # cod prov - drop, duplicate of nom prov and not ordinal
                dataset<-select(dataset,-c(ind_empleado,indrel_1mes,ult_fec_cli_1t,tiprel_1mes, indresi,
                                           conyuemp,pais_residencia,canal_entrada,indfall,tipodom,cod_prov))
        
        #drop the product variables as will have them in combined variable
                dataset_clean<<-dataset[,-c(14:37)]
}

cleanme(dataset = dataset)
saveRDS(dataset_clean,"train_clean.rds")

dec15<-readRDS("dec15.rds")
cleanme(dataset = dec15)
saveRDS(dataset_clean,"dec15_clean.rds")

sep15<-readRDS("sep15.rds")
cleanme(dataset = sep15)
saveRDS(dataset_clean,"sep15_clean.rds")

jun15<-readRDS("jun15.rds")
cleanme(dataset = jun15)
saveRDS(dataset_clean,"jun15_clean.rds")

mar15<-readRDS("mar15.rds")
cleanme(dataset = mar15)
saveRDS(dataset_clean,"mar15_clean.rds")

