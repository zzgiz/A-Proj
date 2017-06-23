#!/bin/bash
# 圧縮&転送

if [ ${#} -lt 1 ]; then
  echo "    sh ./ziptos3.sh TABLE_NAME" 1>&2
  exit 1
fi

TBL=${1}

# 圧縮
if [ -e ./${TBL}.csv.gz ]; then
  rm ./${TBL}.csv.gz
fi
gzip ./${TBL}.csv

# S3に転送
TODAY=`date -u -d '9 hours' +%Y%m%d`
aws s3 cp ./${TBL}.csv.gz s3://S3パス/${TODAY}/${TBL}.csv.gz

