CREATE OR REPLACE PACKAGE PLSQL_PCKG
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

    CN_program_nm       CONSTANT VARCHAR2(30)  := 'PAC01';
    CN_max_value        CONSTANT NUMBER        := 255;

    N_StartDate         DATE;
    N_T_StartDate       DATE;
    N_OutPut            BOOLEAN := FALSE;

    /***************************************************************************************
     * Function Name : PAC01_MAIN
     * Description   : いろんなことをします
     * @param          I_prog_id                    バッチプログラムID
     * @param          IO_error_message             エラーメッセージ
     * @return         TRUE/FALSE
     ***************************************************************************************/
    FUNCTION PAC01_MAIN(
        I_prog_id           IN      VARCHAR2
      , IO_error_message             IN OUT  VARCHAR2
    )RETURN BOOLEAN;

END PLSQL_PCKG;
/
