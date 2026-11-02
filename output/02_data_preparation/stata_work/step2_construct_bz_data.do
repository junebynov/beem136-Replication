*==============================================================================
* This file constructs the data set used in the analysis for: 
* "Public Pension Reforms and Retirement Decision: Narrative Evidence and Aggregate Implications" by Bi and Zubairy
*==============================================================================
clear all
set more off

* ##add: Set the working directory for Step 2 replication
cd "/Users/june/Replication_BEEM136/output/02_data_preparation/stata_work"
cd ./raw_data

*==============================================================================
* Data(Annual) importing 
*==============================================================================
* country level variables
foreach var in lf epop taxrev oecd_rec life_expectancy fiscal_consol {
	import excel "`var'.xlsx", sheet(Sheet1) first clear
	drop if cty == "-"
	by cty TIME, sort: gen year = TIME
	format year %ty
	drop TIME
	rename (LOCATION) (code)
	replace cty = strtrim(cty)
	save `var', replace
}

* country reform dummy
cd ..
import delimited "Dummy.csv", clear
drop if countries == ""
rename (countries) (cty)
replace cty = "New Zealand"    if cty=="NZ"
replace cty = "United Kingdom" if cty=="UK"

drop v1
cd ./raw_data
save Dummy, replace

* country labor reform 
import excel "Reforms_dataset_Online_Appendix.xlsx", sheet(Labor market reforms) first clear
rename (country EPLregularworkers Unemploymentbenefitsoverall) (cty imf_labref_epl imf_labref_ui)
keep cty year imf_labref_epl imf_labref_ui
save Labor_reform, replace

*==============================================================================
* Labor force: by age group 20-49 (need to construct a population weighted measure)

import excel "lf_20to49.xlsx", sheet(Sheet1) first clear 
rename (Country Year) (cty year)
keep cty year LFP2024 LFP2529 LFP3034 LFP3539 LFP4044 LFP4549

foreach i of varlist LFP2024 LFP2529 LFP3034 LFP3539 LFP4044 LFP4549 {
	drop if `i' == ".."
}
destring year LFP*, replace
egen group = group(cty year)
reshape long LFP, i(group) j(age)
drop group
save previous_LFP, replace


local var "POP"
foreach i of local var {
	import delimited "age_`i'.csv", clear
	rename (countrycode country time value) (code cty year `i')

	sort cty year age
	order code cty year age `i'
	drop if age>10000

	by cty: egen min_yr  = min(year) if age == 4549
	by cty: egen min_yr2 = max(min_yr)
	drop if year<min_yr2 
	drop min_* 
	
	keep code cty year age `i'
	save age_`i', replace
}

use age_POP, clear
bys cty year: egen pop_sum = sum(POP)

merge 1:1 cty year age using previous_LFP, keep(3) nogen

bys cty year: g   pop_lfp = POP*LFP/pop_sum
bys cty year: egen lf_20to49 = sum(pop_lfp)
keep if age==2024 
keep code cty year lf_20to49 
save lfp_2049, replace

rm age_POP.dta
rm previous_LFP.dta 
*==============================================================================
* Merge 
*==============================================================================

foreach var in lf epop taxrev Dummy oecd_rec life_expectancy fiscal_consol {
	merge 1:1 cty year using `var'.dta, nogen 
	rm `var'.dta

}
sort cty year
drop if cty==""
save a_data, replace


*==============================================================================
* Data(Annual) importing (ver.2)
* Adding annual raw data, wdi data 
*==============================================================================
foreach var in ngdp_y cpi_index gov_y pop_y pen_oldage {
	import excel "`var'.xlsx", sheet(Sheet1) first clear
	reshape long _, i(cty) j(year) 
	rename _ `var'
	drop if cty==""
	save `var', replace
}

*==============================================================================
* Data reformatting for unemployment/ LFPR by age, gender 
*==============================================================================

* unemployment by gender 
import excel using "uemp_y.xlsx", sheet(Sheet1)first clear
replace cty = cty[_n-1] if missing(cty)
reshape wide _1960-_2017, i(cty) j(Sex) string
rename (_*Men _*Women _*all) (uemp_m_y* uemp_f_y* uemp_y*)
reshape long uemp_m_y uemp_f_y uemp_y, i(cty) j(year)
save uemp_y, replace

* lf & unemp. by age group 
local age_group = "55to59 60to64 64to69"
foreach x of local age_group {
	import excel using "lf_`x'.xlsx", sheet(Sheet1)first clear
	replace cty = cty[_n-1] if missing(cty)
	drop if lf_uemp =="emp"
	reshape wide _1960-_2017, i(cty) j(lf_uemp) string
	rename (_*lf _*uemp) (lf_`x'* uemp_`x'*)
	reshape long lf_`x' uemp_`x', i(cty) j(year)

	save lf_`x', replace 
}
import delimited "lf_55to64.csv", clear
rename (v2 country time value) (cty code year lf_55to64)
keep if series =="LFPR"
keep code cty year lf_55to64
drop if year>=2018
save lf_55to64, replace


*==============================================================================
* Data reformatting for unemployment/LFPR by age, gender 
*==============================================================================

* men 
local group  = "5559 5564 6064" 
foreach x of local group  {
	import excel using "men_`x'.xlsx", sheet(Sheet1) first clear
	replace cty = cty[_n-1] if missing(cty)
	drop if lf_uemp =="emp"
	reshape wide _1960-_2018, i(cty) j(lf_uemp) string
	rename (_*lf _*uemp) (lfm_`x'* uempm_`x'*)
	reshape long lfm_`x' uempm_`x', i(cty) j(year)
	save men_`x', replace 
}

* women 
local group  = "5559 5564 6064" 
foreach x of local group  {
	import excel using "women_`x'.xlsx", sheet(Sheet1) first clear
	replace cty = cty[_n-1] if missing(cty)
	drop if lf_uemp =="emp"
	reshape wide _1960-_2018, i(cty) j(lf_uemp) string
	rename (_*lf _*uemp) (lfw_`x'* uempw_`x'*)
	reshape long lfw_`x' uempw_`x', i(cty) j(year)
	save women_`x', replace 
}
*==============================================================================
* Merging annual data 
*==============================================================================
use a_data, clear
foreach var in ngdp_y cpi_index gov_y pop_y pen_oldage uemp_y ///
               lf_55to64 lf_55to59 lf_60to64 lfp_2049 lf_64to69 /// 
			   men_5559 women_5559 men_5564 women_5564 men_6064 women_6064 ///
			   Labor_reform  {			   
	merge m:1 cty year using `var'.dta, nogen
	rm `var'.dta
}
order ngdp_y cpi_index gov_y pop_y pen_oldage uemp_y lf ///
	  lf_55to59 lf_60to64 lf_64to69 lf_55to59 lf_60to64 lf_64to69 ///
	  lfm_5559 lfw_5559 lfm_5564 lfw_5564 lfm_6064 lfw_6064  ///
	  epop taxrev reform* major* fiscal* lf_55to64 lf_20to49 oecd_rec imf* ///
	  life_expectancy , after(year) 

keep if cty == "Australia" | cty == "Belgium"  ///
| cty == "Denmark" | cty == "Finland" | cty == "France" ///
| cty=="Italy" | cty == "Japan" ///
| cty == "New Zealand" | cty == "Spain" ///
| cty == "United Kingdom" 


g country_id =. 

replace country_id = 1 if cty=="Australia"
replace country_id = 2 if cty=="Belgium"
replace country_id = 4 if cty=="Denmark"
replace country_id = 5 if cty=="Finland"
replace country_id = 6 if cty=="France"
replace country_id = 8 if cty=="Italy"
replace country_id = 9 if cty=="Japan"
replace country_id =10 if cty=="New Zealand"
replace country_id =12 if cty=="Spain"
replace country_id =13 if cty=="United Kingdom"

replace code = "AUS" if cty=="Australia"
replace code = "BEL" if cty=="Belgium"
replace code = "DNK" if cty=="Denmark"
replace code = "ESP" if cty=="Spain"
replace code = "FIN" if cty=="Finland"
replace code = "FRA" if cty=="France"
replace code = "GBR" if cty=="United Kingdom"
replace code = "ITA" if cty=="Italy"
replace code = "JPN" if cty=="Japan"
replace code = "NZL" if cty=="New Zealand"

sort cty year 
drop if year>=2019 
drop BH uemp_m* uemp_f* uemp_55* uemp_6* uempm* uempw* 
order country_id*
save bz_oecd_data, replace
rm a_data.dta 

*==============================================================================
* Export
*==============================================================================
cd "/Users/june/Replication_BEEM136/output/02_data_preparation"
export delimited "bz_oecd_data.csv", replace



