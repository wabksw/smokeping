# smokeping

SmokePing-2.7.2一键安装脚本

### 功能介绍
- 一键安装SmokePing服务，默认已安装tcpping
- 此脚本未配置告警，需自行配置
- 默认支持中文显示
- 默认登录账号密码为：admin/admin@123

![图片1](https://github.com/wabksw/smokeping/raw/master/1.png)
![图片2](https://github.com/wabksw/smokeping/raw/master/2.png)


### 配置文件地址
- http配置文件：/etc/httpd/conf.d/smokeping.conf
- smokeping配置文件：/opt/smokeping/etc/config
- smokeping节点存放目录：/opt/smokeping/etc/Monitoring_Nodes/
- super_smokeping配置文件：/etc/supervisord.d/smokeping.conf 

### 注意
- 请确保服务器环境干净，最好重装后使用该脚本；或者直接使用容器安装

### 参考资料
[centos7安装smokeping2.7.2](https://www.wsfnk.com/archives/610.html)
[参考脚本来源](https://github.com/wabksw/smokeping-onekey)
