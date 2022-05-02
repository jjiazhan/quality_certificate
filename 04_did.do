/* -----------------------------------------------------------------------------
AUTHOR: JIAJIA ZHAN (j.zhan21@imperial.ic.uk)
DATE:   04/13/2022
Aim:    data analysis: did 
----------------------------------------------------------------------------- */

use "$dta/analysis_sample.dta", clear 

global pure_demand "demand_all demand_online demand_wr demand_textimage demand_QA demand_free demand_pcall demand_appoint"
global rel_demand "redemand_all redemand_online redemand_wr redemand_textimage redemand_QA redemand_free redemand_pcall redemand_appoint"
global price "QA_price text_price pcall_price gift_num"


reghdfe demand_all c.treated#c.post if rel<=2 & rel>=-1,a(doc_id week) vce(robust)

foreach var of global pure_demand {

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
