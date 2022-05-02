/* -----------------------------------------------------------------------------
AUTHOR: JIAJIA ZHAN (j.zhan21@imperial.ic.uk)
DATE:   04/12/2022
Aim:    data analysis: description and regression 
----------------------------------------------------------------------------- */

{ /* 0. Analysis Sample */
	use "$dta/senior_doctor_with_label.dta", clear
	drop if rel > quota
	
	drop if doc_id == . // 需要figure out 缺失的情况以及补回
	
	/* construct physician week panel (2018w31-2019w26: 48 week) */
	expand 48
	bys doc_id: gen week = w(2018w31) + _n - 1
	format week %tw
	tsset doc_id week 
	
	/* define treatment period: Excellent Doc released at Jan 6, 2019 */
	gen post = cond(tin(2019w2, 2019w26),1,0) 
	label var post "treatment period (=1)"


	order doc_account doc_id week 
	gsort doc_dep_H rank
	
	
	/* merge outcome variables in physician week level */
	merge 1:1 doc_id week using "$dta/week_pure_demand.dta"
	drop if _merge == 2 // 是否可以把 _merge == 1 理解为当周没有任何订单？
	drop _merge 
	mvencode demand_*, mv(0) override
	
	merge 1:1 doc_id week using "$dta/week_realized_demand.dta"
	drop if _merge == 2
	drop _merge 
	mvencode redemand_*, mv(0) override
	
	merge 1:1 doc_id week using "$dta/week_price_by_services.dta"
	drop if _merge == 2
	drop _merge 
	
	merge 1:1 doc_id week using "$dta/week_waiting_time.dta"
	drop if _merge == 2
	drop _merge 
	
	merge 1:1 doc_id week using "$dta/week_pcall_respone_length.dta"
	drop if _merge == 2
	drop _merge
	
	merge 1:1 doc_id week using "$dta/week_register_wait_day.dta"
	drop if _merge == 2
	drop _merge 
	
	merge 1:1 doc_id week using "$dta/week_login_num.dta"
	drop if _merge == 2
	drop _merge 

	merge 1:1 doc_id week using  "$temp/week_online_service_fb.dta"
	drop if _merge == 2
	drop _merge 
	mvencode posrw_num negrw_num negrw, mv(0) override
	
	merge 1:1 doc_id week using "$temp/week_offline_service_fb.dta"
	drop if _merge == 2
	drop _merge
	mvencode attitude_rating outcome_rating, mv(0) override
	
	save "$dta/analysis_sample.dta", replace 
}	


{ /* 1. Summary Statistics */
	* patient level 
	use "$dta/senior_doctor_with_label.dta", clear
	drop if rel > quota		
	drop if doc_id == .
	merge 1:m doc_id using "$dta/transaction_level_data.dta", keepusing(pat_male pat_birth pat_id req_time dateoftime)
	drop if _merge == 2
	drop _merge 
	
	*处理年龄变量
	gen pat_birth_year = substr(pat_birth,-4,4)
	replace pat_birth_year = "." if pat_birth == "不详" | pat_birth == ""
	replace pat_birth_year = substr(pat_birth,1,4) if regexm(pat_birth_year,"-") == 1
	replace pat_birth_year = "1963" if pat_birth == "0063"
	replace pat_birth_year = "1970" if pat_birth == "0070"
	destring pat_birth_year, replace 
	gen req_year = year(dateoftime)
	gen pat_age = req_year-pat_birth_year+1
	winsor2 pat_age
	sum pat_age_w

	estpost summarize pat_male pat_age_w, detail
	
	esttab using "$esttab/summary_statistics.tex", ///
		cells("mean(fmt(2) p50(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2)))")  ///
		noobs compress fragment width(\hsize)  label ///
		replace
	
	* physician level
	use "$dta/senior_doctor_with_label.dta", clear
	drop if rel > quota	
	local varlist "doc_male doc_age doc_phd doc_reg_year doc_hotindex doc_hits score rank"
	estpost summarize `varlist', detail
	esttab using "$esttab/summary_statistics.tex", ///
		cells("mean(fmt(2)) p50(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2)))")  ///
		noobs compress fragment width(\hsize)  label ///
		booktabs page width(\hsize)	replace 
		
	local varlist "doc_male doc_age doc_phd doc_reg_year doc_hotindex doc_hits score rank"
	estpost ttest `varlist', by(treated)
	esttab using "$esttab/summary_statistics.tex", ///
		cells("N_1 mu_1(fmt(3)) N_2 mu_2(fmt(3)) b(star fmt(3))") starlevels(* 0.10 ** 0.05 *** 0.01) ///
		mgroups("Non Excellent Doctor" "Excellent Doctor" "Diff", pattern(1 0 1 0 1) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
		noobs compress append title(Summary Statistics) ///
		booktabs page width(\hsize)	replace 		

	use "$dta/analysis_sample.dta", clear 
	
	local varlist "posrw_num negrw_num negrw attitude_rating outcome_rating"
	estpost summarize `varlist', detail
	esttab using "$esttab/summary_statistics.tex", ///
		cells("mean(fmt(2)) p50(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2))") ///
		noobs compress append title(Summary Statistics) ///
		booktabs page width(\hsize)	replace addnote()	
	
	
	use "$dta/senior_doctor_with_label.dta", clear
	drop if rel > quota	 	
	local varlist "doc_male doc_age doc_phd doc_reg_year doc_hotindex doc_hits score rank"
	estpost ttest `varlist' if rel <=5 & rel >= -4, by(treated)
	esttab using "$esttab/summary_statistics.tex", ///
		cells("N_1 mu_1(fmt(3)) N_2 mu_2(fmt(3)) b(star fmt(3))") starlevels(* 0.10 ** 0.05 *** 0.01) ///
		mgroups("Non Excellent Doctor" "Excellent Doctor" "Diff", pattern(1 0 1 0 1) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
		noobs compress append title(Summary Statistics) ///
		booktabs page width(\hsize)	replace 
}




/* RD packages:

* local polynominal (continuity assumption)
net install rdrobust, from(https://raw.githubusercontent.com/rdpackages/rdrobust/master/stata) replace
net install rddensity, from(https://raw.githubusercontent.com/rdpackages/rddensity/master/stata) replace
* local randomization assumption
net install rdlocrand, from(https://raw.githubusercontent.com/rdpackages/rdlocrand/master/stata) replace

*/

use "$dta/analysis_sample.dta", clear
replace rel = rel-1 if label == "年度好大夫" 

/* RD plot */
* first restrict our data to post-treatment period 
keep if post == 1
gen ln_demand_online = log(demand_online+1)

{/* Demand Effect */
	rdplot demand_all rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota",size(*1.1)) ///
				title("All Orders",size(*1.2)))
	graph save "$gph/demand_all.gph", replace

	rdplot demand_online rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota",size(*1.1)) ///
				title("Online Services Orders",size(*1.2)))	
	graph save "$gph/demand_online.gph", replace
				
	rdplot demand_wr rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota") ///
				title("Written Consul. Orders",size(*0.8)))
	graph save "$gph/demand_wr.gph", replace

	rdplot demand_textimage rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota") ///
				title("Text/Image Consul. Orders",size(*0.8)))
	graph save "$gph/demand_textimage.gph", replace
				
	rdplot demand_QA rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota") ///
				title("Q&A Consul. Orders",size(*0.8)))	
	graph save "$gph/demand_QA.gph", replace
				
	rdplot demand_free rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota") ///
				title("Free Consul. Orders",size(*0.8)))	
	graph save "$gph/demand_free.gph", replace

	rdplot demand_pcall rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota") ///
				title("Phone-call Consul. Orders",size(*0.8)))	
	graph save "$gph/demand_pcall.gph", replace
				
	rdplot demand_appoint rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota",size(*1.1)) ///
				title("In-person Visit Scheduling Orders",size(*1.2)))	
	graph save "$gph/demand_appoint.gph", replace

	cd ../gph
	gr combine demand_all.gph demand_online.gph demand_appoint.gph, ///
			row(1) col(3) xsize(12) ysize(4) iscale(1.1) ///
			scheme(s1color)
	graph export ../gph/demand_1.pdf,replace

	gr combine demand_pcall.gph demand_textimage.gph demand_QA.gph demand_free.gph , ///
			row(2) col(2) xsize(16) ysize(16)  iscale(.6) ///
			scheme(s1color)
	graph export ../gph/demand_2.pdf,replace
}	

{/* Realized Demand Effect */
	rdplot redemand_all rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota",size(*1.1)) ///
				title("All Orders (Ans)",size(*1.2)))
	graph save "$gph/redemand_all.gph", replace

	rdplot redemand_online rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota",size(*1.1)) ///
				title("Online Services Orders (Ans)",size(*1.2)))	
	graph save "$gph/redemand_online.gph", replace


	rdplot redemand_wr rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota") ///
				title("Written Consul. Orders (Ans)",size(*1.2)))	
	graph save "$gph/redemand_wr.gph", replace

	rdplot redemand_textimage rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota") ///
				title("Text/Image Consul. Orders (Ans)"))	
	graph save "$gph/redemand_textimage.gph", replace
				
	rdplot redemand_QA rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota") ///
				title("Q&A Consul. Orders (Ans)"))	
	graph save "$gph/redemand_QA.gph", replace
				
	rdplot redemand_free rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota") ///
				title("Free Consul. Orders (Ans)"))	
	graph save "$gph/redemand_free.gph", replace

	rdplot redemand_pcall rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota") ///
				title("Phone-call Consul. Orders (Ans)"))	
	graph save "$gph/redemand_pcall.gph", replace
				
	rdplot redemand_appoint rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota",size(*1.1)) ///
				title("In-person Visit Scheduling Orders (Ans)",size(*1.2)))	
	graph save "$gph/redemand_appoint.gph", replace

	cd ../gph
	gr combine redemand_all.gph redemand_online.gph redemand_appoint.gph, ///
			row(1) col(3) xsize(12) ysize(4) iscale(1) ///
			scheme(s1color)
	graph export ../gph/redemand_1.pdf,replace

	gr combine redemand_pcall.gph redemand_textimage.gph redemand_QA.gph redemand_free.gph , ///
			row(2) col(2) xsize(16) ysize(16) iscale(0.6) ///
			scheme(s1color)
	graph export ../gph/redemand_2.pdf,replace
}	

{/* Price */

	rdplot text_price  rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota",size(*1.1)) ///
				title("Price - Text/Image Consul.",size(*1.2)))
	graph save "$gph/price_textimage.gph", replace
	
	rdplot QA_price  rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota",size(*1.1)) ///
				title("Price - Q&A Consul.",size(*1.2)))
	graph save "$gph/price_QA.gph", replace

	rdplot pcall_price  rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota",size(*1.1)) ///
				title("Price - Phone-call Consul.",size(*1.2)))
	graph save "$gph/price_pcall.gph", replace

	
	cd ../gph
	gr combine price_textimage.gph price_QA.gph price_pcall.gph, ///
			row(1) col(3) xsize(12) ysize(4) iscale(1.1) ///
			scheme(s1color)
	graph export ../gph/price.pdf,replace

}

{/* Waiting Time */ 

	rdplot wait_time_d  rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota",size(*1.1)) ///
				title("General Waiting Time (days).",size(*1.2)))
	graph save "$gph/gen_wt.gph", replace
	
	rdplot pcall_wait_h  rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota",size(*1.1)) ///
				title("Phone-call Waiting Time (hours).",size(*1.2)))
	graph save "$gph/pcall_wt.gph", replace

	rdplot reg_wait_d rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota",size(*1.1)) ///
				title("In-person Visit Scheduling Waiting Time (days).",size(*1.2)))
	graph save "$gph/reg_wt.gph", replace

	
	cd ../gph
	gr combine gen_wt.gph pcall_wt.gph reg_wt.gph, ///
			row(1) col(3) xsize(12) ysize(4) iscale(0.8) ///
			scheme(s1color)
	graph export ../gph/waiting_time.pdf,replace

}	

{/* Behaviors */ 
	rdplot login_num rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota",size(*1.1)) ///
				title("Logins"))
	graph save "$gph/logins.gph", replace

	rdplot pcall_dura_m rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota",size(*1.1)) ///
				title("Phone-call Duration (minutes)"))
	graph save "$gph/pcall_dura.gph", replace

	cd ../gph
	gr combine logins.gph pcall_dura.gph, ///
			row(2) col(1) xsize(5) ysize(8) iscale(1) ///
			scheme(s1color)
	graph export ../gph/behaviors.pdf,replace
}

{/* Feedback */

	rdplot posrw_num rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota",size(*1.1)) ///
				title("# Positive Review"))
	graph save "$gph/posrw_num.gph", replace

	rdplot negrw_num rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota",size(*1.1)) ///
				title("# Negative Review"))
	graph save "$gph/negrw_num.gph", replace
	
	cd ../gph
	gr combine posrw_num.gph negrw_num.gph, ///
			row(1) col(2) xsize(8) ysize(4) iscale(1) ///
			scheme(s1color)
	graph export ../gph/onlineservice_fb.pdf,replace	
	
	rdplot gift_num rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota",size(*1.1)) ///
				title("# Gifts"))
	graph save "$gph/gift.gph", replace
	graph export ../gph/gifts.pdf,replace

	rdplot attitude_rating rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota",size(*1.1)) ///
				title("Rating of Attitude"))
	graph save "$gph/attitude_rating.gph", replace

	rdplot outcome_rating rel if rel <= 5 & rel >= -5, p(2) nbins(5 5)  ///
			graph_options(graphregion(color(white)) legend(off) ///
				xlabel(-5(1)5) ///
				xtitle("Relative rank to the department-specific quota",size(*1.1)) ///
				title("Rating of Outcome"))
	graph save "$gph/outcome_rating.gph", replace
	
	cd ../gph
	gr combine attitude_rating.gph outcome_rating.gph, ///
			row(1) col(2) xsize(8) ysize(4) iscale(1) ///
			scheme(s1color)
	graph export ../gph/offlineservice_fb.pdf,replace	

}


* RD plot that uses an IMSE-optimal number of evenly-spaced bins
rdplot ln_demand_online rel if rel <= 5 & rel >= -5, binselect(es) p(2) graph_options(graphregion(color(white)) ///
	xtitle(Relative Rank) ytitle(Outcome))	
* RD plot that uses an IMSE-optimal number of qs-spaced bins
rdplot ln_demand_online rel if rel <= 5 & rel >= -5, binselect(qs) p(2) graph_options(graphregion(color(white)) ///
	xtitle(Relative Rank) ytitle(Outcome))	
* RD plot that uses a mimicking variance number of evenly-spaced bins
rdplot demand_online rel if rel <= 5 & rel >= -5, binselect(esmv) p(2) graph_options(graphregion(color(white)) ///
	xtitle(Relative Rank) ytitle(Outcome))	
* RD plot that uses an mimicking variance number of qs-spaced bins
rdplot demand_online rel if rel <= 5 & rel >= -5, binselect(qsmv) graph_options(graphregion(color(white)) ///
	xtitle(Relative Rank) ytitle(Outcome))	

/* Continuity-based RD Approach: local polynomial point estimation */	
rdrobust demand_online rel, kernel(triangular) p(4) bwselect(mserd) scaleregul(1) vce(nncluster doc_id)

rdrobust demand_pcall rel, p(4) kernel(triangular) bwselect(msetwo) scaleregul(0)
local bandwidth = e(h_l)
rdplot demand_pcall rel if abs(rel) <= `bandwidth', p(4) h(`bandwidth') kernel(triangular)	

/* Local Randomization RD Approach: local polynomial point estimation */	


use "$dta/analysis_sample.dta", clear 
gen ln_demand = log(demand_online + 1)
keep if rel <= 10 & rel >= -9
cmogram demand_online rel if post == 1, cut(0) scatter lineat(0) qfitci

preserve 
rdplot ln_demand rel, binselect(es) graph_options(graphregion(color(white)) ///
	xtitle(Relative Rank) ytitle(Outcome))	



collapse (mean) ln_demand,by(rel post treated)

twoway (line ln_demand rel if post == 1)(line ln_demand rel if post == 0), ///
	  tline(0,lp(dash)) 
	  
	  legend(order(1 "Treatment" 2 "Control") col(2))  ///
	  title("Written Consultation Demand")  ///
	  ytitle("Mean Outcome")  ///
	  xsize(4) ysize(3) ///
	  scheme(s1color)

	
	preserve 
	use "$dta/analysis_sample.dta", clear 
	keep if rel <= 5 & rel >= -4
	graph twoway ///
			(kdensity demand_online if label == "年度好大夫" & post == 0, lcolor(maroon) lp(dash)) ///
			(kdensity demand_online if label != "年度好大夫" & post == 0, lcolor(navy) lp(dash)) ///
			(kdensity demand_online if label == "年度好大夫" & post == 1, lcolor(maroon)) ///
			(kdensity demand_online if label != "年度好大夫" & post == 1, lcolor(navy)), ///
			legend(order(1 "excellent doctor - before" 2 "no accolade - before" 3 "excellent doctor - after" 4 "no accolade - after" ) col(2))  ///
			scheme(s1color)
	restore

	preserve 
	keep if post == 1
	graph twoway ///
		(scatter demand_online rel, mcolor(black) xline(0, lcolor(black))), ///
		ytitle("Outcome") xtitle("Relative Rank") ///
		scheme(s1color)
	restore
	
	keep if post == 1
	
	rdplot demand_all rel, binselect(es) ci(95)
	
	rdplot demand_all rel, binselect(qsmv)
	
	rdplot demand_all rel, binselect(es) ///
		graph_options(graphregion(color(white)) ///
		xtitle("relative rank") ytitle("outcome"))
	
	rdrobust demand_all rel

			demand_online demand_wr demand_textimage demand_QA demand_free demand_pcall demand_appoint
	
	
	
}
