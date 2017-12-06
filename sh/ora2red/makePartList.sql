SET ARRAYSIZE 500
SET FLUSH OFF
SET LINESIZE 32767
SET PAGESIZE 0
SET SERVEROUTPUT ON
SET FEEDBACK OFF
SET TERMOUT OFF
SET TRIMSPOOL ON
SET VERIFY OFF
SET HEADING ON
SET UNDERLINE OFF
WHENEVER OSERROR EXIT 2;
WHENEVER SQLERROR EXIT 1;

SPOOL ./csv/&2/&1._part.lst

-- パーティション名/サブパーティション名取得
DECLARE
  vParam      VARCHAR2(10);
  vSql        VARCHAR2(1000);
  vPartname   VARCHAR2(128);
  TYPE cusorType IS REF CURSOR;
  cur         cusorType;
BEGIN
  vParam := '&3';

  IF vParam = 'PART' THEN
    vSql := '
      SELECT
          partition_name AS part_name
      FROM
          user_tab_partitions
      WHERE
          table_name=''&1''
      ORDER BY
          partition_name';
  ELSIF vParam = 'SUBPART' THEN
    vSql := '
      SELECT
          subpartition_name AS part_name
      FROM
          user_tab_subpartitions
      WHERE
          table_name=''&1''
      ORDER BY
          subpartition_name';
  ELSE
    RETURN;
  END IF;

  OPEN cur FOR vSql;
  LOOP
    FETCH cur INTO vPartname;
    EXIT WHEN cur%NOTFOUND;

    DBMS_OUTPUT.PUT_LINE(vPartname);
  END LOOP;
  CLOSE cur;
END;
/

SPOOL OFF
QUIT

