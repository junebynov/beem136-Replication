

clear 
set more off

*pull in data

insheet using bz_oecd_data.csv

**************************************************
* Data Transformations
**************************************************
/*formatting date to convert string into date for Stata*/
/*gen ydate = yearly(year, "y")
format ydate %t
*/

//Setting up Panel Data in STATA
xtset country_id year


gen lrgdp= log(ngdp_y/cpi_index) 
gen lrgdppc= log(ngdp_y/cpi_index/pop_y) /*make real and per capita*/ 
gen growth_lrgdppc= lrgdppc-L.lrgdppc

gen lcpi= log(cpi_index)
gen infl = (lcpi-L.lcpi)*4

gen eld_pop = epop			/* elderly population share*/
gen unemp= uemp_y
gen lf_marginal = lf_55to64


* number of lags
local MaxLPLags 1

/*Major reforms with no lags*/

gen pennolag = major_nodelay

/*Putting in both country and time fixed effects*/

foreach var in growth_lrgdppc infl uemp_y oecd_rec ///
 pen_oldage lf_marginal epop{
gen pnolag_`var'=.
}

foreach var in  growth_lrgdppc infl uemp_y oecd_rec ///
 pen_oldage lf_marginal epop{
 
quietly xtreg pennolag  L.pennolag L(1/`MaxLPLags').`var'  i.year,  fe cluster(country_id)

if `MaxLPLags' == 1{
test (L.`var' = 0) 
}

replace pnolag_`var' = r(p)
}

/*Major reforms with lags*/

gen penlag = major_delay

/*Putting in both country and time fixed effects*/

foreach var in growth_lrgdppc infl uemp_y oecd_rec ///
 pen_oldage lf_marginal epop{
gen plag_`var'=.
}

foreach var in  growth_lrgdppc infl uemp_y oecd_rec ///
 pen_oldage lf_marginal epop{
 
quietly xtreg penlag  L.penlag L(1/`MaxLPLags').`var'  i.year,  fe cluster(country_id)

if `MaxLPLags' == 1{
test (L.`var' = 0) 
}

replace plag_`var' = r(p)
}


