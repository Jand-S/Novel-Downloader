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
   GUICtrlSetState($cancel_button, $GUI_ENABLE)
   $bInterrupt = False
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
	  $roundprogrss = Round ($progress_set)
	  $numberset = Number ($roundprogrss) ;Convert number
	  Dim $aDdata[$aSelcted[0] + 1]
	  $aDdata[0] = $aSelcted[0]
	  For $i = 1 To $aSelcted[0]
		 If $bInterrupt = True Then
		  ExitLoop
	   EndIf
		 $aDdata[$i] = _GUICtrlListView_GetItemTextString($listview_chap, $aSelcted[$i])
		 $inilink = IniRead (@ScriptDir & "\Configs\iniw.ini", $titleglobal, $aDdata[$i], -1 )
		 ;MsgBox ("","",$aDdata[$i])
		 Local $folder = IniRead (@ScriptDir & "\Configs\Configs.ini", "config_menu", "folder", @ScriptDir & "\Downloads")
		 Local $initxt = IniRead (@ScriptDir & "\Configs\Configs.ini", "config_menu", "txtbox", "False")
		 Local $inihtml = IniRead (@ScriptDir & "\Configs\Configs.ini", "config_menu", "htmlbox", "False")
		 Local $inipdf = IniRead (@ScriptDir & "\Configs\Configs.ini", "config_menu", "pdfbox", "False")

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
	  Sleep (500)
	  $initxt = IniRead (@ScriptDir & "\Configs\Configs.ini", "config_menu", "txtbox", "False")
	  $inihtml = IniRead (@ScriptDir & "\Configs\Configs.ini", "config_menu", "htmlbox", "False")
	  $inipdf = IniRead (@ScriptDir & "\Configs\Configs.ini", "config_menu", "pdfbox", "False")
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
	  If $bInterrupt = True Then
		 $bInterrupt = False
		 _GUICtrlListView_AddSubItem($listview_status, $finditem_2, "Cancelado!", 2, 2)
		 GUICtrlSetState($cancel_button, $GUI_DISABLE)
	  Else
		 _GUICtrlListView_AddSubItem($listview_status, $finditem_2, "Completed!", 2, 2)
		 GUICtrlSetState($cancel_button, $GUI_DISABLE)
	  EndIf
   EndIf
EndFunc

Func Get_Title ()
   ;Switch $SiteNovel
   $link = GUICtrlRead ($input_link)
   $checknovellink = StringInStr ($link, "https://novelmania.com.br/novels")
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
   Local $fileout = StringStripWS ($strc, 2)
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

Func _GetPic ($img_link = "", $put = 0)
   If $put = 0 Then
	  $img_link = _GetLinkImage ()
	  If $img_link = False Then
		 Return False
	  EndIf
   EndIf
   _GDIPlus_Startup()
   Local Const $STM_SETIMAGE = 0x0172
   Local Const $hBmp = _GDIPlus_BitmapCreateFromMemory(InetRead($img_link), True)
   Local Const $hBmp2 = _GDIPlus_BitmapCreateFromMemory(InetRead("https://raw.githubusercontent.com/Jason509/Novel-Downloader/master/Include/icox.png"), True)   ;to load an image from the net ;https://raw.githubusercontent.com/Jason509/Novel-Downloader/master/Include/icox.png
   Local Const $hBitmap = _GDIPlus_BitmapCreateFromHBITMAP($hBmp)
   Local Const $iWidth = _GDIPlus_ImageGetWidth($hBitmap)
   Local Const $iHeight = _GDIPlus_ImageGetHeight($hBitmap)
   $hBitmap_resized = _GDIPlus_ImageResize($hBitmap, 214, 303) ;GDI+ bitmap
   $hHBitmap2 = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hBitmap_resized)
   $clean = GUICtrlSetImage ($novel_pic, "")
   $teste = _WinAPI_DeleteObject(GUICtrlSendMsg($novel_pic, $STM_SETIMAGE, $IMAGE_BITMAP, $hHBitmap2))
   $teste2 = _WinAPI_DeleteObject(GUICtrlSendMsg($novel_picx, $STM_SETIMAGE, $IMAGE_BITMAP, $hBmp2))
   ;GUICtrlSetState($delete_button, $GUI_SHOW)
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
	  IniWrite (@ScriptDir & "\Configs\pics.ini", $titleglobal, "pic", $pic[0])
	  Return $pic[0]
   EndIf
EndFunc

Func _ext_url ()
   $ListCheckRepeat = 2
   ;ConsoleWrite ("exturl" & @crlf)
   $link = GUICtrlRead ($input_link)
   $checknovellink = StringInStr ($link, "https://novelmania.com.br/novels")
   If $checknovellink = 0 Then
	  $title = GUICtrlRead($novel_tittle)
	  If $title <> "" Then
		 Return 0
	  EndIf
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

Func putbuttonskip ()
   $fileiniput = IniReadSection (@ScriptDir & "\Configs\iniw.ini", $titleglobal)
   $maxfileput = UBound ($fileiniput)
   For $i = 1 To $maxfileput -1 Step 1
	  $fileiniput = IniReadSection (@ScriptDir & "\Configs\iniw.ini", $titleglobal)
	  $listviewvalue = _AddListView($fileiniput[$i][0])
   Next
   Return
EndFunc


Func _OpenButton ()
   FileDelete (@ScriptDir & "\Configs\key.txt")
   FileDelete (@ScriptDir & "\Configs\source.txt")
   FileDelete (@ScriptDir & "\Configs\source-links.txt")
   FileDelete (@ScriptDir & "\Configs\value.txt")
   IniDelete (@ScriptDir & "\Configs\iniw.ini", $novel_tittle)
   _GUICtrlListView_DeleteAllItems ($listview_chap)
   GUICtrlSetData($label_status, "Downloading...")
   $link = GUICtrlRead ($input_link)
   $PartSite = _part_txt ($link)
   Global $SiteNovel = String ($PartSite[3])
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
   If GUICtrlRead($input_link) = "" And GUICtrlRead($novel_tittle) = "" And $button_enabled = 1 Then
	  GUICtrlSetState($open_button, $GUI_DISABLE)
	  $button_enabled = 0
   Return
   ElseIf $button_enabled = 0 And GUICtrlRead($input_link) <> "" Then
	  GUICtrlSetState($open_button, $GUI_ENABLE)
	  $button_enabled = 1
	  Return
   Else
	  Return
   EndIf
EndFunc

func Check_Downbutton ()
   $iIndex = _GUICtrlListView_GetSelectedIndices($listview_chap)
   If $iIndex = ""  And $button_enabledDown = 1 Then
	  GUICtrlSetState($down_button, $GUI_DISABLE)
	  $button_enabledDown = 0
   Return
   ElseIf $button_enabledDown = 0 And $iIndex <> "" Then
	  GUICtrlSetState($down_button, $GUI_ENABLE)
	  $button_enabledDown = 1
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
		$asKeyWords[$K] = $value
		$K = $K + 1
		Return ($value)
	 Else
		If _ArraySearch($aValues, $value & "-" & $ListCheckRepeat) = -1 And $value <> "" Then
		    _ArrayAdd($aValues, $value & "-" & $ListCheckRepeat)
			GUICtrlCreateListViewItem($value & "-" & $ListCheckRepeat &"|", $listview_chap)
			$asKeyWords[$K] = $value & "-" & $ListCheckRepeat
			$K = $K + 1
			Return ($value & "-" & $ListCheckRepeat)
		 Else
			$ListCheckRepeat = $ListCheckRepeat + 1
			_ArrayAdd($aValues, $value & "-" & $ListCheckRepeat)
			GUICtrlCreateListViewItem($value & "-" & $ListCheckRepeat &"|", $listview_chap)
			$asKeyWords[$K] = $value & "-" & $ListCheckRepeat
			$K = $K + 1
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

Func checkupdate ()
   $url = "https://raw.githubusercontent.com/Jason509/Novel-Downloader/master/README.md"
   $cversion = _StringBetween ( _INetGetSource ($url), "(v", ")")
   If @error Then
	  _Metro_MsgBox ("","ERROR","Sem acesso a Internet.", 180)
	  Return
   EndIf
   $convert = Number ($cversion[0])
   $initxtboxvesion = IniRead (@SCRIPTDIR & "\Configs\Configs.ini", "version"&$cversion[0], "$txtbox", "False")
   Select
	  Case $initxtboxvesion = "False"
   If $convert > $version Then
	  $url = "https://raw.githubusercontent.com/Jason509/Novel-Downloader/master/CHANGELOG.md"
	  ;MsgBox ("","",$url)
	  $source = _INetGetSource ($url)
	  $stringsource = BinaryToString ( $source , 4)
	  $sOutput = StringRegExpReplace($stringsource, "[#]", "")
	  $splitchangeversion = StringSplit ($sOutput, "<hr>", 1)
	  $strip = StringStripWS ( $splitchangeversion[2], 1 )
	  $filechangelog = FileWrite (@scriptdir & "\Configs\CHANGELOG.txt", $strip)
	  ;MsgBox ("", "", $splitchangeversion[2])
	  $arrayresize = retuncharwid ()
		 _GUIDisable($n_manager, 0, 30)
		 $guidisp = _Metro_CreateGUI("", $arrayresize[0], $arrayresize[1] +90, -1, -1, False)
		 $label_textact = GUICtrlCreateLabel("Atualização disponivel", 8, 10, 200, 34)
		 Local $Control_Buttons_2 = _Metro_AddControlButtons(True, False, False, False)
		 Local $GUI_CLOSE_BUTTON = $Control_Buttons_2[0]
		 $label_text = GUICtrlCreateLabel($strip, 8, 34, $arrayresize[0] - 10,$arrayresize[1] - 35)
		 _fontcolor ($label_text, 12, 0xFFFFFF)
		 _fontcolor ($label_textact, 11, 0xFFFFFF,1)
		 $txtbox = _Metro_CreateCheckbox("Do not show again", 8, $arrayresize[1], 160, 24)
		 $downloadbuttonapp = _Metro_CreateButtonEx2("Download", $arrayresize[0] - 240, $arrayresize[1]+ 35, 100, 40)
		 $cancelbuttonapp =_Metro_CreateButtonEx2("Cancel", $arrayresize[0] - 130, $arrayresize[1]+ 35, 100, 40, $ButtonBKColorCancel)
	  GUISetState(@SW_SHOW)
	  While 1
	  $nMsg = GUIGetMsg()
	  Switch $nMsg
		 Case $GUI_EVENT_CLOSE, $GUI_CLOSE_BUTTON, $cancelbuttonapp
			_Metro_GUIDelete($guidisp)
			_GUIDisable($n_manager)
		 Return 0
		 Case $txtbox
			If _Metro_CheckboxIsChecked($txtbox) Then
				_Metro_CheckboxUnCheck($txtbox)
				ConsoleWrite("Checkbox unchecked!" & @CRLF)
				IniWrite (@SCRIPTDIR & "\Configs\Configs.ini", "version"&$cversion[0], "$txtbox", "False")
			Else
				_Metro_CheckboxCheck($txtbox)
				ConsoleWrite("Checkbox checked!" & @CRLF)
				IniWrite (@SCRIPTDIR & "\Configs\Configs.ini", "version"&$cversion[0], "$txtbox", "True")
			 EndIf
		  Case $downloadbuttonapp
			$urlx = "https://raw.githubusercontent.com/Jason509/Novel-Downloader/master/README.md"
			$cdownload = _StringBetween ( _INetGetSource ($urlx), "<h3>Download</h3>", "/li>")
			$linkdown= _StringBetween ($cdownload[0], "<li>", "<")
			;MsgBox ("","",$linkdown[0])
			ShellExecute($linkdown[0])
		 EndSwitch
	  WEnd
	  ;
	  ;_Metro_MsgBox ("","Atualização disponivel",$splitchangeversion[2]);MsgBox ("", "", "New Update Avaliable Version " & $convert)
	  Return
   Else
	  Return
   EndIf
Case Else
   Return
EndSelect
EndFunc

Func retuncharwid ()
   Local $arrayinfo[2], $x = 0
   $n = 0
   $file = @scriptdir & "\Configs\CHANGELOG.txt"
   $fl = _FileCountLines ( $file )
   Do
	  $n = $n + 1
	  $line = FileReadLine ($file, $n)
	  $numchar = StringLen ($line)
	  If $x < $numchar Then
		 $x = $numchar
	  EndIf
   Until $n = $fl
   $fl = $fl - 2
   $arrayinfo[0] = $x * 8
   $arrayinfo[1] = $fl * 32
   $arrayinfo[0] = $arrayinfo[0]
   If $arrayinfo[0] < 270 Then
	  $arrayinfo[0] = 270
   EndIf
   ;MsgBox ("","",$arrayinfo[0])
   ;MsgBox ("","", $arrayinfo[0] & @CRLF & $arrayinfo[1])
   FileDelete (@scriptdir & "\Configs\CHANGELOG.txt")
   Return $arrayinfo
EndFunc

Func _WM_STOPLOOP($hWnd, $Msg, $wParam, $lParam)
    ; The Stop button was pressed so set the flag
    If BitAND($wParam, 0x0000FFFF) = $cancel_button Then
        $bInterrupt = True
    EndIf
    Return $GUI_RUNDEFMSG
 EndFunc   ;==>_WM_COMMAND

Func _fowardNovel ()
   $fileini = IniReadSectionNames (@ScriptDir & "\Configs\iniw.ini")
   $maxfile = UBound ($fileini)
   If $GlobalChapterIni >= $maxfile -1 Then
	;  MsgBox ("","","Return")
	  Return False
   Else
   $GlobalChapterIni = $GlobalChapterIni + 1
 ;  MsgBox ("","","+1")
   $strs = StringLen ($fileini[$GlobalChapterIni])
   If $strs > 40 then
	  _fontcolor ($novel_tittle, 9, 0xFFFFFF, 1)
   Else
	  _fontcolor ($novel_tittle, 14, 0xFFFFFF, 1)
   EndIf
   Global $titleglobal = $fileini[$GlobalChapterIni]
   GUICtrlSetData($novel_tittle, $fileini[$GlobalChapterIni])
   $inipic = IniRead (@ScriptDir & "\Configs\pics.ini", $titleglobal, "pic", "")
   _GetPic ($inipic, 1)
   Return True
EndIf
EndFunc

Func _backfowardNovel ()
   $fileini = IniReadSectionNames (@ScriptDir & "\Configs\iniw.ini")
   $maxfile = UBound ($fileini)
   If $GlobalChapterIni <= 1 Then
	 ; MsgBox ("","","Return")
	  Return False
   Else
	  $GlobalChapterIni = $GlobalChapterIni - 1
	 ; MsgBox ("","","-1")
	  $strs = StringLen ($fileini[$GlobalChapterIni])
	  If $strs > 40 then
		 _fontcolor ($novel_tittle, 9, 0xFFFFFF, 1)
	  Else
		 _fontcolor ($novel_tittle, 14, 0xFFFFFF, 1)
	  EndIf
	  Global $titleglobal = $fileini[$GlobalChapterIni]
	  GUICtrlSetData($novel_tittle, $fileini[$GlobalChapterIni])
	  $inipic = IniRead (@ScriptDir & "\Configs\pics.ini", $titleglobal, "pic", "")
	  _GetPic ($inipic, 1)
	  Return True
   EndIf
EndFunc

Func _checkputout ()
   Global $fileinisavechap = IniReadSectionNames (@ScriptDir & "\Configs\iniw.ini")
If @error Then
   $fileinisavechap = False
Else
   If $globalfr = 0 Then
   $maxfile = UBound ($fileinisavechap)
  ; MsgBox ("","",$maxfile)
   Global $GlobalChapterIni = $maxfile - 2
   $globalfr =1
Else
   Return
EndIf
   ;MsgBox ("","",$GlobalChapterIni)
EndIf
EndFunc

Func _DeleteButtonchap ()
   IniDelete ( @ScriptDir & "\Configs\iniw.ini", $titleglobal)
   IniDelete ( @ScriptDir & "\Configs\pics.ini", $titleglobal)
   $clean = GUICtrlSetImage ($novel_pic, "")
   GUICtrlSetState($delete_button, $GUI_HIDE)
   _GUICtrlListView_DeleteAllItems ($listview_chap)
   GUICtrlSetData($label_status, "")
   GUICtrlSetData($novel_tittle, "")
   GUICtrlSetData($titleglobal, "")
   $clean = GUICtrlSetImage ($novel_picx, "")
   GUICtrlSetState($delete_button, $GUI_HIDE)
   _ArrayClear ()
   $globalfr = 0
EndFunc

Func CheckInputSearch ()
   Local $sInput = GUICtrlRead($input_search)
   $numb = _GUICtrlListView_GetItemCount ($listview_chap) -1
   For $i = 0 to $numb
   If $sInput <> "" Then
	  If StringInStr($asKeyWords[$i], $sInput) <> 0 And $same = 1 Then
		 $finditem_2 = ControlListView ( "", "", $listview_chap, "FindItem", $asKeyWords[$i])
		 If $finditem_2 < $numb - 10 Then
		 $finditem_2 = $finditem_2 + 10
		 EndIf
		  _GUICtrlListView_EnsureVisible($listview_chap, $finditem_2)
		  $same = 2
	   EndIf
	EndIf
 Next
 EndFunc

 Func WM_COMMANDINPUTSEARCH($hWnd, $iMsg, $wParam, $lParam)

    Local $hdlWindowFrom, _
          $intMessageCode, _
          $intControlID_From

    $intControlID_From =  BitAND($wParam, 0xFFFF)
    $intMessageCode = BitShift($wParam, 16)

    Switch $intControlID_From
        Case $input_search
            Switch $intMessageCode
			Case $EN_CHANGE
			   $same = 1
                    ;ConsoleWrite("[" & _Now() & "] - The text in the $txtInput control has changed! Text = " & GUICtrlRead($inputsearch) & @CRLF)
            EndSwitch
    EndSwitch

    Return $GUI_RUNDEFMSG

EndFunc

