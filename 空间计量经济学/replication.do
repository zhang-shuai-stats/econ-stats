************************************************************************************
*                            空间计量经济学课程代码 
************************************************************************************
#delimit cr
cd /Users/zhangshuai/Desktop/spatial/spatial   // 修改目录
capture log close
set logtype text
log using replication_log.txt, replace
display c(current_time)

version 14.0
clear
set more off 

************************************************************************************
* 					安装工具包INSTALATION OF NECCESARY PACKAGES   			      
************************************************************************************
/*
ssc install spmap
ssc install shp2dta
net install sg162, from(http://www.stata.com/stb/stb60)
net install st0292, from(http://www.stata-journal.com/software/sj13-2)
net install spwmatrix, from(http://fmwww.bc.edu/RePEc/bocode/s)
net install splagvar, from(http://fmwww.bc.edu/RePEc/bocode/s)
ssc install xsmle
*/
* 注意：如果STATA版本为15.0及以上，spmap命令可能无法使用，用grmap替代

************************************************************************************
*        (1) 空间数据的处理MANIPULATION AND GEOVISUALIZATION OF SPATIAL DATA  		  		  
************************************************************************************

* 读取shp格式地图信息 Read the information shape in Stata
shp2dta using nuts2_164, database(data_shp) coordinates(coord) genid(id) genc(c) replace

/* 该命令生成两个文件，data_shp为属性文件，包括每个地区的坐标，编码等信息，coord为地图文件用于显示地图
This command generates two new files: data_shp.dta y coord.dta
The first contains the attributes (variables) of the shape. 
The second contains the information about geographic forms. 
Also, in the data_shp.dta are included three new variables:
id: identify region.
c: generates centroid using: x_c: longitud, y_c: latitud
*/

* 属性文件data_shp
use data_shp, clear
describe

* 显示地图Themeless map (without information)
spmap using coord, id(id) note("Europe, EU15")

* 在属性文件中添加研究变量 Now we include some variables of interes from Eurostat:                       
import excel "migr_unemp07_12.xls", firstrow clear
save "migr_unemp.dta", replace
use migr_unemp
describe

use data_shp, clear
merge 1:1 POLY_ID using migr_unemp
drop _merge 
save migr_unemp_shp.dta, replace

************************************************************************************
* 在地图上展示信息Showing the information using maps
use migr_unemp_shp.dta, clear

* 分位数图Quantile map:
format U2012 %12.1f
spmap U2012 using coord, id(id) clmethod(q) title("Unemployment rate") ///
legend(size(medium) position(5)) fcolor(Blues2) note("Europe, 2012" "Source: Eurostat")         

format NM2012 %12.1f
spmap NM2012 using coord, id(id) clmethod(q) title("Net migration rate") ///
legend(size(medium) position(5)) fcolor(BuRd) note("Europe, 2012" "Source: Eurostat")           

* 等分区间图Equal interval maps
spmap U2012 using coord, id(id) clmethod(e) title("Unemployment rate") ///
legend(size(medium) position(5)) fcolor(Blues2) note("Europe, 2012" "Source: Eurostat")           

spmap NM2012 using coord, id(id) clmethod(e) title("Net migration rate") ///
legend(size(medium) position(5)) fcolor(BuRd) note("Europe, 2012" "Source: Eurostat")           

* 箱线地图Box maps
spmap U2012 using coord, id(id) clmethod(boxplot) title("Unemployment rate") ///
legend(size(medium) position(5)) fcolor(Heat) note("Europe, 2012" "Source: Eurostat")           

spmap NM2012 using coord, id(id) clmethod(boxplot) title("Net migration rate") ///
legend(size(medium) position(5)) fcolor(Rainbow) note("Europe, 2012" "Source: Eurostat")           

graph box U2012
graph box NM2012

* 标准差地图Deviation maps
spmap U2012 using coord, id(id) clmethod(s) title("Unemployment rate") ///
legend(size(medium) position(5)) fcolor(Blues2) note("Europe, 2012" "Source: Eurostat")           

spmap NM2012 using coord, id(id) clmethod(s) title("Net migration rate") ///
legend(size(medium) position(5)) fcolor(BuRd) note("Europe, 2012" "Source: Eurostat")           


* 点面结合图Combination of points and polygons using both variables: 
spmap U2012 using coord, id(id) fcolor(RdYlBu) cln(8) point(data(migr_unemp_shp) xcoord(x_c)  ///
ycoord(y_c) deviation(NM2012) sh(T) fcolor(dknavy) size(*0.3)) legend(size(medium) position(5)) legt(Unemployment) ///
note("Solid triangles indicate values over the mean of net-migration." "Europa, 2012. Source: Eurostat")

spmap NM2012 using coord, id(id) fcolor(RdYlBu) cln(8) diagram(var(U2012) xcoord(x_c) ycoord(y_c) ///
fcolor(gs2) size(1)) legend(size(medium) position(5)) legstyle(3) legt(Net migration) ///
note(" " "Boxes indicate values of unemployment." "Europe, 2012. Source: Eurostat")

*******************************************************************************************
*                              (2) 探索性空间数据分析 ESDA
*         生产空间权重矩阵和空间自相关检验GENERATE W AND SPATIAL AUTOCORRELATION TESTS    	        		  
*******************************************************************************************
use migr_unemp_shp.dta, clear

* 生成邻接权重矩阵，但由于存在5个地区不和其他地区想连接，故不采用此种方法 Problem with conguity criterion: 5 islands.
spmat contiguity Wcontig using "coord.dta", id(id) replace

* 根据最近的五个邻居生产权重矩阵，并且标准化 We choose k-nn: 5 nearest neighbours row-standardized
spwmatrix gecon y_c x_c, wn(W5st) knn(5) row con

* 显示空间权重矩阵Display spatial weight matrix：
* 首先，生产未标准化的空间权重矩阵，并导出为txt。First, we generate W 5nn binary and then we export as txt
spwmatrix gecon y_c x_c, wn(W5bin) knn(5) xport(W5bin,txt) replace

* 其次，读入txt文件 Read the txt file and to adapt format for SPMAT
insheet using "W5bin.txt", delim(" ") clear
erase W5bin.txt
drop in 1
rename v1 id

* 最后生成spmat函数能够识别的对象 Generate SPMAT object: W5 row-standardize 
spmat dta W5_st v*, id(id) norm(row) replace
spmat summarize W5_st, links
spmat graph W5_st

* 空间自相关检验：Moran I test, Geary's c test and Getis-Ord G test.
use migr_unemp_shp.dta, clear

spatgsa U2012, w(W5st) moran geary two
spatgsa NM2012, w(W5st) moran geary two
spatgsa U2012, w(W5bin) moran geary go two  
spatgsa NM2012, w(W5bin) moran geary go two

* Moran散点图 Moran's I scatterplot
splagvar U2012, wname(W5st) wfrom(Stata) ind(U2012) order(1) plot(U2012) moran(U2012) replace
splagvar NM2012, wname(W5st) wfrom(Stata) ind(NM2012) order(1) plot(NM2012) moran(NM2012) replace


* 局部Moran散点图 Local Moran I (LISA)
genmsp_v0 U2012, w(W5st)
graph twoway (scatter Wstd_U2012 std_U2012 if pval_U2012>=0.05, msymbol(i) mlabel ///
(id) mlabsize(*0.6) mlabpos(c)) (scatter Wstd_U2012 std_U2012 if pval_U2012<0.05, ///
msymbol(i) mlabel (id) mlabsize(*0.6) mlabpos(c) mlabcol(red)) (lfit Wstd_U2012  ///
std_U2012), yline(0, lpattern(--)) xline(0, lpattern(--)) xlabel(-1.5(1)4.5,     ///
labsize(*0.8)) xtitle("{it:z}") ylabel(-1.5(1)3.5, angle(0) labsize(*0.8))      ///
ytitle("{it:Wz}") legend(off) scheme(s1color) title("Local Moran I of Unemployment rate")

spmap msp_U2012 using coord, id(id) clmethod(unique) title("Unemployment rate")   ///
legend(size(medium) position(4)) ndl("No signif.") fcolor(blue red)               ///
note("Europe, 2012" "Source: Eurostat") 

************************************************************************************
*                      (3) 空间截面模型 BASIC SPATIAL ECONOMETRICS             	  		  
************************************************************************************

**************************************
* 根据OLS回归结果构建LM估计量进行空间检验
* OLS estimation
use migr_unemp_shp, clear
reg U2012 NM2012

* 空间检验Spatial tests
spwmatrix gecon y_c x_c, wn(W5st) knn(5) row
spatdiag, weights(W5st)

*************************************************************************
* 采用极大似然法估算法估算空间模型 Spatial models using Maximum Likelihood (ML)
use migr_unemp_shp, clear

* OLS estimation
reg U2012 NM2012
estimates store ols

* 空间自回归模型 Spatial Lag Model (SLM) with W5_st spmat object
spreg ml U2012 NM2012, id(id) dlmat(W5_st)
estimates store SLM_ml

* 空间误差模型 Spatial Error Model (SEM)
spreg ml U2012 NM2012, id(id) elmat(W5_st)
estimates store SEM_ml

* 空间自相关模型 Spatial autocorrelation SARAR model: combine SLM-SEM
spreg ml U2012 NM2012, id(id) dlmat(W5_st) elmat(W5_st)
estimates store SARAR_ml

* 空间杜宾模型 Spatial Durbin model (SDM)
spmat lag wx_NM2012 W5_st NM2012

spreg ml U2012 NM2012 wx_NM2012, id(id) dlmat(W5_st)
estimates store SDM_ml

* Cliff-Ord model
spreg ml U2012 NM2012 wx_NM2012, id(id) dlmat(W5_st) elmat(W5_st)
estimates store CLIFF_ml

estimates table ols SLM_ml SEM_ml SARAR_ml SDM_ml CLIFF_ml, b(%7.2f) star(0.1 0.05 0.01)
* Others alternative commands: "spmlreg" de Jeanty o "spatreg" de Pisati

************************************************************************************
* 采用IV-GMM法估算法估算空间模型
* Spatial model using Instrumental Variables / Generalized method of moments(IV-GMM)
use migr_unemp_shp, clear

* OLS estimation
reg U2012 NM2012
estimates store ols

* Spatial Lag Model (SLM)
spivreg U2012 NM2012, dl(W5_st) id(id)
estimates store SLM_IV

* SLM could be estimated using habitual commands in Stata
spmat lag wx_U2012 W5_st U2012
spmat lag wx_NM2012 W5_st NM2012
spmat lag wx2_NM2012 W5_st wx_NM2012
ivregress 2sls U2012 NM2012 (wx_U2012 = wx_NM2012 wx2_NM2012)

* Spatial Error Model (SEM)
spivreg U2012 NM2012, el(W5_st) id(id)
estimates store SEM_IV

* SARAR Model
spivreg U2012 NM2012, dl(W5_st) el(W5_st) id(id)
estimates store SARAR_IV

* Spatial Durbin Model (SDM)
spivreg U2012 NM2012 wx_NM2012, dl(W5_st) id(id)
estimates store SDM_IV
ereturn list

* Same result of SDM using ivregress:
spmat lag wx3_NM2012 W5_st wx2_NM2012
ivregress 2sls U2012 NM2012 wx_NM2012 (wx_U2012 = wx2_NM2012 wx3_NM2012)

* Cliff-Ord Model
spivreg U2012 NM2012 wx_NM2012, dl(W5_st) el(W5_st) id(id)
estimates store CLIFF_IV

estimates table ols SLM_IV SEM_IV SARAR_IV SDM_IV CLIFF_IV, b(%7.2f) star(0.1 0.05 0.01)


************************************************************************************
* 空间效应的估算Interpretation of spatial estimation

* 空间滞后模型的极大似然估计 Remembering the SLM estimated under ML
use migr_unemp_shp, clear
spreg ml U2012 NM2012, dl(W5_st) id(id)

* 用MATA对系数和空间权重矩阵运算，求直接效应和溢出效应 Read W and betas in MATA language 
spmat getmatrix W5_st W
mata:
b = st_matrix("e(b)")
b
lambda = b[1,3]
lambda
S = luinv(I(rows(W))-lambda*W)
end

* 总效应Total effects
mata: (b[1,1]/rows(W))*sum(S)
* 直接效应Direct effects
mata: (b[1,1]/rows(W))*trace(S)
* 溢出效应Indirect effects (spatial spillovers)
mata: (b[1,1]/rows(W))*sum(S) - (b[1,1]/rows(W))*trace(S)


************************************************************************************
*                     (3) 空间面板模型ADVANCED SPATIAL ECONOMETRICS             	  		  
************************************************************************************
use migr_unemp_shp, clear

* 改变数据布局 Reshaping format: from wide to long format
reshape long NM U, i(id) j(year)

xtset id year
xtdes

************************************************************************************
* 静态空间面板 STATIC MODELS
************************************************************************************

* SLM model
xsmle U NM, fe wmat(W5_st) mod(sar) hausman effects
estimates store SLM_fe 

* SEM model
xsmle U NM, fe emat(W5_st) mod(sem) hausman
estimates store SEM_fe 

* SARAR model
xsmle U NM, fe wmat(W5_st) emat(W5_st) mod(sac) effects
estimates store SARAR_fe 

* SDM model
xsmle U NM, fe type(ind) wmat(W5_st) mod(sdm) hausman effects
estimates store SDM_fe 

capture mata: mata drop __000003
estimates table SLM_fe SEM_fe SARAR_fe SDM_fe, b(%7.2f) star(0.1 0.05 0.01) statistics(aic)


************************************************************************************
* 动态空间面板 DYNAMIC MODELS
************************************************************************************
use migr_unemp_shp, clear
reshape long NM U, i(id) j(year)
xtset id year

* dynSLM model (named as SAR)
xsmle U NM, dlag(1) fe wmat(W5_st) type(ind) mod(sar) effects nsim(499)
estimates store dynSLM_1 
xsmle U NM, dlag(2) fe wmat(W5_st) type(ind) mod(sar) effects nsim(499)
estimates store dynSLM_2
xsmle U NM, dlag(3) fe wmat(W5_st) type(ind) mod(sar) effects nsim(499)
estimates store dynSLM_3
estimates table dynSLM_1 dynSLM_2 dynSLM_3, b(%7.2f) star(0.1 0.05 0.01) statistics(aic)


************************************************************************************
erase migr_unemp_shp.dta
erase migr_unemp.dta
erase data_shp.dta
erase coord.dta

display c(current_time)
log close
exit, clear



