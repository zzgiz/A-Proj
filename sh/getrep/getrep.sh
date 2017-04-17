#!/bin/bash
#
#Description:
#データ取得

source /home/bduser/.bash_profile

cd /home/作業ディレクトリ/

TODAY=`date -u -d '9 hours' +%Y%m%d`
GET_DT=`date -d "${TODAY} 8 days ago" +%Y-%m-%d`

CSV_TITL='cust_data_'
CSV_EXT='.csv'
CSV_FILE="${CSV_TITL}${TODAY}${CSV_EXT}"
CSV_PATH="./csv/${CSV_FILE}"

echo "----" >> ./getrep.log
echo `date` >> ./getrep.log
echo "TODAY=${TODAY}" >> ./getrep.log
echo "GET_DT=${GET_DT}" >> ./getrep.log
echo "CSV_PATH=${CSV_PATH}" >> ./getrep.log

if [ -e ${CSV_PATH} ]; then
  rm -f ${CSV_PATH}
fi

sqlplus -s DB名/パスワード@接続文字列 @./getrepdata.sql ${CSV_PATH} ${GET_DT} >> ./getrep.log 1>&2

# UTF→SJIS変換
nkf -Ws ${CSV_PATH} > ${CSV_PATH}_tmp
mv ${CSV_PATH}_tmp ${CSV_PATH}

aws s3 cp ${CSV_PATH} s3://S3出力先/${TODAY}/${CSV_FILE} >> ./getrep.log 2>&1
