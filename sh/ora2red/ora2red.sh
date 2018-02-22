#!/bin/bash
#
# Oracleからデータを取得し、S3およびRedshiftに投入する
# オプションにより取得方法等を選択可能
#
# 1.SQL作成
# 2.データ取得
# 3.S3転送
# 4.Redshift投入
#
# ※動作に必要なファイル
#   makeSql.sql
#   makePartList.sql

source /home/user1/.bash_profile 1>/dev/null

function log() {
  echo -e "$(date -u -d '9 hours' '+%Y-%m-%d %H:%M:%S')\\t$@\\t${TYP}\\t${SCHEMA}\\t${TBL}" >> ${MAIN_LOG} 2>&1
}

function exit_func() {
  sts=${1}
  errmsg=${2}
  cnt=${3}

  log "${errmsg}"

  [ "${cnt}" = "" ] && cnt="null"
  [ ${sts} -eq 0 ] && errmsg=""

  psql -h XXXX.redshift.amazonaws.com -U XXXX -d XXXX -p XXXX -c \
    "insert into schema_a.batch_log values ('${TYP}','${SCHEMA}', '${TBL}', '${START_TIME}', '$(date '+%Y-%m-%d %H:%M:%S')', ${cnt}, '${sts}', '${errmsg}')" \
    1>/dev/null 2>>${MAIN_LOG}

  exit ${sts}
}

function get_data() {
  # データ取得
  sqlret=`sqlplus -s ${ORA_USR}/${ORA_PAS}@${ORA_HST} @./sql/${SQL_FILE} ${prtnm}`
  ret=$?
  if [ `echo ${#sqlret}` -gt 0 ]; then
    echo "${sqlret}" >> ${MAIN_LOG}
    rm ./csv/${DAY_DT}/${CSV_FILE}
    exit_func 1 "ERROR : sqlplusエラー"
  
  elif [ ${ret} -gt 0 ]; then
    filetail=`tail ./csv/${DAY_DT}/${CSV_FILE} | grep -i 'ora\-[0-9]'`
    echo "${filetail}" >> ${MAIN_LOG}
    rm ./csv/${DAY_DT}/${CSV_FILE}
    exit_func 1 "ERROR : データ取得エラー"
  fi
  
  if [ -e ./csv/${DAY_DT}/${CSV_FILE}.gz ]; then
    rm ./csv/${DAY_DT}/${CSV_FILE}.gz
  fi
  gzip ./csv/${DAY_DT}/${CSV_FILE}

  return 0
}

function send_s3() {
  # S3に転送
  aws s3 cp ./csv/${DAY_DT}/${CSV_FILE}.gz ${S3PATH}/${DAY_DT}/${CSV_FILE}.gz 1>/dev/null 2>>${MAIN_LOG}
  ret=$?
  if [ ${ret} -gt 0 ]; then
    exit_func 1 "ERROR : S3転送エラー"
  fi
  return 0
}

function import_data() {
  # Redshiftに投入

  # テーブル存在チェック
  TBL_LW=`echo ${TBL} | tr [A-Z] [a-z]`
  ret=`psql -h XXXX.redshift.amazonaws.com -U XXXX -d XXXX -p XXXX -c \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='"${SCHEMA}"' AND table_name='"${TBL_LW}"';"` 1>/dev/null 2>>${MAIN_LOG}
  if [ `echo ${ret} | cut -d' ' -f3` -eq 0 ]; then
    exit_func 0 "テーブル未定義。S3保存で終了"
  fi
  
  # TRUNCATE
  psql -h XXXX.redshift.amazonaws.com -U XXXX -d XXXX -p XXXX -c \
    "truncate table ${SCHEMA}.${TBL};" 1>/dev/null 2>>${MAIN_LOG}
  ret=$?
  if [ ${ret} -gt 0 ]; then
    exit_func 1 "ERROR : TRUNCATEエラー"
  fi
  
  # 投入
  [ -z ${CSV_FILE} ] && CSV_FILE=${TBL}
  psql -h XXXX.redshift.amazonaws.com -U XXXX -d XXXX -p XXXX -c \
    "copy ${SCHEMA}.${TBL} from '${S3PATH}/${DAY_DT}/${CSV_FILE}' \
       CREDENTIALS 'aws_access_key_id=XXXXX;aws_secret_access_key=XXXXX' \
       GZIP CSV IGNOREHEADER 1 DELIMITER ',' DATEFORMAT 'auto';" 
    1>/dev/null 2>>${MAIN_LOG}
  ret=$?
  if [ ${ret} -gt 0 ]; then
    exit_func 1 "ERROR : Redshift投入エラー"
  fi

  # テーブル件数取得
  ret=`psql -h XXXX.redshift.amazonaws.com -U XXXX -d XXXX -p XXXX -c \
    'SELECT COUNT(*) FROM '${SCHEMA}'.'${TBL_LW}';'` 1>/dev/null 2>>${MAIN_LOG}
  TBL_CNT=`echo ${ret} | cut -d' ' -f3`

  exit_func 0 "Succeeded! ---------" ${TBL_CNT}
}

#-----------------------------------------------------------------
# Batch start

if [ ${#} -lt 1 ]; then
  echo "  例) Oracleからデータを取得しRedshiftに投入"
  echo "    sh ./ora2red.sh SYSA TBL_A 3 s list 1"
  echo ""
  echo "  第1パラメータ: SYSA... から選択"
  echo "  第2パラメータ: テーブル名"
  echo "  第3パラメータ: 1:SQL作成, 2:データ取得, 3:S3転送, 4:Redshift投入まで, 5:Redshift投入のみ実施 (省略時=4)"
  echo "  第4パラメータ: p:Partition, s:SubPartition データ取得方法 (省略時=一括取得。パーティション別取得無し)"
  echo "  第5パラメータ: list:既存パーティションリストファイルあり (省略時=既存リスト無し)"
  echo "  第6パラメータ: 既存パーティションリストファイル 末尾番号 (省略時=末尾番号無し)"
  exit 0
fi

## 定数定義
TYP=${1}
TBL=${2}
PROC_END=${3}
PART_TYPE=${4}
LIST_EXST=${5}
LIST_NO=${6}

MAIN_LOG="ora2red.log"
DAY_DT=`date -u -d '9 hours' +%Y%m%d`

if [ -z "${PROC_END}" ]; then
  PROC_END=4
elif [ ${#PROC_END} -gt 1 ] || [[ ! ${PROC_END} =~ [1-5] ]]; then
  echo "第3パラメータ: 1～5 or 省略"
  exit 1
fi
if [ "${PART_TYPE}" = "p" ]; then
  PART_TYPE="PART"
elif [ "${PART_TYPE}" = "s" ]; then
  PART_TYPE="SUBPART"
else
  PART_TYPE="none"
fi
if [ "${LIST_EXST}" = "list" ]; then
  LIST_EXST=TRUE
  PART_LIST="./csv/${TBL}_part${LIST_NO}.lst"
elif [ -z "${LIST_EXST}" ] && [ "${PART_TYPE}" != "none" ]; then
  LIST_EXST=FALSE
  PART_LIST="./csv/${DAY_DT}/${TBL}_part.lst"
else
  LIST_EXST=FALSE
  PART_LIST=""
fi

if [ ${TYP} = 'SYSA' ]; then
  # SYS_A
  ORA_USR="user"
  ORA_PAS="pass"
  ORA_HST="host"
  S3PATH="path"
  SCHEMA="schema"

elif [ ${TYP} = 'SYSB' ]; then
  # SYS_B
  ORA_USR="user"
  ORA_PAS="pass"
  ORA_HST="host"
  S3PATH="path"
  SCHEMA="schema"

elif [ ${TYP} = 'SYSC' ]; then
  # SYS_C
  ORA_USR="user"
  ORA_PAS="pass"
  ORA_HST="host"
  S3PATH="path"
  SCHEMA="schema"

else
  echo "第1パラメータは SYSA... から選択"
  exit 0
fi

log "Start! -------------"
START_TIME=$(date -u -d '9 hours' '+%Y-%m-%d %H:%M:%S')

## csv過去データ削除
[ ! -e ./csv ] && mkdir csv 
find ./csv -type d -mtime +15 -print | xargs -r rm -rf

## 1.SQL作成
if [ ${PROC_END} -le 4 ]; then

  if [[ ${TYP} =~ IMS[0-9] ]]; then
    type_no=`echo ${TYP} | rev | cut -c 1`
    SQL_FILE="get_${TBL}_${type_no}.sql"
    CSV_FILE="${TBL}_${type_no}"
  else
    SQL_FILE="get_${TBL}.sql"
    CSV_FILE="${TBL}"
  fi

  if [ "${PART_TYPE}" = "none" ]; then
    CSV_FILE="${CSV_FILE}.csv"
  else
    CSV_FILE="${CSV_FILE}_&1..csv"
  fi

  [ ! -e ./sql ] && mkdir sql
  sqlret=`sqlplus -s ${ORA_USR}/${ORA_PAS}@${ORA_HST} @./makeSql.sql ${TBL} ${DAY_DT} ${SQL_FILE} ${CSV_FILE} ${PART_TYPE}`
  ret=$?
  if [ `echo ${#sqlret}` -gt 0 ]; then
    echo "${sqlret}" >> ${MAIN_LOG}
    exit_func 1 "ERROR : sqlplusエラー"
  
  elif [ ${ret} -gt 0 ]; then
    filetail=`tail ./sql/${SQL_FILE} | grep -i 'ora\-[0-9]'`
    echo "${filetail}" >> ${MAIN_LOG}
    exit_func 1 "ERROR : SQL作成エラー"
  fi

  # パーティションリスト作成(必要な場合のみ)
  if [ "${PART_TYPE}" != "none" ] && [ ${LIST_EXST} = FALSE ]; then
    mkdir -p ./csv/${DAY_DT}
    sqlplus -s ${ORA_USR}/${ORA_PAS}@${ORA_HST} @./makePartList.sql ${TBL} ${DAY_DT} ${PART_TYPE}
    ret=$?
    if [ ${ret} -gt 0 ]; then
      filetail=`tail ${PART_LIST} | grep -i 'ora\-[0-9]'`
      echo "${filetail}" >> ${MAIN_LOG}
      exit_func 1 "ERROR : パーティションリスト作成エラー"
    fi
  fi

  if [ ${PROC_END} -eq 1 ]; then
    log "--- SQL作成完了! ---"
    exit 0
  fi
fi

## 2.データ取得, 3.転送
if [ ${PROC_END} -le 4 ]; then

  mkdir -p ./csv/${DAY_DT}

  # 取得,転送
  if [ "${PART_TYPE}" = 'PART' ] || [ "${PART_TYPE}" = 'SUBPART' ]; then
    # パーティション分割で取得

    if [ ${LIST_EXST} = TRUE ] && [ ! -e ${PART_LIST} ]; then
      exit_func 1 "ERROR : リストファイル無し ${PART_LIST}"
    fi

    csv_file_def=${CSV_FILE}

    cat ${PART_LIST} | while read line
    do
      if [[ ${line} =~ ^# ]] || [ "${line}" == "" ]; then
        continue
      fi

      prtnm=`echo ${line} | cut -d ' ' -f 1`  # パーティション名
      CSV_FILE=`echo ${csv_file_def/&1./${prtnm}}`

      log "${prtnm} start"
    
      # 取得
      get_data
    
      # S3に転送
      if [ ${PROC_END} -ge 3 ]; then
        send_s3
      fi
    
      log "${prtnm} end"
    done

    ret=$?
    if [ ${ret} -gt 0 ]; then
      if [ -e ./csv/${DAY_DT}/${CSV_FILE} ]; then
        rm ./csv/${DAY_DT}/${CSV_FILE}
      fi
      exit_func ${ret} "ERROR : partition loop error"
    fi

    # ファイル名リセット
    CSV_FILE=${TBL}	

  else
    # 一括取得 
    get_data

    # S3転送
    if [ ${PROC_END} -ge 3 ]; then
      send_s3
    fi
  fi

  if [ ${PROC_END} -le 2 ]; then
    exit_func 0 "--- データ取得完了! ---"
  elif [ ${PROC_END} -le 3 ]; then
    exit_func 0 "--- S3転送完了! ---"
  fi
fi

## 4.Redshiftに投入
if [ ${PROC_END} -ge 4 ]; then

  import_data &

fi


