
cd "..."
capture log close
log using FDI-Data-inspection, text replace 


*=====================Table A1: Examples of Inconsistent Mirror-Origin FDI Flows (million $)===================

*inconsistent mirror inflows
use FDIdata, clear
keep if sourceif == "mirror"
gen dif1 = abs(unof - unif) 
sum dif1
count if dif1 !=0 & !missing(dif1) //49
drop if dif1 < 100
browse time host source unif sourceif unof  sourceof dif1 if dif1 != 0 & !missing(dif1)
* inconsistent mirror outflows
use FDIdata, clear
keep if sourceof == "mirror"
sort time host source 
gen dif1 = abs(unif - unof)
sum dif1
count if dif1 !=0 & !missing(dif1) //97
drop if dif1 <100
browse time host source unif sourceif unof  sourceof dif1 if dif1 != 0 & !missing(dif1)
* inconsistent mirror outstock
use FDIdata, clear
keep if sourceos == "mirror"
sort time host source 
gen dif1 = abs(unos - unis)
sum dif1
count if dif1 !=0 & !missing(dif1) //117
drop if dif1 <500
browse time host source  unis  sourceis unos sourceos dif1 if dif1 != 0 & !missing(dif1)

* inconsistent mirror instock
use FDIdata, clear
keep if sourceis == "mirror"
sort time host source 
gen dif1 = abs(unos - unis)
sum dif1
count if dif1 !=0 & !missing(dif1) //100
drop if dif1 <500
browse time host source  unis  sourceis unos sourceos  dif1 if dif1 != 0 & !missing(dif1)


*===================Table A2: Correlations and Differences between Data Series =================

use FDIdata, clear
* Get rid of mirror data from UNTACD
replace unif =. if sourceif == "mirror"
replace unof =. if sourceof == "mirror"
replace unis = . if sourceis == "mirror"
replace unos =. if sourceos == "mirror"

** Correlation between series

corr unif unof  //0.475
corr unis unos //0.795
corr oeif oeof  //0.409
corr oeis oeos //0.7752
corr oeis unis //0.9944
corr oeos unos //0.9925
corr oeif unif //0.9760
corr oeof unof // 0.9730

** Compare
gen delunflow = abs(unif - unof)
gen delunstock = abs(unis - unos)
gen deloeflow = abs(oeif - oeof)
gen deloestock = abs(oeis - oeos)

sum del*
browse host source time unif unof delunflow if delunflow > 100000 & !missing(delunflow)
browse host source time oeif unif oeof unof if source == "LUX" & host == "BEL" & time == 2008
browse host source time unis unos delunstock oeis oeos deloestock  if (delunstock > 300000 & !missing(delunstock))| (deloestock > 300000 & !missing(deloestock))
browse host source time oeis unis oeos unos if source == "USA" & host == "NLD" & time > 2009

*================= Table A3: Observations in UNCTAD Database (million $) ============


use FDIdata, clear
* Get rid of mirror data from UNTACD
replace unif =. if sourceif == "mirror"
replace unof =. if sourceof == "mirror"
replace unis = . if sourceis == "mirror"
replace unos =. if sourceos == "mirror"

sum unif unof unis unos

*=================== Inward or Outward? ===========================================
use FDIdata, clear
keep if host == "ARE" 
sort host source time
browse host source time unif sourceif unof sourceof 
keep if sourceif == "origin"
unique source // 10 countries reported by ARE as source country
vallist source

use FDIdata, clear
keep if host == "ARE" 
sort host source time
browse host source time unif sourceif unof sourceof 
keep if sourceof == "origin"
unique source // 35 countries reported sending outflow to ARE
vallist source



**** =============Creating STOCK and FLOW variables with the highest number of positive observations
gen stock = unis //1st preference to inward data
replace stock = unos if (missing(unis) | unis <=0) 

replace stock = 0 if missing(stock) | stock <0

gen flow = unif
replace flow = unof if (missing(unif)  | unif <=0 ) 
replace flow = 0 if missing(flow) | flow <0

