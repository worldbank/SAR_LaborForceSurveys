***********************************************************************
*	BGD_2013_LFS
*	SAR Labor Harmonization
*	Nov 2023
*	Sizhen Fang, sfang2@worldbank.org
***********************************************************************
clear
set more off
local countrycode	"BGD"
local year			"2013"
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
datalibweb, country(BGD) year(2013) type(GLDRAW) surveyid(LFS) clear

* countrycode = country code
g countrycode = "`countrycode'"

* year = Year
g year = 2013

* int_year = interview year
g int_year = 2013

* int_month = interview month
g int_month = .

* hhid = Household identifier
gen psu_str = string(psu, "%04.0f")
gen hh_str = string(hh, "%04.0f")
egen hhid = concat(psu_str hh_str)

* pid = Personal identifier
gen lineno_str = string(line, "%02.0f")
egen  pid = concat(hhid lineno_str)

* confirm unique identifiers: hhid + pid
isid hhid pid

* weight = Household weight
gen weight = wgt_final

* relationharm = Relationship to head of household harmonized across all regions
* adapted from GLD
gen rela = rel
gen head = rela==1
bys hhid: egen tot_head = sum(head)
count if tot_head>1
gen relationharm = .
replace relationharm = rela
drop rela
recode relationharm (5 7 8= 5) (6 9  = 6)

* relationcs = Original relationship to head of household
gen relationcs = rel

* household member. All excluding household workers
gen hhmember=(~inlist(relationharm,7,.))

* hsize = Household size, not including household workers
bys hhid: egen hsize=total(hhmember)

* strata = Strata
gen strata = strata21

* spdef = Spatial deflator (if one is used)
g spdef = .

* subnatid1 = Subnational ID - highest level
gen str subnatid1 = ""
replace subnatid1 = "10 - Barisal" if div == 10
replace subnatid1 = "20 - Chittagong" if div == 20
replace subnatid1 = "30 - Dhaka" if div == 30
replace subnatid1 = "40 - Khulna" if div == 40
replace subnatid1 = "50 - Rajshahi" if div == 50
replace subnatid1 = "55 - Rangpur" if div == 55
replace subnatid1 = "60 - Sylhet" if div == 60

* subnatid2 = Subnational ID - second highest level
tostring zl, gen(zlmstr)
decode zl, gen(zlmname)
replace zlmname = proper(zlmname)
gen str subnatid2 = zlmstr + " - " + zlmname

* subnatid3 = Subnational ID - third highest level
g subnatid3 = ""

* urban = Urban (1) or rural (0)	
gen urban = urb
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
replace marital = q23_b
recode marital (2 = 5) (3 = 4) 
replace marital = 2 if q23_a == 2

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
replace educat7 = class
recode educat7 (0 = 1) (1 2 3 4 = 2) (5 = 3) (6 7 8 9 = 4) (10 11 = 5) (12 = 6) (13 14 15 16 = 7) (99 = .)
replace educat7 = 1 if q26 == 2
		  
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
g cellphone_i = .

* computer = Ownership of a computer
recode q11_computer (2 = 0), g(computer)

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
* IN 2013, this is 5 years and above
g minlaborage = 5

* lstatus - Labor status (7-day ref period)
* adapted from GLD code
gen byte lstatus = .
replace lstatus = 1 if q39 == 1
replace lstatus = 1 if q40 == 1 | q41 == 1
replace lstatus = 1 if q42 == 1
replace lstatus = 1 if q43 == 1
replace lstatus = 2 if q84 == 1 & q87 == 1
replace lstatus = 3 if missing(lstatus)
replace lstatus = . if age < minlaborage
		  
* empstat - Employment status, primary job (7-day ref period)
gen byte empstat=.
replace empstat = q48
recode empstat (1 = 3) (2 3 = 4) (5 6 7 8 9= 1) (4 = 2) (99 = 1)
replace empstat = . if lstatus != 1

* contract - Contract (7-day ref period)
gen byte contract = .
replace contract = 1 if q55 == 1 | q55 == 2
replace contract = 0 if q55 == 3
replace contract = 0 if missing(q55) & lstatus == 1

* empldur_orig = Original employment duration/tenure, primary job (7-day ref period)
g empldur_orig = .

* industry_orig - Original industry code, primary job (7-day ref period)
gen bsic4_str = string(q45, "%04.0f")
gen industry_orig = ""
replace industry_orig = bsic4_str if lstatus == 1

* industrycat10 - 1 digit industry classification, primary job (7-day ref period)
* adapted from GLD
gen bsic2d = substr(industry_orig, 1, 2)
gen industrycat_isic = bsic2d + "00"
replace industrycat_isic = "3800" if industrycat_isic == "3400"  
drop bsic2d

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
replace nlfreason = q89 if lstatus == 3
recode nlfreason (3 = 4) (4 = 3) (5 6 7 9 = 5)

* occup - 1 digit occupational classification, primary job (7-day ref period)
gen byte occup = .
replace occup = bsco1 if lstatus == 1
recode occup (0 = 99) 

* occup_orig - Original occupational classification, primary job (7-day ref period)
gen occup_orig = bsco4 if lstatus == 1
replace occup_orig = "" if occup_orig == "."

* ocusec - Sector of activity, primary job (7-day ref period)
gen byte ocusec = .
replace ocusec = q49 if lstatus == 1
recode ocusec (2 = 1)  (3 4 5 6 = 2) (9 = .)

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
gen double wage_nc = q77_cashkind if lstatus == 1
recode wage_nc (0 = .)

* wage_nc_week - Wage payment adjusted to 1 week, primary job, excl. bonuses, etc. (7-day ref period)
g wage_nc_week = wage_nc/4.3 if lstatus==1 & ~mi(wage_nc)

* wage_total - Annualized total wage, primary job (7-day ref period)
g wage_total = wage_nc * 12 if lstatus==1 & ~mi(wage_nc)

* empstat_2 - Employment status, secondary job (7-day ref period)
gen byte empstat_2 = .
replace empstat_2 = q63_status2
recode empstat_2 (1 = 3) (2 3 = 4) (9 = 5) (5 6 7 8 = 1) (4 = 2) (99 = .)
replace empstat_2 = . if q60_job2 == 2
replace empstat_2 = . if lstatus != 1
	
* wage_nc_2 - Wage payment, secondary job, excl. bonuses, etc. (7-day ref period)
gen wage_nc_2 = .

* wage_nc_week_2 - Wage payment adjusted to 1 week, secondary job, excl. bonuses, etc. (7-day ref period)
g wage_nc_week_2 = .

* wage_total_2 - Annualized total wage, primary job (7-day ref period)
g wage_total_2 = .

* unitwage_2 - Time unit of last wages payment, secondary job (7-day ref period)
gen byte unitwage_2 = .

* whours - Hours of work in last week main activity
gen whours = q59_hours
replace whours = . if whours == 0 
replace whours = . if lstatus != 1

* whours_2 - Hours of work in last week for the secondary job
gen whours_2 = q64_hours2
replace whours_2 = . if whours_2 == 0 | whours_2 == 99
replace whours_2 = . if missing(empstat_2)

* wmore - Willingness to work for more hours
gen wmore = .
replace wmore = 1 if q78 == 1 | q78 == 2
replace wmore = 0 if q78 == 3

* firmsize_l - Firm size (lower bracket), primary job (7-day ref period)
gen firmsize_l = .
replace firmsize_l = 1 if q54 == 1
replace firmsize_l = 2 if q54 == 2
replace firmsize_l = 10 if q54 == 3
replace firmsize_l = 25 if q54 == 4
replace firmsize_l = 100 if q54 == 5
replace firmsize_l = 250 if q54 == 6
replace firmsize_l = . if lstatus != 1

* firmsize_u - Firm size (upper bracket), primary job (7-day ref period)
gen firmsize_u= .
replace firmsize_u = 1 if q54 == 1
replace firmsize_u = 9 if q54 == 2
replace firmsize_u = 9 if q54 == 3
replace firmsize_u = 24 if q54 == 4
replace firmsize_u = 99 if q54 == 5
replace firmsize_u = . if q54 == 6
replace firmsize_u = . if lstatus != 1

* healthins - Health insurance (7-day ref period)
gen byte healthins = .

* maternity_leave - Eligible for maternity leave, primary job (7-day ref period)
gen maternity_leave = .
replace maternity_leave = 1 if q57_b == 1
replace maternity_leave = 0 if q57_b == 2

* sick_leave - Eligible for sick leave, primary job (7-day ref period)
gen sick_leave = .
replace sick_leave = 1 if q57_c == 1
replace sick_leave = 0 if q57_c == 2

* paid_leave - Eligible for any paid leave, primary job (7-day ref period)
gen byte paid_leave = (maternity_leave == 1 | sick_leave == 1)

* pensions - Eligible for pension, primary job (7-day ref period)
gen byte pensions = .
replace pensions = 1 if q57_a == 1 | q57_a_r == 1
replace pensions = 0 if q57_a == 2 & q57_a_r == 2

* industry_orig_2 - Original industry code, secondary job (7-day ref period)
gen industry_orig_2 = string(q61_ind2, "%04.0f")
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
gen occup_orig_2 = string(q62_occ2, "%04.0f")
replace occup_orig_2 = "" if occup_orig_2 == "."

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
