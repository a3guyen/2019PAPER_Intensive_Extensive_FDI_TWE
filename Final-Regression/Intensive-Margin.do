clear
cd "..."
set matsize 11000

capture log close
log using Intenstive-margin, replace

use DATA, clear



global allcountryvar lgdp_s lgdp_h  tech_s  delta_h   remote_s  remote_h startup_h phi_h
global pairvar bit pta  currency ldist  border  language colonizer colony legal religion 
global exclusion lgdp_s lgdp_h  tech_s delta_h remote_s remote_h phi_h $pairvar
global timefe timedummy*
global allvar $allcountryvar $pairvar  lstock lflow invest investflow time source host CountryName*

*==============================TESTING FOR SELECTION BIAS -Wooldrige, 1995 ========================================
*TESTING WITH FLOWs

gen lambda =.
forvalues i = 2004(1)2012 {
	*di "Year=" `i'
    qui probit investflow $allcountryvar $pairvar if time == `i' , cluster(idp)
    qui predict xb, xb
    qui replace lambda=normalden(xb)/normal(xb) if  time == `i' & investflow ==1
    qui drop xb
}

bysort idpair: egen ST = total(investflow) 

local X $exclusion lflow lambda
foreach x of local X {
qui gen S1`x' = `x'*investflow
bysort idpair: egen S2`x' = total(S1`x') 
qui gen S3`x' = `x' - S2`x'/ST
}
qui rename S3lflow SSSflow

reg SSSflow S3* $timefe, cluster(idp)
test S3lambda =0 //p-value = 0.6610 => cannot reject Ho of no selection bias


*TESTING WITH STOCKS
use DATA, clear
gen lambda =.
forvalues i = 2004(1)2012 {
	*di "Year=" `i'
    qui probit invest $allcountryvar $pairvar if time == `i' , cluster(idp)
    qui predict xb, xb
    qui replace lambda=normalden(xb)/normal(xb) if  time == `i' & invest ==1
    qui drop xb
}

bysort idpair: egen ST = total(invest) 

local X $exclusion lstock lambda
foreach x of local X {
qui gen S1`x' = `x'*invest
bysort idpair: egen S2`x' = total(S1`x') 
qui gen S3`x' = `x' - S2`x'/ST
}
qui rename S3lstock SSSstock

reg SSSstock S3* $timefe, cluster(idp)
test S3lambda =0 //p-value = 0.9109


*===================================TESTING FOR THE PRESENCE OF UNOBSERVED EFFECTS, Wooldrige 2010, 299-300======================================================
use DATA, clear

*STOCKS
qui reg lstock  $allcountryvar $pairvar ,  cluster(idp)
qui predict uh, resid
sort idpair time
qui gen uh_1 = uh[_n-1] 
reg uh uh_1
test uh_1 =0
reg uh uh_1, cluster(idp)

gen uhsq = uh*uh
reg uhsq $timefe  

drop uh*

*FLOWS 
qui reg lflow $allcountryvar $pairvar ,  cluster(idp)
qui predict uh, resid
sort idpair time
gen uh_1 = uh[_n-1] 
reg uh uh_1
test uh_1 =0
reg uh uh_1, cluster(idp)

gen uhsq = uh*uh
reg uhsq $timefe  



*===================================MAIN REGRESSION RESULTS====================================
use DATA, clear
eststo clear

*Chosing RE vs FE 
qui xtreg lstock $allcountryvar $pairvar $timefe, fe 
eststo FE
testparm $timefe 
xttest3 //p=0.000 
qui xtreg lstock $allcountryvar $pairvar $timefe  
eststo RE
hausman FE RE, sigmamore 

*Chosing RE vs FE 
qui xtreg lflow $allcountryvar $pairvar $timefe, fe 
eststo FE
testparm $timefe 
xttest3 
qui xtreg lflow $allcountryvar $pairvar $timefe  
eststo RE
hausman FE RE, sigmamore 



* POLS
qui xtreg lstock $allcountryvar $pairvar $timefe , pa robust 
*RE
qui xtreg lstock $allcountryvar $pairvar $timefe, cluster(idp) 
*RE or POLS:
xttest0 

*=========================================Table 3: Global results===================================================
use DATA, clear
*Generate time-varying dummies
egen htime = group(host time)
tab htime, gen(dhtime)
egen stime = group(source time)
tab stime, gen(dstime)
global dummies dhtime* dstime*





eststo clear
*===========================STOCKS
*FE
xtreg lstock $allcountryvar $pairvar $timefe , fe cluster(idp) 
eststo FE

*CRE
xtreg lstock $allcountryvar $pairvar $timefe  M*,  cluster(idp) 
eststo CMRE
*Heckit
heckman lstock $exclusion  $timefe, sel( invest = $allcountryvar $pairvar $timefe ) cluster(idp)
eststo Heckit
*PPML
ppml stock $allcountryvar $pairvar $timefe, cluster(idp) 
eststo PPMLnoFE
*PPML with FE
ppml stock  $pairvar $dummies, cluster(idp) 
eststo PPMLwFE

*============================FLOWS
xtreg lflow $allcountryvar $pairvar $timefe , fe cluster(idp) 
eststo FE1
*CRE
xtreg lflow $allcountryvar $pairvar $timefe  M*,  cluster(idp) 
eststo CMRE1
*Heckit
heckman lflow $exclusion $timefe, sel( investflow = $allcountryvar $pairvar $timefe ) cluster(idp)
eststo Heckit1
*PPML
ppml flow $allcountryvar $pairvar $timefe, cluster(idp) 
eststo PPMLnoFE1

*PPML with FE
ppml flow  $pairvar $dummies, cluster(idp) 
eststo PPMLwFE1



capture erase INTENSIVE.rtf
capture erase INTENSIVE-short.rtf
capture erase INTENSIVE.tex 
capture erase INTENSIVE-short.tex

esttab using INTENSIVE.rtf, star(* 0.1 ** 0.05 *** 0.01) stats (N r2 ll_0 ll rho) ///
se(3) b(3) nodepvars drop ( M* *dummy*) noomitted nogaps  title(GLOBAL INTENSIVE RESULTS) compress append

esttab using INTENSIVE-short.rtf, star(* 0.1 ** 0.05 *** 0.01) stats (N r2 ll_0 ll rho) ///
not  b(3) nodepvars drop ( M* *dummy*) noomitted nogaps title(GLOBAL INTENSIVE RESULTS) compress append

esttab using INTENSIVE.tex, star(* 0.1 ** 0.05 *** 0.01) stats (N r2 ll_0 ll rho) ///
se(3) b(3) nodepvars drop ( M* *dummy*) noomitted nogaps title(GLOBAL INTENSIVE RESULTS) compress append 

esttab using INTENSIVE-short.tex, star(* 0.1 ** 0.05 *** 0.01) stats (N r2 ll_0 ll rho) ///
not  b(3) nodepvars drop ( M* *dummy*) noomitted nogaps  title(GLOBAL INTENSIVE RESULTS) compress append

*======================================Table A6- Country Groups- Stocks===============================================================
use DATA, clear
eststo clear
***DCS to DCs

*FE
xtreg lstock $allcountryvar $pairvar $timefe if (income_s== "H" & income_h =="H"), fe cluster(idp) 
eststo FE
*CMRE
xtreg lstock $allcountryvar $pairvar $timefe  M* if (income_s== "H" & income_h =="H"), cluster(idp) 
eststo CMRE



***DCs to LDCs 
*FE
xtreg lstock $allcountryvar $pairvar $timefe if (income_s== "H" & income_h !="H"), fe cluster(idp) 
eststo FE1
*CMRE
xtreg lstock $allcountryvar $pairvar $timefe  M* if (income_s== "H" & income_h !="H"),  cluster(idp) 
eststo CMRE1

***LDCs to DCs

*FE
xtreg lstock $allcountryvar $pairvar $timefe if (income_s != "H" & income_h =="H"), fe cluster(idp) 
eststo FE2
*CMRE
xtreg lstock $allcountryvar $pairvar $timefe  M* if (income_s != "H" & income_h =="H"),  cluster(idp) 
eststo CMRE2

***LDCs to LDCs

*FE
xtreg lstock $allcountryvar $pairvar $timefe if (income_s != "H" & income_h !="H"), fe cluster(idp) 
eststo FE3
*CMRE
xtreg lstock $allcountryvar $pairvar $timefe  M* if (income_s != "H" & income_h !="H"), cluster(idp) 
eststo CMRE3



esttab using INTENSIVE.rtf, star(* 0.1 ** 0.05 *** 0.01) stats (N r2 ll_0 ll rho) ///
se(3) b(3) nodepvars drop ( M* *dummy*) noomitted nogaps  title(STOCK INTENSIVE RESULTS) compress append

esttab using INTENSIVE-short.rtf, star(* 0.1 ** 0.05 *** 0.01) stats (N r2 ll_0 ll rho) ///
not  b(3) nodepvars drop ( M* *dummy*) noomitted nogaps title(STOCK  INTENSIVE RESULTS) compress append

esttab using INTENSIVE.tex, star(* 0.1 ** 0.05 *** 0.01) stats (N r2 ll_0 ll rho) ///
se(3) b(3) nodepvars drop ( M* *dummy*) noomitted nogaps title(STOCK  INTENSIVE RESULTS) compress append 

esttab using INTENSIVE-short.tex, star(* 0.1 ** 0.05 *** 0.01) stats (N r2 ll_0 ll rho) ///
not  b(3) nodepvars drop ( M* *dummy*) noomitted nogaps  title(STOCK  INTENSIVE RESULTS) compress append



*======================================Table A7- Country Groups- FLows===============================================================
use DATA, clear
eststo clear
***DCS to DCs




*FE
xtreg lflow $allcountryvar $pairvar $timefe if (income_s== "H" & income_h =="H"), fe cluster(idp) 
eststo FE
*CMRE
xtreg lflow $allcountryvar $pairvar $timefe  M* if (income_s== "H" & income_h =="H"), cluster(idp) 
eststo CMRE



***DCs to LDCs 
*FE
xtreg lflow $allcountryvar $pairvar $timefe if (income_s== "H" & income_h !="H"), fe cluster(idp) 
eststo FE1
*CMRE
xtreg lflow $allcountryvar $pairvar $timefe  M* if (income_s== "H" & income_h !="H"),  cluster(idp) 
eststo CMRE1

***LDCs to DCs

*FE
xtreg lflow $allcountryvar $pairvar $timefe if (income_s != "H" & income_h =="H"), fe cluster(idp) 
eststo FE2
*CMRE
xtreg lflow $allcountryvar $pairvar $timefe  M* if (income_s != "H" & income_h =="H"),  cluster(idp) 
eststo CMRE2

***LDCs to LDCs

*FE
xtreg lflow $allcountryvar $pairvar $timefe if (income_s != "H" & income_h !="H"), fe cluster(idp) 
eststo FE3
*CMRE
xtreg lflow $allcountryvar $pairvar $timefe  M* if (income_s != "H" & income_h !="H"), cluster(idp) 
eststo CMRE3



esttab using INTENSIVE.rtf, star(* 0.1 ** 0.05 *** 0.01) stats (N r2 ll_0 ll rho) ///
se(3) b(3) nodepvars drop ( M* *dummy*) noomitted nogaps  title(FLOW INTENSIVE RESULTS) compress append

esttab using INTENSIVE-short.rtf, star(* 0.1 ** 0.05 *** 0.01) stats (N r2 ll_0 ll rho) ///
not  b(3) nodepvars drop ( M* *dummy*) noomitted nogaps title(FLOW INTENSIVE RESULTS) compress append

esttab using INTENSIVE.tex, star(* 0.1 ** 0.05 *** 0.01) stats (N r2 ll_0 ll rho) ///
se(3) b(3) nodepvars drop ( M* *dummy*) noomitted nogaps title(FLOW INTENSIVE RESULTS) compress append 

esttab using INTENSIVE-short.tex, star(* 0.1 ** 0.05 *** 0.01) stats (N r2 ll_0 ll rho) ///
not  b(3) nodepvars drop ( M* *dummy*) noomitted nogaps  title(FLOW INTENSIVE RESULTS) compress append















log close
exit, clear
