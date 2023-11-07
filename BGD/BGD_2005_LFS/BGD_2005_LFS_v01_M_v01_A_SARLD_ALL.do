***********************************************************************
*	BGD_2005_LFS
*	SAR Labor Harmonization
*	Nov 2023
*	Sizhen Fang, sfang2@worldbank.org
***********************************************************************
clear
set more off
local countrycode	"BGD"
local year			"2005"
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
datalibweb, country(BGD) year(2005) type(GLDRAW) surveyid(BGD_2005_LFS_V01_M) filename(bsic_isic_mapping.dta)
tempfile bsic
save `bsic', replace

datalibweb, country(BGD) year(2005) type(GLDRAW) surveyid(BGD_2005_LFS_V01_M) filename(LFS05_06_Final.dta)

* countrycode = country code
g countrycode = "`countrycode'"

* year = Year
g year = 2005

* int_year = interview year
g int_year = 2005

* int_month = interview month
g int_month = round

* hhid = Household identifier
drop hhid
gen psu_str = string(psu, "%04.0f")
gen hh_str = string(hh, "%03.0f")
egen hhid = concat(psu_str hh_str)

* pid = Personal identifier
gen lineno_str = string(line_no, "%02.0f")
egen  pid = concat(hhid lineno_str)

* confirm unique identifiers: hhid + pid
isid hhid pid

* weight = Household weight
gen weight = wgt

* relationharm = Relationship to head of household harmonized across all regions
* adapted from GLD
gen rela = rel
gen head = rela==1
bys hhid: egen tot_head = sum(head)
count if tot_head!=1
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
gen strata = stratum

* spdef = Spatial deflator (if one is used)
g spdef = .

* subnatid1 = Subnational ID - highest level
gen str subnatid1 = ""
replace subnatid1 = "10 - Barisal" if dv2 == 10
replace subnatid1 = "20 - Chittagong" if dv2 == 20
replace subnatid1 = "30 - Dhaka" if dv2 == 30
replace subnatid1 = "40 - Khulna" if dv2 == 40
replace subnatid1 = "50 - Rajshahi" if dv2 == 50
replace subnatid1 = "60 - Sylhet" if dv2 == 60

* subnatid2 = Subnational ID - second highest level
gen subnatid2 = ""
replace subnatid2 = "01 - Bagerhat" if zila == 01
replace subnatid2 = "03 - Bandarban" if zila == 03
replace subnatid2 = "04 - Barguna" if zila == 04
replace subnatid2 = "06 - Barisal" if zila == 06
replace subnatid2 = "09 - Bhola" if zila == 09
replace subnatid2 = "10 - Bogra" if zila == 10
replace subnatid2 = "12 - Brahmanbaria" if zila == 12
replace subnatid2 = "13 - Chandpur" if zila == 13
replace subnatid2 = "15 - Chittagong" if zila == 15
replace subnatid2 = "18 - Chuadanga" if zila == 18
replace subnatid2 = "19 - Comilla" if zila == 19
replace subnatid2 = "22 - Cox'S Bazar" if zila == 22
replace subnatid2 = "26 - Dhaka" if zila == 26
replace subnatid2 = "27 - Dinajpur" if zila == 27
replace subnatid2 = "29 - Faridpur" if zila == 29
replace subnatid2 = "30 - Feni" if zila == 30
replace subnatid2 = "32 - Gaibandha" if zila == 32
replace subnatid2 = "33 - Gazipur" if zila == 33
replace subnatid2 = "35 - Gopalganj" if zila == 35
replace subnatid2 = "36 - Habiganj" if zila == 36
replace subnatid2 = "38 - Joypurhat" if zila == 38
replace subnatid2 = "39 - Jamalpur" if zila == 39
replace subnatid2 = "41 - Jessore" if zila == 41
replace subnatid2 = "42 - Jhalokati" if zila == 42
replace subnatid2 = "44 - Jhenaidah" if zila == 44
replace subnatid2 = "46 - Khagrachhari" if zila == 46
replace subnatid2 = "47 - Khulna" if zila == 47
replace subnatid2 = "48 - Kishorgonj" if zila == 48
replace subnatid2 = "49 - Kurigram" if zila == 49
replace subnatid2 = "50 - Kushtia" if zila == 50
replace subnatid2 = "51 - Lakshmipur" if zila == 51
replace subnatid2 = "52 - Lalmonirhat" if zila == 52
replace subnatid2 = "54 - Madaripur" if zila == 54
replace subnatid2 = "55 - Magura" if zila == 55
replace subnatid2 = "56 - Manikganj" if zila == 56
replace subnatid2 = "57 - Meherpur" if zila == 57
replace subnatid2 = "58 - Maulvibazar" if zila == 58
replace subnatid2 = "59 - Munshiganj" if zila == 59
replace subnatid2 = "61 - Mymensingh" if zila == 61
replace subnatid2 = "64 - Naogaon" if zila == 64
replace subnatid2 = "65 - Narail" if zila == 65
replace subnatid2 = "67 - Narayanganj" if zila == 67
replace subnatid2 = "68 - Narsingdi" if zila == 68
replace subnatid2 = "69 - Natore" if zila == 69
replace subnatid2 = "70 - Nawabganj" if zila == 70
replace subnatid2 = "72 - Netrakona" if zila == 72
replace subnatid2 = "73 - Nilphamari" if zila == 73
replace subnatid2 = "75 - Noakhali" if zila == 75
replace subnatid2 = "76 - Pabna" if zila == 76
replace subnatid2 = "77 - Panchagarh" if zila == 77
replace subnatid2 = "78 - Patuakhali" if zila == 78
replace subnatid2 = "79 - Pirojpur" if zila == 79
replace subnatid2 = "81 - Rajshahi" if zila == 81
replace subnatid2 = "82 - Rajbari" if zila == 82
replace subnatid2 = "84 - Rangamati" if zila == 84
replace subnatid2 = "85 - Rangpur" if zila == 85
replace subnatid2 = "86 - Shariatpur" if zila == 86
replace subnatid2 = "87 - Satkhira" if zila == 87
replace subnatid2 = "88 - Sirajganj" if zila == 88
replace subnatid2 = "89 - Sherpur" if zila == 89
replace subnatid2 = "90 - Sunamganj" if zila == 90
replace subnatid2 = "91 - Sylhet" if zila == 91
replace subnatid2 = "93 - Tangail" if zila == 93
replace subnatid2 = "94 - Thakurgaon" if zila == 94

* subnatid3 = Subnational ID - third highest level
g subnatid3 = ""

* urban = Urban (1) or rural (0)	
gen urban = rural == 0

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
replace marital = mst
recode marital (1 = 2) (2 = 1) (3 = 5) (5 = 4) (0 = .)

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
recode educat7 (3 = 4) (8 9 = 7) (0 10 11 = . )
		  
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
replace literacy = lit
recode literacy (2 = 0) (0 = .)

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
* adapted from GLD code
gen byte lstatus = .
replace lstatus = 1 if emp == 1
replace lstatus = 2 if s8q82 == 1 & s8q83vl1 != 9
replace lstatus = 3 if missing(lstatus)
replace lstatus = . if age < minlaborage
		  
* empstat - Employment status, primary job (7-day ref period)
gen byte empstat=.
replace empstat = s4q412
recode empstat (2 = 3) (4 = 2) (3 = 4) (5 6 7 8 = 1) (9 10 = 5) (0 = .)
replace empstat = . if lstatus != 1

* contract - Contract (7-day ref period)
gen byte contract = .
replace contract = 0 if lstatus == 1
replace contract = 1 if inlist(s4q416, 1)

* empldur_orig = Original employment duration/tenure, primary job (7-day ref period)
g empldur_orig = .

* industry_orig - Original industry code, primary job (7-day ref period)
gen industry_orig = string(s4q44, "%04.0f")
replace industry_orig = "" if lstatus != 1

* industrycat10 - 1 digit industry classification, primary job (7-day ref period)
* adapted from GLD
merge m:1 industry_orig using `bsic' , keep(master match)
gen isic_2d = substr(industry_orig, 1, 2) + "00"
replace industrycat_isic =isic_2d   if !missing(industry_orig) & missing(industrycat_isic)
drop isic_2d

gen isic_1d = substr(industrycat_isic, 1, 1)
gen isic_2d = substr(industrycat_isic, 1, 2)
destring isic_1d, replace
destring isic_2d, replace
gen byte industrycat10 = .
replace industrycat10 = 1 if isic_1d == 0
replace industrycat10 = 2 if inrange(isic_2d, 10, 14)
replace industrycat10 = 3 if inrange(isic_2d, 15, 37)
replace industrycat10 = 4 if inrange(isic_2d, 40, 41)
replace industrycat10 = 5 if isic_2d == 45
replace industrycat10 = 6 if isic_1d == 5
replace industrycat10 = 7 if inrange(isic_2d, 60, 64)
replace industrycat10 = 8 if inrange(isic_2d, 65, 74)
replace industrycat10 = 9 if isic_2d == 75
replace industrycat10 = 10 if inrange(isic_2d, 80, 99)
drop isic_1d isic_2d

* industrycat4 - 4-category industry classification, primary job (7-day ref period)
gen byte industrycat4 = industrycat10
recode industrycat4 (1=1)(2 3 4 5 =2)(6 7 8 9=3)(10=4)

* nlfreason - Reason not in the labor force (7-day ref period)
gen byte nlfreason=.

* occup_orig - Original occupational classification, primary job (7-day ref period)
gen occup_orig = string(s4q46, "%04.0f")

* occup - 1 digit occupational classification, primary job (7-day ref period)
gen occup_isco = substr(occup_orig, 1, 2) + "00"
replace occup_isco = "" if lstatus != 1
gen occup = substr(occup_isco, 1, 1)
destring occup, replace
replace occup = . if lstatus != 1
recode occup (0 = 10)

* ocusec - Sector of activity, primary job (7-day ref period)
gen byte ocusec = .
replace ocusec = s4q414 if lstatus == 1
recode ocusec (7 = 1) (1 2 3 4 5 6 8 = 2) (0 9 = .)

* unempldur_l - Unemployment duration (months) lower bracket (7-day ref period)
gen byte unempldur_l= s8q84
replace unempldur_l = . if lstatus != 2

* unempldur_u - Unemployment duration (months) upper bracket (7-day ref period)
gen byte unempldur_u= s8q84
replace unempldur_u = . if lstatus != 2

* wage_nc - Wage payment, primary job, excl. bonuses, etc. (7-day ref period)
gen double wage_nc = .
egen wage_salary = rowtotal(s4q419val1 s4q419val2) if s4q412 == 1
replace wage_salary = s4q419val3 if s4q419val3!=0 & s4q412 == 1
replace wage_salary = . if wage_salary == 0
egen wage_laborer = rowtotal(s4q418val1 s4q418val2) if s4q412 == 6 | s4q412 == 7
replace wage_laborer = s4q418val3 if s4q418val3!=0 & (s4q412 == 6 | s4q412 == 7)
replace wage_laborer = . if wage_laborer == 0
replace wage_nc = wage_salary if s4q412 == 1
replace wage_nc = wage_laborer if (s4q412 == 6 | s4q412 == 7)
replace wage_nc = . if lstatus !=1

* wage_nc_week - Wage payment adjusted to 1 week, primary job, excl. bonuses, etc. (7-day ref period)
g wage_nc_week = wage_nc/4.3 if lstatus==1 & ~mi(wage_nc)

* wage_total - Annualized total wage, primary job (7-day ref period)
g wage_total = wage_nc * 12 if lstatus==1 & ~mi(wage_nc)

* unitwage - Time unit of last wages payment, primary job (7-day ref period)
gen byte unitwage = .
replace unitwage = 5 if !missing(wage_salary)
replace unitwage = 2 if !missing(wage_laborer)
replace unitwage = . if missing(wage_nc)
replace unitwage = . if lstatus !=1

* union - Union membership (7-day ref period)
drop union
gen union = .

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
gen whours = s4q47
replace whours = . if whours == 0
replace whours = . if lstatus != 1

* whours_2 - Hours of work in last week for the secondary job
gen whours_2 = .

* wmore - Willingness to work for more hours
gen wmore = .

* firmsize_l - Firm size (lower bracket), primary job (7-day ref period)
gen firmsize_l = .

* firmsize_u - Firm size (upper bracket), primary job (7-day ref period)
gen firmsize_u= .

* healthins - Health insurance (7-day ref period)
gen byte healthins = .

* maternity_leave - Eligible for maternity leave, primary job (7-day ref period)
gen maternity_leave = .

* sick_leave - Eligible for sick leave, primary job (7-day ref period)
egen byte sick_leave = anymatch(s4q420v1-s4q420v6), value(2)
replace sick_leave = 0 if missing(sick_leave) & lstatus == 1

* annual_leave - Eligible for annual leave, primary job (7-day ref period)
gen annual_leave = .

* paid_leave - Eligible for any paid leave, primary job (7-day ref period)
gen byte paid_leave = (maternity_leave == 1 | sick_leave == 1 | annual_leave == 1)

* pensions - Eligible for pension, primary job (7-day ref period)
gen byte pensions = .

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
	unempldur_u_year union_year unitwage_o wage_nc_o wage_nc_week_o wage_total_o whours_o wmonths_o empldur_orig_2 njobs wmonths wmonths_2 ///
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
