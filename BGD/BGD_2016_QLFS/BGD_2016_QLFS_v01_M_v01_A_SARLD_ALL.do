***********************************************************************
*	BGD_2016_QLFS
*	SAR Labor Harmonization
*	Nov 2023
*	Sizhen Fang, sfang2@worldbank.org
***********************************************************************
clear
set more off
local countrycode	"BGD"
local year			"2016"
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
use "P:\SARMD\SARDATABANK\WORKINGDATA\BGD\BGD_2016_QLFS\BGD_2016_QLFS_v01_M\Data\Stata\Bangladesh QLFS 2016-17 Microdata.dta", clear

* countrycode = country code
g countrycode = "`countrycode'"

* year = Year
g year = 2016

* int_year = interview year
g int_year = 2016

* int_month = interview month
g int_month = .

* hhid = Household identifier
gen psu_str = string(psu, "%04.0f")
gen hh_str = string(hh, "%03.0f")
tostring qtr, gen(qtrstr)
egen hhid = concat(psu_str hh_str)

* pid = Personal identifier
gen lineno_str = string(ln, "%02.0f")
egen  pid = concat(hhid lineno_str)

* confirm unique identifiers: hhid + pid
* In BGD 2016, hhid and pid are not unique ids. same individual is visited acrossed multiple quaters
isid hhid pid qtr

* weight = Household weight
gen weight = wgt_fy2017

* relationharm = Relationship to head of household harmonized across all regions
* adapted from GLD
gen rela = rel
gen head = rela==1
bys hhid qtr: egen tot_head = sum(head)
count if tot_head!=1
gen neg_age = -(age)
sort hhid qtr sex neg_age ln
by hhid qtr: gen hhorder = _n
replace hhorder = . if hhorder!=1
replace rela = 1 if hhorder==1 & tot_head!=1
replace rela = 5 if hhorder!=1 & rela ==1 & tot_head!=1
drop tot_head head
gen head = rela==1
bys hhid qtr: egen tot_head = sum(head)
assert tot_head ==  1
drop tot_head head 
	
gen relationharm = .
replace relationharm = rela
drop rela
	
recode relationharm (4 6 8= 5) (7 = 4) (9 10 = 6)

* relationcs = Original relationship to head of household
gen relationcs = rel

* household member. All excluding household workers
gen hhmember=(~inlist(relationharm,7,.))

* hsize = Household size, not including household workers
bys hhid: egen hsize=total(hhmember)

* strata = Strata
confirm var strata

* spdef = Spatial deflator (if one is used)
g spdef = .

* subnatid1 = Subnational ID - highest level
gen str subnatid1 = ""
replace subnatid1 = "10 - Barisal" if divm == 10
replace subnatid1 = "20 - Chittagong" if divm == 20
replace subnatid1 = "30 - Dhaka" if divm == 30
replace subnatid1 = "40 - Khulna" if divm == 40
replace subnatid1 = "50 - Rajshahi" if divm == 50
replace subnatid1 = "55 - Rangpur" if divm == 55
replace subnatid1 = "60 - Sylhet" if divm == 60

* subnatid2 = Subnational ID - second highest level
tostring zlm, gen(zlmstr)
decode zlm, gen(zlmname)
gen str subnatid2 = zlmstr + " - " + zlmname

* subnatid3 = Subnational ID - third highest level
g subnatid3 = ""

* urban = Urban (1) or rural (0)	
gen urban = urbm
recode urban (2=1) (1=0)

* psu = PSU
drop psu
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
replace marital = q20
recode marital (1 = 2) (2 = 1) (3 = 5) (5 = 4)

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
replace educat7 = q24
recode educat7 (0 = 1) (1 2 3 4 = 2) (5 = 3) (6 7 8 9 = 4) (10 = 5) (11 12 = 6) (13 14 15 = 7) (99 = .)
		  
* educat5 = Highest level of education completed (5 categories)
gen byte educat5 = educat7
recode educat5 4=3 5=4 6 7=5

* educat4 = Highest level of education completed (4 categories)
gen byte educat4 = educat7
recode educat4 (2 3 4 = 2) (5=3) (6 7=4)

* educy = Years of completed education
g educy = .

* literacy = Individual can read and write
recode literacy (2 = 0)

* cellphone_i = Ownership of a cell phone (individual)
g cellphone_i = (q14l==1)

* computer = Ownership of a computer
g computer = (q14o==1)

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
* adapted from GLD code
gen byte lstatus = .
replace lstatus = 1 if q31 == 1
replace lstatus = 1 if q32 == 1 & q31 == 2
replace lstatus = 1 if (q33 == 1)
replace lstatus = 1 if (q33 == 2 & q34 == 1)
replace lstatus = 1 if emp == 1
replace lstatus = 2 if q77 == 1 & q81 == 1
replace lstatus = . if !missing(q83) & lstatus == 2
replace lstatus = 3 if missing(lstatus)
replace lstatus = . if age < minlaborage
		  
* empstat - Employment status, primary job (7-day ref period)
gen byte empstat=.
replace empstat = q49
recode empstat (1 = 3) (2 = 4) (3 = 2) (9 = 5) (4 5 6 7 = 1)
replace empstat = . if lstatus != 1

* contract - Contract (7-day ref period)
gen byte contract = .
replace contract = 1 if q50 == 1 | q50 == 2
replace contract = 0 if q50 == 3
replace contract = 0 if missing(q50) & lstatus == 1

* empldur_orig = Original employment duration/tenure, primary job (7-day ref period)
g empldur_orig = .

* industry_orig - Original industry code, primary job (7-day ref period)
gen industry_orig = ""
replace industry_orig = bsic4 if lstatus == 1

* industrycat10 - 1 digit industry classification, primary job (7-day ref period)
* adapted from GLD
gen isic3d = substr(industry_orig, 1, 3) 
gen industrycat_isic = isic3d + "0"
replace industrycat_isic = "3800" if industrycat_isic == "3410"  
replace industrycat_isic = "1700" if industrycat_isic == "1730"
replace industrycat_isic = "1900" if industrycat_isic == "1990"
replace industrycat_isic = "2300" if industrycat_isic == "2350"
replace industrycat_isic = "2900" if industrycat_isic == "2950"
replace industrycat_isic = "4100" if industrycat_isic == "4130"
replace industrycat_isic = "4100" if industrycat_isic == "4180"
replace industrycat_isic = "4200" if industrycat_isic == "4270"
replace industrycat_isic = "4500" if industrycat_isic == "4580"
replace industrycat_isic = "4900" if industrycat_isic == "4940"
replace industrycat_isic = "4900" if industrycat_isic == "4970"
replace industrycat_isic = "4900" if industrycat_isic == "4980"
replace industrycat_isic = "6100" if industrycat_isic == "6140"
replace industrycat_isic = "6400" if industrycat_isic == "6460"
replace industrycat_isic = "7500" if industrycat_isic == "7510"
replace industrycat_isic = "7500" if industrycat_isic == "7520"
replace industrycat_isic = "7500" if industrycat_isic == "7530"
replace industrycat_isic = "7500" if industrycat_isic == "7550"
replace industrycat_isic = "7900" if industrycat_isic == "7920"
replace industrycat_isic = "8100" if industrycat_isic == "8160"
replace industrycat_isic = "8700" if industrycat_isic == "8780"
replace industrycat_isic = "9200" if industrycat_isic == "9220"
replace industrycat_isic = "9600" if industrycat_isic == "9610"
replace industrycat_isic = "9700" if industrycat_isic == "9710"
replace industrycat_isic = "9700" if industrycat_isic == "9790"
replace industrycat_isic = "9900" if industrycat_isic == "9990"
replace industry_orig = "" if industry_orig == "."
replace industrycat_isic = "" if industrycat_isic == ".0" | industrycat_isic == "0"
drop isic3d

gen industrycat10 = .
gen isic2d = substr(industrycat_isic, 1, 2)
destring isic2d, replace
replace industrycat10 = isic2d
recode industrycat10 (1/3=1) (5/9 = 2) (10/33 = 3) (35/39 = 4) (41/43 = 5) (45/47 55/56 = 6) (49/53 58/63 = 7) (64/82 = 8) (84 = 9) (85/99 = 10)	
drop isic2d

* industrycat4 - 4-category industry classification, primary job (7-day ref period)
gen byte industrycat4 = industrycat10
recode industrycat4 (1=1)(2 3 4 5 =2)(6 7 8 9=3)(10=4)

* nlfreason - Reason not in the labor force (7-day ref period)
gen byte nlfreason=.
replace nlfreason = q83 if lstatus == 3
recode nlfreason (3 = 4) (4 = 3) (5 6 7 9 = 5) (0 8 = .)

* occup - 1 digit occupational classification, primary job (7-day ref period)
gen byte occup = .
replace occup = bsco1 if lstatus == 1
recode occup (0 = 99) 

* occup_orig - Original occupational classification, primary job (7-day ref period)
gen occup_orig = bsco4 if lstatus == 1

* ocusec - Sector of activity, primary job (7-day ref period)
gen byte ocusec = .
replace ocusec = q39 if lstatus == 1
recode ocusec (2 = 4) (3 = 1) (4 5 6 7 8 = 2) (9 = .)

* unempldur_l - Unemployment duration (months) lower bracket (7-day ref period)
gen byte unempldur_l= .
replace unempldur_l = 0 if q82 == 1
replace unempldur_l = 1 if q82 == 2
replace unempldur_l = 7 if q82 == 3
replace unempldur_l = 13 if q82 == 4
replace unempldur_l = 25 if q82 == 5
replace unempldur_l = . if lstatus != 2

* unempldur_u - Unemployment duration (months) upper bracket (7-day ref period)
gen byte unempldur_u= .
replace unempldur_u = 1 if q82 == 1
replace unempldur_u = 6 if q82 == 2
replace unempldur_u = 12 if q82 == 3
replace unempldur_u = 24 if q82 == 4
replace unempldur_u = . if q82 == 5
replace unempldur_u = . if lstatus != 2

* unitwage - Time unit of last wages payment, primary job (7-day ref period)
gen byte unitwage = .
replace unitwage = 5
replace unitwage = . if lstatus !=1

* wage_nc - Wage payment, primary job, excl. bonuses, etc. (7-day ref period)
egen double wage_nc = rowtotal(q54a q54b) if lstatus == 1
recode wage_nc (0 = .)

* wage_nc_week - Wage payment adjusted to 1 week, primary job, excl. bonuses, etc. (7-day ref period)
g wage_nc_week = wage_nc/4.3 if lstatus==1 & ~mi(wage_nc)

* wage_total - Annualized total wage, primary job (7-day ref period)
g wage_total = wage_nc * 12 if lstatus==1 & ~mi(wage_nc)

* empstat_2 - Employment status, secondary job (7-day ref period)
gen byte empstat_2 = .
replace empstat_2 = q60
recode empstat_2 (1 = 3) (2 = 4) (3 9 = 5) (4 5 6 7 = 1)
replace empstat_2 = . if q56 == 2
replace empstat_2 = . if lstatus != 1
	
* wage_nc_2 - Wage payment, secondary job, excl. bonuses, etc. (7-day ref period)
egen double wage_nc_2 = rowtotal(q62a q62b)
recode wage_nc_2 (0 = .)
replace wage_nc_2 = . if missing(empstat_2)

* wage_nc_week_2 - Wage payment adjusted to 1 week, secondary job, excl. bonuses, etc. (7-day ref period)
g wage_nc_week_2 = wage_nc_2/4.3 if lstatus==1 & ~mi(wage_nc_2)

* wage_total_2 - Annualized total wage, primary job (7-day ref period)
g wage_total_2 = wage_nc_2 * 12 if lstatus==1 & ~mi(wage_nc_2)

* unitwage_2 - Time unit of last wages payment, secondary job (7-day ref period)
gen byte unitwage_2 = .
replace unitwage_2 = 5 if !missing(wage_nc_2)

* whours - Hours of work in last week main activity
gen whours = q48
replace whours = . if whours == 0 | whours == 99
replace whours = . if lstatus != 1

* whours_2 - Hours of work in last week for the secondary job
gen whours_2 = q59
replace whours_2 = . if whours_2 == 0 | whours_2 == 99
replace whours_2 = . if missing(empstat_2)

* wmore - Willingness to work for more hours
gen wmore = .
replace wmore = 1 if q70 == 1 
replace wmore = 0 if q70 == 2

* firmsize_l - Firm size (lower bracket), primary job (7-day ref period)
gen firmsize_l = .
replace firmsize_l = 1 if q38 == 1
replace firmsize_l = 2 if q38 == 2
replace firmsize_l = 5 if q38 == 3
replace firmsize_l = 10 if q38 == 4
replace firmsize_l = 25 if q38 == 5
replace firmsize_l = 100 if q38 == 6
replace firmsize_l = 250 if q38 == 7
replace firmsize_l = . if lstatus != 1

* firmsize_u - Firm size (upper bracket), primary job (7-day ref period)
gen firmsize_u= .
replace firmsize_u = 1 if q38 == 1
replace firmsize_u = 4 if q38 == 2
replace firmsize_u = 9 if q38 == 3
replace firmsize_u = 24 if q38 == 4
replace firmsize_u = 99 if q38 == 5
replace firmsize_u = 249 if q38 == 6
replace firmsize_u = . if q38 == 7
replace firmsize_u = . if lstatus != 1

* healthins - Health insurance (7-day ref period)
gen byte healthins = (q52g == 1)
replace healthins = . if lstatus != 1

* maternity_leave - Eligible for maternity leave, primary job (7-day ref period)
gen byte maternity_leave = (q52b == 1)
replace maternity_leave = . if lstatus != 1

* sick_leave - Eligible for sick leave, primary job (7-day ref period)
gen byte sick_leave = (q52c == 1)
replace sick_leave = . if lstatus != 1

* paid_leave - Eligible for any paid leave, primary job (7-day ref period)
gen byte paid_leave = (maternity_leave == 1 | sick_leave == 1)

* pensions - Eligible for pension, primary job (7-day ref period)
gen byte pensions = (q52a == 1)
replace pensions = . if lstatus != 1

* industry_orig_2 - Original industry code, secondary job (7-day ref period)
gen industry_orig_2 = string(q57b, "%04.0f")
replace industry_orig_2 = "" if missing(empstat_2)

* industrycat10_2 - 1 digit industry classification, secondary job (7-day ref period)
gen isic3d = substr(industry_orig_2, 1, 3) 
gen industrycat_isic_2 = isic3d + "0"
gen byte industrycat10_2 = .
gen isic2d_s = substr(industrycat_isic_2, 1, 2)
destring isic2d_s, replace
replace industrycat10_2 = isic2d_s
recode industrycat10_2 (1/3=1) (5/9 = 2) (10/33 = 3) (35/39 = 4) (41/43 = 5) (45/47 55/56 = 6) (49/53 58/63 = 7) (64/82 = 8) (84 = 9) (85/99 = 10)	

* industrycat4_2 - 4-category industry classification, secondary job (7-day ref period)
gen byte industrycat4_2 = industrycat10_2
recode industrycat4_2 (1=1)(2 3 4 5 =2)(6 7 8 9=3)(10=4)
	
* occup_orig_2 - Original occupational classification, secondary job (7-day ref period)	
gen occup_orig_2 = string(q58a, "%04.0f")
replace occup_orig_2 = "" if missing(empstat_2)

* occup_2 - 1 digit occupational classification, secondary job (7-day ref period)
gen isco2d_s = substr(occup_orig_2, 1, 2)
gen occup_isco_2 = isco2d_s + "00"
replace occup_isco_2 = "0000" if occup_isco_2 == "0610"
replace occup_isco_2 = "0000" if occup_isco_2 == "0990"
replace occup_isco_2 = "6000" if occup_isco_2 == "6400"
replace occup_isco_2 = "8000" if occup_isco_2 == "8600"
replace occup_isco_2 = "9000" if occup_isco_2 == "9900"
replace occup_isco_2 = "" if occup_isco_2 == ".0"
replace occup_isco_2 = "" if occup_isco_2 == ".00" | occup_isco_2 == "00"
drop isco2d_s

gen occup_2 = substr(occup_isco_2, 1, 1)
destring occup_2, replace
recode occup_2 (0 = 10)

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
* annual_leave - Eligible for annual leave, primary job (7-day ref period)
* annual_leave_year - Eligible for annual leave, primary job (12-mon ref period)
* stable_occup - Have worked for three or more years in current occupation, primary job 

foreach unavailable_var in contract_year empldur_orig_2_year empldur_orig_year empstat_2_year empstat_year firmsize_l_2_year firmsize_l_year firmsize_u_2_year firmsize_u_year ///
	healthins_year industry_orig_2_year industry_orig_year industrycat10_2_year industrycat10_year industrycat4_2_year industrycat4_year lstatus_year minlaborage_year nlfreason_year ///
	occup_2_year occup_orig_2_year occup_orig_year occup_year ocusec_2_year ocusec_year paid_leave_2_year paid_leave_year pensions_2_year pensions_year socialsec_year unempldur_l_year	///
	unempldur_u_year union_year unitwage_o wage_nc_o wage_nc_week_o wage_total_o whours_o wmonths_o empldur_orig_2 njobs union wmonths wmonths_2 ///
	socialsec firmsize_l_2 firmsize_u_2 ocusec_2 paid_leave_2 pensions_2 maternity_leave_year sick_leave_year annual_leave annual_leave_year stable_occup {
	if strmatch("`unavailable_var'","*orig*")==1 g `unavailable_var' = ""
	else g `unavailable_var' = .
}


* label all SARLD harmonized variables and values
do "${rootlabels}/label_SARLAB_variables.do"
save "${output}/`surveyfolder'_v`vm'_M_v`va'_A_`type'_TMP", replace
keep ${keepharmonized}
* save harmonized data
save "${output}/`surveyfolder'_v`vm'_M_v`va'_A_`type'_IND", replace
