/* -----------------------------------------------------------------------------
AUTHOR: JIAJIA ZHAN (j.zhan21@imperial.ic.uk)
DATE:   04/12/2022
Aim:    data cleaning
----------------------------------------------------------------------------- */


{/*** 1. physicians infomation data ***/

	** 1.1. backgound info of physicians
	use "$src/医生基本信息.dta", clear 
	ren doc_score doc_hotindex
	ren doc_dep_H doc_dep_H_fromdocinfo // used for checking when merging with score data
	destring doc_age doc_hotindex doc_price3 doc_hits hospital_ranking, replace 
	
	save "$dta/doctor_info.dta", replace 
	
	** 1.2. id and username link data (use for linking doc data to transaction data)
	import delimited "$src/space_username.csv", clear
	rename ïspaceid space_id1
	label var space_id1 "doctor_id"
	rename username doc_account 
	label var doc_account "doctor account"
	save "$temp/doctor_id_username.dta", replace 

	use "$src/2021医生信息.dta", clear
	ren 医生用户名 doc_account
	save "$temp/doctor_id_username_new.dta", replace 
}

{/*** 2. physicians scores, rank, and label ***/

	** 2.1. score data of top tail physicians 
	import excel using "$src/年度好大夫100.xlsx", firstrow clear 
	ren 用户名 doc_account 
	ren 年度好大夫科室 doc_dep_H
	ren 姓名 doc_name
	ren 医院 doc_hospital
	ren rank1 rank 
	ren indexscore score 
	save "$temp/doctor_score_100.dta", replace 
	
	** 2.2. physicians with labels
	import excel using "$src/好大夫名单/2018年度好大夫评选规则.xlsx", sheet("2018获奖名单") firstrow clear 
	drop 序号
	ren 用户名 doc_account
	ren 奖项 label
	ren 年度好大夫科室 doc_dep_H_label
	ren 姓名 doc_name
	ren 医院 doc_hospital
	ren 医院科室 doc_dep
	ren 职称 doc_title_label
	ren 省 doc_province
	ren 市 doc_city
	ren 职务 doc_duty
	save "$dta/doctor_label.dta", replace 
	
	** 2.3. match 
	clear all
	* doctor_score_100.dta is our baseline sample (we have to have underlying score data) 
	* Main variables: doc_account, name, hospital,dep_H，score, ranking
	use "$temp/doctor_score_100.dta", clear  
	
	* adding other doc information using doctor_info.dta 
	* (city, dep, gender, age, title, education, hospital_ranking, register)
	* (hotindex, price1-4, hits)
	merge 1:1 doc_account using "$dta/doctor_info.dta"
	drop if _merge == 2
		* check which physicians have missing doctor_info (7 missing, city, gender, age 其实都很好补全)
		list doc_account doc_dep_H doc_name doc_hospital score rank if _merge == 1
		
		* check doctor info variables 
		tab doc_city if _merge == 3,m
		tab doc_dep  if _merge == 3,m
		
		tab doc_gender if _merge == 3,m
		list doc_account doc_dep_H doc_name doc_hospital rank if doc_gender == "" & _merge == 3
		replace doc_gender =  "女" if doc_name == "单卫华" & doc_gender == ""
		replace doc_gender =  "女" if doc_name == "刘嵘" & doc_gender == ""
		replace doc_gender =  "男" if doc_name == "易甫" & doc_gender == ""
		replace doc_gender =  "男" if doc_name == "贺建清" & doc_gender == ""
		replace doc_gender = "女"  if doc_name == "康姚洁" & doc_gender == ""
		replace doc_gender = "男" if doc_name == "魏林" & doc_gender == ""
		replace doc_gender = "男" if doc_name == "丁翔" & doc_gender == ""
		
		codebook doc_age if _merge == 3 
		hist doc_age 
		list doc_age doc_account doc_name doc_dep doc_hospital rank if (doc_age >= 80 | doc_age <= 25) & _merge == 3
		
		tab doc_title if _merge == 3,m
		list doc_account doc_dep_H doc_name doc_hospital rank doc_education if doc_title == "" & _merge == 3		
		
		tab doc_education if _merge == 3,m 
		list doc_account doc_dep_H doc_name doc_hospital rank doc_title if doc_education == "" | doc_education == "未核实"
		
		codebook doc_register if _merge == 3
		
		codebook doc_hotindex doc_price1 doc_price2 doc_price3 doc_price4 doc_hits if _merge == 3
		
		
		
		

		
		
		

	
	

	
	
	
	
	merge 1:1 doc_account using "$dta/doctor_info.dta", keepusing(doc_title)
	keep if _merge != 2
	drop _merge
	merge 1:1 doc_account using "$dta/doctor_label.dta", keepusing(label doc_title_label doc_dep_H_label)
	keep if _merge != 2
	drop _merge 
	replace doc_title = doc_title_label if doc_title_label != ""
	drop doc_title_label
	replace doc_dep_H = doc_dep_H_label if doc_dep_H_label != ""
	drop doc_dep_H_label
	replace doc_dep_H = "小儿外科" if doc_dep_H == "儿外科"
	replace doc_dep_H = "小儿内科" if doc_dep_H == "儿内科"
	replace doc_dep_H = "呼吸内科" if doc_dep_H == "呼吸科"
	replace doc_dep_H = "感染传染科" if doc_dep_H == "感染内科"
	frame put if regexm(doc_title, "主任") == 1, into(senior_doctor)  // 年度好大夫评选范围：副主任医师及以上
	*frame put if regexm(doc_title, "主任") != 1, into(youth_doctor)

		frame change senior_doctor
		drop if doc_dep_H == "/" | doc_dep_H == "其他" 
		drop if doc_dep_H == "辅助诊断科" | doc_dep_H == "放射治疗科"
		tab doc_dep_H if label == "年度好大夫"
		gsort doc_dep_H -score
		drop rank 
		bys doc_dep_H: gen rank = _n

		merge 1:1 doc_account using "$temp/doctor_id_username.dta", gen(merge1) keepusing(space_id1)
		drop if merge1 == 2
		merge 1:1 doc_account using "$temp/doctor_id_username_new.dta", gen(merge2) keepusing(space_id)
		drop if merge2 == 2
		replace space_id1 = space_id if space_id1 == .
		drop space_id
		ren space_id1 doc_id
		tab doc_id,m
		drop merge1 merge2
	

		gsort doc_dep_H rank
		order doc_account doc_id doc_dep_H doc_title doc_name doc_hospital score label

		gen quota = 0
		replace quota = 20 if doc_dep_H == "妇产科"
		replace quota = 15 if doc_dep_H == "皮肤性病科" | doc_dep_H == "泌尿男科" | doc_dep_H == "骨科"
		replace quota = 12 if doc_dep_H == "小儿外科" | doc_dep_H == "小儿内科" | doc_dep_H == "普通外科" 
		replace quota = 10 if doc_dep_H == "肿瘤科" | doc_dep_H == "眼科" | doc_dep_H == "血液科" | ///
							  doc_dep_H == "胸外科" | doc_dep_H == "心血管外科" | doc_dep_H == "心血管内科" | ///
							  doc_dep_H == "消化内科" | doc_dep_H == "肾病内科" | doc_dep_H == "神经外科" | ///
							  doc_dep_H == "神经内科" | doc_dep_H == "烧伤整形科" | doc_dep_H == "内分泌科" | ///
							  doc_dep_H == "口腔科" | doc_dep_H == "精神心理科" | doc_dep_H == "呼吸内科" | ///
							  doc_dep_H == "感染传染科" | doc_dep_H == "风湿免疫科" | doc_dep_H == "耳鼻喉头颈外科"
		replace quota = 5  if doc_dep_H == "中医科" | doc_dep_H == "肝胆外科" 
		replace quota = 3  if doc_dep_H == "器官移植"
		tab quota,m
		gen rel = rank-quota
		
		label var quota "quota cutoff within department"
		label var rel   "relative rank to the quota cutoff"
		*replace rel = rel-1 if label == "年度好大夫"
		
		/* define treated doc */
		gen treated = cond(rel <= 0,1,0)
		label var treated "treated doc (=1)"		
		
		
		merge 1:1 doc_account using "$dta/doctor_info.dta", keepusing(doc_city doc_gender ///
			doc_age doc_score doc_register doc_hits doc_education hospital_ranking)
		drop if _merge == 2
		drop _merge 
		ren doc_score doc_hotindex
		
		label var doc_account "Doctor Username"
		label var doc_id "Doctor ID"
		label var doc_dep_H "Department"
		label var doc_title "Physician Seniority"
		label var doc_name "Physician Name"
		label var doc_hospital "Physician Affiliated Hospital"
		label var doc_city "City of Doctor"
		label var doc_gender "Gender of Doctor"
		label var doc_age "Age of Doctor"
		label var doc_hotindex "Hot index of Doctor"
		label var doc_register "Register time of Doctor"
		label var doc_hits "Clicks of Doctor (thousand)"
		label var doc_education "Edu level of Doctor"
		label var hospital_ranking "Physician Affiliated Hospital Ranking"
		label var score "Underlying Score"
		label var label "prize"
		label var rank "ranking within department"
		label var quota "quota of department"
		label var rel "ranking relative to quota within department"
		
		* 变量与极值处理
		encode doc_dep_H, gen(doc_dep_H_code)
		drop doc_dep_H
		ren doc_dep_H_code doc_dep_H
		
		encode doc_gender, gen(doc_gender_code)
		drop doc_gender
		ren doc_gender_code doc_gender
		replace doc_gender =  1 if doc_name == "单卫华" & doc_gender == .
		replace doc_gender =  1 if doc_name == "刘嵘" & doc_gender == .
		replace doc_gender =  2 if doc_name == "易甫" & doc_gender == .
		replace doc_gender =  2 if doc_name == "贺建清" & doc_gender == .
		
		replace doc_gender = 2 if doc_name == "魏林" & doc_gender == .
		replace doc_gender = 2 if doc_name == "丁翔" & doc_gender == .
		tab doc_gender,m
		gen doc_male = cond(doc_gender == 2,1,0)
		
		gen doc_reg_year = substr(doc_register,1,4)
		destring doc_reg_year, replace 
		
		gen doc_phd = cond(doc_education == "博士",1,0)
		*replace doc_phd = . if doc_education == "未核实" | doc_education == ""
		
		gen chief_doc = cond(doc_title == "副主任医师",0,1)                                                                                                                                                
// 		replace doc_age ==  if doc_name == "徐凯峰"
// 		replace doc_age ==  if doc_name == "柯珮琪"
// 		replace doc_age ==  if doc_name == "纪尧峰"
// 		replace doc_age ==  if doc_name == "穆玉兰"
// 		replace doc_age ==  if doc_name == "刘卓炜"
// 		replace doc_age ==  if doc_name == "张军"	

		replace doc_hits = doc_hits/1000
		
		gsort doc_dep_H rank
		order doc_account doc_id doc_dep_H doc_title doc_name doc_hospital ///
			hospital_ranking doc_city doc_gender doc_male doc_age doc_education doc_phd doc_hotindex doc_register doc_reg_year doc_hits
		
		save "$dta/senior_doctor_with_label.dta", replace // this is the doctor pools that we select sample from
}


{/*** 3. transaction level data of top tail doctors ***/

	{ /* 3.0. clean transaction level data */
	/*
	import excel using "$src/傅博医生数据20201118.xlsx", desc
	return list 
	forvalues sheet = 1/`r(N_worksheet)'{
		import excel using "$src/傅博医生数据20201118.xlsx", sheet(`r(worksheet_`sheet')') firstrow clear
		save "$temp/`r(worksheet_`sheet')'.dta", replace 
	}
	*/

	/* transaction level data by order types */
	use "$temp/1图文.dta", clear
	ren 医生账号 doc_id
	ren 患者账号 pat_id
	ren 患者生日 pat_birth // 需要处理一下异常值
	ren 患者性别 pat_sex
	ren 患者省 pat_prov //需要统一名字
	ren 患者市 pat_city //需要统一名字
	ren 疾病名称 disease
	ren 问诊发起时间 req_time
	ren 订单类型 wr_type
	ren 是否退单 ans

	* dealing with some overlapping problems of pat_sex and pat_birth
	gen pat_male = 1 if pat_birth == "男" | pat_sex == "男"
	replace pat_male = 0 if pat_birth == "女" | pat_sex == "女"
	label var pat_male "患者是否为男性"
	replace pat_birth = pat_sex if pat_birth == "男" | pat_birth == "女" // 需要处理一下异常值
	drop pat_sex 

	generate dateoftime = dofc(req_time)
	format dateoftime %td 
	generate week = wofd(dateoftime)
	format week %tw
	generate month = mofd(dateoftime)
	format month %tm
	save "$dta/transaction_level_wr.dta", replace 


	use "$temp/2电话.dta", clear 
	ren 医生编号 doc_id 
	ren 患者编号 pat_id 
	ren 患者性别 pat_sex 
	ren 患者生日 pat_birth 
	ren 患者省 pat_prov 
	ren 患者城市 pat_city 
	ren 疾病名称 disease 
	ren 电话发起时间 req_time
	ren 通话开始时间 pcall_start
	ren 通话结束时间 pcall_end
	ren 是否退单 ans 

	gen pat_male = 1 if  pat_sex == "男"
	replace pat_male = 0 if  pat_sex == "女"
	label var pat_male "患者是否为男性"
	drop pat_sex 

	gen pcall_wait_h = hours(pcall_start-req_time)  // 需要处理一下异常值
	gen pcall_dura_m = minutes(pcall_end-pcall_start)  // 需要处理一下异常值
	label var pcall_wait_h "电话等待时间（小时）"
	label var pcall_dura_m "电话持续时间（分钟）"

	generate dateoftime = dofc(req_time)
	format dateoftime %td 
	generate week = wofd(dateoftime)
	format week %tw
	generate month = mofd(dateoftime)
	format month %tm

	save "$dta/transaction_level_pcall.dta", replace 


	use "$temp/3加号.dta", clear 
	ren 医生编号 doc_id 
	ren 患者编号 pat_id 
	ren 患者性别 pat_sex 
	ren 患者生日 pat_birth
	ren 患者省 pat_prov
	ren 患者城市 pat_city
	ren 预约转诊发起时间 req_time 
	ren 预约时间 apt_time

	gen pat_male = 1 if  pat_sex == "男"
	replace pat_male = 0 if  pat_sex == "女"
	label var pat_male "患者是否为男性"
	drop pat_sex 

	gen reg_wait_d = dofc(apt_time)-dofc(req_time)
	label var reg_wait_d "预约等待时间（天）"

	generate dateoftime = dofc(req_time)
	format dateoftime %td 
	generate week = wofd(dateoftime)
	format week %tw
	generate month = mofd(dateoftime)
	format month %tm

	save "$dta/transaction_level_regi.dta", replace 


	use "$dta/transaction_level_wr.dta", clear 
	gen order_type = 1
	append using "$dta/transaction_level_pcall.dta"
	replace order_type = 2 if order_type == .
	append using "$dta/transaction_level_regi.dta"
	replace order_type = 3 if order_type == .

	label define order_type_lab 1 "图文" 2 "电话" 3 "加号"
	label values order_type order_type_lab
	label var order_type "订单类型"
	label var wr_type "图文订单类型"
	
	* 处理病人年龄变量
	

	order order_type wr_type req_time dateoftime week month doc_id pat_id pat_birth pat_male pat_prov pat_city disease pcall_start pcall_end pcall_wait_h pcall_dura_m apt_time reg_wait_d ans

	save "$dta/transaction_level_data.dta", replace // this is transaction level data of top tail doctors, in which we can aggregate it into doctor_week level 
	
	}
	
	{ /* 3.1. construct transaction level data to physician week level data */ 
	  *pure demand, realized demand, waiting time and length of phone call, waiting time of appointment*
		
		program compute_demand
		{/* demand - all (图文、电话、加号) - physician week panel */
			preserve
			collapse (count) pat_id, by(doc_id week)
			ren pat_id demand_all 
			order doc_id week demand_all
			save "$temp/week_demand_all.dta", replace 
			restore
		}
		{/* demand - online services (图文、电话) - physician week panel */
			preserve
			drop if order_type == 3
			collapse (count) pat_id, by(doc_id week)
			ren pat_id demand_online
			order doc_id week demand_online
			save "$temp/week_demand_online.dta", replace 
			restore
		}
		{/* demand - online services (图文/一问一答/义诊) - physician week panel */
			preserve
			
			keep if order_type == 1
			collapse (count) pat_id, by(doc_id week wr_type)
			reshape wide pat_id, i(doc_id week) j(wr_type) string
			
			ren pat_id图文问诊 demand_textimage
			ren pat_id一问一答 demand_QA
			
			ren pat_id义诊 demand_free
			egen demand_wr = rowtotal(demand_textimage demand_QA demand_free)
			
			order doc_id week demand_wr demand_textimage demand_QA demand_free		
			save "$temp/week_demand_wr.dta", replace 
			
			restore 		
		}
		{/* demand - online services (电话) - physician week panel */
			preserve
			keep if order_type == 2
			collapse (count) pat_id, by(doc_id week)
			ren pat_id demand_pcall
			order doc_id week demand_pcall
			save "$temp/week_demand_pcall.dta", replace 
			restore
		}	
		{/* demand - appointment services (加号) - physician week panel */
			preserve
			keep if order_type == 3
			collapse (count) pat_id, by(doc_id week)
			ren pat_id demand_appoint
			order doc_id week demand_appoint
			save "$temp/week_demand_appointment.dta", replace 
			restore
		}	
		
		use "$temp/week_demand_all.dta", clear 
		merge 1:1 doc_id week using "$temp/week_demand_online.dta", gen(merge1)
		merge 1:1 doc_id week using "$temp/week_demand_wr.dta", gen(merge2)
		merge 1:1 doc_id week using "$temp/week_demand_pcall.dta", gen(merge3)
		merge 1:1 doc_id week using "$temp/week_demand_appointment.dta", gen(merge4)
		drop merge*
		mvencode demand_*, mv(0)
	end

		use "$dta/transaction_level_data.dta", clear 
	
		{/* Pure demand - physician week panel*/
			preserve
			compute_demand
			label var demand_all "Pure demand of all services"
			label var demand_online "Pure demand of online services"
			label var demand_textimage "Pure demand of text/image consultation"
			label var demand_QA "Pure demand of Q&A consultation"
			label var demand_free "Pure demand of free consultation"
			label var demand_wr "Pure demand of written consultation"
			label var demand_pcall "Pure demand of phone call consultation"
			label var demand_appoint "Pure demand of appointment"		
			save "$dta/week_pure_demand.dta", replace 
			restore 
		}	
		
		{/* Realized demand - physician week panel*/
		
			preserve
			drop if ans == "是"
			compute_demand
			renvarlab demand_*, prefix(re)
			label var redemand_all "Realized demand of all services"
			label var redemand_online "Realized demand of online services"
			label var redemand_textimage "Realized demand of text/image consultation"
			label var redemand_QA "Realized demand of Q&A consultation"
			label var redemand_free "Realized demand of free consultation"
			label var redemand_wr "Realized demand of written consultation"
			label var redemand_pcall "Realized demand of phone call consultation"
			label var redemand_appoint "Realized demand of appointment"		
			save "$dta/week_realized_demand.dta", replace 
			restore 
		}
	
		{/* Waiting Time and Length of Phone Call - physician week level  */
			preserve 
			keep if order_type == 2
			drop if ans == "是"
			collapse (mean) pcall_wait_h pcall_dura_m, by(doc_id week)
			save "$dta/week_pcall_respone_length.dta", replace 
			restore
		}
		
		{/* Waiting time of Appointment -physician week level */
			preserve
			keep if order_type == 3
			collapse (mean) reg_wait_d, by(doc_id week)
			save "$dta/week_register_wait_day.dta", replace 
			restore 
		}

	}

}

{/*** 4. price by types of services - physician level weekly panel ***/

	use "$temp/6每周订单平均价格.dta", clear
	
	gen dateoftime = dofc(周)
	gen week = wofd(dateoftime)
	format week %tw 
	
	* 12/24/2018 与 12/31/2018 同属于一周，处理方式：取平均去掉最后一个
	bysort 医生账号 订单类型 week: egen price = mean(平均价格礼物次数)
	drop if dateoftime == 21549
	
	drop 平均价格礼物次数
	reshape wide price, i(医生账号 week) j(订单类型) string
	ren 医生账号 doc_id 
	ren price一问一答 QA_price
	ren price图文问诊 text_price
	ren price电话咨询 pcall_price
	ren price心意礼物 gift_num
	drop 周
	
	label var doc_id "Doctor ID"
	label var QA_price "Q&A"
	label var text_price "image/text"
	label var pcall_price "phone call"
	label var gift_num "number of gifts"
	order doc_id dateoftime week QA_price text_price pcall_price gift_num 
	save "$dta/week_price_by_services.dta", replace
	
// 	generate month = mofd(dateoftime)
// 	format month %tm
// 	collapse (mean) *_price gift_num, by(doc_id month)
// 	save "$dta/month_price_by_services.dta", replace
}

{/*** 5. logins - physician level weekly panel ***/
	use "$temp/6每周上线次数.dta", clear 
	
	gen dateoftime = dofc(周)
	gen week = wofd(dateoftime)
	format week %tw 
	
	bysort 医生账号 week: egen login_num = mean(每周登陆次数)
	drop if dateoftime == 21549
	drop 每周登陆次数 周
	ren 医生账号 doc_id 
	
	label var doc_id "Doctor ID"
	label var login_num "times of log in"
	
	save "$dta/week_login_num.dta", replace 
	
// 	generate month = mofd(dateoftime)
// 	format month %tm
// 	collapse (mean) login_num, by(space_id month)
// 	save "$dta/month_login_num.dta", replace
}

{/*** 6. waiting time (cover的业务范围是多少？) - physician level weekly panel ***/
	use "$temp/5每周一般等待时长.dta", clear 
	generate dateoftime = dofc(周)
	generate week = wofd(dateoftime)
	format week %tw 
	
	bysort 医生账号 week: egen wait_time = mean(一般等待时长秒)
	drop if dateoftime == 21549
	
	drop 一般等待时长秒
	gen wait_time_d = wait_time/(60*60*24)
	ren 医生账号 doc_id 
	drop 周
	
	label var doc_id "Doctor ID"
	label var wait_time_d "waiting time (days)"
	save "$dta/week_waiting_time.dta", replace 
	
// 	generate month = mofd(dateoftime)
// 	format month %tm
// 	collapse (mean) wait_time_h, by(space_id month)
// 	save "$dta/month_waiting_time.dta", replace 
}

{/*** 7. feedback - physician level weekly panel ***/
	use "$temp/4线上服务评价数据.dta", clear 
	gen dateoftime = dofc(评价时间)
	gen week = wofd(dateoftime)
	format week %tw 
	
	collapse (count) 患者账号, by(医生账号 week 评价)
	reshape wide 患者账号, i(医生账号 week) j(评价) string
	ren 医生账号 doc_id
	ren 患者账号好评 posrw_num
	label var posrw_num "好评数量"
	ren 患者账号差评 negrw_num
	label var negrw_num "差评数量"
	
	replace posrw_num = 0 if posrw_num == .
	replace negrw_num = 0 if negrw_num == .

	gen negrw = 0 
	replace negrw = 1 if negrw_num > 0
	label var negrw "是否有差评"
	
	save "$temp/week_online_service_fb.dta", replace 	

	
	use "$temp/7线下评价数据.dta", clear
	generate dateoftime = dofc(评价时间)
	generate week = wofd(dateoftime)
	format week %tw 
	
	gen attitude_rating = .
	replace attitude_rating = 0 if 态度评分 == "还不知道"
	replace attitude_rating = 1 if 态度评分 == "不满意"
	replace attitude_rating = 2 if 态度评分 == "一般"
	replace attitude_rating = 3 if 态度评分 == "满意"
	replace attitude_rating = 4 if 态度评分 == "很满意"
	gen outcome_rating = .
	replace outcome_rating = 0 if 疗效评分 == "还不知道"
	replace outcome_rating = 1 if 疗效评分 == "不满意"
	replace outcome_rating = 2 if 疗效评分 == "一般"
	replace outcome_rating = 3 if 疗效评分 == "满意"
	replace outcome_rating = 4 if 疗效评分 == "很满意"
	label define rating_lab 0 "还不知道" 1 "不满意" 2 "一般" 3 "满意" 4"很满意"
	label values attitude_rating outcome_rating rating_lab

	drop 疗效评分 态度评分
	ren 医生账号 doc_id
	
	collapse (mean) attitude_rating outcome_rating, by(doc_id week)

	save "$temp/week_offline_service_fb.dta", replace 
}




* ==============================================================================



