######################################################
## This file has been created by Alexandre Courtiol ##
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

## Updating old status
## Status should be DD (data deficient) or LC > NT > VU > EN > CR > EW > EX

  table2[Status %in% c("CR(PE)"), Status := "CR"]
  table2[Status %in% c("LR/cd", "LR/nt"), Status := "NT"]
  table2[Status %in% c("LR/lc", "LC/VU"), Status := "LC"]
  table2[Status %in% c("I"), Status := "DD"]  ## Not sure about that...
  table2[Status %in% c("NR"), Status := "NA"]
  table2$Status[table2$Status == "NA"] <- NA
  table2$Status <- factor(table2$Status)
  levels(table2$Status)[!levels(table2$Status) %in% c("DD", "LC", "NT", "VU", "EN", "CR", "EW", "EX")]

  table3[Status %in% c("Critically Endangered", "Critically Endangered      (Possibly Extinct)", "CR(PE)"), Status := "CR"]
  table3[Status %in% c("Endangered"), Status := "EN"]
  table3[Status %in% c("Vulnerable"), Status := "VU"]
  table3[Status %in% c("LR/lc", "Least Concern"), Status := "LC"]
  table3[Status %in% c("LR/cd", "LR/nt", "Near Threatened"), Status := "NT"]
  table3[Status %in% c("I", "K", "Data Deficient"), Status := "DD"]  ## Not sure about that...
  table3[Status %in% c("NR"), Status := "NA"]
  table3$Status[table3$Status == "NA"] <- NA
  table3$Status <- factor(table3$Status)
  levels(table3$Status)[!levels(table3$Status) %in% c("DD", "LC", "NT", "VU", "EN", "CR", "EW", "EX")]

## Species to remove
  Sp_to_remove <- c(
    "Garrulax courtoisi",
    "Procellaria conspicillata",
    "Psittacus erithacus")  ## Species were taxonomically split and therefore status occurring before is thus unknown
  Sp_to_remove <- c(Sp_to_remove,
    "Heteromirafra sidamoensis",  ## Species name was changed in 2013
        "Podocarpus barretoi")  ## Discarded taxonomic concept
  Sp_to_remove <- c(Sp_to_remove,
    "Corvus unicolor",
    "Podocarpus costaricensis",
    "Lipotes vexillifer",
    "Aythya innotata",
    "Melamprosops phaeosoma"
  )  ## Species that did not change in 2007 in species info
  
  # Note:   "Sarcogyps calvus" inconsistent but website is correct (IUCN communication)


  table2 <- table2[!Species %in% Sp_to_remove, ]
  table3 <- table3[!Species %in% Sp_to_remove, ]

## Comparison of Alia's table Vs Table 2 that had been manually computed
  table(table2$Status)
  2*table(table3$Status)

  table(unique(table2$Species) %in% unique(table3$Species))
  table(unique(table3$Species) %in% unique(table2$Species))
  unique(table2$Species)[!unique(table2$Species) %in% unique(table3$Species)]
  unique(table3$Species)[!unique(table3$Species) %in% unique(table2$Species)]


  for(y in unique(table2$Years)){
    for(s in unique(table2$Species)){
      test <- unique(as.character(table2[Years==y & Species==s & !is.na(Status)==TRUE, Status])) != as.character(table3[Years==y & Species==s & !is.na(Status)==TRUE, Status])
      if(length(test) > 1) stop(paste("Bug caused by student discrepancies", s, y))
      if(length(test)>0 && test==TRUE)
        print(cbind(who=c("Students", "Students", "Alia"), rbind(
          table2[Years==y & Species==s, data.frame(Species, Years, Status)],
          table3[Years==y & Species==s, data.frame(Species, Years, Status)])))
    }
  }

  for(y in unique(table2$Years)){
    for(s in unique(table2$Species)){
      test <- unique(is.na(table2[Years==y & Species==s, Status])) != unique(is.na(table3[Years==y & Species==s, Status]))
      if(length(test) > 1) stop(paste("Bug caused by student discrepancies", s, y))
      if(length(test)>0 && test==TRUE)
        print(cbind(who=c("Students", "Students", "Alia"), rbind(
          table2[Years==y & Species==s, data.frame(Species, Years, Status)],
          table3[Years==y & Species==s, data.frame(Species, Years, Status)])))
    }
  }

#table2[table2$Species == "Heteromirafra sidamoensis" & table2$Years==1998, ]
#table3[table3$Species == "Heteromirafra sidamoensis" & table3$Years==1998, ]


## Let's explore the status
  table(table3$Status)
  unique(table3[which(table3$Status == "R"), Species])


## Let's replace status by NO before IUCN inclusion 
  for(y in unique(table3$Years)){
    for(s in unique(table3$Species)){
      firstyear <- table1[Species==s, FirstYearIUCN][1]
      if(!is.na(firstyear) & y < firstyear)
        table3[Years==y & Species==s & is.na(Status)==TRUE, Status := "NO"]
    }
  }

  table3$Status <- factor(table3$Status)
  table(table3$Status, useNA="always")

## Let's look at the one who did not change between 2006 and 2007
    for(s in unique(table3$Species)){
      if(any(table3[Species == s & Years == 2006, Status] == table3[Species == s & Years == 2007, Status]))
        print(s)
      }


## Let's compute the number of classification changes per species
  tableNbClass <- dcast(table3, Species ~ ., 
    fun=function(x) length(unique(as.character(x[!is.na(x)]))), value.var="Status")
  colnames(tableNbClass)[2] <- "ClassNb" 
  tableNbClass
  table(tableNbClass$ClassNb)

## Let's change the format of the table
  table3[Status=="LC", Status := "1_LC"]
  table3[Status=="NT", Status := "2_NT"]
  table3[Status=="VU", Status := "3_VU"]
  table3[Status=="EN", Status := "4_EN"]
  table3[Status=="CR", Status := "5_CR"]
  table3[Status=="EW", Status := "6_EW"]
  table3[Status=="EX", Status := "7_EX"]
  table3[Status=="R", Status := "8_R"]
  table3[Status=="DD", Status := "9_DD"]
  table3[Status=="NO", Status := "10_NO"]
  table3$Status <- factor(table3$Status)
  table(table3$Status)

  table3wide <- dcast(table3, Species ~ Years, fun=function(x) unique(as.character(x))[1], value.var="Status")
  table3wide
  table3wide["Aeshna persephone", ]
  
  table3wideNumeric <- dcast(table3, Species ~ Years, fun=function(x) paste(as.numeric(x[1]), collapse=""), value.var="Status")
  table3wideNumeric[, !c("Species"), with=FALSE]

## Let's plot the changes

  table(table3$Status)

  par(las=2, mar=c(5,5,1,1), mgp=c(4,1,0))
  plot(as.numeric(table3wideNumeric[1, !c("Species"), with=FALSE])~ I(1998:2015),
   type="l", ylim=c(1,length(levels(table3$Status))), ylab="IUCN changes", xlab="years", axes = FALSE)
  for(i in 1:nrow(table3wideNumeric))
    points(as.numeric(table3wideNumeric[i, !c("Species"), with=FALSE])~ I(1998:2015), type="l")
  axis(1, at=1998:2015)
  axis(2, at=1:length(levels(table3$Status)), labels = levels(table3$Status))
