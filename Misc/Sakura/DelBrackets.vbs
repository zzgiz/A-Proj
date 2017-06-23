' 対応する括弧を削除
Option Explicit

Dim wkStr
Dim stRow, edRow
Dim stCol, edCol
Dim var

' スタート

Editor.BeginSelect(0)
stRow = Editor.GetSelectLineFrom()
wkStr = Editor.GetLineStr(stRow)
stCol = InStr(wkStr,"(")
Editor.CancelMode(0)
var = Editor.MoveCursor(stRow, stCol, 0)

Editor.BracketPair()

Editor.BeginSelect(0)
edRow = Editor.GetSelectLineFrom()
wkStr = Editor.GetLineStr(edRow)
edCol = InStrRev(wkStr,")")
Editor.CancelMode(0)
var = Editor.MoveCursor(edRow, edCol, 0)

If stRow <> edRow Then
	var = Editor.MoveCursor(edRow, edCol, 0)
	var = DeleteLine(0)
	var = Editor.MoveCursor(stRow, stCol, 0)
	var = DeleteLine(0)
Else
	
End If

