######################################################
## This file has been created by Alexandre Courtiol ##
######################################################

## Let's prepare the session
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


## Species to remove
  Sp_to_remove <- c(
    "Garrulax courtoisi",
    "Procellaria conspicillata",
    "Psittacus erithacus")  ## Species were taxonomically split and therefore status occurring before is thus unknown
  Sp_to_remove <- c(Sp_to_remove,
    "Heteromirafra sidamoensis",
    "Sarcogyps calvus")  ## Inconsistency between list and species info
  Sp_to_remove <- c(Sp_to_remove,
    "Corvus unicolor",
    "Podocarpus costaricensis",
    "Lipotes vexillifer",
    "Aythya innotata",
    "Melamprosops phaeosoma",
    "Podocarpus barretoi"
  )  ## Species that did not change in 2007 in species info
  
  table2 <- table2[!Species %in% Sp_to_remove, ]


## Let's explore the status
  table(table2$Status)
  unique(table2[which(table2$Status == "R"), Species])

## Let's look for inconsistencies between students without NA differences
  for(y in unique(table2$Years)){
    for(s in unique(table2$Species)){
      if(length(unique(table2[Years==y & Species==s & is.na(Status)==FALSE, Status]))>1) 
        print(table2[Years==y & Species==s])
    }
  }

## Let's look for inconsistencies between students with NA differences
#student <- c("Christina", "Anita")
#student <- c("Juliane", "Sita")
  for(y in unique(table2$Years)){
    for(s in unique(table2$Species)){
      if(length(unique(table2[Years==y & Species==s, Status]))>1) 
        print(table2[Years==y & Species==s])
    }
  }

## Let's look for inconsistencies between table1 and table2
  Species_inconsitancies_firstyear <- NULL
  for(y in unique(table2$Years)){
    for(s in unique(table2$Species)){
      firstyear <- table1[Species==s, FirstYearIUCN][1]
      if(!is.na(firstyear) & y < firstyear &
        nrow(table2[Years==y & Species==s & is.na(Status)==FALSE]) > 0)
          Species_inconsitancies_firstyear <- c(Species_inconsitancies_firstyear, s)
    }
  }
  unique(Species_inconsitancies_firstyear)

## Let's replace status by NO before IUCN inclusion 
  for(y in unique(table2$Years)){
    for(s in unique(table2$Species)){
      firstyear <- table1[Species==s, FirstYearIUCN][1]
      if(!is.na(firstyear) & y < firstyear)
        table2[Years==y & Species==s & is.na(Status)==TRUE, Status := "NO"]
    }
  }

  table(table2$Status, useNA="always")


## Let's look at the one who did not change between 2006 and 2007
    for(s in unique(table2$Species)){
      if(any(table2[Species == s & Years == 2006, Status] == table2[Species == s & Years == 2007, Status]))
        print(s)
      }


## Let's compute the number of classification changes per species
  tableNbClass <- dcast(table2, Species ~ ., 
    fun=function(x) = length(unique(as.character(x[!is.na(x)]))), value.var="Status")
  colnames(tableNbChanges)[2] <- "ClassNb" 
  tableNbChanges
  table(tableNbChanges$ClassNb)

## Let's change the format of the table
  table2[Status=="LC", Status := "1_LC"]
  table2[Status=="NT", Status := "2_NT"]
  table2[Status=="VU", Status := "3_VU"]
  table2[Status=="EN", Status := "4_EN"]
  table2[Status=="CR", Status := "5_CR"]
  table2[Status=="EW", Status := "6_EW"]
  table2[Status=="EX", Status := "7_EX"]
  table2[Status=="R", Status := "8_R"]
  table2[Status=="DD", Status := "9_DD"]
  table2$Status <- factor(table2$Status)

  table2wide <- dcast(table2, Species ~ Years, fun=function(x) unique(as.character(x))[1], value.var="Status")
  table2wide
  table2wide["Aeshna persephone", ]
  
  table2wideNumeric <- dcast(table2, Species ~ Years, fun=function(x) paste(as.numeric(x[1]), collapse=""), value.var="Status")
  table2wideNumeric[, !c("Species"), with=FALSE]

## Let's plot the changes

  table(table2$Status)

  par(las=2, mar=c(5,5,1,1), mgp=c(4,1,0))
  plot(as.numeric(table2wideNumeric[1, !c("Species"), with=FALSE])~ I(1998:2015),
   type="l", ylim=c(1,length(levels(table2$Status))), ylab="IUCN changes", xlab="years", axes = FALSE)
  for(i in 1:nrow(table2wideNumeric))
    points(as.numeric(table2wideNumeric[i, !c("Species"), with=FALSE])~ I(1998:2015), type="l")
  axis(1, at=1998:2015)
  axis(2, at=1:length(levels(table2$Status)), labels = levels(table2$Status))
