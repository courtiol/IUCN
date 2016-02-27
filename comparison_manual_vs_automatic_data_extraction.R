######################################################
## This file has been created by Alexandre Courtiol ##
## It compares data extracted manually but students ##
## to data extracted automatically                  ##
## by the python script made by Alia                ## 
######################################################

## Let's prepare the session
  setwd("/home/alex/Boulot/My_teaching/FU/Jens_course/Meta-analysis/Analysis/IUCN")
  rm(list=ls())  ## remove all objects in the R session
  library(RCurl) ## load a package to download from internet
  library(data.table) ## load a package to handle tables efficiently

## Let's import table 2 in R following http://www.r-bloggers.com/access-google-spreadsheet-directly-in-bash-and-in-r/
  table1address <- "https://docs.google.com/spreadsheets/d/1iw8QEJkduvAKbJebZkvFoBQRDxoBMLR93-7yz4L5Cd4/pub?gid=0&single=true&output=csv"
  table1 <- data.table(read.csv(textConnection(getURL(table1address))))
  table1

  table2address <- "https://docs.google.com/spreadsheets/d/1Xlkyj-QgeMnCPdHiZL-a6f8MCX456as1-HnmvIaeg1M/pub?gid=0&single=true&output=csv"
  table2 <- data.table(read.csv(textConnection(getURL(table2address))))
  table2

  #table3address <- "https://docs.google.com/spreadsheets/d/1Xlkyj-QgeMnCPdHiZL-a6f8MCX456as1-HnmvIaeg1M/pub?gid=1477935099&single=true&output=csv"
  table3 <- data.table(read.csv("Table2_auto.csv", header=FALSE))
  colnames(table3) <- c("Species", "Years", "Status")
  table3

## Comparison of Alia's table Vs Table 2 that had been manually computed
  table(table2$Status)
  2*table(table3$Status)

  table(unique(table2$Species) %in% unique(table3$Species))
  table(unique(table3$Species) %in% unique(table2$Species))
  #unique(table2$Species)[!unique(table2$Species) %in% unique(table3$Species)]
  #unique(table3$Species)[!unique(table3$Species) %in% unique(table2$Species)]

  for(y in unique(table2$Years)){
    for(s in unique(table2$Species)){
      test <- unique(as.character(table2[Years==y & Species==s & !is.na(Status)==TRUE, Status])) != as.character(table3[Years==y & Species==s & !is.na(Status)==TRUE, Status])
      if((length(test)>0 && test==TRUE) || (length(test) > 1) )
        print(cbind(who=c("Students", "Students", "Alia"), rbind(
          table2[Years==y & Species==s, data.frame(Species, Years, Status)],
          table3[Years==y & Species==s, data.frame(Species, Years, Status)])))
    }
  }

  for(y in unique(table2$Years)){
    for(s in unique(table2$Species)){
      test <- unique(is.na(table2[Years==y & Species==s, Status])) != unique(is.na(table3[Years==y & Species==s, Status]))
      if(length(test)>0 && test==TRUE || (length(test) > 1))
        print(cbind(who=c("Students", "Students", "Alia"), rbind(
          table2[Years==y & Species==s, data.frame(Species, Years, Status)],
          table3[Years==y & Species==s, data.frame(Species, Years, Status)])))
    }
  }

#table2[table2$Species == "Heteromirafra sidamoensis" & table2$Years==1998, ]
#table3[table3$Species == "Heteromirafra sidamoensis" & table3$Years==1998, ]
