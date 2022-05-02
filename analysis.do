clear all
set more off

global route "/Users/fuhongqiao/Desktop/北京大学公共卫生学院工作文档/论文发表相关材料/未提交/information disclosure/"

use "$route/working_data/analysis1.dta",clear

gen patient_w1= number_w_1 + number_w_2 + number_w_3

gen patient_w2= number_w_1 + number_w_2

gen patient_total = number_w_1 + number_w_2 + number_w_3 + number_tel

gen patient_tel = number_tel

encode 年度好大夫科室,gen(dep)
bysort username: egen dep_mean= mean (dep)
replace dep = dep_mean if dep == .
drop dep_mean

***医疗需求***

foreach var of varlist patient_total patient_w1 patient_tel patient_w2 number_refer{

gen ln_`var' = ln(`var'+1)

reghdfe ln_`var' c.treat#c.post,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", replace bdec(3) sdec(3)

reghdfe ln_`var' c.treat#c.post if rank_dis<=5 & rank_dis>=-4 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)

reghdfe ln_`var' c.treat#c.post if rank_dis<=4 & rank_dis>=-3 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)

reghdfe ln_`var' c.treat#c.post if rank_dis<=3 & rank_dis>=-2 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)

reghdfe ln_`var' c.treat#c.post if rank_dis<=2 & rank_dis>=-1 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)
}


****本地和外地***

gen local_p= number_w_local + number_tel_local
gen nonlocal_p = number_w_nl +  number_tel_nl

foreach var of varlist local_p nonlocal_p number_w_local number_w_nl number_tel_local number_tel_nl {

replace `var' = 0 if `var' ==. 
gen ln_`var' = ln(`var'+1)

reghdfe ln_`var' c.treat#c.post,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", replace bdec(3) sdec(3)

reghdfe ln_`var' c.treat#c.post if rank_dis<=5 & rank_dis>=-4 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)

reghdfe ln_`var' c.treat#c.post if rank_dis<=4 & rank_dis>=-3 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)

reghdfe ln_`var' c.treat#c.post if rank_dis<=3 & rank_dis>=-2 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)

reghdfe ln_`var' c.treat#c.post if rank_dis<=2 & rank_dis>=-1 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)
}

xtset ID week_num 

replace 图文价格= F.图文价格 if 图文价格==.
replace 图文价格= L.图文价格 if 图文价格==.
replace 图文价格= F.图文价格 if 图文价格==.
replace 图文价格= L.图文价格 if 图文价格==.
bysort username post: egen price_w1= mean(图文价格)
replace 图文价格 = price_w1 if  图文价格==.
gen ln_price_w1= ln(图文价格+1)

xtset ID week_num 
replace 电话价格= F.电话价格 if 电话价格==.
replace 电话价格= L.电话价格 if 电话价格==.
replace 电话价格= F.电话价格 if 电话价格==.
replace 电话价格= L.电话价格 if 电话价格==.
bysort username post: egen price_tel= mean(电话价格)
replace 电话价格 = price_tel if 电话价格==.
gen ln_price_tel= ln(电话价格+1)

xtset ID week_num 
replace 一问一答价格= F.一问一答价格 if 一问一答价格==.
replace 一问一答价格= L.一问一答价格 if 一问一答价格==.
replace 一问一答价格= F.一问一答价格 if 一问一答价格==.
replace 一问一答价格= L.一问一答价格 if 一问一答价格==.
bysort username post: egen price_w2= mean(一问一答价格) 
replace 一问一答价格 = price_w1 if  一问一答价格==.
gen ln_price_w2= ln(一问一答价格+1)

foreach var of varlist  ln_price_w1 ln_price_w2 ln_price_tel{

reghdfe `var' c.treat#c.post,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", replace bdec(3) sdec(3)

reghdfe `var' c.treat#c.post if rank_dis<=5 & rank_dis>=-4 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)

reghdfe `var' c.treat#c.post if rank_dis<=4 & rank_dis>=-3 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)

reghdfe `var' c.treat#c.post if rank_dis<=3 & rank_dis>=-2 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)

reghdfe `var' c.treat#c.post if rank_dis<=2 & rank_dis>=-1 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)
}

gen revenue_w_1 =  图文价格 * number_w_1

replace revenue_w_1 = 0 if number_w_1 ==0 

gen revenue_w_2 =  一问一答价格 * number_w_2

replace revenue_w_2 = 0 if number_w_2 ==0 

gen revenue_tel =  电话价格 * number_tel

replace revenue_tel = 0 if number_tel ==0 

replace revenue_tel = 0 if revenue_tel == .

gen revenue_total= revenue_w_1 + revenue_w_2  + revenue_tel 

gen revenue_w= revenue_w_1 + revenue_w_2 



foreach var of varlist revenue_total revenue_w  revenue_tel{

replace `var' = 0 if `var' ==. 
gen ln_`var' = ln(`var'+1) 

reghdfe ln_`var' c.treat#c.post,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", replace bdec(3) sdec(3)

reghdfe ln_`var' c.treat#c.post if rank_dis<=5 & rank_dis>=-4 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)

reghdfe ln_`var' c.treat#c.post if rank_dis<=4 & rank_dis>=-3 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)

reghdfe ln_`var' c.treat#c.post if rank_dis<=3 & rank_dis>=-2 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)

reghdfe ln_`var' c.treat#c.post if rank_dis<=2 & rank_dis>=-1 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)
}

replace 每周登陆次数 = 0 if 每周登陆次数==.

rename 每周登陆次数  reg_time

gen ln_reg_time= ln(reg_time+1)

gen reg_7 = reg_time==7 

foreach var of varlist reg_time ln_reg_time reg_7{


reghdfe `var' c.treat#c.post,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", replace bdec(3) sdec(3)

reghdfe `var' c.treat#c.post if rank_dis<=5 & rank_dis>=-4 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)

reghdfe `var' c.treat#c.post if rank_dis<=4 & rank_dis>=-3 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)

reghdfe `var' c.treat#c.post if rank_dis<=3 & rank_dis>=-2 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)

reghdfe `var' c.treat#c.post if rank_dis<=2 & rank_dis>=-1 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)
}

replace number_good  = 0 if number_good  ==.
replace number_bad  = 0 if number_bad  ==.



foreach var of varlist number_good number_bad{

replace `var' = 0 if `var' ==. 
gen ln_`var' = ln(`var'+1) 

reghdfe ln_`var' c.treat#c.post,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", replace bdec(3) sdec(3)

reghdfe ln_`var' c.treat#c.post if rank_dis<=5 & rank_dis>=-4 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)

reghdfe ln_`var' c.treat#c.post if rank_dis<=4 & rank_dis>=-3 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)

reghdfe ln_`var' c.treat#c.post if rank_dis<=3 & rank_dis>=-2 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)

reghdfe ln_`var' c.treat#c.post if rank_dis<=2 & rank_dis>=-1 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/`var'.xls", append bdec(3) sdec(3)
}

merge 1:1 username week_num using "/Users/fuhongqiao/Desktop/北京大学公共卫生学院工作文档/论文发表相关材料/未提交/information disclosure/working_data/waiting_analysis.dta", gen(_merge)
drop if _merge == 2 
drop _merge 

preserve

keep if week_num>=23

gen ln_waiting= ln(一般等待时长秒+1)

reghdfe ln_waiting c.treat#c.post,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/waiting.xls", replace bdec(3) sdec(3)

reghdfe ln_waiting c.treat#c.post if rank_dis<=5 & rank_dis>=-4 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/waiting.xls", append bdec(3) sdec(3)

reghdfe ln_waiting c.treat#c.post if rank_dis<=4 & rank_dis>=-3 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/waiting.xls", append bdec(3) sdec(3)

reghdfe ln_waiting c.treat#c.post if rank_dis<=3 & rank_dis>=-2 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/waiting.xls", append bdec(3) sdec(3)

reghdfe ln_waiting c.treat#c.post if rank_dis<=2 & rank_dis>=-1 ,a(ID week_num i.dep#c.week_num) vce(robust)
outreg2 using "$route/tables/waiting.xls", append bdec(3) sdec(3)

restore

gen ln_waiting= ln(一般等待时长秒+1)

preserve

keep if rank_dis<=5 & rank_dis>=-4

logout,save("$route/tables/summary") word replace: sum  ln_patient_total patient_total ln_patient_w1 patient_w1 ln_patient_tel patient_tel ///
ln_number_refer number_refer ln_local_p local_p ln_nonlocal_p nonlocal_p ln_price_w1 price_w1 ln_price_tel price_tel ln_revenue_total revenue_total ln_revenue_w revenue_w ln_revenue_tel revenue_tel ///
reg_7 ln_number_good number_good ln_number_bad number_bad ln_waiting

**年度好大夫***
logout,save("$route/tables/summary1") word replace: sum  ln_patient_total ln_patient_w1 ln_patient_tel ///
ln_number_refer ln_local_p ln_nonlocal_p ln_price_w1 ln_price_tel ln_revenue_total ln_revenue_w ln_revenue_tel ///
reg_7 ln_number_good ln_number_bad ln_waiting if treat == 1 & post ==0

logout,save("$route/tables/summary2") word replace: sum  ln_patient_total ln_patient_w1 ln_patient_tel ///
ln_number_refer ln_local_p ln_nonlocal_p ln_price_w1 ln_price_tel ln_revenue_total ln_revenue_w ln_revenue_tel ///
reg_7 ln_number_good ln_number_bad ln_waiting if treat == 1 & post ==1

***控制组
logout,save("$route/tables/summary3") word replace: sum  ln_patient_total ln_patient_w1 ln_patient_tel ///
ln_number_refer ln_local_p ln_nonlocal_p ln_price_w1 ln_price_tel ln_revenue_total ln_revenue_w ln_revenue_tel ///
reg_7 ln_number_good ln_number_bad ln_waiting if treat == 0 & post ==0

logout,save("$route/tables/summary4") word replace: sum  ln_patient_total ln_patient_w1 ln_patient_tel ///
ln_number_refer ln_local_p ln_nonlocal_p ln_price_w1 ln_price_tel ln_revenue_total ln_revenue_w ln_revenue_tel ///
reg_7 ln_number_good ln_number_bad ln_waiting if treat == 0 & post ==1


foreach var of varlist ln_patient_total ln_patient_w1 ln_patient_tel ln_number_refer ln_local_p ln_nonlocal_p ln_price_w1 ln_price_tel ln_revenue_total ln_revenue_w ln_revenue_tel reg_7 ln_number_good ln_number_bad ln_waiting{

logout, save("$route/tables/`var'_1") excel replace: ttest `var' if post==0 ,by(treat)  level(95)
logout, save("$route/tables/`var'_2") excel replace: ttest `var' if post==1 ,by(treat)  level(95)

}

restore


