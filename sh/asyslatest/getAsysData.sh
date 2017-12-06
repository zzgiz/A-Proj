#!/bin/bash

if [ ${#} -lt 1 ]; then
  echo "  例1) データを取得しRedshiftに投入" 1>&2
  echo "    sh ./getAsysData.sh TRN_TBL" 1>&2
  echo "  例2) SQLのみ作成" 1>&2
  echo "    sh ./getAsysData.sh TRN_TBL 0" 1>&2
  exit 1
fi

# SQL作成
sqlplus -s ユーザ名/パスワード@接続文字列 @./makeSql.sql ${1}

if [ ${#} -gt 1 ]; then
  exit 1;
fi

# データ取得
sqlplus -s ユーザ名/パスワード@接続文字列 @./sql/get_${1}.sql

# S3に転送
if [ -e ./csv/${1}.csv.gz ]; then
  rm ./csv/${1}.csv.gz
fi
gzip ./csv/${1}.csv

TODAY=`date -u -d '9 hours' +%Y%m%d`
aws s3 cp ./csv/${1}.csv.gz s3://Ｓ３のアドレス/${TODAY}/${1}.csv.gz

# Redshiftに投入
psql -h ホスト名 -U ユーザ名 -d ＤＢ名 -p ポート -c "truncate table schema.${1};"
psql -h ホスト名 -U ユーザ名 -d ＤＢ名 -p ポート -c "copy schema.${1} from 's3://Ｓ３のアドレス/${TODAY}/${1}.csv.gz' gzip CSV IGNOREHEADER 1 credentials 'aws_access_key_id=アクセスキー; aws_secret_access_key=秘密鍵' delimiter ',' dateformat 'auto';"


# 過去ログ退避(15日以前)、過去データ削除(15日以前)
LOG_DT=`find ./log -maxdepth 1 -name '*.log' -mtime +15 -print | head -1 | cut -c14-21`
if [ ! -z "${LOG_DT}" ]; then
  cd ./log
  find -maxdepth 1 -name '*.log' -mtime +15 -print | tar -cz -T - -f ./_old/log_"${LOG_DT}".tar.gz --remove-files
  cd ../
fi
find ./csv -type d -mtime +15 -print | xargs -r rm -rf
