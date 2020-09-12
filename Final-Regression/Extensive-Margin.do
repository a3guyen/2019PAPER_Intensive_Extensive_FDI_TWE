clear
cd "........."
set matsize 11000

capture log close
log using Extenstive-margin, replace


use DATA, clear
global allcountryvar lgdp_s lgdp_h  tech_s  delta_h   remote_s  remote_h startup_h phi_h
global pairvar bit pta  currency ldist  border  language colonizer colony legal religion 
global countryfe idsdummy* idhdummy*
global timefe timedummy*

display "$S_TIME  $S_DATE"
*================================TABLW 2==========================================
*====================================GLOBAL - FDI STOCK================================
eststo clear
capture erase EXTENSIVE-short.rtf
capture erase EXTENSIVE.rtf
capture erase EXTENSIVE.tex
capture erase EXTENSIVE-short.tex

*========================(1) Pool Probit MLE
probit invest $allcountryvar $pairvar  $timefe, cluster(idp) nolog
* APE:
margins, dydx(*) post 
eststo MPool

*========================(2) RE probit, MLE
xtprobit invest $allcountryvar $pairvar  $timefe, vce(cluster idp) nolog 
margins, dydx(*) post
eststo MREprob

*========================(3) Chamberlain's CRE probit
xtprobit invest $allcountryvar $pairvar M*  $timefe, vce(cluster idp) nolog 

margins, dydx(*) post
eststo marCRE



*====================================GLOBAL - FDI FLOW================================


*========================(4) Pool Probit MLE
probit investflow $allcountryvar $pairvar  $timefe, cluster(idp) nolog
* APE:
margins, dydx(*) post 
eststo MPool1

*========================(5) RE probit, MLE
xtprobit investflow $allcountryvar $pairvar  $timefe,  vce(cluster idp) nolog 
margins, dydx(*) post
eststo MREprob1

*========================(6) Chamberlain's CRE probit
xtprobit investflow $allcountryvar $pairvar M*  $timefe,  vce(cluster idp) nolog 
margins, dydx(*) post
eststo marCRE1


esttab using EXTENSIVE.rtf, star(* 0.1 ** 0.05 *** 0.01) stats (N r2 ar2 pr2 aic bic ll_0 ll chi2 rho) ///
se(3) b(3) nodepvars drop ( *dummy*) noomitted nogaps title(GLOBAL EXTENSIVE RESULTS) compress append 

esttab using EXTENSIVE-short.rtf, star(* 0.1 ** 0.05 *** 0.01) stats (N r2 ar2 pr2 aic bic ll_0 ll chi2 rho) ///
not  b(3) nodepvars drop ( *dummy*) noomitted nogaps title(GLOBAL EXTENSIVE RESULTS) compress append 


esttab using EXTENSIVE.tex, star(* 0.1 ** 0.05 *** 0.01) stats (N r2 ar2 pr2 aic bic ll_0 ll chi2 rho) ///
se(3) b(3) nodepvars drop ( *dummy*) noomitted nogaps title(GLOBAL EXTENSIVE RESULTS) compress append 

esttab using EXTENSIVE-short.tex, star(* 0.1 ** 0.05 *** 0.01) stats (N r2 ar2 pr2 aic bic ll_0 ll chi2 rho) ///
not  b(3) nodepvars drop ( *dummy*) noomitted nogaps title(GLOBAL EXTENSIVE RESULTS) compress append 

display "$S_TIME  $S_DATE"

log close

exit, clear
