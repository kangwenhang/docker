#!/usr/bin/env bash

source $file_config

#前置
function Initialization {
  if [ ! -d "$tongbu_push" ]; then
    echo "$tongbu_push不存在，跳过清理"
  else
    echo "开始清理上传仓库$tongbu_push"
    cd $tongbu_push
    for n in `ls -a`; do
      rm -rf $n >/dev/null 2>&1
    done
  fi
  if [ ! -d "$submit" ]; then
    echo "$submit文件夹不存在，跳过清理"
  else
    echo "开始清理上传日志$submit"
    cd $submit
    for y in `ls -a`; do
      rm -rf $y >/dev/null 2>&1
    done
  fi
  if [[ "$number" -eq "" ]]; then
    number="0"
  fi
  sleep 3s
}

function mkdir_file_folder {
  echo "开始执创建必须的文件夹"
  mkdir -p $tongbu_temp
  mkdir -p $raw_flie
  mkdir -p $diy_config
  mkdir -p $submit
  mkdir -p $dir_repo
  echo "执创建必须的文件夹结束"
}

#清除git信息
function Delete_git {
  echo "正在清除git信息"
  sleep 3s
  find . -name ".git" | xargs rm -Rf
}

#加载代理
function socks_git_set {
  echo "==============开始加载代理================"
  if [ "$sock5_diy" = "" ]; then
    echo "不设置代理，以默认方式执行脚本"
  else
    if [ ! "$sock5_diy" = "" ] && [ "$http_proxy" = "" -o "$http_proxy" = "global" ]; then
      echo "设置为git全局代理"
      git config --global http.proxy "socks5://$sock5_diy"
      git config --global https.proxy "socks5://$sock5_diy"
    elif [ ! "$sock5_diy" = "" ] && [ "$http_proxy" = "push" ]; then
      echo "设置为仅push及使pull用代理"
      push_diy=1
    elif [ ! "$sock5_diy" = "" ] && [ ! "$http_proxy" = "" ]; then
      echo "设置为指定地址模式" 
      git config --global http.$http_proxy.proxy socks5://$sock5_diy
    fi
  fi
  echo "==============加载代理结束================"
}

#取消代理
function socks_git_unset {
  echo "==============开始取消代理================"
  if [ ! "$sock5_diy" = "" ] && [ "$http_proxy" = "" -o "$http_proxy" = "global" -o "$http_proxy" = "push" ]; then
    git config --global --unset http.proxy
    git config --global --unset https.proxy
  elif [ ! "$sock5_diy" = "" ] && [ ! "$http_proxy" = "" ]; then
    git config --global --unset http.$http_proxy.proxy
  fi
  echo "==============取消代理结束================"
}

#网络协议
function Script_Pre {
  if [ "$http_version" = "" ]; then
    echo "http协议未设置，将采用默认协议"
    http_version="HTTP/2"
  else
    echo "http协议已设置，将采用$http_version协议"
    git config --global http.version $http_version
  fi
  if [ "$lowSpeedLimit" = "" ]; then
    echo "未定义lowSpeedLimit参数，采用默认"
  else
    echo "定义lowSpeedLimit参数为$lowSpeedLimit"
    git config --global http.lowSpeedLimit $lowSpeedLimit
  fi
  if [ "$lowSpeedTime" = "" ]; then
    echo "未定义lowSpeedTime参数，采用默认"
  else
    echo "定义lowSpeedTime参数为$lowSpeedTime"
    git config --global http.lowSpeedTime $lowSpeedTime
  fi
  if [ "$autocrlf" = "" ]; then
    echo "未定义autocrlf参数，采用input"
    git config --global core.autocrlf input
  else
    echo "定义autocrlf参数为$autocrlf"
    git config --global core.autocrlft $autocrlf
  fi
}

#清除库内容
function Del_Party {
  for m in `ls`; do
    if [ "$m" != .git ]; then
      rm -rf $m
    fi
  done
}

#确认项目
function Yes_Open {
  echo "拷贝确认文件"
  cp -fv $dir_root/sample/model.sample $tongbu_push/model
}

#主仓库(网络仓库)
function Pull_diy_Third_party_warehouse {
  Initialization
  mkdir_file_folder
  Script_Pre
  echo "正在克隆主仓库"
  git clone -b $diy_branch ${github_proxy_url}https://$diy_url $tongbu_push
  if [ $? = 0 ]; then
    echo "克隆主仓库成功"
    cd $tongbu_push
    Del_Party
    Yes_Open
  else
    l=1
    while [[ l -le 3 ]]; do
      echo "克隆失败,重试执行第$l次"
      git clone -b $diy_branch ${github_proxy_url}https://$diy_url $tongbu_push
      if [ $? = 0 ]; then
        echo "克隆主仓库成功"
        cd $tongbu_push
        Del_Party
        Yes_Open
        return
      else
        let l++
        sleep 20s
      fi
    done
    echo "克隆主仓库失败，正在恢复文件"
    Initialization
    exit
  fi
}

#备份仓库
function Git_Backup {
  echo "克隆(更新)$j号仓库成功，开始备份仓库内容"
  if [ ! -d "$dir_backup/${uniq_path}" ]; then
    \cp -af $repo_path $dir_backup
  else
    rsync -a $dir_backup/${uniq_path} $old_backup
    rm -rf $dir_backup/${uniq_path}
    \cp -af $repo_path $dir_backup
  fi
  echo "备份成功，开始合并$j号仓库"
  Consolidated_Warehouse
}

function Git_Backup_Old {
  echo "克隆(更新)$j号仓库失败，使用备份文件"
  if [ ! -d "$dir_backup/${uniq_path}" ]; then
    echo "无备份文件，跳过此库"
  else
    \cp -af $dir_backup/${uniq_path}/. $repo_path
    Consolidated_Warehouse
  fi
  echo "清理失败缓存"
  rm -rf $repo_path
}

#pull函数
function Git_Pull {
  if [ "$push_diy" = "1" ]; then
    git config --global http.proxy "socks5://$sock5_diy"
    git config --global https.proxy "socks5://$sock5_diy"
  fi
  cd $repo_path
  git remote remove origin
  git remote add origin $pint_warehouse
  git fetch --all
  ExitStatusShell=$?
  git reset --hard origin/$pint_branch
  if [ $? = 0 ] && [ $ExitStatusShell = 0 ]; then
    socks_git_unset
    Git_Backup
  else
    socks_git_unset
    echo "清理失败缓存，并采用clone"
    rm -rf $repo_path
    Git_Clone
  fi
}

#clone函数
function Git_Clone {
  cd $dir_repo
  git clone -b $pint_branch ${github_proxy_url}$pint_warehouse $repo_path
  if [ $? = 0 ]; then
    Git_Backup
  else
    Git_Backup_Old
  fi
}

#合并仓库（网络仓库）
function Consolidated_Warehouse {
 if [ "$pint_diy_feihebing" = "" ]; then
    echo "您已选择将所有文件合并到根目录，开始执行"
    sleep 3s
    \cp -af $repo_path/. $tongbu_temp
    cd $tongbu_temp
    Delete_git
    prefix_suffix
    if [ "$pint_fugai" = "" -o "$pint_fugai" = "1"  ]; then
      echo "您已选择强制覆盖同名文件"
      \cp -af $tongbu_temp/. $tongbu_push
    else
      echo "您已选择跳过同名文件"
      cp -rn $tongbu_temp/. $tongbu_push
    fi
    echo "合并$j号仓库成功，清理文件"
    for n in `ls -a`; do
      rm -rf $n >/dev/null 2>&1
    done
  else
    echo "您已选择将文件夹合并到根目录，开始执行"
    sleep 3s
    mkdir $tongbu_temp/$pint_diy_feihebing
    \cp -af $repo_path/. $tongbu_temp/$pint_diy_feihebing
    cd $tongbu_temp/$pint_diy_feihebing
    Delete_git
    prefix_suffix
    if [ "$pint_fugai" = "" -o "$pint_fugai" = "1"  ]; then
      echo "您已选择强制覆盖同名文件"
      \cp -af $tongbu_temp/$pint_diy_feihebing $tongbu_push
    else
      echo "您已选择跳过同名文件"
      cp -rn $tongbu_temp/$pint_diy_feihebing $tongbu_push
    fi
    echo "合并$j号仓库成功，清理文件"
    for n in `ls -a`; do
      rm -rf $n >/dev/null 2>&1
    done
  fi
}

#识别clone或者pull
function Clone_Pull {
  echo -e "\n======================开始执行$j号仓库的拉取合并========================\n"
  if [ ! -d "$repo_path/.git/" ]; then
    echo "执行clone"
    Git_Clone
  else
    echo "执行git pull"
    Git_Pull
  fi
  echo -e "\n========================$j号仓库的拉取合并结束========================\n"
}

#重命名仓库文件
function prefix_suffix {
  if [[ $pint_name = "" ]] && [[ $pint_file = "" ]]; then
    echo "未定义重命名参数"
  else
    echo "已定义重命名参数，开始重命名文件"
    rename $pint_name $pint_file
    echo "重命名完成"
  fi
}


#库名称判定(网络仓库)
get_uniq_path() {
  local url="$1"
  local branch="$2"
  local urlTmp="${url%*/}"
  local repoTmp="${urlTmp##*/}"
  local repo="${repoTmp%.*}"
  local tmp="${url%/*}"
  local authorTmp1="${tmp##*/}"
  local authorTmp2="${authorTmp1##*:}"
  local author="${authorTmp2##*.}"

  uniq_path="${author}_${repo}"
  [[ $branch ]] && uniq_path="${uniq_path}_${branch}"
}

#自定义仓库数量(网络仓库)
function Count_diy_party_warehouse {
  i=1
  while [ $i -le 1000 ]; do
    Tmp=diy_party_warehouse$i
    diy_warehouse_Tmp=${!Tmp}
    [[ ${diy_warehouse_Tmp} ]] && diySum=$i || break
    let i++
  done
}

#合并仓库(网络仓库)
function Change_diy_party_warehouse {
  h=${diySum}
  for ((j=1; j<=$h; j++)); do
    for num in ${TempBlockwarehouse}; do
      if [[ $j -eq $num ]]; then
        continue 2
      fi
    done
    Tmp_warehouse=diy_party_warehouse$j
    Tmp_warehouse_branch=diy_party_warehouse_branch$j
    Tmp_diy_feihebing=diy_feihebing$j
    Tmp_fugai=fugai$j
    Tmp_name=rename_name$j
    Tmp_file=rename_file$j
    warehouse_Tmp=${!Tmp_warehouse}
    branch_Tmp=${!Tmp_warehouse_branch}
    feihebing_Tmp=${!Tmp_diy_feihebing}
    fugai_Tmp=${!Tmp_fugai}
    name_Tmp=${!Tmp_name}
    file_Tmp=${!Tmp_file}
    pint_warehouse=${warehouse_Tmp}
    pint_branch=${branch_Tmp}
    pint_diy_feihebing=${feihebing_Tmp}
    pint_fugai=${fugai_Tmp}
    pint_name=${name_Tmp}
    pint_file=${file_Tmp}
    get_uniq_path "$pint_warehouse" "$pint_branch"
    local repo_path="${dir_repo}/${uniq_path}"
    Clone_Pull
    cd $tongbu_push
    if [ -e "model" ]; then
      echo "确认文件存在，继续执行拉库命令"
    else
      echo "文件存在异常，清除缓存并停止整个上传动作"
      Initialization
      exit
    fi
  done
}

#合并仓库(网络仓库-RAW)
Update_Own_Raw () {
  local rm_mark
  [[ ${#OwnRawFile[*]} -gt 0 ]] && echo -e "\n=========================开始拉取raw并合并==========================\n"
  for ((i=0; i<${#OwnRawFile[*]}; i++)); do
    raw_file_name[$i]=$(echo ${OwnRawFile[i]} | awk -F "/" '{print $NF}')
    echo "开始下载：${OwnRawFile[i]} 保存路径：$raw_flie/${raw_file_name[$i]}"
    wget -q --no-check-certificate -O "$raw_flie/${raw_file_name[$i]}.new" ${OwnRawFile[i]}
    if [[ $? -eq 0 ]]; then
      mv "$raw_flie/${raw_file_name[$i]}.new" "$raw_flie/${raw_file_name[$i]}"
      echo "下载 ${raw_file_name[$i]} 成功,开始备份成功后的文件"
      \cp -af $raw_flie/${raw_file_name[$i]} $dir_backup_raw/${raw_file_name[$i]}
      echo "备份完成，开始合并"
      \cp -af $raw_flie/${raw_file_name[$i]} $tongbu_push
      echo "合并完成"
    else
      echo "下载 ${raw_file_name[$i]} 失败，保留之前正常下载的版本..."
      [ -f "$raw_flie/${raw_file_name[$i]}.new" ] && rm -f "$dir_raw/${raw_file_name[$i]}.new"
      echo "开始合并"
      \cp -af $raw_flie/${raw_file_name[$i]} $tongbu_push
      echo "合并完成"
    fi
  done

  for file in $(ls $raw_flie); do
    rm_mark="yes"
    for ((i=0; i<${#raw_file_name[*]}; i++)); do
      if [[ $file == ${raw_file_name[$i]} ]]; then
        rm_mark="no"
        break
      fi
    done
    [[ $rm_mark == yes ]] && rm -f $raw_flie/$file 2>/dev/null
  done
  [[ ${#OwnRawFile[*]} -gt 0 ]] && echo -e "\n=========================拉取raw并合并结束===========================\n"
}

#合并仓库(本地仓库)
function Local_Change_diy_party_warehouse {
  echo -e "\n=========================开始识别并合并diy文件==========================\n"
  echo "开始合并本地文件，目标文件夹$dir_root/diy，识别为diy文件夹$config_use"
  cd $diy_config
  if [ "`ls -A $diy_config`" = "" ];then
    echo "$diy_config文件夹为空文件夹，跳过合并"
  else
    echo "$diy_config文件夹已经存在，且存在文件，进行下一步"
    \cp -af $diy_config/. $tongbu_push
    echo "合并完成"
  fi
  echo -e "\n=========================识别并合并diy文件结束==========================\n"
}

#替换文件内容(仅替换互助码)
function Diy_Replace {
  echo -e "\n=============================开始替换文件内容==============================\n"
#  m=1
#  while [ $m -le 1000 ]; do
#    Tmp_sed=sed$m
#    sed_Tmp=${!Tmp_sed}
#    [[ ${sed_Tmp} ]] && diyurl=$m || break
#    let m++
#  done
#  n=1
#  while [[ $n -le ${diyurl} ]]; do
#    Tmp_sed=sed$n
#    sed_Tmp=${!Tmp_sed}
#    pint_sed=${sed_Tmp}
#    Tmp_find=find$n
#    find_Tmp=${!Tmp_find}
#    pint_find=${find_Tmp}
#    find ./ -type f ${pint_find}|xargs sed -i "${pint_sed}"
#    let n++
#  done
  cd $tongbu_push
  source $file_diyreplace
  echo "拷贝.gitignore，黑白名单请填写 $file_gitignore 中的内容"
  cp -rfv $file_gitignore $tongbu_push
  echo -e "\n=============================替换文件内容结束==============================\n"
}

#上传文件至github
function Push_github1 {
  git config user.name "$diy_user_name"
  git config user.email "$diy_user_email"
  git commit --allow-empty -m "$diy_commit"
  git config --global --add core.filemode false
  git config --global sendpack.sideband false
  git config --local sendpack.sideband false
  git config --global http.lowSpeedLimit 1000
  git config --global http.lowSpeedTime 60
  git config --global http.postBuffer 524288000
  git config --global http.sslVerify "false"
  if [ "$push_diy" = "1" ]; then
    git config --global http.proxy "socks5://$sock5_diy"
    git config --global https.proxy "socks5://$sock5_diy"
  fi
  git push --force "https://$diy_user_name:$github_api@$diy_url" HEAD:$diy_branch
  if [ $? = 0 ]; then
    echo "上传成功"
    Initialization
    echo -e "\n===========================上传文件至网端结束==========================\n"
    return
  else
    k=1
    while [[ k -le 3 ]]; do
      echo "上传失败,重试执行第$k次"
      sleep 20s
      git push --force "https://$diy_user_name:$github_api@$diy_url" HEAD:$diy_branch
      if [ $? = 0 ]; then
        echo "上传成功"
        Initialization
        echo -e "\n===========================上传文件至网端结束==========================\n"
        return
      else
        let k++
      fi
    done
    echo "上传失败，正在恢复文件"
    Initialization
  fi
}

#上传文件至github
function Push_github {
  Diy_Replace
  echo -e "\n===========================开始上传文件至网端==========================\n"
  cd $tongbu_push
  if [ -e "model" ]; then
    echo "确认文件存在"
    chmod -R 777 $tongbu_push
    git rm -rq --cached .
    git add .
    source $shell_model/status.sh > $submit/1.log
    if test -s $submit/commit.log; then
      echo "文件存在变更，正常上传"
      source $shell_model/submit.sh > $submit/1.log
      if [ -e "$submit/D.log" ] && test -s $submit/D.log && [ "$number" -ge "0" ]; then
        Dnumber=`grep -o ',' $submit/D.log | wc -l`
        let Dnumber++
        echo "存在删除文件，删除文件数量为:$Dnumber"
        if [ "$Dnumber" -ge "$number" ]; then
          echo "文件删除数量大于等于设定值，请确认文件并调整设定值后重新运行脚本，以防出错"
          Initialization
          exit
        else
          echo "脚本文件正常，进行下一步"
          Push_github1
        fi
      else
        Push_github1
      fi
    else
      echo "无文件变更，取消上传，跳出并恢复文件"
      Initialization
    fi
  else
    echo "文件夹错误，取消上传"
    Initialization
    echo -e "\n===========================上传文件至网端结束==========================\n" 
  fi
}

#执行函数
echo "开始运行"
socks_git_set
Pull_diy_Third_party_warehouse
Count_diy_party_warehouse
Change_diy_party_warehouse
Update_Own_Raw
Local_Change_diy_party_warehouse
Push_github
socks_git_unset
echo "运行结束，退出"
exit
