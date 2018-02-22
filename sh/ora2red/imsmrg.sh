#!/bin/bash

source /home/user1/.bash_profile 1>/dev/null
cd /home/user1/batch/

MAIN_LOG="ora2red.log"
SCMAS=("SYS1" "SYS2" "SYS3" "SYS4" "SYS5")
SRC_SCMA="SYS"
DST_SCMA="scma1"

function log() {
  echo -e "$(date -u -d '9 hours' '+%Y-%m-%d %H:%M:%S')\\t$@\\tMRG-IMP" >> ${MAIN_LOG} 2>&1
}

# 非同期取得
function get_data_async() {
  tbl=${1}
  start_time=$(date -u -d '9 hours' '+%Y-%m-%d %H:%M:%S')
  pids=()

  # 全スキーマS3まで取得
  for scma in ${SCMAS[@]}; do
    sh ./ora2red.sh ${scma} ${tbl} 3 &
    pids[$!]=$!
  done

  # 取得プロセス終了待ち
  err_end=0
  for pid in ${pids[@]}; do
    wait $pid
    if [ $? -gt 0 ]; then
      err_end=1
      break
    fi
  done

  # S3からredshift投入
  merge_data "${tbl}" "${start_time}" ${err_end} &
}

# 同期取得
function get_data() {
  tbl=${1}
  start_time=$(date -u -d '9 hours' '+%Y-%m-%d %H:%M:%S')

  # 全スキーマS3まで取得
  err_end=0
  for scma in ${SCMAS[@]}; do
    sh ./ora2red.sh ${scma} ${tbl} 3
    if [ $? -gt 0 ]; then
      err_end=1
      break
    fi
  done

  # S3からredshift投入
  merge_data "${tbl}" "${start_time}" ${err_end} &
}

# マージ
function merge_data() {
  tbl=${1}
  start_time=${2}
  err_end=${3}


  # S3からredshift投入
  if [ ${err_end} -eq 0 ]; then
    scma="SYS4"
    sh ./ora2red.sh ${scma} ${tbl} 5

    # テーブル件数取得
    tbl_lw=`echo ${tbl} | tr [A-Z] [a-z]`
    ret=`psql -h XXX.amazonaws.com -U XXXX -d XXXX -p XXXX -c \
         'SELECT COUNT(*) FROM '${DST_SCMA}'.'${tbl_lw}';'` 1>/dev/null 2>>${MAIN_LOG}
    tbl_cnt=`echo ${ret} | cut -d' ' -f3`

    sts=0
    errmsg=""
  else
    tbl_cnt="null"
    sts=1
    errmsg="マージエラー"
  fi

  # ログ保存
  psql -h XXXX.redshift.amazonaws.com -U XXXX -d XXXX -p XXXX -c \
    "insert into scma_a.batch_log values ('${SRC_SCMA}','${DST_SCMA}', '${tbl}', '${start_time}', '$(date '+%Y-%m-%d %H:%M:%S')', ${tbl_cnt}, '${sts}', '${errmsg}')" \
    1>/dev/null 2>>${MAIN_LOG}
}

# メイン

log "SYS MERGE Start ---"

get_data ${1}

log "SYS MERGE End -----"


