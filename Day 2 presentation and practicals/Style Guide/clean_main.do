*******************************************************************************************************************
********************************************BEGIN  HEADER******************************************************

/*Name of do-file: clean_main.do*/

/*Purpose:  runs do files for data cleaning in the desired sequence */
	
/*	input : data cleaning do files
		
*/

/*	output : (1) data quality report
						(a)nominal variables without categories-> encode
						(b)nominal variables with undocumented codes->label values
						(c)variables with missing labels ->label var
						(d)variables with same label->rename
						(e)variables with missing mandatory  fields -> impute
						(f)scale-variables with  categorical value ->
						(g) mixed formats or data-types  within the same field e.g. mixing date formats; mixing text and numbers

			(2) anonymized, labelled and CLEANED datasets for LBBS and HBTC
			
*/

/*Authors: 
			Daniel Kwaro	
			
*/

/*Contact Email: dkwaro@kemricdc.org*/

/*first version: 10th April 2017*/

/*last review/version: 27th May 2017*/

******************************************END HEADER**********************************************************
******************************************************************************************************************


******************************************************************************************************************
****************************************BEGIN SET UP************************************************************
//start time for the cleaning process

local start  `c(current_time)'

//set more off
set more off
set trace off


//global macros
global root "F:\HISS\hiss_repositories"
global workspace  "${root}\HBTC_HIVSS_workspace" //workspace
cd $workspace

global scripts     "LBBS_cleaning_project\code\stata\scripts" //input<-scripts for cleaning datasets
global temp_data   "LBBS_cleaning_project\temp_data\data" //output--> cleaned datasets
global reports        "LBBS_cleaning_project\output\reports" //output-->data quality report
global analysis_data        "LBBS_analysis_projects\data"  //secondary output for clean datasets
global analysis_metadata        "LBBS_analysis_projects\metadata"  //output for final metadata



// save log file
cap log using "LBBS_cleaning_project\output\logs\clean_LBBS_HBTC  log.smcl", replace


//install dependencies
capture which missings
if _rc==111 ssc install missings

capture which labellacking
if _rc==111 ssc install labellacking

capture which findname
if _rc==111 ssc install findname

capture which distinct
if _rc==111 ssc install distinct //for counting number of unique values in a variable

capture which caplog
if _rc==111 ssc install caplog   //to 'capture' results logged on the output window

capture which logout
if _rc==111 ssc install logout   ///works with caplog

capture which carryforward
if _rc==111 ssc install carryforward // install the  package <carryforward> from SSC , that has  the command <carryforward>  
									  //for filling missing values with values from ABOVE /PREVIOUS ROW 
									  
capture which personage									  
if _rc==111 ssc install personage  //for calculating age based on birth date and a current event

capture which datacheck
if _rc==111 ssc install datacheck  //a replacement for the assert command



//create file for reporting the data quality
tempname fhandle
file open `fhandle' using "${reports}\quality_report.doc", write text replace
file write `fhandle' "DATA QUALITY REPORT" _newline 
file write `fhandle' "---------------------------------------" _n _n _n
file close `fhandle' 



global scripts     "LBBS_cleaning_project\code\stata\scripts" //input<-scripts for cleaning datasets


  


//STEP 1: diagnose and  clean datasets-generate reports on data quality as this stage is running

do "${scripts}\1_clean_move_files.do"    // move data from raw folder to a temporary folder for manipulation
global workspace  "${root}\HBTC_HIVSS_workspace" //workspace

cd $workspace

do "${scripts}\2_clean_missing.do" 		// clean completely missing variables and observations
global workspace  "${root}\HBTC_HIVSS_workspace" //workspace

cd $workspace

do "${scripts}\3_clean_badlabels.do"   //clean bad labels
global workspace  "${root}\HBTC_HIVSS_workspace" //workspace

cd $workspace
do "${scripts}\4_clean_dates.do"    //clean dates 
global workspace  "${root}\HBTC_HIVSS_workspace" //workspace

cd $workspace

do "${scripts}\5_clean_duplicates.do"    //drop duplicates
global workspace  "${root}\HBTC_HIVSS_workspace" //workspace

cd $workspace

do "${scripts}\6_clean_outliers.do" //detect outliers
global workspace  "${root}\HBTC_HIVSS_workspace" //workspace

cd $workspace

do "${scripts}\7_clean_skiplogic.do"   //check skip logic
global workspace  "${root}\HBTC_HIVSS_workspace" //workspace

cd $workspace

do  "${scripts}\8_clean_looplogic.do"   //check loop logic
global workspace  "${root}\HBTC_HIVSS_workspace" //workspace

cd $workspace

do "${scripts}\9_clean_otherlogic.do"   //check other validation rules
global workspace  "${root}\HBTC_HIVSS_workspace" //workspace

cd $workspace

do "${scripts}\10_clean_mergingconsistency.do" //correct errors that make data  inconsistent across surveys for the same individual
global workspace  "${root}\HBTC_HIVSS_workspace" //workspace

cd $workspace





//STEP 2: move the clean files to the analysis folder
global temp_data   "LBBS_cleaning_project\temp_data" //output--> cleaned datasets
global analysis_data        "LBBS_analysis_projects\data"  //secondary output for clean datasets


//input datasets
local lbbs1 			"KEMRI_LBBSround1_anon"
local lbbs2 			"KEMRI_LBBSround2_anon"
local lbbs4 			"KEMRI_LBBSround4_anon"
local hbtc1				"KEMRI_HBTCround1_anon"
local hbtc2 			"KEMRI_HBTCround2_anon"
local hbtc3 			"KEMRI_HBTCround3_anon"
local hbtc4				"KEMRI_HBTCround4_anon"




foreach num of numlist 1 2 3 4 5{


	//get hbtc file	
	use "${temp_data}\stata\\`hbtc`num''_labelled", clear
	
	//save hbtc file
	sleep 5000
	save "${analysis_data}\stata\\`hbtc`num''_labelled", replace
	
	if `num'!=3{  /*skip lbbs3*/
			//get lbbs file	
			use "${temp_data}\stata\\`lbbs`num''_labelled", clear
			
			//save lbbs file
			sleep 5000
			save "${analysis_data}\stata\\`lbbs`num''_labelled", replace
		}		
}  /* end file movement loop*/
			
// step 3: MOVE THE COMBINED SERODATA
use "${temp_data}\stata\KEMRI_HBTCallRounds_SeroData", clear
sleep 5000
save "${analysis_data}\stata\KEMRI_HBTCallRounds_SeroData", replace


// step 4: MOVE THE REFERENCE DATA SET FOR AGE AND GENDER

use "${temp_data}\stata\lbbs_gender_age.dta", clear
sleep 5000
save "${analysis_data}\stata\lbbs_gender_age.dta", replace



// calculate time taken to run the cleaning process

local end `c(current_time)'


di "Start  Time : `start'"
di "End  Time :  `end'"
clear all

cap log close
