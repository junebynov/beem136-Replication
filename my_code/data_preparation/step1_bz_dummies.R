# Replication files for "Public Pension Reforms and Retirement Decisions: Narrative Evidence and Aggregate Implications"
# Huixin Bi and Sarah Zubairy
# June 2026

# Input file: narrative data file ("All_countries" in bz_narrative_data.xlsx) 
# Output file: public pension reform dummy file (Dummy.csv) to be used in bz_oecd_data.csv

#===============================================================================

rm(list=ls())

library(readxl)
library(tidyverse)

# load narrative data file
# ---------------------------------------------
all_countries <- read_excel("bz_narrative_data.xlsx", sheet="All_Countries")  %>% select(-c(`Details`)) %>%
  mutate(Countries = as.factor(Countries)) %>% # So that country names are not made lowercase
  mutate_if(is.character, tolower) %>%
  mutate_if(is.character, ~ gsub("[^A-Za-z0-9 ]","",.)) %>%
  mutate(Countries = as.character(Countries))

names(all_countries)

# Generate dummies
# ---------------------------------------------
# long lags: pension change with implementation lags of 15 years or longer
# short lags: pension changes with implementation lags of less 15 years, or those with unknown lags (labeled as 'delay' in the narrative file)
# For ease of evaluating this, defining a value of delay as 1 year 

lag_threshold = 15

flagged_reforms <- all_countries %>% 
  mutate(`Implementation Lags (yrs)` = ifelse(`Implementation Lags (yrs)` == "delay","1",`Implementation Lags (yrs)`)) %>% 
  mutate(Reform_index = (Motivation == "reform"),
         Reform_delay = (Motivation == "reform" & !is.na(`Implementation Lags (yrs)`)),
         Major_nodelay = (`Major/Marginal` == "major"& is.na(`Implementation Lags (yrs)`)),
         Major_delay = (`Major/Marginal` == "major"& !is.na(`Implementation Lags (yrs)`)),
         Major_delay_age = (`Major/Marginal` == "major"& !is.na(`Delay_age`)),
         Major_delay_contribution = (`Major/Marginal` == "major"& !is.na(`Delay_contribution`)),
         Major_delay_other = (`Major/Marginal` == "major"& !is.na(`Implementation Lags (yrs)`) & (is.na(`Delay_age`)&is.na(`Delay_contribution`))),
         Major_delay_short= (`Major/Marginal` == "major"& !is.na(`Implementation Lags (yrs)`) & as.numeric(`Implementation Lags (yrs)`) < lag_threshold),
         Major_delay_long = (`Major/Marginal` == "major"& !is.na(`Implementation Lags (yrs)`) & as.numeric(`Implementation Lags (yrs)`) >= lag_threshold),
         Major_delay_age_short = (`Major/Marginal` == "major"&!is.na(`Delay_age`) & as.numeric(`Implementation Lags (yrs)`) < lag_threshold),
         Major_delay_contribution_short = (`Major/Marginal` == "major"& !is.na(`Delay_contribution`) & as.numeric(`Implementation Lags (yrs)`) < lag_threshold),
         Major_delay_age_long = (`Major/Marginal` == "major"& !is.na(`Delay_age`) & as.numeric(`Implementation Lags (yrs)`) >= lag_threshold),
         Major_delay_contribution_long = (`Major/Marginal` == "major" & !is.na(`Delay_contribution`) & as.numeric(`Implementation Lags (yrs)`) >= lag_threshold)) 


# Add sign information to dummies
# ---------------------------------------------
flagged_reforms <-flagged_reforms %>%  mutate(Reform_index = ifelse(Reform_index & Sign == "positive",1,ifelse(Reform_index & Sign == "negative",-1,0)),
                                              Reform_delay = ifelse(Reform_delay & Sign =="positive",1,ifelse(Reform_delay & Sign == "negative",-1,0)),
                                              Major_delay = ifelse(Major_delay & Sign == "positive",1,ifelse(Major_delay & Sign == "negative",-1,0)),
                                              Major_nodelay = ifelse(Major_nodelay & Sign == "positive",1,ifelse(Major_nodelay & Sign == "negative",-1,0)),
                                              Major_delay_age = ifelse(Major_delay_age & Sign == "positive",1,ifelse(Major_delay_age & Sign == "negative",-1,0)),
                                              Major_delay_contribution = ifelse(Major_delay_contribution & Sign == "positive",1,ifelse(Major_delay_contribution & Sign == "negative",-1,0)),
                                              Major_delay_other = ifelse(Major_delay_other & Sign == "positive",1,ifelse(Major_delay_other & Sign == "negative",-1,0)),
                                              Major_delay_short = ifelse(Major_delay_short & Sign == "positive",1,ifelse(Major_delay_short & Sign =="negative",-1,0)),
                                              Major_delay_long = ifelse(Major_delay_long & Sign == "positive",1,ifelse(Major_delay_long & Sign == "negative",-1,0)),
                                              Major_delay_age_short = ifelse(Major_delay_age_short & Sign == "positive",1,ifelse(Major_delay_age_short & Sign == "negative",-1,0)),
                                              Major_delay_contribution_short = ifelse(Major_delay_contribution_short & Sign == "positive",1,ifelse(Major_delay_contribution_short & Sign == "negative",-1,0)),
                                              Major_delay_age_long = ifelse(Major_delay_age_long & Sign == "positive",1,ifelse(Major_delay_age_long & Sign == "negative",-1,0)),
                                              Major_delay_contribution_long = ifelse(Major_delay_contribution_long & Sign == "positive",1,ifelse(Major_delay_contribution_long & Sign == "negative",-1,0)))



#Aggregate dummies into country-year observations
# ---------------------------------------------
dummies <- flagged_reforms %>% group_by(Year, Countries) %>%
  summarise(Reform_index = sum(Reform_index, na.rm=T),
            Reform_delay = sum(Reform_delay, na.rm=T),
            Major_nodelay = sum(Major_nodelay, na.rm=T),
            Major_delay = sum(Major_delay, na.rm=T),
            Major_delay_age = sum(Major_delay_age, na.rm=T),
            Major_delay_contribution = sum(Major_delay_contribution),
            Major_delay_other = sum(Major_delay_other, na.rm=T),
            Major_delay_short = sum(Major_delay_short, na.rm=T),
            Major_delay_long = sum(Major_delay_long, na.rm=T),
            Major_delay_age_short = sum(Major_delay_age_short, na.rm=T),
            Major_delay_contribution_short = sum(Major_delay_contribution_short, na.rm=T),
            Major_delay_age_long = sum(Major_delay_age_long, na.rm=T),
            Major_delay_contribution_long = sum(Major_delay_contribution_long, na.rm=T)) %>%
  ungroup()


# Add observations of 0 for years without reforms in 1960-2018. 
# ---------------------------------------------
# Note: 
# 1) Add 2016 and 1966 manually since no reforms in any countries recorded
# 2) Remove 2019
dummies <- dummies %>% group_by(Countries) %>% group_modify(~ add_row(.x,Year = 1960,.before=0)) %>%
  group_modify(~ add_row(.x,Year = 2016,.before=0)) %>%
  group_modify(~ add_row(.x,Year = 1966,.before=0)) %>%ungroup()
dummies <- dummies %>% complete(Countries, Year) %>% filter(Year != 2019)
dummies[is.na(dummies)] <- 0


# save dummy series
# ---------------------------------------------
write.csv(dummies,"Dummy.csv")




