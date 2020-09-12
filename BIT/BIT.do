cd "A:\AnhDropbox\01 PHD 2016\Data-main\STATA-Python-Bilateral-Treaties-2017"
capture log close
clear
log using BIT-inspection, text replace 
set max_memory 16g, permanently 
* Updated on 04 Jan 2020

*======================== Table A4: Descriptive Statistics on BITs from UNCTAD database===============
use BIT-origin, clear
tab Status
tab Typeoftermination
browse if missing(Dateofentryintoforce)

drop if missing(Dateofentryintoforce)

drop Shorttitle Typeofagreement  Titleofagreement  Files Amendmentprotocols Sideinstruments

*============================= Split strings to get country name in each BIT:
split Parties, p(;)
sort Parties1  Parties2
drop Parties
format %15s Parties1  Parties2


gen year_force1 = substr(Dateofentryintoforce, -4,.)
gen year_force =real(year_force1)
la var year_force "Year of entry into force"
gen year_ter1 = substr(Dateoftermination, -4,.)
gen year_ter = real(year_ter1)
la var year_ter "Year of termination"

drop Dateofsignature Dateofentryintoforce Dateoftermination year_ter1 year_force1 Status
drop if missing(year_force)
rename (Parties1  Parties2) (host source)
gen dum_force = 1
gen dum_ter =1 if !missing(year_ter)
replace host =strtrim(host)
replace source = strtrim(source)
save BIT1, replace

*Getting ISO codes
use BIT1, clear

rename host CountryName
replace CountryName = "Czech Republic" if CountryName == "Czechia"

merge m:1 CountryName using ISO3-CountryName-UNTACD // need to be all matched from master
browse if _merge ==1

drop if _merge ==2
drop _merge 
rename CountryCode host
rename CountryName CountryName_h



rename source CountryName
replace CountryName = "Czech Republic" if CountryName == "Czechia"
merge m:1 CountryName using ISO3-CountryName-UNTACD // need to be all matched from master
browse if _merge ==1

drop if _merge ==2
drop _merge 

rename CountryName CountryName_s
rename CountryCode source

/*
keep if host == "BLEU" | source == "BLEU"
export excel using "BLEU", firstrow(variables) replace //manually edit this file to get isocode for Belgium and Luxembourg seperately
import excel "BLEU-clean.xls", sheet("Sheet1") firstrow clear
save BLEU-clean, replace
*/

drop if strlen(source)!=3
drop if strlen(host)!=3

append using BLEU-clean

format %15s CountryName*
sort host source
egen id_p = group( host source)
save BIT2, replace
*=================================Getting long panel for year-force
use BIT2, clear
drop Type* *ter* Country*
rename dum_force force
reshape wide force, i(id_p) j(year_force)
reshape long force, i(id_p) j(time)
sort host source time
save force, replace
rename host source1
rename source host
rename source1 source
append using force
drop id_p
duplicates drop
save force, replace


*=================================Getting long panel for termination year
use BIT2, clear
replace dum_ter =12 if Typeoftermination == "Replaced by new treaty" // This is to know that this type of termination is 12, not 1
drop *force* Type* Country*
rename dum_ter ter
drop if missing(year_ter)
reshape wide ter, i(id_p) j(year_ter)
reshape long ter, i(id_p) j(time)
sort host source time
save ter, replace
rename host source1
rename source host
rename source1 source
append using ter
drop  id_p
duplicates drop
save ter, replace


*================================Creating a full square matrix with country pair and year and data on BIT
use force, clear
sum time // 1962-2019
unique time //57 but should be 58 => year 1970 is missing 

keep source
unique source //179 => Total obs = 179*178*58 = 1847996
duplicates drop

/*
import excel "NoBITcountries.xlsx", sheet("Sheet1") firstrow clear
save NoBITcountries, replace
*/
append using NoBITcountries
duplicates drop

gen host = source
gen time = _n
replace time = time + 1961
replace time =. if time >2019
fillin host source time
drop if missing(time)
drop if host == source
drop _fillin 
egen id_p = group( host source)

merge 1:1 host source time  using ter, keepusing(ter ) 
drop _merge
merge 1:1 host source time  using force, keepusing(force ) 
drop _merge


gen ter_origin = ter
count if ter==1 & force==1 // =0, just to make sure other types of termination do not have a new replacement in the same year
replace ter=. if (ter==12 & force==1)  // This is to drop termination year when there is a new BIt in the same year replaces the terminated one. 172 obs like this
bysort id_p: egen x = total(force)
unique id_p if x ==2 //also 178 => other types of termination do not have a replacement treaty


browse if ter==12 //There are 9 BITs that the termination year is not the same as the replacement year. 
browse
sort host source time 

bysort id_p : replace ter=ter[_n-1] if !missing(ter[_n-1])
browse if ter != ter_origin
replace ter=0 if missing(ter)

replace ter =15 if (force ==1 & ter==12)  //This is when the terminated BIT is replaced by the new one in force in that year
bysort id_p: replace ter=ter[_n-1] if ter[_n-1]>12 & !missing(ter[_n-1])
replace ter =0 if ter==15 // when ter=15, there is a new BIT replaced the old one
replace ter=1 if ter==12
gen force_origin = force
bysort id_p : replace force=force[_n-1] if !missing(force[_n-1])

replace force =0 if missing(force)
replace force = 0 if ter==1
rename force bit
label var bit "=1 if there is an in-forced BIT"
label var ter "=1 if the BIT is terminated and no new replacement"

drop x *origin*  ter
browse if host == "SVK" & source =="UKR"
browse if host == "UKR" & source =="SVK"


save BIT-final, replace 
erase force.dta
erase ter.dta
erase BIT1.dta 
erase BIT2.dta 

use BIT-final, clear
*If you want to make this dataset to have the same variable names as CEPII database:
// rename source iso_o
// rename host iso_d
// save BIT-final, replace






