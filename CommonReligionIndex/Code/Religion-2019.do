cd "..."
import excel Religion-2019, sheet("Sheet1") firstrow allstring clear
browse
drop othersource
rename Religions religions
**01=========this removes everything within (and including) the parentheses
*ssc install egenmore
gen religion_o =religions
tempvar n
egen `n' = noccur(religions), string("(") //if this line doesn't run for you, you probably need to install egenmore (type ssc install egenmore)
summ `n', meanonly
forvalues i = 1/`r(max)'{
replace religions= subinstr(religions, substr(religions, strpos(religions, "("), strpos(religions, ")")-(strpos(religions, "("))+1), "",.)
}

//this splits the variable and removes leading and lagging spaces
split religions, p(",")
forvalues i = 1/`r(nvars)'{
    replace religions`i' = trim(subinstr(religions`i',"%","",.))
}
label data "Religion-2017-origin"
drop __000000
rename Country CountryName
merge 1:1 CountryName using CountryName-Code
vallist CountryName if _merge !=3
drop if _merge !=3
drop _merge
save 01-Religion, replace


*02-============================reshape the file
use 01-Religion, clear
rename religions allrel
rename religion_o allrel_o
reshape long religions, i(CountryCode) j(newcol, string)
replace religions = trim(religions)
* separating religion name and percent:
moss religions, match("([0-9])") regex
rename _pos1 pos
drop _*
gen reli = trim(substr(religions, 1, pos-1))

gen per = word(religions, -1) if !missing(pos)
drop pos
*delete < in per as these numbers are very small
replace per = trim(subinstr(per,"<","",.))
replace per = trim(subinstr(per,")","",.))
* canculate average if percent is a-b format:
moss per, match("-")
gen byte notnumeric = real(per)==.

edit if notnumeric ==1
sort per
replace per = "0.225" in 1882
replace per = "0.225" in 1883
replace per = "0.225" in 1884
replace per = "0.225" in 1885
replace per = "0.75" in 1972
replace per = "2.5" in 2062
replace per = "25.5" in 2476
replace per = "9.5" in 2609
replace per = "85.5" in 2895
replace per = "6.6" in 2981
replace per = "2" in 2982
drop notnumeric

gen x1 = trim(substr(per,1,_pos1-1))
gen x2 = trim(substr(per, _pos1+1,.))

sort x1

destring x1, gen(y1)
destring x2, gen(y2)
gen y = (y1+y2)/2
tostring y, gen(yy)
replace per = yy if  !missing(_pos1)
drop x1 x2 y1 y2 yy _count _pos1 y
label var per "% of population"
label var reli "Religion"
save 02-Religion, replace


*03==================list of all religions==================
use 02-Religion, clear
keep reli
duplicates drop
sort reli
drop if missing(reli)
export excel using Relgion-listfull.xls, replace

import excel Relgion-listfull-groups, sheet("Sheet1") firstrow allstring clear
rename religion reli
drop subgroup
save religroup, replace

use 02-Religion, clear
drop if missing(reli)

merge m:1 reli using religroup, keepusing(group)
keep if _merge ==3
drop _merge

sort CountryName
export excel using Relgion-all-country.xls, replace


drop all* religions reli
sort CountryName
rename group religroup
destring per, gen(percent)
drop if missing(percent)
drop newcol per
bysort CountryName religroup: egen share = total(percent)
drop if religroup =="Others"
drop percent
duplicates drop

reshape wide share, i(CountryName) j(religroup, string)
rename share* *

save 03-religion, replace

**05============Calculate religion index=======================
* Create all possible pairs:
use 03-religion, clear
keep CountryCode
rename CountryCode host
gen source = host
fillin source host
drop if host == source
drop _fillin
* merging - host
rename host CountryCode
merge m:1 CountryCode using 03-religion
drop _merge
local varlist  CountryName Agnostic_atheism Animism Bahai Buddhism Christianity Druze Hindu Jewish  Muslim Rastafari Sikhism Spiritualism Taoism Vodou 
foreach va of local varlist {
rename `va' `va'_h
}
rename CountryCode host
*merging-source
rename source CountryCode
merge m:1 CountryCode using 03-religion
drop _merge
local varlist  CountryName Agnostic_atheism Animism Bahai Buddhism Christianity Druze Hindu Jewish  Muslim Rastafari Sikhism Spiritualism Taoism Vodou 
foreach va of local varlist {
rename `va' `va'_s
}
rename CountryCode source
*religion index
local varlist  Agnostic_atheism Animism Bahai Buddhism Christianity Druze Hindu Jewish  Muslim Rastafari Sikhism Spiritualism Taoism Vodou 
foreach va of local varlist {
gen `va'1 = `va'_s*`va'_h
}
egen religion = rowtotal(*1)
replace religion = religion/100
sum religion // min-max: 0-100: ok
keep host source Country* reli*
label var religion "Religion Index, Sum of(%x_h * %x_s)/100, x is common relgion between 2 countries"
unique host //211
unique source //211

save CommonReligionIndex, replace


