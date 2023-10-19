*打开面板数据
use 路径\面板数据.dta, clear

*根据相同id，将实验组的变量与面板数据匹配（字段join）
joinby id using 实验组.dta

*生成政策实施后的时间虚拟变量，这里先赋值0
gen t = 0

*如果当期时间大于等于政策发生时点，t赋值1，即可构建出政策时间虚拟变量
*注意：始终是非实验组的个体，time应该保持一个很大的数(例如9999)，这样t就一直为0
replace t = 1 if year >= time

*构建实验组*政策时间的交互项
gen did = treated * t