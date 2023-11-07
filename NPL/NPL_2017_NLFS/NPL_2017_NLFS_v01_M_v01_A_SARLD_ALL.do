***********************************************************************
*	NPL_2018_NLFS
*	SAR Labor Harmonization
*	June 2023
*	Joseph Green, josephgreen@gmail.com
***********************************************************************
clear
set more off
local countrycode	"NPL"
local year			"2018"
local survey		"NLFS"
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
if ("`c(username)'"=="wb611670") {
	* define folder paths
	glo rootdatalib "C:\Users\wb611670\WBG\Laura Liliana Moreno Herrera - 09.SARLAB\WORKINGDATA"
	glo rootlabels "C:\Users\wb611670\WBG\Laura Liliana Moreno Herrera - 09.SARLAB\SARLD_programs\_aux"
}

* global paths on WB computer
else {
	* start with individual data
	datalibweb, country(`countrycode') year(`year') survey(`survey') type(SARRAW) filename(NPL_2018_NLFS.dta) localpath(${rootdatalib}) local
	* merge in income data
	tempfile individual_level_data
	save `individual_level_data'
	datalibweb, country(`countrycode') year(`year') survey(`survey') type(SARRAW) filename(S06_rc.dta) localpath(${rootdatalib}) local
	merge 1:1 personid using `individual_level_data', nogen assert(match)
	* merge in hours worked
	save `individual_level_data'
	datalibweb, country(`countrycode') year(`year') survey(`survey') type(SARRAW) filename(S05_rc.dta) localpath(${rootdatalib}) local
	merge 1:1 personid using `individual_level_data', nogen assert(match)
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
	* load data
	* start with HH data
	use "${surveydata}/NPL_2018_NLFS", clear
	* merge in income data
	merge 1:1 personid using "${surveydata}/S06_rc", nogen assert(match)
	* merge in hours worked
	merge 1:1 personid using "${surveydata}/S05_rc", nogen assert(match)
}

if ("`c(username)'"=="wb611670") {
	* load data
	* start with HH data
	use "${surveydata}/NPL_2018_NLFS", clear
	* merge in income data
	merge 1:1 personid using "${surveydata}/S06_rc", nogen assert(match)
	* merge in hours worked
	merge 1:1 personid using "${surveydata}/S05_rc", nogen assert(match)
}

* countrycode = country code
g countrycode = "`countrycode'"

* year = Year
g year = `year'

* int_year = interview year
g int_year = .

* int_month = interview month
g int_month = .

* hhid = Household identifier
tostring hhld, g(str_hhld)
replace str_hhld = "0" + str_hhld if length(str_hhld)<2
g hhid = string(psu) + str_hhld
destring hhid, replace

* pid = Personal identifier
clonevar pid = personid

* confirm hhid and pid uniquely identify each individual
isid hhid pid

* weight = Household weight
rename designweight_hh weight

* relationharm = Relationship to head of household harmonized across all regions
recode rel_hhh (1=1) (2=2) (3=3) (4 6/9=5) (5=4) (10=7) (11=6) (*=.u), g(relationharm)
note relationharm: For NPL_2018_NLFS, the category 11 "Others" overlaps with two relationharm categories: 6 "non-relatives" and 7 "non household members (domestic worker, room renter)". We assigned them to relationharm = 6 "non-relatives".
note relationharm: For NPL_2018_NLFS, 858 individuals had missing values for their relationship to the head (rel_hhh) and were assigned relationharm = .u

* relationcs = Original relationship to head of household
decode rel_hhh, g(relationcs)

* hsize = Household size
* note: household members = All excluding household workers and those with unknown relationships
egen hsize = total(~inlist(relationharm,7,.,.u)), by(hhid)
note hsize: For NPL_2018_NLFS, 858 individuals has missing values for their relationship to the head (rel_hhh), and were not counted in the hsize.

* strata = Strata
g strata = ""

* psu = PSU
confirm var psu

* spdef = Spatial deflator (if one is used)
g spdef = ""

* subnatid1 = Subnational ID - highest level
g		subnatid1 = string(province) + " - " + "Province " + string(province) if inlist(province,1,2,3,5)
replace	subnatid1 = string(province) + " - " + "Gandaki" if province==3
replace	subnatid1 = string(province) + " - " + "Karnali" if province==6
replace	subnatid1 = string(province) + " - " + "Sudurpashchim" if province==7

* subnatid2 = Subnational ID - second highest level
decode dist, g(subnatid2)
replace subnatid2 = string(dist) + " - " + subnatid2

* subnatid3 = Subnational ID - third highest level
decode dist, g(dist_str)
g subnatid3 = string(vdcmun) + " - " + dist_str + " VDC/Municipality"

* urban = Urban (1) or rural (0)
recode urbrur753 (1=1) (2=0) (*=.), g(urban)

* language = Language
g language = ""

* age = Age of individual (continuous)
confirm var age

* male = Sex of household member (male=1)
recode sex (1=1) (2=0) (*=.), g(male)

* marital = Marital status
recode marital (1=2) (2=1) (3=5) (4/5=4) (*=.)

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
recode grade_comp (0 16 17=1) (1/7=2) (8=3) (9/11=4) (12=5) (13/15=7) (*=.), g(educat7)

* educat5 = Highest level of education completed (5 categories)
recode educat7 (0=0) (1=1) (2=2) (3/4=3) (5=4) (6/7=5), g(educat5)

* educat4 = Highest level of education completed (4 categories)
recode educat7 (0=0) (1=1) (2/3=2) (4/5=3) (6/7=4), g(educat4)

* educy = Years of completed education
g educy = .

* literacy = Individual can read and write
egen	literacy = rowmax(can_read can_write)
* not literate if they either can't read or can't write
recode	literacy (2=0)
* can't be considered literate if we don't know they can both read AND write
recode	literacy (1=.) if mi(can_read,can_write)

* cellphone_i = Ownership of a cell phone (individual)
egen cellphone_i = anymatch(house_facility_?), values(7)
note cellphone_i: For NPL_2018_NLFS, we used the household's access to a mobile phone as a proxy for the individual ownership of a cell phone.
		  
* computer = Ownership of a computer
egen computer = anymatch(house_facility_?), values(4)

* etablet = Ownership of a electronic tablet
g etablet = .

* internet_athome = Internet available at home, any service (including mobile)
egen internet_athome = anymatch(house_facility_?), values(5)

* internet_mobile = has mobile Internet (mobile 2G 3G LTE 4G 5G ), any service
g internet_mobile = .

* internet_mobile4Gplus = has mobile high speed internet (mobile LTE 4G 5G ) services
g internet_mobile4Gplus = .


* labor

* minlaborage = Labor module application age (7-day ref period)
g minlaborage = 10

* lstatus = Labor status (7-day ref period)
g		lstatus = 1 if wrk_paid==1 | wrk_busns==1 | wrk_unpaid==1 | temp_absent==1
replace	lstatus = 2 if mi(lstatus) & (seek30==1 | jobfixed==1)
replace	lstatus = 3 if mi(lstatus) & (inrange(rsn_nteffort,1,14) | seek30==2 | jobfixed==2)
note lstatus: For NPL_2018_NLFS, the recall period for most labor questions used was 7 days. However, the question used regarding looking for work had a reference period of 30 days.

* contract = Contract (7-day ref period)
g contract = (mwrk_cnrt_basis==1) if lstatus==1 & inlist(mwrk_cnrt_basis,1,2)

* empldur_orig = Original employment duration/tenure, primary job (7-day ref period)
decode mwrk_tenure_envlv if lstatus==1, g(empldur_orig)

* empstat = Employment status, primary job (7-day ref period)
recode mwrk_status (1=1) (2 5/6=5) (3=3) (4=4)  (*=.) if lstatus==1, g(empstat)

* firmsize_l = Firm size (lower bracket), primary job (7-day ref period)
recode mwrk_empnum (1=1) (2=2) (3=5) (4=10) (5=20) (*=.) if lstatus==1, g(firmsize_l)

* firmsize_u = Firm size (upper bracket), primary job (7-day ref period)
recode mwrk_empnum (1=1) (2=4) (3=9) (4=19) (*=.) if lstatus==1, g(firmsize_u)

* healthins = Health insurance (7-day ref period)
g healthins = .

* industry_orig = Original industry code, primary job (7-day ref period)
g industry_orig = string(mwrk_nsco4) if lstatus==1

* industrycat10 = 1 digit industry classification, primary job (7-day ref period)
g		industrycat10 = floor(mwrk_nsco4/100) if lstatus==1
recode	industrycat10 (1/3=1) (4/9=2) (10/33=3) (35/39=4) (41/43=5) (45/47 55/56=6) (49/53 58/63 79=7) (64/68 83=8) (84=9) (69/78 80/82 85/99=10) (*=.)

* industrycat4 = 4-category industry classification, primary job (7-day ref period)
recode industrycat10 (1=1) (2/5=2) (6/9=3) (10=4), g(industrycat4)

* njobs = Total number of jobs
g njobs = .

* nlfreason = Reason not in the labor force (7-day ref period)
recode rsn_nteffort (1/7 10/12 14=5) (8=1) (9=2) (13=4) (*=.) if lstatus==3, g(nlfreason)
recode	nlfreason (5 .=1) if rsn_ntavail==1 & lstatus==3
recode	nlfreason (5 .=2) if rsn_ntavail==2 & lstatus==3
recode	nlfreason (5 .=4) if rsn_ntavail==3 & lstatus==3
replace nlfreason = 3 if rsn_ntavail==4 & lstatus==3	//retired trumps other reasons
recode	nlfreason (.=5) if inlist(rsn_ntavail,5,6,7) & lstatus==3
	  
* occup = 1 digit occupational classification, primary job (7-day ref period)
g occup = .

* occup_orig = Original occupational classification, primary job (7-day ref period)
g occup_orig = .

* ocusec = Sector of activity, primary job (7-day ref period)
recode mwrk_orgtype (1=1) (2=3) (3/6=2) (*=.), g(ocusec)

* paid_leave = Eligible for paid leave, primary job (7-day ref period)
recode mwrk_pdannlve mwrk_pdsicklve (3=.)
egen paid_leave = rowmin(mwrk_pdannlve mwrk_pdsicklve)
recode paid_leave (2=0)

* pensions = Eligible for pension, primary job (7-day ref period)
g pensions = .

* socialsec = Social security (7-day ref period)
recode mwrk_soc_secu (1=1) (2=0) (*=.), g(socialsec)

* unempldur_l = Unemployment duration (months) lower bracket (7-day ref period)
recode seek_dur (1=0) (2=1) (3=3) (4=6) (5=12) (6=24) (*=.) if lstatus==2, g(unempldur_l)

* unempldur_u = Unemployment duration (months) upper bracket (7-day ref period)
recode seek_dur (1=1) (2=3) (3=6) (4=12) (5=24) (*=.) if lstatus==2, g(unempldur_u)

* union = Union membership (7-day ref period)
g union = .

* unitwage = Time unit of last wages payment, primary job (7-day ref period)
recode prd_remu (1=1) (2=2) (3=5) (4/5=10) (*=.) if lstatus==1 & empstat<=4, g(unitwage)
note unitwage: For NPL_2018_NLFS, this question was only asked for employees and paid apprentices/interns.

* wage_nc = Wage payment, primary job, excl. bonuses, etc. (7-day ref period)
g		wage_nc = amt_cashrs if lstatus==1 & empstat<=4
note wage_nc: For NPL_2018_NLFS, this question was only asked for employees and paid apprentices/interns.

* wage_nc_week = Wage payment adjusted to 1 week, primary job, excl. bonuses, etc. (7-day ref period)
g		wage_nc_week = amt_cashrs*5 if prd_remu==1 & lstatus==1 & empstat<=4
replace	wage_nc_week = amt_cashrs if prd_remu==2 & lstatus==1 & empstat<=4
replace	wage_nc_week = amt_cashrs/4.3 if prd_remu==3 & lstatus==1 & empstat<=4
note wage_nc_week: For NPL_2018_NLFS, this question was only asked for employees and paid apprentices/interns.

* wage_total = Annualized total wage, primary job (7-day ref period)
g wage_total = .
note wage_total: For NPL_2018_NLFS: In addition to wages, this should include bonuses, in-kind, compensation, etc. Relevant non-wage income questions are asked in F03-F06, but those questions do not have a time period attached, so can't be annualized as required by this variable. We left this variable missing for now.

* whours = Hours of work in last week main activity
g whours = usulhr_mwrk if lstatus==1

* wmonths = Months worked in the last 12 months main activity
g wmonths = .

* empldur_orig_2 = Original employment duration/tenure, second job (7-day ref period)
g empldur_orig_2 = ""

* empstat_2 = Employment status, secondary job (7-day ref period)
recode swrk_status (1=1) (2 5/6=5) (3=3) (4=4) (*=.) if lstatus==1, g(empstat_2)

* firmsize_l_2 = Firm size (lower bracket), secondary job (7-day ref period)
g firmsize_l_2 = .

* firmsize_u_2 = Firm size (upper bracket), secondary job (7-day ref period)
g firmsize_u_2 = .

* industry_orig_2 = Original industry code, secondary job (7-day ref period)
g industry_orig_2 = string(swrk_nsco4) if lstatus==1

* industrycat10_2 = 1 digit industry classification, secondary job (7-day ref period)
g		industrycat10_2 = floor(swrk_nsco4/100) if lstatus==1
recode	industrycat10_2 (1/3=1) (4/9=2) (10/33=3) (35/39=4) (41/43=5) (45/47 55/56=6) (49/53 58/63 79=7) (64/68 83=8) (84=9) (69/78 80/82 85/99=10) (*=.)

* industrycat4_2 = 4-category industry classification, secondary job (7-day ref period)
recode industrycat10_2 (1=1) (2/5=2) (6/9=3) (10=4), g(industrycat4_2)

* occup_2 = 1 digit occupational classification, secondary job (7-day ref period)
g occup_2 = .

* occup_orig_2 = Original occupational classification, secondary job (7-day ref period)
g occup_orig_2 = ""

* ocusec_2 = Sector of activity, secondary job (7-day ref period)
g ocusec_2 = .

* paid_leave_2 = Eligible for paid leave, secondary job (7-day ref period)
g paid_leave_2 = .

* pensions_2 = Eligible for pension, secondary job (7-day ref period)
g pensions_2 = .

* unitwage_2 = Time unit of last wages payment, secondary job (7-day ref period)
g unitwage_2 = .

* unitwage_o = Time unit of last wages payment, other jobs (7-day ref period)
g unitwage_o = .

* wage_nc_2 = Wage payment, secondary job, excl. bonuses, etc. (7-day ref period)
g wage_nc_2 = .

* wage_nc_o = Wage payment, other jobs, excl. bonuses, etc. (7-day ref period)
g wage_nc_o = .

* wage_nc_week_2 = Wage payment adjusted to 1 week, secondary job, excl. bonuses, etc. (7-day ref period)
g wage_nc_week_2 = .

* wage_nc_week_o = Wage payment adjusted to 1 week, other jobs, excl. bonuses, etc. (7-day ref period)
g wage_nc_week_o = .

* wage_total_2 = Annualized total wage, secondary job (7-day ref period)
g wage_total_2 = .

* wage_total_o = Annualized total wage, other job (7-day ref period)
g wage_total_o = .

* whours_2 = Hours of work in last week for the secondary job
g whours_2 = usulhr_swrk

* whours_o = Hours of work in last week for other jobs
g whours_o = usulhr_twrk

* wmonths_2 = Months worked in the last 12 months for the secondary job
g wmonths_2 = .

* wmonths_o = Months worked in the last 12 months for the others jobs
g wmonths_o = .

* wmore = would you like to work more 
g wmore = want_wrkmorehr

* wlong = how long have you been working in the current employment
g wlong = mwrk_tenure_envlv

* variables we cannot create:
* contract_year = Contract (12-mon ref period)
* empldur_orig_2_year = Original employment duration/tenure, second job (12-mon ref period)
* empldur_orig_year = Original employment duration/tenure, primary job (12-mon ref period)
* empstat_2_year = Employment status, secondary job (12-mon ref period)
* empstat_year = Employment status, primary job (12-mon ref period)
* firmsize_l_2_year = Firm size (lower bracket), secondary job (12-mon ref period)
* firmsize_l_year = Firm size (lower bracket), primary job (12-mon ref period)
* firmsize_u_2_year = Firm size (upper bracket), secondary job (12-mon ref period)
* firmsize_u_year = Firm size (upper bracket), primary job (12-mon ref period)
* healthins_year = Health insurance (12-mon ref period)
* industry_orig_2_year = Original industry code, secondary job (12-mon ref period)
* industry_orig_year = Original industry code, primary job (12-mon ref period)
* industrycat10_2_year = 1 digit industry classification, secondary job (12-mon ref period)
* industrycat10_year = 1 digit industry classification, primary job (12-mon ref period)
* industrycat4_2_year = 4-category industry classification, secondary job (12-mon ref period)
* industrycat4_year = 4-category industry classification, primary job (12-mon ref period)
* minlaborage_year = Labor module application age (12-mon ref period)
* nlfreason_year = Reason not in the labor force (12-mon ref period)
* occup_2_year = 1 digit occupational classification, secondary job (12-mon ref period)
* occup_orig_2_year = Original occupational classification, secondary job (12-mon ref period)
* occup_orig_year = Original occupational classification, primary job (12-mon ref period)
* occup_year = 1 digit occupational classification, primary job (12-mon ref period)
* ocusec_2_year = Sector of activity, secondary job (12-mon ref period)
* ocusec_year = Sector of activity, primary job (12-mon ref period)
* paid_leave_2_year = Eligible for paid leave, secondary job (12-mon ref period)
* paid_leave_year = Eligible for paid leave, primary job (12-mon ref period)
* pensions_2_year = Eligible for pension, secondary job (12-mon ref period)
* pensions_year = Eligible for pension, primary job (12-mon ref period)
* socialsec_year = Social security (12-mon ref period)
* lstatus_year = Labor status (12-mon ref period)
* unempldur_l_year = Unemployment duration (months) lower bracket (12-mon ref period)
* unempldur_u_year = Unemployment duration (months) upper bracket (12-mon ref period)
* union_year = Union membership (12-mon ref period)
foreach unavailable_var in  contract_year empldur_orig_2_year empldur_orig_year empstat_2_year empstat_year firmsize_l_2_year firmsize_l_year firmsize_u_2_year firmsize_u_year healthins_year	///
industry_orig_2_year industry_orig_year industrycat10_2_year industrycat10_year industrycat4_2_year industrycat4_year minlaborage_year nlfreason_year occup_2_year occup_orig_2_year ///
occup_orig_year occup_year ocusec_2_year ocusec_year paid_leave_2_year paid_leave_year pensions_2_year pensions_year socialsec_year lstatus_year unempldur_l_year unempldur_u_year union_year {
	g `unavailable_var' = .
}

* label all SARLD harmonized variables and values
do "${rootlabels}/label_SARLAB_variables.do"
save "${output}/`surveyfolder'_v`vm'_M_v`va'_A_`type'_TMP", replace
keep ${keepharmonized}
* save harmonized data
save "${output}/`surveyfolder'_v`vm'_M_v`va'_A_`type'_IND", replace
