#!/bin/sh
upanPath="`df -m | grep /dev/mmcb | grep -E "$(echo $(/usr/bin/find /dev/ -name 'mmcb*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && upanPath="`df -m | grep /dev/sd | grep -E "$(echo $(/usr/bin/find /dev/ -name 'sd*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
alist="$upanPath/alist/alist"
[ -z "$upanPath" ] && alist="/tmp/alist/alist"
datasize="$( du -h /etc/storage/alist/data/data.db-wal | awk '{print $1}')"
alist_restart () {
    if [ -z "`pidof alist`" ] ; then
    logger -t "【AList】" "重新启动"
    alist_start
    fi
}

alist_keep () {
logger -t "【AList】" "守护进程启动"
cronset '#alist守护进程' "*/1 * * * * test -z \"\$(pidof alist)\" && /etc/storage/alist.sh restart #alist守护进程"
}


alist_start() {
if [ -z "$upanPath" ] ; then 
   Available_A=$(df -m | grep "% /tmp" | awk 'NR==1' | awk -F' ' '{print $4}')
   echo $Available_A
   Available_A="$(echo "$Available_A" | tr -d 'M' | tr -d '')"
   if [ "$Available_A" -lt 10 ];then
   logger -t "【AList】" "无法下载alist,当前/tmp分区只剩$Available_A M，请插U盘使用，或尝试在系统管理-固件升级页面点击扩大/tmp按钮后重新启动脚本，即将退出..."
   exit 1
   fi
   etcsize=$(df -m | grep "% /etc" | awk 'NR==1' | awk -F' ' '{print $4}'| tr -d 'M')
   tag=$(curl -k --silent "https://api.github.com/repos/lmq8267/alist/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
   [ -z "$tag" ] && tag="$( curl -k -L --connect-timeout 20 --silent https://api.github.com/repos/lmq8267/alist/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
   [ -z "$tag" ] && tag="$( curl -k --connect-timeout 20 --silent https://api.github.com/repos/lmq8267/alist/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
   [ -z "$tag" ] && tag="$( curl -k --connect-timeout 20 -s https://api.github.com/repos/lmq8267/alist/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
   [ ! -s "$(which curl)" ] && tag="$( wget -T 5 -t 3 --no-check-certificate --output-document=-  https://api.github.com/repos/lmq8267/alist/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
   [ -z "$tag" ] && tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/lmq8267/alist/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f96 )"
   alistdb="/etc/storage/alist/data/data.db"
   [ -L /etc/storage/alist/data/data ] && rm -rf /etc/storage/alist/data/data
   [ ! -d /etc/storage/alist/data ] && mkdir -p /etc/storage/alist/data
   [ ! -d /tmp/alist/temp ] && mkdir -p /tmp/alist/temp
   rm -rf /tmp/alist/data
   rm -rf /home/root/data
   rm -rf /home/admin/data /etc/storage/alist/temp
   ln -sf /tmp/alist/temp /etc/storage/alist/temp
   ln -sf /etc/storage/alist/data /home/root/data
   ln -sf /etc/storage/alist/data /tmp/alist/data
   ln -sf /etc/storage/alist/data /home/admin/data
   down=1
   while [ ! -s "$alist" ] ; do
    down=`expr $down + 1`
    logger -t "【AList】" "未挂载储存设备, 将下载Mini版8M安装在/tmp/alist/alist,当前/tmp分区剩余$Available_A M"
     if [ ! -z "$tag" ] ; then
      logger -t "【AList】" "获取到最新alist_v$tag,开始下载..."
      [ -s "$(which curl)" ] && curl -L -k -S -o  /tmp/alist/MD5.txt  --connect-timeout 10 --retry 3 https://fastly.jsdelivr.net/gh/lmq8267/alist@master/install/$tag/MD5.txt
      [ ! -s "$(which curl)" ] && wget --no-check-certificate -O /tmp/alist/MD5.txt https://fastly.jsdelivr.net/gh/lmq8267/alist@master/install/$tag/MD5.txt
      [ -s "$(which curl)" ] && curl -L -k -S -o  $alist  --connect-timeout 10 --retry 3 https://fastly.jsdelivr.net/gh/lmq8267/alist@master/install/$tag/alist
      [ ! -s "$(which curl)" ] && wget --no-check-certificate -O $alist https://fastly.jsdelivr.net/gh/lmq8267/alist@master/install/$tag/alist
      else
      logger -t "【AList】" "未获取到最新版,开始下载备用版本alist_v3.16.0..."
      [ -s "$(which curl)" ] && curl -L -k -S -o  /tmp/alist/MD5.txt  --connect-timeout 10 --retry 3 https://fastly.jsdelivr.net/gh/lmq8267/alist@master/install/3.16.0/MD5.txt
      [ ! -s "$(which curl)" ] && wget --no-check-certificate -O /tmp/alist/MD5.txt https://fastly.jsdelivr.net/gh/lmq8267/alist@master/install/3.16.0/MD5.txt 
      [ -s "$(which curl)" ] && curl -L -k -S -o  $alist  --connect-timeout 10 --retry 3 https://fastly.jsdelivr.net/gh/lmq8267/alist@master/install/3.16.0/alist
      [ ! -s "$(which curl)" ] && wget --no-check-certificate -O $alist https://fastly.jsdelivr.net/gh/lmq8267/alist@master/install/3.16.0/alist
      fi
      if [ -s $alist ] && [ -s /tmp/alist/MD5.txt ]; then
         alistmd5="$(cat /tmp/alist/MD5.txt)"
         eval $(md5sum "$alist" | awk '{print "MD5_down="$1;}') && echo "$MD5_down"
         if [ "$alistmd5"x = "$MD5_down"x ] ; then
            logger -t "【AList】" "程序下载完成，MD5匹配，开始安装..."
            chmod 777 $alist
          else
            logger -t "【AList】" "程序下载完成，MD5不匹配，删除..."
            rm -rf $alist
            rm -rf /tmp/alist/MD5.txt
         fi
	else
          logger -t "【AList】" "程序下载不完整，删除..."
            rm -rf $alist
            rm -rf /tmp/alist/MD5.txt
      fi
      if [ ! -s "$alist" ] && [ "$Available_A" -gt 17 ]; then
         logger -t "【AList】" "程序下载失败，尝试下载alist压缩包..."
         if [ ! -z "$tag" ] ; then
         [ -s "$(which curl)" ] && curl -L -k -S -o  /tmp/alist/MD5.txt  --connect-timeout 10 --retry 3 https://github.com/lmq8267/alist/releases/download/$tag/MD5.txt
          [ ! -s "$(which curl)" ] && wget --no-check-certificate -O /tmp/alist/MD5.txt https://github.com/lmq8267/alist/releases/download/$tag/MD5.txt
          [ -s "$(which curl)" ] && curl -L -k -S -o  /tmp/alist/alist.tar.gz  --connect-timeout 10 --retry 3 https://github.com/lmq8267/alist/releases/download/$tag/alist.tar.gz
          [ ! -s "$(which curl)" ] && wget --no-check-certificate -O /tmp/alist/alist.tar.gz https://github.com/lmq8267/alist/releases/download/$tag/alist.tar.gz
          else
          [ -s "$(which curl)" ] && curl -L -k -S -o  /tmp/alist/MD5.txt  --connect-timeout 10 --retry 3 https://github.com/lmq8267/alist/releases/download/3.16.0/MD5.txt
          [ ! -s "$(which curl)" ] && wget --no-check-certificate -O /tmp/alist/MD5.txt https://github.com/lmq8267/alist/releases/download/3.16.0/MD5.txt 
          [ -s "$(which curl)" ] && curl -L -k -S -o  /tmp/alist/alist.tar.gz  --connect-timeout 10 --retry 3 https://github.com/lmq8267/alist/releases/download/3.16.0/alist.tar.gz
          [ ! -s "$(which curl)" ] && wget --no-check-certificate -O /tmp/alist/alist.tar.gz https://github.com/lmq8267/alist/releases/download/3.16.0/alist.tar.gz
         fi
	 if [ -s /tmp/alist/alist.tar.gz ] && [ -s /tmp/alist/MD5.txt ]; then
         alitarmd5="$(cat /tmp/alist/MD5.txt)"
         eval $(md5sum "/tmp/alist/alist.tar.gz" | awk '{print "MD5_downtar="$1;}') && echo "$MD5_downtar"
         if [ "$alitarmd5"x = "$MD5_downtar"x ] ; then
            logger -t "【AList】" "程序压缩包下载完成，MD5匹配，开始解压..."
            tar -xzvf /tmp/alist/alist.tar.gz -C /tmp/alist
	    rm -rf /tmp/alist/alist.tar.gz
          else
            logger -t "【AList】" "程序压缩包下载完成，MD5不匹配，删除..."
            rm -rf /tmp/alist/alist.tar.gz
            rm -rf /tmp/alist/MD5.txt
         fi
       fi
      fi
   [ ! -s "$alist" ] && [ "$down" -gt "5" ] && logger -t "【AList】" "程序多次下载失败，将于5分钟后再次尝试下载..." && sleep 300 && down=1
   done
   chmod 777 $alist
   $alist stop
   killall alist
   $alist version >/tmp/alist/alist.version
   alist_ver=$(cat /tmp/alist/alist.version | grep -Ew "^Version" | awk '{print $2}')
   [ -z "$alist_ver" ] &&  logger -t "【AList】" "程序不完整，重新下载..." && rm -rf $alist && sleep 10 && alist_down
   [ ! -z "$alist_ver" ] && logger -t "【AList】" "当前$alist 版本$alist_ver,准备启动"
   if [ ! -f "/etc/storage/alist/data/data.db" ] ; then
    #$alist admin > /etc/storage/alist/data/admin.account 2>&1
    $alist --data /etc/storage/alist/data admin >/etc/storage/alist/data/admin.account 2>&1
    user=$(cat /etc/storage/alist/data/admin.account | grep -E "^username" | awk '{print $2}')
    pass=$(cat /etc/storage/alist/data/admin.account | grep -E "^password" | awk '{print $2}')
    [ -n "$user" ] && logger -t "【AList】" "检测到首次启动alist，初始用户:$user  初始密码:$pass"
    [ ! -n "$user" ] && logger -t "【AList】" "检测到首次启动alist，生成初始用户密码失败" && logger -t "【AList】" "请在ttyd或ssh里输入此脚本启动一次获取密码"
    fi
    $alist --data /etc/storage/alist/data server >/tmp/alist/alistserver.txt 2>&1 &
    sleep 10
    logger -t "【AList】" "当前闪存/etc/storage剩余$etcsize M，alist配置文件/etc/storage/alist/data/data.db-wal $datasize"
    [ "$etcsize" -le 2 ] && logger -t "【AList】" "若alist配置文件超过1500k，或闪存/stc/storage空间不足，可尝试在alist主页进行备份，然后再恢复备份来减少配置文件的大小"
datafile="$(cat /etc/storage/alist/data/config.json | grep temp_dir | awk -F '"' '{print $4}')"
datalog="$(cat /etc/storage/alist/data/config.json | grep enable | awk '{print $2}' | tr -d "," )"
[ "$datafile" = "/etc/storage/alist/data/temp" ] && sed -i 's|"temp_dir": "/etc/storage/alist/data/temp",|"temp_dir": "/etc/storage/alist/temp",|g' "/etc/storage/alist/data/config.json"
[ "$datalog" = "true" ] && sed -i 's|"enable": true,|"enable": false,|g' "/etc/storage/alist/data/config.json"
    $alist --data /etc/storage/alist/data server >/tmp/alist/alistserver.txt 2>&1 &
 [ ! -z "`pidof alist`" ] && logger -t "【AList】" "alist主页:`nvram get lan_ipaddr`:5244" && logger -t "【AList】" "启动成功" && alist_keep
 [ -z "`pidof alist`" ] && logger -t "【AList】" "主程序启动失败, 10 秒后自动尝试重新启动" && sleep 10 && alist_restart
else
   alistdb="/etc/storage/alist/data/data.db"
   [ ! -d /etc/storage/alist/data ] && mkdir -p /etc/storage/alist/data
   [ -L "$upanPath/alist/data" ] && rm -rf $upanPath/alist/data
   [ -L /etc/storage/alist/data/data ] && rm -rf /etc/storage/alist/data/data
   rm -rf /home/root/data
   rm -rf /home/admin/data
   rm -rf /etc/storage/alist/data/temp
   [ ! -d "$upanPath/alist/temp" ] &&  mkdir -p $upanPath/alist/temp
   [ -d /etc/storage/alist/data ] && [ ! -d $upanPath/alist/data ] && cp -rf /etc/storage/alist/data $upanPath/alist/data
   ln -sf $upanPath/alist/data /home/root/data
   ln -sf $upanPath/alist/data /home/admin/data
   ln -sf $upanPath/alist/temp /etc/storage/alist/temp
   tag=$(curl -k --silent "https://api.github.com/repos/alist-org/alist/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
	[ -z "$tag" ] && tag="$( curl -k -L --connect-timeout 20 --silent https://api.github.com/repos/alist-org/alist/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
	[ -z "$tag" ] && tag="$( curl -k --connect-timeout 20 --silent https://api.github.com/repos/alist-org/alist/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
	[ -z "$tag" ] && tag="$( curl -k --connect-timeout 20 -s https://api.github.com/repos/alist-org/alist/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
	[ ! -s "$(which curl)" ] && tag="$( wget -T 5 -t 3 --no-check-certificate --output-document=-  https://api.github.com/repos/alist-org/alist/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
        [ -z "$tag" ] && tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/alist-org/alist/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f96 )"
    down=1
   while [ ! -s "$alist" ] && [ ! -s "$upanPath/alist/alist-linux-musl-mipsle.tar.gz" ] ; do
      down=`expr $down + 1`
      logger -t "【AList】" "找不到$alist, 开始下载"
      if [ ! -z "$tag" ] ; then
          logger -t "【AList】" "获取到最新版本$tag, 开始下载"
          [ -s "$(which curl)" ] && curl -L -k -S -o "$upanPath/alist/alist-linux-musl-mipsle.tar.gz" --connect-timeout 10 --retry 3 "https://github.com/alist-org/alist/releases/download/$tag/alist-linux-musl-mipsle.tar.gz"
	  [ ! -s "$(which curl)" ] && wget --no-check-certificate -O "$upanPath/alist/alist-linux-musl-mipsle.tar.gz" "https://github.com/alist-org/alist/releases/download/$tag/alist-linux-musl-mipsle.tar.gz"
	  [ -s "$(which curl)" ] && curl -L -k -S -o "$upanPath/alist/md5.txt" --connect-timeout 10 --retry 3 "https://github.com/alist-org/alist/releases/download/$tag/md5.txt"
	  [ ! -s "$(which curl)" ] && wget --no-check-certificate -O "$upanPath/alist/md5.txt" "https://github.com/alist-org/alist/releases/download/$tag/md5.txt"
          else
	  logger -t "【AList】" "获取到最新版本失败, 开始下载备用版本alist_v3.16.0"
	  [ -s "$(which curl)" ] && curl -L -k -S -o "$upanPath/alist/alist-linux-musl-mipsle.tar.gz" --connect-timeout 10 --retry 3 "https://github.com/alist-org/alist/releases/download/v3.16.0/alist-linux-musl-mipsle.tar.gz"
	  [ ! -s "$(which curl)" ] && wget --no-check-certificate -O "$upanPath/alist/alist-linux-musl-mipsle.tar.gz" "https://github.com/alist-org/alist/releases/download/v3.16.0/alist-linux-musl-mipsle.tar.gz"
	  [ -s "$(which curl)" ] && curl -L -k -S -o "$upanPath/alist/md5.txt" --connect-timeout 10 --retry 3 "https://github.com/alist-org/alist/releases/download/v3.16.0/md5.txt"
	  [ ! -s "$(which curl)" ] && wget --no-check-certificate -O "$upanPath/alist/md5.txt" "https://github.com/alist-org/alist/releases/download/v3.16.0/md5.txt"
      fi
   if [ -s "$upanPath/alist/md5.txt" ] && [ -s "$upanPath/alist/alist-linux-musl-mipsle.tar.gz" ] ; then
      aliMD5="$(cat $upanPath/alist/md5.txt | grep musl-mipsle | awk '{print $1}')"
      eval $(md5sum "$upanPath/alist/alist-linux-musl-mipsle.tar.gz" | awk '{print "aliMD5_down="$1;}') && echo "$aliMD5_down"
      if [ "$aliMD5"x = "$aliMD5_down"x ]; then
      logger -t "【AList】" "安装包下载完成，MD5匹配，开始解压..."
      tar -xzvf $upanPath/alist/alist-linux-musl-mipsle.tar.gz -C $upanPath/alist
      else
      logger -t "【AList】" "安装包下载不完整，MD5不匹配，删除重新下载"
      rm -rf  $upanPath/alist/alist-linux-musl-mipsle.tar.gz $upanPath/alist/md5.txt
      fi
   fi
   if [ ! -s "$alist" ] ; then
      logger -t "【AList】" "安装包解压失败，删除重新下载"
      rm -rf $upanPath/alist/alist-linux-musl-mipsle.tar.gz
     [ "$down" -gt "5" ] && logger -t "【AList】" "程序多次下载失败，将于5分钟后再次尝试下载..." && sleep 300 && down=1
   fi
   done
   [ -s "$alist" ] && chmod 777 $upanPath/alist/alist
   $alist stop
   killall alist
   $alist version >$upanPath/alist/alist.version
   alist_ver=$(cat $upanPath/alist/alist.version | grep -Ew "^Version" | awk '{print $2}')
   echo "$alist_ver"
   echo "$tag"
  [ -z "$alist_ver" ] &&  logger -t "【AList】" "程序不完整，重新下载..." && rm -rf $alist $upanPath/alist/alist-linux-musl-mipsle.tar.gz && sleep 10 && alist_down
   [ ! -z "$alist_ver" ] && logger -t "【AList】" "当前$alist 版本$alist_ver,准备启动"
   if [ ! -z "$tag" ] && [ ! -z "$alist_ver" ] ; then
      if [ "$tag"x != "$alist_ver"x ] ; then
         logger -t "【AList】" "检测到新版本alist-$tag，当前安装版本$alist_ver，开始下载新版本"
#################如果不想自动更新版本，在下方代码前面各加个#号即可#######################
	 rm -rf $upanPath/alist/alist
         rm -rf $upanPath/alist/alist-linux-musl-mipsle.tar.gz
         alist_down
##############################################################################
      fi
   fi
   chmod 777 $alist
 if [ ! -f "$upanPath/alist/data/data.db" ] ; then
    #$alist admin > $upanPath/alist/data/admin.account 2>&1
    $alist --data $upanPath/alist/data admin >$upanPath/alist/data/admin.account 2>&1
    user=$(cat $upanPath/alist/data/admin.account | grep -E "^username" | awk '{print $2}')
    pass=$(cat $upanPath/alist/data/admin.account | grep -E "^password" | awk '{print $2}')
    [ -n "$user" ] && logger -t "【AList】" "检测到首次启动alist，初始用户:$user  初始密码:$pass"
    [ ! -n "$user" ] && logger -t "【AList】" "检测到首次启动alist，生成初始用户密码失败" && logger -t "【AList】" "请在ttyd或ssh里输入此脚本启动一次获取密码"
 fi
datafile="$(cat $upanPath/alist/data/config.json | grep temp_dir | awk -F '"' '{print $4}')"
datalog="$(cat $upanPath/alist/data/config.json | grep enable | awk '{print $2}' | tr -d "," )"
[ "$datalog" = "true" ] && sed -i 's|"enable": true,|"enable": false,|g' "$upanPath/alist/data/config.json"
[ "$datafile" = "/etc/storage/alist/data/temp" ] && sed -i 's|"temp_dir": "/etc/storage/alist/data/temp",|"temp_dir": "/etc/storage/alist/temp",|g' "/etc/storage/alist/data/config.json"
 $alist start
 sleep 10 
 [ ! -z "`pidof alist`" ] && logger -t "【AList】" "alist主页:`nvram get lan_ipaddr`:5244" && logger -t "【AList】" "启动成功" && alist_keep 
 [ -z "`pidof alist`" ] && logger -t "【AList】" "主程序启动失败, 10 秒后自动尝试重新启动" && sleep 10 && alist_restart 

fi
 exit 0
}

alist_close () {
        cronset "alist守护进程"
	$alist stop
	killall alist
	killall -9 alist
	rm -rf /etc/storage/alist/data/log
	rm -rf /etc/storage/alist/temp /etc/storage/alist/data/temp
	rm -rf /tmp/alist/data
	rm -rf /home/root/data
	rm -rf /home/admin/data
	[ -L "$upanPath/alist/data" ] && rm -rf $upanPath/alist/data
	[ -L "$upanPath/alist/data/data" ] && rm -rf $upanPath/alist/data/data
	[ -L /etc/storage/alist/data/data ] && rm -rf /etc/storage/alist/data/data
	[ ! -z "\`pidof alist\`" ] && logger -t "【AList】" "进程已关闭"
}

alist_down () {
  sleep 4
  alist_start
}

cronset(){
	tmpcron=/tmp/cron_$USER
	croncmd -l > $tmpcron 
	sed -i "/$1/d" $tmpcron
	sed -i '/^$/d' $tmpcron
	echo "$2" >> $tmpcron
	croncmd $tmpcron
	rm -f $tmpcron
}
croncmd(){
	if [ -n "$(crontab -h 2>&1 | grep '\-l')" ];then
		crontab $1
	else
		crondir="$(crond -h 2>&1 | grep -oE 'Default:.*' | awk -F ":" '{print $2}')"
		[ ! -w "$crondir" ] && crondir="/etc/storage/cron/crontabs"
		[ "$1" = "-l" ] && cat $crondir/$USER 2>/dev/null
		[ -f "$1" ] && cat $1 > $crondir/$USER
	fi
}

case $1 in
start)
	alist_start
	;;
check)
	alist_restart
	;;
stop)
	alist_close
	;;
restart)
	alist_restart
	;;
cronset)
	cronset $2 $3
	;;
*)
	alist_restart
	;;
esac

