clear

// set maxvar 10000	
cd "..."
 import excel Legalsystem.xlsx, sheet("Sheet1") firstrow clear
edit
label data "Data on the origins of legal system by country from http://start.csail.mit.edu/mirror/cia.gov/library/publications/the-world-factbook/fields/2100.html"

label var ICJ "=1 if the country has accepted compulsory International Court of Justice (ICJ) jurisdiction (with or without reservations)"
local valist Common Civil Custom Religious 
foreach va of local valist {
replace `va' =0 if missing(`va')
}
des
save Legalsystem.dta, replace

use Legalsystem.dta, clear
keep CountryCode  ICJ
rename ICJ icj
save ICJ, replace

use Legalsystem.dta, clear
keep CountryCode 

rename CountryCode source 
gen host = source
fillin source host
drop if _fillin ==0
drop _*

*get variables for legal for source:
rename source CountryCode
merge m:1 CountryCode using Legalsystem, keepusing(ICJ Common Civil Religious Custom)
drop _*

rename (ICJ Common Civil Religious Custom CountryCode) (ICJ_s Common_s Civil_s Religious_s Custom_s source)

*for host
rename  host CountryCode
merge m:1 CountryCode using Legalsystem, keepusing(ICJ Common Civil Religious Custom)
drop _*

rename (ICJ Common Civil Religious Custom CountryCode) (ICJ_h Common_h Civil_h Religious_h Custom_h host)
gen x = Common_s*Common_h + Civil_s*Civil_h + Religious_s*Religious_h + Custom_s*Custom_h

gen comlegal = 0
replace comlegal =1 if x >0
inspect comlegal //16340 zeros, 26716 positive
gen comicj = ICJ_h*ICJ_s
sum comicj
inspect comicj //38,896 zeros, 4169 positive
keep source host comlegal comicj 
label var comlegal "=1 if sharing a common legal origin"
label var comicj "=1 if both has accepted compulsory International Court of Justice (ICJ) jurisdiction (with or without reservations)"
duplicates drop
save Commonlegal, replace



