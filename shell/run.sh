#!/usr/bin/env bash

## 导入通用变量与函数
config_use=config"$1"
diyreplace_use=diyreplace"$1"
source /push/shell/share.sh
source $file_config

##运行脚本
function run_sh {
  mkdir -p $diy_logs
  source $shell_model/push.sh 2>&1 | tee $log_path
  exit
}

function run_sh_sd {
  cp -rf $config/crontab.list $config/crontab.list.back
  awk '{print "#"$0}' $config/crontab.list
  mkdir -p $diy_logs
  source $shell_model/push.sh 2>&1 | tee $log_path
  cp -rf $config/crontab.list.back $config/crontab.list
  exit
}

case $# in
  0)
    echo
  1)
    if [[ $1 == sd ]]; then
      config_use=config
      run_sh_sd
    else
      config_use=config
      run_sh
    fi
    ;;
  2)
    if [[ $2 == sd ]]; then
      run_sh_sd $1
    else
      run_sh $1
    fi
    ;;
  *)
    echo -e "\n命令过多...\n"
    ;;
esac