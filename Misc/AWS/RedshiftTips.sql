-- テーブル定義
select
    table_name
  , ordinal_position
  , column_name
  , udt_name
  , case
        when udt_name = 'varchar' then character_maximum_length::text
        when udt_name = 'numeric' then (numeric_precision || ',' || numeric_scale)::text
        else null::text
    end as data_length
  , case when is_nullable='NO' then 'NOT NULL' else '' end as null_able
  , column_default
from information_schema.columns 
where 
    table_catalog   = 'db_name'
and table_schema    = 'schema_name'
and table_name      = 'tbl1'
order by table_name, ordinal_position;

-- View定義取得
select 'CREATE OR REPLACE VIEW ' || schemaname || '.' || viewname || ' AS', definition from pg_views 
where schemaname = 'schema_name'
and viewname     = 'view1'
-- and definition like '%search_word%'
order by viewname;

-- カラム名検索
SELECT *
FROM information_schema.columns
where 1=1
--and table_schema= 'schema_name'
and column_name like 'colum1'
-- and is_nullable = 'NO'
-- and udt_name='date'
order by table_schema, table_name;

-- テーブル名検索
SELECT table_schema, table_name
FROM information_schema.tables
where 1=1
and table_schema = 'schema_name'
--and table_name in ('tbl1')
order by table_schema, table_name;


-- User定義関数取得
SELECT '/* ' || proname || ' */' as name, prosrc
FROM pg_proc 
WHERE proname like 'f_%';

-- テーブル一覧
SELECT DISTINCT table_schema, table_name, table_type
FROM information_schema.tables tab
where table_schema = 'schema_name'
and table_name in ('tbl1','tbl2')
order by table_type, table_name
;


-- ロック確認 1
SELECT *
FROM schema_name.v_check_transaction_locks
ORDER BY system_ts,pid,tablename;

-- ロック確認 2
SELECT l.pid,
       l.granted,
       d.datname,
       relation,
       relation::regclass,
       l.mode
FROM pg_locks l
  LEFT JOIN pg_database d ON l.database = d.oid
WHERE l.pid != pg_backend_pid()
ORDER BY l.pid;


-- 実行中のクエリ確認
select pid,
       trim(user_name),
	   starttime +INTERVAL '9 hours' AS starttime,
       -- SYSDATE-starttime AS elapsed_time,
       trim(query)
from stv_recents
where status='Running';

-- プロセス停止方法
SELECT pg_cancel_backend(30209);

-- 上で消えない場合
SELECT pg_terminate_backend(18725);

-- COPY時のLOAD状況
SELECT recordtime +INTERVAL '9 hours' AS recordtime,
       pid,
       process,
       errcode,
       linenum AS LINE,
       TRIM(error) AS err
FROM stl_error
ORDER BY recordtime DESC LIMIT 20;

-- COPY時のエラー内容確認
SELECT
    userid                        AS userid
  , slice                         AS slice
  , tbl                           AS tbl
  , starttime + interval '9 hour' AS starttime
  , session                       AS session
  , query                         AS query
  , TRIM(filename)                AS filename
  , line_number                   AS line_number
  , TRIM(colname)                 AS colname
  , TYPE                          AS TYPE
  , TRIM(col_length)              AS col_length
  , POSITION                      AS POSITION
  , TRIM(raw_line)                AS raw_line
  , TRIM(raw_field_value)         AS raw_field_value
  , err_code                      AS err_code
  , TRIM(err_reason)              AS err_reason
FROM
    STL_LOAD_ERRORS
WHERE 1=1
AND TRUNC(starttime + interval '9 hour') >= trunc(sysdate + interval '9 hour')
--and raw_field_value like '%ERROR%'
--and filename like '%sample%'
ORDER BY
    starttime DESC
--LIMIT 1
;


-- テーブルコメント取得
SELECT DISTINCT
    utb.schemaname          AS schema
  , utb.relname             AS tbl_name
  , cmt.description         AS tbl_comment
FROM
    pg_stat_user_tables utb
INNER JOIN
    pg_attribute        att
ON
    att.attrelid    = utb.relid
AND att.attnum      > 0
LEFT OUTER JOIN
    pg_description      cmt
ON
    cmt.objsubid    = 0
AND cmt.objoid      = att.attrelid
WHERE
    utb.schemaname  = 'schema_name'
--and cmt.description is null         -- コメントが空のもの
ORDER BY
    tbl_name
;


-- カウント文作成
SELECT '(select count(*) from '  || table_schema || '.' || table_name || ') as ' || table_name || ',' as "select"
from (
    SELECT distinct table_schema, table_name
    FROM information_schema.columns 
    where 1=1
    and table_schema = 'schema_name'
    and table_name = 'tbl1'
    order by table_schema, table_name
);


-- QUERY
select * from STL_QUERY 
where database='db_name'
and querytxt like '%abcdefg%'
order by endtime desc;

-- DDL
select * from STL_DDLTEXT 
where text like '%abcdefg%'
order by endtime desc;


