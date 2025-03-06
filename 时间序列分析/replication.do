*******************
* 不带漂移项的随机游走
*******************
clear
set obs 1000
set seed 123456
gen t = _n
gen u = rnormal()
gen yt = sum(u) //假设y0=0
twoway (line yt t) (line u t)

*******************
* 带漂移项的随机游走
*******************
clear
set obs 100
set seed 123456
gen t = _n
gen u = rnormal() + 2 
gen yt = sum(u) //假设y0=0 delta = 2
twoway (line yt t) (line u t)

*******************
* 平稳随机过程
*******************
clear
set obs 1000
set seed 123456
gen t = _n
tsset t 
gen u = rnormal() 
gen yt1 = u
gen yt2 = u
forvalues i = 2/`=_N' {
    replace yt1 = 0.8*yt1[_n-1] + u in `i'  //假设y0=0 rho = 0.8
   * replace yt2 = 0.2*yt2[_n-1] + u in `i'  //假设y0=0 rho = 0.2
}
* twoway (line yt1 t) (line yt2 t) (line u t)
twoway (line yt1 t)  (line u t)

*******************
* 确定性趋势
*******************
clear
set obs 1000
set seed 123456
gen t = _n
tsset t 
gen u = rnormal() 
gen y = 1 + 0.5*t + u
twoway (line y t)  (line u t)

**************************
* 带漂移和确定性趋势的随机游走
*************************
clear
set obs 500
set seed 123456
gen t = _n
tsset t 
gen u = rnormal() 
gen dy = 1 + 0.5*t + u
gen y = sum(dy)
twoway (line y t)  (line u t)

**************************
* 含平稳AR(1)成分的确定性趋势
**************************
clear
set obs 1000
set seed 123456
gen t = _n
tsset t 
gen u = rnormal() 
gen y = u
forvalues i = 2/`=_N' {
    replace y = 1 + 0.5*t + 0.8*y[_n-1] + u in `i'  
}
egen my = mean(y)
gen y1 = y - my
twoway (line y t)  (line u t)
twoway (line y1 t)  (line u t)

***************************
* 谬误回归
**************************
clear
set obs 500
set seed 123456
gen u = rnormal()
gen v = rnormal()
gen y = sum(u)
gen x = sum(v)
reg y x 
reg u v

**************************
* 自相关图correlogram
**************************
clear
set obs 500
set seed 123456
gen t = _n
tsset t
gen u = rnormal()  // 白噪声 
gen y = sum(u)  // 随机游走
gen yt = 1 + 0.5*t + u // 确定性趋势
gen y1 = u 
gen y2 = u 
gen yt1 = u  
gen yt2 = u 
gen yt3 = u 
forvalues i = 2/`=_N' {
    replace y1 = 1 + y1[_n-1] + u in `i'  // 带漂移项的随机游走
    replace y2 = 1 + 0.5*t + y2[_n-1] + u in `i'  // 带漂移项和确定趋势的随机游走
    replace yt1 = 0.8*yt1[_n-1] + u in `i'    // 平稳随机过程
    replace yt2 = 1 + 0.8*yt1[_n-1] + u in `i'   // 带漂移项的平稳随机过程
    replace yt3 = 1 + 0.5*t + 0.8*yt1[_n-1] + u in `i'   // 带漂移项和确定性趋势的平稳随机过程
}

corrgram u, lags(20)  // 白噪声 
corrgram y, lags(20)  // 随机游走
corrgram y1, lags(20)  // 带漂移项的随机游走
corrgram y2, lags(20)  // 带漂移项和确定趋势的随机游走
corrgram yt, lags(20)  // 确定性趋势
corrgram yt1, lags(20) // 平稳随机过程
corrgram yt2, lags(20) // 带漂移项的平稳随机过程
corrgram yt3, lags(20) //  带漂移项和确定性趋势的平稳随机过程

* 自相关图的真实案例
cd /Users/zhangshuai/Desktop/time
use gdp, clear
gen yq = yq(year, quarter) // 生成日期
format %tq yq
tsset yq
gen lgdp = log(gdp)
corrgram lgdp, lags(20)

**************************
* DF,ADF 检验
**************************
* DF检验
dfuller lgdp, regress noconstant  
reg d.lgdp l.lgdp, noconstant
dfuller lgdp, regress drift
dfuller lgdp, regress trend

* ADF检验
dfuller lgdp, regress trend lags(4)

* gdp差分的检验
dfuller d.lgdp, noconstant
dfuller d.lgdp, drift 
dfuller d.lgdp, trend 

* gdp差分的图
line d.lgdp yq, yline(0)

* 趋势平稳的残差
reg lgdp yq
predict res, residual
dfuller res, drift
dfuller res, trend
twoway (line d.lgdp yq)  (line res yq), yline(0)

**************************
* 协整
************************** 
gen ldpi = log(dpi)
gen lpce = log(pce)
reg lpce ldpi
predict res1, residual
dfuller res1, noconstant
dfuller res1, drift lags(4)
dfuller res1, trend lags(4)

egranger lpce ldpi
egranger lpce ldpi, trend
egranger lpce ldpi yq

**************************
* 协整与ECM
************************** 
* 第一步：协整回归
reg lpce ldpi yq
predict res2, residual

* 第二步ecm
reg d.lpce d.ldpi l.res2

* 直接使用
egranger lpce ldpi, ecm trend

**************************
* 例子：美国消费者价格指数（cpi）
************************** 
line cp yq
corrgram cp, lags(20)
dfuller cp, regress drift
dfuller cp, regress trend
dfuller cp, regress trend lags(1)

line d.cp yq
corrgram d.cp, lags(20)
dfuller d.cp,  drift
dfuller d.cp,  trend
dfuller d.cp,  trend lags(1)

**************************
* 例子：三月期和六月期国债
************************** 
use debt, clear
gen ym = ym(year, month) // 生成日期
format %tm ym
tsset ym

twoway (line tb6m ym)  (line tb3m ym)

egranger tb6m tb3m
reg tb6m tb3m
egranger tb6m tb3m, ecm


*******************
* ar(1)随机过程
*******************
clear
set obs 500
set seed 123456
gen t = _n
tsset t
gen u = rnormal()  // 白噪声 
gen ar = 1
gen ma = 1
gen arma = 1
forvalues i = 2/`=_N' {
    replace ar = 1 + 0.5*(ar[_n-1]-1) + u in `i'  // ar1
    replace ma = 1 + 0.5*u + 0.2*u[_n-1] in `i'  // ma1
    replace arma = 1 + 0.5*(ar[_n-1]-1) + 0.5*u + 0.2*u[_n-1] in `i' // arma(1,1)
}
twoway (line ar t) (line ma t) (line arma t) , yline(1)

ac ar, lags(20)
pac ar, lags(20)
ac ma, lags(20)
pac ma, lags(20)
ac arma, lags(20)
pac arma, lags(20)

**************************
* 美国gdp的arima识别
**************************
use gdp, clear
gen yq = yq(year, quarter) // 生成日期
format %tq yq
tsset yq
gen lgdp = log(gdp)

* gdp差分的检验
dfuller d.lgdp, noconstant
dfuller d.lgdp, drift 
dfuller d.lgdp, trend 

ac d.lgdp, lags(20)
pac d.lgdp, lags(20)