create or replace PACKAGE BODY PLSQL_PCKG
AS
/*****************************************************************************************
*  A Project
*  Package Name    : PLSQL_PCKG
*  Description     : いろんなことをします
*  Function Id     : PC01
*  Version         : 1.0
*
*  Program List
*  -------------------------- ---- -------- ----------------------------------------------
*  Name                       Type Return      Description
*  -------------------------- ---- -------- ----------------------------------------------
*  PLSQL_PCKG                 F    BOOLEAN  いろんなことをします
*
*  Change Record
*  --------------- ---- ------------ -----------------------------------------------------
*  Date            Ver. Editor       Description
*  --------------- ---- ------------ -----------------------------------------------------
*  2017/01/01      1.0  Myname       New Create
*****************************************************************************************/

    /***************************************************************************************
     * Procedure Name : DBG_OUT_START
     * Description    : デバッグ用出力(開始)
     ***************************************************************************************/
    PROCEDURE DBG_OUT_START(
        I_Flag                       IN      VARCHAR2 := NULL
    )
    IS
    BEGIN
        IF I_Flag = 'Total' THEN
            N_T_StartDate := SYSDATE;
        ELSE
            N_StartDate := SYSDATE;
        END IF;
    END DBG_OUT_START;

    /***************************************************************************************
     * Procedure Name : DBG_OUT_END
     * Description    : デバッグ用出力(終了)
     * @param          I_Type                        処理タイプ
     * @param          I_TableName                   対象テーブル
     ***************************************************************************************/
    PROCEDURE DBG_OUT_END(
        I_Type                       IN      VARCHAR2
      , I_TableName                  IN      VARCHAR2
      , I_Flag                       IN      VARCHAR2 := NULL
    )
    IS
    BEGIN
        IF N_OutPut THEN
            IF I_Flag = 'Total' THEN
                DBMS_OUTPUT.PUT_LINE(
                    '  ' ||
                    '[' ||
                    TO_CHAR(TRUNC(MOD((SYSDATE - N_T_StartDate) * 24 * 60, 60)), 'FM00') ||
                    ':' ||
                    TO_CHAR(TRUNC(MOD((SYSDATE - N_T_StartDate) * 24 * 60 * 60, 60)), 'FM00') ||
                    '] Total'
                );
            ELSE
                DBMS_OUTPUT.PUT_LINE(
                    '  ' ||
                    '[' ||
                    TO_CHAR(TRUNC(MOD((SYSDATE - N_StartDate) * 24 * 60, 60)), 'FM00') ||
                    ':' ||
                    TO_CHAR(TRUNC(MOD((SYSDATE - N_StartDate) * 24 * 60 * 60, 60)), 'FM00') ||
                    '] ' ||
                    RPAD(I_Type, 6, ' ') ||
                    ' : ' ||
                    I_TableName
                );
            END IF;
        END IF;
    END DBG_OUT_END;

    /***************************************************************************************
     * Procedure Name : DBG_OUT_LINE
     * Description    : デバッグ用出力
     * @param          I_Type                        処理タイプ
     * @param          I_TableName                   対象テーブル
     ***************************************************************************************/
    PROCEDURE DBG_OUT_LINE(
        I_Message                    IN      VARCHAR2
    )
    IS
    BEGIN
        IF N_OutPut THEN
            DBMS_OUTPUT.PUT_LINE(I_Message);
        END IF;
    END DBG_OUT_LINE;

    /***************************************************************************************
     * Function Name : PAC01_MAIN
     * Description   : いろんなことをします
     * @param          I_prog_id            バッチプログラムID
     * @param          IO_error_message              エラーメッセージ
     * @return         TRUE/FALSE
     ***************************************************************************************/
    FUNCTION PAC01_MAIN(
        I_prog_id                   IN      VARCHAR2
      , IO_error_message            IN OUT  VARCHAR2
    )RETURN BOOLEAN
    IS
        L_return        BOOLEAN       := FALSE;                                     --ファンクション実行の成功(TRUE)・失敗(FALSE)を保持
        L_function      VARCHAR2(100) := CN_program_id || '.' || 'PAC01_MAIN';      --ファンクション名称
        L_curr_wk       NUMBER;
        L_curr_date     calender_m.cal_date%TYPE;
        L_cnt       NUMBER;
    BEGIN

DBG_OUT_START;
        --==============================================================
        -- ローカル変数に代入
        --==============================================================
        SELECT
            cal.wk
          , plm.oprtn_date
        INTO
            L_curr_wk
          , L_curr_date
        FROM
            pck_list_m  plm
          , calender_m  cal
        WHERE
            plm.pck_id          = I_prog_id
        AND cal.cal_date        = plm.oprtn_date
        ;
DBG_OUT_END(CN_select, 'proc_1');


        --==============================================================
        -- ループする
        --==============================================================
        L_cnt := 0;

        LOOP

            -- 処理 insert/select/update --

            -- 処理件数なしなら抜ける
            IF (SQL%ROWCOUNT = 0) THEN
                EXIT;
            END IF;

            -- カウンタアップ
            L_cnt := L_cnt + 1;

        END LOOP;


        --==============================================================
        -- MERGE
        --==============================================================
        MERGE INTO MRG_TBL_A tgt
        USING (
            -- 必要データを取得
            SELECT
                stb.pgm_id
              , stb.pgm_date
              , stb.sales_value
              , stb.sales_date
            FROM
                sales_table stb
            WHERE
                stb.sales_date  = trunc(sysdate)
        ) src
        ON (
                tgt.pgm_id   = src.pgm_id
            AND tgt.pgm_date = src.pgm_date
        )
        WHEN MATCHED THEN
            UPDATE SET
                tgt.sales_value    = src.sales_value
              , tgt.sales_date     = src.sales_date
        ;


        -- 関数 正常終了
        RETURN TRUE;

    -- 例外処理
    EXCEPTION
        WHEN OTHERS THEN
            --=================================
            -- エラーメッセージの設定
            --=================================
            IO_error_message := SUBSTR(
                                    SQLERRM || ', ' || SQLCODE      -- SQLエラーメッセージ, SQLコード
                                  , 1
                                  , 255
                                );
            RETURN FALSE;

    -- 関数終わり
    END PAC01_MAIN;




END PLSQL_PCKG;
/