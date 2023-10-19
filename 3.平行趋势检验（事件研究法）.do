*G是实验组变量，一二三期分别是123，非实验组为0
*year是当期年份，policy是政策实施年份，非实验组policy设置为2050
*year是2007-2019年，policy是2010/13/17年，所以实验组event数值是-10到9
*即event是政策前后距离变量
gen event = year - policy if G>0

*合并距离过长的样本：比如政策实施前10年/9年等，统统看作政策执行前4年
replace event = -4 if event <= -4
replace event = 6 if event >= 6

*在上一步中，非实验组也会被赋值，所以这一步排除非实验组（赋空值.）
replace event =. if G==0

*根据政策实施前后距离生成虚拟变量
tab event, gen(eventt)

*在上一步中，非实验组event是空值.，所以生成的虚拟变量也是空值.
*在事件研究法中，也要给非实验组虚拟变量赋予0，因为要参与回归
*循环语句：1/11表示1到11；注意这里引用i，是局部暂元的引用规则 `'
forvalues i = 1/11{
	replace eventt`i' = 0 if eventt`i' == .
}

*避免多重共线性，排除第一个虚拟变量(其实也没必要，回归的时候再去掉也可以)
*eventt*表示所有eventt打头的变量名
drop eventt1
reghdfe labor eventt* $firmvar, absorb(id year) vce(cluster id)