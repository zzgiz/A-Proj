#!/bin/bash
#
# S3からRedshiftへ投入

if [ ${#} -lt 3 ]; then
  echo "  例)  ./s3totbl.sh S3KIND 20170801 TBL1"
  echo ""
  echo "  第1パラメータ: S1, S2, S3 から選択"
  echo "  第2パラメータ: S3日付"
  echo "  第3パラメータ: テーブル名"
  exit 0
fi

function log() {
  echo -e "$(date -u -d '9 hours' '+%Y-%m-%d %H:%M:%S') $@ [${TYP}] [${TBL}]" >> ${MAIN_LOG} 2>&1
}

TYP=${1}
DT=${2}
TBL=${3}
MAIN_LOG="s3totbl.log"

if [ ${TYP} = 'S1' ]; then
  # 1
  S3PATH="s3://S3パス1/"
  SCHEMA="schema_1"

elif [ ${TYP} = 'S2' ]; then
  # 2
  S3PATH="s3://S3パス2/"
  SCHEMA="schema_2"

elif [ ${TYP} = 'S3' ]; then
  # 3
  S3PATH="s3://S3パス3/"
  SCHEMA="schema_3"

else
  echo "第1パラメータは S1,S2,S3から選択"
  exit 0
fi

# Redshiftに投入
log "Start ---"

psql -h XXXXX.redshift.amazonaws.com -U DBユーザ -d DB名 -p ポート -c \
  "truncate table ${SCHEMA}.${TBL};" 1>/dev/null 2>>${MAIN_LOG}
ret=$?
if [ ${ret} -gt 0 ]; then
  log "TRUNCATEエラー!"
  exit 1
fi

psql -h XXXXX.redshift.amazonaws.com -U DBユーザ -d DB名 -p ポート -c \
  "copy ${SCHEMA}.${TBL} from '${S3PATH}/${DT}/${TBL}.csv.gz' \
  CREDENTIALS 'aws_access_key_id=XXXXXX;aws_secret_access_key=XXXXXX' \
  GZIP CSV IGNOREHEADER 1 DELIMITER ',' DATEFORMAT 'auto';" 1>/dev/null 2>>${MAIN_LOG}
ret=$?
if [ ${ret} -gt 0 ]; then
  log "COPYエラー!"
  exit 1
fi

log "End!  ---"
