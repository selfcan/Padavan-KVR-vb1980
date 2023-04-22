#!/bin/bash

/usr/bin/aria.sh stop

aria_config_file="/media/AiCard_01/aria/config/aria2.conf" #修改为你的aria2.conf的绝对地址

list=`wget --no-check-certificate -q -O - https://cdn.jsdelivr.net/gh/XIU2/TrackersListCollection/best_aria2.txt|awk NF|sed ":a;N;s/\n/,/g;ta"`

if [ -z "`grep "bt-tracker" ${aria_config_file}`" ]; then

sed -i '$a bt-tracker='${list} ${aria_config_file}

echo 添加"bt-tracker="前缀...

else

sed -i "s@bt-tracker.*@bt-tracker=$list@g" ${aria_config_file}

echo 升级完成...

fi

/usr/bin/aria.sh restart
