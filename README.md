本脚本用于每天查询Quili余额并发送到钉钉

wget -O sendquili.sh https://raw.githubusercontent.com/optimus-a1/sendquili/main/sendquili.sh 


编辑脚本文件并修改为你自己的钉钉信息

vim sendquili.sh


给脚本执行权限

chmod +x sendquili.sh


在后台运行脚本

nohup ./sendquili.sh > /dev/null 2>&1 &








