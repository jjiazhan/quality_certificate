
clear all

use "$dta/senior_doctor_with_label.dta", clear 

global quota20 "妇产科"
global quota15 "皮肤性病科 泌尿男科 骨科"
global quota12 "小儿外科 小儿内科 普通外科"
global quota10 "肿瘤科 眼科 血液科 胸外科 心血管外科 心血管内科 消化内科 肾病内科 神经外科 神经内科 烧伤整形科 内分泌科 口腔科 精神心理科 呼吸内科 感染传染科 风湿免疫科 耳鼻喉头颈外科"
global quota5 "中医科 肝胆外科"
global quota3 "器官移植"

foreach dep of global quota20 {
	twoway bar indexscore rank if doc_dep_H == "`dep'", sort ///
		xline(20) ///
		xline(15,lp(dash)) ///
		xline(25,lp(dash)) ///
		graphregion(color(white)) ///
		ytitle(Underlying Score) ///
		legend(off) xtitle(Rank) ///
		subtitle("`dep'")
		graph save ../gph/`dep'.gph, replace 
		graph export ../gph/`dep'.pdf, replace font(palatino) 
}

foreach dep of global quota15 {
	twoway bar indexscore rank if doc_dep_H == "`dep'", sort ///
		xline(15) ///
		xline(10,lp(dash)) ///
		xline(20,lp(dash)) ///
		graphregion(color(white)) ///
		ytitle(Underlying Score) ///
		legend(off) xtitle(Rank) ///
		subtitle("`dep'")
		graph save ../gph/`dep'.gph, replace 
		graph export ../gph/`dep'.pdf, replace font(palatino) 
}

foreach dep of global quota12 {
	twoway bar indexscore rank if doc_dep_H == "`dep'", sort ///
		xline(12) ///
		xline(7,lp(dash)) ///
		xline(17,lp(dash)) ///
		graphregion(color(white)) ///
		ytitle(Underlying Score) ///
		legend(off) xtitle(Rank) ///
		subtitle("`dep'")
		graph save ../gph/`dep'.gph, replace 
		graph export ../gph/`dep'.pdf, replace font(palatino) 
}

foreach dep of global quota10 {
	twoway bar indexscore rank if doc_dep_H == "`dep'", sort ///
		xline(10) ///
		xline(5,lp(dash)) ///
		xline(15,lp(dash)) ///
		graphregion(color(white)) ///
		ytitle(Underlying Score) ///
		legend(off) xtitle(Rank) ///
		subtitle("`dep'")
		graph save ../gph/`dep'.gph, replace 
		graph export ../gph/`dep'.pdf, replace font(palatino) 
}

foreach dep of global quota5 {
	twoway bar indexscore rank if doc_dep_H == "`dep'", sort ///
		xline(5) ///
		xline(0,lp(dash)) ///
		xline(10,lp(dash)) ///
		graphregion(color(white)) ///
		ytitle(Underlying Score) ///
		legend(off) xtitle(Rank) ///
		subtitle("`dep'")
		graph save ../gph/`dep'.gph, replace 
		graph export ../gph/`dep'.pdf, replace font(palatino) 
}

foreach dep of global quota3 {
	twoway bar indexscore rank if doc_dep_H == "`dep'", sort ///
		xline(3) ///
		xline(0,lp(dash)) ///
		xline(6,lp(dash)) ///
		graphregion(color(white)) ///
		ytitle(Underlying Score) ///
		legend(off) xtitle(Rank) ///
		subtitle("`dep'")
		graph save ../gph/`dep'.gph, replace 
		graph export ../gph/`dep'.pdf, replace font(palatino) 
}

local graph "妇产科.gph 皮肤性病科.gph 泌尿男科.gph 骨科.gph 小儿外科.gph 小儿内科.gph 普通外科.gph 肿瘤科.gph 眼科.gph 血液科.gph 胸外科.gph 心血管外科.gph 心血管内科.gph 消化内科.gph 肾病内科.gph 神经外科.gph 神经内科.gph 烧伤整形科.gph 内分泌科.gph 口腔科.gph 精神心理科.gph 呼吸内科.gph 感染传染科.gph 风湿免疫科.gph 耳鼻喉头颈外科.gph 中医科.gph 肝胆外科.gph 器官移植.gph"
cd ../gph
	gr combine `graph', ///
		row(5) col(6) ///
		scheme(s1color)
	graph export ../gph/score2.pdf,replace
 
 
 
 
use "$dta/senior_doctor_with_label.dta", clear
keep if rel >= -5 & rel <= 5
drop if space_id == .
merge 1:m space_id using "$dta/week_demand_by_services.dta"
drop if _merge == 2
drop _merge 
gen ln_wrconsul_demand = log(wrconsul_demand + 1)
gen ln_QA_demand = log(QA_demand) 
gen ln_free_demand = log(free_demand) 
gen ln_text_demand = log(text_demand)
gen ln_pcall_demand = log(pcall_demand)
gen ln_register_demand = log(register_demand)
collapse (mean) ln_*,by(label week)
twoway (line ln_wrconsul_demand week if label == "年度好大夫")(line ln_wrconsul_demand week if label != "年度好大夫"), ///
	  tline(2019w1,lp(dash)) ///
	  legend(order(1 "Treatment" 2 "Control") col(2))  ///
	  title("Written Consultation Demand")  ///
	  ytitle("Mean Outcome")  ///
	  xsize(4) ysize(3) ///
	  scheme(s1color)
	  graph export ../gph/wr_demand_week.pdf, replace font(palatino) 
twoway (line ln_QA_demand week if label == "年度好大夫")(line ln_QA_demand week if label != "年度好大夫"), ///
	  tline(2019w1,lp(dash)) ///
	  legend(order(1 "Treatment" 2 "Control") col(2))  ///
	  title("QA Consultation Demand")  ///
	  ytitle("Mean Outcome")  ///
	  xsize(4) ysize(3) ///
	  scheme(s1color)
	  graph export ../gph/qa_demand_week.pdf, replace font(palatino) 
twoway (line ln_text_demand week if label == "年度好大夫")(line ln_text_demand week if label != "年度好大夫"), ///
	  tline(2019w1,lp(dash)) ///
	  legend(order(1 "Treatment" 2 "Control") col(2))  ///
	  title("Image/Text Consultation Demand")  ///
	  ytitle("Mean Outcome")  ///
	  xsize(4) ysize(3) ///
	  scheme(s1color)
	  graph export ../gph/it_demand_week.pdf, replace font(palatino) 
twoway (line ln_pcall_demand week if label == "年度好大夫")(line ln_pcall_demand week if label != "年度好大夫"), ///
	  tline(2019w1,lp(dash)) ///
	  legend(order(1 "Treatment" 2 "Control") col(2))  ///
	  title("Phone-call Consultation Demand")  ///
	  ytitle("Mean Outcome")  ///
	  xsize(4) ysize(3) ///
	  scheme(s1color)
	  graph export ../gph/pcall_demand_week.pdf, replace font(palatino) 
twoway (line ln_register_demand week if label == "年度好大夫")(line ln_register_demand week if label != "年度好大夫"), ///
	  tline(2019w1,lp(dash)) ///
	  legend(order(1 "Treatment" 2 "Control") col(2))  ///
	  title("In-person visit appointment Demand")  ///
	  ytitle("Mean Outcome")  ///
	  xsize(4) ysize(3) ///
	  scheme(s1color)
	  graph export ../gph/inperson_demand_week.pdf, replace font(palatino) 
	  
use "$dta/senior_doctor_with_label.dta", clear
keep if rel >= -5 & rel <= 5
drop if space_id == .
merge 1:m space_id using "$dta/week_price_by_services.dta"
gen ln_QA_price = log(QA_price)
gen ln_text_price = log(text_price)
gen ln_pcall_price = log(pcall_price)
collapse (mean) ln_*  ,by(label week)
graph twoway (line ln_QA_price week if label == "年度好大夫") (line ln_QA_price week if label != "年度好大夫"), ///
	  tline(2019w1,lp(dash)) ///
	  legend(order(1 "Treatment" 2 "Control") col(2))  ///
	  title("QA Price")  ///
	  ytitle("Mean Outcome")  ///
	  xsize(4) ysize(3) ///
	  scheme(s1color)
	  graph export ../gph/qa_price_week.pdf, replace font(palatino) 
graph twoway (line ln_text_price week if label == "年度好大夫") (line ln_text_price week if label != "年度好大夫"), ///
	  tline(2019w1,lp(dash)) ///
	  legend(order(1 "Treatment" 2 "Control") col(2))  ///
	  title("Image/Text Price")  ///
	  ytitle("Mean Outcome")  ///
	  xsize(4) ysize(3) ///
	  scheme(s1color)
	  graph export ../gph/it_price_week.pdf, replace font(palatino) 

graph twoway (line ln_pcall_price week if label == "年度好大夫") (line ln_pcall_price week if label != "年度好大夫"), ///
	  tline(2019w1,lp(dash)) ///
	  legend(order(1 "Treatment" 2 "Control") col(2))  ///
	  title("Phone-call Price")  ///
	  ytitle("Mean Outcome")  ///
	  xsize(4) ysize(3) ///
	  scheme(s1color)	
	  graph export ../gph/pcall_price_week.pdf, replace font(palatino) 

	  
use "$dta/senior_doctor_with_label.dta", clear
keep if rel >= -5 & rel <= 5
drop if space_id == .
merge 1:m space_id using "$temp/week_wrconsul_realized_demand.dta"	
drop if _merge == 2
drop _merge 
gen ln_wr_realized_demand = log(wrconsul_rdemand+1)
collapse (mean) ln_*  ,by(label week)
twoway (line ln_wr_realized_demand week if label == "年度好大夫")(line ln_wr_realized_demand week if label != "年度好大夫"), ///
	  tline(2019w1,lp(dash)) ///
	  legend(order(1 "Treatment" 2 "Control") col(2))  ///
	  title("Written Consultation Realized Demand")  ///
	  ytitle("Mean Outcome")  ///
	  xsize(4) ysize(3) ///
	  scheme(s1color)
	  graph export ../gph/wr_realized_demand_week.pdf, replace font(palatino) 

use "$dta/senior_doctor_with_label.dta", clear
keep if rel >= -5 & rel <= 5
drop if space_id == .
merge 1:m space_id using "$temp/week_pcall_realized_demand.dta"
drop if _merge == 2
drop _merge 
gen ln_pcall_realized_demand = log(pcall_rdemand+1)
collapse (mean) ln_*  ,by(label week)
twoway (line ln_pcall_realized_demand week if label == "年度好大夫")(line ln_pcall_realized_demand week if label != "年度好大夫"), ///
	  tline(2019w1,lp(dash)) ///
	  legend(order(1 "Treatment" 2 "Control") col(2))  ///
	  title("Phone-call Consultation Realized Demand")  ///
	  ytitle("Mean Outcome")  ///
	  xsize(4) ysize(3) ///
	  scheme(s1color)
	  graph export ../gph/pcall_realized_demand_week.pdf, replace font(palatino) 
	  
use "$dta/senior_doctor_with_label.dta", clear
keep if rel >= -5 & rel <= 5
drop if space_id == .
merge 1:m space_id using "$temp/week_online_service_fb.dta"	
drop if _merge == 2
drop _merge 	  
collapse (mean) posrw_num negrw_num negrw ,by(label week)
twoway (line posrw_num week if label == "年度好大夫")(line posrw_num week if label != "年度好大夫"), ///
	  tline(2019w1,lp(dash)) ///
	  legend(order(1 "Treatment" 2 "Control") col(2))  ///
	  title("Number of positive feedback")  ///
	  ytitle("Mean Outcome")  ///
	  xsize(4) ysize(3) ///
	  scheme(s1color)
	  graph export ../gph/psrw_week.pdf, replace font(palatino) 	  
twoway (line negrw week if label == "年度好大夫")(line negrw week if label != "年度好大夫"), ///
	  tline(2019w1,lp(dash)) ///
	  legend(order(1 "Treatment" 2 "Control") col(2))  ///
	  title("If received negative feedback")  ///
	  ytitle("Mean Outcome")  ///
	  xsize(4) ysize(3) ///
	  scheme(s1color)
	  graph export ../gph/negrw_week.pdf, replace font(palatino) 

	  
use "$dta/senior_doctor_with_label.dta", clear
keep if rel >= -5 & rel <= 5
drop if space_id == .
merge 1:m space_id using "$dta/week_login_num.dta"	
drop if _merge == 2
drop _merge 
collapse (mean) login_num,by(label week)
twoway (line login_num week if label == "年度好大夫")(line login_num week if label != "年度好大夫"), ///
	  tline(2019w1,lp(dash)) ///
	  legend(order(1 "Treatment" 2 "Control") col(2))  ///
	  title("Logins")  ///
	  ytitle("Mean Outcome")  ///
	  xsize(4) ysize(3) ///
	  scheme(s1color)
	  graph export ../gph/logins_week.pdf, replace font(palatino) 

use "$dta/senior_doctor_with_label.dta", clear
keep if rel >= -5 & rel <= 5
drop if space_id == .
merge 1:m space_id using "$dta/week_waiting_time.dta"	
drop if _merge == 2
drop _merge 
gen ln_wait_time = log(wait_time_h)
collapse (mean) ln_wait_time,by(label week)
twoway (line ln_wait_time week if label == "年度好大夫")(line ln_wait_time week if label != "年度好大夫"), ///
	  tline(2019w1,lp(dash)) ///
	  legend(order(1 "Treatment" 2 "Control") col(2))  ///
	  title("Waiting Time")  ///
	  ytitle("Mean Outcome")  ///
	  xsize(4) ysize(3) ///
	  scheme(s1color)
	  graph export ../gph/wait_time_week.pdf, replace font(palatino) 
	  
	  
	  
	  
	  


graph twoway (line ln_QA_price month if label == "年度好大夫") (line ln_QA_price month if label != "年度好大夫"), ///
	  tline(2019m1,lp(dash)) ///
	  legend(order(1 "Treatment" 2 "Control") col(2))  ///
	  title("QA Price")  ///
	  ytitle("Mean Outcome")  ///
	  xsize(4) ysize(3) ///
	  scheme(s1color)

graph twoway (line ln_text_price month if label == "年度好大夫") (line ln_text_price month if label != "年度好大夫"), ///
	  tline(2019m1,lp(dash)) ///
	  legend(order(1 "Treatment" 2 "Control") col(2))  ///
	  title("Image/Text Price")  ///
	  ytitle("Mean Outcome")  ///
	  xsize(4) ysize(3) ///
	  scheme(s1color)
	  
graph twoway (line ln_pcall_price month if label == "年度好大夫") (line ln_pcall_price month if label != "年度好大夫"), ///
	  tline(2019m1,lp(dash)) ///
	  legend(order(1 "Treatment" 2 "Control") col(2))  ///
	  title("Phone-call Price")  ///
	  ytitle("Mean Outcome")  ///
	  xsize(4) ysize(3) ///
	  scheme(s1color)


use "$dta/senior_doctor_with_label.dta", clear
keep if rel >= -5 & rel <= 5
drop if space_id == .
merge 1:m space_id using "$dta/month_login_num.dta"
drop if _merge == 2
drop _merge 
collapse (mean) login_num,by(label month)
graph twoway (line login_num month if label == "年度好大夫") (line login_num month if label != "年度好大夫"), ///
	  tline(2019m1,lp(dash)) ///
	  legend(order(1 "Treatment" 2 "Control") col(2))  ///
	  title("Logins")  ///
	  ytitle("Mean Outcome")  ///
	  xsize(4) ysize(3) ///
	  scheme(s1color)


	
	





