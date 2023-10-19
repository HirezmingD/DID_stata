*稳健性检验1：缩尾控制

****************************分割线******************************

*需要使用第三方命令winsor2进行数据缩尾处理，安装代码：
ssc install winsor2,replace
*winsor2命令具体语法应用如下：
winsor2 varlist ,cut(1 99)
*varlist为要进行数据缩尾的变量；
*cut(1 99)：保留1%~99%的观测值
*该命令会默认生成新的变量varlist_w来存储缩尾处理后的数据

****************************分割线******************************

*为了减少极端值对数据分析的影响，通常我们需要对数据进行缩尾处理，即删除掉变量中非常大或非常小的数值。
*原文：对研究样本分别截尾1%和5%后（剔除极端值），重新进行回归。看did交互项的显著结果，并与基准回归比较。

winsor2 varlist ,cut(1 99) replace
*前后缩尾1%；replace：将缩尾处理后的数据替换原始数据（就不会生成新变量）

winsor2 varlist,cut(1 99) trim 
*trim：把被缩尾掉的数值替换成缺失值"."
*默认生成新的变量varlist_tr来存储缩尾处理后的数据

winsor2 varlist ,cut(1 99) trim replace
*缩尾处理后替换原始数据(不生成新变量)，被缩尾掉的值替换为缺失值"."
*例如，我需要删除census数据集中pop变量中大于90%和小于10%的值，同时保持所有变量观测值数量的一致性，具体操作如下：

sysuse census,clear  //调用census数据集
winsor2 pop ,cut(10 90) trim replace //缩尾并替换为缺失值
drop if missing(pop)   //把pop变量存在缺失值的所有行删除掉


****************************分割线******************************

*稳健性检验2：时间趋势控制
*加入城市基准因素与时间趋势的交互项，排除这些特征变量的时间趋势导致的差异。
*基准因素包括城市是否属于"两控区"、是否为省会、是否为经济特区、是否位于胡焕庸线东侧等
*控制了时间趋势的交互项后，还是看did交互项的系数显不显著

*时间趋势项的控制方法：

*在回归中加入c.变量#c.year (注意：单独的c.year和i.year会产生多重共线性问题)

reghdfe labor lccpost $firmvar c.两控区#c.year, absorb(id year) vce(cluster id)
reghdfe labor lccpost $firmvar c.省会城市#c.year, absorb(id year) vce(cluster id)
reghdfe labor lccpost $firmvar c.经济特区城市#c.year, absorb(id year) vce(cluster id)
reghdfe labor lccpost $firmvar c.是否胡焕庸线以东#c.year, absorb(id year) vce(cluster id)
reghdfe labor lccpost $firmvar c.两控区#c.year c.省会城市#c.year c.经济特区#c.year ///
c.胡焕庸线以东#c.year, absorb(id year) vce(cluster id)

*个体固定效应与时间趋势的交互项：
reghdfe y did x* i.id#c.year, absorb(id year) vce(cluster id)


****************************分割线******************************


*稳健性检验3：竞争性政策控制
*原文：两个可能影响样本期间企业就业的试点政策《国家发展改革委关于推进国家创新型城市试点工作的通知》《关于执行大气污染物特别排放限值的公告》，即创新型城市试点和重点控制区

reghdfe labor lccpost $firmvar 创新型城市试点did, absorb(id year) vce(cluster id)
reghdfe labor lccpost $firmvar 重点控制区did, absorb(id year) vce(cluster id)
reghdfe labor lccpost $firmvar 创新型城市试点did 重点控制区did 政策态度 总量指数得分 ///
, absorb(id year) vce(cluster id)
reghdfe labor lccpost $firmvar 创新型城市试点did 重点控制区did 政策态度 人均得分 ///
, absorb(id year) vce(cluster id)
reghdfe labor lccpost $firmvar 创新型城市试点did 重点控制区did 政策态度 单位面积得分 ///
, absorb(id year) vce(cluster id)
reghdfe labor lccpost $firmvar 政策态度, absorb(id year) vce(cluster id)
reghdfe labor lccpost $firmvar 总量指数得分, absorb(id year) vce(cluster id)
reghdfe labor lccpost $firmvar 人均得分, absorb(id year) vce(cluster id)
reghdfe labor lccpost $firmvar 单位面积得分, absorb(id year) vce(cluster id)


****************************分割线******************************


*稳健性检验4：倾向性得分匹配PSM
*还没学会，学会后来补