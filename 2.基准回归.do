*城市层面DID回归（基础回归）：
*定义两个全局暂元，储存要回归的变量
global firmvar1 pgdp pop ind urb es
global firmvar2 citywage pop pgdp rsc

*两组模型，第一组y是城市碳排放，第二组y是城市就业
*都使用了高维回归命令reghdfe，也可以用面板回归xtreg
reghdfe co2 citylccpost $firmvar1, absorb(城市 年度) vce(cluster 城市)
reghdfe citylabor citylccpost $firmvar2, absorb(城市 年度) vce(cluster 城市)



*企业层面DID回归（基础回归）：
*企业层面的控制变量，全局暂元储存
global firmvar wage size lev ser tax grow roa

*两组DID，一组有控制变量，一组没有控制变量（作为对照）
reghdfe labor lccpost, absorb(id year) vce(cluster id)
reghdfe labor lccpost $firmvar, absorb(id year) vce(cluster id)