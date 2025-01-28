***********************************************************************
*	PAK_2017_LFS
*	SAR Labor Harmonization
*	August 2023
*	Joseph Green, josephgreen@gmail.com
***********************************************************************
clear
set more off
local countrycode	"PAK"
local year			"2017"
local survey		"LFS"
local va			"04"
local vm			"01"
local type			"SARLAB"
local surveyfolder	"`countrycode'_`year'_`survey'"

* global path on Joe's computer
if ("`c(username)'"=="sunquat") {
	* define folder paths
	glo rootdatalib "/Users/sunquat/Projects/WORLD BANK/SAR - labor harmonization/SARLD/WORKINGDATA"
	glo rootlabels "/Users/sunquat/Projects/WORLD BANK/SAR - labor harmonization/SARLD/_aux"
}
if ("`c(username)'"=="wb611670") {
	* define folder paths
	glo rootdatalib "C:\Users\wb611670\WBG\Laura Liliana Moreno Herrera - 09.SARLAB\WORKINGDATA"
	glo rootlabels "C:\Users\wb611670\WBG\Laura Liliana Moreno Herrera - 09.SARLAB\_aux"
}
* global paths on WB computer
else {
	* start with individual data
	datalibweb, country(`countrycode') year(`year') survey(`survey') type(SARRAW) filename(LFS 2017-18 (original).dta) localpath(${rootdatalib}) local
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
	* start with individual data
	use "${surveydata}/LFS 2017-18 (original)", clear
}
if ("`c(username)'"=="wb611670") {
	* start with individual data
	use "${surveydata}/LFS 2017-18 (original)", clear
}

* countrycode = country code
g countrycode = "`countrycode'"

* year = Year
g year = 2017

* int_year = interview year
* note: from GLD do file
g int_year = 2017

* int_month = interview month
* note: from GLD do file
g int_month = 7

* hhid = Household identifier
clonevar hhid = PrCode

* pid = Personal identifier
rename S04Psn1 pid

* confirm unique identifiers: hhid + pid
isid hhid pid

* weight = Household weight
rename Weight weight

* relationharm = Relationship to head of household harmonized across all regions
recode S04C03 (1=1) (2=2) (3/4=3) (5=4) (6/7=5) (8=7) (9=6) (*=.), g(relationharm)
* fix some duplicate heads, assiging "other relative" when pid != 1
egen num_heads = total(relationharm==1), by(hhid)
egen num_pid1s = total(pid==1), by(hhid)
replace relationharm = 5 if num_heads>1 & num_pid1s==1 & pid~=1

* relationcs = Original relationship to head of household
label define S04C03 1 "Head of household" 2 "Spouse" 3 "Son/daughter (unmarried)" 4 "Son/daughter (married)" 5 "Father/mother" 6 "Brother/sister" 7 "Other relative" 8 "Servant" 9 "Non relative"
label values S04C03 S04C03
decode S04C03, g(relationcs)

* household member. All excluding household workers
gen hhmember=(~inlist(relationharm,7,.))

* hsize = Household size, not including household workers
bys hhid: egen hsize=total(hhmember)

* strata = Strata
* from GLD do file
tostring PrCode, g(PrCode_str)
g strata = substr(PrCode_str,2,2)

* psu = PSU
* from GLD do file
g psu = substr(PrCode_str,6,3)

* spdef = Spatial deflator (if one is used)
g spdef = .

* subnatid1 = Subnational ID - highest level
g subnatid1_num = substr(PrCode_str,1,1)
destring subnatid1_num, replace
label define subnatid1 1 "Khyber/Pakhtoonkhua" 2 "Punjab" 3 "Sindh" 4 "Balochistan" 6 "Islamabad" 7 "Gilgit-Baltistian" 8 "AJ & Kashmir" 
label values subnatid1_num subnatid1
decode subnatid1_num, g(subnatid1)
replace subnatid1 = string(subnatid1_num) + " - " + subnatid1

* subnatid2 = Subnational ID - second highest level
g subnatid2 = ""

* subnatid3 = Subnational ID - third highest level
g subnatid3 = ""

* urban = Urban (1) or rural (0)
g urban = substr(PrCode_str,4,1)
destring urban, replace
recode urban (1=0) (2/3=1) (*=.)

* language = Language
g language = ""

* age = Age of individual (continuous)
g		age = S04C06

* male = Sex of household member (male=1)
recode S04C05 (1=1) (2=0) (*=.), g(male)

* marital = Marital status
recode S04C07 (1=2) (2=1) (3=5) (4=4) (*=.), g(marital)

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
* code adapted from GLD do file
recode S04C09 (1/2=1) (3=2) (4=3) (5/6=4) (8/15=7) (*=.), g(educat7)
replace educat7 = 5 if S04C09==7 & S04C10==1
replace educat7 = 7 if S04C09==7 & inrange(S04C10,8,15) 

* educat5 = Highest level of education completed (5 categories)
recode educat7 (0=0) (1=1) (2=2) (3/4=3) (5=4) (6/7=5), g(educat5)

* educat4 = Highest level of education completed (4 categories)
recode educat7 (0=0) (1=1) (2/3=2) (4/5=3) (6/7=4), g(educat4)

* educy = Years of completed education
* code adapted from GLD do file
g		educy=0 if S04C09<=3
replace educy=5 if S04C09==4
replace educy=8 if S04C09==5
replace educy=10 if S04C09==6
replace educy=12 if S04C09==7
replace educy=16 if S04C09==8
replace educy=17 if S04C09==9
replace educy=16 if S04C09==10
replace educy=16 if S04C09==11
replace educy=16 if S04C09==12
replace educy=19 if S04C09==13
replace educy=20 if S04C09==14
replace educy=22 if S04C09==15
replace educy=. if age<5 | !inrange(S04C09,1,15)
replace educy=age if educy>age & !mi(educy) & !mi(age)

* literacy = Individual can read and write
* code adapted from GLD do file
recode S04C08 (1=1) (2=0) (*=.), g(literacy)

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
replace lstatus = 1 if S05C02 == 1 // worked for pay
replace lstatus = 1 if S05C03 == 1 // worked for family
replace lstatus = 1 if inlist(S05C04,1,2) //temporary absence 
replace lstatus = . if S05C06 == 2 // absent more than 1 month

replace lstatus = 2 if S05C04 == 3 // plans to work in 1 month
replace lstatus = 2 if S09C01 == 1 & inlist(S09C04,1,2,3,4,5,6) // searched job last week and was available to start
replace lstatus = 2 if inlist(S09C06,2,3,4,8) // awaiting job OR temporarily laid off OR is apprentice OR property owner

replace lstatus = 3 if missing(lstatus)
replace lstatus = . if age < minlaborage


* empstat - Employment status, primary job (7-day ref period)
recode S05C08 (1/4=1) (5=3) (6/8=4) (9 13/14=5) (10=6) (11/12=2) (*=.) if lstatus==1, g(empstat)

* contract - Contract (7-day ref period)
recode S07C01 (1/6=1) (7=0) if lstatus==1, g(contract)
note contract: For PAK_2018_LFS, this question was only asked to employed persons who are paid employees (empstat = 1).

* industry_orig - Original industry code, primary job (7-day ref period)
g industry_orig = S05C10

* industrycat10 - 1 digit industry classification, primary job (7-day ref period)
g		industrycat10 = floor(S05C10/100) if lstatus==1
recode	industrycat10 (1/3=1) (4/9=2) (10/33=3) (35/39=4) (41/43=5) (45/47 55/56=6) (49/53 58/63 79=7) (64/68 83=8) (84=9) (69/78 80/82 85/99=10) (*=.)

* industrycat4 - 4-category industry classification, primary job (7-day ref period)
recode industrycat10 (1=1) (2/5=2) (6/9=3) (10=4), g(industrycat4)

* nlfreason - Reason not in the labor force (7-day ref period)
recode S09C06 (5=1) (6=2) (7=3) (11=4) (1/4 8/10 12/13=5) (*=.) if lstatus==3, g(nlfreason)

* occup - 1 digit occupational classification, primary job (7-day ref period)
g occup = floor(S05C09/1000) if lstatus==1

* occup_orig - Original occupational classification, primary job (7-day ref period)
g occup_orig = S05C09

* ocusec - Sector of activity, primary job (7-day ref period)
recode S05C11 (1/3=1) (4=3) (5/9=2) (*=.) if lstatus==1, g(ocusec)

* unempldur_l - Unemployment duration (months) lower bracket (7-day ref period)
* note: 9.3 should only be answered for one box: years, months, days. However, it is often answered for more, so must calculate based on all values additively.
g months_from_years = S09C031*12
egen unempldur_l = rowtotal(months_from_years S09C032) if lstatus==2, missing

* unempldur_u - Unemployment duration (months) upper bracket (7-day ref period)
egen unempldur_u = rowtotal(months_from_years S09C032) if lstatus==2, missing

* unitwage - Time unit of last wages payment, primary job (7-day ref period)
g		unitwage = 2 if ~missing(S07C031) & lstatus==1 & empstat~=2
replace	unitwage = 5 if ~missing(S07C041) & lstatus==1 & empstat~=2

* wage_nc - Wage payment, primary job, excl. bonuses, etc. (7-day ref period)
g		wage_nc = S07C031 if lstatus==1 & empstat~=2
replace	wage_nc = S07C041 if lstatus==1 & empstat~=2 & ~missing(S07C041)

* wage_nc_week - Wage payment adjusted to 1 week, primary job, excl. bonuses, etc. (7-day ref period)
g		wage_nc_week = S07C031 if lstatus==1 & empstat~=2
replace	wage_nc_week = S07C041/4.3 if lstatus==1 & empstat~=2 & ~missing(S07C041)

* wage_total - Annualized total wage, primary job (7-day ref period)
g		wage_total = S07C03 * 52 if lstatus==1
replace	wage_total = S07C04 * 12 if lstatus==1  & empstat~=2 & ~missing(S07C04)

* whours - Hours of work in last week main activity
g whours = S05C171 if lstatus==1

* firmsize_l - Firm size (lower bracket), primary job (7-day ref period)
g firmsize_l = S05C13

* firmsize_u - Firm size (upper bracket), primary job (7-day ref period)
g firmsize_u = S05C13

* njobs - Total number of jobs
g		njobs = 1 if S05C18==2 & lstatus==1
replace njobs = 2 if S05C18==1 & S05C27==3 & lstatus==1
replace njobs = 3 if S05C18==1 & S05C27==1 & lstatus==1
replace njobs = 4 if S05C18==1 & S05C27==2 & lstatus==1

* paid_leave - Eligible for any paid leave, primary job (7-day ref period)
g paid_leave = inrange(S07C07,1,6) if lstatus==1 & inrange(S07C07,1,7)

* pensions - Eligible for pension, primary job (7-day ref period)
egen any_pension = anymatch(S07C06?), values(1)
egen any_responses7c6 = anymatch(S07C06?), values(1/6)
g pensions = (any_pension) if any_responses7c6==1 & lstatus==1

* socialsec - Social security (7-day ref period)
egen any_socialsec = anymatch(S07C06?), values(4)
g socialsec = (any_socialsec) if any_responses7c6==1 & lstatus==1

* wmore - Willingness to work for more hours
recode S06C02 (1=1) (2=0) (*=.) if lstatus==1, g(wmore)

* SECOND JOB

* empstat_2 - Employment status, secondary job (7-day ref period)
recode S05C19 (1/4=1) (5=3) (6/8=4) (9 13/14=5) (10=6) (11/12=2) (*=.) if lstatus==1, g(empstat_2)

* firmsize_l_2 - Firm size (lower bracket), secondary job (7-day ref period)
g firmsize_l_2 = S05C24 if lstatus==1

* firmsize_u_2 - Firm size (upper bracket), secondary job (7-day ref period)
g firmsize_u_2 = S05C24 if lstatus==1

* industry_orig_2 - Original industry code, secondary job (7-day ref period)
g industry_orig_2 = S05C21

* industrycat10_2 - 1 digit industry classification, secondary job (7-day ref period)
g		industrycat10_2 = floor(S05C21/100) if lstatus==1
recode	industrycat10_2 (1/3=1) (4/9=2) (10/33=3) (35/39=4) (41/43=5) (45/47 55/56=6) (49/53 58/63 79=7) (64/68 83=8) (84=9) (69/78 80/82 85/99=10) (*=.)

* industrycat4_2 - 4-category industry classification, secondary job (7-day ref period)
recode industrycat10_2 (1=1) (2/5=2) (6/9=3) (10=4), g(industrycat4_2)

* occup_2 - 1 digit occupational classification, secondary job (7-day ref period)
g occup_2 = floor(S05C20/1000) if lstatus==1

* occup_orig_2 - Original occupational classification, secondary job (7-day ref period)
g occup_orig_2 = S05C20

* ocusec_2 - Sector of activity, secondary job (7-day ref period)
recode S05C22 (1/3=1) (4=3) (5/9=2) (*=.) if lstatus==1 & S05C18==1, g(ocusec_2)

* whours_2 - Hours of work in last week for the secondary job
g whours_2 = S05C26 if lstatus==1

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
* empldur_orig = Original employment duration/tenure, primary job (7-day ref period)

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
	unempldur_u_year union_year healthins union wmonths wmonths_2 empldur_orig unitwage_o wage_nc_o wage_nc_week_o wage_total_o whours_o wmonths_o empldur_orig_2 paid_leave_2 ///
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
