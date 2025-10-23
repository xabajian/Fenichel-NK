//----------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------build_phiNR_from_WB_and_PWT81--------------------------------------------------------------------

/*
This do file constructs natural resource shares (phi_NR) as in MSS by calling data from the
WB and PWT. As an output it will save a dataset that has phi_NR for multiple countries between 
1970 and 2005. User must set the directory before use. 
This do file calls the following dta files:

1) PWT8
2) timber_and_subsoil_rent_input.dta
3) crop_land_rent_input.dta
4) pasture_land_rent_input.dta



Updated: April 20th 2016
*/

cd "/Users/xabajian/Desktop/Yale Postdoc/NK Datasets/mss 2019 data"

* Call PWT
use "pwt80.dta", clear	

* codebook country
* SAMPLE REMARK: We start with 167 countries from PWT

* pl_gdpe: Price level of CGDPe (PPP/XR), price level of USA GDP_o in 2005 = 1
* pl_gdpo: Price level of CGDPo (PPP/XR), price level of USA GDP_o in 2005 = 1

replace pl_gdpe=. if pl_gdpe<0 /* No country */
replace pl_gdpo=. if pl_gdpo<0 /*This happens in Bermuda*/	

bys year: egen nom_p=max(pl_gdpo) if countrycode=="USA"
bys year: egen nom_pp=max(nom_p)
gen pl_gdpo_old = pl_gdpo/nom_pp

drop nom_p nom_pp
bys year: egen nom_p=max(pl_gdpe) if countrycode=="USA"
bys year: egen nom_pp=max(nom_p)
gen pl_gdpe_old = pl_gdpe/nom_pp


* Remark 1. We multiply nominal GDP by 1,000,000 to transform GDP in the same units as rents from natural resources (from "natural_rents.dta")		
gen nominal_gdpe = (cgdpe)*1000000*pl_gdpe_old
gen nominal_gdpo = (cgdpo)*1000000*pl_gdpo_old
		
* Choose that GDP variable we use, the code runs under nominal_gdp		
gen nominal_gdp=nominal_gdpo



* Sample by years	
scalar minyear = 1970
scalar maxyear = 2010	

	
* We need to do this replacement here regarding the name of Cote d'Ivoire because of the d`Ivorie in the original PWT */
replace country="Cote dIvoire" if country=="Cote d`Ivoire"	

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* (1) Merge with timber_and_subsoil_rents.dta
		
codebook country	
sort country year
merge 1:1 country year using "timber_and_subsoil_rent_input.dta"

keep if year>=minyear & year<maxyear 	



//tab _merge if nominal_gdp~=.
//gen cc1 = countrycode + " " + country
//tabulate cc1 if _merge==1 & nominal_gdp~=. & year<2006
//tabulate cc1 if _merge==2 & nominal_gdp~=. & year<2006
//codebook country if forest~=.  /* Total of 171 countries with forest */
//codebook country if oil~=.     /* Total of 208 countries with oil in at least one year */

rename forest timber

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* COMPUTE TIMBER AND SUBSOIL RENTS AS SHARE OF GDP


local natural_types "timber oil ng coal nickel lead bauxite copper phosphate tin zinc silver iron gold"
foreach x of local natural_types {
	gen phi_NR_`x' = `x'/nominal_gdp 
	}

	
gen tag_phi_NR_subsoil = 1 if phi_NR_oil==. & phi_NR_ng==. & phi_NR_coal==. & phi_NR_nickel==. & phi_NR_lead==. & phi_NR_bauxite==. & phi_NR_copper ==. & phi_NR_phosphate==. & phi_NR_tin==. & phi_NR_zinc==. & phi_NR_silver==. & phi_NR_iron==. & phi_NR_gold==.
egen phi_NR_subsoil = rsum(              phi_NR_oil   phi_NR_ng   phi_NR_coal   phi_NR_nickel   phi_NR_lead   phi_NR_bauxite   phi_NR_copper   phi_NR_phosphate   phi_NR_tin   phi_NR_zinc   phi_NR_silver   phi_NR_iron   phi_NR_gold) if tag_phi_NR_subsoil~=1


* For Serbia and Montenegro we have joint data but NOT individual. We compute individual using gdp as weight. 
* We need to compute the gdp of "Serbia and Montenegro" in order to compute the phi_NR_`x':

gen nominal_gdp_serb = nominal_gdp if country=="Serbia"
gen nominal_gdp_mont = nominal_gdp if country=="Montenegro"
bys year: egen mnominal_gdp_serb = max(nominal_gdp_serb)  
bys year: egen mnominal_gdp_mont = max(nominal_gdp_mont)
replace nominal_gdp =  mnominal_gdp_serb +  mnominal_gdp_mont if country=="Serbia and Montenegro"

		
* For Serbia and Montenegro we have joint data on timber and subsoil but NOT individual. 
* 		On the other hand we have data on INDIVIDUAL nominal gdp, but not joint. 
* 		We already computed the joint nominal_gdp for "Serbia and Montenegro" above.
* 		We compute now timber and subsoil shares using individiual gdp as weights:

 gen  share_serb = mnominal_gdp_serb/(mnominal_gdp_serb + mnominal_gdp_mont) 
 gen  phi_NR_timber_serb         = share_serb*phi_NR_timber         if country=="Serbia and Montenegro"
 gen  phi_NR_subsoil_serb        = share_serb*phi_NR_subsoil        if country=="Serbia and Montenegro"

bys year: egen mphi_NR_timber_serb        =max(phi_NR_timber_serb)
bys year: egen mphi_NR_subsoil_serb       =max(phi_NR_subsoil_serb)
replace phi_NR_timber         = mphi_NR_timber_serb if country=="Serbia"
replace phi_NR_subsoil        = mphi_NR_subsoil_serb if country=="Serbia"

 gen           share_mont = mnominal_gdp_mont/(mnominal_gdp_serb + mnominal_gdp_mont) 
 gen  phi_NR_timber_mont         = share_mont*phi_NR_timber         if country=="Serbia and Montenegro"
 gen  phi_NR_subsoil_mont        = share_mont*phi_NR_subsoil        if country=="Serbia and Montenegro"
 
bys year: egen mphi_NR_timber_mont        =max(phi_NR_timber_mont)
bys year: egen mphi_NR_subsoil_mont       =max(phi_NR_subsoil_mont)
replace phi_NR_timber         = mphi_NR_timber_mont if country=="Montenegro"
replace phi_NR_subsoil        = mphi_NR_subsoil_mont if country=="Montenegro"

drop if country=="Serbia and Montenegro"

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* (2) Merge with crop_rent_input.dta
drop _merge

codebook country	
sort country year
merge 1:1 country year using "crop_land_rent_input.dta"
keep if year>=minyear & year<maxyear	

tab _merge if nominal_gdp~=.
gen cc2 = countrycode + " " + country
tabulate cc2 if _merge==1 & nominal_gdp~=. & year<2006
tabulate cc2 if _merge==2 & nominal_gdp~=. & year<2006


/*
Further we have two sets of countries for which we do not have individual data on crop
land rents per country but joint data for country pairs for a selected number of 
years: 
(a) Belgium (30 periods), Luxembourg (30 periods), 
(b) Czech Rep (16 periods), Slovak Republic (16 periods), 
*/
		
*-------------------------------------------------------------------------------
* (a) Belgium and Luxembourg:

/* Remark: We notice that we compute crop rents jointly for
Belgium-Luxembourg from 1966 to 1999, and then separately for Belgium from 2000 to 2001,
and for Luxembourg from 2000 to 2011. Next, we impute pasture rents for Belgium and 
Luxembourg separately by assuming that for years before 2000 these are split in 
the Belgium-Luxembourg variable  as they are split between the Belgium and Luxemburg
in 2000.*/

 *br country countrycode year pq_rent_a nominal_gdp if country=="Belgium" | country=="Luxembourg" | country=="Belgium-Luxembourg"   
  
 gen  bel_2000=pq_rent_a if country=="Belgium"    & year==2000
 gen  lux_2000=pq_rent_a if country=="Luxembourg" & year==2000
egen mbel_2000=max(bel_2000)
egen mlux_2000=max(lux_2000)

 gen  share_bel_2000=mbel_2000/(mbel_2000+mlux_2000) 
 gen pq_rent_a_bel=share_bel_2000*pq_rent_a if country=="Belgium-Luxembourg"
bys year: egen mpq_rent_a_bel=max(pq_rent_a_bel)
replace pq_rent_a = mpq_rent_a_bel if country=="Belgium" & year<2000	

 gen  share_lux_2000=mlux_2000/(mbel_2000+mlux_2000) 
 gen pq_rent_a_lux=share_lux_2000*pq_rent_a if country=="Belgium-Luxembourg"
bys year: egen mpq_rent_a_lux=max(pq_rent_a_lux)
replace pq_rent_a = mpq_rent_a_lux if country=="Luxembourg" & year<2000	
	
sort country year	
 * br country year pq_rent_a if country=="Belgium-Luxembourg" | country=="Belgium" | country=="Luxembourg"
  drop bel_2000-mpq_rent_a_lux
 
 *br country countrycode year pq_rent_a nominal_gdp if country=="Belgium" | country=="Luxembourg" | country=="Belgium-Luxembourg"   

 drop if country=="Belgium-Luxembourg" 
 
*-------------------------------------------------------------------------------
* (b) Czech Rep. and Slovakia Rep.

/*Simlarly, the World Bank provides pasture land rents jointly for Czechoslovakia 
from 1966 to 1992, and then separately for Czech Rep. from 1993 to 2011 and 
Slovakia Rep. from 1993 to 2011. Next, we impute pasture rents for Czech Rep. and 
Slovakia Rep. separately by assuming that for years before 1993 these rents are split
in Czechoslovakia variable as they are split between the Czech Rep and the Slovakia Rep. 
in 1993.*/

* br country countrycode year pq_rent_a nominal_gdp if country=="Czech Republic" | country=="Slovak Republic" | country=="Czechoslovakia" 

 gen  cze_1993=pq_rent_a if country=="Czech Republic"  & year==1993
 gen  slo_1993=pq_rent_a if country=="Slovak Republic" & year==1993
egen mcze_1993=max(cze_1993)
egen mslo_1993=max(slo_1993)

 gen  share_cze_1993=mcze_1993/(mcze_1993+mslo_1993) 
 gen pq_rent_a_cze=share_cze_1993*pq_rent_a if country=="Czechoslovakia"
bys year: egen mpq_rent_a_cze=max(pq_rent_a_cze)
replace pq_rent_a = mpq_rent_a_cze if country=="Czech Republic" & year<1993	

 gen  share_slo_1993=mslo_1993/(mcze_1993+mslo_1993) 
 gen pq_rent_a_slo=share_slo_1993*pq_rent_a if country=="Czechoslovakia"
bys year: egen mpq_rent_a_slo=max(pq_rent_a_slo)
replace pq_rent_a = mpq_rent_a_slo if country=="Slovak Republic" & year<1993	
	
sort country year	
*  br country year pq_rent_a if country=="Czechoslovakia" | country=="Czech Republic" | country=="Slovak Republic"
  drop cze_1993-mpq_rent_a_slo

* br country countrycode year pq_rent_a nominal_gdp if country=="Czech Republic" | country=="Slovak Republic" | country=="Czechoslovakia" 

 drop if country=="Czechoslovakia"  
 
*-------------------------------------------------------------------------------  
* (c) Serbia and Montenegro

/* Finally, the World Bank provides pasture land rents jointly for Serbia and Montenegro 
from 1992 to 2005, and then separately for Serbia 2006 to 2011 and Montenegro 2006 to 2011.
Next, we impute pasture rents for Serbia and 
Montenegro separately by assuming that for years before 2006 these are split in 
the "Serbia and Montenegro" variable as they are split between Serbia and Montenegro
in 2006.*/ */

 gen  serb_2006=pq_rent_a if country=="Serbia"     & year==2006
 gen  mont_2006=pq_rent_a if country=="Montenegro" & year==2006
egen mserb_2006=max(serb_2006)
egen mmont_2006=max(mont_2006)

 gen  share_serb_2006=mserb_2006/(mserb_2006+mmont_2006) 
 gen pq_rent_a_serb=share_serb_2006*pq_rent_a if country=="Serbia and Montenegro"
bys year: egen mpq_rent_a_serb=max(pq_rent_a_serb)
replace pq_rent_a = mpq_rent_a_serb if country=="Serbia" & year<2006	

 gen  share_mont_2006=mmont_2006/(mserb_2006+mmont_2006) 
 gen pq_rent_a_mont=share_mont_2006*pq_rent_a if country=="Serbia and Montenegro"
bys year: egen mpq_rent_a_mont=max(pq_rent_a_mont)
replace pq_rent_a = mpq_rent_a_mont if country=="Montenegro" & year<2006	
	
sort country year	
*  br country year pq_rent_a if country=="Serbia and Montenegro" | country=="Serbia" | country=="Montenegro"
  drop serb_2006-mpq_rent_a_mont  

* br country countrycode year pq_rent_a nominal_gdp if country=="Serbia" | country=="Montenegro" | country=="Serbia and Montenegro" 

 drop if country=="Serbia and Montenegro" 
 
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* COMPUTE CROP LAND RENTS AS SHARE OF GDP
 
g phi_NR_crop_pq_a  =  pq_rent_a/nominal_gdp
g phi_NR_crop_fao_a = fao_rent_a/nominal_gdp
g phi_NR_crop_pq_p  =  pq_rent_p/nominal_gdp
g phi_NR_crop_fao_p = fao_rent_p/nominal_gdp
   
label variable phi_NR_crop_pq_a  "phi_NR_crop_a: rent/gdp using p*q and area weights"
label variable phi_NR_crop_fao_a "phi_NR_crop_FAO_a: rent/gdp using FAO and area weights"
label variable phi_NR_crop_pq_p  "phi_NR_crop_p: rent/gdp using p*q and production weights"
label variable phi_NR_crop_fao_p "phi_NR_crop_FAO_p: rent/gdp using FAO and production weights"
		
//table year, c(n phi_NR_crop_pq_a n phi_NR_crop_pq_p n phi_NR_crop_fao_a n phi_NR_crop_fao_p)
		

* COMPARE OUR WEALTH STOCKS WITH WEALTH STOCKS FROM WORLD BANK 
* 	do crop_rent_graph_comparisons

/* For all countries with crop land rents, we have nominal gdp. But there are 16.38\% of
all country X year pairs for which we have nominal gdp but not crop land rents.

The countries for which we have gdp for a large number of years, but not crop land for a large number of years. 
There is actually a set of countries without crop land at all (i.e. 36 periods), these are:
Baharain, Bahamas, Bermuda, Brunei, DRC, Cape Verde, Equatorial Guinea, Hong Kong,
Iran, Iceland, St. Kitts & Nevis, Laos, St. Lucia, Macao, Sudan, Singapore, Taiwan, 
Tanzania and St. Vincent & Grenadines.

Not all countries have gdp for all years. For example, note that the series of GDP
for Serbia starts in 1990 leaving 16 periods for which we have gdp but no crop land
rents. The same thing happens for Montenegro.
*/
	
drop _merge	
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

* (3) Merge with pasture_rent_input.dta

codebook country	
 sort country year
merge country year using "pasture_land_rent_input.dta"
keep if year>=minyear & year<maxyear 	

tab _merge if nominal_gdp~=.
gen cc3 = countrycode + " " + country
tabulate cc3 if _merge==1 & nominal_gdp~=. & year<2006
tabulate cc3 if _merge==2 & nominal_gdp~=. & year<2006
tab _merge
*br if _merge==2


/* 
Further we have a collection of countries for which we have not individual data per country but joint data on a set country pairs for a selected number of years: 
(a) Belgium (30 periods), Luxembourg (30 periods), 
(b) Czech Rep (3 periods), Slovak Republic (3 periods), 
(c) Serbia (16 periods), Montenegro (16 periods), 
*/
		
*-------------------------------------------------------------------------------
* (a) Belgium and Luxembourg:

/* Remark: We notice that the world bank provides timber_and_subsoil rents jointly for
Belgium-Luxembourg from 1966 to 1999, and then separately for Belgium from 2000 to 2001,
and for Luxembourg from 2000 to 2011. Next, we impute pasture rents for Belgium and 
Luxembourg separately by assuming that for years before 2000 these are split in 
the Belgium-Luxembourg variable  as they are split between the Belgium and Luxemburg
in 2000.*/

 gen  bel_2000=pasture_rent if country=="Belgium"     & year==2000
 gen  lux_2000=pasture_rent if country=="Luxembourg" & year==2000
egen mbel_2000=max(bel_2000)
egen mlux_2000=max(lux_2000)

 gen  share_bel_2000=mbel_2000/(mbel_2000+mlux_2000) 
 gen pasture_rent_bel=share_bel_2000*pasture_rent if country=="Belgium-Luxembourg"
bys year: egen mpasture_rent_bel=max(pasture_rent_bel)
replace pasture_rent = mpasture_rent_bel if country=="Belgium" & year<2000	

 gen  share_lux_2000=mlux_2000/(mbel_2000+mlux_2000) 
 gen pasture_rent_lux=share_lux_2000*pasture_rent if country=="Belgium-Luxembourg"
bys year: egen mpasture_rent_lux=max(pasture_rent_lux)
replace pasture_rent = mpasture_rent_lux if country=="Luxembourg" & year<2000	
	
sort country year	
*  br country year pasture_rent if country=="Belgium-Luxembourg" | country=="Belgium" | country=="Luxembourg"
  drop bel_2000-mpasture_rent_lux

*br country countrycode year pasture_rent nominal_gdp if country=="Belgium" | country=="Luxembourg" | country=="Belgium-Luxembourg"   
  
*-------------------------------------------------------------------------------
* (b) Czech Rep. and Slovakia Rep.

/*Simlarly, the World Bank provides pasture land rents jointly for Czechoslovakia 
from 1966 to 1992, and then separately for Czech Rep. from 1993 to 2011 and 
Slovakia Rep. from 1993 to 2011. Next, we impute pasture rents for Czech Rep. and 
Slovakia Rep. separately by assuming that for years before 1993 these rents are split
in Czechoslovakia variable as they are split between the Czech Rep and the Slovakia Rep. 
in 1993.*/

 gen  cze_1993=pasture_rent if country=="Czech Republic"  & year==1993
 gen  slo_1993=pasture_rent if country=="Slovak Republic" & year==1993
egen mcze_1993=max(cze_1993)
egen mslo_1993=max(slo_1993)

 gen  share_cze_1993=mcze_1993/(mcze_1993+mslo_1993) 
 gen pasture_rent_cze=share_cze_1993*pasture_rent if country=="Czechoslovakia"
bys year: egen mpasture_rent_cze=max(pasture_rent_cze)
replace pasture_rent = mpasture_rent_cze if country=="Czech Republic" & year<1993	

 gen  share_slo_1993=mslo_1993/(mcze_1993+mslo_1993) 
 gen pasture_rent_slo=share_slo_1993*pasture_rent if country=="Czechoslovakia"
bys year: egen mpasture_rent_slo=max(pasture_rent_slo)
replace pasture_rent = mpasture_rent_slo if country=="Slovak Republic" & year<1993	
	
sort country year	
*  br country year pasture_rent if country=="Czechoslovakia" | country=="Czech Republic" | country=="Slovak Republic"
  drop cze_1993-mpasture_rent_slo

*br country countrycode year pasture_rent nominal_gdp if country=="Czech Republic" | country=="Slovak Republic" | country=="Czechoslovakia" 
  
*-------------------------------------------------------------------------------  
* (c) Serbia and Montenegro

/* Finally, the World Bank provides pasture land rents jointly for Serbia and Montenegro 
from 1992 to 2005, and then separately for Serbia 2006 to 2011 and Montenegro 2006 to 2011.
Next, we impute pasture rents for Serbia and 
Montenegro separately by assuming that for years before 2006 these are split in 
the "Serbia and Montenegro" variable as they are split between Serbia and Montenegro
in 2006.*/ */

 gen  serb_2006=pasture_rent if country=="Serbia"     & year==2006
 gen  mont_2006=pasture_rent if country=="Montenegro" & year==2006
egen mserb_2006=max(serb_2006)
egen mmont_2006=max(mont_2006)

 gen  share_serb_2006=mserb_2006/(mserb_2006+mmont_2006) 
 gen pasture_rent_serb=share_serb_2006*pasture_rent if country=="Serbia and Montenegro"
bys year: egen mpasture_rent_serb=max(pasture_rent_serb)
replace pasture_rent = mpasture_rent_serb if country=="Serbia" & year<2006	

 gen  share_mont_2006=mmont_2006/(mserb_2006+mmont_2006) 
 gen pasture_rent_mont=share_mont_2006*pasture_rent if country=="Serbia and Montenegro"
bys year: egen mpasture_rent_mont=max(pasture_rent_mont)
replace pasture_rent = mpasture_rent_mont if country=="Montenegro" & year<2006	
	
sort country year	
*  br country year pasture_rent if country=="Serbia and Montenegro" | country=="Serbia" | country=="Montenegro"
  drop serb_2006-mpasture_rent_mont  

*br country countrycode year pasture_rent nominal_gdp if country=="Serbia" | country=="Montenegro" | country=="Serbia and Montenegro" 
	
*-------------------------------------------------------------------------------	

keep if year>=minyear & year<maxyear & nominal_gdp~=.	

 
   g phi_NR_pasture = pasture_rent/nominal_gdp

   label variable phi_NR_pasture "phi_NR_pasture: rent/gdp for pasture land"
   		
    * COMPARE OUR WEALTH STOCKS WITH WEALTH STOCKS FROM WORLD BANK 
	* do pasture_rent_graph_comparisons
	
//table year, c(n phi_NR_timber n phi_NR_subsoil n phi_NR_crop_pq_a n phi_NR_pasture)	


	
/* For all countries with pasture land rents, we have nominal gdp. But there are 5.87\% of
all country X year pairs for which we have nominal gdp but not pasture land rents.

The countries for which we have gdp for a large number of years, but not pasture land for a large number of years are:
Brunei (25 periods), Equatorial Guinea (36 periods), Macao (40 periods), Maldives (40 periods), Singapore (36 periods), and St. Kitts and Nevis (36 periods) 
*/	

drop _merge
	
*----------------------------------------------------------------------------------------------------------------------------------------------------------------------
*----------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Contruct phi_NR
*----------------------------------------------------------------------------------------------------------------------------------------------------------------------
*----------------------------------------------------------------------------------------------------------------------------------------------------------------------		
		
        local natural_types "timber oil ng coal nickel lead bauxite copper phosphate tin zinc silver iron gold"
        foreach x of local natural_types {
			bys year: egen total_Y`x'=sum(`x')
        }
 
egen total_YNR=rsum(total_Ytimber total_Yoil total_Yng total_Ycoal total_Ynickel total_Ylead total_Ybauxite total_Ycopper total_Yphosphate total_Ytin total_Yzinc total_Ysilver total_Yiron total_Ygold)

        local natural_types "timber oil ng coal nickel lead bauxite copper phosphate tin zinc silver iron gold"
        foreach x of local natural_types {
			bys year:  gen share_total_Y`x'=total_Y`x'/total_YNR
        }

egen share_total_Ysuboil=rsum(share_total_Ytimber share_total_Yoil share_total_Yng share_total_Ycoal share_total_Ynickel share_total_Ylead share_total_Ybauxite share_total_Ycopper share_total_Yphosphate share_total_Ytin share_total_Yzinc share_total_Ysilver share_total_Yiron share_total_Ygold)		
		
// table year, c(n share_total_Ytimber mean share_total_Ytimber)		
// table year, c(n share_total_Ysuboil mean share_total_Ysuboil)		


*replace natu_share =  1 if natu_share >1 & natu_share!=.
*         replace natu_share2 = 1 if natu_share2>1 & natu_share2!=.

// *hist natural_share20o, bin(10) frac
// *hist natural_share30o, bin(10) frac
//
// *hist natural_share20e, bin(10) frac
// *hist natural_share30e, bin(10) frac
//

*drop timber-nominal_gdp
*drop phi_NR_oil-phi_NR_gold
*drop total_Ytimber-share_total_Ysuboil
*drop rent_gdp_fao_a rent_gdp_fao_p _merge

egen phi_NR   = rsum(phi_NR_timber phi_NR_subsoil phi_NR_crop_pq_a phi_NR_pasture) 
*egen phi_NR_1 = rsum(phi_NR_timber phi_NR_subsoil phi_NR_crop_pq_a phi_NR_pasture) if tag~=0
*egen phi_NR_4 = rsum(phi_NR_timber phi_NR_subsoil phi_NR_crop_pq_a phi_NR_pasture) if tag==4


*drop if phi_NR==0
scalar maxyear = 2006	

// table year if phi_NR~=0, c(n phi_NR_timber n phi_NR_subsoil n phi_NR_crop_pq_a n phi_NR_pasture n phi_NR)

keep if year>=minyear & year<maxyear	

sort country year
gen countrym = countrycode

keep phi_NR phi_NR_timber phi_NR_subsoil phi_NR_crop_pq_a phi_NR_pasture countrycode year country

save MSS_NRshares.dta, replace



 
