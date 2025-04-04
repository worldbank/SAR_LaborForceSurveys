***********************************************************************
*	BTN_2024_QLFS
*	SAR Labor Harmonization
*	April 2025
*	Sizhen Fang, sfang2@worldbank.org
***********************************************************************
clear
set more off
local countrycode	"BTN"
local year			"2024"
local survey		"QLFS"
local vm			"01"
local va			"01"
local type			"SARLAB"
local surveyfolder	"`countrycode'_`year'_`survey'"

**TEMPORAL WORKING DATA
* SF
if ("`c(username)'"=="wb611670") {
 	* define folder paths
 	glo rootdatalib "C:\Users\wb611670\WBG\Laura Liliana Moreno Herrera - 09.SARLAB\WORKINGDATA"
 	glo rootlabels "C:\Users\wb611670\WBG\Laura Liliana Moreno Herrera - 09.SARLAB\_aux"
 }

glo surveydata	"${rootdatalib}/`countrycode'/`surveyfolder'/`surveyfolder'_v`vm'_M/Data/Stata"
glo output		"${rootdatalib}/`countrycode'/`surveyfolder'/`surveyfolder'_v`vm'_M_v`va'_A_`type'/Data/Harmonized"
cap mkdir "${rootdatalib}/`countrycode'/`surveyfolder'"
cap mkdir "${rootdatalib}/`countrycode'/`surveyfolder'/`surveyfolder'_v`vm'_M_v`va'_A_`type'"
cap mkdir "${rootdatalib}/`countrycode'/`surveyfolder'/`surveyfolder'_v`vm'_M_v`va'_A_`type'/Data"
cap mkdir "${rootdatalib}/`countrycode'/`surveyfolder'/`surveyfolder'_v`vm'_M_v`va'_A_`type'/Data/Harmonized"
cap mkdir "${rootdatalib}/`countrycode'/`surveyfolder'/`surveyfolder'_v`vm'_M_v`va'_A_`type'/Program"

* calling data
if inlist("`c(username)'","sunquat","wb611670") {
 	* load data
 	* start with HH data
 	use "${surveydata}/BTN_2024_QLFS_v01_M.dta", clear
 }

* countrycode = country code
g countrycode = "`countrycode'"

* year = Year
g year = 2024

* int_year = interview year
g int_year = 2024

* int_month = interview month
g int_month = .

* hhid = Household identifier

confirm var hhid

* pid = Personal identifier
sort hhid
by hhid: gen hhmember_id = _n
tostring(hhmember_id), replace
gen pid = hhid + "-" + hhmember_id
note: BTN QLFS 2024 raw does not have pid

* confirm unique identifiers: hhid + pid
isid hhid pid

* weight = Household weight
confirm var weight

* relationharm = Relationship to head of household harmonized across all regions
recode q1_3 (1=1) (2=2) (3/4=3) (5/6=4) (7/31=5) (32=7) (33=6) (*=.), g(relationharm)

* relationcs = Original relationship to head of household
decode q1_3, g(relationcs)

* household member. All excluding household workers
gen hhmember=(~inlist(relationharm,7,.))

* hsize = Household size, not including household workers
bys hhid: egen hsize=total(hhmember)

* strata = Strata
g strata = .

* spdef = Spatial deflator (if one is used)
g spdef = .

* subnatid1 = Subnational ID - highest level
decode dcode24, g(subnatid1)
replace subnatid1 = string(dcode24) + " - " + subnatid1

* subnatid2 = Subnational ID - second highest level
g subnatid2 = ""

* subnatid3 = Subnational ID - third highest level
g subnatid3 = ""

* urban = Urban (1) or rural (0)
recode area (1=1) (2=0) (*=.), g(urban)

* psu = PSU
g psu = ""

* language = Language
g language = ""

* age = Age of individual (continuous)
g age = q1_4

* male = Sex of household member (male=1)
recode q1_2 (1=1) (2=0) (*=.), g(male)

* marital = Marital status
recode q1_5 (1=2) (2=3) (3=1) (4/5=4) (6=5) (*=.), g(marital)

* eye_dsablty = Difficulty seeing
* hear_dsablty = Difficulty hearing
* walk_dsablty = Difficulty walking or climbing steps
* conc_dsord = Difficulty remembering or concentrating
* slfcre_dsablty = Difficulty with self-care
* comm_dsablty = Difficulty communicating
foreach unavailable_var in eye_dsablty hear_dsablty walk_dsablty conc_dsord slfcre_dsablty comm_dsablty {
	g `unavailable_var' = .
}

* educat7 = Highest level of education completed (7 categories)
* in pervious years we use q2_13 and q2_15. these two questions are available in the survey but not found in raw data
recode q2_3 (0 19=1) (1/5=2) (6=3) (7/11=4) (12=5) (13/14=6) (15/18=7) (*=.), g(educat7)
replace	educat7 = 1 if q2_1==3 | q2_2==5 
replace educat7 = 0 if q2_2==3 

* educat5 = Highest level of education completed (5 categories)
recode educat7 (0=0) (1=1) (2=2) (3/4=3) (5=4) (6/7=5), g(educat5)

* educat4 = Highest level of education completed (4 categories)
recode educat7 (0=0) (1=1) (2/3=2) (4/5=3) (6/7=4), g(educat4)

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
g lstatus = .
replace lstatus = 1 if inlist(q3_1,1,2,3)
replace lstatus = 1 if q3_2 == 1
replace	lstatus = 2 if inlist(q5_1,1,2,3) & q5_9 == 1
replace lstatus = 3 if missing(lstatus)
replace lstatus = . if age < minlaborage

* empstat - Employment status, primary job (7-day ref period)
recode q4_3 (1/2=1) (3/4=4) (5/6 8=2) (7=3) (96=5) (*=.) if lstatus==1, g(empstat)

* contract - Contract (7-day ref period)
g contract = .

* empldur_orig = Original employment duration/tenure, primary job (7-day ref period)
g empldur_orig = ""

* industry_orig - Original industry code, primary job (7-day ref period)
decode q4_2a, g(industry_orig)

* industrycat10 - 1 digit industry classification, primary job (7-day ref period)
g		industrycat10 = floor(q4_2a/1000) if lstatus==1
recode	industrycat10 (1/3=1) (4/9=2) (10/33=3) (35/39=4) (41/43=5) (45/47 55/56=6) (49/53 58/63 79=7) (64/68 83=8) (84=9) (69/78 80/82 85/99=10) (*=.)

* industrycat4 - 4-category industry classification, primary job (7-day ref period)
recode industrycat10 (1=1) (2/5=2) (6/9=3) (10=4), g(industrycat4)

* nlfreason - Reason not in the labor force (7-day ref period)
* note: prior to 2023, retired and old age are two seperate options, after 2023, they are one.
recode q5_7 (1 4=1) (2=2) (8/15 96=5) (6=4) (7=3) (*=.) if lstatus==3, g(nlfreason)
replace nlfreason = 1 if q2_1==1 & lstatus==3

* occup - 1 digit occupational classification, primary job (7-day ref period)
recode q4_1a (11111/14399=1) (21111/26599=2) (31111/35220=3) (41100/44190=4) (51111/54199=5) (61111/63400=6) (71110/75499=7) (81111/83503=8) (91110/96295 96299=9) (1101 2101 3101 99999=10) if lstatus==1, g(occup)

* occup_orig - Original occupational classification, primary job (7-day ref period)
decode q4_1a, g(occup_orig)

* ocusec - Sector of activity, primary job (7-day ref period)
recode q4_4 (1/2=1) (3 6/9=2) (4/5=3) (*=.) if lstatus==1, g(ocusec)

* unempldur_l - Unemployment duration (months) lower bracket (7-day ref period)
recode q5_5 (1=0) (2=1) (3=6) (4=12) (5=24) (*=.) if lstatus==2, g(unempldur_l)

* unempldur_u - Unemployment duration (months) upper bracket (7-day ref period)
recode q5_5 (1=1) (2=5) (3=11) (4=23) (*=.) if lstatus==2, g(unempldur_u)

* unitwage - Time unit of last wages payment, primary job (7-day ref period)
g unitwage = 5 if lstatus==1 & ~inlist(q4_13,-98,.,.a)

* unitwage_2 - Time unit of last wages payment, secondary job (7-day ref period)
g unitwage_2 = 5 if lstatus==1 & ~inlist(q4_15e,-98,.,.a)

* wage_nc - Wage payment, primary job, excl. bonuses, etc. (7-day ref period)
g wage_nc = q4_13 if lstatus==1 & ~inlist(q4_13,-98,.,.a)

* wage_nc_week - Wage payment adjusted to 1 week, primary job, excl. bonuses, etc. (7-day ref period)
g wage_nc_week = q4_13/4.3 if lstatus==1 & ~inlist(q4_13,-98,.,.a)

* wage_total - Annualized total wage, primary job (7-day ref period)
g wage_total = q4_13 * 12 if lstatus==1  & ~inlist(q4_13,-98,.,.a)

* wage_nc_2 - Wage payment, secondary job, excl. bonuses, etc. (7-day ref period)
g wage_nc_2 = q4_15e if lstatus==1 & ~inlist(q4_15e,-98,.,.a)

* wage_nc_week_2 - Wage payment adjusted to 1 week, secondary job, excl. bonuses, etc. (7-day ref period)
g wage_nc_week_2 = q4_15e/4.3 if lstatus==1 & ~inlist(q4_15e,-98,.,.a)

* wage_total_2 - Annualized total wage, secondary job (7-day ref period)
g wage_total_2 = q4_15e * 12 if lstatus==1  & ~inlist(q4_15e,-98,.,.a)

* whours - Hours of work in last week main activity
g whours = q4_12 if lstatus==1

* whours_2 - Hours of work in last week for the secondary job
g whours_2 = q4_15a if lstatus==1

* wmore - Willingness to work for more hours
recode q4_16 (1=1) (2=0) (*=.) if lstatus==1, g(wmore)

* stable_occup - Have worked for three or more years in current occupation, primary job 
g stable_occup = .

* following questions are in the survey but not in raw data
* pensions - Eligible for pension, primary job (7-day ref period)
g pensions = .

* annual_leave - Eligible for annual leave, primary job (7-day ref period)
g annual_leave = .

* sick_leave - Eligible for sick leave, primary job (7-day ref period)
g sick_leave = .

* paid_leave - Eligible for any paid leave, primary job (7-day ref period)
g paid_leave = .

* variables we cannot create:
* note about *_year variables: Question 3.3 asks about employment status 1 year ago, but in a very limited way (same/different/no job or studying). We cannot create any of the 12-month recall employment variables.
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
* unitwage_o - Time unit of last wages payment, other jobs (7-day ref period)
* wage_nc_o - Wage payment, other jobs, excl. bonuses, etc. (7-day ref period)
* wage_nc_week_o - Wage payment adjusted to 1 week, other jobs, excl. bonuses, etc. (7-day ref period)
* wage_total_o - Annualized total wage, other job (7-day ref period)
* whours_o - Hours of work in last week for other jobs
* wmonths_o - Months worked in the last 12 months for the others jobs
* empldur_orig_2 - Original employment duration/tenure, second job (7-day ref period)
* firmsize_l - Firm size (lower bracket), primary job (7-day ref period)
* firmsize_u - Firm size (upper bracket), primary job (7-day ref period)
* healthins - Health insurance (7-day ref period)
* njobs - Total number of jobs
* wmonths_2 - Months worked in the last 12 months for the secondary job
* union - Union membership (7-day ref period)
* wmonths - Months worked in the last 12 months main activity
* socialsec - Social security (7-day ref period)
* empstat_2 - Employment status, secondary job (7-day ref period)
* firmsize_l_2 - Firm size (lower bracket), secondary job (7-day ref period)
* firmsize_u_2 - Firm size (upper bracket), secondary job (7-day ref period)
* industry_orig_2 - Original industry code, secondary job (7-day ref period)
* industrycat10_2 - 1 digit industry classification, secondary job (7-day ref period)
* industrycat4_2 - 4-category industry classification, secondary job (7-day ref period)
* occup_2 - 1 digit occupational classification, secondary job (7-day ref period)
* occup_orig_2 - Original occupational classification, secondary job (7-day ref period)
* ocusec_2 - Sector of activity, secondary job (7-day ref period)
* paid_leave_2 - Eligible for paid leave, secondary job (7-day ref period)
* pensions_2 - Eligible for pension, secondary job (7-day ref period)
* maternity_leave - Eligible for maternity leave, primary job (7-day ref period)
* maternity_leave_year - Eligible for maternity leave, primary job (12-mon ref period)
* sick_leave_year - Eligible for sick leave, primary job (12-mon ref period)
* annual_leave_year - Eligible for annual leave, primary job (12-mon ref period)

foreach unavailable_var in contract_year empldur_orig_2_year empldur_orig_year empstat_2_year empstat_year firmsize_l_2_year firmsize_l_year firmsize_u_2_year firmsize_u_year ///
	healthins_year industry_orig_2_year industry_orig_year industrycat10_2_year industrycat10_year industrycat4_2_year industrycat4_year lstatus_year minlaborage_year nlfreason_year ///
	occup_2_year occup_orig_2_year occup_orig_year occup_year ocusec_2_year ocusec_year paid_leave_2_year paid_leave_year pensions_2_year pensions_year socialsec_year unempldur_l_year	///
	unempldur_u_year union_year unitwage_o wage_nc_o wage_nc_week_o wage_total_o whours_o wmonths_o empldur_orig_2 firmsize_l firmsize_u healthins njobs union wmonths wmonths_2 ///
	socialsec empstat_2 firmsize_l_2 firmsize_u_2 industry_orig_2 industrycat10_2 industrycat4_2 occup_2 occup_orig_2 ocusec_2 paid_leave_2 pensions_2 maternity_leave maternity_leave_year sick_leave_year annual_leave_year {
	if strmatch("`unavailable_var'","*orig*")==1 g `unavailable_var' = ""
	else g `unavailable_var' = .
}

* label all SARLD harmonized variables and values
do "${rootlabels}/label_SARLAB_variables.do"
save "${output}/`surveyfolder'_v`vm'_M_v`va'_A_`type'_TMP", replace
keep ${keepharmonized}
* save harmonized data
save "${output}/`surveyfolder'_v`vm'_M_v`va'_A_`type'_IND", replace
