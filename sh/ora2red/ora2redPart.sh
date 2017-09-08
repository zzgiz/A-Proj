#!/bin/bash
#
# データをパーティションごとに取得。データ量が多い場合などに使用
#
# 1.SQL作成
# 2.データ取得    -- Partition単位で取得
# 3.S3転送
# 4.Redshift投入

source /home/user1/.bash_profile 1>/dev/null

function log() {
  echo -e "$(date -u -d '9 hours' '+%Y-%m-%d %H:%M:%S')\\t$@\\t[${TYP}] [$SCHEMA] [${TBL}]" >> ${MAIN_LOG} 2>&1
}

if [ ${#} -lt 1 ]; then
  echo "  例) Oracleからデータを取得しRedshiftに投入"
  echo "    sh ./ora2red.sh KIND TABLE_NAME"
  echo ""
  echo "  第1パラメータ: S1,S2 から選択"
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
PART_LIST="./csv/${DAY_DT}/${TBL}_part.lst"

if [ ${TYP} = 'S1' ]; then
  # 1
  ORA_USR="ORACLE_USER_1"
  ORA_PAS="XXXX"
  ORA_HST="ORACLE_HOST_NAME_or_HOST_ADDRESS"
  S3PATH="s3://S3パス1/"
  SCHEMA="schema_1"

elif [ ${TYP} = 'S2' ]; then
  # 1
  ORA_USR="ORACLE_USER_2"
  ORA_PAS="XXXX"
  ORA_HST="ORACLE_HOST_NAME_or_HOST_ADDRESS"
  S3PATH="s3://S3パス2/"
  SCHEMA="schema_2"

else
  echo "第1パラメータは S1,S2 から選択"
  exit 0
fi

log "Start! -------------"

## 1.SQL作成
sqlret=`sqlplus -s ${ORA_USR}/${ORA_PAS}@${ORA_HST} @./makeSqlPart.sql ${TBL} ${DAY_DT}`
ret=$?
if [ `echo ${#sqlret}` -gt 0 ]; then
  log "ERROR : sqlplusエラー"
  echo "${sqlret}" >> ${MAIN_LOG}
  exit 1
elif [ ${ret} -gt 0 ]; then
  csvtail=`tail ./sql/get_${TBL}.sql | grep -i 'ora\-[0-9]'`
  log "ERROR : SQL作成エラー"
  echo "${csvtail}" >> ${MAIN_LOG}
  exit 1
fi

# SQL作成のみの場合はここで終了
if [ ${PROC_END} -le 1 ]; then
  log "--- SQL作成完了! ---"
  exit 0;
fi

## 2.データ取得
# 出力先準備
if [ ! -e ./csv/${DAY_DT} ]; then
    mkdir ./csv/${DAY_DT}
fi

# パーティションリスト作成
sqlret=`sqlplus -s ${ORA_USR}/${ORA_PAS}@${ORA_HST} @./makePartList.sql ${TBL} ${DAY_DT}`

cnt=1
cat ${PART_LIST} | while read line
do
  if [[ ${line} =~ ^# ]] || [ "${line}" == "" ]; then
    continue
  fi

  prtnm=`echo ${line} | cut -d ' ' -f 1`  # パーティション名
  log "${prtnm} start"

  # 取得
  sqlret=`sqlplus -s ${ORA_USR}/${ORA_PAS}@${ORA_HST} @./sql/get_${TBL}.sql ${prtnm}`
  ret=$?
  if [ `echo ${#sqlret}` -gt 0 ]; then
    log "ERROR : sqlplusエラー"
    echo "${sqlret}" >> ${MAIN_LOG}
    exit 1
  elif [ ${ret} -gt 0 ]; then
    csvtail=`tail ./csv/${DAY_DT}/${TBL}_${prtnm}.csv | grep -i 'ora\-[0-9]'`
    log "ERROR : データ取得エラー"
    echo "${csvtail}" >> ${MAIN_LOG}
    exit 1
    #continue
  fi
  
  if [ -e ./csv/${DAY_DT}/${TBL}_${prtnm}.csv.gz ]; then
    rm ./csv/${DAY_DT}/${TBL}_${prtnm}.csv.gz
  fi
  gzip ./csv/${DAY_DT}/${TBL}_${prtnm}.csv
  
  ## 3.S3に転送
  if [ ${PROC_END} -ge 3 ]; then
    aws s3 cp ./csv/${DAY_DT}/${TBL}_${prtnm}.csv.gz ${S3PATH}/${DAY_DT}/${TBL}_${prtnm}.csv.gz 1>/dev/null 2>>${MAIN_LOG}
    ret=$?
    if [ ${ret} -gt 0 ]; then
      log "ERROR : S3転送エラー"
      exit 1
      #continue
    fi
  fi

  cnt=$((cnt + 1))

  log "${prtnm} end"
done

ret=$?
if [ ${ret} -gt 0 ]; then
  exit ${ret}
fi

if [ ${PROC_END} -le 2 ]; then
  log "--- データ取得完了! ---"
  exit 0;
elif [ ${PROC_END} -le 3 ]; then
  log "--- S3転送完了! ---"
  exit 0;
fi

## 4.Redshiftに投入
# テーブル存在チェック
TBL_LW=`echo ${TBL} | tr [A-Z] [a-z]`
ret=`psql -h XXXXX.redshift.amazonaws.com -U DBユーザ -d DB名 -p ポート -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='"${SCHEMA}"' AND table_name='"${TBL_LW}"';"` 1>/dev/null 2>>${MAIN_LOG}
if [ `echo ${ret} | cut -d' ' -f3` -eq 0 ]; then
    log "テーブル未定義。S3保存で終了"
    exit 0
fi

# TRUNCATE
psql -h XXXXX.redshift.amazonaws.com -U DBユーザ -d DB名 -p ポート -c "truncate table ${SCHEMA}.${TBL};" 1>/dev/null 2>>${MAIN_LOG}
ret=$?
if [ ${ret} -gt 0 ]; then
  log "ERROR : TRUNCATEエラー"
  exit 1
fi

# 投入
for csvfile in $( aws s3 ls ${S3PATH}/${DAY_DT}/ | grep ${TBL} | awk '{print $4}' ); do
  psql -h XXXXX.redshift.amazonaws.com -U DBユーザ -d DB名 -p ポート -c "copy ${SCHEMA}.${TBL} from '${S3PATH}/${DAY_DT}/${csvfile}' CREDENTIALS 'aws_access_key_id=XXXXX;aws_secret_access_key=XXXXX' GZIP CSV IGNOREHEADER 1 DELIMITER ',' DATEFORMAT 'auto';" 1>/dev/null 2>>${MAIN_LOG}
done

ret=$?
if [ ${ret} -gt 0 ]; then
  log "ERROR : Redshift投入エラー"
  exit 1
fi


## csv過去データ削除
find ./csv -type d -mtime +30 -print | xargs -r rm -rf


log "Succeeded! ---------"
exit 0

