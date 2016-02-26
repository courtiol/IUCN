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

  possible_status <- c("LC", "NT", "VU", "EN", "CR", "EW", "EX", "R", "DD", "NO")

  table3wide <- dcast(table3, Species ~ Years, fun=function(x) unique(as.character(x))[1], value.var="Status")
  table3wide
  table3wide["Aeshna persephone", ]
  
  table3$Status_nb <- unlist(lapply(strsplit(as.character(table3$Status), "_"), function(y) as.numeric(y[1])))

  table3wideNumeric <- dcast(table3, Species ~ Years, fun=function(x) unique(x)[1], value.var="Status_nb")

  table3wideNumeric[, !c("Species"), with=FALSE]

  tableNbClass$NbChanges <- NA
  for(i in 1:nrow(table3wideNumeric)){
	 m <- rbind(c(table3wideNumeric[i, ], NA), c(NA,table3wideNumeric[i, ]))[,-c(1,2,ncol(table3wideNumeric)+1)]
	changes <- apply(m, 2, function(x) as.numeric(x[2])- as.numeric(x[1]))
	tableNbClass$NbChanges[i] <- sum(changes != 0)
	}
 
 tableNbClass


## Let's plot the changes
  Nos <- apply(table3wide, 1, function(x) any(x=="10_NO"))

  table4txt <- table3wide[tableNbClass$NbChanges==1 & !Nos,]
  table4 <- table3wideNumeric[tableNbClass$NbChanges==1 & ! Nos,]
  table(table3$Status)

  table5 <- data.frame(
	Species=table4txt$Species,
	Status_before=unlist(table4txt[, 2, with=FALSE]),
	Status_after=unlist(table4txt[, ncol(table4txt), with=FALSE]),
	Status_before_nb=unlist(table4[, 2, with=FALSE]),
	Status_after_nb=unlist(table4[, ncol(table4txt), with=FALSE])
	)
  table5
  table5$Change <- NA
  for(i in 1:nrow(table5)){
	if(table5$Status_before[i]=="9_DD" & table5$Status_after[i]!="9_DD")
		table5$Change[i] <- "Gain_info"
	if(table5$Status_before[i]!="9_DD" & table5$Status_after[i]=="9_DD")
		table5$Change[i] <- "Loss_info"
	if(table5$Status_before[i]=="8_R" & table5$Status_after[i] %in% c("1_LC","2_NT"))
		table5$Change[i] <- "Better"
	if(table5$Status_before[i]=="8_R" & !table5$Status_after[i] %in% c("1_LC","2_NT"))
		table5$Change[i] <- "Unclear"
	if(!table5$Status_before[i] %in%c("8_R", "9_DD") &
	   !table5$Status_before[i] %in% c("8_R","9_DD") &
		table5$Status_before_nb[i] > table5$Status_after_nb[i])
		table5$Change[i] <- "Better"
		if(!table5$Status_before[i] %in%c("8_R", "9_DD") &
	   !table5$Status_after[i] %in% c("8_R","9_DD") &
		table5$Status_before_nb[i] < table5$Status_after_nb[i])
		table5$Change[i] <- "Worse"
	}
	
	 table5[is.na(table5$Change), ]

table( table5$Change)

# add starting date, ending date, date of change, so that Alia can use it, create also empty columns for info to add (citation number)


  par(las=2, mar=c(5,5,1,1), mgp=c(4,1,0))
  plot(as.numeric(table4[1, !c("Species"), with=FALSE])~ I(1998:2015), col=0,
   type="l", ylim=c(1,length(possible_status)), ylab="IUCN changes", xlab="years", axes = FALSE)
  for(i in 1:nrow(table4)){
	line <- as.numeric(table4[i, !c("Species"), with=FALSE])
    	points(line+runif(1,min=0,max=0.4)~ I(1998:2015), type="l", col=ifelse(any(line==9),1,1))
	}
  axis(1, at=1998:2015)
  axis(2, at=1:length(possible_status), labels = possible_status)

   table(unlist(table4txt[,2, with=F]), unlist(table4txt[,ncol(table4txt), with=F]))



