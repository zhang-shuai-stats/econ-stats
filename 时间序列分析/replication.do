* 不带漂移项的随机游走
clear
set obs 1000
set seed 123456
gen t = _n
gen u = rnormal()
gen yt = sum(u) //假设y0=0
twoway (line yt t) (line u t)