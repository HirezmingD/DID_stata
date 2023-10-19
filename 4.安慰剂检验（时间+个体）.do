*安慰剂检验（反事实检验）
*政策的实施时间分别提前2年、3年、4年和5年
*lccpostfalse[1-4]是需要手工准备好的，这里直接用即可
reghdfe labor lccpostfalse1 $firmvar, absorb(id year) vce(cluster id)
reghdfe labor lccpostfalse2 $firmvar, absorb(id year) vce(cluster id)
reghdfe labor lccpostfalse3 $firmvar, absorb(id year) vce(cluster id)
reghdfe labor lccpostfalse4 $firmvar, absorb(id year) vce(cluster id)

*个体安慰剂检验原理

*思路：
*假设总样本280个城市，处理组有71个城市，我们需要从280个城市中随机选取71个城市作为"伪处理组"
*假设这71个城市是试点，其他城市为控制组，然后生成"伪政策虚拟变量"(交互项）进行回归
*重复进行500次，就会得到500次回归结果 (包含"伪政策虚拟变量"估计系数、标准误和p值)
*最后绘制出500个"伪政策虚拟变量"估计系数的分布及相应的p值，直观展示安慰剂检验的结果

*难点：
*如何从280个城市中随机选取71个城市作为"伪处理组"，然后生成"伪政策虚拟变量"?
*因为是面板数据，为了防止重复抽取，先保留一期数据，然后使用sample命令从中随机抽取32个样本
*保留所抽取样本id编号，与原数据进行匹配，最终匹配上的就是我们的"伪处理组"样本，未匹配上是控制组样本
*如何存储500次回归中的估计系数、标准误和p值?
*生成三个500行1列的矩阵 (矩阵中的元素初始值为0)
*分别存储500个"伪政策虚拟变量"的估计系数、标准误和p值。
*每回归一次，就将估计系数、标准误和p值分别存储到三个矩阵的对应位置

*多时点did的个体安慰剂检验代码解析：

*（前提：静态面板，即每期的样本数和变量都相同）

set matsize 5000
mat b = J(500,1,0) //β系数矩阵，500行1列0维，命名为b
mat se = J(500,1,0) //标准误矩阵，命名为se
mat p = J(500,1,0) //p-value矩阵，命名为p

forvalues i=1/500{
	use "数据.dta" , clear 
	xtset city year //面板数据声明
	keep if year==2004 //为防止重复抽取，保留一期数据，这里是2004年
	sample 71, count //设定实验组的样本容量71(可变)
	keep city //抽取时，保留city变量(相当于id，用来匹配的)
	save "atchcity.dta",replace //抽取出的样本及cityid，存入当前文件
	
	*注意：save后，此时的文件不再是"数据.dta"，而是"atchcity.dta"
	
	merge 1:m city using "数据.dta" //基于cityid，1对多，匹配"数据.dta"的数据
	gen groupnew=(_merge==3) //如果两边匹配上，则生成伪实验组的虚拟变量1，没匹配上为0
	
	*_merge==1的观察是仅主库有的，==2的是仅辅助库有的，==3是两个库都有的(匹配成功)
	
	save "matchcity`i'.dta",replace //再保存为一份文件：匹配后、含有伪处理组虚拟变量
		
	*伪政策虚拟变量
	use "数据.dta",clear 
	bsample 1, strata(city) //280个城市分组抽样，每组抽1个城市，代表一个时间节点
	keep year //保留抽取出来的城市的year字段
	save "matchyear.dta", replace //把抽取出来的所有城市及其year字段另存为
	
	mkmat year, matrix(sampleyear) //mkmat向量转化为280行1列的矩阵，只存year，方便调用。
	*mkmat：将数值型变量中的观测值转变为矩阵
	
	*打开我们上一步保存的，匹配后的、含有伪处理组虚拟变量的数据集
	use "matchcity`i'.dta",replace
	xtset city year //面板数据声明
	gen time = 0 //构建政策冲击时点虚拟变量，初始值为0
	foreach j of numlist 1/280 { //对总样本280个城市做循环
		replace time = 1 if (city == `j' & year >= sampleyear[`j',1])
		*对上一步抽样出来的280个时间节点，每期大于该时间节点的，time都赋予1
	}	
	gen did=time*groupnew //政策冲击时点*伪处理组 = 我们想要的反事实交互项did
	
	*基准回归，把系数、标准差、p值全部保存下来
	global xlist  "lnagdp indust_stru finance ainternet market "	
	xtreg entre_activation did  $xlist  i.year, fe robust //也可用高维回归reghdfe
	
	mat b[`i',1] = _b[did] //保存β
	mat se[`i',1] = _se[did] //保存标准误
	scalar df_r = e(N) - e(df_m) -1 //df_r残差自由度，df_m组间自由度，e(N)样本容量
	mat p[`i',1] = 2*ttail(df_r,abs(_b[did]/_se[did])) //ttail:t分布的概率计算，双尾
}

*svmat：从矩阵中创建变量。分别命名为coef、se、pvalue
*将矩阵转化成变量后，"变量名+列排序"，比如我们的矩阵只有一列，所以名字是coef1，se1，pvalue1
svmat b, names(coef)
svmat se, names(se)
svmat p, names(pvalue)

drop if pvalue1 == . //如果p值不存在，删除整行
label var pvalue1 p值 //"label var"定义标签
label var coef1 估计系数

 twoway (scatter pvalue1 coef1,  ///
 xlabel(-0.2(0.05)0.4, grid) yline(0.1,lp(shortdash)) xline(0.2997,lp(shortdash)) ///
 xtitle(估计系数) ytitle(p值) msymbol(smcircle_hollow) mcolor(grey) legend(off)) ///
 (kdensity coef1, title(安慰剂检验))

 *-删除临时文件
forvalue i=1/500{
	*即每次循环生成的500个dta文件。结束后删掉
    erase  "matchcity`i'.dta" 
}