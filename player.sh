#!/bin/bash
DST_conf_dirname="DoNotStarveTogether"
DST_conf_basedir="$HOME/.klei"

function getplayerlist() {
  if [[ $(screen -ls | grep -c "DST_MASTER") > 0 ]]; then
    allplayerslist=$(date +%s%3N)
    screen -S "DST_MASTER" -p 0 -X stuff "for i, v in ipairs(TheNet:GetClientTable()) do  print(string.format(\"playerlist %s [%d] %s %s %s\", $allplayerslist, i-1, v.userid, v.name, v.prefab )) end$(printf \\r)"
    sleep 1
    list=$(grep "${DST_conf_basedir}/${DST_conf_dirname}/MyDediServer/Master/server_log.txt" -e "playerlist $allplayerslist" | cut -d ' ' -f 4-15 | tail -n +2)
    if [[ ! "$list" == "" ]]; then
      echo -e "\e[92m服务器玩家列表：\e[0m"
      echo -e "\e[92m================================================================================\e[0m"
      echo "$list"
      echo -e "\e[92m================================================================================\e[0m"
#      echo "$list" >$HOME/.klei/playerlist.txt
    fi
  fi
  if [[ $(screen -ls | grep -c "DST_MASTER") == 0 && $(screen -ls | grep -c "DST_CAVES") > 0 ]]; then
    allplayerslist=$(date +%s%3N)
    screen -S "DST_CAVES" -p 0 -X stuff "for i, v in ipairs(TheNet:GetClientTable()) do  print(string.format(\"playerlist %s [%d] %s %s %s\", $allplayerslist, i-1, v.userid, v.name, v.prefab)) end$(printf \\r)"
    sleep 1
    list=$(grep "${DST_conf_basedir}/${DST_conf_dirname}/MyDediServer/Caves/server_log.txt" -e "playerlist $allplayerslist" | cut -d ' ' -f 4-15 | tail -n +2)
    if [[ ! "$list" == "" ]]; then
      echo -e "\e[92m服务器玩家列表：\e[0m"
      echo -e "\e[92m================================================================================\e[0m"
      echo "$list"
      echo -e "\e[92m================================================================================\e[0m"
#      echo "$list" >$HOME/.klei/playerlist.txt
    fi
  fi
}

getplayerlist
