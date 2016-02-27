######################################################
## This file has been created by Alexandre Courtiol ##
## It prepares the table for the analysis     `     ##
######################################################
  
  #setwd("/home/alex/Boulot/My_teaching/FU/Jens_course/Meta-analysis/Analysis/IUCN")
  rm(list=ls())  ## remove all objects in the R session
  library(data.table) ## load a package to handle tables efficiently

  table.raw <- data.table(read.csv("Table2_auto.csv", header=FALSE))
  colnames(table.raw) <- c("Species", "Years", "Status")
  table.raw

  first.year <- 1998
  last.year <- 2015
  year.change <- 2007 ## for change 2006/2007

  possible_status <- c("LC", "NT", "VU", "EN", "CR", "EW", "EX", "R", "DD", "NO")
  unique(table.raw$Status[!table.raw$Status %in% possible_status])  ## other status in raw table

## Updating old status (except "R" that is hard to convert into a new status)
  table.raw[Status %in% c("Critically Endangered", "Critically Endangered      (Possibly Extinct)", "CR(PE)"), Status := "CR"]
  table.raw[Status %in% c("Endangered"), Status := "EN"]
  table.raw[Status %in% c("Vulnerable"), Status := "VU"]
  table.raw[Status %in% c("LR/lc", "Least Concern"), Status := "LC"]
  table.raw[Status %in% c("LR/cd", "LR/nt", "Near Threatened"), Status := "NT"]
  table.raw[Status %in% c("I", "K", "Data Deficient"), Status := "DD"]  ## Not sure about that...
  table.raw[Status %in% c("NR"), Status := "NA"]
  table.raw[Status %in% c("NA", NA), Status := "NO"]

  table.raw$Status <- factor(table.raw$Status)
  if(length(levels(table.raw$Status)[!levels(table.raw$Status) %in% possible_status])!=0) {
    stop(paste("\n Strange status to change = ", paste(levels(table.raw$Status)[!levels(table.raw$Status) %in% possible_status], "\n", collpase=" ")))
  }

  table.raw[Status=="LC", Status := "1_LC"]
  table.raw[Status=="NT", Status := "2_NT"]
  table.raw[Status=="VU", Status := "3_VU"]
  table.raw[Status=="EN", Status := "4_EN"]
  table.raw[Status=="CR", Status := "5_CR"]
  table.raw[Status=="EW", Status := "6_EW"]
  table.raw[Status=="EX", Status := "7_EX"]
  table.raw[Status=="R", Status := "8_R"]
  table.raw[Status=="DD", Status := "9_DD"]
  table.raw[Status=="NO", Status := "10_NO"]

  table.raw$Status <- factor(table.raw$Status)
  table(table.raw$Status, useNA="always")

## Let's identify the species who did not change between year.change-1 and year.change
    Sp_to_remove <- NULL
    for(s in unique(table.raw$Species)){
      if(any(table.raw[Species == s & Years == (year.change-1), Status] == table.raw[Species == s & Years == year.change, Status])){
        warning(paste("no change for species", s))
        Sp_to_remove <- c(Sp_to_remove, s)
      }
      }

  # "Psittacus erithacus"  ## Species were taxonomically split and therefore status occurring before is thus unknown
  # "Heteromirafra sidamoensis"  ## Species name was changed in 2013
  # "Podocarpus barretoi"  ## Discarded taxonomic concept
  # "Corvus unicolor" ## Species that did not change in year.change in species info
  # "Podocarpus costaricensis" ## Species that did not change in year.change in species info
  # "Lipotes vexillifer" ## Species that did not change in year.change in species info
  # "Aythya innotata" ## Species that did not change in year.change in species info
  # "Melamprosops phaeosoma" ## Species that did not change in year.change in species info
  # Note:   "Sarcogyps calvus" inconsistent but website is correct (IUCN communication)


## Let's identify the species that do not have complete information since beginning
    for(s in unique(table.raw$Species)){
      if(table.raw[Species == s & Years == first.year, Status] == "10_NO"){
        warning(paste("no complete info for species", s))
        Sp_to_remove <- c(Sp_to_remove, s)
      }
      }

  print(paste("Sp_to_remove = "))
  print(paste(unique(Sp_to_remove)))
  table.raw2 <- table.raw[!Species %in% unique(c(Sp_to_remove)), ]
  table(table.raw2$Status, useNA="always")

## Let's transform the table into a wide table
  table.raw2wide <- dcast(table.raw2, Species ~ Years, fun=function(x) as.character(x)[1], value.var="Status")
  table.raw2wide
  #table.raw2wide["Aeshna persephone", ]
  
## Let's also do a numeric wide table to plot
  table.raw2$Status_nb <- unlist(lapply(strsplit(as.character(table.raw2$Status), "_"), function(y) as.numeric(y[1])))
  table.raw2wideMumeric <- dcast(table.raw2, Species ~ Years, fun=function(x) unique(x)[1], value.var="Status_nb")

  possible_status2 <- possible_status[possible_status != "NO"]
  possible_years <- as.numeric(names(table.raw2wideMumeric[1, !c("Species"), with=FALSE]))

## Let's create a function to draw plots
  plotIUCN <- function(filename, data, year.change) {
    pdf(paste(filename, year.change, ".pdf", sep=""))
      par(las=2, mar=c(6,6,0,1), mgp=c(4,1,0))
      plot(as.numeric(data[1, !c("Species"), with=FALSE])~ possible_years, col=0,
       type="l", ylim=c(0.5,length(possible_status2)+1), ylab="IUCN Status", xlab="years", axes = FALSE)
      for(i in 1:nrow(data)){
      line <- as.numeric(data[i, !c("Species"), with=FALSE])
          points(line+runif(1,min=-.2,max=0.2)~ possible_years, type="l", col=ifelse(any(line==9),1,1))
      }
      axis(1, at=possible_years)
      axis(2, at=1:length(possible_status2), labels = possible_status2)
    dev.off()
  }

## Let's plot
  plotIUCN(filename="All_changes", data=table.raw2wideMumeric, year.change=year.change)

## Let's compute number of status changes within species
  table.raw2wide$NbChanges <- NA
  for(i in 1:nrow(table.raw2wide)){
   m <- rbind(c(table.raw2wide[i, ], NA), c(NA,table.raw2wide[i, ]))[,-c(1, 2, ncol(table.raw2wide),ncol(table.raw2wide)+1)]
  changes <- apply(m, 2, function(x) as.character(x)[2]==as.character(x)[1])
  table.raw2wide$NbChanges[i] <- sum(!changes)
  }
 
 table.raw2wide

## Let's plot again
  plotIUCN(filename="Single_changes",
    data=table.raw2wideMumeric[table.raw2wide$NbChanges==1,],
    year.change=year.change)

## Let's create the final table

  table.temp <- table.raw2wide[NbChanges==1, ]

  table.final <- data.frame(
    Species=table.temp$Species,
    Before=unlist(table.temp[, 2, with=FALSE]),
    After=unlist(table.temp[, (ncol(table.temp)-1), with=FALSE])
    )
  
  table.final$Before_nb <- as.numeric(unlist(lapply(strsplit(as.character(table.final$Before), "_"), function(x) x[1])))
  table.final$After_nb <- as.numeric(unlist(lapply(strsplit(as.character(table.final$After), "_"), function(x) x[1])))

  table.final
  table.final$Change <- NA
  for(i in 1:nrow(table.final)){
  if(table.final$Before[i]=="9_DD" & table.final$After[i]!="9_DD")
    table.final$Change[i] <- "Gain_info"
  if(table.final$Before[i]!="9_DD" & table.final$After[i]=="9_DD")
    table.final$Change[i] <- "Loss_info"
  if(table.final$Before[i]=="8_R" & table.final$After[i] %in% c("1_LC","2_NT"))
    table.final$Change[i] <- "Better"
  if(table.final$Before[i]=="8_R" & !table.final$After[i] %in% c("1_LC","2_NT"))
    table.final$Change[i] <- "Unclear"
  if(!table.final$Before[i] %in%c("8_R", "9_DD") &
     !table.final$Before[i] %in% c("8_R","9_DD") &
    table.final$Before_nb[i] > table.final$After_nb[i])
    table.final$Change[i] <- "Better"
    if(!table.final$Before[i] %in%c("8_R", "9_DD") &
     !table.final$After[i] %in% c("8_R","9_DD") &
    table.final$Before_nb[i] < table.final$After_nb[i])
    table.final$Change[i] <- "Worse"
  }
  
  table.final$Before_nb <- NULL
  table.final$After_nb <- NULL
  table.final$YearChange <- year.change
  table.final$FirstYear <- first.year
  table.final$LastYear <- last.year
  table.final$PublicationsBefore <- NA
  table.final$PublicationsAfter <- NA
  table.final$DateOfSearch <- NA
  table.final$StringUsedForSearch <- NA
  
  if(sum(is.na(table.final$Change))>0) stop("NA problems in final table")

  write.csv(table.final, file=paste("Table_",year.change,".csv", sep=""), row.names=FALSE)

