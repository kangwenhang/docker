#!/usr/bin/env bash

#获取仓库更新日志
function Git_log {
  if [ "$diy_commit" = "" ]; then
    echo "未设置自定义提交内容，使用系统级识别日志"
    grep ^[A].* $submit/commit.log 2>&1 | tee $submit/A.log
    grep ^[C].* $submit/commit.log 2>&1 | tee $submit/C.log
    grep ^[D].* $submit/commit.log 2>&1 | tee $submit/D.log
    grep ^[M].* $submit/commit.log 2>&1 | tee $submit/M.log
    grep ^[R].* $submit/commit.log 2>&1 | tee $submit/R.log
    grep ^[T].* $submit/commit.log 2>&1 | tee $submit/T.log
    grep ^[U].* $submit/commit.log 2>&1 | tee $submit/U.log
    grep ^[X].* $submit/commit.log 2>&1 | tee $submit/X.log
    cat /dev/null > $submit/commit.log
    for z in `ls $submit`; do
      if [ "$z" != "$submit/commit.log" ]; then
        if test -s $submit/$z; then
          awk '{$1="";print $0}' $submit/$z 2>&1 | tee $submit/push.log
          sed '1s/^/[/;$!s/$/,/;$s/$/]/' $submit/push.log 2>&1 | tee $submit/$z
          cat $submit/$z | xargs 2>&1 | tee $submit/push.log
          cat $submit/push.log 2>&1 | tee $submit/$z
        fi
      fi
    done
    if [ -e "$submit/A.log" ] && test -s $submit/A.log; then
      sed 's/^/新增：/' $submit/A.log 2>&1 | tee -a $submit/commit.log
    fi
    if [ -e "$submit/C.log" ] && test -s $submit/C.log; then
      sed 's/^/拷贝：/' $submit/C.log 2>&1 | tee -a $submit/commit.log
    fi
    if [ -e "$submit/D.log" ] && test -s $submit/D.log; then
      sed 's/^/删除：/' $submit/D.log 2>&1 | tee -a $submit/commit.log
    fi
    if [ -e "$submit/M.log" ] && test -s $submit/M.log; then
      sed 's/^/修改内容：/' $submit/M.log 2>&1 | tee -a $submit/commit.log
    fi
    if [ -e "$submit/R.log" ] && test -s $submit/R.log; then
      sed 's/^/修改文件名：/' $submit/R.log 2>&1 | tee -a $submit/commit.log
    fi
    if [ -e "$submit/T.log" ] && test -s $submit/T.log; then
      sed 's/^/文件类型修改：/' $submit/T.log 2>&1 | tee -a $submit/commit.log
    fi
    if [ -e "$submit/U.log" ] && test -s $submit/U.log; then
      sed 's/^/未合并：/' $submit/U.log 2>&1 | tee -a $submit/commit.log
    fi
    if [ -e "$submit/X.log" ] && test -s $submit/X.log; then
      sed 's/^/状态错误：/' $submit/X.log 2>&1 | tee -a $submit/commit.log
    fi
    diy_commit=$(cat $submit/commit.log)
  else
    echo "已设置提交内容，进行下一步"
  fi
}

Git_log
