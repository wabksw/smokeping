#!/bin/bash
#########################################################
# Script to email a ping report on alert from Smokeping #
#########################################################
# 解析变量
Alertname=$1
Target=$2
Losspattern=$3
Rtt=$4
Hostname=$5
Date=$( date '+%Y-%m-%d %H:%M:%S' )

#这是smokeping报警会创出的$1-$5值的类型
#A1=hightloss
#B2="HK.HK-9S.9s-3 [from template]"
#C3="loss: 0%, 0%, 0%, 0%, 15%, 45%, 40%"
#D4="rtt: 29ms, 29ms, 29ms, 29ms, 33ms, 33ms, 33ms"
#E5="1.1.1.1"


#　注意：为钉钉机器人告警，重新处理变量，因为钉钉机器人告警里（变量的内容不能包含空格）
A=`echo $1 | sed 's/ //g'`
#    case "$Alertname" in
#    hightloss)
#        A=hightloss-高丢包;;
#    hostdown)
#        A=hostdown-DOWN;;
#    rtt-1)
#        A=rtt-1-高延时;;
#    esac


#处理变量B
B=`echo $2 | sed 's/ //g'`
#B=`echo $B | sed 's/\[fromSH_youfu_CT_Proxy\]//g'`
#B=`echo $B | sed 's/\[fromtemplate\]//g'`

#  这里为了报警的内容的美观，顺带将rtt:和loss:抹去了
C=`echo $3 | sed 's/ //g'`
C=`echo $C | sed 's/loss://g'`
D=`echo $4 | sed 's/ //g'`
D=`echo $D | sed 's/rtt://g'`

E=`echo $5 | sed 's/ //g'`
F=`echo $Date |sed 's/ /_/g'`
G=未知类别



#定义＂目标分类的函数＂
Mubiao() {
        H=/opt/smokeping/etc/targets
                P=`cat -n "$H"-"$X" |grep "host = $E$" |  cut -f 1 `
                PP=`expr $P - 2`
                G=`sed -n "s/menu = //g;$PP p" $H-$X `

}

#设置报警值的A端Z端，这里默认设置为    "AEND=深圳阿里云，ZEND=DNS"
#根据报警的target判断那个机房出现报警
        if [ `echo "$Target" |grep SGP | wc -l`  -ne 0 ];then
                ZEND='新加坡'
        X=SGP
        Mubiao
          elif [ `echo "$Target" |grep PHI | wc -l`  -ne 0 ];then
                ZEND='菲律宾'
        X=PHI
        Mubiao
          elif [ `echo "$Target" |grep HK | wc -l`  -ne 0 ];then
                ZEND='香港'
        X=HK
        Mubiao
          elif [ `echo "$Target" |grep LA | wc -l`  -ne 0 ];then
                ZEND='洛杉矶'
        X=LA
        Mubiao
          elif [ `echo "$Target" |grep JP | wc -l`  -ne 0 ];then
                ZEND='日本'
        X=JP
        Mubiao
          elif [ `echo "$Target" |grep KOR | wc -l`  -ne 0 ];then
                ZEND='韩国'
        X=KOR
        Mubiao
          elif [ `echo "$Target" |grep CD-PBS | wc -l`  -ne 0 ];then
                ZEND='成都鹏博士'
        X=TG
        Mubiao
          elif [ `echo "$Target" |grep BJ-SJQ | wc -l`  -ne 0 ];then
                ZEND='北京四季青'
        X=TG
        Mubiao
          elif [ `echo "$Target" |grep SH-YF | wc -l`  -ne 0 ];then
                ZEND='有孚双线'
        X=TG
        Mubiao
          elif [ `echo "$Target" |grep SZ-YX | wc -l`  -ne 0 ];then
                ZEND='深圳易信'
        X=TG
        Mubiao
          elif [ `echo "$Target" |grep SZ-PBS | wc -l`  -ne 0 ];then
                ZEND='深圳鹏博士'
        X=TG
        Mubiao
          elif [ `echo "$Target" |grep TG-YN | wc -l`  -ne 0 ];then
                ZEND='越南'
        X=TG
        Mubiao
          else
         [ `echo "$Target" |grep DNS | wc -l`  -ne 0 ]
                ZEND='DNS'
        X=DNS
        Mubiao
        fi

#根据报警的target判断是否报警源位置（smokeping_salve的主机名）
        if [ `echo "$Target" |grep SH_youfu | wc -l`  -ne 0 ];then
                AEND='有孚双线'
          elif [ `echo "$Target" |grep template | wc -l`  -ne 0 ];then
                AEND='陕西联通'
      else
           AEND='深圳阿里云'
#         mtr -r -n $Hostname &gt;&gt; /tmp/mtr.txt
#         echo '++++++++++++' &gt;&gt; /tmp/mtr.txt
        fi


####################钉钉机器人告警执行部分#######################
#　注意：为钉钉机器人告警，重新处理变量，因为钉钉机器人告警里（变量的内容不能包含空格）
curl 'https://oapi.dingtalk.com/robot/send?access_token=xxxxxxxx' \
   -H 'Content-Type: application/json' \
   -d '
{
    "msgtype": "text",
    "text": {
"content":"('$AEND'－'$ZEND')网络告警
告警策略：'$A'
目标类别：'$G'
目标名称：'$B'
丢包率：'$C'
延　迟：'$D'
目标地址：'$E'
故障时间：'$F'"
    },
     "at": {
         "atMobiles": [
             "182****8240"
         ], 
         "isAtAll": false
     }
}'
#&gt;&gt; /tmp/dingding-alert.log  2&gt;&amp;1


#####################邮件告警调用执行部分，这里暂不使用，只记录到日志文件#######################

#zhuti="打码 ($AEND－$ZEND) 网络质量告警"
#messages=`echo -e " 报警策略名: \t $Alertname \n 报警目标: \t $Target \n 丢包率: \t $Losspattern  \n 延迟时间: \t $Rtt \n 主机地址: \t$Hostname \n 报警时间: \t$Date "`
#email="zhsd@www.com"
echo "$Date -- $Alertname -- $Target -- $Losspattern -- $Rtt -- $Hostname"  >> /tmp/smokeping-baojin
#echo "$messages" | mail -s "$zhuti" $email &gt;&gt;/tmp/mailx.log 2&gt;&amp;1
