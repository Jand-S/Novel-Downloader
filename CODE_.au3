#include <INet.au3>
#include <Array.au3>
#include <MsgBoxConstants.au3>
#include <String.au3>
#include <GUIConstantsEx.au3>
#include <GDIPlus.au3>
#include <FileConstants.au3>
#include <WinAPIFiles.au3>
#include <File.au3>
#include "Include\class\wkhtmltox.au3"

Func _DownNovel ()
   $header = 1
   $iProgress = 0
   ;Procura Item no ListView
   $finditem = ControlListView ( "", "", $listview_status, "FindItem", $titleglobal)
   ;Se não achar um item(Novel) ele cria um novo item
   If $finditem = -1 Then
	  _GUICtrlListView_AddItem($listview_status, $titleglobal)
   EndIf
   ;Checa onde se encontra o id da novel no listview
   $finditem_2 = ControlListView ( "", "", $listview_status, "FindItem", $titleglobal)
   _GUICtrlListView_AddSubItem($listview_status, $finditem_2, "Downloading...", 2, 2)
   _GUICtrlListView_AddSubItem($listview_status, $finditem_2, "Progress: ", 3, 3)
   $hProgress  = _ListView_InsertProgressBar($listview_status, $finditem_2,3)
   Local $aSelcted, $aDdata
   $aSelcted = _GUICtrlListView_GetSelectedIndices($listview_chap, True)
   If $aSelcted[0] > 0 Then
	  $progress_set = 100/$aSelcted[0] ;Divide 100 pelo tanto de Cap
	  $numberset = Number ($progress_set) ;Convert number
	  Dim $aDdata[$aSelcted[0] + 1]
	  $aDdata[0] = $aSelcted[0]
	  For $i = 1 To $aSelcted[0]
		 $aDdata[$i] = _GUICtrlListView_GetItemTextString($listview_chap, $aSelcted[$i])
		 $inilink = IniRead (@ScriptDir & "\Configs\iniw.ini", $titleglobal, $aDdata[$i], -1 )
		 ;MsgBox ("","",$aDdata[$i])
		 $folder = IniRead (@ScriptDir & "\Configs\Configs.ini", "config_menu", "folder", @ScriptDir & "\Downloads")
		 $initxt = IniRead (@ScriptDir & "\Configs\Configs.ini", "config_menu", "txtbox", "False")
		 $inihtml = IniRead (@ScriptDir & "\Configs\Configs.ini", "config_menu", "htmlbox", "False")
		 $inipdf = IniRead (@ScriptDir & "\Configs\Configs.ini", "config_menu", "pdfbox", "False")

		 $ITEMID = ControlListView ( "", "", $listview_chap, "FindItem", $aDdata[$i])
		 _GUICtrlListView_AddSubItem($listview_status, $finditem_2, $aDdata[$i], 1, 1)
		 _Progress_SetPos($hProgress, $iProgress + $numberset)
		 $iProgress = $iProgress + $numberset
		 If $initxt = "True" Then
			_TextGET ($inilink, $titleglobal, $folder)
		 EndIf
		 If $inihtml = "True" Then
			_HTMLGET ($inilink, $titleglobal, $folder)
		 EndIf
		 If $inipdf = "True" Then
			$inihtml = IniRead (@ScriptDir & "\Configs\Configs.ini", "config_menu", "htmlbox", "False")
			If $inihtml = "True" Then
			Else
			   _PDFGET ($inilink, $titleglobal, $folder, $header)
			   $header = $header + 1
			EndIf
		 EndIf
	  Next
	  Sleep (250)
	  If $inipdf = "True" Then
		 $inihtml = IniRead (@ScriptDir & "\Configs\Configs.ini", "config_menu", "htmlbox", "False")
		 _GUICtrlListView_AddSubItem($listview_status, $finditem_2, "Converting...", 2, 2)
		 Switch $inihtml
		 Case "False"
			Local $oObject = WKHtmlToX()
			$oObject.Input = @ScriptDir & "\Configs\" & $titleglobal & "(PDF).html"
			$oObject.Output = $folder & "\" & $titleglobal & "\" & $titleglobal&".pdf"
			$oObject.Convert()
			FileDelete (@ScriptDir & "\Configs\" & $titleglobal & "(PDF).html")
			;ShellExecute($folder & "\" & $titleglobal & "\" & $titleglobal&".pdf")
		 Case "True"
			Local $oObject = WKHtmlToX()
			$oObject.Input = $folder & "\" & $titleglobal & "\" & $titleglobal & ".html"
			$oObject.Output = $folder & "\" & $titleglobal & "\" & $titleglobal&".pdf"
			$oObject.Convert()
			;ShellExecute($folder & "\" & $titleglobal & "\" & $titleglobal&".pdf")
		 EndSwitch
	  EndIf
	  FileDelete (@ScriptDir & "\Configs\" & $titleglobal & ".html")
	  _Progress_SetPos($hProgress, 100)
	  _GUICtrlListView_AddSubItem($listview_status, $finditem_2, "Completed!", 2, 2)
   EndIf
EndFunc

Func Get_Title ()
   $link = GUICtrlRead ($input_link)
   $checknovellink = StringInStr ($link, "https://novelmania.com.br/")
   If $checknovellink = 0 Then
	  GUICtrlSetData($label_status, "Link não valido")
	  Return 0
   EndIf
   $HTMLSource = _INetGetSource($link)
   If @error Then
	  GUICtrlSetData($label_status, "Link não valido")
	  Return
   EndIf
   $string = BinaryToString ( $HTMLSource , 4)
   $title = _StringBetween ( $string, '<title>', ' •')
   Local $sOutput = StringRegExpReplace($title[0], "[1234567890;#―:]", "")
   $strc = StringRegExpReplace($sOutput, "Novel", "")
   Local $fileout = StringStripWS ($strc, 1)
   $strs = StringLen ($strc)
   If $strs > 40 then
	  _fontcolor ($novel_tittle, 9, 0xFFFFFF, 1)
   Else
	  _fontcolor ($novel_tittle, 14, 0xFFFFFF, 1)
   EndIf
   Global $titleglobal = $fileout
   GUICtrlSetData($novel_tittle, $strc)
   Return
EndFunc

Func _GetPic ()
   Local $img_link = _GetLinkImage ()
   If $img_link = False Then
	  Return False
   EndIf
   _GDIPlus_Startup()
   Local Const $STM_SETIMAGE = 0x0172
   Local Const $hBmp = _GDIPlus_BitmapCreateFromMemory(InetRead($img_link), True) ;to load an image from the net
   Local Const $hBitmap = _GDIPlus_BitmapCreateFromHBITMAP($hBmp)
   Local Const $iWidth = _GDIPlus_ImageGetWidth($hBitmap)
   Local Const $iHeight = _GDIPlus_ImageGetHeight($hBitmap)
   $hBitmap_resized = _GDIPlus_ImageResize($hBitmap, 214, 303) ;GDI+ bitmap
   $hHBitmap2 = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hBitmap_resized) ;GDI bitmap
   $clean = GUICtrlSetImage ($novel_pic, "")
   $teste = _WinAPI_DeleteObject(GUICtrlSendMsg($novel_pic, $STM_SETIMAGE, $IMAGE_BITMAP, $hHBitmap2))
   Return
EndFunc

Func _GetLinkImage ()
   $link = GUICtrlRead ($input_link)
   $HTMLSource = _INetGetSource($link)
   $string = BinaryToString ( $HTMLSource , 4)
   $pic_1 = _StringBetween ( $string, '<img loading=', '/>') ;//Np
   If @error Then
	  Return False
   Else
	  $pic = _StringBetween ( $pic_1[0], 'src="', '"')
	  Return $pic[0]
   EndIf
EndFunc

Func _ext_url ()
   $ListCheckRepeat = 2
   ;ConsoleWrite ("exturl" & @crlf)
   $link = GUICtrlRead ($input_link)
   $checknovellink = StringInStr ($link, "https://novelmania.com.br/")
   If $checknovellink = 0 Then
	  Return 0
   EndIf
   $decodetxt = _part_txt ($link)
   $check_file= FileExists (@ScriptDir & "\source.txt")
   If $check_file <> 1 Then
	  $link = GUICtrlRead ($input_link) ;"http://novelmania.com.br/coreana/arena-indice/" ;GUICtrlRead ($input_link)
	  $decodetxt = _part_txt ($link)
	  $HTMLSource = _INetGetSource($link)
	  $string_decode = BinaryToString ($HTMLSource, 4)
	  FileWrite (@ScriptDir & "\Configs\source.txt", $string_decode);$FILESPACE)
   EndIf
   $file = @ScriptDir & "\Configs\source.txt"
   Local $n = 1
   Local $vol = 2
   $fl = _FileCountLines ( $file )
   Do
	  $check_line =  FileReadLine (@ScriptDir & "\Configs\source.txt", $n)

	  $STRBC = _StringBetween ($check_line, "<strong>", ':')
	  If @error Then
		 $STRBC = _StringBetween ($check_line, "<strong>", '</strong>')
		 If @error Then
		 Else
			$listviewvalue = _AddListView($STRBC[0])
			FileWrite (@ScriptDir & "\Configs\key.txt",$listviewvalue& @CRLF)
		 EndIf
	  Else
		 $listviewvalue = _AddListView($STRBC[0])
		 FileWrite (@ScriptDir & "\Configs\key.txt",$listviewvalue& @CRLF)
	  EndIf

	  $STRB = _StringBetween ($check_line, $decodetxt[4], '">')
	  If @error Then
		 $n = $n + 1
	  Else
		 $seachstr = _Str_In_Str ($STRB[0], "capitulo")
		 If $seachstr = True Then
			$seachstr2 = _Str_In_Str ($STRB[0], $decodetxt[5])
			If $seachstr2 = True Then
			   $seachstr3 = _Str_In_Str ($check_line, "class=")
			   If $seachstr3 = False Then
				  ;ConsoleWrite ("https://"&$decodetxt[3]&"/"&$decodetxt[4]&$STRB[0] & @CRLF)
				  FileWrite (@ScriptDir & "\Configs\value.txt", "https://"&$decodetxt[3]&"/"&$decodetxt[4]&$STRB[0] & @CRLF)
				  $n = $n  + 1
			   Else
				  $n = $n + 1
			   EndIf
			Else
			   $n = $n + 1
			EndIf
		 Else
			$n = $n + 1
		 EndIf
	  ;Else
		 $n = $n + 1
	  EndIf
   Until $n = $fl
   ;ConsoleWrite ("2 Parte" & @CRLF)
   $file = @ScriptDir & "\Configs\key.txt"
   Local $n = 0
   $fl = _FileCountLines ( $file )
   If @error Then
	  GUICtrlSetData($label_status, "Erro")
	  Return
   EndIf
   $fl2 = $fl - 1
   Do
	  $n = $n + 1
	  $key_line =  FileReadLine (@ScriptDir & "\Configs\key.txt", $n)
	  $value_line =  FileReadLine (@ScriptDir & "\Configs\value.txt", $n)
	  IniWrite (@ScriptDir & "\Configs\iniw.ini", $titleglobal, $key_line, $value_line)
   Until $n = $fl
   $chapters = _GUICtrlListView_GetItemCount ( $listview_chap )
   ;GUICtrlCreateListViewItem("|",$listview_chap)
   GUICtrlSetData($label_status, "Mostrando "&$chapters& " capítulos")
EndFunc

Func _OpenButton ()
   FileDelete (@ScriptDir & "\Configs\key.txt")
   FileDelete (@ScriptDir & "\Configs\source.txt")
   FileDelete (@ScriptDir & "\Configs\source-links.txt")
   FileDelete (@ScriptDir & "\Configs\value.txt")
   IniDelete (@ScriptDir & "\Configs\iniw.ini", $novel_tittle)
   _GUICtrlListView_DeleteAllItems ($listview_chap)
   GUICtrlSetData($label_status, "Downloading...")
   Get_Title ()
   _GetPic ()
   _ext_url ()
   _ArrayClear ()
EndFunc

;Check DIR, If dir = 0 Create dir
Func _DirFileCheck ($dir)
   $checkfileexist = FileExists ($dir)
   If $checkfileexist = 0 Then
	  DirCreate ($dir)
	  Return
   EndIf
   Return
EndFunc

;Check Input Link Novel Manager
func Check_Input ()
   If GUICtrlRead($input_link) = ""  And $button_enabled = 1 Then
	  GUICtrlSetState($open_button, $GUI_DISABLE)
	  $button_enabled = 0
   Return
   ElseIf $button_enabled = 0 And GUICtrlRead($input_link) <> "" Then
	  GUICtrlSetState($open_button, $GUI_ENABLE)
	  $button_enabled = 1
   Return
   EndIf
EndFunc

Func _MY_NCHITTEST($hWnd, $uMsg, $wParam, $lParam)
    ; If it is our GUI
   If $hWnd = $n_manager Then
        ; Check if mouse is over the GUI
	  Local $aPos = WinGetPos($hWnd)
	  If Abs(BitAND(BitShift($lParam, 16), 0xFFFF) - $aPos[1]) < 500 Then
            ; Fool Windows into thinking it is the title bar so it drags the GUI
		 Return $HTCAPTION
	  EndIf
   EndIf
   Return $GUI_RUNDEFMSG
EndFunc   ;==>_MY_NCHITTEST

Func WM_SYSCOMMAND($hWnd, $Msg, $wParam, $lParam)
   ; If it is our GUI and we are trying to resize it
   If $hWnd = $n_manager And $wParam = 0xF000 Then ; $SC_SIZE
   ; Do not let it happen
   Return 0
   EndIf
EndFunc

Func _part_txt ($str)
   $strsplit = StringSplit ($str, "/")
   If @error Then
	  Return @error
   EndIf
   Return $strsplit
EndFunc

Func _fontcolor ($hwd, $size = "8", $color = "0x000000", $bold = "0")
   If $bold = 0 Then
	  $bold = 400
   ElseIf $bold = 1 Then
	  $bold = 800
   EndIf
   GUICtrlSetColor($hwd, $color)
   GUICtrlSetFont($hwd, $size, $bold, 0, "Arial")
   Return
EndFunc

Func _TextGET ($value, $name, $directory)
   _DirFileCheck ($directory & "\" & $name)
   Global $oMyError = ObjEvent("AutoIt.Error", "COMError")
   InetGet($value,@ScriptDir & "\Configs\" & $name &".html")
   $sSource = FileRead(@ScriptDir & "\Configs\" & $name & ".html")
   $strresolve = _StringBetween ($sSource, "<hr>", "<hr>")
   $sPlainText = _HTML_StripTags($strresolve[0])
   FileWrite ($directory & "\" & $name & "\" & $name & ".txt", $sPlainText & @CRLF & @CRLF & @CRLF)
EndFunc

Func _HTMLGET ($value, $name, $directory)
   _DirFileCheck ($directory & "\" & $name)
   $inipdf = IniRead (@ScriptDir & "\Configs\Configs.ini", "config_menu", "pdfbox", "False")
   Switch $inipdf
   Case "False"
	  $source = _INetGetSource($value)
	  $string_decode = BinaryToString ($source, 4)
	  ;MsgBox ("","",$value)
	  $html = _StringBetween ($string_decode, '<hr>','<hr>')
	  ;MsgBox ("","",$html[0])
	  FileWrite ($directory & "\" & $name & "\" & $name & ".html",$html[0])
   Case "True"
	  $source = _INetGetSource($value)
   $string_decode = BinaryToString ($source, 4)
   If $header = 1 Then
	  $htmlhead = _StringBetween ($string_decode, '<!DOCTYPE html>','</head>')
	  $html = _StringBetween ($string_decode, '<hr>','<hr>')
	  FileWrite ($directory & "\" & $name & "\" & $name & ".html",'<!DOCTYPE html>'&@CRLF&$htmlhead[0]&@CRLF&$html[0]&@CRLF)
	  $header = $header + 1
	  Return
   Else
	  $html = _StringBetween ($string_decode, '<hr>','<hr>')
	  FileWrite ($directory & "\" & $name & "\" & $name & ".html",$html[0]&@CRLF)
	  Return
   EndIf
   EndSwitch
EndFunc

Func _PDFGET ($value, $name, $directory, $l)
   _DirFileCheck ($directory & "\" & $name)
   $source = _INetGetSource($value)
   $string_decode = BinaryToString ($source, 4)
   If $l = 1 Then
	  $htmlhead = _StringBetween ($string_decode, '<!DOCTYPE html>','</head>')
	  $html = _StringBetween ($string_decode, '<hr>','<hr>')
	  FileWrite (@ScriptDir & "\Configs\" & $name & "(PDF).html",'<!DOCTYPE html>'&@CRLF&$htmlhead[0]&@CRLF&$html[0]&@CRLF)
	  Return
   Else
	  $html = _StringBetween ($string_decode, '<hr>','<hr>')
	  FileWrite (@ScriptDir & "\Configs\" & $name & "(PDF).html",$html[0]&@CRLF)
	  Return
   EndIf
EndFunc

Func _HTML_StripTags($sHTML)
    If Not StringStripWS($sHTML, 8) Then Return SetError(1, 0, "")
    Local $oHTML = ObjCreate("HTMLFILE")
    If @error Then Return SetError(2, 0, "")
    $oHTML.Open()
    $oHTML.Write($sHTML)
    If Not $oHTML.Body.InnerText Then Return SetError(3, 0, "")
    Return SetError(0, 0, $oHTML.Body.InnerText)
EndFunc   ;==>_HTML_StripTags

Func COMError()
    MsgBox(16, "AutoItCOM Test", "We intercepted a COM Error !" & @CRLF & @CRLF & _
            "err.description is: " & @TAB & $oMyError.description & @CRLF & _
            "err.windescription:" & @TAB & $oMyError.windescription & @CRLF & _
            "err.number is: " & @TAB & Hex($oMyError.number, 8) & @CRLF & _
            "err.lastdllerror is: " & @TAB & $oMyError.lastdllerror & @CRLF & _
            "err.scriptline is: " & @TAB & $oMyError.scriptline & @CRLF & _
            "err.source is: " & @TAB & $oMyError.source & @CRLF & _
            "err.helpfile is: " & @TAB & $oMyError.helpfile & @CRLF & _
            "err.helpcontext is: " & @TAB & $oMyError.helpcontext _
            )
    SetError(1)
EndFunc   ;==>COMError

Func _Str_In_Str ($str, $substr)
   $varstr= StringInStr ( $str, $substr)
   If @error Then
	  Return @error
   ElseIf $varstr <> 0 Then
	  Return True
   Else
	  Return False
   EndIf
EndFunc

Func WM_COMMAND($hWnd, $iMsg, $iwParam, $ilParam)
    If $iwParam = 1 Then Add()
    Return "GUI_RUNDEFMSG"
 EndFunc

 Func _AddListView($value)
    ;$value = GUICtrlRead($Input)
    If _ArraySearch($aValues, $value) = -1 And $value <> "" Then
        _ArrayAdd($aValues, $value)
        GUICtrlCreateListViewItem($value&"|", $listview_chap)
		Return ($value)
	 Else
		If _ArraySearch($aValues, $value & "-" & $ListCheckRepeat) = -1 And $value <> "" Then
		    _ArrayAdd($aValues, $value & "-" & $ListCheckRepeat)
			GUICtrlCreateListViewItem($value & "-" & $ListCheckRepeat &"|", $listview_chap)
			Return ($value & "-" & $ListCheckRepeat)
		 Else
			$ListCheckRepeat = $ListCheckRepeat + 1
			_ArrayAdd($aValues, $value & "-" & $ListCheckRepeat)
			GUICtrlCreateListViewItem($value & "-" & $ListCheckRepeat &"|", $listview_chap)
			Return ($value & "-" & $ListCheckRepeat)
		 EndIf
    EndIf
 EndFunc

  Func _ArrayClear ()
   $ListCheckRepeat = 2
   $arrayubound = UBound ($aValues)
   $arrayreset = $arrayubound -1
   $sRange = "0-"&$arrayreset
   _ArrayDelete($aValues, $sRange)
EndFunc