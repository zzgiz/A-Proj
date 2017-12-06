-- セッション
select SID, SERIAL#, SQL_EXEC_START, STATUS, LAST_CALL_ET, BLOCKING_SESSION, BLOCKING_SESSION_STATUS, MODULE, OSUSER from v$session where sid='862';  -- sid='956'; -- --module='SQL Developer';

-- テーブル一覧と件数
SELECT TABLE_NAME, NUM_ROWS, LAST_ANALYZED
FROM   USER_TABLES
where 1=1
AND table_name = 'tbl1'
--AND table_name = :TABLE_NAME
--AND table_name like '%search_word%'
ORDER BY TABLE_NAME;

-- select count文作成
SELECT '(select count(*) from ' || table_name || ') as ' || table_name || ','
from user_tables
where table_name in   ('tbl1','tbl2')
;

-- カラム名検索
SELECT DISTINCT
    c.table_name
  , c.column_name
  , c.DATA_TYPE
  , CASE
        WHEN c.DATA_PRECISION IS NOT NULL
        THEN '(' || c.DATA_PRECISION || ',' || c.DATA_SCALE || ')'
        ELSE '(' || TO_CHAR(c.DATA_LENGTH) || ')'
    END AS "LENGTH"
  , i.index_name
FROM
    user_tab_columns c
  , user_ind_columns i
WHERE 1=1
AND c.column_name  like '%search_word%'
AND c.column_name = i.column_name(+)
AND c.table_name  = i.table_name(+)
--AND i.index_name like 'PK_%'      -- PKのみ
--and c.DATA_TYPE = 'DATE'          -- 型
ORDER BY
    c.table_name
  , c.column_name;


-- テーブル定義情報
SELECT
    tbl.TABLE_NAME
  , col.COLUMN_ID
  , col.COLUMN_NAME
  , col.DATA_TYPE
  , CASE
        WHEN col.DATA_PRECISION IS NOT NULL
        THEN '(' || col.DATA_PRECISION || ',' || col.DATA_SCALE || ')'
        ELSE '(' || TO_CHAR(col.DATA_LENGTH) || ')'
    END AS "LENGTH"
  , CASE
        WHEN pk.COLUMN_POSITION IS NOT NULL
        THEN to_char(pk.COLUMN_POSITION)
        ELSE '-'
    END AS "PK"
  , CASE
        WHEN col.NULLABLE = 'Y'
        THEN 'N'
        ELSE 'Y'
    END              AS "NOT NULL"
  , col.DATA_DEFAULT AS "DEFAULT"
FROM
    USER_TABLES tbl
INNER JOIN USER_TAB_COLUMNS col
ON
    tbl.TABLE_NAME = col.TABLE_NAME
LEFT OUTER JOIN
    (
        SELECT
            ind.INDEX_NAME
          , cst.TABLE_NAME
          , ind.COLUMN_NAME
          , ind.COLUMN_POSITION
        FROM
            USER_IND_COLUMNS ind
        INNER JOIN USER_CONSTRAINTS cst
        ON
            cst.CONSTRAINT_NAME = ind.INDEX_NAME
        AND cst.CONSTRAINT_TYPE = 'P'
    ) pk
ON
	pk.TABLE_NAME  = tbl.TABLE_NAME
AND pk.COLUMN_NAME = col.COLUMN_NAME
WHERE
    tbl.TABLE_NAME = :TABLE_NAME
ORDER BY
    tbl.TABLE_NAME
  , col.COLUMN_ID
  , pk.COLUMN_POSITION;


-- パーティション情報
SELECT
    pkc.name
  , pkc.object_type
  , pkc.COLUMN_NAME     AS part_key
  , pkc.COLUMN_POSITION AS part_key_pos
  , skc.COLUMN_NAME     AS sub_key
  , Skc.COLUMN_POSITION AS sub_key_pos
FROM
    USER_PART_KEY_COLUMNS pkc
  , USER_SUBPART_KEY_COLUMNS skc
WHERE 1=1
--AND pkc.NAME in ('PART_KEY_NAME_SAMPLE')
AND pkc.NAME = :TABLE_NAME
AND pkc.NAME = skc.NAME(+)
ORDER BY
    pkc.name
  , part_key_pos
  , sub_key_pos
;

-- パーティションと件数 (ANALIZE_DATE 注意)
select
    TABLE_NAME
  , PARTITION_NAME
  , SUBPARTITION_COUNT
  , PARTITION_POSITION
  , NUM_ROWS
  , LAST_ANALYZED
from USER_TAB_PARTITIONS
where 1=1
AND table_name = :TABLE_NAME
order by table_name, PARTITION_POSITION
;

-- パーティション指定
select * from tbl1 partition(PART_KEY_NAME_SAMPLE);


-- サブパーティション
select
    TABLE_NAME
  , PARTITION_NAME
  , SUBPARTITION_NAME
  , SUBPARTITION_POSITION
  , NUM_ROWS
  , LAST_ANALYZED
from USER_TAB_SUBPARTITIONS
where table_name = :TABLE_NAME
order by b.TABLE_NAME, a.PARTITION_POSITION, b.SUBPARTITION_POSITION;

-- インデックス情報
select
    TABLE_NAME
  , INDEX_NAME
  , COLUMN_NAME
  , COLUMN_POSITION
  , COLUMN_LENGTH
  , CHAR_LENGTH
  , DESCEND
from USER_IND_COLUMNS   
where table_name = :TABLE_NAME
order by table_name, index_name, column_position;

-- テーブル容量
SELECT
    SEGMENT_NAME
  , BYTES
  , BYTES/1024           AS K_BYTES
  , BYTES/1024/1024      AS M_BYTES
  , BYTES/1024/1024/1024 AS G_BYTES
FROM DBA_SEGMENTS
WHERE SEGMENT_NAME = :TABLE_NAME;

-- テーブル容量 - パーティション合計
SELECT
    OWNER
  , SEGMENT_NAME
  , SUM(BYTES/1024/1024/1024)   AS G_BYTES
  , SUM(BYTES/1024/1024)        AS M_BYTES
FROM DBA_SEGMENTS
WHERE 1=1
and SEGMENT_NAME = :TABLE_NAME
--and BYTES > 8388608
GROUP BY
    SEGMENT_NAME
  , OWNER
ORDER BY
    SEGMENT_NAME
  , OWNER
;

-- シーケンステスト
/*
alter sequence SEQ_01 increment by 5;    --表示された値を指定
select SEQ_01.nextval from dual;         --実際に値を変更する
alter sequence SEQ_01 increment by 1;    --増分を元に戻す
select SEQ_01.currval from dual;
*/

-- 再帰呼び出し
with rec(tm) as(
    select 0 as tm from dual
    union all
    select tm+3 from rec where tm+3 <= 60
)
select tm from rec union select 9999 as tm from dual order by tm
;

with rec(sttm, edtm) as(
    select 0 as sttm, 0+3 as edtm from dual
    union all
    select sttm+3, edtm+3 from rec where sttm+3 <= 60
)
select sttm, (case when edtm>60 then 9999 else edtm end) as edtm from rec
;


-- パッケージ確認 日付
select object_name, created, last_ddl_time, status
from USER_OBJECTS
where object_type='PACKAGE BODY'
and object_name like 'PAC_%' 
and last_ddl_time >= '2017-6-1'
order by last_ddl_time desc, object_name;

-- パッケージ確認 ソース
select name, text 
from user_source
where name like 'PAC_%' and type = 'PACKAGE BODY'
and text like '%search_word%'
--and name = 'PAC_01_02'
order by name, line
;

-- パッケージ一覧
SELECT
OBJECT_NAME, OBJECT_TYPE,TO_CHAR(LAST_DDL_TIME,'YYYY/MM/DD HH24:MI:SS') as dt
FROM USER_OBJECTS
WHERE OBJECT_TYPE='PACKAGE' 
order by dt desc;



-- テーブル定義変換 Oralce → Redshift
SELECT
    CASE
        WHEN COLUMN_ID = 1 THEN 'CREATE TABLE schema1.' || LOWER(TABLE_NAME) || ' (' 
        ELSE ','
    END AS MARK1
  , LOWER(COLUMN_NAME) AS column_name
  , CASE
        WHEN DATA_TYPE = 'VARCHAR2' THEN 'varchar'
        WHEN DATA_TYPE = 'NUMBER'   THEN 'numeric'
        WHEN DATA_TYPE = 'DATE'     THEN 'timestamp'
        ELSE DATA_TYPE
    END AS DATA_TYPE
  , CASE
        WHEN DATA_TYPE = 'VARCHAR2' THEN '(' || DATA_LENGTH || ')'
        WHEN DATA_TYPE = 'NUMBER'   THEN '(' || DATA_PRECISION || ',' || DATA_SCALE || ')'
        WHEN DATA_TYPE = 'DATE'     THEN NULL
        ELSE NULL
    END AS LENGTH
  , CASE WHEN NULLABLE = 'Y' THEN NULL ELSE ' NOT NULL' END AS NULL_VAL
  , CASE WHEN COLUMN_ID = max_col THEN ');' ELSE NULL END AS MARK2
FROM (
    -- Oracle定義
    SELECT
        col.COLUMN_ID
      , MAX(col.COLUMN_ID) OVER(PARTITION BY tbl.table_name) AS max_col
      , tbl.TABLE_NAME
      , col.COLUMN_NAME
      , col.DATA_TYPE
      , col.DATA_PRECISION
      , col.DATA_SCALE
      , col.DATA_LENGTH
      , col.NULLABLE
    FROM
        USER_TABLES tbl
--        DBA_TABLES tbl
    INNER JOIN USER_TAB_COLUMNS col
    ON
        tbl.TABLE_NAME = col.TABLE_NAME
    WHERE 1=1
    AND tbl.TABLE_NAME = :TABLE_NAME
    ORDER BY
        col.TABLE_NAME
      , col.COLUMN_ID
)
ORDER BY
    TABLE_NAME
  , COLUMN_ID
;







