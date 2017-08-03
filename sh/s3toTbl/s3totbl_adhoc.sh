#!/bin/bash
#
# 特定テーブル更新バッチ
# S3に作成された直近1週間分のデータをRedshiftのテーブルに投入する

cd /home/user1/     # 作業場所に移動

function log() {
  echo -e "$(date -u -d '9 hours' '+%Y-%m-%d %H:%M:%S')\\t$@" >> ${LOG_FILE} 2>&1
}

TGT_TBL="shema_name.table_name"
S3PATH="s3://XXXXXXXXXXX"               # 最後のスラッシュ無し
TGT_FILE="s3_file_name"
LIST_FILE="./s3totbl_achoc.lst"
LOG_FILE="./s3totbl_achoc.log"
TODAY=`date -u -d '9 hours' '+%Y-%m-%d'`
GET_DT=`date -d "${TODAY} 6 days ago" +%Y-%m-%d`

log "Start --------------------------------"

# S3ファイルリスト作成
echo `AWS_ACCESS_KEY_ID=XXXXX AWS_SECRET_ACCESS_KEY=XXXXX aws s3 ls ${S3PATH}/ | grep ${TGT_FILE} > ${LIST_FILE}` 1>/dev/null 2>>${LOG_FILE}


# リスト読み込み
cat ${LIST_FILE} | while read line
do
  if [[ ${line} =~ ^# ]] || [ "${line}" == "" ]; then
    continue
  fi

  # パラメタ読み込み
  updt=`echo ${line} | cut -d ' ' -f 1`
  uptm=`echo ${line} | cut -d ' ' -f 2`
  size=`echo ${line} | cut -d ' ' -f 3`
  file=`echo ${line} | cut -d ' ' -f 4`

  if [ ${#file} -le 1 ]; then
    continue
  fi

  # 日付確認
  upd=`date -d "${updt}" '+%s'`
  tgt=`date -d "${GET_DT}" '+%s'`
  if [ ${upd} -lt ${tgt} ]; then
    continue
  fi

  # Redshift投入
  log "${S3PATH}/${file}"
  psql -h XXXXX.redshift.amazonaws.com -U ユーザ -d DB名 -p ポート -c \
    "COPY ${TGT_TBL} FROM '${S3PATH}/${file}' CREDENTIALS 'aws_access_key_id=XXXXX;aws_secret_access_key=XXXXX' DELIMITER ',' REMOVEQUOTES;" \
    >> ${LOG_FILE} 2>&1

done

log "End   --------------------------------"

exit 0

