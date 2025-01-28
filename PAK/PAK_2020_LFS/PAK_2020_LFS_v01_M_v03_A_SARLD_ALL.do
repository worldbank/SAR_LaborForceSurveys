***********************************************************************
*	PAK_2020_LFS
*	SAR Labor Harmonization
*	July 2023
*	Joseph Green, josephgreen@gmail.com
***********************************************************************
clear
set more off
local countrycode	"PAK"
local year			"2020"
local survey		"LFS"
local va			"03"
local vm			"01"
local type			"SARLAB"
local surveyfolder	"`countrycode'_`year'_`survey'"
tempfile			PAK_subnatid2_code_2020

* global path on Joe's computer
if ("`c(username)'"=="sunquat") {
	* define folder paths
	glo rootdatalib "/Users/sunquat/Projects/WORLD BANK/SAR - labor harmonization/SARLD/WORKINGDATA"
	glo rootlabels "/Users/sunquat/Projects/WORLD BANK/SAR - labor harmonization/SARLD/_aux"
}
else if ("`c(username)'"=="wb611670") {
	* define folder paths
	glo rootdatalib "C:\Users\wb611670\WBG\Laura Liliana Moreno Herrera - 09.SARLAB\WORKINGDATA"
	glo rootlabels "C:\Users\wb611670\WBG\Laura Liliana Moreno Herrera - 09.SARLAB\_aux"
}
* global paths on WB computer
else {
	* prepare city codes data, eliminating duplicates
	datalibweb, country(`countrycode') year(`year') survey(`survey') type(SARRAW) filename(PAK_subnatid2_code_2020.dta) localpath(${rootdatalib}) local
	duplicates drop _all, force
	save `PAK_subnatid2_code_2020'
	* start with individual data
	datalibweb, country(`countrycode') year(`year') survey(`survey') type(SARRAW) filename(LFS2020-21.dta) localpath(${rootdatalib}) local
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
	* prepare city codes data, eliminating duplicates
	use "${surveydata}/PAK_subnatid2_code_2020", clear
	duplicates drop _all, force
	save `PAK_subnatid2_code_2020'
	* start with individual data
	use "${surveydata}/LFS2020-21", clear
}
if ("`c(username)'"=="wb611670") {
	* prepare city codes data, eliminating duplicates
	use "${surveydata}/PAK_subnatid2_code_2020", clear
	duplicates drop _all, force
	save `PAK_subnatid2_code_2020'
	* start with individual data
	use "${surveydata}/LFS2020-21", clear
}

* countrycode = country code
g countrycode = "`countrycode'"

* year = Year
g year = 2020

* int_year = interview year
* note: from GLD do file
g int_year = 2020

* int_month = interview month
* note: from GLD do file
g int_month = 7

* hhid = Household identifier
egen hhid = concat(PCode HHSNo)

* pid = Personal identifier
rename SNo pid

* confirm unique identifiers: hhid + pid
isid hhid pid

* weight = Household weight
rename Weights weight

* relationharm = Relationship to head of household harmonized across all regions
recode S4C3 (1=1) (2=2) (3/4=3) (5=4) (6/7=5) (8=7) (9=6) (*=.), g(relationharm)

* relationcs = Original relationship to head of household
label define S4C3 1 "Head of household" 2 "Spouse" 3 "Son/daughter (unmarried)" 4 "Son/daughter (married)" 5 "Father/mother" 6 "Brother/sister" 7 "Other relative" 8 "Servant" 9 "Non relative"
label values S4C3 S4C3
decode S4C3, g(relationcs)

* household member. All excluding household workers
gen hhmember=(~inlist(relationharm,7,.))

* hsize = Household size, not including household workers
bys hhid: egen hsize=total(hhmember)

* strata = Strata
* from GLD do file
g strata = substr(PCode,2,2)

* psu = PSU
* from GLD do file
g psu = EBCode

* spdef = Spatial deflator (if one is used)
g spdef = .

* subnatid1 = Subnational ID - highest level
decode Province, g(subnatid1)
replace subnatid1 = string(Province) + " - " + subnatid1

* subnatid2 = Subnational ID - second highest level
* correct some district names (based on GLD do file)
g		city_name = proper(District)
replace city_name = "Karachi West" if city_name=="West"
replace city_name = "Karachi East" if city_name=="East"
* merge in codes
merge m:1 city_name using `PAK_subnatid2_code_2020', nogen assert(match)
egen subnatid2 = concat(city_code city_name), punct(" - ")
note subnatid2: For PAK_2020_LFS, the city_code variable from PAK_subnatid2_code_2020.dta (merged with District) matches the first 3 digits of PCode in nearly all cases: only 102 out of the 570991 observations don't match. However, it seems we should trust the city_code (which we used for subnatid2) instead of the first 3 digits of PCode, because the District names are inconsistent with the first 3 digits of PCode.

* subnatid3 = Subnational ID - third highest level
g subnatid3 = ""

* urban = Urban (1) or rural (0)
recode Region (2=1) (1=0) (*=.), g(urban)

* language = Language
g language = ""

* age = Age of individual (continuous)
g age = S4C6

* male = Sex of household member (male=1)
recode S4C5 (1=1) (2=0) (*=.), g(male)

* marital = Marital status
recode S4C7 (1=2) (2=1) (3=5) (4=4) (*=.), g(marital)

* eye_dsablty = Difficulty seeing
g eye_dsablty = S4C19

* hear_dsablty = Difficulty hearing
g hear_dsablty = S4C20

* walk_dsablty = Difficulty walking or climbing steps
g walk_dsablty = S4C21

* conc_dsord = Difficulty remembering or concentrating
g conc_dsord = S4C22

* slfcre_dsablty = Difficulty with self-care
g slfcre_dsablty = S4C23

* comm_dsablty = Difficulty communicating
g comm_dsablty = S4C24

* educat7 = Highest level of education completed (7 categories)
* code adapted from GLD do file
recode S4C9 (1/2=1) (3=2) (4=3) (5/6=4) (8/15=7) (*=.), g(educat7)
replace educat7 = 5 if S4C9==7 & S4C10==1
replace educat7 = 7 if S4C9==7 & inrange(S4C10,8,15) 

* educat5 = Highest level of education completed (5 categories)
recode educat7 (0=0) (1=1) (2=2) (3/4=3) (5=4) (6/7=5), g(educat5)

* educat4 = Highest level of education completed (4 categories)
recode educat7 (0=0) (1=1) (2/3=2) (4/5=3) (6/7=4), g(educat4)

* educy = Years of completed education
* code adapted from GLD do file
g		educy=0 if S4C9<=3
replace educy=5 if S4C9==4
replace educy=8 if S4C9==5
replace educy=10 if S4C9==6
replace educy=12 if S4C9==7
replace educy=16 if S4C9==8
replace educy=17 if S4C9==9
replace educy=16 if S4C9==10
replace educy=16 if S4C9==11
replace educy=16 if S4C9==12
replace educy=19 if S4C9==13
replace educy=20 if S4C9==14
replace educy=22 if S4C9==15
replace educy=. if age<5 | !inrange(S4C9, 1, 15)
replace educy=age if educy>age & !mi(educy) & !mi(age)

* literacy = Individual can read and write
* code adapted from GLD do file
g		literacy=1 if S4C81==1 & S4C82==1
replace literacy=0 if literacy!=1 & !mi(S4C81) & !mi(S4C82)
	
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
g minlaborage = 10

* lstatus - Labor status (7-day ref period)
g lstatus = .
replace lstatus = 1 if S5C1 == 1 //worked for pay
replace lstatus = 1 if S5C2 == 1 //worked for famaily
replace lstatus = 1 if S5C3 == 1 & inlist(S5C5, 1, 2, 3) //had job but didn't work but will return

replace lstatus = 2 if S9C1 == 1 & inlist(S9C6, 1, 2) //seeking during the last four weeks and can start within 2 weeks
replace lstatus = 2 if S9C5 == 1 & inlist(S9C6, 1, 2) //awaiting results and can start within 2 weeks
replace lstatus = 2 if inlist(S9C5,1,2) // awaiting to start a new OR previous job
replace lstatus = 2 if inlist(S9C9,2,2) // awaiting to start new job or is apprentice

replace lstatus = 3 if missing(lstatus)
replace lstatus = . if age < minlaborage

* empstat - Employment status, primary job (7-day ref period)
recode S5C7 (1/4=1) (5=3) (6/8=4) (9 13/14=5) (10=6) (11/12=2) (*=.) if lstatus==1, g(empstat)

* contract - Contract (7-day ref period)
recode S7C1 (1/6=1) (7=0) if lstatus==1, g(contract)
note contract: For PAK_2020_LFS, this question was only asked to employed persons who are paid employees (empstat = 1).

* empldur_orig = Original employment duration/tenure, primary job (7-day ref period)
g empldur_orig = .

* industry_orig - Original industry code, primary job (7-day ref period)
g industry_orig = S5C9

* industrycat10 - 1 digit industry classification, primary job (7-day ref period)
destring S5C9, replace
g		industrycat10 = floor(S5C9/100) if lstatus==1
recode	industrycat10 (1/3=1) (4/9=2) (10/33=3) (35/39=4) (41/43=5) (45/47 55/56=6) (49/53 58/63 79=7) (64/68 83=8) (84=9) (69/78 80/82 85/99=10) (*=.)

* industrycat4 - 4-category industry classification, primary job (7-day ref period)
recode industrycat10 (1=1) (2/5=2) (6/9=3) (10=4), g(industrycat4)

* nlfreason - Reason not in the labor force (7-day ref period)
destring S9C5, replace
recode S9C5 (2/8 11 13/14=5) (9=1) (10=2) (12=4) (*=.) if lstatus==3, g(nlfreason)

* occup - 1 digit occupational classification, primary job (7-day ref period)
g occup = substr(S5C8,1,1) if lstatus==1
destring occup, replace
recode occup (0=10)

* occup_orig - Original occupational classification, primary job (7-day ref period)
g occup_orig = S5C8

* ocusec - Sector of activity, primary job (7-day ref period)
recode S5C10 (1/3=1) (4=3) (5/9=2) (*=.) if lstatus==1, g(ocusec)

* unempldur_l - Unemployment duration (months) lower bracket (7-day ref period)
recode S9C3 (1=0) (2=1) (3=3) (4=6) (5=12) (*=.) if lstatus==2, g(unempldur_l)

* unempldur_u - Unemployment duration (months) upper bracket (7-day ref period)
recode S9C3 (1=1) (2=3) (3=6) (4=12) (*=.) if lstatus==2, g(unempldur_u)

* unitwage - Time unit of last wages payment, primary job (7-day ref period)
* Note: S7C31 and S7C41 are never both answered for the same person.
g		unitwage = 2 if ~missing(S7C31) & lstatus==1 & empstat~=2
replace	unitwage = 5 if ~missing(S7C41) & lstatus==1 & empstat~=2

* wage_nc - Wage payment, primary job, excl. bonuses, etc. (7-day ref period)
g		wage_nc = S7C31 if lstatus==1 & empstat~=2
replace	wage_nc = S7C41 if lstatus==1 & empstat~=2 & ~missing(S7C41)

* wage_nc_week - Wage payment adjusted to 1 week, primary job, excl. bonuses, etc. (7-day ref period)
g		wage_nc_week = S7C31 if lstatus==1 & empstat~=2
replace	wage_nc_week = S7C41/4.3 if lstatus==1 & empstat~=2 & ~missing(S7C41)

* wage_total - Annualized total wage, primary job (7-day ref period)
* Note: S7C33 and S7C43 are never both answered for the same person.
g		wage_total = S7C33 * 52 if lstatus==1
replace	wage_total = S7C43 * 12 if lstatus==1  & empstat~=2 & ~missing(S7C43)

* whours - Hours of work in last week main activity
g whours = S5C161 if lstatus==1

* firmsize_l - Firm size (lower bracket), primary job (7-day ref period)
g firmsize_l = S5C12

* firmsize_u - Firm size (upper bracket), primary job (7-day ref period)
g firmsize_u = S5C12

* njobs - Total number of jobs
g		njobs = 1 if lstatus==1
replace	njobs = 2 if lstatus==1 & S5C26==3
replace	njobs = 3 if lstatus==1 & S5C26==1
replace	njobs = 4 if lstatus==1 & S5C26==2
recode njobs (.=0)

* paid_leave - Eligible for any paid leave, primary job (7-day ref period)
egen paid_leave = anymatch(S7C61-S7C610) if lstatus==1, values(8)

* pensions - Eligible for pension, primary job (7-day ref period)
egen any_pension = anymatch(S7C6*), values(1)
egen any_responses7c6 = anymatch(S7C6*), values(1/10)
g pensions = (any_pension) if any_responses7c6==1 & lstatus==1

* socialsec - Social security (7-day ref period)
egen any_socialsec = anymatch(S7C6*), values(4)
g socialsec = (any_socialsec) if any_responses7c6==1 & lstatus==1

* wmore - Willingness to work for more hours
recode S6C2 (1=1) (2=0) (*=.) if lstatus==1, g(wmore)

* SECOND JOB

* empstat_2 - Employment status, secondary job (7-day ref period)
recode S5C18 (1/4=1) (5=3) (6/8=4) (9 13/14=5) (10=6) (11/12=2) (*=.) if lstatus==1, g(empstat_2)

* firmsize_l_2 - Firm size (lower bracket), secondary job (7-day ref period)
g firmsize_l_2 = S5C23 if S5C17==1 & lstatus==1

* firmsize_u_2 - Firm size (upper bracket), secondary job (7-day ref period)
g firmsize_u_2 = S5C23 if S5C17==1 & lstatus==1

* industry_orig_2 - Original industry code, secondary job (7-day ref period)
g industry_orig_2 = S5C20

* industrycat10_2 - 1 digit industry classification, secondary job (7-day ref period)
replace S5C20 = "0" + S5C20 if length(S5C20)==3
destring S5C20, replace
g		industrycat10_2 = floor(S5C20/100) if lstatus==1
recode	industrycat10_2 (1/3=1) (4/9=2) (10/33=3) (35/39=4) (41/43=5) (45/47 55/56=6) (49/53 58/63 79=7) (64/68 83=8) (84=9) (69/78 80/82 85/99=10) (*=.)

* industrycat4_2 - 4-category industry classification, secondary job (7-day ref period)
recode industrycat10_2 (1=1) (2/5=2) (6/9=3) (10=4), g(industrycat4_2)

* occup_2 - 1 digit occupational classification, secondary job (7-day ref period)
g occup_2 = substr(S5C19,1,1) if lstatus==1
destring occup_2, replace
recode occup_2 (0=10)

* occup_orig_2 - Original occupational classification, secondary job (7-day ref period)
g occup_orig_2 = S5C19

* ocusec_2 - Sector of activity, secondary job (7-day ref period)
recode S5C21 (1/3=1) (4=3) (5/9=2) (*=.) if lstatus==1, g(ocusec_2)

* whours_2 - Hours of work in last week for the secondary job
g whours_2 = S5C251 if lstatus==1




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
* paid_leave_2_year - Eligible for paid leave, secondary job (12-mon ref period)
* paid_leave_year - Eligible for paid leave, primary job (12-mon ref period)
* pensions_2_year - Eligible for pension, secondary job (12-mon ref period)
* pensions_year - Eligible for pension, primary job (12-mon ref period)
* socialsec_year - Social security (12-mon ref period)
* unempldur_l_year - Unemployment duration (months) lower bracket (12-mon ref period)
* unempldur_u_year - Unemployment duration (months) upper bracket (12-mon ref period)
* union_year - Union membership (12-mon ref period)

* healthins - Health insurance (7-day ref period)
* union - Union membership (7-day ref period)
* wmonths - Months worked in the last 12 months main activity
* wmonths_2 - Months worked in the last 12 months for the secondary job

* unitwage_o - Time unit of last wages payment, other jobs (7-day ref period)
* wage_nc_o - Wage payment, other jobs, excl. bonuses, etc. (7-day ref period)
* wage_nc_week_o - Wage payment adjusted to 1 week, other jobs, excl. bonuses, etc. (7-day ref period)
* wage_total_o - Annualized total wage, other job (7-day ref period)
* whours_o - Hours of work in last week for other jobs
* wmonths_o - Months worked in the last 12 months for the others jobs

* empldur_orig_2 - Original employment duration/tenure, second job (7-day ref period)
* paid_leave_2 - Eligible for paid leave, secondary job (7-day ref period)
* pensions_2 - Eligible for pension, secondary job (7-day ref period)
* unitwage_2 - Time unit of last wages payment, secondary job (7-day ref period)
* wage_nc_2 - Wage payment, secondary job, excl. bonuses, etc. (7-day ref period)
* wage_nc_week_2 - Wage payment adjusted to 1 week, secondary job, excl. bonuses, etc. (7-day ref period)
* wage_total_2 - Annualized total wage, secondary job (7-day ref period)

* maternity_leave - Eligible for maternity leave, primary job (7-day ref period)
* maternity_leave_year - Eligible for maternity leave, primary job (12-mon ref period)
* sick_leave - Eligible for sick leave, primary job (7-day ref period)
* sick_leave_year - Eligible for sick leave, primary job (12-mon ref period)
* annual_leave - Eligible for annual leave, primary job (7-day ref period)
* annual_leave_year - Eligible for annual leave, primary job (12-mon ref period)
* stable_occup - Have worked for three or more years in current occupation, primary job 

foreach unavailable_var in contract_year empldur_orig_2_year empldur_orig_year empstat_2_year empstat_year firmsize_l_2_year firmsize_l_year firmsize_u_2_year firmsize_u_year ///
	healthins_year industry_orig_2_year industry_orig_year industrycat10_2_year industrycat10_year industrycat4_2_year industrycat4_year lstatus_year minlaborage_year nlfreason_year ///
	occup_2_year occup_orig_2_year occup_orig_year occup_year ocusec_2_year ocusec_year paid_leave_2_year paid_leave_year pensions_2_year pensions_year socialsec_year unempldur_l_year	///
	unempldur_u_year union_year healthins union wmonths wmonths_2 unitwage_o wage_nc_o wage_nc_week_o wage_total_o whours_o wmonths_o empldur_orig_2 paid_leave_2 ///
	pensions_2 unitwage_2 wage_nc_2 wage_nc_week_2 wage_total_2 maternity_leave maternity_leave_year sick_leave sick_leave_year annual_leave annual_leave_year stable_occup {
		if strmatch("`unavailable_var'","*orig*")==1 g `unavailable_var' = ""
		else g `unavailable_var' = .
}


* label all SARLD harmonized variables and values
do "${rootlabels}/label_SARLAB_variables.do"
save "${output}/`surveyfolder'_v`vm'_M_v`va'_A_`type'_TMP", replace
keep ${keepharmonized}
* save harmonized data
save "${output}/`surveyfolder'_v`vm'_M_v`va'_A_`type'_IND", replace
