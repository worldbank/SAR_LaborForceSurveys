***********************************************************************
*	BGD_2010_LFS
*	SAR Labor Harmonization
*	Nov 2023
*	Sizhen Fang, sfang2@worldbank.org
***********************************************************************
clear
set more off
local countrycode	"BGD"
local year			"2010"
local survey		"LFS"
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
datalibweb, country(BGD) year(2010) type(GLDRAW) surveyid(LFS) clear

* countrycode = country code
g countrycode = "`countrycode'"

* year = Year
g year = 2010

* int_year = interview year
g int_year = 2010

* int_month = interview month
g int_month = 5

* hhid = Household identifier
gen psu_str = string(psu_no, "%04.0f")
gen hh_str = string(hhno, "%03.0f")
egen hhid = concat(psu_str hh_str)

* pid = Personal identifier
gen lineno_str = string(lineno, "%02.0f")
egen pid = concat(hhid lineno_str)

* confirm unique identifiers: hhid + pid
isid hhid pid

* weight = Household weight
gen weight = wgt_svrs

* relationharm = Relationship to head of household harmonized across all regions
* adapted from GLD
gen rela = s3_2
gen head = rela==1
bys hhid: egen tot_head = sum(head)
count if tot_head!=1
gen neg_age = -(age)
sort hhid sex neg_age lineno
by hhid: gen hhorder = _n
replace hhorder = . if hhorder!=1
replace rela = 1 if hhorder==1 & tot_head!=1
replace rela = 5 if hhorder!=1 & rela ==1 & tot_head!=1
drop tot_head head
gen head = rela==1
bys hhid: egen tot_head = sum(head)
assert tot_head ==  1
drop tot_head head 
gen relationharm = .
replace relationharm = rela
drop rela
recode relationharm (4 6 8= 5) (7 = 4) (9 10 = 6)

* relationcs = Original relationship to head of household
gen relationcs = s3_2

* household member. All excluding household workers
gen hhmember=(~inlist(relationharm,7,.))

* hsize = Household size, not including household workers
bys hhid: egen hsize=total(hhmember)

* strata = Strata
gen strata = strataf

* spdef = Spatial deflator (if one is used)
g spdef = .

* subnatid1 = Subnational ID - highest level
gen str subnatid1 = ""
replace subnatid1 = "10 - Barisal" if div == 10
replace subnatid1 = "20 - Chittagong" if div == 20
replace subnatid1 = "30 - Dhaka" if div == 30
replace subnatid1 = "40 - Khulna" if div == 40
replace subnatid1 = "50 - Rajshahi" if div == 50
replace subnatid1 = "60 - Sylhet" if div == 60

* subnatid2 = Subnational ID - second highest level
gen districtname = proper(zl_name)
gen str subnatid2 = zl + " - " + districtname

* subnatid3 = Subnational ID - third highest level
g subnatid3 = ""

* urban = Urban (1) or rural (0)	
confirm var urban

* psu = PSU
gen psu = psu_str

* language = Language
g language = ""

* age = Age of individual (continuous)
confirm var age

* male = Sex of household member (male=1)
gen male = sex
recode male (2 = 0)

* marital = Marital status
gen byte marital = .
replace marital = s3_6
recode marital (3 = 5) (5 = 4)

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
gen byte educat7 =.
replace educat7 = edu
recode educat7 (3 = 4) (8 9 = 7) (10 11 = . )
		  
* educat5 = Highest level of education completed (5 categories)
gen byte educat5 = educat7
recode educat5 4=3 5=4 6 7=5

* educat4 = Highest level of education completed (4 categories)
gen byte educat4 = educat7
recode educat4 (2 3 4 = 2) (5=3) (6 7=4)

* educy = Years of completed education
g educy = .

* literacy = Individual can read and write
gen byte literacy = .
replace literacy = q37
recode literacy (2 = 0)

* cellphone_i = Ownership of a cell phone (individual)
g cellphone_i = .

* computer = Ownership of a computer
recode s2_9_9 (2 = 0), g(computer)

* etablet = Ownership of a electronic tablet
g etablet = .

* internet_athome = Internet available at home, any service (including mobile)
* In BGD 2010, the survey does not distinguish ownership of computer vs internet
recode s2_9_9 (2 = 0), g(internet_athome)

* internet_mobile = has mobile Internet (mobile 2G 3G LTE 4G 5G ), any service
g internet_mobile = .

* internet_mobile4Gplus = has mobile high speed internet (mobile LTE 4G 5G ) services
g internet_mobile4Gplus = .


*********************
* labor

* minlaborage - Labor module application age (7-day ref period)
g minlaborage = 15

* lstatus - Labor status (7-day ref period)
* adapted from GLD code
gen byte lstatus = .
replace lstatus = 1 if s4_1 == 1
replace lstatus = 1 if s4_2 == 1 & inlist(s4_3, 3, 4)
replace lstatus = 2 if inlist(s5_1, 1, 2) & s5_5 == 1
replace lstatus = 3 if missing(lstatus)
replace lstatus = . if age < minlaborage
		  
* empstat - Employment status, primary job (7-day ref period)
gen byte empstat=.
replace empstat = s4_9
recode empstat (2 = 3) (3 = 4) (5 = 2) (6 7 8 9 = 1)
replace empstat = . if lstatus != 1

* contract - Contract (7-day ref period)
gen byte contract = .
replace contract = 1 if s4_23 == 1
replace contract = 0 if s4_23 == 2 | s4_23 == 3

* empldur_orig = Original employment duration/tenure, primary job (7-day ref period)
g empldur_orig = .

* industry_orig - Original industry code, primary job (7-day ref period)
gen industry_orig = ""
replace industry_orig = s4_7 if lstatus == 1

* industrycat10 - 1 digit industry classification, primary job (7-day ref period)
* adapted from GLD
gen bsic2d = substr(industry_orig, 1, 2)
gen industrycat_isic = bsic2d + "00"
replace industrycat_isic = "3800" if industrycat_isic == "3400" 
 
gen industrycat10 = .
gen isic2d = substr(industrycat_isic, 1, 2)
destring isic2d, replace
replace industrycat10 = isic2d
recode industrycat10 (1/3=1) (5/9 = 2) (10/33 = 3) (35/39 = 4) (41/43 = 5) (45/47 55/56 = 6) (49/53 58/63 = 7) (64/82 = 8) (84 = 9) (85/99 = 10)

* industrycat4 - 4-category industry classification, primary job (7-day ref period)
gen byte industrycat4 = industrycat10
recode industrycat4 (1=1)(2 3 4 5 =2)(6 7 8 9=3)(10=4)

* nlfreason - Reason not in the labor force (7-day ref period)
gen byte nlfreason=.
replace nlfreason = s5_3 if lstatus == 3
recode nlfreason (1 2 3 7 9 10 = 5) (4 = 1) (5 = 2) (6 = 3) (8 = 4)

* occup - 1 digit occupational classification, primary job (7-day ref period)
gen byte occup = .
replace occup = bsco88 if lstatus == 1
recode occup (0 = 10)

* occup_orig - Original occupational classification, primary job (7-day ref period)
gen occup_orig = s4_17 if lstatus == 1

* ocusec - Sector of activity, primary job (7-day ref period)
gen byte ocusec = .
replace ocusec = s4_10 if lstatus == 1
recode ocusec (2 = 4) (3 = 1) (4 5 6 7 8 = 2) (9 = .)

* unempldur_l - Unemployment duration (months) lower bracket (7-day ref period)
gen byte unempldur_l= s5_4
replace unempldur_l = . if lstatus != 2

* unempldur_u - Unemployment duration (months) upper bracket (7-day ref period)
gen byte unempldur_u= s5_4
replace unempldur_u = . if lstatus != 2

* wage_nc - Wage payment, primary job, excl. bonuses, etc. (7-day ref period)
egen double wage_nc = rowtotal(s4_13 s4_14) if lstatus == 1
recode wage_nc (0 = .)

* wage_nc_week - Wage payment adjusted to 1 week, primary job, excl. bonuses, etc. (7-day ref period)
g wage_nc_week = wage_nc/4.3 if lstatus==1 & ~mi(wage_nc)

* wage_total - Annualized total wage, primary job (7-day ref period)
g wage_total = wage_nc * 12 if lstatus==1 & ~mi(wage_nc)

* unitwage - Time unit of last wages payment, primary job (7-day ref period)
gen byte unitwage = .
replace unitwage = 2 if !missing(wage_nc)
replace unitwage = . if lstatus !=1

* empstat_2 - Employment status, secondary job (7-day ref period)
gen byte empstat_2 = .
	
* wage_nc_2 - Wage payment, secondary job, excl. bonuses, etc. (7-day ref period)
gen wage_nc_2 = .

* wage_nc_week_2 - Wage payment adjusted to 1 week, secondary job, excl. bonuses, etc. (7-day ref period)
g wage_nc_week_2 = .

* wage_total_2 - Annualized total wage, primary job (7-day ref period)
g wage_total_2 = .

* unitwage_2 - Time unit of last wages payment, secondary job (7-day ref period)
gen byte unitwage_2 = .

* whours - Hours of work in last week main activity
gen whours = s4_22h
replace whours = . if whours == 0
replace whours = . if lstatus != 1

* whours_2 - Hours of work in last week for the secondary job
gen whours_2 = .

* wmore - Willingness to work for more hours
gen wmore = .
replace wmore = 1 if s4_44 == 1 | s4_44 == 2
replace wmore = 0 if s4_44 == 3

* firmsize_l - Firm size (lower bracket), primary job (7-day ref period)
gen firmsize_l = s4_40
replace firmsize_l = . if lstatus != 1

* firmsize_u - Firm size (upper bracket), primary job (7-day ref period)
gen firmsize_u= s4_40
replace firmsize_u = . if lstatus != 1

* healthins - Health insurance (7-day ref period)
gen byte healthins = .

* maternity_leave - Eligible for maternity leave, primary job (7-day ref period)
gen maternity_leave = .
replace maternity_leave = 1 if s4_27 == 1
replace maternity_leave = 0 if s4_27 == 2

* sick_leave - Eligible for sick leave, primary job (7-day ref period)
gen sick_leave = .
replace sick_leave = 1 if s4_25 == 1
replace sick_leave = 0 if s4_25 == 2

* annual_leave - Eligible for annual leave, primary job (7-day ref period)
gen annual_leave = .
replace annual_leave = 1 if s4_26 == 1
replace annual_leave = 0 if s4_26 == 2

* paid_leave - Eligible for any paid leave, primary job (7-day ref period)
gen byte paid_leave = (maternity_leave == 1 | sick_leave == 1 | annual_leave == 1)

* pensions - Eligible for pension, primary job (7-day ref period)
gen byte pensions = .
replace pensions = 1 if s4_32 == 1 
replace pensions = 0 if s4_32 == 2

* industry_orig_2 - Original industry code, secondary job (7-day ref period)
gen industry_orig_2 = .

* industrycat10_2 - 1 digit industry classification, secondary job (7-day ref period)
gen byte industrycat10_2 = .

* industrycat4_2 - 4-category industry classification, secondary job (7-day ref period)
gen byte industrycat4_2 = .
	
* occup_orig_2 - Original occupational classification, secondary job (7-day ref period)	
gen occup_orig_2 = .

* occup_2 - 1 digit occupational classification, secondary job (7-day ref period)
gen byte occup_2 = .


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
