#!/usr/bin/env bash

## 导入通用变量与函数
config_use=config"$1"
diyreplace_use=diyreplace"$1"
source /push/shell/share.sh

##运行脚本
mkdir -p $diy_logs
source $shell_model/push.sh 2>&1 | tee $log_path
exit
