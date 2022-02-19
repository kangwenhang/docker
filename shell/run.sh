#!/usr/bin/env bash

## 导入通用变量与函数
config_use=config"$1"
diyreplace_use=diyreplace"$1"

##运行脚本
function run_sh {
  source /push/shell/share.sh
  mkdir -p $diy_logs
  source $shell_model/push.sh 2>&1 | tee $log_path
  exit
}

function run_sh_sd {
  source /push/shell/share_sd.sh
  mkdir -p $diy_logs
  source $shell_model/push.sh 2>&1 | tee $log_path
  exit
}

function Help {
  echo -e "本脚本的用法为："
  echo -e "1. bash /push/shell/run.sh           # 查看帮助"
  echo -e "2. bash /push/shell/run.sh 数字      # 运行confing+数字脚本（手动【不建议】运行此项）"
  echo -e "3. bash /push/shell/run.sh 数字 sd   # 运行confing+数字脚本（手动【建议】运行此项）"
}

case $# in
  0)
    echo -e "==============================帮助==================================="
    Help
    ;;
  1)
    if [[ "$1" =~ ^(-?|\+?)[0-9]+(\.?[0-9]+)?$ ]]; then
      run_sh $1
    else
      echo -e "\n命令输入错误...\n"
      Help
    fi
    ;;
  2)
    if [[ $2 == sd ]]; then
      run_sh_sd $1
    elif [[ "$2" == "" ]]; then
      run_sh $1
    else
      echo -e "\n命令输入错误...\n"
      Help
    fi
    ;;
  *)
    echo -e "\n命令过多...\n"
    Help
    ;;
esac
