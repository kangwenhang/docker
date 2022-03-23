#!/usr/bin/env bash

## 导入通用变量与函数
source /push/shell/share.sh

function Git_Off_True {
  echo -e "更新完成，更新文件并提升权限"
  cp -rf $repo_docker/* $dir_root
  cp -rf ${dir_root}/sample/config_model/ ${dir_root}/config/
  chmod -R 777 $dir_root
}

function Git_Off_Over {
  echo -e "更新失败，清理缓存并提升权限"
  rm -rf $repo_docker
  chmod -R 777 $dir_root
}

function Git_CloneShell {
  rm -rf $repo_docker
  cd $dir_repo
  git clone -b master https://ghproxy.com/https://github.com/kangwenhang/docker.git $repo_docker
  if [ $? = 0 ]; then
    Git_Off_True
  else
    x=1
    while [[ x -le 3 ]]; do
      echo "克隆失败,重试执行第$x次"
      git clone -b master https://ghproxy.com/https://github.com/kangwenhang/docker.git $repo_docker
      if [ $? = 0 ]; then
        Git_Off_True
        return
      else
        let x++
        sleep 20s
      fi
    done
    Git_Off_Over
  fi
}

function Git_PullShell {
  git config --global http.version HTTP/1.1
  echo -e "更新shell脚本\n"
  cd $repo_docker
  git fetch --all
  ExitStatusShell=$?
  git reset --hard origin/master
  if [ $ExitStatusShell = 0 ]; then
    echo -e "pull成功，开始更新文件"
    Git_Off_True
  else
    echo -e "pull失败了，采用clone更新"
    Git_CloneShell
  fi
}

function Update_Config {
  if [ -d "$repo_docker" ]; then
    echo -e "检测到文件夹，采用pull更新"
    Git_PullShell
  else
    echo -e "未检测到文件夹，采用clone更新"
    Git_CloneShell
  fi
}

#临时更新
function temporary {
  source $shell_model/uptemp.sh > $logs/update_temporary.log
}

echo "开始运行"
Update_Config
temporary
echo "运行结束，退出"
exit
