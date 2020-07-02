#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#定义终端输出颜色
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
#定义文件路径
smokeping_ver="/opt/smokeping/wabks/ver"
#Check Root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }
#获取进程PID
Get_PID(){
        PID=(`ps -ef |grep "smokeping"|grep -v "grep"|grep -v "smokeping.sh"|awk '{print $2}'|xargs`)
}
#禁用selinux、防火墙
Disable_Firewall_And_Selinux(){
        systemctl stop firewalld
        systemctl disable firewalld
        setenforce 0
        sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
        sed -i "s/SELINUX=permissive/SELINUX=disabled/g" /etc/selinux/config
}
#同步时间
Time_Synchronization(){
        yum install ntpdate -y
        \cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
        /usr/sbin/ntpdate pool.ntp.org
cat >>  /var/spool/cron/root  << EOF
#time sync by bks
*/10 * * * * /usr/sbin/ntpdate pool.ntp.org && /sbin/hwclock -w >/dev/null 2>&1
EOF
}
#安装依赖,fping需在epel*源里面，所以需先安装epel
Install_Dependency(){
        yum -y install epel* wget make gcc openssl openssl-devel rrdtool rrdtool-perl perl-core perl mod_fcgid perl-CPAN httpd httpd-devel sendmail
        yum -y install fping
}
#下载smokeping
Download_Source(){
        cd
        wget https://github.com/wabksw/smokeping/raw/master/smokeping-2.7.2.tar.gz
        tar -xzvf smokeping-2.7.2.tar.gz -C /opt/
        cd /opt/smokeping-2.7.2
}
#安装smokeping
Install_SomkePing(){
        ./configure --prefix=/opt/smokeping
        /usr/bin/gmake install
        #第一次make,是不会成功的，需要再次执行一次
        /usr/bin/gmake install
}
#清除文件
Delete_Files(){
        rm -rf /opt/smokeping-2.7.*
}
#配置smokeping
Configure_SomkePing(){
        cd /opt/smokeping/
        mkdir /opt/smokeping/htdocs/{data,cache,var}
        mkdir /opt/smokeping/etc/Monitoring_Nodes
        touch /var/log/smokeping.log
        cd /opt/smokeping/htdocs/
        mv smokeping.fcgi.dist smokeping.fcgi
        wget -O /opt/smokeping/etc/config https://github.com/wabksw/smokeping/raw/master/smokeping_config 
        wget -O /opt/smokeping/etc/Monitoring_Nodes/targets https://github.com/wabksw/smokeping/raw/master/Monitoring_Nodes/targets 
        wget -O /opt/smokeping/etc/Monitoring_Nodes/gaofang https://github.com/wabksw/smokeping/raw/master/Monitoring_Nodes/gaofang 
}
#配置config Master
Master_Configure_SomkePing(){
        cd /opt/smokeping/etc
        sed -i "s/some.url/$server_name/g" config
}
#配置httpd相关文件权限,设置登录密码。默认为：admin/admin@123
Configure_httpd(){
        chown apache. /opt/smokeping/htdocs/{data,cache,var} -R
        chown apache. /var/log/smokeping.log
        chmod 600 /opt/smokeping/etc/smokeping_secrets.dist
        htpasswd -bc /opt/smokeping/htdocs/htpasswd admin  admin@123
}
#修改httpd配置文件 Master
Master_Configure_httpd(){
        wget -O /etc/httpd/conf.d/smokeping.conf https://github.com/wabksw/smokeping/raw/master/httpd_smokeping.conf 
        sed -i "s/localhost/$server_name/g" /etc/httpd/conf.d/smokeping.conf 
}
#配置smokeping支持中文
Chinese_Support_config(){
        yum -y install wqy-zenhei-fonts
        rm -f /opt/smokeping/lib/Smokeping/Graphs.pm
        wget -O /opt/smokeping/lib/Smokeping/Graphs.pm https://github.com/wabksw/smokeping/raw/master/Graphs.pm 
}
Install_Tcpping(){
        yum install tcptraceroute -y
        rm -rf /opt/smokeping/bin/tcpping-smokeping
        wget -O  /opt/smokeping/bin/tcpping-smokeping https://github.com/wabksw/smokeping/raw/master/tcpping.sh
        chmod 755 /opt/smokeping/bin/tcpping-smokeping
        echo -e "${Info} 安装 tcpping 完成"
}
#配置Supervisor启动
Supervisor_Config_Smokeping(){
        yum install -y supervisor
        sed -i 's/;chmod=0700/chmod=0766/g' /etc/supervisord.conf   
        sed -i '$a [include] \
files = /etc/supervisord.d/*.conf' /etc/supervisord.conf
        wget -O /etc/supervisord.d/smokeping.conf https://github.com/wabksw/smokeping/raw/master/supervisord_smokeping.conf 
}
#启动Master服务
Master_Run_SmokePing(){
        systemctl restart supervisord
        supervisorctl restart smokeping
        systemctl restart httpd
}
#开机自启服务
Auto_Starts(){
        systemctl enable supervisord
        systemctl enable httpd
}
Master_Install(){
        echo
        read -p "请输入Master地址 : " server_name
        kill -9 `ps -ef |grep "smokeping"|grep -v "grep"|grep -v "smokeping.sh"|grep -v "perl"|awk '{print $2}'|xargs` 2>/dev/null
        rm -rf /opt/smokeping
        Disable_Firewall_And_Selinux
        Time_Synchronization
        Install_Dependency
        Download_Source
        Install_SomkePing
        Delete_Files
        Configure_SomkePing
        Master_Configure_SomkePing
        Configure_httpd
        Master_Configure_httpd
        Chinese_Support_config
        Install_Tcpping
        Supervisor_Config_Smokeping
        Master_Run_SmokePing
        Auto_Starts
        mkdir /opt/smokeping/wabks
        echo "Master" > ${smokeping_ver}
        echo -e "${Info} 安装 SmokePing Master端完成"
}
#卸载SmokePing
Uninstall(){
        while :; do echo
                echo -e "${Tip} 已经安装${Green_font_prefix} $mode2 ${Font_color_suffix}，是否卸载 [y/n]: "
                read um
                if [[ ! $um =~ ^[y,n]$ ]]; then
                        echo "输入错误! 请输入y或者n!"
                else
                        break
                fi
        done
        if [[ $um == "y" ]]; then
                kill -9 `ps -ef |grep "smokeping"|grep -v "grep"|grep -v "smokeping.sh"|grep -v "perl"|awk '{print $2}'|xargs` 2>/dev/null
                rm -rf /opt/smokeping
                rm -rf /etc/supervisord.d/smokeping.conf
                supervisorctl reload
                echo
                echo -e "${Info} SmokePing 卸载完成!"
                echo
        else
                echo
                echo -e "${Info} 卸载已取消!"
                echo
                exit
        fi
}
clear
echo && echo -e "  SmokePing 一键管理脚本 
  
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 SmokePing Master端
  ————————————
 ${Green_font_prefix} 2.${Font_color_suffix} 卸载 SmokePing
  ————————————
 ${Green_font_prefix} 3.${Font_color_suffix} 重启 SmokePing
  ————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 退出
  ————————————" && echo
if [[ -e ${smokeping_ver} ]]; then
        Get_PID
        if [[ `grep "Master" ${smokeping_ver}` ]]; then
                mode="Master"
                mode2="Master端"
        fi
        if [[ ! -z "${PID}" ]]; then
                echo -e "当前状态: ${Green_font_prefix}已安装 $mode2 ${Font_color_suffix}并 ${Green_font_prefix}已启动${Font_color_suffix}"
        else
                echo -e "当前状态: ${Green_font_prefix}已安装 $mode2 ${Font_color_suffix}但 ${Red_font_prefix}未启动${Font_color_sufffix}"
        fi
else
        echo -e "当前状态: ${Red_font_prefix}未安装${Font_color_suffix}"
fi
echo
read -p "请输入数字 [1-4]:" num
case "$num" in
1)
        if [[ -e ${smokeping_ver} ]]; then
                while :; do echo
                        echo -e "${Tip} 已经安装${Green_font_prefix} $mode2 ${Font_color_suffix}，是否重新安装 [y/n]: "
                        read um
                        if [[ ! $um =~ ^[y,n]$ ]]; then
                                echo "输入错误! 请输入y或者n!"
                        else
                                break
                        fi
                done
                if [[ $um == "y" ]]; then
                        kill -9 `ps -ef |grep "smokeping"|grep -v "grep"|grep -v "smokeping.sh"|grep -v "perl"|awk '{print $2}'|xargs` 2>/dev/null
                        rm -rf /opt/smokeping
                        supervisorctl stop smokeping
                        echo
                        echo -e "${Info} Smokeping ${mode2} 卸载完成! 开始安装 Master端!"
                        echo
                        sleep 5
                        Master_Install
                        exit
                else
                        exit
                fi
        fi
        Master_Install
;;
2)
        [[ ! -e ${smokeping_ver} ]] && echo -e "${Error} Smokeping 没有安装，请检查!" && exit 1
        Uninstall
;;
3)
        [[ ! -e ${smokeping_ver} ]] && echo -e "${Error} Smokeping 没有安装，请检查!" && exit 1
        ${mode}_Run_SmokePing
;;
4)
        exit
;;
*)
        echo "输入错误! 请输入正确的数字! [1-9]"
;;
esac
