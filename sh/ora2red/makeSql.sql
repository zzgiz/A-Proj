SET ARRAYSIZE 500
SET FLUSH OFF
SET LINESIZE 32767
SET PAGESIZE 0
SET SERVEROUTPUT OFF
SET FEEDBACK OFF
SET TERMOUT OFF
SET TRIMSPOOL ON
SET VERIFY OFF
SET HEADING ON
SET UNDERLINE OFF
SET ESCAPE '\'
WHENEVER OSERROR EXIT 2;
WHENEVER SQLERROR EXIT 1;
ALTER SESSION SET NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS';

SPOOL ./sql/&3

prompt SET ARRAYSIZE 500
prompt SET FLUSH OFF
SELECT
    -- LINESIZE最適値取得
    'SET LINESIZE ' ||
        SUM(
            CASE
                WHEN (base_size + commna_size + date_size + delim_size) > col_name_len
                THEN (base_size + commna_size + date_size + delim_size)
                ELSE col_name_len
            END
        )
FROM (
    SELECT
        column_name
      , NVL(data_precision, data_length)                AS base_size
      , CASE WHEN data_scale>0 THEN 1 ELSE 0 END        AS commna_size  -- 小数点有無
      , CASE WHEN data_type = 'DATE' THEN 13 ELSE 0 END AS date_size    -- DATE型(20桁)
      , 3                                               AS delim_size   -- デリミタ(",")
      , LENGTH(column_name) + 1                         AS col_name_len -- 項目名
    FROM
        user_tab_columns
    WHERE
        table_name = '&1'
);
prompt SET PAGESIZE 0
prompt SET SERVEROUTPUT OFF
prompt SET FEEDBACK OFF
prompt SET TERMOUT OFF
prompt SET TRIMSPOOL ON
prompt SET VERIFY OFF
prompt SET HEADING ON
prompt SET UNDERLINE OFF
prompt WHENEVER OSERROR EXIT 2;;
prompt WHENEVER SQLERROR EXIT 1;;
prompt ALTER SESSION SET NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS';;
prompt spool ./csv/&2/&4

--列名表示
SELECT
  DECODE(COLUMN_ID, '1', 'SELECT ', ' || '','' || '),
  '''' || COLUMN_NAME || ''''
FROM USER_TAB_COLUMNS
WHERE TABLE_NAME = UPPER('&1')
ORDER BY COLUMN_ID;
SELECT 'FROM DUAL;' FROM DUAL;

--データ取得、値はダブルクォーテーションで囲む
SELECT
  DECODE(COLUMN_ID, '1', 'SELECT  /*+ parallel(tbl 6) */', ' || '','' || '),
  '''"'' || ' || 'REPLACE(REPLACE(REPLACE(' || COLUMN_NAME || ', ''"'', ''''), CHR(13), '' ''), CHR(10), '' '')' || ' || ''"'''
FROM USER_TAB_COLUMNS
WHERE TABLE_NAME = UPPER('&1')
ORDER BY COLUMN_ID;

SELECT 'FROM ' || UPPER('&1') FROM DUAL;
SELECT
    CASE
        WHEN '&5'='PART'    THEN 'PARTITION(\&1)'
        WHEN '&5'='SUBPART' THEN 'SUBPARTITION(\&1)'
        ELSE 'WHERE 1=1'
    END
FROM DUAL;
SELECT ';' FROM DUAL;

prompt spool off
prompt quit
SPOOL OFF
QUIT

