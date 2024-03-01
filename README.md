# Cashflow Calculation
I designed this repository with the purpose of sharing my projects as a sample of my Stata coding skills.
Here I calculate three amortized bond cashflows. The original data is available in excel format. The code is written in a way that if more bonds are added to the mentioned excel file the calculations will be also applied to them in an automatic manner. 
Amortization scheme: The debt service remains stable over time for these three bonds i.e. it will be 5% coupon rate +1% amortization rate in the beginning, totaling 6% of the amount issued. 
The following code consists of transferring data into stata, cleaning it and preparing it for calculations, and finally saving the results in both wide and long panel format.
The date variable is created based on the issuance, maturity, first coupon payment and first redemption dates before starting with the cashflow calculations.
