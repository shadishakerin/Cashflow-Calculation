********************************************************************************
*Task: Amortized Bond Calculation
*Author: Shadi Shakerin
*Date: May 2021
********************************************************************************
*Introduction: This do-file is created to calculate three amortized bond
*cashflows. The original data is available in excel format. The code is written 
*in the way that if more bonds are added to the mentioned excel file the 
*calculations will also apply to them in an automatic manner. 
*Amortization scheme: The debt service remains stable over time for these three 
*bonds i.e. it will be 5% coupon rate +1% amortization rate in the beginning, 
*totaling 6% of the amount issued. 
*The following code consists of transferring data into stata, cleaning it and 
*preparing it for calculations, and finally saving the results in both wide and 
*log panel format.
*The date variable is created based on the issuance, maturity, first coupon 
*payment and first redemption dates before starting with the cashflow
*calculations
******************************************************************************** 
cd
clear
cd "C:\Users\shadi\Documents\GitHub\Stata to Github\Stata-Projects\data"
********************************************************************************
*import the excel file into stata
import excel using bonds_for_Haircut_computationTest.xlsx, firstrow clear
********************************************************************************
*Data cleaning
*Rename some variables and split the string date variables into month and year
*elements and then convert them into numeric in order to make proper date 
*variables afterwards
rename Couponstateswhendividendsar mo
rename Issuanceissueyearofbond y
split mo, p(;)
rename Amountamountissuedinmillion fv
split MaturitymaturitydateTEXT, p(/)
split FirstCouponpayment, p(/)
split Firstredemption, p(/)
split IssuanceissueddateTEXT, p(/)
destring FirstCouponpayment* Firstredemption* IssuanceissueddateTEXT* MaturitymaturitydateTEXT*, replace
*Generate dates by using the splitted numerized variables:
*c_date: first coupon payment date 
*r_date: first redemption date 
*issue date: issuance date 
*m_date: maturity date  
ge c_date = mdy(FirstCouponpayment1, 1, FirstCouponpayment2)
ge r_date = mdy(Firstredemption2, 1, Firstredemption3)
ge issue_date = mdy(IssuanceissueddateTEXT1, 1, IssuanceissueddateTEXT2)
ge maturity_date = mdy(MaturitymaturitydateTEXT1, 1, MaturitymaturitydateTEXT2)
*Generate separate variables for each bond from date variablesm here the number 
*of observations equals the number of bonds, i.e. three
forval i = 1/`=_N' {
	gen c_date`i' = c_date[`i']
	gen r_date`i' = r_date[`i']
	gen issue_date`i' = issue_date[`i']
	gen m_date`i' = maturity_date[`i']
	}
*Convert to date format
format c_date* r_date* issue_date* m_date* %d
*After creating the dates I generate the variables needed for calculations,
*namely, face value (amount issued) variables, amortization and coupon rate
*variables: Generate face value variables for each bond using the first value 
*of each variable to avoid missing value problem 
forval i = 1/`=_N' {
	gen fv`i' = fv[`i']
	replace fv`i' = fv`i'[1] 
*Generate coupon payment variables based on the ID variable and the replacing 
*them by zero for later calculations 
	gen coupon_pay`i' = ID[`i']
	replace coupon_pay`i' = 0
*Generate amortization payment variables 
	gen amort`i' = 0
*Generate separate payment months to count the number of periods later 
*Generate separate ID variables for each bond 
	gen pay_months`i' = mo[`i']
	gen ID`i' = ID[`i']
	}
*Install a package for "egen command", could be escaped when package is already
*installed
ssc install egenmore
*Calculate the number of payment periods in year for each bond based on the 
*number of ";" in "mo" variable
egen n_pay = noccur(mo), string(;)
replace n_pay = n_pay +1
*Then I separate the number of payments in year for each bond
forval i = 1/`=_N' {
	gen n_pay`i' = n_pay[`i']
	}
*Generate coupon rate variabel based on the number of periods for each bond
*c_r is coupon rate 
destring couponrate, replace
rename couponrate c_r
forval i = 1/`=_N' {
	gen c_r`i' = c_r[`i']/(n_pay`i')/100
	}
*Convert amortization rate into numeric
replace Rate = subinstr(Rate, "%","", 1)
rename Rate a_r 
destring a_r, replace
*Calculate amortiztion rate based on number of periods for each of the bonds
*a_r is amortization rate 
forval i = 1/`=_N' {
	gen a_r`i' = a_r[`i']/(n_pay`i')/100
	gen fv_per`i' = fv`i'[1]
	}
drop mo 
*Generate a variable that contains the number of bonds, this is used later in
*the loops 
gen x = _N
*Now I can reshape the data into an initital long format
reshape long mo, i(ID) j(mon) 
drop FirstCouponpayment* Firstredemption* IssuanceissueddateTEXT* maturity_date 
*Generate the main date variable on a monthly basis, "y" is year of issue, 
*I take min and max of it in order to include all given years in the date
*variable, then "o" is defined as the number of months within this year range, 
*beacause I need to repeat each year 12 times to accomodate  the desired number
*of months later. This is done by replacing the missing values in between the 
*years by the previous year. 
ge year=.
su y
local j=round(r(min))
su Maturitymaturityyearstatic
local k=round(r(max))
local o = (`k'-`j'+1)*12
set obs `o'
forval i = 1(12)`o' {
  replace year = `j'+(`i'-1)/12 if _n ==`i'
	}
replace year = year[_n-1] if year ==.
*Generate "rep" to use as month variable when generating date variable 
bys year: gen rep = _n
*Generate date variables using the created "year" and "rep" variable, 
*1 represents the 1st day of the month 
ge date = mdy(rep,1,year)
format date %d
********************************************************************************
*Cashflow calculations 
*x[1] equals the number of bonds as defined above, I use this to write the loops
*as a local variable 
local j = x[1]
*Correcting the face value observations by setting them to zero before the
*issuance
*c_r is coupon rate 
*Coupon payments on the first coupon payment date are calculated and c_r 
*multiplied by fv, same is done for amortization payment. 
forvalues i = 1/`j' {
replace fv`i' = fv`i'[1] 
replace fv`i' = 0 if date < issue_date`i'[1]
replace c_r`i' = c_r`i'[1]
replace a_r`i' = a_r`i'[1]
replace coupon_pay`i' = fv`i'*c_r`i' if date == c_date`i'[1]
	} 
*pmt is caluculated as the sum of amortizationa and coupon payment in the first 
*period and replaced by 0 before the first redemption date 
forval i = 1/`j' {
	gen pmt`i' = fv`i'*(c_r`i' + a_r`i') 
	replace pmt`i' = 0 if date < r_date`i'[1]
	}
*generate np defined as the duration of periods based on the number of payments 
*per year 
forval i =1/`j' {
	gen np`i' = 12 / n_pay`i'
	}	
*generating the number of observations to use for determination of the 
*observation number at specific dates. These specific dates are used in the loop
*as start values for the next loop. Here I extract three start numbers 
*corresponding to the each of the three redemption dates. 
gen n_obs = _n
order n_obs
local j = x[1]
forval k = 1/`j' {
	gen start`k' = n_obs if date == r_date`k'[1]
	su start`k'
	gen s`k' = round(r(min))
	gen mature`k' = n_obs if date == m_date`k'[1]
	su mature`k'
	gen mt`k' = round(r(min))
	}
*Here I use the generated start dates above to do the debt service calculations.
*"s" represents the first redemption dates and "mt" shows the maturity dates
*when the calculation must stop. 
*k: number of bonds
*z: number of payment periods 
*s: at what observations first redemptions occure
*mt: at what observation the bonds mature
*i: starts from the first redemtion date and jumps forward according to the 
*number of periods in between the payments and ends at maturity 
*the following loop calculated the coupon payments, amortization payment and 
*updated face value of each of the bonds 
local j = x[1]
forvalues k = 1/`j' {
	local z = np`k'[1]
	local s = s`k'[1]
	local mt = mt`k'[1]
	forval i = `s'(`z')`mt' {
		replace coupon_pay`k'= fv`k'[_n-`z']*c_r`k' in `i'
        replace amort`k' = pmt`k' - coupon_pay`k' in `i'
        replace fv`k' = fv`k'[_n-`z'] - amort`k' in `i'
		}
		}
*Bond IDs are generated
*fv_percent shows the ratio of current fv to the initial face value in 
*percentage terms
local j = x[1]
forvalues i = 1/`j' {
	gen bond_ID`i' = ID`i'[1]
	gen percent_fv`i' = 100*fv`i'/fv_per`i'[1]
	}
*variables are ordered from last to first 
local j = x[1]
forvalues i = 1/`j' {
	order date bond_ID`i' coupon_pay`i' amort`i' fv`i' pmt`i' percent_fv`i'
	}
*Face values in between the payments remain equal to the initial value after the
*related loop runs, here I replace them with their previous obsevation and with
*0 after the maturity. Same is done for pmt. 
forval i = 1/`j' {
	replace fv`i' = fv`i'[_n-1] if fv`i' > fv`i'[_n-1] & date > c_date`i'[1]
	replace fv`i' = 0 if date > m_date`i'[1]
	replace pmt`i' = 0 if date > m_date`i'[1]
	}
*fv_percent variables must be adjusted after the first coupon payment, too. 
local j = x[1]
forvalues i = 1/`j' {
	replace percent_fv`i' = percent_fv`i'[_n-1] if percent_fv`i' > percent_fv`i'[_n-1] & date > c_date`i'[1]
	replace percent_fv`i' = 0 if date > m_date`i'[1]
	}
********************************************************************************
*eliminating extra variables 
keep date bond_ID* amort* fv* pmt* percent_fv* coupon_pay*
drop fv fv_per*
*replaceing missing values with zero for the months when there's no payment
foreach x of varlist _all {
 replace `x' = 0 if (`x' == .) 
	}
*Introducing the date variable to stata
xtset date
**Note: Here the date includes all dates in monthly formant for all bonds and 
*the variable's observations for dates before issuance and after maturity appear
*as zeros. 
********************************************************************************
*save datasets
*save in wide format
save chashflow_wide.dta, replace
*reshape into long format 
reshape long bond_ID coupon_pay amort fv pmt percent_fv, i(date) j(bond_num)
sort bond_num date
********************************************************************************
*labeling variables
label variable date "monthly dates"
label variable bond_num "bond number, changes with bond ID"
label variable bond_ID "bond IDs based on original data"
label variable coupon_pay "monthly coupon payments"
label variable amort "monthly amortization payments"
label variable fv "last outstanding face value or amount issued, fv updates with each redemption"
label variable pmt "constant payment = sum of amortization and coupon payment at the first redemption period"
label variable percent_fv "ratio of last fv to the initial face value in percentage terms"
*save in long format
save cashflow_long.dta, replace
*browse data
br
describe 
