#!/usr/bin/env bash

## 导入通用变量与函数
function input_can {
  config_use=config"$1"
  diyreplace_use=diyreplace"$1"
  source /push/shell/share.sh
  source $file_config
}

##运行脚本
function run_sh {
  input_can $1
  mkdir -p $diy_logs
  source $shell_model/push.sh 2>&1 | tee $log_path
  exit
}

function run_sh_sd {
  input_can $1
  cp -rf $config/crontab.list $config/crontab.list.back
  awk '{print "#"$0}' $config/crontab.list > /dev/null 2>&1
  mkdir -p $diy_logs
  source $shell_model/push.sh 2>&1 | tee $log_path
  cp -rf $config/crontab.list.back $config/crontab.list
  exit
}

function help {
  echo -e "本脚本的用法为："
  echo -e "1. bash run.sh           # 查看帮助"
  echo -e "2. bash run.sh 数字      # 运行confing+数字脚本（手动【不建议】运行此项）"
  echo -e "3. bash run.sh 数字 sd   # 运行confing+数字脚本（手动【建议】运行此项）"
}


if [[ $1 == "" ]]; then
    echo -e "==============================帮助==================================="
    help
elif [[ $2 == sd ]]; then
    run_sh_sd $1
else
    run_sh $1
fi
