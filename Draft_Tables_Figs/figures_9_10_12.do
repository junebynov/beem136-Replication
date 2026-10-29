clear 
set more off

*pull in data
insheet using bz_oecd_data.csv

/*GENERATING FIGURE 9*/

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

gen credib =0
replace credib =1 if country_id==10 | country_id==5 | country_id==4 | country_id==1 | country_id==2 /*NZ, Finland, Denmark, Australia, Belgium*/

/* 15 years of implementation lags*/
gen penref= -(major_delay_long)  /*blue*/
gen penref_n = -major_nodelay     /*red*/
gen penref_nn = -(major_delay_short)   /*green*/


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

}

* controls in LP regression
local rhscontrols l.eld_pop l.life_expectancy 

			
****************************************************************
*** Baseline LP regressions
****************************************************************
foreach var in lpen lf_marginal {
  
* One regression for each horizon of the response 
	forvalues i=0/`horizon' {	
		
		xtreg `var'`i' penref  penref_n penref_nn i.year L(1/`MaxLPLags').`var' L(1/`MaxLPLags').penref L(1/`MaxLPLags').penref_n L(1/`MaxLPLags').penref_nn `rhscontrols',  fe cluster(country_id) 
	
	
		replace b_`var' = _b[penref] if _n == `i'+1
		replace se_`var'= _se[penref] if _n == `i'+1
		replace b_`var'n = _b[penref_n] if _n == `i'+1
		replace se_`var'n = _se[penref_n] if _n == `i'+1
		replace b_`var'nn = _b[penref_nn] if _n == `i'+1
		replace se_`var'nn = _se[penref_nn] if _n == `i'+1
	
	}
}
	
****************************************************************
*** Baseline LP graphs
****************************************************************
gen Years = _n-1 if _n <= `horizon' +1

* zero line
gen zero = 0 if _n <= `horizon' +1

***** create confidence bands ****
	scalar sig1 = 0.3	 // specify significance level
	
foreach var in lpen lf_marginal {
  
   gen up_`var' = b_`var' + invnormal(1-sig1/2)*se_`var' if _n <= (`horizon' + 1)
   gen dn_`var' = b_`var' - invnormal(1-sig1/2)*se_`var' if _n <= (`horizon' + 1)
   gen up_`var'n = b_`var'n + invnormal(1-sig1/2)*se_`var'n if _n <= (`horizon' + 1)
   gen dn_`var'n = b_`var'n - invnormal(1-sig1/2)*se_`var'n if _n <= (`horizon' + 1)
   gen up_`var'nn = b_`var'nn + invnormal(1-sig1/2)*se_`var'nn if _n <= (`horizon' + 1)
   gen dn_`var'nn = b_`var'nn - invnormal(1-sig1/2)*se_`var'nn if _n <= (`horizon' + 1)
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
	(line b_lpennn Years, lcolor(green) ///
	lpattern(shortdash) lwidth(thick)) /// 
	(line up_lpennn Years, lcolor(green) ///
	lpattern(shortdash) lwidth(thin)) /// 
	(line dn_lpennn Years, lcolor(green) ///
	lpattern(shortdash) lwidth(thin)) ///
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
	(line b_lf_marginalnn Years, lcolor(green) ///
	lpattern(shortdash) lwidth(thick)) /// 
	(line up_lf_marginalnn Years, lcolor(green) ///
	lpattern(shortdash) lwidth(thin)) /// 
	(line dn_lf_marginalnn Years, lcolor(green) ///
	lpattern(shortdash) lwidth(thin)) ///
	(line zero Years, lcolor(black)), ///
	title("LFPR - 55 to 64", color(black) size(medium)) ///
	ytitle("Percentage pts.", size(medsmall)) xtitle("Year", size(medsmall)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(off) name(unemp_lp, replace) nodraw
	graph save  lf_marginal_LP.gph , replace
	
	
	graph combine lf_marginal_LP.gph lpen_LP.gph, col(2) row(1) iscale(0.8) ysize(2) xsize(4)
	graph save figure9.gph, replace
	graph export figure9.pdf, replace
	

		
	graph drop _all
	cd ..
	
/**************************************************************************************/

/*GENERATING FIGURE 10*/

****************************************************************************************

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

gen credib =0
replace credib =1 if country_id==10 | country_id==5 | country_id==4 | country_id==1 | country_id==2 /*NZ, Finland, Denmark, Australia, Belgium*/


gen penref= -(major_delay_age+major_delay_contribution) /*blue*/
gen penref_n = -major_nodelay                      /*red*/
gen penref_nn = -(major_delay_other)               /*green*/



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

}

* controls in LP regression
local rhscontrols l.eld_pop l.life_expectancy 

			
****************************************************************
*** Baseline LP regressions
****************************************************************
foreach var in lpen lf_marginal {
  
* One regression for each horizon of the response 
	forvalues i=0/`horizon' {	
		
		xtreg `var'`i' penref  penref_n penref_nn i.year L(1/`MaxLPLags').`var' L(1/`MaxLPLags').penref L(1/`MaxLPLags').penref_n L(1/`MaxLPLags').penref_nn `rhscontrols',  fe cluster(country_id) 
	
	
		replace b_`var' = _b[penref] if _n == `i'+1
		replace se_`var'= _se[penref] if _n == `i'+1
		replace b_`var'n = _b[penref_n] if _n == `i'+1
		replace se_`var'n = _se[penref_n] if _n == `i'+1
		replace b_`var'nn = _b[penref_nn] if _n == `i'+1
		replace se_`var'nn = _se[penref_nn] if _n == `i'+1
	
	}
}
	
****************************************************************
*** Baseline LP graphs
****************************************************************
gen Years = _n-1 if _n <= `horizon' +1

* zero line
gen zero = 0 if _n <= `horizon' +1

***** create confidence bands ****
	scalar sig1 = 0.3	 // specify significance level
	
foreach var in lpen lf_marginal {
  
   gen up_`var' = b_`var' + invnormal(1-sig1/2)*se_`var' if _n <= (`horizon' + 1)
   gen dn_`var' = b_`var' - invnormal(1-sig1/2)*se_`var' if _n <= (`horizon' + 1)
   gen up_`var'n = b_`var'n + invnormal(1-sig1/2)*se_`var'n if _n <= (`horizon' + 1)
   gen dn_`var'n = b_`var'n - invnormal(1-sig1/2)*se_`var'n if _n <= (`horizon' + 1)
   gen up_`var'nn = b_`var'nn + invnormal(1-sig1/2)*se_`var'nn if _n <= (`horizon' + 1)
   gen dn_`var'nn = b_`var'nn - invnormal(1-sig1/2)*se_`var'nn if _n <= (`horizon' + 1)
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
	(line b_lpennn Years, lcolor(green) ///
	lpattern(shortdash) lwidth(thick)) /// 
	(line up_lpennn Years, lcolor(green) ///
	lpattern(shortdash) lwidth(thin)) /// 
	(line dn_lpennn Years, lcolor(green) ///
	lpattern(shortdash) lwidth(thin)) ///
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
	(line b_lf_marginalnn Years, lcolor(green) ///
	lpattern(shortdash) lwidth(thick)) /// 
	(line up_lf_marginalnn Years, lcolor(green) ///
	lpattern(shortdash) lwidth(thin)) /// 
	(line dn_lf_marginalnn Years, lcolor(green) ///
	lpattern(shortdash) lwidth(thin)) ///
	(line zero Years, lcolor(black)), ///
	title("LFPR - 55 to 64", color(black) size(medium)) ///
	ytitle("Percentage pts.", size(medsmall)) xtitle("Year", size(medsmall)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(off) name(unemp_lp, replace) nodraw
	graph save  lf_marginal_LP.gph , replace
	
	
	graph combine lf_marginal_LP.gph lpen_LP.gph, col(2) row(1) iscale(0.8) ysize(2) xsize(4)
	graph save figure10.gph, replace
	graph export figure10.pdf, replace
	

		
	graph drop _all
	cd ..
	
		


/**************************************************************************************/

/*GENERATING FIGURE 12*/

****************************************************************************************

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

gen credib =0
replace credib =1 if country_id==10 | country_id==5 | country_id==4 | country_id==1 | country_id==2 /*NZ, Finland, Denmark, Australia, Belgium*/

gen penref= - (major_delay) * (1-credib) /*blue*/
gen penref_n = -major_nodelay   /*red*/
gen penref_nn = -(major_delay)* credib /*green*/


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

}

* controls in LP regression
local rhscontrols l.eld_pop l.life_expectancy 

			
****************************************************************
*** Baseline LP regressions
****************************************************************
foreach var in lpen lf_marginal {
  
* One regression for each horizon of the response 
	forvalues i=0/`horizon' {	
		
		xtreg `var'`i' penref  penref_n penref_nn i.year L(1/`MaxLPLags').`var' L(1/`MaxLPLags').penref L(1/`MaxLPLags').penref_n L(1/`MaxLPLags').penref_nn `rhscontrols',  fe cluster(country_id) 
	
	
		replace b_`var' = _b[penref] if _n == `i'+1
		replace se_`var'= _se[penref] if _n == `i'+1
		replace b_`var'n = _b[penref_n] if _n == `i'+1
		replace se_`var'n = _se[penref_n] if _n == `i'+1
		replace b_`var'nn = _b[penref_nn] if _n == `i'+1
		replace se_`var'nn = _se[penref_nn] if _n == `i'+1
	
	}
}
	
****************************************************************
*** Baseline LP graphs
****************************************************************
gen Years = _n-1 if _n <= `horizon' +1

* zero line
gen zero = 0 if _n <= `horizon' +1

***** create confidence bands ****
	scalar sig1 = 0.3	 // specify significance level
	
foreach var in lpen lf_marginal {
  
   gen up_`var' = b_`var' + invnormal(1-sig1/2)*se_`var' if _n <= (`horizon' + 1)
   gen dn_`var' = b_`var' - invnormal(1-sig1/2)*se_`var' if _n <= (`horizon' + 1)
   gen up_`var'n = b_`var'n + invnormal(1-sig1/2)*se_`var'n if _n <= (`horizon' + 1)
   gen dn_`var'n = b_`var'n - invnormal(1-sig1/2)*se_`var'n if _n <= (`horizon' + 1)
   gen up_`var'nn = b_`var'nn + invnormal(1-sig1/2)*se_`var'nn if _n <= (`horizon' + 1)
   gen dn_`var'nn = b_`var'nn - invnormal(1-sig1/2)*se_`var'nn if _n <= (`horizon' + 1)
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
	(line b_lpennn Years, lcolor(green) ///
	lpattern(shortdash) lwidth(thick)) /// 
	(line up_lpennn Years, lcolor(green) ///
	lpattern(shortdash) lwidth(thin)) /// 
	(line dn_lpennn Years, lcolor(green) ///
	lpattern(shortdash) lwidth(thin)) ///
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
	(line b_lf_marginalnn Years, lcolor(green) ///
	lpattern(shortdash) lwidth(thick)) /// 
	(line up_lf_marginalnn Years, lcolor(green) ///
	lpattern(shortdash) lwidth(thin)) /// 
	(line dn_lf_marginalnn Years, lcolor(green) ///
	lpattern(shortdash) lwidth(thin)) ///
	(line zero Years, lcolor(black)), ///
	title("LFPR - 55 to 64", color(black) size(medium)) ///
	ytitle("Percentage pts.", size(medsmall)) xtitle("Year", size(medsmall)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(off) name(unemp_lp, replace) nodraw
	graph save  lf_marginal_LP.gph , replace
	
	
	graph combine lf_marginal_LP.gph lpen_LP.gph, col(2) row(1) iscale(0.8) ysize(2) xsize(4)
	graph save figure12.gph, replace
	graph export figure12.pdf, replace
	

		
	graph drop _all
	cd ..
	
		
