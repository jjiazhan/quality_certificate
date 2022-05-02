clear all
set more off

global route "/Users/fuhongqiao/Desktop/北京大学公共卫生学院工作文档/论文发表相关材料/未提交/information disclosure/"


***50人大名单***
use "$route/working_data/name_50.dta",clear
rename 用户名 username

merge 1:1 username using "$route/working_data/doc_1212.dta",gen(merge) keepusing(doc_title doc_gender reg_time doc_city)
drop if merge != 3
drop merge

keep if doc_title == "主任医师" | doc_title == "副主任医师"

gsort 年度好大夫科室 -indexscore 

bysort 年度好大夫科室: gen rank2=_n

drop rank1

merge 1:1 username using "$route/working_data/space_username.dta",gen(_merge)

drop if _merge!=3
drop _merge

merge 1:1 username using  "/Users/fuhongqiao/Desktop/北京大学公共卫生学院工作文档/好大夫相关/年度排行榜2020/科室merge.dta", gen(x) keepusing(省份 市)
drop if x==2

replace 市= doc_city if x == 1
replace 省份 = "上海" if x == 1 & doc_city == "上海"
replace 省份 = "北京" if x == 1 & doc_city == "北京"
replace 省份 = "江苏" if x == 1 & doc_city == "南京"
replace 省份 = "安徽" if x == 1 & doc_city == "合肥"
replace 省份 = "河北" if x == 1 & doc_city == "唐山"
replace 省份 = "江苏" if x == 1 & doc_city == "常州"
replace 省份 = "四川" if x == 1 & doc_city == "成都"
replace 省份 = "江苏" if x == 1 & doc_city == "扬州"
replace 省份 = "浙江" if x == 1 & doc_city == "杭州"
replace 省份 = "浙江" if x == 1 & doc_city == "温州"
replace 省份 = "江苏" if x == 1 & doc_city == "连云港"
replace 省份 = "河南" if x == 1 & doc_city == "郑州"
replace 省份 = "重庆" if x == 1 & doc_city == "重庆"

drop x doc_city

rename 省份 doc_prov
rename 市 doc_city

save "$route/working_data/temp_list.dta",replace /*最终分析的医生名单，不删除*/



****图文问诊数据****
use "$route/working_data/written.dta",clear
rename 医生账号 spaceid
format spaceid %12.0g
merge m:1 spaceid using "$route/working_data/temp_list.dta",gen(merge_list) 
drop if merge_list == 1

merge m:1 username using "$route/working_data/namelist.dta",gen(_merge) keepusing(奖项)
drop if _merge==2
replace 奖项= "X" if _merge==1
drop if 奖项== "县域明星"
drop _merge

replace 年度好大夫科室= "小儿内科" if 年度好大夫科室=="儿内科"
replace 年度好大夫科室= "小儿外科" if 年度好大夫科室=="儿外科"
replace 年度好大夫科室= "呼吸内科" if 年度好大夫科室=="呼吸科"

merge m:1 年度好大夫科室 using "$route/working_data/honor1.dta",gen(_merge)
drop if _merge!=3
drop _merge

order username spaceid 姓名 医院 doc_title doc_prov doc_city reg_time 年度好大夫科室 奖项  indexscore  rank2 quota  患者账号 患者生日  患者性别  患者省  患者市 疾病名称 问诊发起时间  订单类型  是否退单 
sort 年度好大夫科室 rank2

gen gender = "男" if 患者生日=="男"| 患者性别=="男"
replace gender = "女" if 患者生日=="女"| 患者性别=="女"

replace 患者生日 = 患者性别 if gender != 患者性别
replace  患者性别= gender 
drop gender

gen rank_dis= rank2- quota

gen year = substr(问诊发起时间,1,4)
destring year,replace
drop if 问诊发起时间== "" &  merge_list==3
replace year = 2018 if year ==.

gen month=substr(问诊发起时间,6,2)
replace month = substr(month,1,1) if substr(month,2,1)== "/"
destring month,replace
replace month= 7 if month ==.

gen day = substr(问诊发起时间,-8,2)
replace day= "0"+substr(day,-1,1) if substr(day,1,1)== "/"
destring day,replace
replace day = 1 if day==. 

tostring year,gen(year1)
tostring month, gen(month1)
tostring day, gen(day1)
replace month1="0" +month1 if month<10
replace day1="0" +day1 if day<10

gen year_month_date= year1+month1+day1
 gen dis_date1= date( year_month_date,"YMD")
gen temp= "20180701"
gen dis_date2= date( temp,"YMD")
gen datex= dis_date1- dis_date2
gen week_num = int(datex/7)+1

gen number = 1

gen same_prov = 1 if substr(doc_prov,1,6) == substr(患者省,1,6)

collapse (count) number,by(username week_num 订单类型 年度好大夫科室 奖项 rank2 rank_dis quota 姓名 医院 merge_list doc_prov doc_city)

/*
tostring year,gen(year1)
tostring month, gen(month1)
replace month1="0" +month1 if month<10
gen year_month= year1+ month1
encode year_month,gen(y_m)
drop year_month
*/

preserve

keep if merge_list==2
save "$route/working_data/w_图文_non.dta",replace
restore

/*图文问诊周数据*/
preserve

keep if 订单类型== "图文问诊"
append using "$route/working_data/w_图文_non.dta"
replace 订单类型= "图文问诊" if 订单类型== ""

fillin username week_num
gen post= 1 if week>=28 
replace post = 0 if post==.

encode username,gen(ID)

bysort username: egen rank_mean = mean(rank2)
replace rank2 = rank_mean

bysort username: egen quota_mean = mean(quota)
replace quota = quota_mean

replace rank_dis = rank2- quota

encode 奖项,gen(honor)
bysort username: egen honor_mean = mean(honor)
replace honor = honor_mean if 奖项==""

gen treat = 1 if honor == 2
replace treat = 0 if honor == 1
replace number = 0 if _fillin == 1
replace number = 0 if merge_list == 2

rename number number_w_1

label var number_w_1 "图文问诊数量"

save "$route/working_data/图文问诊1_analysis.dta",replace

restore

/*一问一答*/
preserve

keep if 订单类型== "一问一答"
append using "$route/working_data/w_图文_non.dta"
replace 订单类型= "一问一答" if 订单类型== ""

fillin username week_num

gen post= 1 if week>=28 
replace post = 0 if post==.

encode username,gen(ID)

bysort username: egen rank_mean = mean(rank2)
replace rank2 = rank_mean

bysort username: egen quota_mean = mean(quota)
replace quota = quota_mean

replace rank_dis = rank2- quota

encode 奖项,gen(honor)
bysort username: egen honor_mean = mean(honor)
replace honor = honor_mean if 奖项==""

gen treat = 1 if honor == 2
replace treat = 0 if honor == 1
replace number = 0 if _fillin == 1
replace number = 0 if merge_list == 2

rename number number_w_2

label var number_w_2 "一问一答数量"

save "$route/working_data/图文问诊2_analysis.dta",replace

restore

/*义诊*/
preserve

keep if 订单类型== "义诊"
append using "$route/working_data/w_图文_non.dta"
replace 订单类型= "义诊" if 订单类型== ""

fillin username week_num

gen post= 1 if week>=28 
replace post = 0 if post==.

encode username,gen(ID)

bysort username: egen rank_mean = mean(rank2)
replace rank2 = rank_mean

bysort username: egen quota_mean = mean(quota)
replace quota = quota_mean

replace rank_dis = rank2- quota

encode 奖项,gen(honor)
bysort username: egen honor_mean = mean(honor)
replace honor = honor_mean if 奖项==""

gen treat = 1 if honor == 2
replace treat = 0 if honor == 1
replace number = 0 if _fillin == 1
replace number = 0 if merge_list == 2

rename number number_w_3

label var number_w_3 "义诊数量"

save "$route/working_data/义诊_analysis.dta",replace

restore

****电话问诊数据****
use "$route/working_data/tel.dta",clear
rename 医生编号 spaceid
format spaceid %12.0g
merge m:1 spaceid using "$route/working_data/temp_list.dta",gen(merge_list) 
drop if merge_list == 1

merge m:1 username using "$route/working_data/namelist.dta",gen(_merge) keepusing(奖项)
drop if _merge==2
replace 奖项= "X" if _merge==1
drop if 奖项== "县域明星"
drop _merge

replace 年度好大夫科室= "小儿内科" if 年度好大夫科室=="儿内科"
replace 年度好大夫科室= "小儿外科" if 年度好大夫科室=="儿外科"
replace 年度好大夫科室= "呼吸内科" if 年度好大夫科室=="呼吸科"

merge m:1 年度好大夫科室 using "$route/working_data/honor1.dta",gen(_merge)
drop if _merge!=3
drop _merge

 order username spaceid 姓名 医院 doc_title reg_time 年度好大夫科室 奖项  indexscore  rank2 quota  患者生日  患者编号  患者省  患者城市 疾病名称  电话发起时间 是否退单

gen rank_dis= rank2- quota


gen year = substr(电话发起时间,1,4)
destring year,replace
drop if 电话发起时间== "" &  merge_list==3
replace year = 2018 if year ==.
drop if year < 2018

gen month=substr(电话发起时间,6,2)
replace month = substr(month,1,1) if substr(month,2,1)== "/"
destring month,replace
replace month= 7 if month ==.
drop if year == 2018 & month<=6 

gen day = substr(电话发起时间,-8,2)
replace day= "0"+substr(day,-1,1) if substr(day,1,1)== "/"
destring day,replace
replace day = 1 if day==. 

tostring year,gen(year1)
tostring month, gen(month1)
tostring day, gen(day1)
replace month1="0" +month1 if month<10
replace day1="0" +day1 if day<10

gen year_month_date= year1+month1+day1
 gen dis_date1= date( year_month_date,"YMD")
gen temp= "20180701"
gen dis_date2= date( temp,"YMD")
gen datex= dis_date1- dis_date2
gen week_num = int(datex/7)+1

gen number_tel = 1

collapse (count) number,by(username week_num 年度好大夫科室 奖项 rank2 rank_dis quota 姓名 医院 merge_list)


fillin username week_num

/*
decode y_m,gen(year_month)
replace year1 = substr(year_month,1,4) if year1==""
replace month1 = substr(year_month,5,2) if month1 == ""

destring year1,replace
destring month1,replace
*/
gen post= 1 if week>=28 
replace post = 0 if post==.

encode username,gen(ID)

bysort username: egen rank_mean = mean(rank2)
replace rank2 = rank_mean

bysort username: egen quota_mean = mean(quota)
replace quota = quota_mean

replace rank_dis = rank2- quota

encode 奖项,gen(honor)
bysort username: egen honor_mean = mean(honor)
replace honor = honor_mean if 奖项==""

gen treat = 1 if honor == 2
replace treat = 0 if honor == 1
replace number = 0 if _fillin == 1
replace number = 0 if merge_list == 2

label var number_tel "电话周数据"

save "$route/working_data/电话_analysis.dta",replace

****加号服务****
use "$route/working_data/refer.dta",clear
rename 医生编号 spaceid
format spaceid %12.0g
merge m:1 spaceid using "$route/working_data/temp_list.dta",gen(merge_list) 
drop if merge_list == 1

merge m:1 username using "$route/working_data/namelist.dta",gen(_merge) keepusing(奖项)
drop if _merge==2
replace 奖项= "X" if _merge==1
drop if 奖项== "县域明星"
drop _merge

replace 年度好大夫科室= "小儿内科" if 年度好大夫科室=="儿内科"
replace 年度好大夫科室= "小儿外科" if 年度好大夫科室=="儿外科"
replace 年度好大夫科室= "呼吸内科" if 年度好大夫科室=="呼吸科"

merge m:1 年度好大夫科室 using "$route/working_data/honor1.dta",gen(_merge)
drop if _merge!=3
drop _merge

 order username spaceid 姓名 医院 doc_title reg_time 年度好大夫科室 奖项  indexscore  rank2 quota  患者生日  患者编号  患者省  患者城市 预约转诊发起时间

gen rank_dis= rank2- quota


gen year = substr(预约转诊发起时间,1,4)
destring year,replace
drop if 预约转诊发起时间== "" &  merge_list==3
replace year = 2018 if year ==.
drop if year < 2018

gen month=substr(预约转诊发起时间,6,2)
replace month = substr(month,1,1) if substr(month,2,1)== "/"
destring month,replace
replace month= 7 if month ==.
drop if year == 2018 & month<=6 

gen day = substr(预约转诊发起时间,-8,2)
replace day= "0"+substr(day,-1,1) if substr(day,1,1)== "/"
destring day,replace
replace day = 1 if day==. 

tostring year,gen(year1)
tostring month, gen(month1)
tostring day, gen(day1)
replace month1="0" +month1 if month<10
replace day1="0" +day1 if day<10

gen year_month_date= year1+month1+day1
 gen dis_date1= date( year_month_date,"YMD")
gen temp= "20180701"
gen dis_date2= date( temp,"YMD")
gen datex= dis_date1- dis_date2
gen week_num = int(datex/7)+1

gen number = 1

collapse (count) number,by(username week_num  年度好大夫科室 奖项 rank2 rank_dis quota 姓名 医院 merge_list)


fillin username week_num

gen post= 1 if week>=28 
replace post = 0 if post==.

encode username,gen(ID)

bysort username: egen rank_mean = mean(rank2)
replace rank2 = rank_mean

bysort username: egen quota_mean = mean(quota)
replace quota = quota_mean

replace rank_dis = rank2- quota

encode 奖项,gen(honor)
bysort username: egen honor_mean = mean(honor)
replace honor = honor_mean if 奖项==""

gen treat = 1 if honor == 2
replace treat = 0 if honor == 1
replace number = 0 if _fillin == 1
replace number = 0 if merge_list == 2


rename number number_refer
label var number_refer "转诊周数据"

save "$route/working_data/转诊_analysis.dta",replace

use "$route/working_data/图文问诊1_analysis.dta",clear
merge 1:1 username week_num using "$route/working_data/图文问诊2_analysis.dta",gen(x1) keepusing(number_w_2)
merge 1:1 username week_num using "$route/working_data/义诊_analysis.dta",gen(x2) keepusing(number_w_3)
merge 1:1 username week_num using "$route/working_data/电话_analysis.dta",gen(x3) keepusing(number_tel)
merge 1:1 username week_num using "$route/working_data/转诊_analysis.dta",gen(x4) keepusing(number_refer)

drop x1 x2 x3 x4

replace number_w_2= 0 if number_w_2 == .
replace number_w_3= 0 if number_w_3 == .

save "$route/working_data/servce_analysis.dta",replace

merge 1:1 username week_num using "$route/working_data/图文问诊_price",gen(x) keepusing (图文价格)
drop if x==2
drop x

merge 1:1 username week_num using "$route/working_data/一问一答_price",gen(x) keepusing (一问一答价格)
drop if x==2
drop x

merge 1:1 username week_num using "$route/working_data/电话_price",gen(x) keepusing (电话价格)
drop if x==2
drop x

merge 1:1 username week_num using "$route/working_data/on_analysis",gen(x) keepusing (每周登陆次数)
drop if x==2
drop x

merge 1:1 username week_num using "$route/working_data/good_analysis",gen(x) keepusing (number_good)
drop if x==2
drop x


merge 1:1 username week_num using "$route/working_data/bad_analysis",gen(x) keepusing (number_bad)
drop if x==2
drop x

merge 1:1 username week_num using "$route/working_data/图文问诊_local_analysis",gen(x) keepusing (number_w_local)
drop if x==2
drop x

merge 1:1 username week_num using "$route/working_data/图文问诊_nl_analysis",gen(x) keepusing (number_w_nl)
drop if x==2
drop x

merge 1:1 username week_num using "$route/working_data/电话_local_analysis.dta",gen(x) keepusing (number_tel_local)
drop if x==2
drop x


merge 1:1 username week_num using "$route/working_data/电话_nl_analysis.dta",gen(x) keepusing (number_tel_nl)
drop if x==2
drop x

merge 1:1 username week_num using "$route/working_data/written_analysis.dta",gen(x) keepusing (number_wrriten ln_written)
drop if x==2
drop x

save "$route/working_data/analysis.dta",replace


