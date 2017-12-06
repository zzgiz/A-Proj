#!/bin/bash

if [ ${#} -lt 1 ]; then
  echo "  例) analyze compressionの実行"
  echo "    sh ./goana.sh schema1.table1 ..."
  echo ""
  echo "  第1パラメータ: スキーマ.テーブル名 ..."
  exit 0
fi

if [ $# -gt 1 ]; then
  rst_file="ana-result.txt"
else
  rst_file="ana-${1}.txt"
fi

rm -f ${rst_file}

for tbl in "$@"
do
  psql -h XXXXX.redshift.amazonaws.com -U user1 -d db1 -p 1234 -c \
    "analyze compression ${tbl};" > ${rst_file}.tmp
  
  sed 's/|/ /g' ${rst_file}.tmp | sed -E 's/ +/\t/g' | sed -E 's/^\t//' | sed '/^--/d' | sed '/^Table/d' | sed '/^(/d' >> ${rst_file}
  rm ./${rst_file}.tmp
done

echo -e "Analyze Finnished!!!"

