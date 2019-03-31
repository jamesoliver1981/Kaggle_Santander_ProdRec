##Explorative Analysis 
##The start point here is the Shiny app (https://jamesoliver1981.shinyapps.io/santander_distributions_and_pivots/)
#The data is then further analysed here:
library(dplyr)
library(reshape2)
library(ggplot2)
options(scipen = 999)
#Age
#Shiny apps show that a number of customers are under 18 and also that a number are over 85 up to 117

#Those under 18 are not possible, and those up to 117 are questionable.  Look at their conversion rates

setwd("C:/Users/James/Documents/James/DataScience/SantanderPrediction/Kaggle_Santander_ProdRec/data")
df<-readRDS("trainchange1.rds")
veryyoung<-df[df$age < 18,]
older<-df[df$age > 85,]

agecheck<-rbind(veryyoung,older)
agecheck2<-group_by(agecheck,age)

out<-summarize(agecheck2,

          total.count = n(),
          Num_Changed = sum(Changed),
          Conversion = Num_Changed/total.count)
midage<-group_by(df[df$age %in% 18:75,], age)
summarize(df[df$age %in% 18:75,],
          total.count = n(),
          Num_Changed = sum(Changed),
          Conversion = Num_Changed/total.count)

#drop those under 18 and those over 85 - as represent 2,5% of customers
df2<-df[df$age %in% 18:85,]

#renta has 220k of missing values - this cannot be dropped as this is 24% of the customers
        #alt create a 
nrow(df[is.na(df$renta),])/nrow(df)
rent<-table(df2$renta)
summary(df2$renta)
# plot
df2$GroupedAge<-ifelse(df2$age<30,"20-29",ifelse(df2$age<40,"30-39",ifelse(df2$age<50,"40-49",
                        ifelse(df2$age<60,"50-59",ifelse(df2$age<70,"60-69","70+")))))

rent<-melt(df2[complete.cases(df2$renta),],id.vars = "GroupedAge", measure.vars ="renta" )
ggplot(rent, aes(x=GroupedAge, y=value, fill=GroupedAge)) +
        geom_boxplot(alpha=0.4) +
        stat_summary(fun.y=mean, geom="point", shape=20, size=10, color="red", fill="red") +
        theme(legend.position="none") +
        scale_fill_brewer(palette="Set3")

#everything is stuck at zero - likely due to the scale
tapply(df2$renta, df2$GroupedAge, summary)
#note the max is often the same for these groups!! Suggests incorrect data here

df2[complete.cases(df2$renta),] %>% group_by(GroupedAge) %>% 
        summarize(d1=quantile(renta, 0.1), d9=quantile(renta, 0.9))

#restrict to those who have joint income under 250k
smallrenta<-df2[df2$renta <250000,]
tapply(smallrenta$renta,smallrenta$GroupedAge, summary)
#Not huge variation - try a diferent grouping
missrent<-df2[is.na(df2$renta),]
View(missrent %>% group_by(pais_residencia) %>% summarise(count= n()))
#97%  in spain therefore look at regional values
View(missrent %>% group_by(nomprov) %>% summarise(count= n()))

tapply(smallrenta$renta,smallrenta$nomprov, summary)
tapply(df2$renta,df2$nomprov, summary)
rent<-melt(smallrenta[complete.cases(smallrenta$renta),],id.vars = "nomprov", measure.vars ="renta" )
ggplot(rent, aes(x=nomprov, y=value, fill=nomprov)) +
        geom_boxplot(alpha=0.4) +
        stat_summary(fun.y=mean, geom="point", shape=20, size=10, color="red", fill="red") +
        theme(legend.position="none") +
        scale_fill_brewer(palette="Set3")
#good variation here - use to imput the values

renta_ref<-df2[complete.cases(df2$renta),] %>% group_by(nomprov) %>% 
        summarize(mean_renta=mean(renta), median_renta=median(renta))

df3<-merge(df2,renta_ref, by= "nomprov", all.x = TRUE)
df3$renta_mean<-ifelse(complete.cases(df3$renta),df3$renta,df3$mean_renta)
df3$renta_median<-ifelse(complete.cases(df3$renta),df3$renta,df3$median_renta)
df4<-select(df3,-c(renta,median_renta,mean_renta ))

#consider one by age


#antiguedad is the seniority of customers but this distribution appears to be not very peaky
#peaks is 4-8 (dec - Sep),(15-20 (jan-august),28-32 (dec-august),40-44 (nov-july)
#then splitting by changed, shows that those in those periods tend to have purchased more
        #more so the further back in history we go
        # build a binary variable, if customer began in August to December
        #add a varialble for how many years they are a customer too
anti<-group_by(df2,antiguedad)
View(summarise(anti,total.count = n(),
                 Num_Changed = sum(Changed),
                 Conversion = Num_Changed/total.count))
#antiguedad less than 12 have significantly higher conversions - create a binary variable for that
df4$antiguedad_lt12<-ifelse(df4$antiguedad<12,1,0)
df4$antiguedad_peak<-ifelse(df4$antiguedad %in% c(3:9,15:20,27:32,39:44),1,0)

NewFeatures<-select(df4,c(ncodpers,antiguedad_lt12,antiguedad_peak,renta_median,renta_mean ))

saveRDS(NewFeatures,"NewFeatures1.rds")

##To Do
#age - under 25 flag
#does antiguedad line up with days since becoming customer (fecha_alta?)

#ind_empleado is all N?  Look at full data set and check - is the cust an employee
#same proportion of genders

#ind_neuvo slightly higher proportion of customers who are new customers in changed
        #still 90 10 though - should be built in via new in last year from antiguedad
#indrei - primary customer -99% -drop here but worth looking at history

#pais residencia - 99% are in spain - but large variation outside this...
        #should be captured by matrix 

#indrel_mes -customer type - drop / duplicate to indrei

# ult_fec_cliu_1t - when in month the customers stopped being a primary - drop

#tiprel_1mes - active or inactive cusotmer status.  Similar distribution
        #drop less clean version of ind_activitdad

#indext - foreign born - similar
#indresi - drop - if customer is resident (repeat from country res)

#conyuemp has employee spouse - 99% no - drop

#canal entrada - many small areas - drop those under 1000.  
#Remaining 7 have different values

#indfall deceased - irrelevant -drop
#tipdom  -all primary address - drop
#cod prov - numerical version of nomprov - drop not ordinal
#nom prov - disitrubtion, keep.
        #might be interesting to try to group these by populous / growth to create distinctions

#ind_activitdad Cliente - repeat of tiprel_1mes - use this as cleaner

#segmento - convert to factor as not ordinal

#products, either very heavy or very limited values - 
#therefore combine to create combinations which might have variation -
#look at distribution of those combis - see if have a difference - reduces required tree depth

#add in number of products they have

#create a function which does this cleaning for one month
        #can then blend together in similar way to what already done


#Viewing the data that is now cleaned and have added history to it
        #need to look at what the top product combinations are and keep those - over 2000 cannot list

#ind_actividad_cliente_pr_3, some small difference

#ind_nuevo new customer in last 3 months - little higher - slightly misrep
        #change just looks at if different (if was new and wasn't)
#segmento_pr_3 - small change
#stopPrimary_pr_3 - minimal but relevant

#Channel changes for a minorty - unlikely to be important but try
#Those who changed number of prods in the past were slightly more likely to purchase again
        #this is the same information in change in All prods - therefore add back in the number of prods had before
                #then calculate the difference in the number of products to now


#indrel_pr3
#variables to drop
        #antiguedad_3
        #indext
        #indrel_pr3 - no change 
        #nom_prov_pr_3
        #renta_pr_3
        #antiguedad_lt12_pr_3 antigueded_peak_pr_3 - not relevant for now
        #countryres_pr_3



