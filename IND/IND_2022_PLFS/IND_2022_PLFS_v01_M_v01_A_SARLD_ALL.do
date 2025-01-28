***********************************************************************
*	IND_2022_PLFS
*	SAR Labor Harmonization
*	Aug 2024
*	Sizhen Fang, sfang2@gmail.com
***********************************************************************
clear
set more off
local countrycode	"IND"
local year			"2022"
local survey		"PLFS"
local va			"01"
local vm			"01"
local type			"SARLAB"
local surveyfolder	"`countrycode'_`year'_`survey'"
local masternm	 	"`surveyfolder'_v`vm'_M"
local filename 		"`surveyfolder'_v`vm'_M_v`va'_A_`type'"" 

 * SF
 if ("`c(username)'"=="wb611670") {
 	* define folder paths
 	glo rootdatalib "C:\Users\wb611670\WBG\Laura Liliana Moreno Herrera - 09.SARLAB\WORKINGDATA"
 	glo rootlabels "C:\Users\wb611670\WBG\Laura Liliana Moreno Herrera - 09.SARLAB\_aux"
 }
 * global paths on WB computer
 else {
 	* NOTE: TODO: You (WB staff) will need to define the location of the datalibweb folder path here.
 	* load data and merge
 	tempfile hhvisit1
 	datalibweb, country(`countrycode') year(`year') survey(`survey') type(SARRAW) filename(hhvisit1_2022-23.dta) localpath(${rootdatalib}) local
 	save `hhvisit1', replace
 	* start with individual data
 	datalibweb, country(`countrycode') year(`year') survey(`survey') type(SARRAW) filename(personvisit1_2022-23.dta) localpath(${rootdatalib}) local
 	drop district stratum substratum subsample _merge
 	* merge in HH data
 	merge m:1 hhid using `hhvisit1', nogen assert(match)
	
 } 
 
 glo surveydata		"${rootdatalib}\\`countrycode'\\`surveyfolder'\\`surveyfolder'_v`vm'_M\Data\Stata"
 glo output			"${rootdatalib}\\`countrycode'\\`surveyfolder'\\`surveyfolder'_v`vm'_M_v`va'_A_`type'\Data\Harmonized"
 cap mkdir "${rootdatalib}\\`countrycode'\\`surveyfolder'"
 cap mkdir "${rootdatalib}\\`countrycode'\\`surveyfolder'\\`surveyfolder'_v`vm'_M_v`va'_A_`type'"
 cap mkdir "${rootdatalib}\\`countrycode'\\`surveyfolder'\\`surveyfolder'_v`vm'_M_v`va'_A_`type'\Data"
 cap mkdir "${rootdatalib}\\`countrycode'\\`surveyfolder'\\`surveyfolder'_v`vm'_M_v`va'_A_`type'\Data\Harmonized"
 cap mkdir "${rootdatalib}\\`countrycode'\\`surveyfolder'\\`surveyfolder'_v`vm'_M_v`va'_A_`type'\Program"
 * load data on Joe's computer
 if ("`c(username)'"=="wb611670") {
 	* load data and merge
 	* start with individual data
 	use "${surveydata}\personvisit1_2022-23", clear
 	drop district stratum substratum subsample _merge
 	* merge in HH data
 	merge m:1 hhid using "${surveydata}\hhvisit1_2022-23", nogen assert(match)
 }

* label state names
* note: India merged the union territories of Daman and Diu (25 in our old value labels) and Dadra and Nagar Haveli (26 in our old value labels) into a single union territory to be known as Dadra and Nagar Haveli and Daman and Diu, effective from 26 January 2020. They are combined in this survey in state code 25.
label define state 28 "28 - Andhra Pradesh" 12 "12 - Arunachal Pradesh" 18 "18 - Assam" 10 "10 - Bihar" 30 "30 - Goa" 24 "24 - Gujrat" 6 "6 - Haryana" 2 "2 - Himachal Pradesh" 1 "1 - Jammu & Kashmir" 29 "29 - Karnataka" 32 "32 - Kerala" 23 "23 - Madhya Pradesh" 27 "27 - Maharastra" 14 "14 - Manipur" 17 "17 - Meghalaya" 15 "15 - Mizoram" 13 "13 - Nagaland" 21 "21 - Odisha" 3 "3 - Punjab" 8 "8 - Rajasthan" 11 "11 - Sikkim" 33 "33 - Tamil Nadu" 16 "16 - Tripura" 9 "9 - Uttar Pradesh" 19 "19 - West Bengal" 35 "35 - Andaman & Nicober" 4 "4 - Chandigarh" 25 "25 - Dadra and Nagar Haveli and Daman and Diu" 7 "7 - Delhi" 31 "31 - Lakshadweep" 34 "34 - Pondicheri" 22 "22 - Chhattisgarh" 20 "20 - Jharkhand" 5 "5 - Uttaranchal" 36 "36 - Telangana" 37 "37 - "
label values state state

* countrycode = country code
g countrycode = "`countrycode'"

* year = Year
drop year
g year = `year'

* int_year = interview year
g		int_year = 2022 if inlist(quarter,"Q3","Q4")
replace	int_year = 2023 if inlist(quarter,"Q1","Q2")

* int_month = interview month
destring month, gen(int_month)
bys fsu: egen auxmonth = mode(int_month)
replace int_month=auxmonth if mi(int_month)
assert ~missing(int_month)

* hhid = Household identifier
* NOTE: hhid = 4VVFFFFFBSHH
*	the number "4"		: 4th round?
*	visit				: visit
*	fsu					: first segment unit
*	sample_sg			: segment block number?
*	stage2_stratumno	: second stage stratum
*	hhno				: HH number
confirm var hhid

* pid = Personal identifier
confirm var pid

* confirm unique identifiers: hhid + pid
isid hhid pid

* weight = Household weight
g weight = hhwt

* relationharm = Relationship to head of household harmonized across all regions
recode relationtohead (1=1) (2=2) (3 5=3) (4 6=5) (7/8=4) (9=7) (*=.), g(relationharm)
note relationharm: For IND_2021_PLFS, the survey variable relationtohead = 7 "father/mother/father-in-law/mother-in-law" overlapped with two harmonized categories and was coded as 4 "parents".
note relationharm: For IND_2021_PLFS, the survey variable relationtohead = 9 "servants/employees/other non-relatives" overlapped with two harmonized categories and was coded as 7 "non household members (domestic worker, room renter)".

* relationcs = Original relationship to head of household
label define relationtohead 1 "self" 2 "spouse of head" 3 "married child" 4 "spouse of married child" 5 "unmarried child" 6 "grandchild" 7 "father/mother/father-in-law/mother-in-law" 8 "brother/sister/brother-in-law/ sister-in-law/other relatives" 9 "servants/employees/other non-relatives"
label values relationtohead relationtohead
decode relationtohead, g(relationcs)

* household member. All excluding household workers
gen hhmember=(relationharm!=7)

* hsize = Household size, not including household workers
bys hhid: egen hsize=total(hhmember)

* strata = Strata
g strata = stratum

* psu = PSU
g psu = fsu

* spdef = Spatial deflator (if one is used)
g spdef = .

* subnatid1 = Subnational ID - highest level
*label define state 28 "28 - Andhra Pradesh" 12 "12 - Arunachal Pradesh" 18 "18 - Assam" 10 "10 - Bihar" 30 "30 - Goa" 24 "24 - Gujrat" 6 "6 - Haryana" 2 "2 - Himachal Pradesh" 1 "1 - Jammu & Kashmir" 29 "29 - Karnataka" 32 "32 - Kerala" 23 "23 - Madhya Pradesh" 27 "27 - Maharastra" 14 "14 - Manipur" 17 "17 - Meghalaya" 15 "15 - Mizoram" 13 "13 - Nagaland" 21 "21 - Odisha" 3 "3 - Punjab" 8 "8 - Rajasthan" 11 "11 - Sikkim" 33 "33 - Tamil Nadu" 16 "16 - Tripura" 9 "9 - Uttar Pradesh" 19 "19 - West Bengal" 35 "35 - Andaman & Nicober" 4 "4 - Chandigarh" 26 "26 - Dadra & Nagar Haveli" 25 "25 - Daman & Diu" 7 "7 - Delhi" 31 "31 - Lakshadweep" 34 "34 - Pondicheri" 22 "22 - Chhattisgarh" 20 "20 - Jharkhand" 5 "5 - Uttaranchal" 36 "36 - Telangana"
*label values state state
decode state, g(subnatid1)

* subnatid2 = Subnational ID - second highest level
g subnatid2 = district

* subnatid3 = Subnational ID - third highest level
g subnatid3 = ""

* urban = Urban (1) or rural (0)
recode sector (1=0) (2=1), g(urban)

* language = Language
g language = ""

* age = Age of individual (continuous)
confirm var age

* male = Sex of household member (male=1)
recode sex (1=1) (2=0) (3=.o) (*=.), g(male)
note sex: other recode as .o to meet the harmonization dictionary and keep the information available for a country-specific user.

* marital = Marital status
recode maritalstat (1=2) (2=1) (3=5) (4=4) (*=.), g(marital)

* eye_dsablty = Difficulty seeing
g eye_dsablty = .

* hear_dsablty = Difficulty hearing
g hear_dsablty = .

* walk_dsablty = Difficulty walking or climbing steps
g walk_dsablty = .

* conc_dsord = Difficulty remembering or concentrating
g conc_dsord = .

* slfcre_dsablty = Difficulty with self-care
g slfcre_dsablty = .

* comm_dsablty = Difficulty communicating
g comm_dsablty = .

* educat7 = Highest level of education completed (7 categories)
*from: educational level - general:
*not literate -01, 
*literate without formal schooling: 
**EGS/ NFEC/ AEC -02, TLC -03, others -04; 
*literate: 
**below primary -05, primary -06, middle -07, secondary -08, higher secondary -10, diploma/certificate course -11, graduate -12, postgraduate and above -13.
recode geneducation (1/4=1) (5=2) (6=3) (7=4) (8/10=5) (11=6) (12/13=7) (*=.o), g(educat7)

* educat5 = Highest level of education completed (5 categories)
recode educat7 (0=0) (1=1) (2=2) (3/4=3) (5=4) (6/7=5), g(educat5)

* educat4 = Highest level of education completed (4 categories)
recode educat7 (0=0) (1=1) (2/3=2) (4/5=3) (6/7=4), g(educat4)

* educy = Years of completed education
g educy = noyrsformaled

* literacy = Individual can read and write
recode geneducation (1=0) (2/13=1), g(literacy)
note literacy: For IND_2021_PLFS, we used the general education variable that specified literate or non-literate, but didn't specify whether or not their definition of literacy included both reading and writing.

* cellphone_i = Ownership of a cell phone (individual)
g cellphone_i = .

* computer = Ownership of a computer
g computer = .

* etablet = Ownership of a electronic tablet
g etablet = .

* internet_athome = Internet available at home, any service (including mobile)
g internet_athome = .

* internet_mobile = has mobile Internet (mobile 2G 3G LTE 4G 5G ), any service
g internet_mobile = .

* internet_mobile4Gplus = has mobile high speed internet (mobile LTE 4G 5G ) services
g internet_mobile4Gplus = .

*********************
* labor
destring prn_occ sub_occupation cws_occupation status*day? industry*day? *_industry duration_* *_day? earnings_* *paid_leave ???_enterprise ???_job_contract ???_soc_security ???_n_workers	///
sub_status, replace

* minlaborage_year = Labor module application age (12-mon ref period)
g minlaborage_year = 0

* lstatus_year = Labor status (12-mon ref period)
recode prn_status (11/51 = 1) (81=2) (91/97=3) (99=.a) (*=.), g(lstatus_year)

* nlfreason_year = Reason not in the labor force (12-mon ref period)
recode prn_status (91=1) (92 93=2) (94=3) (95=4) (82 96 97=5) (*=.) if lstatus_year==3, g(nlfreason_year)

* unempldur_l_year = Unemployment duration (months) lower bracket (12-mon ref period)
recode duration_unemp (1=1) (2=7) (3=13) (4=25) (5=37) (*=.) if lstatus_year==2, g(unempldur_l_year)

* unempldur_u_year = Unemployment duration (months) upper bracket (12-mon ref period)
recode duration_unemp (1=6) (2=12) (3=24) (4=36) (*=.) if lstatus_year==2, g(unempldur_u_year)

* empstat_year = Employment status, primary job (12-mon ref period)
recode prn_status (11=4) (12=3) (61 62 21=2) (31 41 42 51 52 71 72 98 =1) (81/97 99=.) (*=.) if lstatus_year==1, g(empstat_year)

* ocusec_year = Sector of activity, primary job (12-mon ref period)
recode prn_enterprise (1/4 7 10/12=2) (5/6=1) (8=4) (*=.) if lstatus_year==1, g(ocusec_year)

* industry_orig_year = Original industry code, primary job (12-mon ref period)
tostring prn_industry, g(industry_orig_year)
replace industry_orig_year = "" if lstatus_year~=1

* industrycat10_year = 1 digit industry classification, primary job (12-mon ref period)
gen industrycat10_year = floor(prn_industr/1000) if lstatus_year==1
recode industrycat10_year (1/3=1) (4/9=2) (10/33=3) (35/39=4) (41/43=5) (45/47 55/56=6) (49/53 58/63 79=7) (64/68 83=8) (84=9) (69/78 80/82 85/99=10) (*=.)
	
* industrycat4_year = 4-category industry classification, primary job (12-mon ref period)
recode industrycat10_year (1=1) (2/5=2) (6/9=3) (10=4) if lstatus_year==1, g(industrycat4_year)

* occup_orig_year = Original occupational classification, primary job (12-mon ref period)
g occup_orig_year = prn_occ if lstatus_year==1

* occup_year = 1 digit occupational classification, primary job (12-mon ref period)
g occup_year = floor(prn_occ/100) if lstatus_year==1

* contract_year = Contract (12-mon ref period)
recode prn_job_contract (1=0) (2/4=1) if lstatus_year==1, g(contract_year)
note contract_year: For IND_2021_PLFS, the source variable was only constructed for a subset of employed people.

* socialsec_year = Social security (12-mon ref period)
la def prn_soc_security ///
1 "pension" ///
2 "gratuity" ///
3 "health" ///
4 "pension and gratuity" ///
5 "pension and health" ///
6 "gratuity and health" ///
7 "pension, gratuity, and health" ///
8 "none" ///
9 "not known" 
la val prn_soc_security prn_soc_security
recode prn_soc_security (1/7=1) (8=0) (*=.) if lstatus_year==1, g(socialsec_year)
note socialsec_year: For IND_2021_PLFS, we considered any of the following benefits as social security: pension, gratuity, or health.

* healthins_year = Health insurance (12-mon ref period)
recode prn_soc_security (3 5/7=1) (1 2 4 8=0) (*=.) if lstatus_year==1, g(healthins_year)

* pensions_year = Pension main activity (12-mon ref period)
recode prn_soc_security (1 4 5 7=1) (2 3 6 8=0) (*=.) if lstatus_year==1, g(pensions_year)

* paid_leave_year = Eligible for paid leave, primary job (12-mon ref period)
g paid_leave_year = (prn_paid_leave==1) if lstatus_year==1 & ~missing(prn_paid_leave)

* union_year = Union membership (12-mon ref period)
g union_year = .

* firmsize_l_year = Firm size (lower bracket), primary job (12-mon ref period)
recode prn_n_workers (1=1) (2=6) (3=10) (4=20) (*=.) if lstatus_year==1, g(firmsize_l_year)

* firmsize_u_year = Firm size (upper bracket), primary job (12-mon ref period)
recode prn_n_workers (1=5) (2=9) (3=19) (*=.) if lstatus_year==1, g(firmsize_u_year)

* empldur_orig_year = Original employment duration/tenure, primary job (12-mon ref period)
* empldur_orig_2_year = Original employment duration/tenure, second job (12-mon ref period)
destring duration_*_act, replace
label define duration_act 1 "less than or equal to 6 months" 2 "more than 6 months but less than or equal to 1 year" 3 "more than 1 year but less than or equal to 2 years" 4 "more than 2 years but less than or equal to 3 years" 5 "more than three years"
label values duration_prn_act duration_sub_act duration_act
decode duration_prn_act if lstatus_year==1, g(empldur_orig_year)
decode duration_sub_act if lstatus_year==1, g(empldur_orig_2_year)

* empstat_2_year = Employment status, secondary job (12-mon ref period)
recode sub_status (11=4) (12=3) (61 62 21=2) (31 41 42 51 52 71 72 98 =1) (81/97 99=.) (*=.) if lstatus_year==1, g(empstat_2_year)

* ocusec_2_year = Sector of activity, secondary job (12-mon ref period)
recode sub_enterprise (1/4 7 10/12=2) (5/6=1) (8=4) (*=.) if lstatus_year==1, g(ocusec_2_year)

* industry_orig_2_year = Original industry code, secondary job (12-mon ref period)
g industry_orig_2_year = sub_industry if lstatus_year==1

* industrycat10_2_year = 1 digit industry classification, secondary job (12-mon ref period)
gen industrycat10_2_year = floor(sub_industry/1000) if lstatus_year==1

* industrycat4_2_year = 4-category industry classification, secondary job (12-mon ref period)
recode industrycat10_2_year (1=1) (2/5=2) (6/9=3) (10=4) if lstatus_year==1, g(industrycat4_2_year)

* occup_orig_2_year = Original occupational classification, secondary job (12-mon ref period)
tostring sub_occupation, g(occup_orig_2_year)
replace occup_orig_2_year = "" if lstatus_year~=1

* occup_2_year = 1 digit occupational classification, secondary job (12-mon ref period)
g occup_2_year = floor(sub_occupation/100) if lstatus_year==1

* paid_leave_2_year = Eligible for paid leave, secondary job (12-mon ref period)
g paid_leave_2_year = (sub_paid_leave==1) if lstatus_year==1 & ~missing(sub_paid_leave)

* pensions_2_year = Eligible for pension, secondary job (12-mon ref period)
recode sub_soc_security (1 4 5 7=1) (2 3 6 8=0) (*=.) if lstatus_year==1, g(pensions_2_year)

* wmonths_2 = Months worked in the last 12 months for the secondary job
g wmonths_2 = .

* wage_total_2 = Secondary job total wage
g wage_total_2 = .

* firmsize_l_2_year = Firm size (lower bracket), secondary job (12-mon ref period)
recode sub_n_workers (1=1) (2=6) (3=10) (4=20) (*=.) if lstatus_year==1, g(firmsize_l_2_year)

* firmsize_u_2_year = Firm size (upper bracket), secondary job (12-mon ref period)
recode sub_n_workers (1=5) (2=9) (3=19) (*=.) if lstatus_year==1, g(firmsize_u_2_year)

* njobs = Total number of jobs
g njobs = .

* variables for other jobs: none can be created
* unitwage_o = Time unit of last wages payment, other jobs (7-day ref period)
* wage_nc_o = Last week wage payment other jobs (different than primary and secondary)
* wage_nc_week_o = Wage payment adjusted to 1 week, other jobs, excl. bonuses, etc. (7-day ref period)
* wage_total_o = Annualized total wage, other job (7-day ref period)
* whours_o = Hours of work in last week for other jobs
* wmonths_o = Months worked in the last 12 months for the others jobs
foreach var in unitwage_o wage_nc_o wage_nc_week_o wage_total_o whours_o wmonths_o {
	g `var' = .
}

*************
* 7-day recall activities

* minlaborage = Labor module application age (7-day ref period)
g minlaborage = 0

* lstatus = Labor status (7-day ref period)
recode status_cws (11/72=1) (81=2) (91/97=3) (*=.), g(lstatus)

* empstat = Employment status, primary job (7-day ref period)
recode status_cws (11=4) (12=3) (61 62 21=2) (31 41 42 51 52 71 72 98 =1) (81/97 99=.) (*=.) if lstatus==1, g(empstat)

* match daily recall jobs to priamry week recall job
forval day = 1/7 {
	g		act_job1_day`day' = 2 if (status_cws==status_act2_day`day') & (nic_cws==industry_act2_day`day') & !mi(status_cws) & !mi(nic_cws)
	replace act_job1_day`day' = 1 if (status_cws==status_act1_day`day') & (nic_cws==industry_act1_day`day') & !mi(status_cws) & !mi(nic_cws)
	* identify each day's other activity
	recode act_job1_day`day' (2=1) (*=2), g(act_joboth_day`day')
	* consolidate job attribute variables from daily recall activities 1 and 2 into ones for the current week main activity, and other activity
	foreach job_attribute in status industry hours wage {
		foreach activity in job1 joboth {
			clonevar `job_attribute'_`activity'_day`day'=`job_attribute'_act1_day`day'  if act_`activity'_day`day'==1
			replace `job_attribute'_`activity'_day`day'=`job_attribute'_act2_day`day'  if act_`activity'_day`day'==2 
		}
	}
}

* aggregate primary job status, industry, weekly hours (for everyone), and weekly wages (for casual workers)
egen status_job1_week = rowmin(status_job1_day?)
egen industry_job1_week = rowmin(industry_job1_day?)
egen hours_job1_week = rowtotal(hours_job1_day?), missing
egen wage_job1_week = rowtotal(wage_job1_day?), missing

* aggregate secondary job status, industry, weekly hours (for everyone), and weekly wages (for casual workers)
* step 1: find daily recall second job, based on which status+industry combo has the most # of hours among other (non-primary job) activities.
tempfile all_individual_data
save `all_individual_data'
keep hhid pid *_joboth_day?
* reshape wide data (IDs: hhid + pid) to long format (unique IDs: hhid + pid + day)
reshape long status_joboth_day industry_joboth_day hours_joboth_day wage_joboth_day, i(hhid pid) j(day)
* keep only observations with other jobs, to reduce compute time
keep if ~mi(status_joboth_day)
* step 2: sum hours and wages for each person's jobs (status + industry)
collapse (sum) hours_joboth_day wage_joboth_day, by(hhid pid status_joboth_day industry_joboth_day)
* step 3: sort jobs by highest hours first, and break ties in # of hours by keeping the highest wage job, and if that is tied break ties using status code and industry code (ie arbitrary but consistent across executions of the do file).
* note: cannot use "egen hours_joboth_rank = rank(-hours_joboth_day), by(hhid pid) unique" because it breaks ties arbitrarily
gsort hhid pid -hours_joboth_day -wage_joboth_day status_joboth_day industry_joboth_day
* step 4: keep only second job (most # of hours among remaining jobs - see step 3 for how ties in # of hours are broken)
keep if pid~=pid[_n-1]
* rename variables to indentify they are for the 2nd job, and aggregated to the week
rename *_joboth_* *_job2_*
rename *_day *_week
* merge variables back into the full individual data
merge 1:1 hhid pid using `all_individual_data', nogen assert(using match)

* match week-recall job1 with 12-month recall job: 1 "1st job - from section 5.1", 2 "2nd job - from section 5.2"
* step 1: match by exact occupation
	* last week job1 occupation = 2nd occupation if they match and are non-missing
	g		lastweek_job1_12mojob = 2 if (cws_occupation==sub_occupation) & ~missing(cws_occupation)
	* last week job1 occupation = 1st occupation if they match and are non-missing
	replace lastweek_job1_12mojob = 1 if (cws_occupation==prn_occ) & ~missing(cws_occupation)
* step 2: match by status and aggregate occupation category
	* last week job1 status = 12-month job1 status AND last week job1 aggregate occupation category = 12-month job1 aggregate occupation category AND last week status and occupation are non-missing
	replace lastweek_job1_12mojob = 1 if missing(lastweek_job1_12mojob) & (status_cws==prn_status) & (floor(cws_occupation/100)==floor(prn_occ/100)) & ~missing(status_cws) & ~missing(cws_occupation)
	* last week job1 status = 12-month job2 status AND last week job1 aggregate occupation category = 12-month job2 aggregate occupation category AND last week status and occupation are non-missing
	replace lastweek_job1_12mojob = 2 if missing(lastweek_job1_12mojob) & (status_cws==sub_status) & (floor(cws_occupation/100)==floor(sub_occupation/100)) & ~missing(status_cws) & ~missing(cws_occupation)

* empstat_2 = Employment status, secondary job (7-day ref period)
recode status_job2_week (11=4) (12=3) (61 62 21=2) (31 41 42 51 52 71 72 98 =1) (81/97 99=.) (*=.) if lstatus==1, g(empstat_2)

* wage_nc = Wage payment, primary job, excl. bonuses, etc. (7-day ref period)
	* from daily recall workers in "casual labor": 7 days
	g		wage_nc = wage_job1_week if inlist(status_cws,41,42,51) & lstatus==1 & empstat<=4
	* from weekly recall workers in salaried jobs: last calendar month
	replace	wage_nc = earnings_sal if inlist(status_cws,31,71,72) & lstatus==1 & empstat<=4
	* from weekly recall workers in self-employed jobs: 30 days
	replace wage_nc = earnings_selfemp if inlist(status_cws,11,12,61,62) & lstatus==1 & empstat<=4

* unitwage = Time unit of last wages payment, primary job (7-day ref period)
recode status_cws (41 42 51=2) (31 71 72=5) (11 12 61 62=10) (*=.) if lstatus==1 & empstat==1, g(unitwage)
note unitwage: For IND_2021_PLFS, self-employed (status = 11 12 61 62) recall is actually 30 days, so coded as unitwage = 10 "Other" since there was not an exact match.

* wage_nc_week = Wage payment adjusted to 1 week, primary job, excl. bonuses, etc. (7-day ref period)
	* from daily recall workers in "casual labor": 7 days
	g		wage_nc_week = wage_job1_week if inlist(status_cws,41,42,51) & lstatus==1
	* from weekly recall workers in salaried jobs: last calendar month
	replace	wage_nc_week = earnings_sal/4.3 if inlist(status_cws,31,71,72) & lstatus==1
	* from weekly recall workers in self-employed jobs: 30 days
	replace wage_nc_week = earnings_selfemp/30*7 if inlist(status_cws,11,12,61,62) & lstatus==1
	
* wage_nc_2 = Wage payment, secondary job, excl. bonuses, etc. (7-day ref period)
	* from daily recall workers in "casual labor": 7 days
	g		wage_nc_2 = wage_job2_week if inlist(status_job2_week,41,42,51) & lstatus==1 & empstat_2<=4
note wage_nc_2: For IND_2021_PLFS, we could only create this variable for those in "casual labor".

* unitwage_2 = Time unit of last wages payment, secondary job (7-day ref period)
recode status_job2_week (41 42 51=2) (*=.) if lstatus==1 & empstat_2==1, g(unitwage_2)
note unitwage_2: For IND_2021_PLFS, we could only create this variable for those in "casual labor".

* wage_nc_week_2 = Wage payment adjusted to 1 week, secondary job, excl. bonuses, etc. (7-day ref period)
	* from daily recall workers in "casual labor": 7 days
	g		wage_nc_week_2 = wage_job2_week if inlist(status_job2_week,41,42,51) & lstatus==1
note wage_nc_week_2: For IND_2021_PLFS, we could only create this variable for those in "casual labor".

* whours = Hours of work in last week main activity
g whours = hours_job1_week if lstatus==1

* whours_2 = Hours of work in last week for the secondary job
g whours_2 = hours_job2_week if lstatus==1

* contract = Contract (7-day ref period)
g		contract = contract_year if lastweek_job1_12mojob==1 & lstatus==1
* from 12-month recall secondary job
recode sub_job_contract (1=0) (2/4=1) if lstatus_year==1, g(contract_2_year)
replace	contract = contract_2_year if lastweek_job1_12mojob==2 & lstatus==1
note contract: For IND_2021_PLFS, we were only able to create this for a subset of employed individuals.

* empldur_orig = Original employment duration/tenure, primary job (7-day ref period)
g		empldur_orig = empldur_orig_year if lastweek_job1_12mojob==1 & lstatus==1
replace	empldur_orig = empldur_orig_2_year if lastweek_job1_12mojob==2 & lstatus==1

* firmsize_l = Firm size (lower bracket), primary job (7-day ref period)
g		firmsize_l = firmsize_l_year if lastweek_job1_12mojob==1 & lstatus==1
replace	firmsize_l = firmsize_l_2_year if lastweek_job1_12mojob==2 & lstatus==1

* firmsize_u = Firm size (upper bracket), primary job (7-day ref period)
g		firmsize_u = firmsize_u_year if lastweek_job1_12mojob==1 & lstatus==1
replace	firmsize_u = firmsize_u_2_year if lastweek_job1_12mojob==2 & lstatus==1

* healthins = Health insurance (7-day ref period)
g		healthins = healthins_year if lastweek_job1_12mojob==1 & lstatus==1
* from 12-month recall secondary job
recode sub_soc_security (3 5/7=1) (1 2 4 8=0) (*=.) if lstatus_year==1, g(healthins_2_year)
replace healthins = healthins_2_year if lastweek_job1_12mojob==2 & lstatus==1

* industry_orig = Original industry code, primary job (7-day ref period)
tostring nic_cws, g(industry_orig)
replace industry_orig = "" if lstatus~=1

* industry_orig_2 = Original industry code, secondary job (7-day ref period)
tostring industry_job2_week, g(industry_orig_2)
replace industry_orig_2 = "" if lstatus~=1

* industrycat10 = 1 digit industry classification, primary job (7-day ref period)
recode nic_cws (1/3=1) (4/9=2) (10/33=3) (35/39=4) (41/43=5) (45/47 55/56=6) (49/53 58/63 79=7) (64/68 83=8) (84=9) (69/78 80/82 85/99=10) (*=.) if lstatus==1, g(industrycat10)

* industrycat10_2 = 1 digit industry classification, secondary job (7-day ref period)
recode industry_job2_week (1/3=1) (4/9=2) (10/33=3) (35/39=4) (41/43=5) (45/47 55/56=6) (49/53 58/63 79=7) (64/68 83=8) (84=9) (69/78 80/82 85/99=10) (*=.) if lstatus==1, g(industrycat10_2)

* industrycat4 = 4-category industry classification, primary job (7-day ref period)
recode industrycat10 (1=1) (2/5=2) (6/9=3) (10=4) if lstatus==1, g(industrycat4)

* industrycat4_2 = 4-category industry classification, secondary job (7-day ref period)
recode industrycat10_2 (1=1) (2/5=2) (6/9=3) (10=4) if lstatus==1, g(industrycat4_2)

* nlfreason = Reason not in the labor force (7-day ref period)
recode status_cws (91=1) (92 93=2) (94=3) (95=4) (82 96 97=5) (*=.) if lstatus==3, g(nlfreason)

* occup = 1 digit occupational classification, primary job (7-day ref period)
g occup = floor(cws_occupation/100) if lstatus==1

* occup_orig = Original occupational classification, primary job (7-day ref period)
tostring cws_occupation, g(occup_orig)
replace occup_orig = "" if lstatus~=1

* ocusec = Sector of activity, primary job (7-day ref period)
g		ocusec = ocusec_year if lastweek_job1_12mojob==1 & lstatus==1
replace	ocusec = ocusec_2_year if lastweek_job1_12mojob==2 & lstatus==1

* ocusec_2 = Sector of activity, secondary job (7-day ref period)
g ocusec_2 = .

* paid_leave = Eligible for paid leave, primary job (7-day ref period)
g		paid_leave = paid_leave_year if lastweek_job1_12mojob==1 & lstatus==1
replace	paid_leave = paid_leave_2_year if lastweek_job1_12mojob==2 & lstatus==1

* paid_leave_2 = Eligible for paid leave, secondary job (7-day ref period)
g paid_leave_2 = .

* pensions = Eligible for pension, primary job (7-day ref period)
g		pensions = pensions_year if lastweek_job1_12mojob==1 & lstatus==1
replace pensions = pensions_2_year if lastweek_job1_12mojob==2 & lstatus==1

* pensions_2 = Eligible for pension, secondary job (7-day ref period)
g pensions_2 = .

* socialsec = Social security (7-day ref period)
g		socialsec = socialsec_year if lastweek_job1_12mojob==1 & lstatus==1
* from 12-month recall secondary job
recode sub_soc_security (1/7=1) (8=0) (*=.) if lstatus_year==1, g(socialsec_2_year)
replace	socialsec = socialsec_2_year if lastweek_job1_12mojob==2 & lstatus==1
note socialsec: For IND_2021_PLFS, we considered any of the following benefits as social security: pension, gratuity, or health.

* unempldur_l = Unemployment duration (months) lower bracket (7-day ref period)
g unempldur_l = unempldur_l_year if lstatus==2

* unempldur_u = Unemployment duration (months) upper bracket (7-day ref period)
g unempldur_u = unempldur_u_year if lstatus==2

* wage_total = Annualized total wage, primary job (7-day ref period)
g wage_total = .

* wmonths = Months worked in the last 12 months main activity
g wmonths = .

* union = Union membership (7-day ref period)
g union = .

* label all SARLD harmonized variables and values
do "${rootlabels}/label_SARLAB_variables.do"
save "${output}/`surveyfolder'_v`vm'_M_v`va'_A_`type'_TMP", replace
keep ${keepharmonized}
* save harmonized data
save "${output}/`surveyfolder'_v`vm'_M_v`va'_A_`type'_IND", replace
