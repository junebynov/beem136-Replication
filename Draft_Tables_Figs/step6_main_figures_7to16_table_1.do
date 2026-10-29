
/*
Replication code for figures and tables in 
"Public Pension Reforms and Retirement Decisions: Narrative Evidence and Aggregate Implications"

October, 2022

** This file produces table 1, figure 7 -16 in the paper. 
** The figures are also stored with the corresponding name in the subfolder called graphs.
*/

clear 
set more off

* generate figures 7-8
do figures_7_8.do

* generate figures 9, 10, 12
do figures_9_10_12.do

* generate figures 11 and 13
do figures_11_13.do

* generate figure 15
do figure_15.do

* generate figure 14 and 16
do figures_14_16.do

* generate table 1
do table_1.do