/*
Extension: Sample Period Sensitivity Analysis
Bi and Zubairy (2023), Figure 7

Baseline:
    Code sample start (samplestart): 1978
    Regression period: 1980–2017

Extension:
    Code sample start (samplestart): 1990
    Regression period: 1992–2017

All other specifications remain unchanged:
    Local Projections, controls, two lags,
    and a 10-year horizon.

Replicated and extended by June
*/

clear all
set more off

* ## Use my reconstructed dataset
cd "/Users/june/Replication_BEEM136/output/02_data_preparation"

* pull in data
insheet using bz_oecd_data.csv

* ##add: Check the dataset structure
describe

* ##add: Count the observations
count

* ##add: Display the first five observations
list in 1/5

*******************************************************
/* OPTIONS to INPUT */
*******************************************************

* ##modified: Change sample start year for sensitivity analysis
local samplestart = 1990

local sample_end = 0 /* =1 drop obs after 2013*/

* number of lags
local MaxLPLags 2

* horizon
local horizon 10

**************************************************
* Data Transformations
**************************************************

*Setting up Panel Data in STATA
xtset country_id year

* ##add: Check lagged and future values
gen lf_lag1 = L.lf
gen lf_lead1 = F.lf

* ##add: Compare current, past, and future LFPR
list country_id year lf lf_lag1 lf_lead1 in 1/10

/*Consider sample period here*/

drop if year < `samplestart'  /* in order to consider subsample*/
if `sample_end' ==1{
        drop if year >2013
}

gen lrgdp= log(ngdp_y/cpi_index/pop_y) /*make real and per capita*/ 
gen growth_lrgdp= lrgdp-L.lrgdp

* ##add: Check the sample period after dropping observations
summarize year

* ##add: Check GDP variables
summarize lrgdp growth_lrgdp

* ##add: Display GDP and growth for the first ten observations
list country_id year lrgdp growth_lrgdp in 1/10

bys country: egen groupmeangdpgrowth= pctile(growth_lrgdp), p(50)
gen gdpgrowth_ind = growth_lrgdp < groupmeangdpgrowth
replace gdpgrowth_ind = . if growth_lrgdp == .
sort country_id year

* choice of shock

*baseline
gen penref= -(major_delay)
gen penref_n = -(major_nodelay)

* ##add: Check GDP growth indicator
tabulate gdpgrowth_ind, missing

* ##add: Check pension reform shocks
tabulate major_delay penref, missing
tabulate major_nodelay penref_n, missing

* ##add: Summary statistics for reform shocks
summarize penref penref_n

*******************************************************
/* CONSTRUCTING DATA */
*******************************************************

gen lcpi= log(cpi_index)
gen infl = (lcpi-L.lcpi)*4
gen lpop= log(pop_y)
gen gr_pop = lpop- L.lpop
gen lrgov= log(gov_y/cpi_index/pop_y) /*make real and per capita*/
gen growth_lrgov= lrgov-L.lrgov
gen lpen = log(pen_oldage/100 * ngdp_y/ cpi_index)
gen growth_lpen  =  lpen - L.lpen
gen def_y =-(gov_y/ngdp_y -taxrev)
gen eld_pop = epop			/* elderly population share*/
gen fc = -fiscal_consol

gen ltaxrev= log(taxrev*ngdp_y)
gen growth_ltaxrev = ltaxrev - L.ltaxrev

* ##add: Check pension spending variables
summarize pen_oldage lpen growth_lpen

* ##add: Check demographic variables
summarize eld_pop life_expectancy

* ##add: Compare pension spending measures
list country_id year pen_oldage lpen growth_lpen in 1/10

gen lf_fif = lf_55to59
gen lf_six = lf_60to64
gen pens = pen_oldage
gen lf_marginal = lf_55to64
gen lf_young = lf_20to49		/* LFPR for 20 to 49, composed by Louis*/

gen lf_f_marginal = lfw_5564
gen lf_m_marginal = lfm_5564
gen lf_f_fif = lfw_5559
gen lf_m_fif = lfm_5559
gen lf_f_six = lfw_6064
gen lf_m_six = lfm_6064


gen t = _n

* ##add: Check labour force participation variables
summarize lf lf_young lf_fif lf_six lf_marginal

* ##add: Compare male and female LFPR
summarize lf_f_marginal lf_m_marginal

*******************
** Set-up of LPs **
*******************

***** LHS variable: the response variable

forvalues i=0/`horizon'  {
	gen lf`i'	   = f`i'.lf /*labor force participation rate*/
	gen lf_fif`i'	   = f`i'.lf_fif
	gen lf_young`i' = f`i'.lf_young
	gen pens`i'   =  f`i'.pens
	gen lf_six`i'	   = f`i'.lf_six
	gen lpen`i'   =  (f`i'.lpen - l.lpen)*100 /*f`i'.pen_oldage*/
	gen lf_marginal`i'	   = f`i'.lf_marginal
	gen lf_f_marginal`i'	   = f`i'.lf_f_marginal
	gen lf_m_marginal`i'	   = f`i'.lf_m_marginal
	gen lf_f_fif`i'	   = f`i'.lf_f_fif
	gen lf_m_fif`i'	   = f`i'.lf_m_fif

	
}


***** variables to store the impulse response (vector of betas from the LP regressions) and standard errors

foreach var in lf lf_fif lf_six lf_young ///
pens lpen lf_marginal lf_f_marginal lf_m_marginal lf_f_fif ///
lf_m_fif  {

gen b_`var'=.
gen se_`var'=.
gen b_`var'n=.
gen se_`var'n=.

}


* controls in LP regression

local rhscontrols l.eld_pop  l.life_expectancy 


					
****************************************************************
*** Baseline LP regressions
****************************************************************
foreach var in lf lf_fif lf_six lf_young ///
pens lpen lf_marginal lf_f_marginal lf_m_marginal lf_f_fif ///
lf_m_fif {
  
* One regression for each horizon of the response 
	forvalues i=0/`horizon' {	
	
		if `var'== lpen{
		xtreg `var'`i' penref  penref_n i.year  L(1/`MaxLPLags').lpen L(1/`MaxLPLags').penref L(1/`MaxLPLags').penref_n `rhscontrols',  fe cluster(country_id) 
	}
		if `var'== lrgdp{
		xtreg `var'`i' penref  penref_n i.year  L(1/`MaxLPLags').lrgdp L(1/`MaxLPLags').penref L(1/`MaxLPLags').penref_n `rhscontrols',  fe cluster(country_id) 
	}
	else{
		
		xtreg `var'`i' penref  penref_n i.year L(1/`MaxLPLags').`var' L(1/`MaxLPLags').penref L(1/`MaxLPLags').penref_n `rhscontrols',  fe cluster(country_id) 
		}
	 
	
		replace b_`var' = _b[penref] if _n == `i'+1
		replace se_`var'= _se[penref] if _n == `i'+1
		replace b_`var'n = _b[penref_n] if _n == `i'+1
		replace se_`var'n = _se[penref_n] if _n == `i'+1
	}
}

	

****************************************************************
*** Baseline LP graphs
****************************************************************


gen Years = _n-1 if _n <= `horizon' +1

* zero line
gen zero = 0 if _n <= `horizon' +1

***** create confidence bands  ****
	scalar sig1 = 0.3	 // specify significance level
	
foreach var in lf lf_fif lf_six lf_young ///
pens lpen lf_marginal lf_f_marginal lf_m_marginal lf_f_fif ///
lf_m_fif {
  
   gen up_`var' = b_`var' + invnormal(1-sig1/2)*se_`var' if _n <= (`horizon' + 1)
   gen dn_`var' = b_`var' - invnormal(1-sig1/2)*se_`var' if _n <= (`horizon' + 1)
   gen up_`var'n = b_`var'n + invnormal(1-sig1/2)*se_`var'n if _n <= (`horizon' + 1)
   gen dn_`var'n = b_`var'n - invnormal(1-sig1/2)*se_`var'n if _n <= (`horizon' + 1)
}
  
* ##modified: Save extension graphs separately
cd "/Users/june/Replication_BEEM136/output/04_extension_1990"

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
	(line zero Years, lcolor(black)), ///
	title("Pension Spending", color(black) size(medium)) ///
	ytitle("Percent", size(medsmall)) xtitle("Year", size(medsmall)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(off) name(unemp_lp, replace) nodraw
	graph save  lpen_LP.gph , replace
	
	
twoway (rarea up_pens dn_pens  Years, ///
	fcolor(gs12) lcolor(white) lpattern(solid)) ///
	(line b_pens Years, lcolor(blue) ///
	lpattern(solid) lwidth(thick)) /// 
	(line b_pensn Years, lcolor(red) ///
	lpattern(dash) lwidth(thick)) /// 
	(line up_pensn Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line dn_pensn Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) ///
	(line zero Years, lcolor(black)), ///
	title("Pension Spending/GDP", color(black) size(medium)) ///
	ytitle("Percent", size(medsmall)) xtitle("Year", size(medsmall)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(off) name(unemp_lp, replace) nodraw
	graph save  pens_LP.gph , replace

	
	twoway (rarea up_lf dn_lf  Years, ///
	fcolor(gs12) lcolor(white) lpattern(solid)) ///
	(line b_lf Years, lcolor(blue) ///
	lpattern(solid) lwidth(thick)) /// 
	(line b_lfn Years, lcolor(red) ///
	lpattern(dash) lwidth(thick)) /// 
	(line up_lfn Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line dn_lfn Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line zero Years, lcolor(black)), ///
	title("LFPR", color(black) size(medium)) ///
	ytitle("Percentage pts.", size(medsmall)) xtitle("Year", size(medsmall)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(off) name(unemp_lp, replace) nodraw
	graph save  lf_LP.gph , replace
	
	twoway (rarea up_lf_young dn_lf_young  Years, ///
	fcolor(gs12) lcolor(white) lpattern(solid)) ///
	(line b_lf_young Years, lcolor(blue) ///
	lpattern(solid) lwidth(thick)) /// 
	(line b_lf_youngn Years, lcolor(red) ///
	lpattern(dash) lwidth(thick)) /// 
	(line up_lf_youngn Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line dn_lf_youngn Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line zero Years, lcolor(black)), ///
	title("LFPR - 20 to 49", color(black) size(medium)) ///
	ytitle("Percentage pts.", size(medsmall)) xtitle("Year", size(medsmall)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(off) name(unemp_lp, replace) nodraw
	graph save  lf_young_LP.gph , replace
	
	
	twoway (rarea up_lf_fif dn_lf_fif  Years, ///
	fcolor(gs12) lcolor(white) lpattern(solid)) ///
	(line b_lf_fif Years, lcolor(blue) ///
	lpattern(solid) lwidth(thick)) /// 
	(line b_lf_fifn Years, lcolor(red) ///
	lpattern(dash) lwidth(thick)) /// 
	(line up_lf_fifn Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line dn_lf_fifn Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line zero Years, lcolor(black)), ///
	title("LFPR - 55 to 59", color(black) size(medium)) ///
	ytitle("Percentage pts.", size(medsmall)) xtitle("Year", size(medsmall)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(off) name(unemp_lp, replace) nodraw
	graph save  lf_fif_LP.gph , replace
	
	twoway (rarea up_lf_m_fif dn_lf_m_fif  Years, ///
	fcolor(gs12) lcolor(white) lpattern(solid)) ///
	(line b_lf_m_fif Years, lcolor(blue) ///
	lpattern(solid) lwidth(thick)) /// 
	(line b_lf_m_fifn Years, lcolor(red) ///
	lpattern(dash) lwidth(thick)) /// 
	(line up_lf_m_fifn Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line dn_lf_m_fifn Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line zero Years, lcolor(black)), ///
	title("LFPR Male - 55 to 59", color(black) size(medium)) ///
	ytitle("Percentage pts.", size(medsmall)) xtitle("Year", size(medsmall)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(off) name(unemp_lp, replace) nodraw
	graph save  lf_m_fif_LP.gph , replace
	
	twoway (rarea up_lf_f_fif dn_lf_f_fif  Years, ///
	fcolor(gs12) lcolor(white) lpattern(solid)) ///
	(line b_lf_f_fif Years, lcolor(blue) ///
	lpattern(solid) lwidth(thick)) /// 
	(line b_lf_f_fifn Years, lcolor(red) ///
	lpattern(dash) lwidth(thick)) /// 
	(line up_lf_f_fifn Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line dn_lf_f_fifn Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line zero Years, lcolor(black)), ///
	title("LFPR Female - 55 to 59", color(black) size(medium)) ///
	ytitle("Percentage pts.", size(medsmall)) xtitle("Year", size(medsmall)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(off) name(unemp_lp, replace) nodraw
	graph save  lf_f_fif_LP.gph , replace
	
	
	twoway (rarea up_lf_six dn_lf_six  Years, ///
	fcolor(gs12) lcolor(white) lpattern(solid)) ///
	(line b_lf_six Years, lcolor(blue) ///
	lpattern(solid) lwidth(thick)) /// 
	(line b_lf_sixn Years, lcolor(red) ///
	lpattern(dash) lwidth(thick)) /// 
	(line up_lf_sixn Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line dn_lf_sixn Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line zero Years, lcolor(black)), ///
	title("LFPR - 60 to 64", color(black) size(medium)) ///
	ytitle("Percentage pts.", size(medsmall)) xtitle("Year", size(medsmall)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(off) name(unemp_lp, replace) nodraw
	graph save  lf_six_LP.gph , replace
	
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
	(line zero Years, lcolor(black)), ///
	title("LFPR - 55 to 64", color(black) size(medium)) ///
	ytitle("Percentage pts.", size(medsmall)) xtitle("Year", size(medsmall)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(off) name(unemp_lp, replace) nodraw
	graph save  lf_marginal_LP.gph , replace
	
	twoway (rarea up_lf_f_marginal dn_lf_f_marginal  Years, ///
	fcolor(gs12) lcolor(white) lpattern(solid)) ///
	(line b_lf_f_marginal Years, lcolor(blue) ///
	lpattern(solid) lwidth(thick)) /// 
	(line b_lf_f_marginaln Years, lcolor(red) ///
	lpattern(dash) lwidth(thick)) /// 
	(line up_lf_f_marginaln Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line dn_lf_f_marginaln Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line zero Years, lcolor(black)), ///
	title("LFPR Female - 55 to 64", color(black) size(medium)) ///
	ytitle("Percentage pts.", size(medsmall)) xtitle("Year", size(medsmall)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(off) name(unemp_lp, replace) nodraw
	graph save  lf_f_marginal_LP.gph , replace
	
	twoway (rarea up_lf_m_marginal dn_lf_m_marginal  Years, ///
	fcolor(gs12) lcolor(white) lpattern(solid)) ///
	(line b_lf_m_marginal Years, lcolor(blue) ///
	lpattern(solid) lwidth(thick)) /// 
	(line b_lf_m_marginaln Years, lcolor(red) ///
	lpattern(dash) lwidth(thick)) /// 
	(line up_lf_m_marginaln Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line dn_lf_m_marginaln Years, lcolor(red) ///
	lpattern(dash) lwidth(thin)) /// 
	(line zero Years, lcolor(black)), ///
	title("LFPR Male - 55 to 64", color(black) size(medium)) ///
	ytitle("Percentage pts.", size(medsmall)) xtitle("Year", size(medsmall)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(off) name(unemp_lp, replace) nodraw
	graph save  lf_m_marginal_LP.gph , replace
	

	
	* ##modified: Save Figure 7a with the extension sample year
	graph combine lf_fif_LP.gph lf_six_LP.gph lf_marginal_LP.gph lf_LP.gph lf_young_LP.gph, col(3) row(2) iscale(0.5) ysize(4) xsize(6)
	graph save figure7a_1990.gph, replace
	graph export figure7a_1990.pdf, replace

* ##modified: Save Figure 7b with the extension sample year
	graph combine lpen_LP.gph pens_LP.gph, col(2) row(1) iscale(0.8) ysize(3) xsize(6)
	graph save figure7b_1990.gph, replace
	graph export figure7b_1990.pdf, replace