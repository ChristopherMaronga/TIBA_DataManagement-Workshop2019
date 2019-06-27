#--++++++++++++++++++++++++++++++++++++++++++++ ----
## Training Day 4; Data extraction/pulling from MySQL
#--+++++++++++++++++++++++++++++++++++++++++++++ ----
# load required packages

file.show("Archive/Internal Data Request Form_2017-DA.docx")  ## view data request doc

library(DBI)
library(RMySQL)

con <- dbConnect(MySQL(),
                           host = 'keklf-mysqluat', # host name
                           dbname = 'tiba',         # database name
                           user = 'tiba_usr',       # valid username
                           password = 'tiba2019')   # password associated with username

# list number of tables
dbListTables(con)

# List fields of 2 tables
dbListFields(con, "person") # sex, dob for age calculation
dbListFields(con, "adult_admission") # date_admn, admin_ward, diagnosis_1_disch,diagnosis_1_category

## ++ Approach 1
tiba_demo_data <- dbGetQuery(con, 
"select p.id, p.sex, p.dob, ad.date_admn, ad.admin_ward, ad.diagnosis_1_disch, ad.diagnosis_1_category 
from person p join adult_admission ad on p.id=ad.fk_person 
where p.sex IN ('F','f')")

## compute age from dob and date_admn

## convert dob and date_adm to dates
tiba_demo_data$date_admn <- as_date(tiba_demo_data$date_admn)

tiba_demo_data$dob <- as_date(tiba_demo_data$dob)

## calculate age
tiba_demo_data <- tiba_demo_data %>% 
  mutate(
    age_mons = trunc(difftime(date_admn, dob, units = c("days"))/365.25) # divide days by 365.25
  )
  

rm(tiba_demo_data) ## clean up

## ++ Approach 2 (export the 2 tables and use R to merge/select variables)

library(tidyverse)
adult_adm <- dbGetQuery(con, "select * from adult_admission") # export admissions table

khdss_table <- dbGetQuery(con, "select * from person") # extract person table

## merge and select variables
tiba_demo_data <- khdss_table %>% 
  left_join(adult_adm, by = c("id"="fk_person")) %>% # join the 2 tables
  select(id,sex,dob,date_admn, admin_ward, diagnosis_1_disch,diagnosis_1_category) %>% # select required variables
  filter(sex %in% c("F","f"))  ## filter all female gender
  

## calculate age
tiba_demo_data <- tiba_demo_data %>% 
  mutate(
    age_mons = trunc(difftime(date_admn, dob, units = c("days"))/365.25) # divide days by 365.25
  )


## further participant exercise
# calculate BMI 




#--++++++++++++++++++++++++++++++++++++++++++++ ----
## TIBA Workshop practice script ---Day 5-- +++ -----
#--+++++++++++++++++++++++++++++++++++++++++++++ ----

## Getting data into R --------------------------------------------------

# reading from flat files ----

# load packages
library(readxl)  # for reading .xlsx data (excel datasets)
library(readr)   # read a variety of formats (.csv, tab delimeted)


## read various formats of data
dir("./datasets")  # list items on the datasets folder

# read .xlsx (excel data)
adult_adm_excel <- read_excel("datasets/adult_admission.xlsx")

# read .csv (comma separated files)
adult_adm_csv <- read_csv("datasets/adult_admission.csv")

# read .txt(tab delimeted data)
adult_adm_txt <- read_tsv("datasets/adult_admission.txt")


# Connecting to web-based database (REDCap) ----

library(redcapAPI) # load required package

# create a connection
con <- redcapConnection(url='http://uat/redcap/api/',token = 'token here')

# export data
redcap_all_data<-exportRecords(con, fields = NULL, forms = NULL , records = NULL, events = NULL ,
labels = TRUE, dates = TRUE, survey = FALSE, factors=F, dag = T, checkboxLabels = TRUE)

?redcapAPI # get more help

redcap_all_data %>% 
  group_by(redcap_event_name) %>% 
  summarise(
    total_count = n() # how many records for each visits
  )

## You can also export events (timepoints)
total_events <- exportEvents(con)

## you can export instruments (CRFs)
CRFs_name <- exportInstruments(con)

## You can export users and their rights
all_users <- exportUsers(con)

### +++++++++++ --- AND MANY MORE -----++++++

# Connecting to web-based database (MySQL) ----
# load required packages

library(DBI)
library(RMySQL)

con <- dbConnect(MySQL(),
                           host = 'keklf-mysqluat', # host name
                           dbname = 'tiba',         # database name
                           user = 'tiba_usr',       # valid username
                           password = 'tiba2019')   # password associated with username

# list tables available
dbListTables(con)

# list fields/variables in a specific table
dbListFields(conn = con, name = "adult_admission")  ## list fields for the  table


# extract/pull data from the database
adult_admission <- dbGetQuery(con, "select * from adult_admission")

diagnosis <- dbGetQuery(con, "select * from diagnosis")

haematology <- dbGetQuery(con, "select * from haematology_test")

person_table <- dbGetQuery(con, "select * from person")


## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# READ IN messy datasets +++++++++++++++++++++++++++++++++++++++++++++++++
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
adult_admission <- read_csv("messy_datasets/adult_adm_data.csv")

lab_results <- read_csv("messy_datasets/lab_results.csv")


# Exploring raw data ------------------------------------------------------

dim(adult_admission)
str(adult_admission)
glimpse(adult_admission)  # better version of str()

head(adult_admission, 10)
tail(adult_admission, 10)

summary(adult_admission) # quick summary of all variables


# General housekeeping (maintaining the quality) ---------------------------------
# drop un-necessary columns

adult_admission <- adult_admission %>% 
  select(-X)

## identify duplicates (on all variables)
dups_1 <- adult_admission[duplicated(adult_admission), ]  ## duplicated rows


## remove duplicated data
adult_admission <- adult_admission %>% distinct() # remove duplicated data

# also adult_admission[!duplicated(adult_admission), ] or unique(adult_admission)


## checking duplicates on a variable
dups_2 <- adult_admission[duplicated(adult_admission$id), ] 

## remove duplicates on a variable
adult_admission <- adult_admission %>% distinct(id, .keep_all = T) # remove duplicated data on id



#some columns have high missing rate, probably not needed
miss_perc <- colSums(is.na(adult_admission))/nrow(adult_admission)
View(miss_perc)

# exclude columns where 100% data is missing
adult_admission <- adult_admission %>% 
  select(-c(death_hiv, palpable_kidney_which, date_popd, appt_fare,
            appt_date, appt_date1, family_history, personal_history, appt_fare1))


## missing values
# columns with almost 100% missing values report
miss_perc <- colSums(is.na(adult_admission))/nrow(adult_admission) # proportion of missing
 
View(miss_perc)

## filter specific missing data for variables
miss_height <- adult_admission %>% 
  filter(is.na(height))  # missing height

miss_hgt_wght <- adult_admission %>% 
  filter(is.na(height)|is.na(weight)) # missing either height or weight

miss_vitals <- adult_admission %>% 
  filter(is.na(height) & is.na(weight))  # missing both height and weight


## suspicious/abnormal values (outliers for numeric variable)
# visualize (histogram, boxplots and scatterplots) 
# focus on vital status and identify any anormalies

ggplot(adult_admission, aes(height, weight))+geom_point() # scatter plot



## you can also use summary()
summary(adult_admission$height)


## check for dates (admission vs discharge)
# was anyone discharged before being enrolled??
adult_admission$date_disch <- dmy(adult_admission$date_disch)  # Very important you convert to date format
adult_admission$date_admn <- dmy(adult_admission$date_admn)

neg_enrl_date <- adult_admission %>% 
  filter(as_date(date_disch) < as_date(date_admn)) %>% 
  select(id, pk_serial, date_admn, date_disch)  # patients discharged before they were enrolled

## creating variables (discretizing continous variables)
# length_hosp_stay


# calculate age and discretize



# BMI



# Tidying/Reshaping data --------------------------------------------------
# gather
 # use results, gather cbc tests into 1 column test_type and result



# spread
 # undo the above (spread)




# separate
 # separate admission date into day, month and year (by default, original variable is droped)
test <- adult_messy %>% 
  separate(date_admn, into = c("day", "month", "year"), sep = "-") 


# unite
 # join date_admn and time_admn :: datetime_admn
test2 <- adult_messy %>% 
  unite("datetime_admn", c(date_admn,time_admn), sep = " ")


## merging datasets
# adult_admission and results data
results <- read_csv("messy_datasets/lab_results.csv")

all_daata <- merge(adult_messy, results, by.x = "pk_serial", by.y = "serial_study_id", all = T)


# Preparing data for analysis ---------------------------------------------
## majorly type conversion




# Exporting and saving datasets -------------------------------------------























