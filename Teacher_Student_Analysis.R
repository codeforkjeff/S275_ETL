library(RODBC)
library(tidyverse)
library(knitr)
#library(scales)
library(grid)
#library(reshape)
library(ggthemes)
#library(scales)


db <- odbcDriverConnect('driver={SQL Server};
                        server=SQLDB-DEV-01;
                        database=SandBox;
                        trusted_connection=true')

df <- sqlFetch(db,"dbo.s275_stateh_sch_17")
df2 <- sqlFetch(db,"dbo.RMP_SCHDems_2017")

close(db)


#df2 <- unique(df[!duplicated(df$cert),])
names(df)
levels(df$race)

#############################################################################################
## RACE CATS:
## "     " "A"     "A    " "AB"    "AB   " "ABIPW" "ABP  " "ABW  " "ABWI " "AI"    "AI   " ##
## "AIW"   "AIW  " "AP"    "AP   " "APW"   "APW  " "AW"    "AW   " "AWI  " "B"     "B    " ##
## "BA   " "BAP  " "BAPW " "BAW  " "BI"    "BI   " "BIW  " "BP   " "BPW  " "BW"    "BW   " ##
## "BWA  " "BWI  " "I"     "I    " "IA   " "IAB  " "IABPW" "IAP  " "IAPW " "IAW  " "IB   " ##
## "IBA  " "IBW  " "IP"    "IP   " "IPW  " "IW"    "IW   " "IWB  " "P"     "P    " "PA   " ##
## "PABWI" "PAW  " "PB   " "PW"    "PW   " "W"     "W    " "WA   " "WAB  " "WABI " "WABP " ##
## "WABPI" "WAIB " "WAIBP" "WAP  " "WB   " "WI   " "WIAB " "WIB  " "WP   "                 ##
#############################################################################################
## We want race logic to mirror OSPI's logic: Use Race3

df2 <- df %>%
  mutate(race=as.character(race),
         hispanic=as.character(hispanic),
         race2 = ifelse(race == "A", "asian",
                        ifelse(race == "A    ", "asian",
                               ifelse(race=="W","white",
                                      ifelse(race=="W    ","white",
                                             ifelse(race=="B","black",
                                                    ifelse(race=="B    ","black",
                                                           ifelse(race=="I","native",
                                                                  ifelse(race=="I    ","native",
                                                                         ifelse(race=="P","nhpi",
                                                                                ifelse(race=="P    ","nhpi",
                                                                                       ifelse(race=="     ","not_provided","two_or_more")
                                                                                )))))))))),
         
         
         race3 = ifelse(hispanic == "Y", "Hispanic",
                        ifelse(race == "A" & hispanic == "N", "Asian",
                               ifelse(race == "A    " & hispanic == "N", "Asian",
                                      ifelse(race=="W" & hispanic == "N","White",
                                             ifelse(race=="W    " & hispanic == "N","White",
                                                    ifelse(race=="B" & hispanic == "N","Black",
                                                           ifelse(race=="B    " & hispanic == "N","Black",
                                                                  ifelse(race=="I" & hispanic == "N","American Indian",
                                                                         ifelse(race=="I    " & hispanic == "N","American Indian",
                                                                                ifelse(race=="P" & hispanic == "N","Pacific Islander",
                                                                                       ifelse(race=="P    " & hispanic == "N","Pacific Islander",
                                                                                              ifelse(race=="     " & hispanic == "N","not_provided","two_or_more")
                                                                                       ))))))))))),
         districtcode = ifelse(codist==17902 |codist==17906 | codist==17908, 17999,codist),
         DistrictName=as.character(DistrictName)) %>%
         mutate(districtname = ifelse(districtcode == 17999, "Charter",DistrictName)
  )   


race <- df2  %>% group_by(race3) %>%
        summarise(n=n()) %>%
        mutate(perc= n/sum(n,na.rm=T))
####################
#look at RMPR :

rmp <- df2 %>%
        filter(dRoadMapRegionFlag==1)
############Region
#calculate the flat outcome percent by race to mirror the teacher file###

RMPDEMS <- rmp %>%
  group_by(race3) %>%
  summarise(racetotal= n()) %>%
  filter(race3 != "not_provided") %>%
  mutate( 
    raceperc = racetotal/sum(racetotal, na.rm=T))

write.csv(RMPDEMS, file="RMPTeach.csv")
##############
RMPDEMS$fraction = RMPDEMS$racetotal / sum(RMPDEMS$racetotal)
RMPDEMS = RMPDEMS[order(RMPDEMS$fraction), ]
RMPDEMS$ymax = cumsum(RMPDEMS$fraction)
RMPDEMS$ymin = c(0, head(RMPDEMS$ymax, n=-1))

  ggplot(RMPDEMS, aes(fill=race3, ymax=ymax, ymin=ymin, xmax=4, xmin=3)) +
  geom_rect(colour="grey30") +
  coord_polar(theta="y") +
  scale_fill_manual(values = c('#1b9e77','#d95f02','#7570b3','#e7298a','#66a61e','#e6ab02','#a6761d')) +
  xlim(c(0, 4)) +
  theme_bw() 
ggsave("RMP_Teach.png",width = 10, height = 8)
#####################################################
District <- rmp %>%
  group_by(districtcode,districtname,race3) %>%
  summarise(racetotal= n()) %>%
  filter(race3 != "not_provided") %>%
  mutate(teachTot = sum(racetotal,na.rm=T), 
         raceperc = racetotal/sum(racetotal, na.rm=T),
         fraction=racetotal/sum(racetotal),
         ymax=cumsum(fraction),
         ymin=c(0, head(ymax, n=-1))) %>%
  arrange(districtname,fraction)
  write.csv(District,file="district_teach.csv")
  
  
  ggplot(District, aes(fill=race3, ymax=ymax, ymin=ymin, xmax=4, xmin=3)) +
  geom_rect(colour="grey30") +
    theme(legend.text=element_text(size=20),
          text = element_text(size = 20)) +
  coord_polar(theta="y") +
  scale_fill_manual(values = c('#1b9e77','#d95f02','#7570b3','#e7298a','#66a61e','#e6ab02','#a6761d')) +
  xlim(c(0, 4)) +
  #theme_bw() + 
  facet_wrap(~districtname)
    
ggsave("RMP_Teach_Dist.png",width = 16, height = 16)

ggplot() + geom_bar(aes(y = raceperc, x = districtname, fill = race3), data = District,
                    stat="identity") +
  scale_fill_manual(values = c('#1b9e77','#d95f02','#7570b3','#e7298a','#66a61e','#e6ab02','#a6761d')) +
  theme(legend.text=element_text(size=20),
        text = element_text(size = 20))

####################################################################################
#Graphing
#District <- rmp %>%
#     group_by(districtcode,districtname,race3) %>%
#     summarise(racetotal= n()) %>%
#     mutate(total = sum(racetotal, na.rm=T),
#            raceperc = racetotal/sum(racetotal, na.rm=T))
#####################################################################################
#RATIO comparison
##############
District <- rmp %>%
     group_by(districtcode,districtname,race3) %>%
     summarise(racetotal= n()) %>%
     mutate(teachTot = sum(racetotal,na.rm=T), 
            raceperc = racetotal/sum(racetotal, na.rm=T))

flatOut <- District %>%
  #filter(LastRMRAcademicYear == 2011) %>%
  gather(Var, val, c('racetotal','raceperc')) %>% 
  unite(Var1,Var, race3) %>% 
  spread(Var1, val) 

write.csv(flatOut, file="Teacher_Dems_district.csv")
################################
#Need flat OSPI school dems district
#################################
##GFAPHS AND COMPARISONS
####################################
RMPDEMSOS <- osDis %>%
  group_by(Subgroup) %>%
  summarise(racetotal= sum(Total,na.rm=T)) %>%
  filter(Subgroup != "All") %>%
  mutate( 
    raceperc = racetotal/sum(racetotal, na.rm=T))


RMPDEMSOS$fraction = RMPDEMSOS$racetotal / sum(RMPDEMSOS$racetotal)
RMPDEMSOS = RMPDEMSOS[order(RMPDEMSOS$fraction), ]
RMPDEMSOS$ymax = cumsum(RMPDEMSOS$fraction)
RMPDEMSOS$ymin = c(0, head(RMPDEMSOS$ymax, n=-1))

  ggplot(RMPDEMSOS, aes(fill=Subgroup, ymax=ymax, ymin=ymin, xmax=4, xmin=3)) +
  geom_rect(colour="grey30") +
  coord_polar(theta="y") +
  scale_fill_manual(values = c('#1b9e77','#d95f02','#7570b3','#e7298a','#66a61e','#e6ab02','#a6761d')) +
  xlim(c(0, 4)) +
  theme_bw() 
ggsave("RMP_stud.png",width = 10, height = 8)
####################################DISTRICT

DistrictST <- osDis %>%
  mutate(Subgroup = as.character(Subgroup)) %>%
  group_by(DistrictCode,DistrictName) %>%
  filter(Subgroup != "All") %>%
  
  mutate(raceperc = Total/sum(Total, na.rm=T),
         fraction=Total/sum(Total),
         ymax=cumsum(fraction),
         ymin=c(0, head(ymax, n=-1))) %>%
  arrange(DistrictName,Subgroup,fraction)

write.csv(DistrictST,file="district_stu.csv")

ggplot(DistrictST, aes(fill=Subgroup, ymax=ymax, ymin=ymin, xmax=4, xmin=3)) +
  geom_rect(colour="grey30") +
  theme(legend.text=element_text(size=20),
        text = element_text(size = 20)) +
  coord_polar(theta="y") +
  scale_fill_manual(values = c('#1b9e77','#d95f02','#7570b3','#e7298a','#66a61e','#e6ab02','#a6761d')) +
  xlim(c(0, 4)) +
  #theme_bw()  + 
  facet_wrap(~DistrictName)

ggsave("RMP_ST_Dist.png",width = 16, height = 16)

ggplot() + geom_bar(aes(y = raceperc, x = DistrictName, fill = Subgroup), data = DistrictST,
                    stat="identity") +
  scale_fill_manual(values = c('#1b9e77','#d95f02','#7570b3','#e7298a','#66a61e','#e6ab02','#a6761d')) +
  theme(legend.text=element_text(size=20),
        text = element_text(size = 20))
##################################################
##FLAT OUTCOMES FOR STUDENT OSPI
###################################################

osDis <- df2 %>%
          filter(Subgroup %in% c("All","American Indian","Asian","Black","Hispanic","Pacific Islander","Two or More races","White") &
                 !complete.cases(SchoolName) & !DistrictCode %in% c('50002','50005'))%>%
          mutate(DistrictCode = ifelse(DistrictCode==17902 |DistrictCode==17906 | DistrictCode==17908, 17999,DistrictCode),
                 DistrictName=as.character(DistrictName),
                 DistrictName = ifelse(DistrictCode == 17999, "Charter",DistrictName)) %>%
          select(DistrictCode,DistrictName,Subgroup,Total) %>%
          group_by(DistrictCode,DistrictName,Subgroup)%>%
          summarise(Total=sum(Total,na.rm=T))

flatOutosDis <- osDis %>%
  mutate(Subgroup = gsub(" ", "", Subgroup)) %>%
  #filter(LastRMRAcademicYear == 2011) %>%
  gather(Var, val, c('Total')) %>% 
  unite(Var1,Var, Subgroup) %>% 
  spread(Var1, val) %>%
  mutate(NativePct = Total_AmericanIndian/Total_All,
         AsianPct = Total_Asian/Total_All,
         BlackPct = Total_Black/Total_All,
         latinPct= Total_Hispanic/Total_All,
         piPct = Total_PacificIslander/Total_All,
         twoPct= Total_TwoorMoreraces/Total_All,
         whitePct = Total_White/Total_All)

write.csv(flatOutosDis, file="OSPI_Student_Dems_district.csv")

#############################################################################



