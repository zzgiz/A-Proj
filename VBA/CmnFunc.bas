Attribute VB_Name = "CmnFunc"
Option Explicit
Option Private Module

' -----------------------------------------------------------------
' �ŏI�s��擾
' -----------------------------------------------------------------
Public Function GetEndRng(ByRef sh As Worksheet) As Range

    Dim lastRow As Long
    Dim lastCol As Long

    With sh.UsedRange
        lastRow = .Rows(.Rows.Count).row
        lastCol = .Columns(.Columns.Count).Column
    End With
    
    Set GetEndRng = sh.Range(sh.Cells(lastRow, lastCol).Address)

End Function

' -----------------------------------------------------------------
' �u�b�N�̃I�[�v���m�F
' -----------------------------------------------------------------
Public Function IsBookOpen(fileName As String) As Boolean

    Dim bk As Workbook
    
    IsBookOpen = False

    For Each bk In Workbooks
        If bk.name = fileName Then
            IsBookOpen = True
            Exit Function
        End If
    Next bk

End Function

' -----------------------------------------------------------------
' �V�[�g�̑��݊m�F
' -----------------------------------------------------------------
Public Function IsSheetExists(bk As Workbook, name As String, ptnMatch As Boolean, ByRef exstName As String) As Boolean

    Dim sh As Worksheet
    Dim reg As Object

    IsSheetExists = False

    If ptnMatch Then
        Set reg = CreateObject("VBScript.RegExp")
        With reg
            .Pattern = name
            .IgnoreCase = True
            .Global = True
        End With
    End If

    For Each sh In bk.Worksheets
        If ptnMatch Then
            If reg.Test(sh.name) Then
                exstName = sh.name
                IsSheetExists = True
                Exit Function
            End If
        Else
            If sh.name = name Then
                IsSheetExists = True
                Exit Function
            End If
        End If
    Next

End Function

' -----------------------------------------------------------------
' �}�`�̑��݊m�F
' -----------------------------------------------------------------
Public Function IsShapeExists(sh As Worksheet, name As String) As Boolean

    Dim sp As Variant
    
    IsShapeExists = False

    For Each sp In sh.Shapes
        If sp.name = name Then
            IsShapeExists = True
            Exit Function
        End If
    Next

End Function

' -----------------------------------------------------------------
' �l�̌ܓ�
' -----------------------------------------------------------------
Public Function RoundVal(val As Variant, dgt As Integer) As String

    Dim dst As Double

    If IsNumVal(val) Then
        If val > 0 Then
            dst = Int(CDbl(val * (10 ^ dgt) + 0.5)) / (10 ^ dgt)
        Else
            dst = Fix(CDbl(val * (10 ^ dgt) - 0.5)) / (10 ^ dgt)
        End If
    Else
        dst = "0"
    End If

    RoundVal = CStr(dst)

End Function

' -----------------------------------------------------------------
' ���l�`�F�b�N
' -----------------------------------------------------------------
Public Function IsNumVal(ByVal val As Variant) As Boolean
       
    On Error GoTo Err1
    
    Dim dbl As Double
    
    dbl = CDbl(val)
    
    IsNumVal = True
    
    Exit Function

Err1:
    IsNumVal = False

End Function

' -----------------------------------------------------------------
' ������`�F�b�N
' -----------------------------------------------------------------
Public Function IsStrVal(src As Variant) As Boolean
       
    On Error GoTo Err1
    
    Dim tmp As String
    tmp = CStr(src)
    
    IsStrVal = True
    
    Exit Function

Err1:
    IsStrVal = False

End Function

' -----------------------------------------------------------------
' ���t�`�F�b�N
' -----------------------------------------------------------------
Public Function IsDateVal(src As Variant) As Boolean
       
    On Error GoTo Err1
    
    Dim tmp As Variant
    
    tmp = CnvDateVal(src)
    
    If IsDate(tmp) Then
        If DateValue(tmp) > 0 Then
            IsDateVal = True
        End If
    End If
    
    Exit Function

Err1:
    IsDateVal = False

End Function

' -----------------------------------------------------------------
' ���t��L���l�ɕϊ�����
' -----------------------------------------------------------------
Public Function CnvDateVal(src As Variant) As Variant

    On Error GoTo Err1

    Dim rst As Variant
    
    rst = src
    
    If InStr(src, "/") <= 0 And InStr(src, "-") <= 0 Then
        If Len(src) = 8 Then
            rst = Left(src, 4) & "/" & Mid(src, 5, 2) & "/" & Right(src, 2)
        ElseIf Len(src) = 6 Then
            rst = "20" & Left(src, 2) & "/" & Mid(src, 3, 2) & "/" & Right(src, 2)  ' 2000�N��Œ�
        Else
            rst = ""
        End If
    End If
    
    
Err1:
    CnvDateVal = rst

End Function

' -----------------------------------------------------------------
' �]���ȋ󔒂̏���
' -----------------------------------------------------------------
Public Function RmvSP(str As String) As String

    Dim reg As Object
    
    Set reg = CreateObject("VBScript.RegExp")
    With reg
        .Pattern = " +"
        .IgnoreCase = True
        .Global = True
    End With
    
    RmvSP = reg.Replace(str, " ")

End Function

' -----------------------------------------------------------------
' �]���ȉ��s�̏���
' -----------------------------------------------------------------
Public Function RmvCRLF(str As String) As String

    Dim rst As String

    rst = Replace(str, vbLf, " ")
    rst = Replace(rst, vbCr, " ")

    RmvCRLF = rst

End Function

' -----------------------------------------------------------------
' �����񌟍�(���K�\��)
' -----------------------------------------------------------------
Public Function RegFind(src As String, ptn As String) As Boolean

    Dim reg As Object
    
    Set reg = CreateObject("VBScript.RegExp")
    
    With reg
        .Pattern = ptn
        .IgnoreCase = True
        .Global = True
    End With
    
    RegFind = reg.Test(src)

    Set reg = Nothing

End Function

' -----------------------------------------------------------------
' ������u��(���K�\��)
' -----------------------------------------------------------------
Public Function RegReplace(src As String, ptn As String, aft As String) As String

    Dim reg As Object
    
    Set reg = CreateObject("VBScript.RegExp")
    
    With reg
        .Pattern = ptn
        .IgnoreCase = True
        .Global = True
    End With
    
    RegReplace = reg.Replace(src, aft)

    Set reg = Nothing

End Function

' -----------------------------------------------------------------
' �v���O���X�o�[�\��
' -----------------------------------------------------------------
Public Function DispProgress(pos As Long, max As Long, visible As Boolean) As Variant

    Dim i As Long
    Const str = "������ ... "
    
    If visible Then
        If pos <= max And max > 0 Then
            i = RoundVal(pos / max * 10, 0)
        Else
            i = 0
        End If
        
        Application.StatusBar = str & String(i, "��") & String(10 - i, "��")
        DoEvents
    Else
        Application.StatusBar = False
        DoEvents
    End If

End Function

' -----------------------------------------------------------------
' �t�H���_�I���_�C�A���O
' -----------------------------------------------------------------
Public Function GetFolderName(caption As String, initPath As String) As Variant

    Dim rst As Long

    With Application.FileDialog(msoFileDialogFolderPicker)
        .title = caption
        .InitialFileName = initPath
        rst = .Show
        If rst <> 0 Then
            GetFolderName = Trim(.SelectedItems.Item(1))
        Else
            GetFolderName = ""
        End If
    End With
    
End Function

' -----------------------------------------------------------------
' �t�@�C���I���_�C�A���O
' -----------------------------------------------------------------
Public Function GetFileNeme(title As String) As String

    Dim fname As Variant
    Dim fso As Object
    Dim path As String
    
    fname = Application.GetOpenFilename("Microsoft Excel Book,*.xls?", , title, , False)
    If fname = "False" Then
        Exit Function
    End If
    
    GetFileNeme = fname

    Set fso = CreateObject("Scripting.FileSystemObject")

    path = fso.GetParentFolderName(fname)
    If Mid(path, 2, 1) = ":" Then ChDrive Left(path, 1)
    ChDir path

    Set fso = Nothing

End Function

' -----------------------------------------------------------------
' ���샍�O�o��(�O���t�@�C��)
' -----------------------------------------------------------------
Public Function OutLog(fname As String, msg As String)

    Dim fd As Long
    Dim logfile As String

    On Error GoTo Err_1

    logfile = ActiveWorkbook.path & "\" & fname

    fd = FreeFile()

    Open logfile For Append As fd
    Print #fd, Format(Now(), "yyyy/mm/dd hh:mm:ss") & vbTab & msg
    Close #fd

    Exit Function

Err_1:

End Function

' -----------------------------------------------------------------
' ���샍�O�o��(�O���t�@�C�� ���ԏo�͖���)
' -----------------------------------------------------------------
Public Function OutLogNT(fname As String, msg As String)

    Dim fd As Long
    Dim logfile As String

    On Error GoTo Err_1

    logfile = ActiveWorkbook.path & "\" & fname

    fd = FreeFile()

    Open logfile For Append As fd
    Print #fd, msg
    Close #fd

    Exit Function

Err_1:

End Function

' -----------------------------------------------------------------
' ���샍�O�o��
' -----------------------------------------------------------------
Public Function SetProcessLog(sh As Worksheet, adr As String, msg As String)

    Dim i As Long
    Const maxRow = 10000    ' �b��ő�s
    
    If sh Is Nothing Then
        MsgBox "���O�o�̓G���[", vbCritical, "�G���["
        Exit Function
    End If
    
    i = sh.Range(sh.Cells(maxRow, sh.Range(adr).Column), sh.Cells(maxRow, sh.Range(adr).Column)).End(xlUp).row + 1
    If i < sh.Range(adr).row Then i = sh.Range(adr).row

    If msg = "" Then    ' ���O�N���A
        If i >= sh.Range(adr).row Then
            sh.Range(sh.Cells(sh.Range(adr).row, sh.Range(adr).Column), sh.Cells(i, sh.Range(adr).Column + 1)).ClearContents
        End If
      
        Exit Function
    End If
    
    sh.Cells(i, sh.Range(adr).Column).NumberFormatLocal = "yyyy/mm/dd hh:mm:ss"
    sh.Cells(i, sh.Range(adr).Column) = Now
    sh.Cells(i, sh.Range(adr).Column + 1) = msg
    
End Function

' -----------------------------------------------------------------
' �摜�t�@�C���ۑ�
' -----------------------------------------------------------------
Public Sub SavePics()

    Dim tgtSh As Worksheet
    Dim tmpBk As Workbook
    Dim tmpSh As Worksheet
    Dim sp As Shape
    Dim tmpCht As Variant
    Dim curPath As String
    Dim outPath As String
    Dim fname As String
    Dim fso As Object
    
    Const IMG_DIR As String = "images_crop"     ' �o�̓t�H���_��
    
    Application.ScreenUpdating = False
    
    Set tgtSh = ActiveWorkbook.ActiveSheet
    Set tmpBk = Workbooks.Add
    Set tmpSh = tmpBk.Worksheets(1)
    
    curPath = tgtSh.Parent.path
    outPath = curPath & "\" & IMG_DIR & "\"
    
    Set fso = CreateObject("Scripting.FileSystemObject")
    
    If fso.FolderExists(outPath) = False Then
        fso.createFolder outPath
    End If
    
    For Each sp In tgtSh.Shapes
        If sp.Type <> 13 Or sp.TopLeftCell.Column <= 1 Then
           GoTo NEXT_SHAPE
        End If

        ' �t�@�C�����擾
        fname = Trim(tgtSh.Cells(sp.TopLeftCell.row, sp.TopLeftCell.Column - 1).Value)
        If fname = "" Then
            GoTo NEXT_SHAPE
        End If
        
        ' Drop�����O
        If tgtSh.Cells(sp.TopLeftCell.row + 2, sp.TopLeftCell.Column - 1).Value = "Drop" Then
            GoTo NEXT_SHAPE
        End If

        ' �I�u�W�F�N�g�Ɠ��T�C�Y�̋�̃O���t���ꎞ�I�ɍ��
        Set tmpCht = tmpSh.ChartObjects.Add(0, 0, sp.Width, sp.Height).Chart

        ' �O���t�ɉ摜���y�[�X�g����
        sp.CopyPicture
        tmpCht.Paste

        ' �O���t�̃G�N�X�|�[�g�B�^�C�v��JPG�i�����������png���ł�������j
        tmpCht.Export fileName:=outPath & fname & ".jpg", filtername:="JPG"

        '�O���t���폜����
        tmpCht.Parent.Delete
        Set tmpCht = Nothing

NEXT_SHAPE:
    Next

    Application.DisplayAlerts = False
    tmpBk.Close saveChanges:=False
    Application.DisplayAlerts = True

    Set fso = Nothing
    Set tgtSh = Nothing

    Application.ScreenUpdating = True

End Sub

' -----------------------------------------------------------------
' �g���̏��������Z�b�g
' -----------------------------------------------------------------
Public Sub �g��()

    Dim sh As Worksheet
    Dim rng As Range
    Dim cnt As Long
    Dim row As Long
    Dim col As Long
    Dim idx As Long
    
    Set sh = ActiveWorkbook.ActiveSheet

    Set rng = Selection
    
    rng.FormatConditions.Delete
    
'    cnt = rng.Columns.Count - 2
    cnt = 3     ' ���[�v���Ƃ肠�����Œ�
    
    
    For col = rng.Column To rng.Column + cnt - 1
    
        rng.FormatConditions.Add Type:=xlExpression, Formula1:="=" & CnvAdr(rng.row, col) & "<>" & CnvAdr(rng.row + 1, col)
    
        idx = rng.FormatConditions.Count
    
        With rng.FormatConditions(idx).Borders(xlBottom)
            .LineStyle = xlContinuous
            .TintAndShade = 0
            .Weight = xlThin
        End With
        
        rng.FormatConditions(idx).StopIfTrue = False
        
        Set rng = sh.Range(sh.Cells(rng.row, col + 1), sh.Cells(rng.row + rng.Rows.Count - 1, rng.Column + rng.Columns.Count - 1))
    
    Next
    
    
    Set rng = Nothing
    Set sh = Nothing

End Sub

' -----------------------------------------------------------------
' �A�h���X�ϊ�
' -----------------------------------------------------------------
Private Function CnvAdr(row As Long, col As Long) As String

    Dim tmp As String

    ' �A�h���X�ϊ�  R1C1 �� A1
    tmp = Application.ConvertFormula("R" & row & "C" & col, FromReferenceStyle:=xlR1C1, ToReferenceStyle:=xlA1)
    
    ' $��񂾂��ɂ���
    tmp = Replace(tmp, "$", "")
    tmp = "$" & tmp
    
    CnvAdr = tmp

End Function

' -----------------------------------------------------------------
' �Ώ۔͈͂���w�荀�ڂ��������s�ʒu��Ԃ�
' -----------------------------------------------------------------
Public Function FindRow(ByRef rng As Range, key As Variant) As Long

    Dim row As Long

    FindRow = 0
    
    On Error GoTo Err1

    row = Application.WorksheetFunction.Match(CStr(key), rng, 0)
    
    FindRow = row
    
Err1:
    ' �G���[ = �������ʂȂ�
    
End Function

' -----------------------------------------------------------------
' UTF8�����o�� TAB��؂�
' -----------------------------------------------------------------
Public Sub Outf8(sh As Worksheet, outfile As String)

    ' StreamTypeEnum
    Const adTypeBinary = 1
    Const adTypeText = 2
    
    ' LineSeparatorsEnum
    Const adCR = 13
    Const adCRLF = -1
    Const adLF = 10
    
    ' StreamWriteEnum
    Const adWriteChar = 0
    Const adWriteLine = 1
    
    ' SaveOptionsEnum
    Const adSaveCreateNotExist = 1
    Const adSaveCreateOverWrite = 2
    
    
    Dim fname As String
    Dim lastRow As Long
    Dim lastCol As Long
    Dim line As String
    Dim fso As Object
    Dim strm As Object
    Dim r As Long
    Dim c As Long
    
    Const START_ROW As Long = 1
    Const START_COL As Long = 1
    
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set strm = CreateObject("ADODB.Stream")
    
    With sh.UsedRange
        lastRow = .Rows(.Rows.Count).row
        lastCol = .Columns(.Columns.Count).Column
    End With
    
    ' �o�̓t�@�C���Z�b�g
    fname = sh.Parent.path & "\" & outfile
    
    If fso.FileExists(fname) Then
        fso.DeleteFile fname
    End If
    
    With strm
        .Charset = "UTF-8"
        .LineSeparator = adLF
        .Open
    End With
    
    For r = START_ROW To lastRow
        
        line = ""
        
        For c = START_COL To lastCol
            line = line & RmvCRLF(sh.Cells(r, c).Value)
            If c < lastCol Then line = line & vbTab
        Next
        
        strm.WriteText line, adWriteLine
    
Next_Line:
    Next

    ' BOM���� & �ۑ�
    With strm
        .Position = 0           ' �X�g���[���̈ʒu��0�ɂ���
        .Type = adTypeBinary    ' �f�[�^�̎�ނ��o�C�i���f�[�^�ɕύX
        .Position = 3           ' �X�g���[���̈ʒu��3�ɂ���
    
        Dim byteData() As Byte  ' �ꎞ�i�[�p
        byteData = .Read        ' �X�g���[���̓��e���ꎞ�i�[�p�ϐ��ɕۑ�
        .Close                  ' ��U�X�g���[�������i���Z�b�g�j
    
        .Open                   ' �X�g���[�����J��
        .Write byteData         ' �X�g���[���Ɉꎞ�i�[�����f�[�^�𗬂�����
        
        .SaveToFile fname, adSaveCreateOverWrite
        .Close
    End With
   
    MsgBox "�f�[�^�����o���I��"

End Sub

' -----------------------------------------------------------------
' Set fso = CreateObject("Scripting.FileSystemObject")
' -----------------------------------------------------------------
' �v���p�e�B
' Drives                �V�X�e���ɐڑ����ꂽDrives�R���N�V������Ԃ��܂�
' ���\�b�h
' BuildPath             �p�X�̖����ɁA�w�肵���t�H���_����ǉ������p�X��Ԃ��܂�
' CopyFile              �t�@�C�����R�s�[���܂�
' CopyFolder            �t�H���_���R�s�[���܂�
' CreateFolder          �V�����t�H���_���쐬���܂�
' CreateTextFile        �V�����e�L�X�g�t�@�C�����쐬���܂�
' DeleteFile            �t�@�C�����폜���܂�
' DeleteFolder          �t�H���_���폜���܂�
' DriveExists           �h���C�u�����݂��邩�ǂ������ׂ܂�
' FileExists            �t�@�C�������݂��邩�ǂ������ׂ܂�
' FolderExists          �t�H���_�����݂��邩�ǂ������ׂ܂�
' GetAbsolutePathName   �ȗ������p�X���犮�S�ȃp�X����Ԃ��܂�
' GetBaseName           �g���q���������t�@�C���̃x�[�X����Ԃ��܂�
' GetDrive              �w�肵��Drive�I�u�W�F�N�g��Ԃ��܂�
' GetDriveName          �w�肵���h���C�u�̖��O��Ԃ��܂�
' GetExtensionName      �t�@�C���̊g���q��Ԃ��܂�
' GetFile               �w�肵��File�I�u�W�F�N�g��Ԃ��܂�
' GetFileName           �w�肵���t�@�C���̖��O��Ԃ��܂�
' GetFolder             �w�肵��Folder�I�u�W�F�N�g��Ԃ��܂�
' GetParentFolderName   �w�肵���t�H���_�̐e�t�H���_��Ԃ��܂�
' GetSpecialFolder      �V�X�e�����g�p������ʂȃt�H���_�̃p�X��Ԃ��܂�
' GetTempName           �ꎞ�I�ȃt�@�C�����𐶐����܂�
' MoveFile              �t�@�C�����ړ����܂�
' MoveFolder            �t�H���_���ړ����܂�
' OpenTextFile          �w�肵��TextStream�I�u�W�F�N�g��Ԃ��܂�

' -----------------------------------------------------------------
' ������
' -----------------------------------------------------------------
Private Function Initial() As Variant

    Application.Calculation = xlCalculationAutomatic
    Application.ScreenUpdating = True
    Application.Cursor = xlDefault

End Function

' -----------------------------------------------------------------
' �e�X�g
' -----------------------------------------------------------------
Private Function test1() As Variant




End Function

