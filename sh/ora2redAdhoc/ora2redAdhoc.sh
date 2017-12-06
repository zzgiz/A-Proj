#!/bin/bash
#
# 1.SQL作成       -- 第3パラメータで指定された場合のみ作成
# 2.データ取得    -- テーブル個別
# 3.S3転送
# 4.Redshift投入  -- テーブル個別 Truncate, Delete, 何もしない等

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

  psql -h XXXXX.redshift.amazonaws.com -U db_user1 -d db_name1 -p 1234 -c \
    "insert into ログテーブル values ('${TYP}','${SCHEMA}', '${TBL}', '${START_TIME}', '$(date '+%Y-%m-%d %H:%M:%S')', ${cnt}, '${sts}', '${errmsg}')" \
    1>/dev/null 2>>${MAIN_LOG}

  exit ${sts}
}

if [ ${#} -lt 1 ]; then
  echo "  例) Oracleからデータを取得しRedshiftに投入"
  echo "    sh ./ora2red.sh KIND1 TABLE_1"
  echo ""
  echo "  第1パラメータ: KIND1, KIND2 から選択"
  echo "  第2パラメータ: テーブル名"
  echo "  第3パラメータ: 1:SQL作成, 2:データ取得, 3:S3転送, 4:Redshift投入 まで実施 (省略可)"
  exit 0
fi

## 定数定義
TYP=${1}
TBL=${2}
if [ ${#} -ge 3 ]; then
  PROC_END=${3}
else
  PROC_END=4
fi

MAIN_LOG="ora2red.log"
DAY_DT=`date -u -d '9 hours' +%Y%m%d`
S3SUBDIR="latest_part"

if [ ${TYP} = 'KIND1' ]; then
  ORA_USR="user1"
  ORA_PAS="pass1"
  ORA_HST="host or IP address"
  S3PATH="s3://s3_path1"
  SCHEMA="schema1"

elif [ ${TYP} = 'KIND2' ]; then
  ORA_USR="user2"
  ORA_PAS="pass2"
  ORA_HST="host or IP address"
  S3PATH="s3://s3_path2"
  SCHEMA="schema2"

else
  echo "第1パラメータは KIND1, KIND2 から選択"
  exit 0
fi

log "Start! -------------"
START_TIME=$(date -u -d '9 hours' '+%Y-%m-%d %H:%M:%S')

## 1.SQL作成
if [ ${PROC_END} -le 1 ]; then
  # 既存ファイルあれば退避
  if [ -e ./sql/get_${TBL}.sql ]; then
    cp ./sql/get_"${TBL}".sql ./sql/get_"${TBL}"_"`date -u -d '9 hours' '+%Y%m%d_%H%M%S'`".sql
  fi

  # 作成
  sqlret=`sqlplus -s ${ORA_USR}/${ORA_PAS}@${ORA_HST} @./makeSql.sql ${TBL} ${DAY_DT}`
  ret=$?
  if [ `echo ${#sqlret}` -gt 0 ]; then
    echo "${sqlret}" >> ${MAIN_LOG}
    exit_func 1 "ERROR : sqlplusエラー"

  elif [ ${ret} -gt 0 ]; then
    csvtail=`tail ./sql/get_${TBL}.sql | grep -i 'ora\-[0-9]'`
    echo "${csvtail}" >> ${MAIN_LOG}
    exit_func 1 "ERROR : SQL作成エラー"
  fi

  log "--- SQL作成完了! ---"
  exit 0
fi

## 2.データ取得
# 出力先準備
if [ ! -e ./csv/${DAY_DT} ]; then
    mkdir ./csv/${DAY_DT}
fi

# 取得 (※個別SQL使用)
sqlret=`sqlplus -s ${ORA_USR}/${ORA_PAS}@${ORA_HST} @./sql/get_${TBL}.sql ${DAY_DT}`
ret=$?
if [ `echo ${#sqlret}` -gt 0 ]; then
  echo "${sqlret}" >> ${MAIN_LOG}
  rm ./csv/${DAY_DT}/${TBL}.csv
  exit_func 1 "ERROR : sqlplusエラー"

elif [ ${ret} -gt 0 ]; then
  csvtail=`tail ./csv/${DAY_DT}/${TBL}.csv | grep -i 'ora\-[0-9]'`
  echo "${csvtail}" >> ${MAIN_LOG}
  rm ./csv/${DAY_DT}/${TBL}.csv
  exit_func 1 "ERROR : データ取得エラー"
fi

if [ ${PROC_END} -le 2 ]; then
  exit_func 0 "--- データ取得完了! ---"
fi

## 3.S3に転送
if [ -e ./csv/${DAY_DT}/${TBL}.csv.gz ]; then
  rm ./csv/${DAY_DT}/${TBL}.csv.gz
fi
gzip ./csv/${DAY_DT}/${TBL}.csv

aws s3 cp ./csv/${DAY_DT}/${TBL}.csv.gz ${S3PATH}/${DAY_DT}/${S3SUBDIR}/${TBL}.csv.gz 1>/dev/null 2>>${MAIN_LOG}
ret=$?
if [ ${ret} -gt 0 ]; then
  exit_func 1 "ERROR : S3転送エラー"
fi

if [ ${PROC_END} -le 3 ]; then
  exit_func 0 "--- S3転送完了! ---"
fi

## 4.Redshiftに投入
# テーブル存在チェック
TBL_LW=`echo ${TBL} | tr [A-Z] [a-z]`
ret=`psql -h XXXXX.redshift.amazonaws.com -U db_user1 -d db_name1 -p 1234 -c \
  "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='"${SCHEMA}"' AND table_name='"${TBL_LW}"';"` 1>/dev/null 2>>${MAIN_LOG}

if [ `echo ${ret} | cut -d' ' -f3` -eq 0 ]; then
  exit_func 0 "テーブル未定義。S3保存で終了"
fi

# データ投入 (※個別SQL使用)
psql -h XXXXX.redshift.amazonaws.com -U db_user1 -d db_name1 -p 1234 -f \
  ./sql/set_${TBL}.sql -v SCHEMA=${SCHEMA} -v TBL=${TBL_LW} -v S3FILE="'${S3PATH}/${DAY_DT}/${S3SUBDIR}/${TBL}.csv.gz'" \
  1>/dev/null 2>>${MAIN_LOG}
ret=$?
if [ ${ret} -gt 0 ]; then
  exit_func 1 "ERROR : Redshift投入エラー"
fi

# 最新状態をバックアップ & 全件洗い替え
psql -h XXXXX.redshift.amazonaws.com -U db_user1 -d db_name1 -p 1234 -c \
  "UNLOAD( 'SELECT * FROM ${SCHEMA}.${TBL_LW}' ) TO '${S3PATH}/${DAY_DT}/${TBL_LW}.tsv' CREDENTIALS 'aws_access_key_id=XXXXX;aws_secret_access_key=XXXXX' DELIMITER '\t' ESCAPE GZIP ALLOWOVERWRITE;" \
  1>/dev/null 2>>${MAIN_LOG}
ret=$?
if [ ${ret} -gt 0 ]; then
  exit_func 1 "ERROR : バックアップエラー"
fi

psql -h XXXXX.redshift.amazonaws.com -U db_user1 -d db_name1 -p 1234 -c \
  "TRUNCATE TABLE ${SCHEMA}.${TBL_LW};" \
  1>/dev/null 2>>${MAIN_LOG}

psql -h XXXXX.redshift.amazonaws.com -U db_user1 -d db_name1 -p 1234 -c \
  "COPY ${SCHEMA}.${TBL_LW} FROM '${S3PATH}/${DAY_DT}/${TBL_LW}.tsv' CREDENTIALS 'aws_access_key_id=XXXXX;aws_secret_access_key=XXXXX' DELIMITER '\t' ESCAPE GZIP DATEFORMAT 'auto';" \
  1>/dev/null 2>>${MAIN_LOG}



## csv過去データ削除
find ./csv -type d -mtime +15 -print | xargs -r rm -rf


# テーブル件数取得
ret=`psql -h XXXXX.redshift.amazonaws.com -U db_user1 -d db_name1 -p 1234 -c \
  'SELECT COUNT(*) FROM '${SCHEMA}'.'${TBL_LW}';'` 1>/dev/null 2>>${MAIN_LOG}
TBL_CNT=`echo ${ret} | cut -d' ' -f3`

exit_func 0 "Succeeded! ---------" ${TBL_CNT}


