' SQLの無駄な改行を除く
Option Explicit

Dim rows, cols
rows = GetSelectLineTo - GetSelectLineFrom
cols = GetSelectColmTo - GetSelectColmFrom

If Not(rows = 0 And cols = 0) Then
  call funk
End If

' DO FUNK
Private Function funk()

	Editor.ReplaceAll "\r\n", "\n", 134
	Editor.ReplaceAll "\n", "", 134
	Editor.GoLineTop
	Editor.GoLineEnd_Sel
	Editor.ReplaceAll " +", " ", 134
	Editor.ReplaceAll "^ +", "", 134
	Editor.ReplaceAll "( ", "(", 130
	Editor.ReplaceAll " )", ")", 130
	Editor.ReplaceAll " ::", "::", 130
	Editor.GoLineTop
	Editor.GoLineTop
	Editor.SearchClearMark
	Editor.ReDraw

End Function
