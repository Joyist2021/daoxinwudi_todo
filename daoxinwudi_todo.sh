#!/bin/bash
#道心无敌写于2020.11.12，本来是用来自用的，想了想分享一下吧
#这个脚本有一个问题没写，我懒得写了，没有判断系统是centos还是ubuntu
#区别就在于命令是yum还是apt-get,下载的库和位置也略有不同

#11.25添加了备份的功能，备份包括定时循环自动备份的功能（当然本意就是只要这个，不过顺手加了几个删除管理的功能）
#12.3把之前写的检测更新的代码先加进来，保存一下,但是没有加到主循环，也就是不调用，因为写的还有点问题
#12.4把备份和世界检测代码改为了循环脚本形式
#12.13增加了mod配置，优化了echo的格式和颜色，也可以生成多重世界（同时改动生成世界的方式）
#禁止接受ctrl+C，防止这个脚本启动的后台进程在这个脚本ctrl+c的时候一起退出
#使用exit退出即可
trap   ""  INT QUIT  TSTP
needinstall_aptget=(libstdc++6:i386 libgcc1:i386 libcurl4-gnutls-dev:i386 lib32gcc1 lua)
needinstall=(glibc.i686 libstdc++.i686 libcurl4-gnutls-dev.i686 libcurl.i686 lua)
needinstallnum=4
DSTserverFolder=/home/DSTserver
#备份地址和备份数量
backsave_maxnum=0
backsave_location=null
#生成世界用到的几个参数，会在准备阶段赋值一个可用的
archiveLocation=null
server_port=11000
is_master=true
id=1
master_server_port=27018
authentication_port=8768
existedworldname=null
#世界设置的几个固定数组
MasterSetting1=(
"创世界生物群落" "创世界出生点" "创世界大小" "创世界分支" 
"创世界循环" "创世界活动" "秋天" "冬天" 
"春天" "夏天" "起始季节" "昼夜选项"
"世界再生" "疾病" "开始资源多样化" "森林石化" 
"失败的冒险家" "试金石" "野火" "青蛙雨" 
"闪电" "雨"     "花" "草" 
"树苗" "燧石" "尖灌木" "流星频率" 
"流星区域" "芦苇" "矿石" "迷你冰川" 
"所有树" "风滚草"     "浆果丛" "仙人掌" 
"胡萝卜" "蘑菇"     "追猎惊喜" "杀人蜂" 
"皮佛楼牛" "皮佛楼牛交配频率" "蜜蜂","鸟"
"蝴蝶" "秃鹫" "浣猫" "狩猎"
"伏特羊" "鼹鼠" "企鹅" "火鸡"
"猪" "池塘" "兔子" "高脚鸟"
     "蚁狮贡品" "熊獾" "独眼巨鹿" "龙蝇"
"麋鹿鹅" "发条装置" "猎犬丘" "猎犬袭击"
"坎普斯" "树精守卫" "毒桦栗树" "鱼人"
"蜘蛛" "触手" "海象营地"    
)
declare -A MasterSetting2=(
[创世界生物群落]="task_set" #classic经典 default联机版
[创世界出生点]="start_location" #plus额外资源 darkness黑暗 default默认
[创世界大小]="world_size"  #small小 medium中 default大 huge巨大 
[创世界分支]="branching" #never从不 least最少 default most最多 random随机
[创世界循环]="loop" #never从不 default  always总是
[创世界活动]="specialevent" #none无 default自动 hallowed_nights万圣节 winters_feast冬季盛宴 year_of_the_gobbler火鸡之年 year_of_the_varg座狼之年 year_of_the_pig猪王之年 year_of_the_carrat胡萝卜鼠之年
[秋天]="winter"
[冬天]="autumn"
[春天]="spring"
[夏天]="summer" #noseason无 veryshortseason极短 shortseason短 default默认 longseason长 verylongseason极长 random随机
[起始季节]="season_start" #default秋  winter冬 spring春 summer夏  autumnorspring春或秋 winterorsummer冬或夏 random随机
[昼夜选项]="day" #default longday长白天 longdusk长黄昏 longnight长夜晚 noday无白天 nodusk无黄昏 nonight无夜晚 onlyday仅白天 onlydusk仅黄昏  onlynight仅夜晚
[世界再生]="regrowth" #veryslow极慢 slow慢 default fast快  veryfast极快
[疾病]="disease_delay" #none无 random随机 long慢 default short快
[开始资源多样化]="prefabswaps_start" #classic经典 default "highly random"高度随机
[森林石化]="petrification" #none无 few慢 default many多 max很多
[失败的冒险家]="boons"    #never rare default often always
[试金石]="touchstone"
[野火]="wildfires" 
[青蛙雨]="frograin"
[闪电]="lightning"
[雨]="weather"

[花]="flowers" 
[草]="grass" 
[树苗]="sapling" 
[燧石]="flint"
[尖灌木]="marshbush"
[流星频率]="meteorshowers"
[流星区域]="meteorspawner"
[芦苇]="reeds"
[矿石]="rock"
[迷你冰川]="rock_ice"
[所有树]="trees"
[风滚草]="tumbleweed"

[浆果丛]="berrybush"
[仙人掌]="cactus"
[胡萝卜]="carrot"
[蘑菇]="mushroom"

[追猎惊喜]="alternatehunt"
[杀人蜂]="angrybees"
[皮佛楼牛]="beefalo"
[皮佛楼牛交配频率]="beefaloheat"
[蜜蜂]="bees"
[鸟]="birds"
[蝴蝶]="butterfly"
[秃鹫]="buzzard"
[浣猫]="catcoon"
[狩猎]="hunt"
[伏特羊]="lightninggoat"
[鼹鼠]="moles"
[企鹅]="penguins"
[火鸡]="perd"
[猪]="pigs"
[池塘]="ponds"
[兔子]="rabbits"
[高脚鸟]="tallbirds"

[蚁狮贡品]="antliontribute"
[熊獾]="bearger"
[独眼巨鹿]="deerclops"
[龙蝇]="dragonfly"
[麋鹿鹅]="goosemoose"
[发条装置]="chess"
[毒桦栗树]="deciduousmonster"
[猎犬丘]="houndmound"
[猎犬袭击]="hounds"
[坎普斯]="krampus"
[树精守卫]="liefs"
[食人花]="lureplants"
[鱼人]="merm"
[蜘蛛]="spiders"
[触手]="tentacles"
[海象营地]="walrus"
)
declare -A MasterSetting3=(
[task_set]="default" #classic经典 default联机版
[start_location]="default" #plus额外资源 darkness黑暗 default默认
[world_size]="default"  #small小 medium中 default大 huge巨大 
[branching]="default" #never从不 least最少 default most最多 random随机
[loop]="default" #never从不 default  always总是
[specialevent]="default" #none无 default自动 hallowed_nights万圣节 winters_feast冬季盛宴 year_of_the_gobbler火鸡之年 year_of_the_varg座狼之年 year_of_the_pig猪王之年 year_of_the_carrat胡萝卜鼠之年
[winter]="default"
[autumn]="default"
[spring]="default"
[summer]="default" #noseason无 veryshortseason极短 shortseason短 default默认 longseason长 verylongseason极长 random随机
[season_start]="default" #default秋  winter冬 spring春 summer夏  autumnorspring春或秋 winterorsummer冬或夏 random随机
[day]="default" #longday长白天 longdusk长黄昏 longnight长夜晚 noday无白天 nodusk无黄昏 nonight无夜晚 onlyday仅白天 onlydusk仅黄昏  onlynight仅夜晚
[regrowth]="default" #veryslow极慢 slow慢 default fast快  veryfast极快
[disease_delay]="default" #none无 random随机 long慢 default short快
[prefabswaps_start]="default" #classic经典 default "highly random"高度随机
[petrification]="default" #none无 few慢 default many多 max很多
[boons]="default"    #never无 rare较少 default often较多 always很多
[touchstone]="default"
[wildfires]="default" 
[frograin]="default"
[lightning]="default"
[weather]="default"
[flowers]="default" 
[grass]="default" 
[sapling]="default"
[flint]="default"
[marshbush]="default"
[meteorshowers]="default"
[meteorspawner]="default"
[reeds]="default"
[rock]="default"
[rock_ice]="default"
[trees]="default"
[tumbleweed]="default"
[berrybush]="default"
[cactus]="default"
[carrot]="default"
[mushroom]="default"
[alternatehunt]="default"
[angrybees]="default"
[beefalo]="default"
[beefaloheat]="default"
[bees]="default"
[birds]="default"
[butterfly]="default"
[buzzard]="default"
[catcoon]="default"
[hunt]="default"
[lightninggoat]="default"
[moles]="default"
[penguins]="default"
[perd]="default"
[pigs]="default"
[ponds]="default"
[rabbits]="default"
[tallbirds]="default"
[antliontribute]="default"
[bearger]="default"
[deerclops]="default"
[dragonfly]="default"
[goosemoose]="default"
[chess]="default"
[deciduousmonster]="default"
[houndmound]="default"
[hounds]="default"
[krampus]="default"
[liefs]="default"
[lureplants]="default"
[merm]="default"
[spiders]="default"
[tentacles]="default"
[walrus]="default"
#一些不用选的
[has_ocean]="true"
[keep_disconnected_tiles]="true"
[layout_mode]="LinkNodesByKeys"
[wormhole_prefab]="wormhole"
[no_joining_islands]="true"
[no_wormholes_to_disconnected_tiles]="true"
[roads]="default"
)
CavesSetting1=(
"创世界大小" "创世界分支" "创世界循环" "世界再生"
 "洞穴光照" "疾病" "开始资源多样化" "地震" 
 "失败的冒险家" "试金石" "雨"        "草" 
"树苗" "燧石" "尖灌木"  "芦苇" "矿石" 
"所有树" "蘑菇树" "蕨类" "荧光花"
"发光浆果"     "浆果丛"  "蘑菇" "洞穴香蕉"
 "苔藓"       "池塘" "啜食者" "兔人"
 "蛞蝓和蜗牛" "石虾" "猴子"      "蜘蛛"
 "触手" "发条装置" "树精守卫" "蝙蝠"
 "梦魇裂隙" "洞穴蠕虫攻击" "洞穴蠕虫"
)
declare -A CavesSetting2=(
[创世界大小]="world_size"  #small小 medium中 default大 huge巨大 
[创世界分支]="branching" #never从不 least最少 default most最多 random随机
[创世界循环]="loop" #never从不 default  always总是
[世界再生]="regrowth" #veryslow极慢 slow慢 default fast快  veryfast极快
[洞穴光照]="cavelight" 
[疾病]="disease_delay" #none无 random随机 long慢 default short快
[开始资源多样化]="prefabswaps_start" #classic经典 default "highly random"高度随机
[地震]="earthquakes"   #never rare default often always
[失败的冒险家]="boons"
[试金石]="touchstone"
[雨]="weather"

[草]="grass" 
[树苗]="sapling" 
[燧石]="flint"
[尖灌木]="marshbush"
[芦苇]="reeds"
[矿石]="rock"
[所有树]="trees"
[蘑菇树]="mushtree"
[蕨类]="fern"
[荧光花]="flower_cave"
[发光浆果]="wormlights"

[浆果丛]="berrybush"
[蘑菇]="mushroom"
[洞穴香蕉]="banana"
[苔藓]="lichen"

[池塘]="cave_ponds"
[啜食者]="slurper"
[兔人]="bunnymen"
[蛞蝓和蜗牛]="slurtles"
[石虾]="rocky"
[猴子]="monkey"
 
[蜘蛛]="cave_spiders"
[触手]="tentacles"
[发条装置]="chess"
[树精守卫]="liefs"
[蝙蝠]="bats"
[梦魇裂隙]="fissure"
[洞穴蠕虫攻击]="wormattacks"
[洞穴蠕虫]="worms"
)
declare -A CavesSetting3=(
[task_set]="cave_default" 
[start_location]="caves" 
[world_size]="default"  #small小 medium中 default大 huge巨大 
[branching]="default" #never从不 least最少 default most最多 random随机
[loop]="default" #never从不 default  always总是
[regrowth]="default" #veryslow极慢 slow慢 default fast快  veryfast极快
[cavelight]="default"
[disease_delay]="default" #none无 random随机 long慢 default short快
[prefabswaps_start]="default" #classic经典 default "highly random"高度随机
[earthquakes]="default"
[boons]="default"
[touchstone]="default"
[weather]="default"
[flowers]="default" #never rare default always
[grass]="default" 
[sapling]="default"
[flint]="default"
[marshbush]="default"
[reeds]="default"
[rock]="default"
[trees]="default"
[mushtree]="default"
[fern]="default"
[flower_cave]="default"
[wormlights]="default"
[berrybush]="default"
[mushroom]="default"
[banana]="default"
[lichen]="default"
[cave_ponds]="default"
[slurper]="default"
[bunnymen]="default"
[slurtles]="default"
[rocky]="default"
[monkey]="default"
[cave_spiders]="default"
[tentacles]="default"
[chess]="default"
[liefs]="default"
[bats]="default"
[fissure]="default"
[wormattacks]="default"
[worms]="default"
#一些不用选的
[layout_mode]="RestrictNodesByKey"
[roads]="never"
[season_start]="default"
[start_location]="caves"
[task_set]="cave_default"
[wormhole_prefab]="tentacle_pillar"
[wormlights]="default"
)
value1=(never rare default often always)
declare -A value1_chs=([never]="无" [rare]="很少" [default]="默认" [often]="较多" [always]="很多")
value2=(classic default)
declare -A value2_chs=([classic]="经典" [default]="联机版")
value3=(plus darkness default)
declare -A value3_chs=([plus]="额外资源" [darkness]="黑暗" [default]="默认")
value4=(small medium default huge )
declare -A value4_chs=([small]="小" [medium]="中" [default]="大" [huge]="巨大" )
value5=(never least default most random)
declare -A value5_chs=([never]="从不" [least]="最少" [default]="默认" [most]="最多" [random]="随机")
value6=(never default  always)
declare -A value6_chs=([never]="从不" [default]="默认"  [always]="总是")
value7=(none default hallowed_nights winters_feast year_of_the_gobbler year_of_the_varg year_of_the_pig year_of_the_carrat)
declare -A value7_chs=([none]="无" [default]="自动" [hallowed_nights]="万圣节" [winters_feast]="冬季盛宴" [year_of_the_gobbler]="火鸡之年" [year_of_the_varg]="座狼之年" [year_of_the_pig]="猪王之年" [year_of_the_carrat]="胡萝卜鼠之年")
value8=(noseason veryshortseason shortseason default ongseason verylongseason random)
declare -A value8_chs=([noseason]="无" [veryshortseason]="极短" [shortseason]="短" [default]="默认" [longseason]="长" [verylongseason]="极长" [random]="随机")
value9=(default  winter spring summer  autumnorspring winterorsummer random)
declare -A value9_chs=([default]="秋"  [winter]="冬" [spring]="春" [summer]="夏"  [autumnorspring]="春或秋" [winterorsummer]="冬或夏" [random]="随机")
value10=(default longday longdusk longnight noday nodusk nonight onlyday onlydusk  onlynight)
declare -A value10_chs=([default]="默认" [longday]="长白天" [longdusk]="长黄昏" [longnight]="长夜晚" [noday]="无白天" [nodusk]="无黄昏" [nonight]="无夜晚" [onlyday]="仅白天" [onlydusk]="仅黄昏"  [onlynight]="仅夜晚")
value11=(veryslow slow default fast  veryfast)
declare -A value11_chs=([veryslow]="极慢" [slow]="慢" [default]="默认" [fast]="快"  [veryfast]="极快")
value12=(none random long default short)
declare -A value12_chs=([none]="无" [random]="随机" [long]="慢" [default]="默认" [short]="快")
value13=(classic default "highly random")
declare -A value13_chs=([classic]="经典" [default]="默认" [highly random]="高度随机")
value14=(none few default many max)
declare -A value14_chs=([none]="无" [few]="慢" [default]="默认" [many]="多" [max]="很多")
#工具函数
function message()
{
echo -e "\033[32;40m$1\033[0m"
}
function waring()
{
echo -e "\033[33;40m$1\033[0m"
}
function error()
{
echo -e "\033[31;40m$1\033[0m"
}

#修改存档的时候关闭一些东西包括进程，更新和检测崩溃自动任务
function archiveclose
{
local curFolder=$(pwd)
waring "操作存档mod相关，我把服务器进程和更新/检测崩溃的自动任务先给你关咯"
closeserver
local checkWorldPid=$(ps aux|grep "checkworld.sh"| grep daoxinwudi| grep -E "\s[0-9]+" -o |sed -n 1p|grep -E "[0-9]+")
if [ ${checkWorldPid}x != x ]
then
	kill -9 ${checkWorldPid}
	message "已经杀掉检测崩溃的进程"
else
	waring "当前没有定时检测崩溃的任务，不需要关闭"
fi
				
local updatecheckPid=$(ps aux|grep "updatecheck.sh"| grep daoxinwudi| grep -E "\s[0-9]+" -o |sed -n 1p|grep -E "[0-9]+")
if [ ${updatecheckPid}x != x ]
then
	kill -9 ${updatecheckPid}
	message "已经杀掉检测更新的进程"
else
	waring "当前没有定时检测更新的任务，不需要关闭"
fi
cd ${curFolder}
}

function backprepare
{
local curFolder=$(pwd)
#备份前的准备，即得到一个备份的地址和数量，当前有自动备份进程的话，就从这里查出来
#不然就让用户输入一个
local isbacksavefileexist=$(find /home/daoxinwudi -maxdepth 1 -type f -name "backsave.sh"|wc -l)
if [ ${backsave_location} == "null"  ]
then
	if [ ${isbacksavefileexist} -ne 0 ]
	then
		backsave_maxnum=$(grep -E "最多\s.*\s地址" -o /home/daoxinwudi/backsave.sh |grep -E "\s.*\s" -o)
		backsave_location=$(grep -E "地址是\s.*" -o /home/daoxinwudi/backsave.sh |grep -E "\s.*" -o)
	else
		message "最多维持多少个备份?因为存储空间肯定不够啊，存多了我就把最早的一个备份给删除(看着硬盘容量写，太多存不下)"
		while read temp
		do
			if [ ${temp}x != x ]
			then
				if [ ${temp} -ne 0 ]
				then
					backsave_maxnum=${temp}
					break
				fi
			fi
		done
		message "备份所在的文件夹位置?要写绝对路径,要是已经存在的,比如/home/cundang这样的，我就给你存这下面"
		while read temp
		do
			if [ ${temp}x != x ]
			then
				if [ -d  ${temp} ]
				then
					backsave_location=${temp}
					break
				else
					waring "你这个文件夹不存在啊，重写重写重写重写"
					continue
				fi	
			fi
		done					
	fi		
fi			
cd ${curFolder}
}


function writedefaultconfig
{
local curFolder=$(pwd)
#遍历dedicated_server_mods_setup.lua,这个里面比modoverrides.lua多的mod全部置为默认配置
local hasnew=false
local modnumber=$(grep -E "ServerModSetup\([^0-9]*.*[^0-9]*\)" -o ${DSTserverFolder}/mods/dedicated_server_mods_setup.lua |grep -E "[0-9]+" -c)
for((i=1;i<=${modnumber};i++))
do
	local modid=$(grep -E "ServerModSetup\([^0-9]*.*[^0-9]*\)" -o ${DSTserverFolder}/mods/dedicated_server_mods_setup.lua |grep -E "[0-9]+" -o|sed -n ${i}p)
	if [ ${modid} == "350811795" ]
	then
		#这个是这个文件中的示例
		continue
	fi
	#没有这个mod就置为默认配置
	local hasthismodinmodoverrides=$(grep "${modid}" -c /root/.klei/DoNotStarveTogether/${archiveLocation}/${existedworldname}/modoverrides.lua)
	if [ ${hasthismodinmodoverrides} -eq 0 ]
	then
		hasnew=true
		echo "package.path=\"/home/DSTserver/mods/workshop-${modid}/?.lua;\"..package.path
require(\"modinfo\")
local overrides = require(\"modinfo\")
configs={}
--有的mod没有config
if(type(configuration_options) ~= type(nil))
then
	for k,v in pairs(configuration_options)
	do
		configs[v.name]=tostring(v.default)
	end
end

file = io.open(\"/root/.klei/DoNotStarveTogether/${archiveLocation}/${existedworldname}/modoverrides.lua\", \"r+\")
--跳到倒数第二个大括号处写
file:seek(\"end\", -1)
while(file:read(1) ~= \"}\")
do
	file:seek(\"cur\", -2)
end
file:seek(\"cur\", -2)
while(file:read(1) ~= \"}\")
do
	file:seek(\"cur\", -2)
end
file:seek(\"cur\", -1)
file:write(\"},\\n\")
file:write(\"[\\\"workshop-${modid}\\\"]={\\nconfiguration_options={\\n\")
--有的mod没有config
if(type(configuration_options) ~= type(nil))
then
	for k1,v1 in pairs(configs)
	do
		file:write(\"[\\\"\"..k1..\"\\\"]=\"..\"\\\"\"..v1..\"\\\"\"..\",\\n\")
	end
	--去掉最后一个逗号
	file:seek(\"cur\", -1)
	while(file:read(1) ~= ',')
	do
		file:seek(\"cur\", -2)
	end
	file:seek(\"cur\", -1)
end
file:write(\"\\n\")
file:write(\"},\\nenabled=true\\n}\\n}\")" > /home/daoxinwudi/writedefaultconfig.lua 
		lua /home/daoxinwudi/writedefaultconfig.lua
	fi
done
#modoverride.lua粘贴到其他世界
local foldernumber=$(find /root/.klei/DoNotStarveTogether/${archiveLocation} -maxdepth 1 -type d| wc -l)
#第一个是自身名字
for((i=1;i<${foldernumber};i++))
do
	#去除前面的路径
	p=`expr ${i} + 1`
	local temp=$(find /root/.klei/DoNotStarveTogether/${archiveLocation} -maxdepth 1 -type d|sed -n ${p}p|sed 's#.*/##')
	#自己不用再复制
	if [ ${temp} != ${existedworldname} ]
	then
		cp  -f /root/.klei/DoNotStarveTogether/${archiveLocation}/${existedworldname}/modoverrides.lua  /root/.klei/DoNotStarveTogether/${archiveLocation}/${temp}/modoverrides.lua
	fi
done
if [ ${hasnew} == true ]
then
	message "新添加的mod已经全部置为默认配置！"
fi
cd ${curFolder}
}

#修改某一个指定mod的配置项，并写入存档中所有世界的modoverrides.lua
#为了复用代码而抽出来的工具函数
function modifymodconfig_lua
{
local curFolder=$(pwd)
local modid=$1
touch /root/.klei/DoNotStarveTogether/${archiveLocation}/${existedworldname}/modoverrides_temp.lua
#控制权交给这个lua脚本
echo "package.path=\"/home/DSTserver/mods/workshop-${modid}/?.lua;\"..package.path
package.path=\"/root/.klei/DoNotStarveTogether/${archiveLocation}/${existedworldname}/?.lua;\"..package.path
require(\"modinfo\")
local overrides = require(\"modoverrides\")
--去除各个配置的当前值
--处理不了表中带表的配置，典型就是多重世界选择器1754389029
overrideconfig={}
for k3,v3 in pairs(overrides)
do
	if(k3 == \"workshop-${modid}\")
	then
		overrideconfig=v3.configuration_options
		break
	end
end
--开始读取配置项并显示出来,有的mod无配置显示无配置
if(type(configuration_options) ~= type(nil))
then
	configs={}
	names={}
	--values是个二维数组
	values={}
	print(\"\\27[32m以下是ID:${modid}  名字:\"..name..\"的所有配置项\\27[0m\") 
	index=1
	for k,v in pairs(configuration_options)
	do
		--打印name和label
		if(v.name == nil)
		then
			namecfg=\"无\"
		else
			namecfg=v.name
		end
		if(v.label == nil)
		then
			label=\"无\"
		else
			label=v.label
		end
		if(v.default == nil)
		then
			default=\"无\"
		else
			default=tostring(v.default)
		end
		print(\"\\27[32m\"..\"[[\"..index..\"]]\"..\"名字:\"..namecfg, \"标签:\"..label..\"\\27[0m\") 
		--打印options
		optionindex=1
		values[index]={}
		for k2,v2 in pairs(v.options)
		do
			if(type(v2.description) ~= table)
			then
				if(v2.description == nil)
				then
					des=\"无\"
				else
					des=v2.description
				end
				
			else
				des=\"这是个读不出来的奇怪描述(daoxinwudi注)\"
			end
			if(type(v2.hover) ~= table)
			then
				if(v2.hover == nil)
				then
					hover=\"无\"
				else
					hover=v2.hover
				end
			
			else
				hover=\"这是个读不出来的奇怪提示(daoxinwudi注)\"
			end
			if(type(v2.data) ~= table)
			then
				if(v2.data == nil)
				then
					data=\"无\"
				else
					data=tostring(v2.data)
				end
	        
			else
				data=\"这是个读不出来的奇怪值(daoxinwudi注)\"
			end
			print(\"\\27[32m\"..\"----(\"..optionindex..\")\"..\"描述:\"..des,\"提示:\"..hover,\"值:\"..data..\"\\27[0m\") 
			values[index][optionindex]=tostring(data)
			optionindex=optionindex+1
		end
		print(\"\\27[32m默认值:\"..default..\"    当前值:\"..tostring(overrideconfig[namecfg])..\"\\27[0m\") 
		print(\"\\27[32m==============================\\27[0m\") 
		--这些值存储下来
		names[index]=namecfg
		configs[index]=\"[\\\"\"..namecfg..\"\\\"]\"..\" = \"..\"\\\"\"..tostring(overrideconfig[namecfg])..\"\\\"\"
		index=index+1
	end
else
	print(\"\\27[31m=====此mod无配置，不需要修改=====\\27[0m\") 
	return 0
end
--用完都加一了，最后一次多加一次
index=index-1
optionindex=optionindex-1
--开始处理用户输入
--lua没有continue，用三个标志模仿continue的行为
local changenumber=1
local optionnumber=1
local canrun=true
local canrun1=true
local canrun2=true
while (canrun)
do
	canrun=true
	canrun1=true
	canrun2=true
	while (canrun1)
	do
		repeat
			print(\"\\27[32m请输入想更改的配置项,输入回车退出，使用当前配置\\27[0m\") 
			temp = io.read()
			if (temp == \"\")
			then
				canrun=false
				canrun1=fasle
				canrun2=fasle
				break
			end
			changenumber = tonumber(temp)
			if(type(changenumber) == type(nil))
			then
				print(\"\\27[32m输入不是数字，重新输入\\27[0m\") 
				break
			end
			if(changenumber > index)
			then
				print(\"\\27[32m数字超过配置项个数，重新输入\\27[0m\") 
				break
			end
			canrun1=false
			break
		until(false)	
	end
	
	while (canrun2)
	do
		repeat
			print(\"\\27[32m这个配置项你想改成哪个值，输入对应的选项索引数字\\27[0m\") 
			optionnumber = tonumber(io.read())
			if(type(optionnumber) == type(nil))
			then
				print(\"\\27[32m输入不是数字，重新输入\\27[0m\") 
				break
			end
			if(optionnumber > #values[changenumber])
			then
				print(\"\\27[32m索引超过选项个数，重新输入\\27[0m\") 
				break
			end
			canrun2=fasle
			break
		until(false)
	end	
	configs[changenumber]=\"[\\\"\"..names[changenumber]..\" = \"..\"\\\"\"..values[changenumber][optionnumber]..\"\\\"\"
end


--将修改过的写入文件
file = io.open(\"/root/.klei/DoNotStarveTogether/${archiveLocation}/${existedworldname}/modoverrides_temp.lua\", \"w+\")
file:write(\"return {\\n\")
function writetable(configtable)
	local isconfignotnull=false
	for k2,v2 in pairs(configtable)
	do
		isconfignotnull=true
		if( type(v2) ~= \"table\" )
			then
				file:write(\"[\\\"\"..k2..\"\\\"]\"..\"=\"..\"\\\"\"..tostring(v2)..\"\\\"\"..\",\\n\")
			else
				file:write(\"[\"..k2..\"]\"..\"={\\n\")
				writetable(v2)
				file:write(\"},\\n\")
			end
	end
	--倒退任意字符，删除逗号
	if( isconfignotnull)
	then
		file:seek(\"cur\", -1)
		while(file:read(1) ~= ',')
		do
			file:seek(\"cur\", -2)
		end
		file:seek(\"cur\", -1)
	end
	file:write(\"\\n\")
	return 0
end
if(type(overrides) ~= type(nil))
then
	for k,v in pairs(overrides)
		do
			--非此mod全部照旧写进去
			if(k ~= \"workshop-${modid}\")
			then
				file:write(\"[\\\"\"..k..\"\\\"]={\\nconfiguration_options={\\n\")
				local isconfignotnull=false
				for k1,v1 in pairs(v.configuration_options)
				do
					isconfignotnull=true
					if( type(v1) ~= \"table\" )
					then
						file:write(\"[\\\"\"..k1..\"\\\"]\"..\"=\"..\"\\\"\"..tostring(v1)..\"\\\"\"..\",\\n\")
					else
						file:write(\"[\"..k1..\"]\"..\"={\\n\")
						writetable(v1)
						file:write(\"},\\n\")
					end	
				end
				--倒退任意字符，直到删除多余的逗号
				if( isconfignotnull)
				then
					file:seek(\"cur\", -1)
					while(file:read(1) ~= ',')
					do
						file:seek(\"cur\", -2)
					end
					file:seek(\"cur\", -1)
				end
				file:write(\"\\n\")
				file:write(\"},\\nenabled=true\\n},\\n\")
			end
		end
end
--对于此mod按照修改过的写进去
file:write(\"[\\\"workshop-${modid}\\\"]={\\nconfiguration_options={\\n\")
file:write(table.concat(configs, \",\\n\"))
--倒退任意字符，直到删除多余的逗号
file:seek(\"cur\", -1)
while(file:read(1) ~= ',')
do
	file:seek(\"cur\", -2)
end
file:seek(\"cur\", -1)
file:write(\"\\n\")
file:write(\"},\\nenabled=true\\n},\\n\")
--倒退任意字符，直到删除多余的逗号
file:seek(\"cur\", -1)
while(file:read(1) ~= ',')
do
	file:seek(\"cur\", -2)
end
file:seek(\"cur\", -1)
file:write(\"}\")
" > /home/daoxinwudi/modifymodconfig.lua 
lua /home/daoxinwudi/modifymodconfig.lua 

#modoverride.lua粘贴到其他世界
local foldernumber=$(find /root/.klei/DoNotStarveTogether/${archiveLocation} -maxdepth 1 -type d| wc -l)
#第一个是自身名字
for((i=1;i<${foldernumber};i++))
do
	#去除前面的路径
	p=`expr ${i} + 1`
	local temp=$(find /root/.klei/DoNotStarveTogether/${archiveLocation} -maxdepth 1 -type d|sed -n ${p}p|sed 's#.*/##')
	cp  -f /root/.klei/DoNotStarveTogether/${archiveLocation}/${existedworldname}/modoverrides_temp.lua  /root/.klei/DoNotStarveTogether/${archiveLocation}/${temp}/modoverrides.lua
done
rm -f /root/.klei/DoNotStarveTogether/${archiveLocation}/${existedworldname}/modoverrides_temp.lua
cd ${curFolder}
}



#下载文件
function download
{
	local curFolder=$(pwd)
	#安装各种工具，yum和aptget各执行一遍，没有的自己就提示了
	yum update
	apt-get update
	for ((i=0;i<${needinstallnum};i++))
	do
	message 正在安装${needinstall[${i}]}
	yum -y install ${needinstall[${i}]}
	apt-get  -y install ${needinstall_aptget[${i}]}
	done

	#下面是安装steamcmd
	cd /home
	rm -rf steamcmd
	mkdir steamcmd
	message 正在下载steamcmd的压缩包
	wget -P ~/steamcmd https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
	cd ./steamcmd
	message 正在解压缩
	tar -xvzf ~/steamcmd/steamcmd_linux.tar.gz
	message 正在下载饥荒服务端核心程序
	chmod +x /home/steamcmd/steamcmd.sh
	./steamcmd.sh +login anonymous +force_install_dir ${DSTserverFolder} +app_update 343050 validate +quit
	#解决一个lib缺失
	cd ${DSTserverFolder}/bin/lib32
	ln -s /usr/lib/libcurl.so.4 libcurl-gnutls.so.4
	cd ${curFolder}
	message 下载完毕
}

#开启世界
function startserver
{
local curFolder=$(pwd)
#首先申请操作
#开启世界之前先关闭所有世界
message "正在关掉已经有的世界"
closeserver
#遍历所有的世界，全都开启
local foldernumber=$(find /root/.klei/DoNotStarveTogether/${archiveLocation} -maxdepth 1 -type d| wc -l)
#第一个是自身名字
if [ ${foldernumber}  -ne 1 ]
then
	exec 12<>/home/daoxinwudi/lockfile_Process
	flock -x 12
	for((i=1;i<${foldernumber};i++))
	do
		local startworldsuccess=false
		local timeout=3
		#去除前面的路径
		local p=`expr ${i} + 1`
		local worldfolder=$(find /root/.klei/DoNotStarveTogether/${archiveLocation} -maxdepth 1 -type d|sed -n ${p}p|sed 's#.*/##')
		#先清空日志文件，防止查询错误
		rm -f /root/.klei/DoNotStarveTogether/${archiveLocation}/${worldfolder}/server_log.txt
		touch /root/.klei/DoNotStarveTogether/${archiveLocation}/${worldfolder}/server_log.txt
		echo " " > /root/.klei/DoNotStarveTogether/${archiveLocation}/${worldfolder}/server_log.txt
		#开启,一定要cd到这个目录，不然这个程序跑不起来，他应该设定了工作目录
		cd ${DSTserverFolder}/bin
		nohup ./dontstarve_dedicated_server_nullrenderer -console -cluster ${archiveLocation} -monitor_parent_process $ -shard ${worldfolder} > /dev/null 2>&1 &
		message "正在开启${worldfolder}世界...........预计3分钟左右，目前错误超时时间${timeout}分钟,请不要退出"
		message "为了屏幕上不显示一大片字，日志已经输出至/root/.klei/DoNotStarveTogether/${archiveLocation}/${worldfolder}/server_log.txt"
		local timer=`date +%M`
		local isStarted=fasle
		local lastline=null
		while true
		do
			isStarted=$(tail -n 200 /root/.klei/DoNotStarveTogether/${archiveLocation}/${worldfolder}/server_log.txt |grep "SteamGameServer_Init success" -c)
			local lastline_temp=$(tail -n 1 /root/.klei/DoNotStarveTogether/${archiveLocation}/${worldfolder}/server_log.txt)
			if [ ${isStarted} -ne 0 ]
			then
				startworldsuccess=true;
				break
			fi
			#检测超时
			temp=`date +%M`
			if [ "${lastline_temp}x" == "${lastline}x" ]
			then
				if [ `expr $temp - $timer` -ge ${timeout} ]
				then
					#已经超时timeout分钟了，认为没有成功开启
					startworldsuccess=false;
					break
				fi
			fi
			lastline=${lastline_temp}
		done
		if [ $startworldsuccess == true ]
		then
			message "你成功开启了${worldfolder}这个世界"
		else
			error "开启${worldfolder}超时了${timeout}分钟还没开启，认为失败了"
			#kill掉残留的进程
			local worldPid=$(ps aux|grep dontstarve_dedicated_server_nullrenderer | grep "\-shard ${worldfolder}"|grep -E "\s[0-9]+" -o |sed -n 1p|grep -E "[0-9]+")
			if [ ${worldPid}x != x ]
			then
				kill -9 ${worldPid}
			fi
		fi
	done
	flock -u 12
fi
cd ${curFolder}
}

#更新程序
function updateserver
{
curFolder=$(pwd)
#申请steamcmd操作权限
exec 19<>/home/daoxinwudi/lockfile_Steamcmd
flock -x 19
#更新之前先保存一下dedicated_server_mods_setup.lua，因为更新会清空这个文件
#当你新增了一个mod，而还没有下载，更新后新增的就消失了
cp -f ${DSTserverFolder}/mods/dedicated_server_mods_setup.lua ${DSTserverFolder}/mods/dedicated_server_mods_setup_backup.lua
message 开始执行更新
/home/steamcmd/steamcmd.sh +login anonymous +force_install_dir ${DSTserverFolder} +app_update 343050 validate +quit
#更新完毕之后，有的时候mods下面的dedicated_server_mods_setup.lua文件会被清空，需要恢复一下
cp -f ${DSTserverFolder}/mods/dedicated_server_mods_setup_backup.lua ${DSTserverFolder}/mods/dedicated_server_mods_setup.lua
rm -f ${DSTserverFolder}/mods/dedicated_server_mods_setup_backup.lua
flock -u 19
message 更新完毕咯
startserver
cd ${curFolder}
}

#关闭世界
function closeserver
{
curFolder=$(pwd)
worldnumber=$(ps aux|grep dontstarve_dedicated_server_nullrenderer | grep "\-shard" -c)
for((i=1;i<=${worldnumber};i++))
do
	worldPid=$(ps aux|grep dontstarve_dedicated_server_nullrenderer | grep "\-shard"|sed -n ${i}p |grep -E "\s[0-9]+" -o |sed -n 1p|grep -E "[0-9]+")
	if [ ${worldPid}x != x ]
	then
		kill -9 ${worldPid}
	fi
done
message 关闭了${worldnumber}个世界！
cd ${curFolder}
}

#列出当前所有mod
function listmods
{
local curFolder=$(pwd)
message 以下是所有mod：
local hasmod=false
local modnumber=$(grep -E "ServerModSetup\([^0-9]*.*[^0-9]*\)" -o ${DSTserverFolder}/mods/dedicated_server_mods_setup.lua |grep -E "[0-9]+" -c)
for((i=1;i<=${modnumber};i++))
do
	local modid=$(grep -E "ServerModSetup\([^0-9]*.*[^0-9]*\)" -o ${DSTserverFolder}/mods/dedicated_server_mods_setup.lua |grep -E "[0-9]+" -o|sed -n ${i}p)
	if [ ${modid} == "350811795" ]
	then
		#这个是这个文件中的示例
		continue
	fi
	#assert这个mod的文件夹存在,必定下载下来了
	echo "package.path = \"${DSTserverFolder}/mods/workshop-${modid}/?.lua\"
require(\"modinfo\")
print(name)" > ./temp${modid}.lua
	lua ./temp${modid}.lua > ./tempoutput${modid}.txt
	rm -f ./temp${modid}.lua
	local modname=$(cat  ./tempoutput${modid}.txt)
	rm -f ./tempoutput${modid}.txt
	echo -e "\033[32;40m名字:${modname} ID:${modid}\033[0m"
	hasmod=true
done	
if [ ${hasmod} == false ]
then
	waring "当前没有mod！"
	return 0
else
	return ${modnumber}
fi				
cd $curFolder
}

#修改mod配置项
function modifymodconfig
{
local curFolder=$(pwd)
message ==================================
listmods
modsnumber=$?
if [ ${modsnumber} -ne 0 ]
then
	while :
	do
		message ==================================
		listmods
		message "请输入一个mod的数字id，修改它的配置项目,什么都不输入直接回车就什么都不改"
		read temp
		if [ ${temp}x == x ]
		then
			#空的直接退出
			break
		fi
		local str=$(echo $temp |grep -E "[^0-9]" -c)
		if [ ${str} -ne 0 ]	
		then
			error 你输入的不是纯数字，我觉得你按错了，重新输入一个吧
			continue
		fi
		#如果在dedicated_server_mods_setup.lua中没有就不算
		local hasthis=$(grep -E "ServerModSetup\([^0-9]*${temp}[^0-9]*\)" -c ${DSTserverFolder}/mods/dedicated_server_mods_setup.lua)
		if [ ${hasthis} -eq 0 ]
		then
			error "没有这个mod，无法修改！"
			continue
		fi
		#然后开始真正的调用修改mod配置项的lua脚本，因为配置项本身就是lua，用lua脚本更好改。
		modifymodconfig_lua $temp	
		message "已经配置此修改"
	done
else
	waring "当前没有mod，不需要修改"
fi
cd $curFolder
}

#添加mod
function addmod
{
	local curFolder=$(pwd)
	message =======================================================================
	message "请输入一个mod的数字id，你可以去创意工坊打开某mod，对应的网址中后面那一串数字就是"
	message "比如https://steamcommunity.com/sharedfiles/filedetails/?id=1699194522,这个数字就是mod的id"
	message ========================================================================
	while :
	do
		message 你可以一直输入id，直到你什么都不输入，直接回车，认为结束了,我就会开始给你下载mod
		read temp
		if [ ${temp}x == x ]
		then
			#空的直接退出
			break
		fi
		local str=$(echo $temp |grep -E "[^0-9]" -c)
		if [ ${str} -eq 0 ]
		then
			local hasthismod=$(grep -E "ServerModSetup\([^0-9]*${temp}[^0-9]*\)" -c ${DSTserverFolder}/mods/dedicated_server_mods_setup.lua)
			if [ ${hasthismod} -eq 0 ]
			then
				echo "ServerModSetup(\"${temp}\")" >> ${DSTserverFolder}/mods/dedicated_server_mods_setup.lua
				message 已经将${temp}写入配置文件	
			else
				waring 你已经有这个mod了（以dedicated_server_mods_setup.lua显示的为准）！
			fi
		else
			error 你输入的不是纯数字，我觉得你按错了，重新输入一个吧
			continue
		fi
	done
	cd ${DSTserverFolder}/bin
	#开启一个临时世界来下载mod，存档名字叫temp,世界文件夹叫daoxinwudi
	#先清空日志文件，防止查询错误
	rm -f /root/.klei/DoNotStarveTogether/temp/daoxinwudi/server_log.txt
	mkdir -p /root/.klei/DoNotStarveTogether/temp/daoxinwudi
	touch /root/.klei/DoNotStarveTogether/temp/daoxinwudi/server_log.txt
	echo " " > /root/.klei/DoNotStarveTogether/temp/daoxinwudi/server_log.txt
	nohup  ./dontstarve_dedicated_server_nullrenderer -console -cluster temp -monitor_parent_process $ -shard daoxinwudi > /dev/null 2>&1 &
	message 正在开始下载这一大堆mod......
	local laststr=null
	#下载mod比较慢，超时时间长一点
	local timeout=15
	local timer=`date +%M`
	while true
	do
		local isdownloadsuccess=$(tail -n 200 /root/.klei/DoNotStarveTogether/temp/daoxinwudi/server_log.txt |grep "LOADING LUA SUCCESS" -c)
		if [ ${isdownloadsuccess} -ne 0 ]
		then
			message 这一大堆mod都下载完成！
			break
		fi
		
		#检测超时
		temp=`date +%M`
		if [ "${lastline_temp}x" == "${lastline}x" ]
		then
			if [ `expr $temp - $timer` -ge ${timeout} ]
			then
				#已经超时timeout分钟了，认为没有成功开启
				error "下载失败！应该是网速太慢，你也可以手动复制mod的文件夹到服务器上"
				break
			fi
		fi
		lastline=${lastline_temp}
	done
	#杀临时世界的进程
	local tempPid=$(ps aux|grep "\-shard daoxinwudi"| grep dontstarve| grep -E "\s[0-9]+" -o |sed -n 1p|grep -E "[0-9]+")
	if [ ${tempPid}x != x ]
	then
		kill -9 ${tempPid}
	fi
	#删除临时世界生成的临时存档
	rm -rf /root/.klei/DoNotStarveTogether/temp
	#然后把dedicated_server_mods_setup.lua中有的，modoverrides.lua没有的都写一个默认配置到modoverrides.lua
	writedefaultconfig
	cd $curFolder
}

#删除一个mod
function delmod
{
local curFolder=$(pwd)
listmods
local modnumber=$?
if [ ${modnumber} -ne 0 ]
then
	while :
	do
		message "输入你想删除的mod的id,你可以一直输入id，输入一个删除一个，直到你什么都不输入，直接回车，就结束了"
		read temp
		if [ ${temp}x != x ]
		then
			str=$(echo $temp |grep -E "[^0-9]" -c)
			if [ ${str} -eq 0 ]
			then
				local hasthismod=$(grep -E "ServerModSetup\([^0-9]*${temp}[^0-9]*\)" -c ${DSTserverFolder}/mods/dedicated_server_mods_setup.lua)
				if [ ${hasthismod} -ne 0 ]
				then
					rm -rf ${DSTserverFolder}/mods/workshop-${temp}
					sed -i "/${temp}/d" ${DSTserverFolder}/mods/dedicated_server_mods_setup.lua
					message 已经删除dedicated_server_mods_setup.lua配置文件中的此mod
					#删除modoverride.lua中的此mod
					echo "package.path=\"/root/.klei/DoNotStarveTogether/${archiveLocation}/${existedworldname}/?.lua;\"..package.path
local overrides = require(\"modoverrides\")
file = io.open(\"/root/.klei/DoNotStarveTogether/${archiveLocation}/${existedworldname}/modoverrides_temp.lua\", \"w+\")
function writetable(configtable)
	local isconfignotnull=false
	for k2,v2 in pairs(configtable)
	do
		isconfignotnull=true
		if( type(v2) ~= \"table\" )
			then
				file:write(\"[\\\"\"..k2..\"\\\"]\"..\"=\"..\"\\\"\"..tostring(v2)..\"\\\"\"..\",\\n\")
			else
				file:write(\"[\"..k2..\"]\"..\"={\\n\")
				writetable(v2)
				file:write(\"},\\n\")
			end
	end
	--倒退任意字符，删除逗号
	if( isconfignotnull)
	then
		file:seek(\"cur\", -1)
		while(file:read(1) ~= ',')
		do
			file:seek(\"cur\", -2)
		end
		file:seek(\"cur\", -1)
	end
	file:write(\"\\n\")
	return 0
end
file:write(\"return{\\n\")
for k,v in pairs(overrides)
do
	if(k ~= \"workshop-${temp}\")
	then
		file:write(\"[\\\"\"..k..\"\\\"]={\\nconfiguration_options={\\n\")
		local isconfignotnull=false
		for k1,v1 in pairs(v.configuration_options)
		do
			isconfignotnull=true
			if( type(v1) ~= \"table\" )
			then
				file:write(\"[\\\"\"..k1..\"\\\"]\"..\"=\"..\"\\\"\"..tostring(v1)..\"\\\"\"..\",\\n\")
			else
				file:write(\"[\"..k1..\"]\"..\"={\\n\")
				writetable(v1)
				file:write(\"},\\n\")
			end	
		end
		--倒退任意字符，直到删除多余的逗号
		if( isconfignotnull)
		then
			file:seek(\"cur\", -1)
			while(file:read(1) ~= ',')
			do
				file:seek(\"cur\", -2)
			end
			file:seek(\"cur\", -1)
		end
		file:write(\"\\n\")
		file:write(\"},\\nenabled=true\\n},\\n\")
	end
end
--倒退任意字符，直到删除多余的逗号
file:seek(\"cur\", -1)
while(file:read(1) ~= ',')
do
	file:seek(\"cur\", -2)
end
file:seek(\"cur\", -1)
file:write(\"}\")" > /home/daoxinwudi/delmod.lua
					lua /home/daoxinwudi/delmod.lua	#把/root/.klei/DoNotStarveTogether/${archiveLocation}/${existedworldname}/modoverrides_temp.lua复制到其他世界下面
					local foldernumber=$(find /root/.klei/DoNotStarveTogether/${archiveLocation} -maxdepth 1 -type d| wc -l)
					#第一个是自身名字
					for((i=1;i<${foldernumber};i++))
					do
						#去除前面的路径
						p=`expr ${i} + 1`
						local name_temp=$(find /root/.klei/DoNotStarveTogether/${archiveLocation} -maxdepth 1 -type d|sed -n ${p}p|sed 's#.*/##')
						cp  -f /root/.klei/DoNotStarveTogether/${archiveLocation}/${existedworldname}/modoverrides_temp.lua  /root/.klei/DoNotStarveTogether/${archiveLocation}/${name_temp}/modoverrides.lua
					done
					rm -f /root/.klei/DoNotStarveTogether/${archiveLocation}/${existedworldname}/modoverrides_temp.lua
					message 已经删除各个世界modoverrides.lua配置文件中的此mod	
				else
					waring 这个mod不存在，不需要删除
				fi
			else
				error "你输入的不是纯数字，我觉得你按错了，重新输入一个吧"
				continue
			fi
		else
			message 什么都不做
			break
		fi
	done
else
	waring "当前没有mod，不能删除"
fi						
cd $curFolder
}

#mod管理
function modmanage
{
local curFolder=$(pwd)
archiveclose
#申请存档操作权限
exec 31<>/home/daoxinwudi/lockfile_Archive
flock -x 31
while :
	do
	message =======================================================
	message "[1]添加mod    [2]更改mod配置项    [3]列出当前所有mod "
	message "[4]删除mod    [5]退回上一级"
	message =======================================================
		read temp
			case $temp in
				1)addmod
				;;
				2)modifymodconfig
				;;
				3)listmods
				;;
				4)delmod
				;;
				5)break
				;;
			esac
	done
flock -u 31
cd $curFolder
}

#增加一个世界
function addworld
{
local curFolder=$(pwd)
#先复制或者生成一个modoverrides.lua
message 正在生成modoverrides.lua.....
cd /root/.klei/DoNotStarveTogether/${archiveLocation}
local worldname=null
worldname=$1`date +%Y%m%d%H%M%S`
mkdir $worldname
cd ./${worldname}
if [ existedworldname == null ]
then
	echo "return {
}" > modoverrides.lua
	existedworldname=$worldname
else
	cp -f /root/.klei/DoNotStarveTogether/${archiveLocation}/${existedworldname}/modoverrides.lua   /root/.klei/DoNotStarveTogether/${archiveLocation}/${worldname}/modoverrides.lua
fi
#生成server.ini
message "生成server.ini....."
echo "[NETWORK]
server_port = ${server_port}

[SHARD]
is_master = ${is_master}
name = ${worldname}
id = ${id}

[STEAM]
master_server_port = ${master_server_port}
authentication_port = ${authentication_port}" > server.ini
#用过这些参数后，改动参数
server_port=`expr ${server_port} + 1`
master_server_port=`expr ${master_server_port} + 1`
authentication_port=`expr ${authentication_port} + 1`
id=`expr ${id} + 1`
if [ $is_master == true ]
then
	is_master=false
fi
#生成leveldataoverride.lua，地洞的话自动生成一个worldgenoverride.lua
#这一次addworld使用的与原型数组不同的值
local mastersetting_temp=${MasterSetting3[*]}
local cavessetting_temp=${CavesSetting3[*]}
local value1_chstemp=${value1_chs[*]}
local value2_chstemp=${value2_chs[*]}
local value3_chstemp=${value3_chs[*]}
local value4_chstemp=${value4_chs[*]}
local value5_chstemp=${value5_chs[*]}
local value6_chstemp=${value6_chs[*]}
local value7_chstemp=${value7_chs[*]}
local value8_chstemp=${value8_chs[*]}
local value9_chstemp=${value9_chs[*]}
local value10_chstemp=${value10_chs[*]}
local value11_chstemp=${value11_chs[*]}
local value12_chstemp=${value12_chs[*]}
local value13_chstemp=${value13_chs[*]}
local value14_chstemp=${value14_chs[*]}
if [ $1 == Master ]
then
	error "${MasterSetting1[0]}"
	error "${mastersetting_temp[0]"
	error "${mastersetting_temp[0]}"
	error "${value2_chstemp[*]}"
	#根据输入修改
	while :
	do
		message =================森林世界=========================
		message "${MasterSetting1[0]}:${value2_chstemp[${mastersetting_temp[0]}]}  ${MasterSetting1[1]}:${value3_chstemp[${mastersetting_temp[1]}]}  ${MasterSetting1[2]}:${value4_chstemp[${mastersetting_temp[2]}]}"
		message "${MasterSetting1[3]}:${value5_chstemp[${mastersetting_temp[3]}]}  ${MasterSetting1[4]}:${value6_chstemp[${mastersetting_temp[4]}]}  ${MasterSetting1[5]}:${value7_chstemp[${mastersetting_temp[5]}]}"
		message "${MasterSetting1[6]}:${value8_chstemp[${mastersetting_temp[6]}]}  ${MasterSetting1[7]}:${value8_chstemp[${mastersetting_temp[7]}]}  ${MasterSetting1[8]}:${value8_chstemp[${mastersetting_temp[8]}]}"
		message "${MasterSetting1[9]}:${value8_chstemp[${mastersetting_temp[9]}]}  ${MasterSetting1[10]}:${value9_chstemp[${mastersetting_temp[10]}]}  ${MasterSetting1[11]}:${value10_chstemp[${mastersetting_temp[11]}]}"
		message "${MasterSetting1[12]}:${value11_chstemp[${mastersetting_temp[12]}]}  ${MasterSetting1[13]}:${value12_chstemp[${mastersetting_temp[13]}]}  ${MasterSetting1[14]}:${value13_chstemp[${mastersetting_temp[14]}]}"
		message "${MasterSetting1[15]}:${value14_chstemp[${mastersetting_temp[15]}]}  ${MasterSetting1[16]}:${value1_chstemp[${mastersetting_temp[16]}]}  ${MasterSetting1[17]}:${value1_chstemp[${mastersetting_temp[17]}]}"
		message "${MasterSetting1[18]}:${value1_chstemp[${mastersetting_temp[18]}]}  ${MasterSetting1[19]}:${value1_chstemp[${mastersetting_temp[19]}]}  ${MasterSetting1[20]}:${value1_chstemp[${mastersetting_temp[20]}]}"
		message "${MasterSetting1[21]}:${value1_chstemp[${mastersetting_temp[21]}]}"
		message ===================资源===========================
		message "${MasterSetting1[22]}:${value1_chstemp[${mastersetting_temp[22]}]}  ${MasterSetting1[23]}:${value1_chstemp[${mastersetting_temp[23]}]}  ${MasterSetting1[24]}:${value1_chstemp[${mastersetting_temp[24]}]}"
		message "${MasterSetting1[25]}:${value1_chstemp[${mastersetting_temp[25]}]}  ${MasterSetting1[26]}:${value1_chstemp[${mastersetting_temp[26]}]}  ${MasterSetting1[27]}:${value1_chstemp[${mastersetting_temp[27]}]}"
		message "${MasterSetting1[28]}:${value1_chstemp[${mastersetting_temp[28]}]}  ${MasterSetting1[29]}:${value1_chstemp[${mastersetting_temp[29]}]}  ${MasterSetting1[30]}:${value1_chstemp[${mastersetting_temp[30]}]}"
		message "${MasterSetting1[31]}:${value1_chstemp[${mastersetting_temp[31]}]}  ${MasterSetting1[32]}:${value1_chstemp[${mastersetting_temp[32]}]}  ${MasterSetting1[33]}:${value1_chstemp[${mastersetting_temp[33]}]}"
		message ===================食物===========================
		message "${MasterSetting1[34]}:${value1_chstemp[${mastersetting_temp[34]}]}  ${MasterSetting1[35]}:${value1_chstemp[${mastersetting_temp[35]}]}  ${MasterSetting1[36]}:${value1_chstemp[${mastersetting_temp[36]}]}"
		message "${MasterSetting1[37]}:${value1_chstemp[${mastersetting_temp[37]}]}"
		message ===================动物===========================
		message "${MasterSetting1[38]}:${value1_chstemp[${mastersetting_temp[38]}]}  ${MasterSetting1[39]}:${value1_chstemp[${mastersetting_temp[39]}]}  ${MasterSetting1[40]}:${value1_chstemp[${mastersetting_temp[40]}]}"
		message "${MasterSetting1[41]}:${value1_chstemp[${mastersetting_temp[41]}]}  ${MasterSetting1[42]}:${value1_chstemp[${mastersetting_temp[42]}]}  ${MasterSetting1[43]}:${value1_chstemp[${mastersetting_temp[43]}]}"
		message "${MasterSetting1[44]}:${value1_chstemp[${mastersetting_temp[44]}]}  ${MasterSetting1[45]}:${value1_chstemp[${mastersetting_temp[45]}]}  ${MasterSetting1[46]}:${value1_chstemp[${mastersetting_temp[46]}]}"
		message "${MasterSetting1[47]}:${value1_chstemp[${mastersetting_temp[47]}]}  ${MasterSetting1[48]}:${value1_chstemp[${mastersetting_temp[48]}]}  ${MasterSetting1[49]}:${value1_chstemp[${mastersetting_temp[49]}]}"
		message "${MasterSetting1[50]}:${value1_chstemp[${mastersetting_temp[50]}]}  ${MasterSetting1[51]}:${value1_chstemp[${mastersetting_temp[51]}]}  ${MasterSetting1[52]}:${value1_chstemp[${mastersetting_temp[52]}]}"
		message "${MasterSetting1[53]}:${value1_chstemp[${mastersetting_temp[53]}]}  ${MasterSetting1[54]}:${value1_chstemp[${mastersetting_temp[54]}]}  ${MasterSetting1[55]}:${value1_chstemp[${mastersetting_temp[55]}]}"
		message ===================怪物===========================
		message "${MasterSetting1[56]}:${value1_chstemp[${mastersetting_temp[56]}]}  ${MasterSetting1[57]}:${value1_chstemp[${mastersetting_temp[57]}]}  ${MasterSetting1[58]}:${value1_chstemp[${mastersetting_temp[58]}]}"
		message "${MasterSetting1[59]}:${value1_chstemp[${mastersetting_temp[59]}]}  ${MasterSetting1[60]}:${value1_chstemp[${mastersetting_temp[60]}]}  ${MasterSetting1[61]}:${value1_chstemp[${mastersetting_temp[61]}]}"
		message "${MasterSetting1[62]}:${value1_chstemp[${mastersetting_temp[62]}]}  ${MasterSetting1[63]}:${value1_chstemp[${mastersetting_temp[63]}]}  ${MasterSetting1[64]}:${value1_chstemp[${mastersetting_temp[64]}]}"
		message "${MasterSetting1[65]}:${value1_chstemp[${mastersetting_temp[65]}]}  ${MasterSetting1[66]}:${value1_chstemp[${mastersetting_temp[66]}]}  ${MasterSetting1[67]}:${value1_chstemp[${mastersetting_temp[67]}]}"
		message "${MasterSetting1[68]}:${value1_chstemp[${mastersetting_temp[68]}]}  ${MasterSetting1[69]}:${value1_chstemp[${mastersetting_temp[69]}]}  ${MasterSetting1[70]}:${value1_chstemp[${mastersetting_temp[70]}]}"
		message "${MasterSetting1[71]}:${value1_chstemp[${mastersetting_temp[71]}]}"
		
		waring "输入你想修改的项目索引数字,什么都不输入直接回车视为结束"
		read temp
		if [ ${temp}x !=x ]
		then
			local str=$(echo $temp |grep -E "[^0-9]" -c)
			if [${str} -ne 0 ]	
			then
				error "你输入的不是纯数字，我觉得你按错了，重新输入一个吧"
				continue
			else
				if [ ${temp} -gt 71 ]
				then
					message "输入大于71"
				fi
				if [ ${temp} -lt 0 ]
				then	
					message "输入小于0"
				fi
				error "下面不再判断数字输入问题，你自己看好了，反正乱输肯定出问题。判断麻烦死了，十行代码九都在判断用户乱输入输错的情况，反正我默认你不会乱输，反正乱输肯定出问题"
				#从16"失败的冒险家"开始，就是#never rare default often always这么选择
				if [ ${temp} -ge 16]
				then
					message "请选择[1]无[2]很少[3]默认[4]较多[5]很多"
					read temp2
					if [ ${temp2}x !=x ]
					then
						local str2=$(echo $temp2 |grep -E "[^0-9]" -c)
						if [${str} -ne 0 ]	
						then
							message "你搁这乱按，每次我判断输入是不是数字都麻烦死了烦死了，重来吧你小子"
							continue
						else
							message "你选择了${temp2}"
							local index=`expr ${temp2} - 1` 
							mastersetting_temp[${MasterSetting2[${MasterSetting1[${temp}]}]}]=${value1[${index}]}
						fi
					fi
				#创世界生物群落
				elif [ ${temp} -eq 0 ]
				then
					message "请选择[1]经典[2]联机版"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					mastersetting_temp[${MasterSetting2[${MasterSetting1[${temp}]}]}]=${value2[${index}]}
				#创世界出生点
				elif [ ${temp} -eq 1 ]
				then
					message "请选择[1]额外资源[2]黑暗[3]默认"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					mastersetting_temp[${MasterSetting2[${MasterSetting1[${temp}]}]}]=${value3[${index}]}
				#创世界大小
				elif [ ${temp} -eq 2 ]
				then
					message "请选择[1]小[2]中[3]大[4]巨大"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					mastersetting_temp[${MasterSetting2[${MasterSetting1[${temp}]}]}]=${value4[${index}]}
				#创世界分支
				elif [ ${temp} -eq 3 ]
				then
					message "请选择[1]从不[2]最少[3]默认[4]最多[5]随机"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					mastersetting_temp[${MasterSetting2[${MasterSetting1[${temp}]}]}]=${value5[${index}]}
				
				#创世界循环
				elif [ ${temp} -eq 4 ]
				then
					message "请选择[1]从不[2]默认[3]总是"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					mastersetting_temp[${MasterSetting2[${MasterSetting1[${temp}]}]}]=${value6[${index}]}
				#创世界活动
				elif [ ${temp} -eq 5 ]
				then
					message "请选择[1]无[2]自动[3]万圣节[4]冬季盛宴[5]火鸡年[6]座狼年[7]猪王年[8]胡萝卜鼠年"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					mastersetting_temp[${MasterSetting2[${MasterSetting1[${temp}]}]}]=${value7[${index}]}
				#季节
				elif [ ${temp} -eq 6 ]
				then
					message "请选择[1]无[2]极短[3]短[4]默认[5]长[6]极长[7]随机"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					mastersetting_temp[${MasterSetting2[${MasterSetting1[${temp}]}]}]=${value8[${index}]}
				elif [ ${temp} -eq 7 ]
				then
					message "请选择[1]无[2]极短[3]短[4]默认[5]长[6]极长[7]随机"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					mastersetting_temp[${MasterSetting2[${MasterSetting1[${temp}]}]}]=${value8[${index}]}
				elif [ ${temp} -eq 8 ]
				then
					message "请选择[1]无[2]极短[3]短[4]默认[5]长[6]极长[7]随机"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					mastersetting_temp[${MasterSetting2[${MasterSetting1[${temp}]}]}]=${value8[${index}]}
				elif [ ${temp} -eq 9 ]
				then
					message "请选择[1]无[2]极短[3]短[4]默认[5]长[6]极长[7]随机"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					mastersetting_temp[${MasterSetting2[${MasterSetting1[${temp}]}]}]=${value8[${index}]}
				#起始季节
				elif [ ${temp} -eq 10 ]
				then
					message "请选择[1]默认秋[2]冬[3]春[4]夏[5]春或秋[6]冬或夏[7]随机"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					mastersetting_temp[${MasterSetting2[${MasterSetting1[${temp}]}]}]=${value9[${index}]}
				#昼夜选项
				elif [ ${temp} -eq 11 ]
				then
					message "请选择[1]默认[2]长白天[3]长黄昏[4]长夜晚[5]无白天[6]无黄昏[7]无夜晚[8]仅白天[9]仅黄昏[10]仅夜晚"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					mastersetting_temp[${MasterSetting2[${MasterSetting1[${temp}]}]}]=${value10[${index}]}
				#世界再生
				elif [ ${temp} -eq 12 ]
				then
					message "请选择[1]极慢[2]慢[3]默认[4]快[5]极快"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					mastersetting_temp[${MasterSetting2[${MasterSetting1[${temp}]}]}]=${value11[${index}]}
				#疾病
				elif [ ${temp} -eq 13 ]
				then
					message "请选择[1]无[2]随机[3]慢[4]默认[5]快"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					mastersetting_temp[${MasterSetting2[${MasterSetting1[${temp}]}]}]=${value12[${index}]}
				#开始资源多样化
				elif [ ${temp} -eq 14 ]
				then
					message "请选择[1]经典[2]默认[3]高度随机"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					mastersetting_temp[${MasterSetting2[${MasterSetting1[${temp}]}]}]=${value13[${index}]}
				#森林石化
				elif [ ${temp} -eq 15 ]
				then
					message "请选择[1]无[2]慢[3]默认[4]多[5]很多"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					mastersetting_temp[${MasterSetting2[${MasterSetting1[${temp}]}]}]=${value14[${index}]}
				fi
			fi
		else
			waring “你选择了全部默认：
			break
		fi
	done
	#选择完了就把存下来的写道世界设置的lua里
	#固定的开头
	echo "return {
  desc=\"标准《饥荒》体验。\",
  hideminimap=false,
  id=\"SURVIVAL_TOGETHER\",
  location=\"forest\",
  max_playlist_position=999,
  min_playlist_position=0,
  name=\"标准森林\",
  numrandom_set_pieces=4,
  override_level_string=false,
  overrides={" > ./leveldataoverride.lua
	#改动的中间，遍历
	for key in ${!mastersetting_temp[*]}
	do
		winter="default",
		local value=${mastersetting_temp[${key}]}
		#非最后一行都要加个逗号
		local douhao=
		if [ ${key} != "roads" ]
		then
			douhao=","
		fi
		echo "${key}=\"${value}\"${douhao}" >> ./leveldataoverride.lua
	done
  #固定的结尾
	echo "},
  random_set_pieces={
    \"Sculptures_2\",
    \"Sculptures_3\",
    \"Sculptures_4\",
    \"Sculptures_5\",
    \"Chessy_1\",
    \"Chessy_2\",
    \"Chessy_3\",
    \"Chessy_4\",
    \"Chessy_5\",
    \"Chessy_6\",
    \"Maxwell1\",
    \"Maxwell2\",
    \"Maxwell3\",
    \"Maxwell4\",
    \"Maxwell6\",
    \"Maxwell7\",
    \"Warzone_1\",
    \"Warzone_2\",
    \"Warzone_3\" 
  },
  required_prefabs={ \"multiplayer_portal\" },
  required_setpieces={ \"Sculptures_1\", \"Maxwell5\" },
  substitutes={  },
  version=4 
}" >> ./leveldataoverride.lua
elif [ $1 == Caves ]
then
	#地洞的话啥也不干先自动生成一个worldgenoverride.lua
	echo "return {
    override_enabled = true,
    preset = "DST_CAVE",
}
" > worldgenoverride.lua
	#根据输入修改
	while :
	do
		message =================洞穴世界=========================
		message "${CavesSetting1[0]}:${value4_chstemp[${cavessetting_temp[0]}]}  ${CavesSetting1[1]}:${value5_chstemp[${cavessetting_temp[1]}]}  ${CavesSetting1[2]}:${value6_chstemp[${cavessetting_temp[2]}]}"
		message "${CavesSetting1[3]}:${value11_chstemp[${cavessetting_temp[3]}]}    ${CavesSetting1[4]}:${value12_chstemp[${cavessetting_temp[4]}]}    ${CavesSetting1[5]}:${value12_chstemp[${cavessetting_temp[5]}]}"
		message "${CavesSetting1[6]}:${value13_chstemp[${cavessetting_temp[6]}]}    ${CavesSetting1[7]}:${value1_chstemp[${cavessetting_temp[7]}]}    ${CavesSetting1[8]}:${value1_chstemp[${cavessetting_temp[8]}]}"
		message "${CavesSetting1[9]}:${value1_chstemp[${cavessetting_temp[9]}]}    ${CavesSetting1[10]}:${value1_chstemp[${cavessetting_temp[10]}]}"
		message ===================资源===========================
		message "${CavesSetting1[11]}:${value1_chstemp[${cavessetting_temp[11]}]}  ${CavesSetting1[12]}:${value1_chstemp[${cavessetting_temp[12]}]}  ${CavesSetting1[13]}:${value1_chstemp[${cavessetting_temp[13]}]}"
		message "${CavesSetting1[14]}:${value1_chstemp[${cavessetting_temp[14]}]}  ${CavesSetting1[15]}:${value1_chstemp[${cavessetting_temp[15]}]}  ${CavesSetting1[16]}:${value1_chstemp[${cavessetting_temp[16]}]}"
		message "${CavesSetting1[17]}:${value1_chstemp[${cavessetting_temp[17]}]}  ${CavesSetting1[18]}:${value1_chstemp[${cavessetting_temp[18]}]}  ${CavesSetting1[19]}:${value1_chstemp[${cavessetting_temp[19]}]}"
		message "${CavesSetting1[20]}:${value1_chstemp[${cavessetting_temp[20]}]}  ${CavesSetting1[21]}:${value1_chstemp[${cavessetting_temp[21]}]}"
		message ===================食物===========================
		message "${CavesSetting1[22]}:${value1_chstemp[${cavessetting_temp[22]}]}  ${CavesSetting1[23]}:${value1_chstemp[${cavessetting_temp[23]}]}  ${CavesSetting1[24]}:${value1_chstemp[${cavessetting_temp[24]}]}"
		message "${CavesSetting1[25]}:${value1_chstemp[${cavessetting_temp[25]}]}"
		message ===================动物===========================
		message "${CavesSetting1[26]}:${value1_chstemp[${cavessetting_temp[26]}]}  ${CavesSetting1[27]}:${value1_chstemp[${cavessetting_temp[27]}]}  ${CavesSetting1[28]}:${value1_chstemp[${cavessetting_temp[28]}]}"
		message "${CavesSetting1[29]}:${value1_chstemp[${cavessetting_temp[29]}]}  ${CavesSetting1[30]}:${value1_chstemp[${cavessetting_temp[30]}]}  ${CavesSetting1[31]}:${value1_chstemp[${cavessetting_temp[31]}]}"
		message ===================怪物===========================
		message "${CavesSetting1[32]}:${value1_chstemp[${cavessetting_temp[32]}]}  ${CavesSetting1[33]}:${value1_chstemp[${cavessetting_temp[33]}]}  ${CavesSetting1[34]}:${value1_chstemp[${cavessetting_temp[34]}]}"
		message "${CavesSetting1[35]}:${value1_chstemp[${cavessetting_temp[35]}]}  ${CavesSetting1[36]}:${value1_chstemp[${cavessetting_temp[36]}]}  ${CavesSetting1[37]}:${value1_chstemp[${cavessetting_temp[37]}]}" 
		message "${CavesSetting1[38]}:${value1_chstemp[${cavessetting_temp[38]}]}  ${CavesSetting1[39]}:${value1_chstemp[${cavessetting_temp[39]}]}"
		
		waring "输入你想修改的项目索引数字,什么都不输入直接回车视为结束"
		read temp
		if [ ${temp}x !=x ]
		then
			local str=$(echo $temp |grep -E "[^0-9]" -c)
			if [${str} -ne 0 ]	
			then
				error "你输入的不是纯数字，我觉得你按错了，重新输入一个吧"
				continue
			else
				if [ ${temp} -gt 39 ]
				then
					message "输入大于39"
				fi
				if [ ${temp} -lt 0 ]
				then	
					message "输入小于0"
				fi
				error "下面不再判断数字输入问题，你自己看好了，反正乱输肯定出问题。判断麻烦死了，十行代码九都在判断用户乱输入输错的情况，反正我默认你不会乱输，反正乱输肯定出问题"
				#从7"地震"开始，就是#never rare default often always这么选择
				if [ ${temp} -ge 7]
				then
					message "请选择[1]无[2]很少[3]默认[4]较多[5]很多"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					cavessetting_temp[${CavesSetting2[${CavesSetting1[${temp}]}]}]=${value1[${index}]}
				#创世界大小
				elif [ ${temp} -eq 0 ]
				then
					message "请选择[1]小[2]中[3]大[4]巨大"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					cavessetting_temp[${CavesSetting2[${CavesSetting1[${temp}]}]}]=${value4[${index}]}
				#创世界分支
				elif [ ${temp} -eq 1 ]
				then
					message "请选择[1]从不[2]最少[3]默认[4]最多[5]随机"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					cavessetting_temp[${CavesSetting2[${CavesSetting1[${temp}]}]}]=${value5[${index}]}	
				#创世界循环
				elif [ ${temp} -eq 2 ]
				then
					message "请选择[1]从不[2]默认[3]总是"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					cavessetting_temp[${CavesSetting2[${CavesSetting1[${temp}]}]}]=${value6[${index}]}	
				#世界再生
				elif [ ${temp} -eq 3 ]
				then
					message "请选择[1]极慢[2]慢[3]默认[4]快[5]极快"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					cavessetting_temp[${CavesSetting2[${CavesSetting1[${temp}]}]}]=${value11[${index}]}
				#洞穴光照
				elif [ ${temp} -eq 4 ]
				then
					message "请选择[1]无[2]随机[3]慢[4]默认[5]快"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					cavessetting_temp[${CavesSetting2[${CavesSetting1[${temp}]}]}]=${value12[${index}]}
				#疾病
				elif [ ${temp} -eq 5 ]
				then
					message "请选择[1]无[2]随机[3]慢[4]默认[5]快"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					cavessetting_temp[${CavesSetting2[${CavesSetting1[${temp}]}]}]=${value12[${index}]}
				#开始资源多样化
				elif [ ${temp} -eq 6 ]
				then
					message "请选择[1]经典[2]默认[3]高度随机"
					read temp2
					message "你选择了${temp2}"
					local index=`expr ${temp2} - 1`
					cavessetting_temp[${CavesSetting2[${CavesSetting1[${temp}]}]}]=${value13[${index}]}
				fi
			fi
		else
			waring "你选择了全部默认"
		fi
	done
	#选择完了就把存下来的写道世界设置的lua里
	#固定的开头
	echo "return {
  background_node_range={ 0, 1 },
  desc=\"探查洞穴…… 一起！\",
  hideminimap=false,
  id=\"DST_CAVE\",
  location=\"cave\",
  max_playlist_position=999,
  min_playlist_position=0,
  name=\"洞穴\",
  numrandom_set_pieces=0,
  override_level_string=false,
  overrides={" >  ./leveldataoverride.lua
	#改动过的中间部分
	for key in ${!cavessetting_temp[*]}
	do
		winter="default",
		local value=${cavessetting_temp[${key}]}
		#非最后一行都要加个逗号
		local douhao=
		if [ ${key} != "wormlights" ]
		then
			douhao=","
		fi
		echo "${key}=\"${value}\"${douhao}" >> ./leveldataoverride.lua
	done
	#固定的结尾
	echo "},
  required_prefabs={ \"multiplayer_portal\" },
  substitutes={  },
  version=4 
}" >>  ./leveldataoverride.lua
fi
cd ${curFolder}
}

#删除一个世界
function delworld
{
local curFolder=$(pwd)
message "你要删除哪个？输入名字"
read needrm
cd /root/.klei/DoNotStarveTogether/${archiveLocation}
if [ -d $needrm ]
then
	#删除之前，改动一下生成世界的几个参数，因为有可能删除一个核心世界，或者是最后一个世界
	#至于端口，就不动了，反正端口多的是
	cd /root/.klei/DoNotStarveTogether/${archiveLocation}/${needrm}
	#删除了一个核心世界
	local is_master_true=$(grep -E "is_master"  server.ini| grep "true" -c)
	if [ $is_master_true -eq 1 ]
	then
		is_master=fasle
	fi	
	cd /root/.klei/DoNotStarveTogether/${archiveLocation}
	local foldernumber=$(find /root/.klei/DoNotStarveTogether/${archiveLocation} -maxdepth 1 -type d| wc -l)
	
	#删除
	rm -rf /root/.klei/DoNotStarveTogether/${archiveLocation}/$needrm
	message 已经删除${needrm}这个世界的文件夹
	#第一个是自身名字
	if [ ${foldernumber}  -eq 1 ]
	then
		message 由于你删除了最后一个世界，为你自动生成一个地上核心世界......
		addworld
	fi
else
	error 你输入这个世界的文件夹不存在
fi
cd ${curFolder}
}

#列出存档内所有世界
function listworlds
{
local curFolder=$(pwd)
message 当前存档名字叫${archiveLocation}
message 以下是当前世界：
local foldernumber=$(find /root/.klei/DoNotStarveTogether/${archiveLocation} -maxdepth 1 -type d| wc -l)
local hasworld=false
#第一个是自身名字
for((i=1;i<${foldernumber};i++))
do
	hasworld=true
	#去除前面的路径
	p=`expr ${i} + 1`
	local temp=$(find /root/.klei/DoNotStarveTogether/${archiveLocation} -maxdepth 1 -type d|sed -n ${p}p|sed 's#.*/##')
	message ${temp}
done
if [ ${hasworld} == false ]
then
	waring 当前没有世界！
fi
cd ${curFolder}
}

#修改服务器配置项
function modifyserver
{
local curFolder=$(pwd)
#申请存档操作权限
while :
do
	message =======你要修改世界的哪个配置项==========
	message "[1]世界名字    [2]世界描述    [3]世界密码"
	message "[4]游戏模式    [5]人数上限    [6]是否pvp"
	message "[7]增加管理员  [8]删除管理员  [9]列出所有管理员"
	message "[10]改动令牌   [11]主世界服务器ip(多重世界)  [12]退出修改"
	read temp
		case $temp in
			1)
				message 输入你想要的名字
				read temp
				if [ ${temp}x != x ]
				then
					sed -i "/cluster_name/ccluster_name = ${temp}" /root/.klei/DoNotStarveTogether/${archiveLocation}/cluster.ini
					message 你的房间名字现在是${temp}
				else
					error 你输入了一个空名字！
				fi	
			;;
			2)
				message 输入你想要的描述
				read temp
				sed -i "/cluster_description/ccluster_description = ${temp}" /root/.klei/DoNotStarveTogether/${archiveLocation}/cluster.ini
				if [ ${temp}x != x ]
				then
					message 你的房间描述现在是${temp}
				else
					waring 你的房间描述现在是空的
				fi
				
			;;
			3)
				message 输入你想要的密码
				read temp
				sed -i "/cluster_password/ccluster_password = ${temp}" /root/.klei/DoNotStarveTogether/${archiveLocation}/cluster.ini
				if [ ${temp}x != x ]
				then
					message 你的密码现在是${temp}
				else
					waring 你的密码现在是空的
				fi
			;;
			4)
				message 输入你想要的模式
				message "[1]生存 [2]荒野 [3]无尽"
				game_mode=endless
				read temp
				if [ ${temp} -eq 1 ]
				then
					game_mode=survival
				elif [ ${temp} -eq 2 ]
				then
					game_mode=wilderness
				elif [ ${temp} -eq 3 ]
				then
					game_mode=endless
				fi
				sed -i "/game_mode/cgame_mode = ${game_mode}" /root/.klei/DoNotStarveTogether/${archiveLocation}/cluster.ini
				message 你的模式现在是${game_mode}
			;;
			5)
				message 输入你想要的人数上限
				read temp
				local str=$(echo $temp |grep -E "[^0-9]" -c)
				if [${str} -ne 0 ]	
				then
					error "错误！你输入的不是数字"
					continue
				fi
				sed -i "/max_players/cmax_players = ${temp}" /root/.klei/DoNotStarveTogether/${archiveLocation}/cluster.ini
				message 你的人数上限现在是${temp}
			;;
			6)
				message 输入你是否想要pvp
				message "[1]是 [2]否"
				pvp=false
				read temp
				if [ ${temp} -eq 1 ]
				then
					pvp=true
				elif [ ${temp} -eq 2 ]
				then
					pvp=false
				fi
				sed -i "/pvp/cpvp = ${pvp}" /root/.klei/DoNotStarveTogether/${archiveLocation}/cluster.ini
				message 现在pvp模式是${pvp}
			;;
			7)
				message 输入你想要增加的管理员的kleiID
				read temp
				if [ ${temp}x != x ]
				then
					echo "${temp}" >> /root/.klei/DoNotStarveTogether/${archiveLocation}/adminlist.txt
					message 你增加了一个kleiID叫做${temp}
				else
					error 你输入了空，不需要增加啊
				fi
				
			;;
			8)
				message 输入你想要删除的管理员的kleiID
				read temp
				hasthisID=$(grep "${temp}" -c /root/.klei/DoNotStarveTogether/${archiveLocation}/adminlist.txt)
				if [ ${hasthisID} -eq 0 ]
				then
					error 没有这个kleiID，不需要删除
				else
					if [ ${temp}x != x ]
					then
						sed -i "/${temp}/d" /root/.klei/DoNotStarveTogether/${archiveLocation}/adminlist.txt
						message 你删除了${temp}这个kleiID
					else
						error 你输入了空，啥也不干
					fi
				fi
			;;
			9)
				message 以下是所有管理员的kleiID
				cat /root/.klei/DoNotStarveTogether/${archiveLocation}/adminlist.txt
			;;
			10)
				message 你想要吧令牌改为？请输入
				read temp
				echo "${temp}" > /root/.klei/DoNotStarveTogether/${archiveLocation}/cluster_token.txt
				if [ ${temp}x != x ]
				then
					message 你的令牌现在是${temp}
				else
					waring 你现在令牌文件中没有令牌！
				fi
			;;
			11)
				message "输入你的主世界服务器ip(多重世界才需要修改这个)"
				read temp
				if [ ${temp}x != x ]
				then
					sed -i "/master_ip/cmaster_ip = ${temp}" /root/.klei/DoNotStarveTogether/${archiveLocation}/cluster.ini
					sed -i "/bind_ip/cbind_ip = 0.0.0.0" /root/.klei/DoNotStarveTogether/${archiveLocation}/cluster.ini
					message "主世界ip现在是${temp}"
				else
					waring 你输入了空，什么都不操作
				fi
			;;
			12)break
			;;
		esac		
done
cd ${curFolder}
}

#管理存档
function archivemanage
{
	local curFolder=$(pwd)
	archiveclose
	#申请存档操作权限
	exec 18<>/home/daoxinwudi/lockfile_Archive
	flock -x 18
	while :
	do
	message ===================================================================
	message "[1]修改服务器各种配置项 [2]增加一个地上世界    [3]增加一个地下世界"   
	message "[4]删除一个世界         [5]列出当前所有世界名字[6]退回上一级"
	message ===================================================================
	message "请输入你要操作的选项:"
		read temp
			case $temp in
				1)modifyserver
				;;
				2)addworld Master
				;;
				3)addworld Caves
				;;
				4)delworld
				;;
				5)listworlds
				;;
				6)break
				;;
			esac
	done
	flock -u 18
	cd ${curFolder}
}

#管理一下备份
function backsavemanage
{
	curFolder=$(pwd)
	backprepare
	cd $backsave_location
	while :
	do
	message ===============================================================
	message "[1]现在就备份一个!    [2]删除一个我觉的没用的    [3]恢复备份(会自动关闭世界再开启) "
	message "[4]列出所有存档       [5]退回上一级"
	message ===============================================================
		read temp
			case $temp in
				1)
					if [ -e /root/.klei/DoNotStarveTogether/${archiveLocation} ]
					then
						num=$(ls -t |grep -E "*" -c)
						if [ ${num} -ge ${backsave_maxnum} ]
						then
							waring 备份数量超了哦，你先删除一个吧
						else
							mkdir `date +%Y%m%d%H%M`
							cp -af /root/.klei/DoNotStarveTogether/${archiveLocation}  ./`date +%Y%m%d%H%M`
							echo "手动备份了一个，日期就是文件夹名字" >> /home/daoxinwudi/backsave.log
							message "你手动备份了一个，日期就是文件夹名字"
						fi
					else
						waring 你的备份文件夹还不存在呢，备份不了啊兄
					fi	
				;;
				2)
					read -p "你要删除哪个？输入名字" needrm
					if [ -d $needrm ]
					then
						rm -rf $needrm
					else
						error 你输入这个备份名字不存在
					fi
				;;
				3)
					read -p "你要恢复哪个？输入名字" needrecovery
					if [ -d $needrecovery ]
					then
						#然后复制文件过去
						rm -rf /root/.klei/DoNotStarveTogether/${archiveLocation} 
						cp -af ./$needrecovery/${archiveLocation} /root/.klei/DoNotStarveTogether/
						#然后开启世界
						startserver
					else
						error 你输入这个备份名字不存在
					fi
				;;
				4)
					num=$(ls -t |grep -E "*" -c)
					if [ $num -eq 0 ]
					then
						waring 你当前没有备份哦
					else
						message 这是你当前所有的备份
						ls -t
					fi
				;;
				5)break
				;;
			esac
	done
	cd ${curFolder}
}

#管理定时循环任务
function taskmanage
{
local curFolder=$(pwd)
while :
	do
	message ===============================================================
	message "[1]启动自动定时备份    [2]启动自动检测崩溃    [3]启动自动检测更新 "
	message "[4]关闭自动定时备份    [5]关闭自动检测崩溃    [6]关闭自动检测更新 "
	message "[7]退回上一级"
	message ===============================================================
		read temp
			case $temp in
				1)
					backprepare
					local isBacksaveStart=$(ps aux|grep "backsave.sh"| grep daoxinwudi -c)
					if [ ${isBacksaveStart} -ne 0 ]
					then
						waring 备份任务已经定时开始循环了！
					else
						#启动定时任务
						message "每隔多少分钟备份一次(10分钟8分钟备份一次简直是浪费存储空间-_-||)"
						local backuptime=0
						while read temp
						do
							if [ ${temp}x != x ]
							then
								if [ ${temp} -ne 0 ]
								then
									backuptime=${temp}
									break
								fi
							fi
						done
						#备份的脚本
						echo "#!/bin/bash
	curFolder=\$(pwd)
	sleeptime=\`expr ${backuptime} \\* 60\`
	while true
	do
		#最多 ${backsave_maxnum} 地址是 ${backsave_location}
		cd ${backsave_location}
		#申请存档操作权限
		#如果备份个数大于等于开始填写的backsave_maxnum就删除一个最先的
		foldernum=\$(ls |grep -E \"*\" -c)
			if [ \${foldernum} -ge ${backsave_maxnum} ]
			then
			echo 备份过多，删除一个最老的
			foldername=\$(ls -t |sed -n \${foldernum}p)
			rm -rf \${foldername}
			echo \"\`date +%Y%m%d%H%M\`,删除了一个最老的名字是\${foldername}\" 
		fi

		mkdir \`date +%Y%m%d%H%M\`
		#本来只需要复制存档中的backup和save文件夹就行，但是本着偷懒的原则-_-，就一起复制过来吧
		cp -af /root/.klei/DoNotStarveTogether/${archiveLocation}  ${backsave_location}/\`date +%Y%m%d%H%M\`
		echo \"\`date +%Y%m%d%H%M\`,自动备份了一个\" 
		echo 备份完了
		sleep \${sleeptime}
	done
	cd \${curFolder}" > /home/daoxinwudi/backsave.sh
						chmod +x /home/daoxinwudi/backsave.sh
						nohup /home/daoxinwudi/backsave.sh > /home/daoxinwudi/backsave.log 2>&1 &
						message "你开始了备份任务"
					fi
				;;
				2)
					
					#然后开启
					local isCheckworldStart=$(ps aux|grep "checkworld.sh"| grep daoxinwudi -c)
					if [ ${isCheckworldStart} -ne 0 ]
					then
						waring 定时检测世界崩溃任务已经定时开始循环了！
					else	
						#启动定时任务
						message 世界崩溃检测每隔几分钟检测一次呢？
						local checkworld_gaptime=0
						while read  temp
						do
							if [ ${temp}x != x ]
							then
								if [ ${temp} -ne 0 ]
								then
									checkworld_gaptime=$temp
									break
								fi
							fi
						done
						#检测崩溃的脚本
						echo "#!/bin/bash
curFolder=\$(pwd)
sleeptime=\`expr ${checkworld_gaptime} \\* 60\`
while true
do
	#遍历所有的世界，全都开启
	foldernumber=\$(find /root/.klei/DoNotStarveTogether/${archiveLocation} -maxdepth 1 -type d| wc -l)
	#第一个是自身名字
	if [ \${foldernumber}  -ne 1 ]
	then
		exec 9<>/home/daoxinwudi/lockfile_Process
		flock -x 9
		for((i=1;i<\${foldernumber};i++))
		do
			#去除前面的路径
			p=\`expr \${i} + 1\`
			worldfolder=\$(find /root/.klei/DoNotStarveTogether/${archiveLocation} -maxdepth 1 -type d|sed -n \${p}p|sed 's#.*/##')
			curworldPid=\$(ps aux|grep dontstarve_dedicated_server_nullrenderer | grep \"\\-shard \${worldfolder}\"|grep -E \"\\s[0-9]+\" -o |sed -n 1p|grep -E \"[0-9]+\")
			if [ \${curworldPid}x == x ]
			then
				echo \${worldfolder}这个世界消失了，重新启动这个
				startworldsuccess=false
				timeout=3
			
				#先清空日志文件，防止查询错误
				rm -f /root/.klei/DoNotStarveTogether/${archiveLocation}/\${worldfolder}/server_log.txt
				touch /root/.klei/DoNotStarveTogether/${archiveLocation}/\${worldfolder}/server_log.txt
				echo \" \" > /root/.klei/DoNotStarveTogether/${archiveLocation}/\${worldfolder}/server_log.txt
				#开启
				cd ${DSTserverFolder}/bin
				nohup ./dontstarve_dedicated_server_nullrenderer -console -cluster ${archiveLocation} -monitor_parent_process \$ -shard \${worldfolder} > /dev/null 2>&1 &
				echo \"正在开启\${worldfolder}世界...........预计3分钟左右，目前错误超时时间\${timeout}分钟,请不要退出\"
				echo \"为了屏幕上不显示一大片字，日志已经输出至/root/.klei/DoNotStarveTogether/${archiveLocation}/\${worldfolder}/server_log.txt\"
				timer=\`date +%M\`
				isStarted=fasle
				lastline=null
				while true
				do
					isStarted=\$(tail -n 200 /root/.klei/DoNotStarveTogether/${archiveLocation}/\${worldfolder}/server_log.txt |grep \"SteamGameServer_Init success\" -c)
					lastline_temp=\$(tail -n 1 /root/.klei/DoNotStarveTogether/${archiveLocation}/\${worldfolder}/server_log.txt)
					if [ \${isStarted} -ne 0 ]
					then
						startworldsuccess=true;
						break
					fi
					#检测超时
					temp=\`date +%M\`
					if [ \"${lastline_temp}x\" == \"${lastline}x\" ]
					then
						if [ \`expr \$temp - \$timer\` -ge \${timeout} ]
						then
							#已经超时timeout分钟了，认为没有成功开启
							startworldsuccess=false;
							break
						fi
					fi
					lastline=\${lastline_temp}
				done
				if [ \$startworldsuccess == true ]
				then
					echo \"你成功开启了\${worldfolder}这个世界\"
				else
					echo  \"开启\${worldfolder}超时了\${timeout}分钟还没开启，认为失败了\"
					#kill掉残留的进程
					worldPid=\$(ps aux|grep dontstarve_dedicated_server_nullrenderer | grep \"\\-shard \${worldfolder}\"|grep -E \"\\s[0-9]+\" -o |sed -n 1p|grep -E \"[0-9]+\")
					if [ \${worldPid}x != x ]
					then
						kill -9 \${worldPid}
					fi
				fi
			else
				echo \${worldfolder}这个世界没问题，pid是\${curworldPid}
			fi
			
			
		done
		flock -u 9
	fi
	sleep \${sleeptime}
	cd \${curFolder}
done
" >> /home/daoxinwudi/checkworld.sh
						chmod +x /home/daoxinwudi/checkworld.sh
						nohup /home/daoxinwudi/checkworld.sh > /home/daoxinwudi/checkworld.log 2>&1 &
						message "你开始了定时检测世界崩溃任务"
					fi
				;;
				3)
					local isCheckupdateStart=$(ps aux|grep "updatecheck.sh"| grep daoxinwudi -c)
					if [ ${isCheckupdateStart} -ne 0 ]
					then
						waring 定时检测更新任务已经定时开始循环了！
					else	
						#启动定时任务
						message 每隔多少分钟检测一次更新（检测到更新会自动重启）？
						local updateTime=0
						while read temp
						do
							if [ ${temp}x != x ]
							then
								if [ ${temp} -ne 0 ]
								then
									updateTime=$temp
									break
								fi
							fi
						done
						#检测更新的脚本
						echo "#!/bin/bash
curFolder=\$(pwd)
sleeptime=\`expr ${updateTime} \\* 60\`
while true
do
	#获取本地版本号,存在安装的目录下之//steamapps/appmanifest_343050.acf中的buildid字段
	appmanifestFile=\$(find \"${DSTserverFolder}\" -type f -name \"appmanifest_343050.acf\")
	localVersion=\$(grep buildid \"\${appmanifestFile}\" |grep -E \"[0-9]+\" -o)
	echo \`date +%Y%m%d%H%M\`本地版本号\${localVersion} 	
	remoteVersion=\$(/home/steamcmd/steamcmd.sh +login anonymous +app_info_update 1 +app_info_print 343050 +quit |grep -E \"public\" -A 2| grep -E \"buildid.*[0-9]+\"|grep -E \"[0-9]+\" -o)	
	echo \`date +%Y%m%d%H%M\`远程版本号\${remoteVersion} 	
	if [ \"\${localVersion}\" != \"\${remoteVersion}\" ]
	then
		echo \`date +%Y%m%d%H%M\`版本号不等，开始更新喽 
		#先关闭世界
		#申请操作Master进程锁的权限
		exec 23<>/home/daoxinwudi/lockfile_Process
		flock -x 23
		worldnumber=\$(ps aux|grep dontstarve_dedicated_server_nullrenderer | grep \"\\-shard\" -c)
		for((i=1;i<=\${worldnumber};i++))
		do
			worldPid=\$(ps aux|grep dontstarve_dedicated_server_nullrenderer | grep \"\\-shard\"|sed -n \${i}p |grep -E \"\\s[0-9]+\" -o |sed -n 1p|grep -E \"[0-9]+\")
			kill -9 \${worldPid}
		done
		echo 更新前关闭了\${worldnumber}个世界！
		
		#更新
		exec 22<>/home/daoxinwudi/lockfile_Steamcmd
		flock -x 22
		#更新之前先保存一下dedicated_server_mods_setup.lua，因为更新会清空这个文件
		#当你新增了一个mod，而还没有下载，更新后新增的就消失了
		cp -f ${DSTserverFolder}/mods/dedicated_server_mods_setup.lua ${DSTserverFolder}/mods/dedicated_server_mods_setup_backup.lua
		/home/steamcmd/steamcmd.sh +login anonymous +force_install_dir ${DSTserverFolder} +app_update 343050 validate +quit
		#恢复此文件
		cp -f ${DSTserverFolder}/mods/dedicated_server_mods_setup_backup.lua ${DSTserverFolder}/mods/dedicated_server_mods_setup.lua
		rm -f ${DSTserverFolder}/mods/dedicated_server_mods_setup_backup.lua
		flock -u 22
		#然后开启世界
		foldernumber=\$(find /root/.klei/DoNotStarveTogether/${archiveLocation} -maxdepth 1 -type d| wc -l)
		#第一个是自身名字
		if [ \${foldernumber}  -ne 1 ]
		then
			for((i=1;i<\${foldernumber};i++))
			do
				startworldsuccess=false
				timeout=3
				#去除前面的路径
				p=\`expr \${i} + 1\`
				worldfolder=\$(find /root/.klei/DoNotStarveTogether/${archiveLocation} -maxdepth 1 -type d|sed -n \${p}p|sed 's#.*/##')
				#先清空日志文件，防止查询错误
				rm -f /root/.klei/DoNotStarveTogether/${archiveLocation}/\${worldfolder}/server_log.txt
				touch /root/.klei/DoNotStarveTogether/${archiveLocation}/\${worldfolder}/server_log.txt
				echo " " > /root/.klei/DoNotStarveTogether/${archiveLocation}/\${worldfolder}/server_log.txt
				#开启,一定要cd到这个目录，不然这个程序跑不起来，他应该设定了工作目录
				cd ${DSTserverFolder}/bin
				nohup ./dontstarve_dedicated_server_nullrenderer -console -cluster ${archiveLocation} -monitor_parent_process \$ -shard \${worldfolder} > /dev/null 2>&1 &
				echo \"正在开启\${worldfolder}世界...........预计3分钟左右，目前错误超时时间\${timeout}分钟,请不要退出\"
				timer=\`date +%M\`
				isStarted=fasle
				lastline=null
				while true
				do
					isStarted=\$(tail -n 200 /root/.klei/DoNotStarveTogether/${archiveLocation}/\${worldfolder}/server_log.txt |grep \"SteamGameServer_Init success\" -c)
					lastline_temp=\$(tail -n 1 /root/.klei/DoNotStarveTogether/${archiveLocation}/\${worldfolder}/server_log.txt)
					if [ \${isStarted} -ne 0 ]
					then
						startworldsuccess=true;
						break
					fi
					#检测超时
					temp=\`date +%M\`
					if [ \"\${lastline_temp}x\" == \"\${lastline}x\" ]
					then
						if [ \`expr \$temp - \$timer\` -ge \${timeout} ]
						then
							#已经超时timeout分钟了，认为没有成功开启
							startworldsuccess=false;
							break
						fi
					fi
					lastline=\${lastline_temp}
				done
				if [ \$startworldsuccess == true ]
				then
					echo \"你成功开启了\${worldfolder}这个世界\"
				else
					echo \"开启\${worldfolder}超时了\${timeout}分钟还没开启，认为失败了最后一句话是\${lastline}\"
					#kill掉残留的进程
					worldPid=\$(ps aux|grep dontstarve_dedicated_server_nullrenderer | grep \"\\-shard \${worldfolder}\"|grep -E \"\\s[0-9]+\" -o |sed -n 1p|grep -E \"[0-9]+\")
					if [ \${worldPid}x != x ]
					then
						kill -9 \${worldPid}
					fi
				fi
			done
		fi
		flock -u 23
	fi
sleep \${sleeptime}
done
cd \${curFolder}" > /home/daoxinwudi/updatecheck.sh
						chmod +x /home/daoxinwudi/updatecheck.sh
						nohup /home/daoxinwudi/updatecheck.sh > /home/daoxinwudi/updatecheck.log 2>&1 &
						message "你开始了定时检测更新任务"
					fi
				;;
				4)
					local backPid=$(ps aux|grep "backsave.sh"| grep daoxinwudi| grep -E "\s[0-9]+" -o |sed -n 1p|grep -E "[0-9]+")
					if [ ${backPid}x != x ]
					then
						kill -9 ${backPid}
						message "已经关闭定时备份的任务"
					else
						waring "当前没有定时备份的任务，不需要关闭"
					fi
				;;
				5)	
					local checkWorldPid=$(ps aux|grep "checkworld.sh"| grep daoxinwudi| grep -E "\s[0-9]+" -o |sed -n 1p|grep -E "[0-9]+")
					if [ ${checkWorldPid}x != x ]
					then
						kill -9 ${checkWorldPid}
						message "已经杀掉检测崩溃的进程"
					else
						waring "当前没有定时检测崩溃的任务，不需要关闭"
					fi
				;;
				6)
					local updatecheckPid=$(ps aux|grep "updatecheck.sh"| grep daoxinwudi| grep -E "\s[0-9]+" -o |sed -n 1p|grep -E "[0-9]+")
					if [ ${updatecheckPid}x != x ]
					then
						kill -9 ${updatecheckPid}
						message "已经杀掉检测更新的进程"
					else
						waring "当前没有定时检测更新的任务，不需要关闭"
					fi
				;;
				7)break
				;;
			esac
	done
cd ${curFolder}
}

#重置所有设置
function Reset
{
	local curFolder=$(pwd)
	waring 这个操作会删除所有配置文件（不用担心丢失文件，都是操作的过程中生成的）
	#删除整个daoxinwudi目录，包括里面的各种文件
	rm -rf /home/daoxinwudi
	message "已经删除所有配置文件"
	cd ${curFolder}
}

#一些使用方法说明
function readme
{
message 0.这里是一些小说明
message 1.此脚本主要功能如主列表所示，其中mod、存档、备份、服务器操作相关都需要先有存档，所以这些操作之前都会提醒创建或者改动存档
message 2.更新和检测崩溃后会更改核心程序的开启，操作世界和操作mod会更改存档，所以这些操作不允许同时进行，会自动关闭
message 3.有三种自动任务，更新、检测崩溃和备份任务，开启后会按照设定的时间无限循环
message 4.开启服务器会顺次开启存档下所有世界（意味着你可以开启多重世界）
message 5.第一个脚本生成的地上世界会默认写成核心世界，如果你已经有了核心世界则不会这么做
message 6.由于饥荒服务器程序可用的端口是有限的，所以其实你能创建的世界个数也是有限的,
message 7.生成世界中各种设置那个，其实可以用客户端开启一个世界，然后复制文件夹下面的leveldataoverride.lua，服务器端用的和这个一样的
message 8.多重世界需要在cluster.ini改动主世界服务器ip
error "重要提示，mod管理和存档管理目前不可用，最好不要用,即5，7，8选项不可用"
}

function Main()
{
#打开之前告诉你当前有什么
local Masternumber=0;
local Cavesnumber=0;
local worldnumber=$(ps aux|grep dontstarve_dedicated_server_nullrenderer | grep "\-shard" -c)
for((i=1;i<=${worldnumber};i++))
do
	local Master=$(ps aux|grep dontstarve_dedicated_server_nullrenderer | grep "\-shard"|sed -n ${i}p |grep -E "(m|M)aster" -c )
	local Caves=$(ps aux|grep dontstarve_dedicated_server_nullrenderer | grep "\-shard"|sed -n ${i}p |grep -E "(C|c)aves" -c )
	Masternumber=`expr ${Masternumber} + ${Master}` 
	Cavesnumber=`expr ${Cavesnumber} + ${Caves}` 
done
local updatecheckPid=$(ps aux|grep "updatecheck.sh"| grep daoxinwudi| grep -E "\s[0-9]+" -o |sed -n 1p|grep -E "[0-9]+")
local checkWorldPid=$(ps aux|grep "checkworld.sh"| grep daoxinwudi| grep -E "\s[0-9]+" -o |sed -n 1p|grep -E "[0-9]+")
local backPid=$(ps aux|grep "backsave.sh"| grep daoxinwudi| grep -E "\s[0-9]+" -o |sed -n 1p|grep -E "[0-9]+")
message "现在进入主程序"
echo    "系统输出是白色"
message "我输出的信息提示是绿色"
waring  "我输出的警告信息是黄色"
error   "我输出的错误信息是红色"
if [ ${Masternumber} -ne 0 ]
then
	message "世界：${Masternumber}个地上世界"
fi
if [ ${Cavesnumber} -ne 0 ]
then
	message "世界：${Cavesnumber}个地下世界"
fi
if [ ${updatecheckPid}x != x ]
then
	message "自动更新任务：已经开启"
fi
if [ ${checkWorldPid}x != x ]
then
	message "自动检测崩溃任务：已经开启"
fi
if [ ${backPid}x != x ]
then
	message "自动定时备份任务：已经开启"
fi
while :
do
message ===识别到当前存档位置/root/.klei/DoNotStarveTogether/${archiveLocation}===
message "[1]下载饥荒服务器程序    [2]启动服务器    [3]关闭服务器"
message "[4]更新服务器            [5]存档管理      [6]管理自动任务(检测崩溃、检测更新、备份)"
message "[7]mod管理               [8]备份管理      [9]重置所有设置"
message "[10]一些说明             [11]关闭脚本"
message ===============================================================
	read main1
		case $main1 in
			1)download
			;;
			2)startserver
			;;
			3)closeserver
			;;
			4)updateserver
			;;
			5)archivemanage
			;;
			6)taskmanage
			;;
			7)modmanage
			;;
			8)backsavemanage
			;;
			9)Reset
			;;
			10)readme
			;;
			11)exit
			;;
		esac
done
}

function prepare
{
local curFolder=$(pwd)
#创建daoxinwudi目录来存放临时文件
if [ ! -d /home/daoxinwudi ]
then
	mkdir daoxinwudi
fi
#为创建世界用到的几个参数赋值
#第一个找到的存档文件夹作为当前世界，我认为不会有人在这里创建多个文件夹
hasarchive=$(find /root/.klei/DoNotStarveTogether -maxdepth 1 -type d|wc -l)
if [ ${hasarchive} -eq 0 ]
then
	waring 识别到你还没有存档目录，为你创建存档目录daoxinwudi
	mkdir -p /root/.klei/DoNotStarveTogether/daoxinwudi
	archiveLocation=daoxinwudi
	message 在存档目录下创建了世界配置文件，令牌文件和管理员文件
	touch /root/.klei/DoNotStarveTogether/daoxinwudi/adminlist.txt
	echo "[GAMEPLAY]
game_mode = endless
max_players = 6
pvp = false
pause_when_empty = true

[NETWORK]
cluster_description = 使用道心无敌的自动脚本自动生成的世界
cluster_name =道心无敌自动生成的世界
cluster_intention = cooperative
cluster_password =
cluster_language = zh

[MISC]
console_enabled = true

[SHARD]
shard_enabled = true
bind_ip = 127.0.0.1
master_ip = 127.0.0.1
master_port = 10889
cluster_key = supersecretkey" > /root/.klei/DoNotStarveTogether/daoxinwudi/cluster.ini
	touch /root/.klei/DoNotStarveTogether/daoxinwudi/cluster_token.txt
	waring ========提醒你现在可以为新存档修改配置项=======
	waring ========你也可以现在不改，后续再改=======
	modifyserver
	#自动生成一个世界
	message 为你自动生成一个地上核心世界......
	addworld
else
	archiveLocation=$(find /root/.klei/DoNotStarveTogether -maxdepth 1 -type d|sed -n 2p|sed 's#.*/##')
	#查询当前世界的参数，为生成世界的参数赋值
	cd /root/.klei/DoNotStarveTogether/${archiveLocation}
	local foldernumber=$(find /root/.klei/DoNotStarveTogether/${archiveLocation} -maxdepth 1 -type d| wc -l)
	#第一个是自身名字
	if [ ${foldernumber}  -ne 1 ]
	then
		existedworldname=$(find /root/.klei/DoNotStarveTogether/${archiveLocation} -maxdepth 1 -type d|sed -n 2p|sed 's#.*/##')
		for((i=1;i<${foldernumber};i++))
		do
			#去除前面的路径
			local p=`expr ${i} + 1`
			local temp=$(find /root/.klei/DoNotStarveTogether/${archiveLocation} -maxdepth 1 -type d|sed -n ${p}p|sed 's#.*/##')
			cd /root/.klei/DoNotStarveTogether/${archiveLocation}/${temp}
			#各个数值
			local server_port_temp=$(grep -E "server_port" server.ini|sed -n 1p| grep -E "[0-9]+" -o)
			if [ ${server_port_temp} -ge $server_port ]
			then
				server_port=${server_port_temp}
			fi
			local master_server_port_temp=$(grep -E "master_server_port" server.ini| grep -E "[0-9]+" -o)
			if [ ${master_server_port_temp} -ge $master_server_port ]
			then
				master_server_port=${master_server_port_temp}
			fi
			local authentication_port_temp=$(grep -E "authentication_port"  server.ini| grep -E "[0-9]+" -o)
			if [ ${authentication_port_temp} -ge $authentication_port ]
			then
				authentication_port=${authentication_port_temp}
			fi
			local id_temp=$(grep -E "id"  server.ini| grep -E "[0-9]+" -o)
			if [ ${id_temp} -ge $id ]
			then
				id=${id_temp}
			fi
			local is_master_true=$(grep -E "is_master"  server.ini| grep "true" -c)
			if [ $is_master_true -eq 1 ]
			then
				is_master=fasle
			fi	
		done
		server_port=`expr ${server_port} + 1`
		master_server_port=`expr ${master_server_port} + 1`
		authentication_port=`expr ${authentication_port} + 1`
		id=`expr ${id} + 1`
	else
		message 识别到你有存档，没有世界，为你自动生成一个地上核心世界......
		addworld
	fi
fi
#创建几个用来当锁操作的文件,防止互相操作，破坏文件
if [ ! -f /home/daoxinwudi/lockfile_Process ]
then
	touch /home/daoxinwudi/lockfile_Process
fi
if [ ! -f /home/daoxinwudi/lockfile_Archive ]
then
	touch /home/daoxinwudi/lockfile_Archive
fi
if [ ! -f /home/daoxinwudi/lockfile_Steamcmd ]
then
	touch /home/daoxinwudi/lockfile_Steamcmd
fi
cd ${curFolder}
}
prepare
Main



