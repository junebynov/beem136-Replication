clear 
set more off

**********************************************************************
/*FIGURE 15a   */
**********************************************************************

*pull in data
insheet using bz_oecd_data.csv

*******************************************************
/* OPTIONS to INPUT */
*******************************************************

local samplestart = 1978 /*set the start date for sample period here*/

* number of lags
local MaxLPLags 2

* horizon
local horizon 10

**************************************************
* Data Transformations
**************************************************
/*formatting date to convert string into date for Stata*/
/*gen ydate = yearly(year, "y")
format ydate %t
*/

//Setting up Panel Data in STATA
xtset country_id year

/*Consider sample period here*/

drop if year < `samplestart'  /* in order to consider subsample*/



gen lrgdp= log(ngdp_y/cpi_index/pop_y) /*make real and per capita*/ 
gen growth_lrgdp= lrgdp-L.lrgdp
gen fc = -fiscal_consol
gen lrgov= log(gov_y/cpi_index/pop_y) /*make real and per capita*/
gen growth_lrgov= lrgov-L.lrgov
gen ltaxrev= log(taxrev*ngdp_y)
gen growth_ltaxrev = ltaxrev - L.ltaxrev
	

bys country: egen groupmeangdpgrowth= pctile(growth_lrgdp), p(50)
gen gdpgrowth_ind = growth_lrgdp <  groupmeangdpgrowth 
replace gdpgrowth_ind = . if growth_lrgdp == . 
sort country_id year

* choice of shock

*baseline
gen penref= -(major_delay)
gen penref_n = -(major_nodelay)



*******************************************************
/* CONSTRUCTING DATA */
*******************************************************
gen lpen = log(pen_oldage/100 * ngdp_y/ cpi_index)
gen eld_pop = epop			/* elderly population share*/
gen lf_marginal = lf_55to64

gen t = _n

*******************
** Set-up of LPs **
*******************

***** LHS variable: the response variable

forvalues i=0/`horizon'  {
	gen lpen`i'   =  (f`i'.lpen - l.lpen)*100 
	gen lf_marginal`i'	   = f`i'.lf_marginal
	
}


***** variables to store the impulse response (vector of betas from the LP regressions) and standard errors

foreach var in lpen lf_marginal {

gen b_`var'=.
gen se_`var'=.
gen b_`var'n=.
gen se_`var'n=.
gen b_`var'nn=.
gen se_`var'nn=.
gen bgdp_`var'=.
gen bgdp_`var'n=.
gen boecd_`var'=.
gen boecd_`var'n=.
}


* controls in LP regression

local rhscontrols l.eld_pop  l.life_expectancy 

local rhscontrolsgdp l.eld_pop l.life_expectancy l.growth_lrgdp 

local rhscontrolsoecd l.eld_pop l.life_expectancy l.oecd_rec

					
****************************************************************
*** Baseline LP regressions
****************************************************************
foreach var in lpen lf_marginal {
  
* One regression for each horizon of the response 
	forvalues i=0/`horizon' {	
		
		xtreg `var'`i' penref  penref_n  i.year L(1/`MaxLPLags').`var' L(1/`MaxLPLags').penref L(1/`MaxLPLags').penref_n `rhscontrols',  fe cluster(country_id) 
	
		replace b_`var' = _b[penref] if _n == `i'+1
		replace se_`var'= _se[penref] if _n == `i'+1
		replace b_`var'n = _b[penref_n] if _n == `i'+1
		replace se_`var'n = _se[penref_n] if _n == `i'+1
			
	}
	
	
* One regression for each horizon of the response 
	forvalues i=0/`horizon' {	
		
		xtreg `var'`i' penref  penref_n  i.year L(1/`MaxLPLags').`var' L(1/`MaxLPLags').penref L(1/`MaxLPLags').penref_n `rhscontrolsgdp',  fe cluster(country_id) 
	
		replace bgdp_`var' = _b[penref] if _n == `i'+1
		replace bgdp_`var'n = _b[penref_n] if _n == `i'+1
		
			
	}
	
	
	forvalues i=0/`horizon' {	
		
		xtreg `var'`i' penref  penref_n  i.year L(1/`MaxLPLags').`var' L(1/`MaxLPLags').penref L(1/`MaxLPLags').penref_n `rhscontrolsoecd',  fe cluster(country_id) 
	
		replace boecd_`var' = _b[penref] if _n == `i'+1
		replace boecd_`var'n = _b[penref_n] if _n == `i'+1
		
			
	}
	
}
  
****************************************************************
*** Baseline LP graphs
****************************************************************


gen Years = _n-1 if _n <= `horizon' +1

* zero line
gen zero = 0 if _n <= `horizon' +1

***** create confidence bands (in this case 90 and 95%) ****
	scalar sig1 = 0.3	 // specify significance level
	
foreach var in lpen lf_marginal {
  
   gen up_`var' = b_`var' + invnormal(1-sig1/2)*se_`var' if _n <= (`horizon' + 1)
   gen dn_`var' = b_`var' - invnormal(1-sig1/2)*se_`var' if _n <= (`horizon' + 1)
   gen up_`var'n = b_`var'n + invnormal(1-sig1/2)*se_`var'n if _n <= (`horizon' + 1)
   gen dn_`var'n = b_`var'n - invnormal(1-sig1/2)*se_`var'n if _n <= (`horizon' + 1)
}
  
  
cd ./graphs
 

twoway (rarea up_lpen dn_lpen  Years, ///
	fcolor(gs12) lcolor(white) lpattern(solid)) ///
	(line b_lpen Years, lcolor(blue) ///
	lpattern(solid) lwidth(thick)) /// 
	(line b_lpenn Years, lcolor(red) ///
	lpattern(dash) lwidth(thick)) /// 
	(line up_lpenn Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line dn_lpenn Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) ///
	(line bgdp_lpen Years, lcolor(black) ///
	lpattern(solid) lwidth(thin)) ///
	(line bgdp_lpenn Years, lcolor(black) ///
	lpattern(solid) lwidth(thin)) ///
	(line boecd_lpen Years, lcolor(black) ///
	lpattern(shortdash_dot) lwidth(thin)) ///
	(line boecd_lpenn Years, lcolor(black) ///
	lpattern(shortdash_dot) lwidth(thin)) ///
	(line zero Years, lcolor(black)), ///
	title("Pension Spending", color(black) size(medium)) ///
	ytitle("Percent", size(medsmall)) xtitle("Year", size(medsmall)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(off) name(unemp_lp, replace) nodraw
	graph save  lpen_LP.gph , replace
	

	twoway (rarea up_lf_marginal dn_lf_marginal  Years, ///
	fcolor(gs12) lcolor(white) lpattern(solid)) ///
	(line b_lf_marginal Years, lcolor(blue) ///
	lpattern(solid) lwidth(thick)) /// 
	(line b_lf_marginaln Years, lcolor(red) ///
	lpattern(dash) lwidth(thick)) /// 
	(line up_lf_marginaln Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line dn_lf_marginaln Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line bgdp_lf_marginal Years, lcolor(black) ///
	lpattern(solid) lwidth(thin)) ///
	(line bgdp_lf_marginaln Years, lcolor(black) ///
	lpattern(solid) lwidth(thin)) ///
	(line boecd_lf_marginal Years, lcolor(black) ///
	lpattern(shortdash_dot) lwidth(thin)) ///
	(line boecd_lf_marginaln Years, lcolor(black) ///
	lpattern(shortdash_dot) lwidth(thin)) ///
	(line zero Years, lcolor(black)), ///
	title("LFPR - 55 to 64", color(black) size(medium)) ///
	ytitle("Percentage pts.", size(medsmall)) xtitle("Year", size(medsmall)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(off) name(unemp_lp, replace) nodraw
	graph save  lf_marginal_LP.gph , replace
	
		
	graph combine lf_marginal_LP.gph lpen_LP.gph, col(2) row(1) iscale(0.8) ysize(2) xsize(4)
	graph save figure15a.gph, replace
	graph export figure15a.pdf, replace
	
		
	graph drop _all
	cd ..
	



**********************************************************************
/*FIGURE 15b   */
**********************************************************************

clear 
set more off

*pull in data
insheet using bz_oecd_data.csv

*******************************************************
/* OPTIONS to INPUT */
*******************************************************

local samplestart = 1978 /*set the start date for sample period here*/

* number of lags
local MaxLPLags 2

* horizon
local horizon 10

**************************************************
* Data Transformations
**************************************************
/*formatting date to convert string into date for Stata*/
/*gen ydate = yearly(year, "y")
format ydate %t
*/

//Setting up Panel Data in STATA
xtset country_id year

/*Consider sample period here*/

drop if year < `samplestart'  /* in order to consider subsample*/



gen lrgdp= log(ngdp_y/cpi_index/pop_y) /*make real and per capita*/ 
gen growth_lrgdp= lrgdp-L.lrgdp
gen fc = -fiscal_consol
gen lrgov= log(gov_y/cpi_index/pop_y) /*make real and per capita*/
gen growth_lrgov= lrgov-L.lrgov
gen ltaxrev= log(taxrev*ngdp_y)
gen growth_ltaxrev = ltaxrev - L.ltaxrev
	

bys country: egen groupmeangdpgrowth= pctile(growth_lrgdp), p(50)
gen gdpgrowth_ind = growth_lrgdp <  groupmeangdpgrowth 
replace gdpgrowth_ind = . if growth_lrgdp == . 
sort country_id year

* choice of shock

*baseline
gen penref= -(major_delay)
gen penref_n = -(major_nodelay)



*******************************************************
/* CONSTRUCTING DATA */
*******************************************************
gen lpen = log(pen_oldage/100 * ngdp_y/ cpi_index)
gen eld_pop = epop			/* elderly population share*/
gen lf_marginal = lf_55to64

gen t = _n

*******************
** Set-up of LPs **
*******************

***** LHS variable: the response variable

forvalues i=0/`horizon'  {
	gen lpen`i'   =  (f`i'.lpen - l.lpen)*100 
	gen lf_marginal`i'	   = f`i'.lf_marginal
	
}


***** variables to store the impulse response (vector of betas from the LP regressions) and standard errors

foreach var in lpen lf_marginal {

gen b_`var'=.
gen se_`var'=.
gen b_`var'n=.
gen se_`var'n=.
gen b_`var'nn=.
gen se_`var'nn=.
gen bfc_`var'=.
gen bfc_`var'n=.
gen bfcp_`var'=.
gen bfcp_`var'n=.
gen blab_`var'=.
gen blab_`var'n=.
}


* controls in LP regression
gen labref = imf_labref_epl + imf_labref_ui

local rhscontrols l.eld_pop  l.life_expectancy 

local rhscontrolsfc l.eld_pop  l.life_expectancy l.fc 

local rhscontrolsfcplus l.eld_pop l.life_expectancy l.growth_lrgov l.growth_ltaxrev l.fc

local rhscontrolslab l.eld_pop l.life_expectancy l.labref


					
****************************************************************
*** Baseline LP regressions
****************************************************************
foreach var in lpen lf_marginal {
  
* One regression for each horizon of the response 
	forvalues i=0/`horizon' {	
		
		xtreg `var'`i' penref  penref_n  i.year L(1/`MaxLPLags').`var' L(1/`MaxLPLags').penref L(1/`MaxLPLags').penref_n `rhscontrols',  fe cluster(country_id) 
	
		replace b_`var' = _b[penref] if _n == `i'+1
		replace se_`var'= _se[penref] if _n == `i'+1
		replace b_`var'n = _b[penref_n] if _n == `i'+1
		replace se_`var'n = _se[penref_n] if _n == `i'+1
			
	}
	
	
* One regression for each horizon of the response 
	forvalues i=0/`horizon' {	
		
		xtreg `var'`i' penref  penref_n  i.year L(1/`MaxLPLags').`var' L(1/`MaxLPLags').penref L(1/`MaxLPLags').penref_n `rhscontrolsfc',  fe cluster(country_id) 
	
		replace bfc_`var' = _b[penref] if _n == `i'+1
		replace bfc_`var'n = _b[penref_n] if _n == `i'+1
		
			
	}
	
	forvalues i=0/`horizon' {	
		
		xtreg `var'`i' penref  penref_n  i.year L(1/`MaxLPLags').`var' L(1/`MaxLPLags').penref L(1/`MaxLPLags').penref_n `rhscontrolsfcplus',  fe cluster(country_id) 
	
		replace bfcp_`var' = _b[penref] if _n == `i'+1
		replace bfcp_`var'n = _b[penref_n] if _n == `i'+1
		
			
	}
	
	
	forvalues i=0/`horizon' {	
		
		xtreg `var'`i' penref  penref_n  i.year L(1/`MaxLPLags').`var' L(1/`MaxLPLags').penref L(1/`MaxLPLags').penref_n `rhscontrolslab',  fe cluster(country_id) 
	
		replace blab_`var' = _b[penref] if _n == `i'+1
		replace blab_`var'n = _b[penref_n] if _n == `i'+1
		
			
	}
	
}
  
****************************************************************
*** Baseline LP graphs
****************************************************************


gen Years = _n-1 if _n <= `horizon' +1

* zero line
gen zero = 0 if _n <= `horizon' +1

***** create confidence bands (in this case 90 and 95%) ****
	scalar sig1 = 0.3	 // specify significance level
	
foreach var in lpen lf_marginal {
  
   gen up_`var' = b_`var' + invnormal(1-sig1/2)*se_`var' if _n <= (`horizon' + 1)
   gen dn_`var' = b_`var' - invnormal(1-sig1/2)*se_`var' if _n <= (`horizon' + 1)
   gen up_`var'n = b_`var'n + invnormal(1-sig1/2)*se_`var'n if _n <= (`horizon' + 1)
   gen dn_`var'n = b_`var'n - invnormal(1-sig1/2)*se_`var'n if _n <= (`horizon' + 1)
}
  
  
cd ./graphs
 

twoway (rarea up_lpen dn_lpen  Years, ///
	fcolor(gs12) lcolor(white) lpattern(solid)) ///
	(line b_lpen Years, lcolor(blue) ///
	lpattern(solid) lwidth(thick)) /// 
	(line b_lpenn Years, lcolor(red) ///
	lpattern(dash) lwidth(thick)) /// 
	(line up_lpenn Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line dn_lpenn Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) ///
	(line bfc_lpen Years, lcolor(black) ///
	lpattern(solid) lwidth(thin)) ///
	(line bfc_lpenn Years, lcolor(black) ///
	lpattern(solid) lwidth(thin)) ///
	(line bfcp_lpen Years, lcolor(black) ///
	 lpattern(shortdash_dot) lwidth(thin)) ///
	(line bfcp_lpenn Years, lcolor(black) ///
	lpattern(shortdash_dot) lwidth(thin)) ///
	(line blab_lpen Years, lcolor(black) ///
	lpattern(dash)  lwidth(thin)) ///
	(line blab_lpenn Years, lcolor(black) ///
	lpattern(dash) lwidth(thin)) ///
	(line zero Years, lcolor(black)), ///
	title("Pension Spending", color(black) size(medium)) ///
	ytitle("Percent", size(medsmall)) xtitle("Year", size(medsmall)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(off) name(unemp_lp, replace) nodraw
	graph save  lpen_LP.gph , replace
	

	twoway (rarea up_lf_marginal dn_lf_marginal  Years, ///
	fcolor(gs12) lcolor(white) lpattern(solid)) ///
	(line b_lf_marginal Years, lcolor(blue) ///
	lpattern(solid) lwidth(thick)) /// 
	(line b_lf_marginaln Years, lcolor(red) ///
	lpattern(dash) lwidth(thick)) /// 
	(line up_lf_marginaln Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line dn_lf_marginaln Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line bfc_lf_marginal Years, lcolor(black) ///
	lpattern(solid) lwidth(thin)) ///
	(line bfc_lf_marginaln Years, lcolor(black) ///
	lpattern(solid) lwidth(thin)) ///
	(line bfcp_lf_marginal Years, lcolor(black) ///
	lpattern(shortdash_dot) lwidth(thin)) ///
	(line bfcp_lf_marginaln Years, lcolor(black) ///
	lpattern(shortdash_dot) lwidth(thin)) ///
	(line blab_lf_marginal Years, lcolor(black) ///
	lpattern(dash) lwidth(thin)) ///
	(line blab_lf_marginaln Years, lcolor(black) ///
	lpattern(dash) lwidth(thin)) ///
	(line zero Years, lcolor(black)), ///
	title("LFPR - 55 to 64", color(black) size(medium)) ///
	ytitle("Percentage pts.", size(medsmall)) xtitle("Year", size(medsmall)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(off) name(unemp_lp, replace) nodraw
	graph save  lf_marginal_LP.gph , replace
	
		
	graph combine lf_marginal_LP.gph lpen_LP.gph, col(2) row(1) iscale(0.8) ysize(2) xsize(4)
	graph save figure15b.gph, replace
	graph export figure15b.pdf, replace
	
		
	graph drop _all
	cd ..
	

