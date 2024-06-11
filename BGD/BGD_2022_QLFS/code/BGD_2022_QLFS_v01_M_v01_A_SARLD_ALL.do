***********************************************************************
*	BGD_2022_QLFS
*	SAR Labor Harmonization
*	Updated April 2024
*	Sizhen Fang, sfang2@worldbank.org
***********************************************************************
clear
set more off
local countrycode	"BGD"
local year			"2022"
local survey		"QLFS"
local va			"01"
local vm			"01"
local type			"SARLAB"
local surveyfolder	"`countrycode'_`year'_`survey'"

* global path
* SF
if ("`c(username)'"=="wb611670") {
* define folder paths
glo rootdatalib "C:\Users\wb611670\WBG\Laura Liliana Moreno Herrera - 09.SARLAB\WORKINGDATA"
	glo rootlabels "C:\Users\wb611670\WBG\Laura Liliana Moreno Herrera - 09.SARLAB\SARLD_programs\_aux"
}

glo surveydata	"${rootdatalib}/`countrycode'/`surveyfolder'/`surveyfolder'_v`vm'_M/Data/Stata"
glo output		"${rootdatalib}/`countrycode'/`surveyfolder'/`surveyfolder'_v`vm'_M_v`va'_A_`type'/Data/Harmonized"
cap mkdir "${rootdatalib}/`countrycode'/`surveyfolder'"
cap mkdir "${rootdatalib}/`countrycode'/`surveyfolder'/`surveyfolder'_v`vm'_M_v`va'_A_`type'"
cap mkdir "${rootdatalib}/`countrycode'/`surveyfolder'/`surveyfolder'_v`vm'_M_v`va'_A_`type'/Data"
cap mkdir "${rootdatalib}/`countrycode'/`surveyfolder'/`surveyfolder'_v`vm'_M_v`va'_A_`type'/Data/Harmonized"
cap mkdir "${rootdatalib}/`countrycode'/`surveyfolder'/`surveyfolder'_v`vm'_M_v`va'_A_`type'/Program"

* load data
use "P:\SARMD\SARDATABANK\WORKINGDATA\BGD\BGD_2022_QLFS\BGD_2022_QLFS_v01_M\Data\Stata\BGD_LFS_2022.dta", clear

* countrycode = country code
g countrycode = "`countrycode'"

* year = Year
g year = 2022

* int_year = interview year
g int_year = 2022

* int_month = interview month 
g int_month = V1_MONTH
replace int_month = V2_MONTH if missing(int_month)
replace int_month = V3_MONTH if missing(int_month)
replace int_month = . if int_month > 12

* hhid = Household identifier
gen psu_str = string(PSU, "%04.0f")
gen eaum_str  = string(EAUM, "%03.0f")
gen hh_str  = string(HHNO, "%03.0f")
egen hhid = concat(psu_str eaum_str hh_str)

* pid = Personal identifier
gen lineno_str = string(EMP_HRLN, "%02.0f")
gen mgt_str  = string(MGT_LN, "%03.0f")
gen mlab = "m"
egen mgt_ln = concat(mgt_str mlab)
replace lineno_str = mgt_ln if missing(EMP_HRLN)
egen pid = concat(hhid lineno_str)
duplicates drop pid qtr, force // 4 obs dropped
drop mgt_str mlab mgt_ln
* In BGD 2022, hhid and pid are not unique ids. same individual is visited acrossed multiple quarters

* weight = Household weight
* weight is divided by 4 to match up with the total popualtion
gen weight = wgt_lfs2022Q1Adj if qtr == 1
replace weight = wgt_lfs2022Q2Adj if qtr == 2
replace weight = wgt_lfs2022Q3Adj if qtr == 3
replace weight = wgt_lfs2022Q4Adj if qtr == 4
replace weight = weight/4

* relationcs = Original relationship to head of household
gen relationcs = relation

* relationharm = Relationship to head of household harmonized across all regions
* adapted from BGD BBS code
* 1 "head" 2 "spouse" 3 "children" 4 "parents" 5 "other relatives" 6 "non-relatives" 7 "non household members (domestic worker, room renter)"
gen relationharm=relation
recode relationharm (1 = 1) (2 = 2) (3 = 3)(4 = 4)(5 7 = 5)(6 8 = 7)

* household member. All excluding household workers
gen hhmember=(~inlist(relationharm,7,.))

* hsize = Household size, not including household workers
bys hhid: egen hsize=total(hhmember)

* strata = Strata
g strata = .

* spdef = Spatial deflator (if one is used)
g spdef = .

* subnatid1 = Subnational ID - highest level
gen str subnatid1 = ""
replace subnatid1 = "10 - Barisal" if DIV_CODE== 10
replace subnatid1 = "20 - Chittagong" if DIV_CODE == 20
replace subnatid1 = "30 - Dhaka" if DIV_CODE == 30
replace subnatid1 = "40 - Khulna" if DIV_CODE == 40
replace subnatid1 = "45 - Mymensingh" if DIV_CODE == 45
replace subnatid1 = "50 - Rajshahi" if DIV_CODE == 50
replace subnatid1 = "55 - Rangpur" if DIV_CODE == 55
replace subnatid1 = "60 - Sylhet" if DIV_CODE == 60

replace subnatid1 = "20 - Chittagong" if DIVISION == "CHATTOGRAM"
replace subnatid1 = "30 - Dhaka" if DIVISION == "Dhaka"
replace subnatid1 = "30 - Dhaka" if DIVISION == "DHAKA"
replace subnatid1 = "10 - Barisal" if DIVISION == "Barisal"
replace subnatid1 = "40 - Khulna" if DIVISION == "Khulna"

* subnatid2 = Subnational ID - second highest level
tostring UPZ_CODE, gen(upz_codestr)
gen str subnatid2 = upz_codestr + " - " + UPZ

* subnatid3 = Subnational ID - third highest level
g subnatid3 = ""

* urban = Urban (1) or rural (0)	
gen urban = BBS_geo
recode urban (2=0)
drop if urban > 1

* psu = PSU
gen psu = PSU

* language = Language
g language = ""

* age = Age of individual (continuous)
confirm var age

* male = Sex of household member (male=1)
recode male (2 = 0)
drop if male > 1

* marital = Marital status
* 1 “married” 2 “never married” 3 “living together” 4 “divorced/separated” 5 “widowed”
recode marital (2 = 1) (1 = 2) (3 = 5) (4 5 = 4)
replace marital = 1 if MGT_01E == "Y"
replace marital = 2 if MGT_01E == "N"

// * eye_dsablty = Difficulty seeing
// * 1 “No – no difficulty” 2 “Yes – some difficulty” 3 “Yes – a lot of difficulty” 4 “Cannot do at all” 5 “Yes - severity unknown”
// * BGD 2022 only records disability as yes or no (no levels)
// gen eye_dsablty = difsee
// recode eye_dsablty (0 = 1)(5 = 2)

// * hear_dsablty = Difficulty hearing
// gen hear_dsablty = difhear
// recode hear_dsablty (0 = 1)(5 = 2)

// * walk_dsablty = Difficulty walking or climbing steps
// gen walk_dsablty = difwalk
// recode walk_dsablty (0 = 1)(5 = 2)

// * conc_dsord = Difficulty remembering or concentrating
// gen conc_dsord = difremember
// recode conc_dsord (0 = 1)(5 = 2)

// * slfcre_dsablty = Difficulty with self-care
// gen slfcre_dsablty = difselfcare
// recode slfcre_dsablty (0 = 1)(5 = 2)

// * comm_dsablty = Difficulty communicating
// gen comm_dsablty = difcommunicate
// recode comm_dsablty (0 = 1)(5 = 2)

foreach unavailable_var in eye_dsablty hear_dsablty walk_dsablty conc_dsord slfcre_dsablty comm_dsablty {
	g `unavailable_var' = .
}

* educat7 = Highest level of education completed (7 categories)
* 0 “religious education” 1 “no education”  2 “primary incomplete” 3 “primary complete” 
* 4 “secondary incomplete" 5 “secondary complete”  6 “Higher than secondary but not university”  
* 7 “university incomplete or complete"
gen byte educat7 =.
replace educat7 = EDU_04
recode educat7 (0 = 1) (1 2 3 4 5 = 2) (6 = 3) (7 8 9 = 4) (10 = 5)(11 = 6)(12 13 14 15 = 7) (16 = 0)
		  
* educat5 = Highest level of education completed (5 categories)
gen byte educat5 = educat7
recode educat5 4=3 5=4 6 7=5

* educat4 = Highest level of education completed (4 categories)
gen byte educat4 = educat7
recode educat4 (2 3 4 = 2) (5=3) (6 7=4)

* educy = Years of completed education
g educy = .

* literacy = Individual can read and write
g literacy = . 

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

* minlaborage - Labor module application age (7-day ref period)
g minlaborage = 15

* lstatus - Labor status (7-day ref period)
* 1 "Employed" 2 "Unemployed" 3 "Not in labor force"
gen byte lstatus = .
replace lstatus = 1 if EMP_01 == 1 //worked for wage
replace lstatus = 1 if EMP_02 == 1 //worked for business, farming, others
replace lstatus = 1 if EMP_03 == 1 //worked unpaid in family bussiness
replace lstatus = 1 if EMP_04 == 1 //produced goods and agri
replace lstatus = 1 if EMP_06 == 1 //employed but absent
replace lstatus = 2 if JSA_01 == 1 & JSA_06 == 1 //looking to start a new job
replace lstatus = 2 if JSA_02 == 1 & JSA_06 == 1 //looking to start a new business 
replace lstatus = 3 if missing(lstatus)
replace lstatus = . if age < minlaborage

* empstat - Employment status, primary job (7-day ref period)
* 1 "Paid Employee" 2 "Non-Paid Employee" 3 "Employer" 4 "Self-employed" 
* 5 "Other, workers not classifiable by status" 6 "independent contractor"
gen byte empstat=.
replace empstat = 1 if MJ_05 == 1
replace empstat = 2 if MJ_05 == 7
replace empstat = 3 if MJ_05 == 5
replace empstat = 4 if MJ_05 == 6
replace empstat = 5 if MJ_05 == 99
replace empstat = . if lstatus != 1

* contract - Contract (7-day ref period)
gen byte contract = .
replace contract = 1 if MJ_06 == 1 | MJ_06 == 2
replace contract = 0 if MJ_06 == 3 | MJ_06 == 97
replace contract = 0 if missing(MJ_06) & lstatus == 1

* empldur_orig = Original employment duration/tenure, primary job (7-day ref period)
g empldur_orig = .

* industry_orig - Original industry code, primary job (7-day ref period)
tostring MJ_04C, gen (industry_orig)
replace industry_orig = "" if lstatus != 1

* industrycat10 - 10-category industry classification, primary job (7-day ref period) 
gen isic2d = floor(MJ_04C/1000)
drop if isic2d < 1
gen industrycat10 = .
replace industrycat10 = isic2d
recode industrycat10 (1/3=1) (5/9 = 2) (10/33 = 3) (35/39 = 4) (41/43 = 5) (45/47 55/56 = 6) (49/53 58/63 = 7) (64/82 = 8) (84 = 9) (85/99 = 10)	
drop isic2d

* industrycat4 - 4-category industry classification, primary job (7-day ref period)
gen byte industrycat4 = industrycat10
recode industrycat4 (1=1)(2 3 4 5 =2)(6 7 8 9=3)(10=4)

* nlfreason - Reason not in the labor force (7-day ref period)
* Note: there is a question on the survey but the corresponding variable in LFS is unrecognizable 
gen byte nlfreason=.

* occup - 1 digit occupational classification, primary job (7-day ref period)
gen byte occup = .
replace occup = BSCO_prof_struc if lstatus == 1
recode occup (. = 96) 

* occup_orig - Original occupational classification, primary job (7-day ref period)
gen occup_orig = MJ_09 if lstatus == 1

* ocusec - Sector of activity, primary job (7-day ref period)
* 1 "Public sector, Central Government, Army" 2 "Private, NGO" 3 "State owned" 4 "Public or State-owned, but cannot distinguish"
gen byte ocusec = .
replace ocusec = MJ_09 if lstatus == 1
recode ocusec (1 3 9 = 1) (4 5 6 7 8 = 2) (2 = 4) (99=.)

* unempldur_l - Unemployment duration (months) lower bracket (7-day ref period)
gen byte unempldur_l= .

* unempldur_u - Unemployment duration (months) upper bracket (7-day ref period)
gen byte unempldur_u= .

* unitwage - Time unit of last wages payment, primary job (7-day ref period)
* 1 "Daily" 2 "Weekly" 3 "Every two weeks" 4 "Every two months" 5 "Monthly" 6 "Quarterly" 7 "Every six months" 8 "Annually" 9 "Hourly" 10 "Other"
gen byte unitwage = .
replace unitwage = MJ_14
recode unitwage (3 = 5)(99 = 10)
replace unitwage = . if lstatus !=1

* wage_nc - Wage payment, primary job, excl. bonuses, etc. (7-day ref period)
gen double wage_nc = MJ_15C if lstatus == 1
recode wage_nc (0 = .)
replace wage_nc = . if missing(empstat)

* wage_nc_week - Wage payment adjusted to 1 week, primary job, excl. bonuses, etc. (7-day ref period)
g wage_nc_week = wage_nc/4.3 if lstatus==1 & ~mi(wage_nc)

* wage_total - Annualized total wage, primary job (7-day ref period)
g wage_total = wage_nc_week * 4.3 * 12 if lstatus==1 & ~mi(wage_nc)

* empstat_2 - Employment status, secondary job (7-day ref period)
* 1 "Paid Employee" 2 "Non-Paid Employee" 3 "Employer" 4 "Self-employed" 
* 5 "Other, workers not classifiable by status" 6 "independent contractor"
gen byte empstat_2 = .
replace empstat_2 = SJ_03
recode empstat_2 (1 2 3 4  = 1) (7 = 2) (5 = 3) (6 = 4) (8 = 5)
replace empstat_2 = . if lstatus != 1
	
* wage_nc_2 - Wage payment, secondary job, excl. bonuses, etc. (7-day ref period)
gen double wage_nc_2 = SJ_05C if lstatus == 1
recode wage_nc_2 (0 = .)
replace wage_nc_2 = . if missing(empstat_2)

* unitwage_2 - Time unit of last wages payment, secondary job (7-day ref period)
gen byte unitwage_2 = .
replace unitwage_2 = SJ_04
recode unitwage_2 (3 = 5)(99 = 10)
replace unitwage_2 = . if lstatus !=1

* wage_nc_week_2 - Wage payment adjusted to 1 week, secondary job, excl. bonuses, etc. (7-day ref period)
g wage_nc_week_2 = wage_nc_2/4.3 if lstatus==1 & ~mi(wage_nc_2)

* wage_total_2 - Annualized total wage, primary job (7-day ref period)
g wage_total_2 = wage_nc_week_2 *4.3 * 12 if lstatus==1 & ~mi(wage_nc_2)

* whours - Hours of work in last week main activity
gen whours = WT_01MJ
replace whours = . if whours == 0 
replace whours = . if lstatus != 1

* whours_2 - Hours of work in last week for the secondary job
gen whours_2 =  WT_01SJ
replace whours_2 = . if whours_2 == 0 | whours_2 == 99
replace whours_2 = . if missing(empstat_2)

* wmore - Willingness to work for more hours
gen wmore = .
replace wmore = 1 if WT_05 == 1 
replace wmore = 0 if WT_05 == 2

* firmsize_l - Firm size (lower bracket), primary job (7-day ref period)
gen firmsize_l = .
replace firmsize_l = 1 if MJ_12 == 1
replace firmsize_l = 2 if MJ_12 == 2
replace firmsize_l = 5 if MJ_12 == 3
replace firmsize_l = 10 if MJ_12 == 4
replace firmsize_l = 25 if MJ_12 == 5
replace firmsize_l = 100 if MJ_12 == 6
replace firmsize_l = 250 if MJ_12 == 7
replace firmsize_l = . if lstatus != 1

* firmsize_u - Firm size (upper bracket), primary job (7-day ref period)
gen firmsize_u= .
replace firmsize_u = 1 if MJ_12 == 1
replace firmsize_u = 4 if MJ_12 == 2
replace firmsize_u = 9 if MJ_12 == 3
replace firmsize_u = 24 if MJ_12 == 4
replace firmsize_u = 99 if MJ_12 == 5
replace firmsize_u = 249 if MJ_12 == 6
replace firmsize_u = . if MJ_12 == 7
replace firmsize_u = . if lstatus != 1

* healthins - Health insurance (7-day ref period)
gen byte healthins = (MJ_08H != "")
replace healthins = . if lstatus != 1

* maternity_leave - Eligible for maternity leave, primary job (7-day ref period)
gen byte maternity_leave = (MJ_08C != "")
replace maternity_leave = . if lstatus != 1

* sick_leave - Eligible for sick leave, primary job (7-day ref period)
gen byte sick_leave = (MJ_08D != "")
replace sick_leave = . if lstatus != 1

* annual_leave - Eligible for annual leave, primary job (7-day ref period)
gen byte annual_leave = (MJ_08B != "")
replace annual_leave = . if lstatus != 1

* paid_leave - Eligible for any paid leave, primary job (7-day ref period)
gen byte paid_leave = (maternity_leave == 1 | sick_leave == 1| annual_leave == 1)

* pensions - Eligible for pension, primary job (7-day ref period)
gen byte pensions = (MJ_08A != "")
replace pensions = . if lstatus != 1

* industry_orig_2 - Original industry code, secondary job (7-day ref period)
* there's a survey question but no obs in data
gen industry_orig_2 = .

* industrycat10_2 - 1 digit industry classification, secondary job (7-day ref period)
gen isic3d =  .

* industrycat4_2 - 4-category industry classification, secondary job (7-day ref period)
gen byte industrycat4_2 = .
	
* occup_orig_2 - Original occupational classification, secondary job (7-day ref period)	
gen occup_orig_2 = .

* occup_2 - 1 digit occupational classification, secondary job (7-day ref period)
gen occup_2 = .

* variables we cannot create:
* contract_year - Contract (12-mon ref period)
* empldur_orig_2_year - Original employment duration/tenure, second job (12-mon ref period)
* empldur_orig_year - Original employment duration/tenure, primary job (12-mon ref period)
* empstat_2_year - Employment status, secondary job (12-mon ref period)
* empstat_year - Employment status, primary job (12-mon ref period)
* firmsize_l_2_year - Firm size (lower bracket), secondary job (12-mon ref period)
* firmsize_l_year - Firm size (lower bracket), primary job (12-mon ref period)
* firmsize_u_2_year - Firm size (upper bracket), secondary job (12-mon ref period)
* firmsize_u_year - Firm size (upper bracket), primary job (12-mon ref period)
* healthins_year - Health insurance (12-mon ref period)
* industry_orig_2_year - Original industry code, secondary job (12-mon ref period)
* industry_orig_year - Original industry code, primary job (12-mon ref period)
* industrycat10_2_year - 1 digit industry classification, secondary job (12-mon ref period)
* industrycat10_year - 1 digit industry classification, primary job (12-mon ref period)
* industrycat4_2_year - 4-category industry classification, secondary job (12-mon ref period)
* industrycat4_year - 4-category industry classification, primary job (12-mon ref period)
* lstatus_year - Labor status (12-mon ref period)
* minlaborage_year - Labor module application age (12-mon ref period)
* nlfreason_year - Reason not in the labor force (12-mon ref period)
* occup_2_year - 1 digit occupational classification, secondary job (12-mon ref period)
* occup_orig_2_year - Original occupational classification, secondary job (12-mon ref period)
* occup_orig_year - Original occupational classification, primary job (12-mon ref period)
* occup_year - 1 digit occupational classification, primary job (12-mon ref period)
* ocusec_2_year - Sector of activity, secondary job (12-mon ref period)
* ocusec_year - Sector of activity, primary job (12-mon ref period)
* paid_leave_2_year - Eligible for any paid leave, secondary job (12-mon ref period)
* paid_leave_year - Eligible for any paid leave, primary job (12-mon ref period)
* pensions_2_year - Eligible for pension, secondary job (12-mon ref period)
* pensions_year - Eligible for pension, primary job (12-mon ref period)
* socialsec_year - Social security (12-mon ref period)
* unempldur_l_year - Unemployment duration (months) lower bracket (12-mon ref period)
* unempldur_u_year - Unemployment duration (months) upper bracket (12-mon ref period)
* union_year - Union membership (12-mon ref period)
* unitwage_o - Time unit of last wages payment, other jobs (7-day ref period)
* wage_nc_o - Wage payment, other jobs, excl. bonuses, etc. (7-day ref period)
* wage_nc_week_o - Wage payment adjusted to 1 week, other jobs, excl. bonuses, etc. (7-day ref period)
* wage_total_o - Annualized total wage, other job (7-day ref period)
* whours_o - Hours of work in last week for other jobs
* wmonths_o - Months worked in the last 12 months for the others jobs
* empldur_orig_2 - Original employment duration/tenure, second job (7-day ref period)
* njobs - Total number of jobs
* wmonths_2 - Months worked in the last 12 months for the secondary job
* union - Union membership (7-day ref period)
* wmonths - Months worked in the last 12 months main activity
* socialsec - Social security (7-day ref period)
* ocusec_2 - Sector of activity, secondary job (7-day ref period)
* firmsize_l_2 - Firm size (lower bracket), secondary job (7-day ref period)
* firmsize_u_2 - Firm size (upper bracket), secondary job (7-day ref period)
* paid_leave_2 - Eligible for any paid leave, secondary job (7-day ref period)
* pensions_2 - Eligible for pension, secondary job (7-day ref period)
* maternity_leave_year - Eligible for maternity leave, primary job (12-mon ref period)
* sick_leave_year - Eligible for sick leave, primary job (12-mon ref period)
* annual_leave_year - Eligible for annual leave, primary job (12-mon ref period)
* stable_occup - Have worked for three or more years in current occupation, primary job 

foreach unavailable_var in contract_year empldur_orig_2_year empldur_orig_year empstat_2_year empstat_year firmsize_l_2_year firmsize_l_year firmsize_u_2_year firmsize_u_year ///
	healthins_year industry_orig_2_year industry_orig_year industrycat10_2_year industrycat10_year industrycat4_2_year industrycat4_year lstatus_year minlaborage_year nlfreason_year ///
	occup_2_year occup_orig_2_year occup_orig_year occup_year ocusec_2_year ocusec_year paid_leave_2_year paid_leave_year pensions_2_year pensions_year socialsec_year unempldur_l_year	///
	unempldur_u_year union_year unitwage_o wage_nc_o wage_nc_week_o wage_total_o whours_o wmonths_o empldur_orig_2 njobs union wmonths wmonths_2 ///
	socialsec firmsize_l_2 firmsize_u_2 ocusec_2 paid_leave_2 pensions_2 maternity_leave_year sick_leave_year annual_leave_year stable_occup {
	if strmatch("`unavailable_var'","*orig*")==1 g `unavailable_var' = ""
	else g `unavailable_var' = .
}


* label all SARLD harmonized variables and values
do "${rootlabels}/label_SARLAB_variables.do"
save "${output}/`surveyfolder'_v`vm'_M_v`va'_A_`type'_TMP", replace
keep ${keepharmonized}
* save harmonized data
save "${output}/`surveyfolder'_v`vm'_M_v`va'_A_`type'_IND", replace
