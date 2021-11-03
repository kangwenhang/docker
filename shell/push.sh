#!/usr/bin/env bash

#变量判定
source /push/shell/share.sh

#清除缓存
function Initialization {
  if [ ! -d "$tongbu_push" ];then
    echo "文件夹不存在，跳过清理"
  else
    echo "开始清理文件夹"
    cd $tongbu_push
    for n in `ls -a`;do
      rm -rf $n >/dev/null 2>&1
    done
  fi
  sleep 3s
}

#清除git信息
function Delete_git {
  echo "正在清除git信息"
  sleep 3s
  find . -name ".git" | xargs rm -Rf
}

#获取主仓库更新日志
function Git_log {
  if [ "$diy_commit" = "" ]; then
    echo "未设置自定义提交内容，默认拉取主仓库更新内容"
    git log --pretty=format:"%s %cr" > $diy_logs/diy.log
    cd $diy_logs
    diy_commit=`head -1 diy.log`
    echo "拉取成功"
  else
    echo "已设置提交内容，进行下一步"
  fi
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
  for m in `ls`;do
    if [ "$m" != .git ];then
      rm -rf $m
    fi
  done
}

#主仓库(网络仓库)
function Pull_diy_Third_party_warehouse {
  echo "正在克隆主仓库"
  git clone -b $diy_branch ${github_proxy_url}https://$diy_url $tongbu_push
  if [ $? = 0 ]; then
    echo "克隆第主仓库成功"
    cd $tongbu_push
    Del_Party
    Git_log
  else
    l=1
    while [[ l -le 3 ]]; do
      echo "克隆失败,重试执行第$l次"
      git clone -b $diy_branch ${github_proxy_url}https://$diy_url $tongbu_push
      if [ $? = 0 ]; then
        echo "克隆主仓库成功"
        cd $tongbu_push
        Del_Party
        Git_log
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
  if [ ! -d "$dir_backup/${uniq_path}" ];then
    cp -af $repo_path $dir_backup
  else
    rsync -a $dir_backup/${uniq_path} $old_backup
    rm -rf $dir_backup/${uniq_path}
    cp -af $repo_path $dir_backup
  fi
  echo "备份成功，开始合并$j号仓库"
  Consolidated_Warehouse
}

function Git_Backup_Old {
  echo "克隆(更新)$j号仓库失败，使用备份文件"
  if [ ! -d "$dir_backup/${uniq_path}" ];then
    echo "无备份文件，跳过此库"
  else
    cp -af $dir_backup/${uniq_path}/. $repo_path
    Consolidated_Warehouse
  fi
  echo "清理失败缓存"
  rm -rf $repo_path
}

#pull函数
function Git_Pull {
  git remote remove origin
  git remote add origin $pint_warehouse
  git fetch --all
  ExitStatusShell=$?
  git reset --hard origin/$pint_branch
  if [ $? = 0 ] && [ $ExitStatusShell = 0 ]; then
    Git_Backup
  else
    echo "清理失败缓存，并采用clone"
    rm -rf $repo_path
    Git_Clone
  fi
}

#clone函数
function Git_Clone {
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
    mkdir -p $tongbu_temp
    cp -af $repo_path/. $tongbu_temp
    cd $tongbu_temp
    Delete_git
    prefix_suffix
    if [ "$pint_fugai" = "" -o "$pint_fugai" = "1"  ]; then
      echo "您已选择强制覆盖同名文件"
      cp -af $tongbu_temp/. $tongbu_push
    else
      echo "您已选择跳过同名文件"
      cp -rn $tongbu_temp/. $tongbu_push
    fi
    echo "合并$j号仓库成功，清理文件"
    rm -rf $tongbu_temp
  else
    echo "您已选择将文件夹合并到根目录，开始执行"
    sleep 3s
    mkdir -p $tongbu_temp/$pint_diy_feihebing
    cp -af $repo_path/. $tongbu_temp/$pint_diy_feihebing
    cd $tongbu_temp/$pint_diy_feihebing
    Delete_git
    prefix_suffix
    if [ "$pint_fugai" = "" -o "$pint_fugai" = "1"  ]; then
      echo "您已选择强制覆盖同名文件"
      cp -af $tongbu_temp/$pint_diy_feihebing $tongbu_push
    else
      echo "您已选择跳过同名文件"
      cp -rn $tongbu_temp/$pint_diy_feihebing $tongbu_push
    fi
    echo "合并$j号仓库成功，清理文件"
    rm -rf $tongbu_temp
  fi
}

#识别clone或者pull
function Clone_Pull {
  echo -e "\n======================开始执行$j号仓库的拉取合并========================\n"
  if [ ! -d "$repo_path" ];then
    echo "文件夹不存在，创建并执行clone"
    mkdir -p $repo_path
    cd $dir_repo
    Git_Clone
  else
    echo "文件夹存在，进行下一步"
    cd $dir_repo
    ls -a
    if [ ! -d "$repo_path/.git/" ];then
      echo "执行clone"
      Git_Clone
    else
      echo "执行git pull"
      cd $repo_path
      Git_Pull
    fi
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
  j=1
  h=${diySum}
  while [[ $j -le $h ]]; do
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
    let j++
  done
}

#合并仓库(网络仓库-RAW)
Update_Own_Raw () {
  mkdir -p $raw_flie
  local rm_mark
  [[ ${#OwnRawFile[*]} -gt 0 ]] && echo -e "\n=========================开始拉取raw并合并==========================\n"
  for ((i=0; i<${#OwnRawFile[*]}; i++)); do
    raw_file_name[$i]=$(echo ${OwnRawFile[i]} | awk -F "/" '{print $NF}')
    echo "开始下载：${OwnRawFile[i]} 保存路径：$raw_flie/${raw_file_name[$i]}"
    wget -q --no-check-certificate -O "$raw_flie/${raw_file_name[$i]}.new" ${OwnRawFile[i]}
    if [[ $? -eq 0 ]]; then
      mv "$raw_flie/${raw_file_name[$i]}.new" "$raw_flie/${raw_file_name[$i]}"
      echo "下载 ${raw_file_name[$i]} 成功,开始备份成功后的文件"
      cp -af $raw_flie/${raw_file_name[$i]} $dir_backup_raw/${raw_file_name[$i]}
      echo "备份完成，开始合并"
      cp -af $raw_flie/${raw_file_name[$i]} $tongbu_push
      echo "合并完成"
    else
      echo "下载 ${raw_file_name[$i]} 失败，保留之前正常下载的版本..."
      [ -f "$raw_flie/${raw_file_name[$i]}.new" ] && rm -f "$dir_raw/${raw_file_name[$i]}.new"
      echo "开始合并"
      cp -af $raw_flie/${raw_file_name[$i]} $tongbu_push
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
  if [ ! -d "$dir_root/diy/$config_use" ];then
    echo "$diy_config文件夹不存在,创建$config_use文件夹"
    mkdir -p $diy_config
  else
    cd $diy_config
    if [ "`ls -A $diy_config`" = "" ];then
      echo "$diy_config文件夹为空文件夹，跳过合并"
    else
      echo "$diy_config文件夹已经存在，且存在文件，进行下一步"
      cp -af $diy_config/. $tongbu_push
      echo "合并完成"
    fi
  fi
  echo -e "\n=========================识别并合并diy文件结束==========================\n"
}

#替换文件内容(仅替换互助码)
function Diy_Replace {
echo -e "\n=============================开始替换文件内容==============================\n"
m=1
while [ $m -le 1000 ]; do
  Tmp_url=url$m
  url_Tmp=${!Tmp_url}
  [[ ${url_Tmp} ]] && diyurl=$m || break
  let m++
done
n=1
while [[ $n -le ${diyurl} ]]; do
  Tmp_url=url$n
  url_Tmp=${!Tmp_url}
  pint_url=${url_Tmp}
  sed_use=${sed_use}s@$pint_url@123@g';'
  let n++
done
sed -i "$sed_use" $tongbu_push/*.js
sed -i "$sed_use" $tongbu_push/*.py
echo -e "\n=============================替换文件内容结束==============================\n"
}

#确认项目
function Yes_Open {
  echo -e "\n=============================项目最终确认==============================\n"
  echo "拷贝确认文件"
  cp -fv $dir_root/sample/model.sample $tongbu_push/model
  echo "拷贝.gitignore，黑白名单请填写 $file_gitignore 中的内容"
  cp -rfv $file_gitignore $tongbu_push
  echo -e "\n=============================项目确认完成==============================\n"
}

#上传文件至github
function Push_github {
  Yes_Open
  echo -e "\n===========================开始上传文件至网端==========================\n"
  cd $tongbu_push
  if [ -e "model" ];then
    echo "确认文件夹存在"
    chmod -R 777 $tongbu_push
    git rm -rq --cached .
    git add .
    git status --short 2>&1 | tee $diy_logs/commit.log
    if test -s $diy_logs/commit.log;then
      echo "文件存在变更，正常上传"
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
      git push --force "https://$diy_user_name:$github_api@$diy_url" HEAD:$diy_branch
      if [ $? = 0 ]; then
        echo "上传成功"
        Initialization
      else
        k=1
        while [[ k -le 3 ]]; do
          echo "上传失败,重试执行第$k次"
          sleep 20s
          git push --force "https://$diy_user_name:$github_api@$diy_url" HEAD:$diy_branch
          if [ $? = 0 ]; then
            echo "上传成功"
            Initialization
            return
          else
            let k++
          fi
        done
        echo "上传失败，正在恢复文件"
        Initialization
      fi
    else
      echo "无文件变更，取消上传，跳出并恢复文件"
      Initialization
    fi
  else
    echo "文件夹错误，取消上传"
    Initialization
  fi
  echo -e "\n===========================上传文件至网端结束==========================\n"
}

#执行函数
echo "开始运行"
Initialization
Script_Pre
Pull_diy_Third_party_warehouse
Count_diy_party_warehouse
Change_diy_party_warehouse
Update_Own_Raw
Local_Change_diy_party_warehouse
Diy_Replace
Push_github
echo "运行结束，退出"
exit
