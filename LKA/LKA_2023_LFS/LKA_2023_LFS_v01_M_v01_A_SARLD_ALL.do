***********************************************************************
*	LKA_2023_LFS
*	SAR Labor Harmonization
*	December 2024
*	Sizhen Fang, sfang2@worldbank.org
***********************************************************************
clear
set more off
local countrycode	"LKA"
local year			"2023"
local survey		"LFS"
local va			"01"
local vm			"01"
local type			"SARLAB"
local surveyfolder	"`countrycode'_`year'_`survey'"

* global path on SF's computer
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
* load data on SF's computer
if ("`c(username)'"=="wb611670") {
	* load data
	* start with HH data
	use "${surveydata}/2023LFSAnnual-OutFile-With-Computer", clear
}
* global paths on WB computer
else {
	* start with individual data
	datalibweb, country(`countrycode') year(`year') survey(`survey') type(SARRAW) 
}

* countrycode = country code
g countrycode = "`countrycode'"

* year = Year
rename ïyear year

* int_year = interview year
g int_year = year

* int_month = interview month
g int_month = month

* hhid = Household identifier
* NOTE: hhid = DDPPPUUH
*	district		: district (2 digits)
*	psu				: primary sampling unit (3 digits)
*	hunit			: housing unit number (2 digits)
*	hhold			: HH number (1 digit)
foreach var in district psu hunit {
	tostring `var', g(`var'_str)
	replace `var'_str = "0" + `var'_str if length(`var'_str)<2
}
replace psu_str = "0" + psu_str if length(psu_str)<3
g hhid = district_str + psu_str + hunit_str + string(hhold)

* pid = Personal identifier
rename serno pid

* confirm unique identifiers: hhid + pid
isid hhid pid

* weight = Household weight
g weight = annual_factor

* relationharm = Relationship to head of household harmonized across all regions
recode rship (1=1) (2=2) (3=3) (4=4) (5=5) (6/7=7) (9=6) (*=.), g(relationharm)

* relationcs = Original relationship to head of household
label define rship 1 "Head of Household" 2 "Wife / Husband" 3 "Son / Daughter" 4 "Parents" 5 "Other Relative" 6 "Domestic Servant" 7 "Boarder" 9 "Other"
label values rship rship
decode rship, g(relationcs)

* household member. All excluding household workers
gen hhmember=(~inlist(relationharm,7,.))

* hsize = Household size, not including household workers
egen hsize = total(hhmember), by(hhid)

* strata = Strata
g strata = string(year) + "-" + string(month) + "-" + string(sector) + "-" + string(district)

* psu = PSU
confirm var psu

* spdef = Spatial deflator (if one is used)
g spdef = .

* subnatid1 = Subnational ID - highest level
g province = floor(district/10)
label define province 1 "Western Province" 2 "Central Province" 3 "Southern Province" 4 "Northern Province" 5 "Eastern Province" 6 "North Western Province" 7 "North Central Province" 8 "Uva Province" 9 "Sabaragamuwa Province"
label values province province
decode province, g(subnatid1)
replace subnatid1 = string(province) + " - " + subnatid1

* subnatid2 = Subnational ID - second highest level
label define district 11 "Colombo" 12 "Gampaha" 13 "Kalutara" 21 "Kandy" 22 "Matale" 23 "Nuwara Eliya" 31 "Galle" 32 "Matara" 33 "Hambantota" 41 "Jaffna" 42 "Mannar" 43 "Vavuniya" 44 "Mullaitivu" 45 "Kilinochchi" 51 "Batticaloa" 52 "Ampara" 53 "Trincomalee" 61 "Kurunegala" 62 "Puttalam" 71 "Anuradhapura" 72 "Polonnaruwa" 81 "Badulla" 82 "Moneragala" 91 "Ratnapura" 92 "Kegalle"
label values district district
decode district, g(subnatid2)
replace subnatid2 = string(district) + " - " + subnatid2

* subnatid3 = Subnational ID - third highest level
g subnatid3 = ""

* urban = Urban (1) or rural (0)
recode sector (2/3=0) (1=1) (*=.), g(urban)

* language = Language
g		language = "Sinhala" if sin==1
replace	language = language + ", " + "Tamil" if ~missing(language) & tamil==1
replace	language = "Tamil" if missing(language) & tamil==1
replace	language = language + ", " + "English" if ~missing(language) & eng==1
replace	language = "English" if missing(language) & eng==1

* age = Age of individual (continuous)
confirm var age

* male = Sex of household member (male=1)
recode sex (1=1) (2=0) (*=.), g(male)

* marital = Marital status
recode marital (1=2) (2=1) (3=5) (4/5=4) (*=.)

* eye_dsablty = Difficulty seeing
recode p15 (1=4) (2=3) (3=2) (4=1) (*=.), g(eye_dsablty)

* hear_dsablty = Difficulty hearing
recode p16 (1=4) (2=3) (3=2) (4=1) (*=.), g(hear_dsablty)

* walk_dsablty = Difficulty walking or climbing steps
recode p17 (1=4) (2=3) (3=2) (4=1) (*=.), g(walk_dsablty)

* conc_dsord = Difficulty remembering or concentrating
recode p18 (1=4) (2=3) (3=2) (4=1) (*=.), g(conc_dsord)

* slfcre_dsablty = Difficulty with self-care
recode p19 (1=4) (2=3) (3=2) (4=1) (*=.), g(slfcre_dsablty)

* comm_dsablty = Difficulty communicating
recode p20 (1=4) (2=3) (3=2) (4=1) (*=.), g(comm_dsablty)

* educat7 = Highest level of education completed (7 categories)
* note: adapted from LKA_2016_HIES code for SARMD
recode edu (19 = 1) (0/5 = 2) (6 = 3) (7/10 = 4) (11/14 = 5) (17=6) (15/16=7) (*=.) if age>=5, g(educat7)
note educat7: For LKA_2021_LFS, to be consistent with LKA_2016_HIES we categorized "Special Education learning / learnt" as educat7 = 6 "Higher than secondary but not university".

* educat5 = Highest level of education completed (5 categories)
recode educat7 (0=0) (1=1) (2=2) (3/4=3) (5=4) (6/7=5), g(educat5)
note educat5: For LKA_2021_LFS, to be consistent with LKA_2016_HIES we categorized "Special Education learning / learnt" as educat5 = 5 "some tertiary/post-secondary".

* educat4 = Highest level of education completed (4 categories)
recode educat7 (0=0) (1=1) (2/3=2) (4/5=3) (6/7=4), g(educat4)
note educat4: For LKA_2021_LFS, to be consistent with LKA_2016_HIES we categorized "Special Education learning / learnt" as educat4 = 4 "Tertiary (complete or incomplete)".

* educy = Years of completed education
* note: Mapping copied from LKA_2016_HIES SARMD do file
recode edu (18=.) (19=0), g(educy)

* literacy = Individual can read and write
egen literacy = rowmin(sin tamil eng)
recode literacy (2=0)

* cellphone_i = Ownership of a cell phone (individual)
egen cellphone_i = rowmin(c1_4a c1_5a)
recode cellphone_i (2=0)

* computer = Ownership of a computer
egen computer = rowmin(c1_1a c1_2a)
recode computer (2=0)

* etablet = Ownership of a electronic tablet
recode c1_3a (2=0) (1=1) (*=.), g(etablet)

* internet_athome = Internet available at home, any service (including mobile)
g internet_athome = (inlist(c8_1,1,2,3,4)) if inlist(c7,1,2)
note internet_athome: For LKA_2021_LFS, we used "internet use anywhere" as a proxy for "internet availability at home".

* internet_mobile = has mobile Internet (mobile 2G 3G LTE 4G 5G ), any service
g internet_mobile = .

* internet_mobile4Gplus = has mobile high speed internet (mobile LTE 4G 5G ) services
g internet_mobile4Gplus = .


*********************
* labor

* minlaborage - Labor module application age (7-day ref period)
g minlaborage = 15

* lstatus - Labor status (7-day ref period)
g		lstatus = 1 if q2==1 | q4==1
replace	lstatus = 2 if mi(lstatus) & ((q47==1 & q48==1) | q47==3)
replace	lstatus = 3 if mi(lstatus) & q2==2

* empstat - Employment status, primary job (7-day ref period)
recode q9 (1=1) (2=3) (3=4) (4=2) if lstatus==1, g(empstat)

* contract - Contract (7-day ref period)
g contract = (q13==1) if lstatus==1 & (q10==4 | inlist(q13,1,2))
note contract: For LKA_2021_LFS, this question was only asked to employees, and only if those employees had permanent, temporary, or casual employment (ie. did not answer "no permanent employer").

* firmsize_l - Firm size (lower bracket), primary job (7-day ref period)
recode q17 (1=1) (2=5) (3=10) (4=16) (5=50) (6=100) (*=.), g(firmsize_l)

* firmsize_u - Firm size (upper bracket), primary job (7-day ref period)
recode q17 (1=4) (2=9) (3=15) (4=49) (5=99) (*=.), g(firmsize_u)

* industry_orig - Original industry code, primary job (7-day ref period)
tostring q8, g(industry_orig)

* industrycat10 - 1 digit industry classification, primary job (7-day ref period)
g		industrycat10 = floor(q8/1000) if lstatus==1
recode	industrycat10 (1/3=1) (4/9=2) (10/33=3) (35/39=4) (41/43=5) (45/47 55/56=6) (49/53 58/63 79=7) (64/68 83=8) (84=9) (69/78 80/82 85/99=10) (*=.)

* industrycat4 - 4-category industry classification, primary job (7-day ref period)
recode industrycat10 (1=1) (2/5=2) (6/9=3) (10=4), g(industrycat4)

* nlfreason - Reason not in the labor force (7-day ref period)
recode q52 (1=1) (2=2) (3=3) (4=4) (9=5) if lstatus==3, g(nlfreason)

* occup - 1 digit occupational classification, primary job (7-day ref period)
g occup = floor(q7/1000) if lstatus==1
recode occup (0=10)

* occup_orig - Original occupational classification, primary job (7-day ref period)
tostring q7, g(occup_orig)

* ocusec - Sector of activity, primary job (7-day ref period)
recode q14 (1=1) (2=3) (3=2) (*=.) if lstatus==1, g(ocusec)

* paid_leave - Eligible for any paid leave, primary job (7-day ref period)
recode q12 (1=1) (2=0) (*=.) if lstatus==1, g(paid_leave)

* pensions - Eligible for pension, primary job (7-day ref period)
recode q11 (1=1) (2=0) (*=.) if lstatus==1, g(pensions)

* socialsec - Social security (7-day ref period)
recode q11 (1=1) (2=0) (*=.) if lstatus==1, g(socialsec)

* unempldur_l - Unemployment duration (months) lower bracket (7-day ref period)
recode q58 (1=1) (2=6) (3=12) (*=.) if lstatus==2, g(unempldur_l)

* unempldur_u - Unemployment duration (months) upper bracket (7-day ref period)
recode q58 (1=5) (2=11) (*=.) if lstatus==2, g(unempldur_u)

* unitwage - Time unit of last wages payment, primary job (7-day ref period)
g		unitwage = 1 if lstatus==1 & ~mi(q45_b_1)
replace	unitwage = 5 if lstatus==1 & (~mi(q45_a_1) | ~mi(q45_c_1))

* wage_nc - Wage payment, primary job, excl. bonuses, etc. (7-day ref period)
g		wage_nc = q45_a_1 if lstatus==1
replace	wage_nc = q45_b_1 if lstatus==1 & ~mi(q45_b_1)
replace wage_nc = q45_c_1 if lstatus==1 & ~mi(q45_c_1)

* wage_nc_week - Wage payment adjusted to 1 week, primary job, excl. bonuses, etc. (7-day ref period)
g		wage_nc_week = q45_a_1 if lstatus==1 & ~mi(q45_a_1)
replace	wage_nc_week = q45_b_1 * q45_b_2 if lstatus==1 & ~mi(q45_b_1)
replace	wage_nc_week = q45_c_1 if lstatus==1 & ~mi(q45_c_1)

* wage_total - Annualized total wage, primary job (7-day ref period)
egen	wage_total_mse_month = rowtotal(q45_a_1 q45_a_2 q45_a_3), missing
g		wage_total_we_wages_month = q45_b_1 * q45_b_2
g		wage_total_we_inkind_month = q45_b_4
egen	wage_total_month = rowtotal(wage_total_mse_month wage_total_we_wages_month wage_total_we_inkind_month q45_c_1), mis
g		wage_total = wage_total_month * 12 if lstatus==1

* whours - Hours of work in last week main activity
g whours = q20
note whours: For LKA_2022_LFS, we used "number of hours you usually worked at this occupation work per week" instead of "number of hours you actually worked at this occupation during the reference period".

* empstat_2 - Employment status, secondary job (7-day ref period)
recode q27 (1=1) (2=3) (3=4) (4=2) if lstatus==1, g(empstat_2)

* firmsize_l_2 - Firm size (lower bracket), secondary job (7-day ref period)
recode q35 (1=1) (2=5) (3=10) (4=16) (5=50) (6=100) (*=.), g(firmsize_l_2)

* firmsize_u_2 - Firm size (upper bracket), secondary job (7-day ref period)
recode q35 (1=4) (2=9) (3=15) (4=49) (5=99) (*=.), g(firmsize_u_2)

* industry_orig_2 - Original industry code, secondary job (7-day ref period)
tostring q26, g(industry_orig_2)

* industrycat10_2 - 1 digit industry classification, secondary job (7-day ref period)
g		industrycat10_2 = floor(q26/1000) if lstatus==1
recode	industrycat10_2 (1/3=1) (4/9=2) (10/33=3) (35/39=4) (41/43=5) (45/47 55/56=6) (49/53 58/63 79=7) (64/68 83=8) (84=9) (69/78 80/82 85/99=10) (*=.)

* industrycat4_2 - 4-category industry classification, secondary job (7-day ref period)
recode industrycat10_2 (1=1) (2/5=2) (6/9=3) (10=4), g(industrycat4_2)

* occup_2 - 1 digit occupational classification, secondary job (7-day ref period)
g occup_2 = floor(q25/1000) if lstatus==1
recode occup_2 (0=10)

* occup_orig_2 - Original occupational classification, secondary job (7-day ref period)
tostring q25, g(occup_orig_2)

* ocusec_2 - Sector of activity, secondary job (7-day ref period)
recode q32 (1=1) (2=3) (3=2) (*=.) if lstatus==1, g(ocusec_2)

* paid_leave_2 - Eligible for paid leave, secondary job (7-day ref period)
recode q30 (1=1) (2=0) (*=.) if lstatus==1, g(paid_leave_2)

* pensions_2 - Eligible for pension, secondary job (7-day ref period)
recode q29 (1=1) (2=0) (*=.) if lstatus==1, g(pensions_2)

* unitwage_2 - Time unit of last wages payment, secondary job (7-day ref period)
g		unitwage_2 = 1 if lstatus==1 & ~mi(q46_b_1)
replace	unitwage_2 = 5 if lstatus==1 & (~mi(q46_a_1) | ~mi(q46_c_1))

* wage_nc_2 - Wage payment, secondary job, excl. bonuses, etc. (7-day ref period)
g		wage_nc_2 = q46_a_1 if lstatus==1
replace	wage_nc_2 = q46_b_1 if lstatus==1 & ~mi(q46_b_1)
replace wage_nc_2 = q46_c_1 if lstatus==1 & ~mi(q46_c_1)

* wage_nc_week_2 - Wage payment adjusted to 1 week, secondary job, excl. bonuses, etc. (7-day ref period)
g		wage_nc_week_2 = q46_a_1 if lstatus==1 & ~mi(q46_a_1)
replace	wage_nc_week_2 = q46_b_1 * q46_b_2 if lstatus==1 & ~mi(q46_b_1)
replace	wage_nc_week_2 = q46_c_1 if lstatus==1 & ~mi(q46_c_1)

* wage_total_2 - Annualized total wage, secondary job (7-day ref period)
egen	wage_total_2_mse_month = rowtotal(q46_a_1 q46_a_2 q46_a_3), missing
g		wage_total_2_we_wages_month = q46_b_1 * q46_b_2
g		wage_total_2_we_inkind_month = q46_b_4
egen	wage_total_2_month = rowtotal(wage_total_2_mse_month wage_total_2_we_wages_month wage_total_2_we_inkind_month q46_c_1), mis
g		wage_total_2 = wage_total_2_month * 12 if lstatus==1

* whours_2 - Hours of work in last week for the secondary job
g whours_2 = q38
note whours_2: For LKA_2021_LFS, we used "number of hours you usually worked at this occupation work per week" instead of "number of hours you actually worked at this occupation during the reference period".

* wmore - Would you like to work more?
recode q41 (1=1) (2=0) (*=.) if lstatus==1, g(wmore)


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
* maternity_leave - Eligible for maternity leave, primary job (7-day ref period)
* maternity_leave_year - Eligible for maternity leave, primary job (12-mon ref period)
* sick_leave - Eligible for sick leave, primary job (7-day ref period)
* sick_leave_year - Eligible for sick leave, primary job (12-mon ref period)
* annual_leave - Eligible for annual leave, primary job (7-day ref period)
* annual_leave_year - Eligible for annual leave, primary job (12-mon ref period)
* stable_occup - Have worked for three or more years in current occupation, primary job 
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
* empldur_orig - Original employment duration/tenure, primary job (7-day ref period)
* empldur_orig_2 - Original employment duration/tenure, second job (7-day ref period)
* healthins - Health insurance (7-day ref period)
* njobs - Total number of jobs
* union - Union membership (7-day ref period)
* wmonths - Months worked in the last 12 months main activity
* wmonths_2 - Months worked in the last 12 months for the secondary job

foreach unavailable_var in contract_year empldur_orig_2_year empldur_orig_year empstat_2_year empstat_year firmsize_l_2_year firmsize_l_year firmsize_u_2_year firmsize_u_year ///
	healthins_year industry_orig_2_year industry_orig_year industrycat10_2_year industrycat10_year industrycat4_2_year industrycat4_year lstatus_year minlaborage_year nlfreason_year ///
	occup_2_year occup_orig_2_year occup_orig_year occup_year ocusec_2_year ocusec_year paid_leave_2_year paid_leave_year  pensions_2_year pensions_year socialsec_year unempldur_l_year stable_occup maternity_leave maternity_leave_year sick_leave sick_leave_year annual_leave annual_leave_year ///
	unempldur_u_year union_year unitwage_o wage_nc_o wage_nc_week_o wage_total_o whours_o wmonths_o empldur_orig empldur_orig_2 healthins njobs union wmonths wmonths_2 {
	if strmatch("`unavailable_var'","*orig*")==1 g `unavailable_var' = ""
	else g `unavailable_var' = .
}


* label all SARLD harmonized variables and values
do "${rootlabels}/label_SARLAB_variables.do"
save "${output}/`surveyfolder'_v`vm'_M_v`va'_A_`type'_TMP", replace
keep ${keepharmonized}
* save harmonized data
save "${output}/`surveyfolder'_v`vm'_M_v`va'_A_`type'_IND", replace
