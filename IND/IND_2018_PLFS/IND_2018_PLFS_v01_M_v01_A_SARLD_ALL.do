***********************************************************************
*	IND_2018_PLFS
*	SAR Labor Harmonization
*	May 2023
*	Joseph Green, josephgreen@gmail.com
***********************************************************************
clear
set more off
local countrycode	"IND"
local year			"2018"
local survey		"PLFS"
local va			"01"
local vm			"01"
local type			"SARLAB"
local surveyfolder	"`countrycode'_`year'_`survey'"

* global path on Joe's computer
if ("`c(username)'"=="sunquat") {
	* define folder paths
	glo rootdatalib "/Users/sunquat/Projects/WORLD BANK/SAR - labor harmonization/SARLD/WORKINGDATA"
	glo rootlabels "/Users/sunquat/Projects/WORLD BANK/SAR - labor harmonization/SARLD/_aux"
}
* global paths on WB computer
else {
	* NOTE: TODO: You (WB staff) will need to define the location of the datalibweb folder path here.
		tempfile hhvisit1
	datalibweb, country(`countrycode') year(`year') survey(`survey') type(SARRAW) filename(hhvisit1_2018-19.dta) localpath(${rootdatalib}) local
	drop state district nssregion stratum substratum subsample no_qtr
	save `hhvisit1', replace
	* start with individual data
	datalibweb, country(`countrycode') year(`year') survey(`survey') type(SARRAW) filename(personvisit1_2018-19.dta) localpath(${rootdatalib}) local
	* merge in HH data
	merge m:1 hhid using `hhvisit1', nogen assert(match)
}
glo surveydata	"${rootdatalib}/`countrycode'/`surveyfolder'/`surveyfolder'_v`vm'_M/Data/Stata"
glo output		"${rootdatalib}/`countrycode'/`surveyfolder'/`surveyfolder'_v`vm'_M_v`va'_A_`type'/Data/Harmonized"
cap mkdir "${rootdatalib}/`countrycode'/`surveyfolder'"
cap mkdir "${rootdatalib}/`countrycode'/`surveyfolder'/`surveyfolder'_v`vm'_M_v`va'_A_`type'"
cap mkdir "${rootdatalib}/`countrycode'/`surveyfolder'/`surveyfolder'_v`vm'_M_v`va'_A_`type'/Data"
cap mkdir "${rootdatalib}/`countrycode'/`surveyfolder'/`surveyfolder'_v`vm'_M_v`va'_A_`type'/Data/Harmonized"
cap mkdir "${rootdatalib}/`countrycode'/`surveyfolder'/`surveyfolder'_v`vm'_M_v`va'_A_`type'/Program"
* load data on Joe's computer
if ("`c(username)'"=="sunquat") {
	* load data and merge
	* start with HH data
	use "${surveydata}/hhvisit1_2018-19", clear
	drop state district nssregion stratum substratum subsample no_qtr
	* merge with individual data
	merge 1:m hhid using "${surveydata}/personvisit1_2018-19", nogen assert(match)
}

* countrycode = country code
g countrycode = "`countrycode'"

* year = Year
g year = `year'

* int_year = interview year
g		int_year = 2017 if inlist(quarter,"Q5","Q6")
replace	int_year = 2018 if inlist(quarter,"Q7","Q8")

* int_month = interview month
g int_month = month if inrange(month,1,12)
* fill missing values with mode interview month by fsu
bys fsu: egen auxmonth = mode(int_month)
replace int_month = auxmonth if missing(int_month)
* fill missing values with mode interview month by quarter
bys quarter stratum: egen auxmonth2 = mode(int_month)
replace int_month = auxmonth2 if missing(int_month)
assert ~missing(int_month)

* hhid = Household identifier
* NOTE: hhid = 4VVFFFFFBSHH
*	quarter				: quarter of interview (Q3,Q4,Q1,Q2)
*	visit				: visit
*	fsu					: first segment unit
*	sample_sg			: segment block number?
*	stage2_stratumno	: second stage stratum
*	hhno				: HH number
confirm var hhid

* pid = Personal identifier
rename personno pid

* confirm unique identifiers: hhid + pid
isid hhid pid

* weight = Household weight
g weight = hhwt

* relationharm = Relationship to head of household harmonized across all regions
recode relationtohead (1=1) (2=2) (3 5=3) (4 6=5) (7/8=4) (9=7) (*=.), g(relationharm)
note relationharm: For IND_2018_PLFS, the survey variable relationtohead = 7 "father/mother/father-in-law/mother-in-law" overlapped with two harmonized categories and was coded as 4 "parents".
note relationharm: For IND_2018_PLFS, the survey variable relationtohead = 9 "servants/employees/other non-relatives" overlapped with two harmonized categories and was coded as 7 "non household members (domestic worker, room renter)".

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
decode state, g(subnatid1)
replace subnatid1 = string(state) + " - " + subnatid1

* subnatid2 = Subnational ID - second highest level
g subnatid2 = ""

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
recode geneducation (1/4=1) (5=2) (6=3) (7=4) (8/10=5) (11=6) (12/13=7) (*=.), g(educat7)

* educat5 = Highest level of education completed (5 categories)
recode educat7 (0=0) (1=1) (2=2) (3/4=3) (5=4) (6/7=5), g(educat5)

* educat4 = Highest level of education completed (4 categories)
recode educat7 (0=0) (1=1) (2/3=2) (4/5=3) (6/7=4), g(educat4)

* educy = Years of completed education
g educy = noyrsformaled

* literacy = Individual can read and write
recode geneducation (1=0) (2/13=1), g(literacy)
note literacy: For IND_2018_PLFS, we used the general education variable that specified literate or non-literate, but didn't specify whether or not their definition of literacy included both reading and writing.

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

* minlaborage_year = Labor module application age (12-mon ref period)
g minlaborage_year = 0

* lstatus_year = Labor status (12-mon ref period)
recode status_prn (11/51 = 1) (81=2) (91/97=3) (99=.a) (*=.), g(lstatus_year)

* nlfreason_year = Reason not in the labor force (12-mon ref period)
recode status_prn (91=1) (92 93=2) (94=3) (95=4) (82 96 97=5) (*=.) if lstatus_year==3, g(nlfreason_year)

* unempldur_l_year = Unemployment duration (months) lower bracket (12-mon ref period)
g unempldur_l_year = .

* unempldur_u_year = Unemployment duration (months) upper bracket (12-mon ref period)
g unempldur_u_year = .

* empstat_year = Employment status, primary job (12-mon ref period)
recode status_prn (11=4) (12=3) (61 62 21=2) (31 41 42 51 52 71 72 98 =1) (81/97 99=.) (*=.) if lstatus_year==1, g(empstat_year)

* ocusec_year = Sector of activity, primary job (12-mon ref period)
recode enttype_prn (1/4 7 10/12=2) (5/6=1) (8=4) (*=.) if lstatus_year==1, g(ocusec_year)

* industry_orig_year = Original industry code, primary job (12-mon ref period)
tostring nic_prn, g(industry_orig_year)
replace industry_orig_year = "" if lstatus_year~=1

* industrycat10_year = 1 digit industry classification, primary job (12-mon ref period)
gen industrycat10_year = floor(nic_prn/1000) if lstatus_year==1
recode industrycat10_year (1/3=1) (4/9=2) (10/33=3) (35/39=4) (41/43=5) (45/47 55/56=6) (49/53 58/63 79=7) (64/68 83=8) (84=9) (69/78 80/82 85/99=10) (*=.)
	
* industrycat4_year = 4-category industry classification, primary job (12-mon ref period)
recode industrycat10_year (1=1) (2/5=2) (6/9=3) (10=4) if lstatus_year==1, g(industrycat4_year)

* occup_orig_year = Original occupational classification, primary job (12-mon ref period)
g occup_orig_year = nco_prn if lstatus_year==1

* occup_year = 1 digit occupational classification, primary job (12-mon ref period)
g occup_year = floor(nco_prn/100) if lstatus_year==1

* contract_year = Contract (12-mon ref period)
recode jobcontract_prn (1=0) (2/4=1) if lstatus_year==1, g(contract_year)
note contract_year: For IND_2019_PLFS, the source variable was only constructed for a subset of employed people.

* socialsec_year = Social security (12-mon ref period)
la def socialsecurity_prn ///
1 "pension" ///
2 "gratuity" ///
3 "health" ///
4 "pension and gratuity" ///
5 "pension and health" ///
6 "gratuity and health" ///
7 "pension, gratuity, and health" ///
8 "none" ///
9 "not known" 
la val socialsecurity_prn socialsecurity_prn
recode socialsecurity_prn (1/7=1) (8=0) (*=.) if lstatus_year==1, g(socialsec_year)
note socialsec_year: For IND_2019_PLFS, we considered any of the following benefits as social security: pension, gratuity, or health.

* healthins_year = Health insurance (12-mon ref period)
recode socialsecurity_prn (3 5/7=1) (1 2 4 8=0) (*=.) if lstatus_year==1, g(healthins_year)

* pensions_year = Pension main activity (12-mon ref period)
recode socialsecurity_prn (1 4 5 7=1) (2 3 6 8=0) (*=.) if lstatus_year==1, g(pensions_year)

* paid_leave_year = Eligible for paid leave, primary job (12-mon ref period)
g paid_leave_year = (paidleave_prn==1) if lstatus_year==1 & ~missing(paidleave_prn)

* union_year = Union membership (12-mon ref period)
g union_year = .

* firmsize_l_year = Firm size (lower bracket), primary job (12-mon ref period)
recode entwrk_prn (1=1) (2=6) (3=10) (4=20) (*=.) if lstatus_year==1, g(firmsize_l_year)

* firmsize_u_year = Firm size (upper bracket), primary job (12-mon ref period)
recode entwrk_prn (1=5) (2=9) (3=19) (*=.) if lstatus_year==1, g(firmsize_u_year)

* empldur_orig_year = Original employment duration/tenure, primary job (12-mon ref period)
g empldur_orig_year = .

* empldur_orig_2_year = Original employment duration/tenure, second job (12-mon ref period)
g empldur_orig_2_year = .

* empstat_2_year = Employment status, secondary job (12-mon ref period)
recode status_sbs (11=4) (12=3) (61 62 21=2) (31 41 42 51 52 71 72 98 =1) (81/97 99=.) (*=.) if lstatus_year==1, g(empstat_2_year)

* ocusec_2_year = Sector of activity, secondary job (12-mon ref period)
recode enttype_sbs (1/4 7 10/12=2) (5/6=1) (8=4) (*=.) if lstatus_year==1, g(ocusec_2_year)

* industry_orig_2_year = Original industry code, secondary job (12-mon ref period)
g industry_orig_2_year = nic_sbs if lstatus_year==1

* industrycat10_2_year = 1 digit industry classification, secondary job (12-mon ref period)
gen industrycat10_2_year = floor(nic_sbs/1000) if lstatus_year==1

* industrycat4_2_year = 4-category industry classification, secondary job (12-mon ref period)
recode industrycat10_2_year (1=1) (2/5=2) (6/9=3) (10=4) if lstatus_year==1, g(industrycat4_2_year)

* occup_orig_2_year = Original occupational classification, secondary job (12-mon ref period)
tostring nco_sbs, g(occup_orig_2_year)
replace occup_orig_2_year = "" if lstatus_year~=1

* occup_2_year = 1 digit occupational classification, secondary job (12-mon ref period)
g occup_2_year = floor(nco_sbs/100) if lstatus_year==1

* paid_leave_2_year = Eligible for paid leave, secondary job (12-mon ref period)
g paid_leave_2_year = (paidleave_sbs==1) if lstatus_year==1 & ~missing(paidleave_sbs)

* pensions_2_year = Eligible for pension, secondary job (12-mon ref period)
recode socialsecurity_sbs (1 4 5 7=1) (2 3 6 8=0) (*=.) if lstatus_year==1, g(pensions_2_year)

* wmonths_2 = Months worked in the last 12 months for the secondary job
g wmonths_2 = .

* wage_total_2 = Secondary job total wage
g wage_total_2 = .

* firmsize_l_2_year = Firm size (lower bracket), secondary job (12-mon ref period)
recode entwrk_sbs (1=1) (2=6) (3=10) (4=20) (*=.) if lstatus_year==1, g(firmsize_l_2_year)

* firmsize_u_2_year = Firm size (upper bracket), secondary job (12-mon ref period)
recode entwrk_sbs (1=5) (2=9) (3=19) (*=.) if lstatus_year==1, g(firmsize_u_2_year)

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
local status "status"
local industry "nic"
local hours "hrsactual"
local wage "wage"
forval day = 1/7 {
	g		act_job1_day`day' = 2 if (status_cws==status_act2_day`day') & (nic_cws==nic_act2_day`day') & !mi(status_cws) & !mi(nic_cws)
	replace act_job1_day`day' = 1 if (status_cws==status_act1_day`day') & (nic_cws==nic_act1_day`day') & !mi(status_cws) & !mi(nic_cws)
	* identify each day's other activity
	recode act_job1_day`day' (2=1) (*=2), g(act_joboth_day`day')
	* consolidate job attribute variables from daily recall activities 1 and 2 into ones for the current week main activity, and other activity
	foreach job_attribute in status industry hours wage {
		foreach activity in job1 joboth {
			clonevar `job_attribute'_`activity'_day`day'=``job_attribute''_act1_day`day'  if act_`activity'_day`day'==1
			replace `job_attribute'_`activity'_day`day'=``job_attribute''_act2_day`day'  if act_`activity'_day`day'==2 
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
* step 3: rank jobs by highest hours first
egen hours_joboth_rank = rank(-hours_joboth_day), by(hhid pid) unique
* step 4: keep only second job (most # of hours)
keep if hours_joboth_rank==1
* rename variables to indentify they are for the 2nd job, and aggregated to the week
drop hours_joboth_rank
rename *_joboth_* *_job2_*
rename *_day *_week
* merge variables back into the full individual data
merge 1:1 hhid pid using `all_individual_data', nogen assert(using match)

* match week-recall job1 with 12-month recall job: 1 "1st job - from section 5.1", 2 "2nd job - from section 5.2"
* step 1: match by exact occupation
	* last week job1 occupation = 2nd occupation if they match and are non-missing
	g		lastweek_job1_12mojob = 2 if (nco_cws==nco_sbs) & ~missing(nco_cws)
	* last week job1 occupation = 1st occupation if they match and are non-missing
	replace lastweek_job1_12mojob = 1 if (nco_cws==nco_prn) & ~missing(nco_cws)
* step 2: match by status and aggregate occupation category
	* last week job1 status = 12-month job1 status AND last week job1 aggregate occupation category = 12-month job1 aggregate occupation category AND last week status and occupation are non-missing
	replace lastweek_job1_12mojob = 1 if missing(lastweek_job1_12mojob) & (status_cws==status_prn) & (floor(nco_cws/100)==floor(nco_prn/100)) & ~missing(status_cws) & ~missing(nco_cws)
	* last week job1 status = 12-month job2 status AND last week job1 aggregate occupation category = 12-month job2 aggregate occupation category AND last week status and occupation are non-missing
	replace lastweek_job1_12mojob = 2 if missing(lastweek_job1_12mojob) & (status_cws==status_sbs) & (floor(nco_cws/100)==floor(nco_sbs/100)) & ~missing(status_cws) & ~missing(nco_cws)

* empstat_2 = Employment status, secondary job (7-day ref period)
recode status_job2_week (11=4) (12=3) (61 62 21=2) (31 41 42 51 52 71 72 98 =1) (81/97 99=.) (*=.) if lstatus==1, g(empstat_2)

* wage_nc = Wage payment, primary job, excl. bonuses, etc. (7-day ref period)
	* from daily recall workers in "casual labor": 7 days
	g		wage_nc = wage_job1_week if inlist(status_cws,41,42,51) & lstatus==1 & empstat<=4
	* from weekly recall workers in salaried jobs: last calendar month
	replace	wage_nc = earnings_monthly_wage if inlist(status_cws,31,71,72) & lstatus==1 & empstat<=4
	* from weekly recall workers in self-employed jobs: 30 days
	replace wage_nc = earning_monthly_selfempl if inlist(status_cws,11,12,61,62) & lstatus==1 & empstat<=4

* unitwage = Time unit of last wages payment, primary job (7-day ref period)
recode status_cws (41 42 51=2) (31 71 72=5) (11 12 61 62=10) (*=.) if lstatus==1 & empstat==1, g(unitwage)
note unitwage: For IND_2019_PLFS, self-employed (status = 11 12 61 62) recall is actually 30 days, so coded as unitwage = 10 "Other" since there was not an exact match.

* wage_nc_week = Wage payment adjusted to 1 week, primary job, excl. bonuses, etc. (7-day ref period)
	* from daily recall workers in "casual labor": 7 days
	g		wage_nc_week = wage_job1_week if inlist(status_cws,41,42,51) & lstatus==1
	* from weekly recall workers in salaried jobs: last calendar month
	replace	wage_nc_week = earnings_monthly_wage/4.3 if inlist(status_cws,31,71,72) & lstatus==1
	* from weekly recall workers in self-employed jobs: 30 days
	replace wage_nc_week = earning_monthly_selfempl/30*7 if inlist(status_cws,11,12,61,62) & lstatus==1
	
* wage_nc_2 = Wage payment, secondary job, excl. bonuses, etc. (7-day ref period)
	* from daily recall workers in "casual labor": 7 days
	g		wage_nc_2 = wage_job2_week if inlist(status_job2_week,41,42,51) & lstatus==1 & empstat_2<=4
note wage_nc_2: For IND_2019_PLFS, we could only create this variable for those in "casual labor".

* unitwage_2 = Time unit of last wages payment, secondary job (7-day ref period)
recode status_job2_week (41 42 51=2) (*=.) if lstatus==1 & empstat_2==1, g(unitwage_2)
note unitwage_2: For IND_2019_PLFS, we could only create this variable for those in "casual labor".

* wage_nc_week_2 = Wage payment adjusted to 1 week, secondary job, excl. bonuses, etc. (7-day ref period)
	* from daily recall workers in "casual labor": 7 days
	g		wage_nc_week_2 = wage_job2_week if inlist(status_job2_week,41,42,51) & lstatus==1
note wage_nc_week_2: For IND_2019_PLFS, we could only create this variable for those in "casual labor".

* whours = Hours of work in last week main activity
g whours = hours_job1_week if lstatus==1

* whours_2 = Hours of work in last week for the secondary job
g whours_2 = hours_job2_week if lstatus==1

* contract = Contract (7-day ref period)
g		contract = contract_year if lastweek_job1_12mojob==1 & lstatus==1
* from 12-month recall secondary job
recode jobcontract_sbs (1=0) (2/4=1) if lstatus_year==1, g(contract_2_year)
replace	contract = contract_2_year if lastweek_job1_12mojob==2 & lstatus==1
note contract: For IND_2019_PLFS, we were only able to create this for a subset of employed individuals.

* empldur_orig = Original employment duration/tenure, primary job (7-day ref period)
g		empldur_orig = .

* firmsize_l = Firm size (lower bracket), primary job (7-day ref period)
g		firmsize_l = firmsize_l_year if lastweek_job1_12mojob==1 & lstatus==1
replace	firmsize_l = firmsize_l_2_year if lastweek_job1_12mojob==2 & lstatus==1

* firmsize_u = Firm size (upper bracket), primary job (7-day ref period)
g		firmsize_u = firmsize_u_year if lastweek_job1_12mojob==1 & lstatus==1
replace	firmsize_u = firmsize_u_2_year if lastweek_job1_12mojob==2 & lstatus==1

* healthins = Health insurance (7-day ref period)
g		healthins = healthins_year if lastweek_job1_12mojob==1 & lstatus==1
* from 12-month recall secondary job
recode socialsecurity_sbs (3 5/7=1) (1 2 4 8=0) (*=.) if lstatus_year==1, g(healthins_2_year)
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
g occup = floor(nco_cws/100) if lstatus==1

* occup_orig = Original occupational classification, primary job (7-day ref period)
tostring nco_cws, g(occup_orig)
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
recode socialsecurity_sbs (1/7=1) (8=0) (*=.) if lstatus_year==1, g(socialsec_2_year)
replace	socialsec = socialsec_2_year if lastweek_job1_12mojob==2 & lstatus==1
note socialsec: For IND_2019_PLFS, we considered any of the following benefits as social security: pension, gratuity, or health.

* unempldur_l = Unemployment duration (months) lower bracket (7-day ref period)
g unempldur_l = .

* unempldur_u = Unemployment duration (months) upper bracket (7-day ref period)
g unempldur_u = .

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
