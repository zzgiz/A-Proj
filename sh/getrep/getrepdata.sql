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
ALTER SESSION SET NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS'; 
SPOOL &1

----------------------------------------------------------------------------------
SELECT
'"ITM_1","ITM_2","ITM_3"'
FROM DUAL;

SELECT
'"' ||
a.itm1      || '","' ||
a.itm2      || '","' ||
a.itm3      || '","' ||
FROM
    tbl a
ORDER BY
    itm1
  , itm2
;
----------------------------------------------------------------------------------

SPOOL OFF
QUIT
