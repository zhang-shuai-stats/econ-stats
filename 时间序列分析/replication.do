* 不带漂移项的随机游走
clear
set obs 1000
set seed 123456
gen t = _n
gen u = rnormal()
gen yt = sum(u) //假设y0=0
twoway (line yt t) (line u t)

* 带漂移项的随机游走
clear
set obs 100
set seed 123456
gen t = _n
gen u = rnormal() + 2 
gen yt = sum(u) //假设y0=0 delta = 2
twoway (line yt t) (line u t)

* 平稳随机过程
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

* 谬误回归
clear
set obs 500
set seed 123456
gen u = rnormal()
gen v = rnormal()
gen y = sum(u)
gen x = sum(v)
reg y x 
reg u v

* 自相关图correlogram
clear
set obs 500
set seed 123456
gen t = _n
tsset t
gen u = rnormal()
corrgram u, lags(20) // 白噪声

gen y = sum(u)  // 随机游走
corrgram y, lags(20)

* 自相关图的真实案例
cd /Users/zhangshuai/Desktop/time
use gdp, clear
gen yq = yq(year, quarter) // 生成日期
format %tq yq
tsset yq
gen lgdp = log(gdp)
corrgram lgdp, lags(20)