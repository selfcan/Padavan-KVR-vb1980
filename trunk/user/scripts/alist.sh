#!/bin/sh
upanPath="`df -m | grep /dev/mmcb | grep -E "$(echo $(/usr/bin/find /dev/ -name 'mmcb*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && upanPath="`df -m | grep /dev/sd | grep -E "$(echo $(/usr/bin/find /dev/ -name 'sd*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
alist="$upanPath/alist/alist"
[ -z "$upanPath" ] && alist="/tmp/alist/alist"

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
   logger -t "【AList】" "无法下载alist,当前/tmp分区只剩$Available_A M，请插U盘使用，即将退出..."
   exit 1
   fi
   tag=$(curl -k --silent "https://api.github.com/repos/lmq8267/alist/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
   [ -z "$tag" ] && tag="$( curl -k -L --connect-timeout 20 --silent https://api.github.com/repos/lmq8267/alist/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
   [ -z "$tag" ] && tag="$( curl -k --connect-timeout 20 --silent https://api.github.com/repos/lmq8267/alist/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
   [ -z "$tag" ] && tag="$( curl -k --connect-timeout 20 -s https://api.github.com/repos/lmq8267/alist/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
   logger -t "【AList】" "未挂载储存设备, 将下载Mini版8M安装在/tmp/alist/alist,当前/tmp分区剩余$Available_A M"
   alistdb="/etc/storage/alist/data/data.db"
   [ ! -d /etc/storage/alist/data ] && mkdir -p /etc/storage/alist/data
   [ ! -d /tmp/alist ] && mkdir -p /tmp/alist
   rm -rf /tmp/alist/data
   rm -rf /home/root/data
   rm -rf /home/admin/data
   ln -sf /etc/storage/alist/data /home/root/data
   ln -sf /etc/storage/alist/data /tmp/alist/data
   ln -sf /etc/storage/alist/data /home/admin/data
   if [ ! -s "$alist" ] ; then
     if [ ! -z "$tag" ] ; then
      logger -t "【AList】" "找不到$alist, 开始下载"
      curl -L -k -S -o  /tmp/alist/MD5.txt  --connect-timeout 10 --retry 3 https://fastly.jsdelivr.net/gh/lmq8267/alist@master/install/$tag/MD5.txt
      curl -L -k -S -o  $alist  --connect-timeout 10 --retry 3 https://fastly.jsdelivr.net/gh/lmq8267/alist@master/install/$tag/alist
      else
      curl -L -k -S -o  /tmp/alist/MD5.txt  --connect-timeout 10 --retry 3 https://fastly.jsdelivr.net/gh/lmq8267/alist@master/install/3.15.0/MD5.txt
      curl -L -k -S -o  $alist  --connect-timeout 10 --retry 3 https://fastly.jsdelivr.net/gh/lmq8267/alist@master/install/3.15.0/alist
      fi
      if [ -f $alist ] && [ -f /tmp/alist/MD5.txt ]; then
         alistmd5="$(cat /tmp/alist/MD5.txt)"
         eval $(md5sum "$alist" | awk '{print "MD5_down="$1;}') && echo "$MD5_down"
         if [ "$alistmd5"x = "$MD5_down"x ] ; then
            logger -t "【AList】" "程序下载完成，MD5匹配，开始启动..."
            chmod 777 $alist
          else
            logger -t "【AList】" "程序下载完成，MD5不匹配，删除..."
            rm -rf $alist
            rm -rf /tmp/alist/MD5.txt
            alist_down
         fi
      fi
   fi
   [ ! -s "$alist" ] && logger -t "【AList】" "程序下载失败，重新下载..." && sleep 10 && alist_down
   chmod 777 $alist
   killall alist
   killall -9 alist
   if [ ! -f "/etc/storage/alist/data/data.db" ] ; then
    #$alist admin > /etc/storage/alist/data/admin.account 2>&1
    $alist --data /etc/storage/alist/data admin >/etc/storage/alist/data/admin.account 2>&1
    user=$(cat /etc/storage/alist/data/admin.account | grep -E "^username" | awk '{print $2}')
    pass=$(cat /etc/storage/alist/data/admin.account | grep -E "^password" | awk '{print $2}')
    [ -n "$user" ] && logger -t "【AList】" "检测到首次启动alist，初始用户:$user  初始密码:$pass"
    [ ! -n "$user" ] && logger -t "【AList】" "检测到首次启动alist，权限不足，生成初始用户密码失败" && logger -t "【AList】" "请在ttyd或ssh里输入此脚本启动一次获取密码"
    fi
    $alist --data /etc/storage/alist/data server >/tmp/alist/alistserver.txt 2>&1 &
    sleep 10
 [ ! -z "`pidof alist`" ] && logger -t "【AList】" "alist主页:`nvram get lan_ipaddr`:5244" && logger -t "【AList】" "启动成功" && alist_keep
 [ -z "`pidof alist`" ] && logger -t "【AList】" "主程序启动失败, 10 秒后自动尝试重新启动" && sleep 10 && alist_restart
else
   alistdb="/etc/storage/alist/data/data.db"
   [ ! -d /etc/storage/alist/data ] && mkdir -p /etc/storage/alist/data
   rm -rf /home/root/data
   rm -rf /home/admin/data
   rm -rf $upanPath/alist/data
   ln -sf /etc/storage/alist/data /home/root/data
   ln -sf /etc/storage/alist/data /home/admin/data
   [ ! -d $upanPath/alist ] && mkdir -p $upanPath/alist
   ln -sf /etc/storage/alist/data $upanPath/alist/data
   tag=$(curl -k --silent "https://api.github.com/repos/alist-org/alist/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
	[ -z "$tag" ] && tag="$( curl -k -L --connect-timeout 20 --silent https://api.github.com/repos/alist-org/alist/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
	[ -z "$tag" ] && tag="$( curl -k --connect-timeout 20 --silent https://api.github.com/repos/alist-org/alist/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
	[ -z "$tag" ] && tag="$( curl -k --connect-timeout 20 -s https://api.github.com/repos/alist-org/alist/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
   if [ ! -s "$alist" ] && [ ! -f "$upanPath/alist/alist-linux-musl-mipsle.tar.gz" ] ; then
      logger -t "【AList】" "找不到$alist, 开始下载"
      if [ ! -z "$tag" ] ; then
          logger -t "【AList】" "获取到最新版本$tag, 开始下载"
          curl -L -k -S -o "$upanPath/alist/alist-linux-musl-mipsle.tar.gz" --connect-timeout 10 --retry 3 "https://github.com/alist-org/alist/releases/download/$tag/alist-linux-musl-mipsle.tar.gz"
          else
	  logger -t "【AList】" "获取到最新版本失败, 开始下载备用版本alist_v3.14.0"
	  curl -L -k -S -o "$upanPath/alist/alist-linux-musl-mipsle.tar.gz" --connect-timeout 10 --retry 3 "https://github.com/alist-org/alist/releases/download/v3.14.0/alist-linux-musl-mipsle.tar.gz"
      fi
   fi
   if [ ! -s "$alist" ] && [ -f "$upanPath/alist/alist-linux-musl-mipsle.tar.gz" ] ; then
      logger -t "【AList】" "安装包下载完成，开始解压..."
      tar -xzvf $upanPath/alist/alist-linux-musl-mipsle.tar.gz -C $upanPath/alist
   fi
   if [ ! -s "$alist" ] ; then
      logger -t "【AList】" "安装包解压失败，安装包下载不完整，重新下载"
      rm -rf $upanPath/alist/alist-linux-musl-mipsle.tar.gz
      alist_down
    else
      chmod 777 $upanPath/alist/alist
   fi
   killall alist
   killall -9 alist
   $alist version >$upanPath/alist/alist.version
   alist_ver=$(cat $upanPath/alist.version | grep -Ew "^Version" | awk '{print $2}')
   echo "$alist_ver"
   echo "$tag"
   if [ ! -z "$tag" ] & [ ! -z "$alist_ver" ] ; then
      if [ "$tag"x != "$alist_ver"x ] ; then
         logger -t "【AList】" "检测到新版本alist-$tag，当前安装版本v$alist_ver，如需使用新版，控制台执行rm -rf $upanPath/alist 后手动重启此脚本"      
      fi
   fi
   chmod 777 $alist
 if [ ! -f "/etc/storage/alist/data/data.db" ] ; then
    #$alist admin > $upanPath/alist/data/admin.account 2>&1
    $alist --data /etc/storage/alist/data admin >/etc/storage/alist/data/admin.account 2>&1
    user=$(cat /etc/storage/alist/data/admin.account | grep -E "^username" | awk '{print $2}')
    pass=$(cat /etc/storage/alist/data/admin.account | grep -E "^password" | awk '{print $2}')
    [ -n "$user" ] && logger -t "【AList】" "检测到首次启动alist，初始用户:$user  初始密码:$pass"
    [ ! -n "$user" ] && logger -t "【AList】" "检测到首次启动alist，权限不足，生成初始用户密码失败" && logger -t "【AList】" "请在ttyd或ssh里输入此脚本启动一次获取密码"
 fi
 $alist start
 sleep 10 
 [ ! -z "`pidof alist`" ] && logger -t "【AList】" "alist主页:`nvram get lan_ipaddr`:5244" && logger -t "【AList】" "启动成功" && alist_keep
 [ -z "`pidof alist`" ] && logger -t "【AList】" "主程序启动失败, 10 秒后自动尝试重新启动" && sleep 10 && alist_restart 

fi
 exit 0
}

alist_close () {
	$alist stop
	killall alist
	killall -9 alist
	cronset "alist守护进程"
	rm -rf /etc/storage/alist/data/log
	rm -rf /tmp/alist/data
	rm -rf /home/root/data
	rm -rf /home/admin/data
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
