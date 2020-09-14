#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <GuiListView.au3>
#include <GUIEdit.au3>
#include <Include\ListView_Progress.au3>
#include <CODE_.au3>
#include "Include\MetroGUI-UDF\MetroGUI_UDF.au3"
#include "Include\MetroGUI-UDF\_GUIDisable.au3"
#include <GUIConstants.au3>
#NoTrayIcon
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/so /rm /pe
#Au3Stripper_Ignore_Funcs=_iHoverOn,_iHoverOff,_iFullscreenToggleBtn,_cHvr_CSCP_X64,_cHvr_CSCP_X86,_iControlDelete
#AutoIt3Wrapper_Res_HiDpi=y

Global $iProgress = 0
Global $header = 1
Global $button_enabled = 1 ;OpenButton
Global $aValues[1]
Global $ListCheckRepeat = 2
Global $SiteNovel
Global $arrayreset = 0
Global $aValues

;//Set Theme
_SetTheme("DarkTeal")
;//Form
$n_manager = _Metro_CreateGUI("Novel Manager", 878, 455, -1, -1, False)
$Control_Buttons = _Metro_AddControlButtons(True,False,True)
$GUI_CLOSE_BUTTON = $Control_Buttons[0]
$GUI_MINIMIZE_BUTTON = $Control_Buttons[3]
;//Picture
$frame_pic = GUICtrlCreateGroup("", 9,116, 215, 310)
Global $novel_pic = GUICtrlCreatePic("", 9,122, 213, 302)
;//Buttons
$conf_button = _Metro_CreateButtonEx2("Configurações", 400, 34, 153, 33)
$cancel_button = _Metro_CreateButtonEx2("Cancelar", 560, 34, 153, 33)
GUICtrlSetState(-1, $GUI_DISABLE)
$down_button = _Metro_CreateButtonEx2("Download", 718, 34, 153, 33)
$open_button = _Metro_CreateButtonEx2("Abrir", 312, 34, 81, 33)
$put_button = _Metro_CreateButtonEx2(">", 360, 78, 33, 33)
$output_button = _Metro_CreateButtonEx2("<", 6, 78, 33, 33)
;//Labels
Global $novel_tittle = GUICtrlCreateLabel("", 40, 84, 320, 24, $SS_CENTER)
Global $label_status = GUICtrlCreateLabel("", 8, 428, 180, 22)
$credit_l = GUICtrlCreateLabel("github.com/Jason509", 720, 428, 180, 22)
$p_name = GUICtrlCreateLabel("Novel Downloader", 8, 10, 180, 22)
;//InputBox
Global $input_link = GUICtrlCreateInput("", 8, 39, 297, 24)
$input_search = GUICtrlCreateInput("", 232, 121, 161, 24)
;//ListViews
$frame_list = GUICtrlCreateGroup("", 232,146, 161, 280)
Global $listview_chap = GUICtrlCreateListView("Chapters|", 233, 153, 159, 271)
$listview_status = GUICtrlCreateListView("Novel| Cápitulo| Status| Progresso", 402,80, 468, 345)
;//Fundo Transparente
_GUICtrlListView_SetExtendedListViewStyle($listview_chap, $LVS_EX_TRANSPARENTBKGND)
_GUICtrlListView_SetExtendedListViewStyle($listview_status, $LVS_EX_TRANSPARENTBKGND)
;//Estilos do $listview_chap
GUICtrlSetStyle($listview_chap, $LVS_NOCOLUMNHEADER + $LVS_SHOWSELALWAYS + $LVS_REPORT, $LVS_EX_FULLROWSELECT)
GUICtrlSendMsg($listview_status, $LVM_SETCOLUMNWIDTH, 0, 120)
GUICtrlSendMsg($listview_status, $LVM_SETCOLUMNWIDTH, 1, 100)
GUICtrlSendMsg($listview_status, $LVM_SETCOLUMNWIDTH, 2, 110)
GUICtrlSendMsg($listview_status, $LVM_SETCOLUMNWIDTH, 3, 125)
GUICtrlSendMsg($listview_chap, $LVM_SETCOLUMNWIDTH, 0, 130)
;//Texto Transparente
_GUICtrlEdit_SetCueBanner($input_link, "Link da Novel", True)
_GUICtrlEdit_SetCueBanner($input_search, "Procurar Capítulo", True)
;//Formatações de texto
_fontcolor ($credit_l, 12, 0xFFFFFF)
_fontcolor ($input_link, 10)
_fontcolor ($input_search, 10)
_fontcolor ($put_button, 14, 0xFFFFFF, 1)
_fontcolor ($output_button, 14, 0xFFFFFF, 1)
_fontcolor ($novel_tittle, 14, 0xFFFFFF, 1)
_fontcolor ($p_name, 10, 0xFFFFFF, 1)
_fontcolor ($output_button, 14, 0xFFFFFF, 1)
_fontcolor ($label_status, 12, 0xFFFFFF)
_fontcolor ($listview_chap, 12, 0xFFFFFF,1 )
_fontcolor ($listview_status, 10, 0xFFFFFF,1 )
;//Cursor Fix
GUICtrlSetCursor($input_link, "5")
GUICtrlSetCursor($input_search, "5")
GUISetState(@SW_SHOW)

GUIRegisterMsg($WM_NCHITTEST, "_MY_NCHITTEST")
GUIRegisterMsg($WM_GETMINMAXINFO, "WM_GETMINMAXINFO")
GUIRegisterMsg($WM_COMMAND, "WM_COMMAND")

;CheckDirectories
_DirFileCheck (@scriptdir & "\Downloads")
_DirFileCheck (@ScriptDir & "\Configs")


While 1
   $nMsg = GUIGetMsg()
   Check_Input ()
   Switch $nMsg
	  Case $GUI_EVENT_CLOSE, $GUI_CLOSE_BUTTON
		 _Metro_GUIDelete($n_manager)
		 Exit
	  Case $GUI_MINIMIZE_BUTTON
		 GUISetState(@SW_MINIMIZE, $n_manager)
	  Case $conf_button
		 _ConfigGUI ()
	  Case $down_button
		 _DownNovel ()
	  Case $open_button
		 _OpenButton ()
   EndSwitch
WEnd

Func _ConfigGUI()
   ;//Disable other gui
   _GUIDisable($n_manager, 0, 30)
   ;//Form
   Local $config_form = _Metro_CreateGUI("Config", 418, 200, -1, -1, False)
   Local $Control_Buttons_2 = _Metro_AddControlButtons(True, False, False, False)
   Local $GUI_CLOSE_BUTTON = $Control_Buttons_2[0]
   ;//Input
   $input_folder = GUICtrlCreateInput(IniRead (@SCRIPTDIR & "\Configs\Configs.ini", "config_menu", "folder", @ScriptDir & "\Downloads"), 8, 39, 330, 24)
   ;//CheckBox
   $txtbox = _Metro_CreateCheckbox(".TXT", 8, 70, 60, 24)
   $initxt = IniRead (@SCRIPTDIR & "\Configs\Configs.ini", "config_menu", "txtbox", "False")
   If $initxt = "True" Then
	  _Metro_CheckboxCheck($txtbox, True)
   EndIf
   $htmlbox = _Metro_CreateCheckbox(".HTML", 8, 110, 75, 24)
   $inihtml = IniRead (@SCRIPTDIR & "\Configs\Configs.ini", "config_menu", "htmlbox", "False")
   If $inihtml = "True" Then
	  _Metro_CheckboxCheck($htmlbox, True)
   EndIf
   $pdfbox = _Metro_CreateCheckbox(".PDF", 8, 150, 60, 24)
   $inipdf = IniRead (@SCRIPTDIR & "\Configs\Configs.ini", "config_menu", "pdfbox", "False")
   If $inipdf = "True" Then
	  _Metro_CheckboxCheck($pdfbox, True)
   EndIf
   $folder_button = _Metro_CreateButtonEx2("Folder", 345, 36, 66, 29)
   ;$theme_button = _Metro_CreateOnOffToggle("Light", "Dark", 8, 160, 160, 30)
   ;//Label
   $p_conf = GUICtrlCreateLabel("Configurações", 8, 10, 180, 22)
   ;//Transparent text
   _GUICtrlEdit_SetCueBanner($input_folder, "Local de Download", True)
   ;//Text Format
   _fontcolor ($input_folder, 10)
   _fontcolor ($p_conf, 10, 0xFFFFFF, 1)
   ;//Fix Cursor
   GUICtrlSetCursor($input_folder, "5")
   GUISetState(@SW_SHOW)

   While 1
	  $nMsg = GUIGetMsg()
	  Switch $nMsg
		 Case $GUI_EVENT_CLOSE, $GUI_CLOSE_BUTTON
			_Metro_GUIDelete($config_form)
			_GUIDisable($n_manager)
			Return 0
		 Case $txtbox
			If _Metro_CheckboxIsChecked($txtbox) Then
				_Metro_CheckboxUnCheck($txtbox)
				ConsoleWrite("Checkbox unchecked!" & @CRLF)
				IniWrite (@SCRIPTDIR & "\Configs\Configs.ini", "config_menu", "txtbox", "False")
			Else
				_Metro_CheckboxCheck($txtbox)
				ConsoleWrite("Checkbox checked!" & @CRLF)
				IniWrite (@SCRIPTDIR & "\Configs\Configs.ini", "config_menu", "txtbox", "True")
			EndIf
		Case $htmlbox
			If _Metro_CheckboxIsChecked($htmlbox) Then
				_Metro_CheckboxUnCheck($htmlbox)
				ConsoleWrite("Checkbox unchecked!" & @CRLF)
				IniWrite (@SCRIPTDIR & "\Configs\Configs.ini", "config_menu", "htmlbox", "False")
			Else
				_Metro_CheckboxCheck($htmlbox)
				ConsoleWrite("Checkbox checked!" & @CRLF)
				IniWrite (@SCRIPTDIR & "\Configs\Configs.ini", "config_menu", "htmlbox", "True")
			EndIf
		Case $pdfbox
			If _Metro_CheckboxIsChecked($pdfbox) Then
				_Metro_CheckboxUnCheck($pdfbox)
				ConsoleWrite("Checkbox unchecked!" & @CRLF)
				IniWrite (@SCRIPTDIR & "\Configs\Configs.ini", "config_menu", "pdfbox", "False")
			Else
				_Metro_CheckboxCheck($pdfbox)
				ConsoleWrite("Checkbox checked!" & @CRLF)
				IniWrite (@SCRIPTDIR & "\Configs\Configs.ini", "config_menu", "pdfbox", "True")
			 EndIf
		 Case $folder_button
				$folder = FileSelectFolder ( "Select Folder", "")
				GUICtrlSetData ( $input_folder, $folder)
				IniWrite (@SCRIPTDIR & "\Configs\Configs.ini", "config_menu", "folder", $folder)
	  EndSwitch
   WEnd
EndFunc

