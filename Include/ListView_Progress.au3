#include-once
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Constants.au3>
#include <ProgressConstants.au3>
#include <HeaderConstants.au3>
#include <WinAPI.au3>
#include <GuiListView.au3>

Global $aProgress = 0

Global Const $SW_HIDE = 0
Global Const $SW_SHOW = 5

Global $aProgress[1][4]

GUIRegisterMsg($WM_NOTIFY, "_ListView_Notify")
GUIRegisterMsg($WM_SIZE, "_ListView_Notify")

; #FUNCTION# ======================================================================================
; Function Name:    _ListView_InsertProgressBar()
; Description:      Inserts a progressbar control in the ListView control.
; Syntax.........:  _ListView_InsertProgressBar($sHwnd, $sItemIndex[, $sSubItemIndex])
; Parameter(s):     $sHwnd - Handle to the ListView control.
;                   $sItemIndex - Zero based index of the item at which the progressbar should be inserted.
;                   $sSubItemIndex - [Optional] One based index of the subitem where progressbar should be placed, default is 1.
;
; Return Value(s):  Returns the identifier (controlID) of the new progressbar control.
; Requirement(s):   AutoIt 3.2.10.0 and above
; Note(s):          Optimal amount of progressbar controls is 5-10. Don`t abuse with many amount of progressbar controls.
;
; Author(s):        R.Gilman (a.k.a rasim), arcker
;==================================================================================================
Func _ListView_InsertProgressBar($sHwnd, $sItemIndex, $sSubItemIndex = 0)
    If Not IsHWnd($sHwnd) Then $sHwnd = GUICtrlGetHandle($sHwnd)

    Local $iStyle = _WinAPI_GetWindowLong($sHwnd, $GWL_STYLE)

	If BitAND($iStyle, $WS_CLIPCHILDREN) <> $WS_CLIPCHILDREN Then
		_WinAPI_SetWindowLong($sHwnd, $GWL_STYLE, BitOR($iStyle, $WS_CLIPCHILDREN))
	EndIf

	Local $aRect

	If $sSubItemIndex = 0 Then
		$aRect = _GUICtrlListView_GetItemRect($sHwnd, $sItemIndex, 2)
	Else
		$aRect = _GUICtrlListView_GetSubItemRect($sHwnd, $sItemIndex, $sSubItemIndex)
	EndIf

    $aProgress[0][0] += 1
    ReDim $aProgress[$aProgress[0][0] + 1][4]
    $aProgress[$aProgress[0][0]][0] = _Progress_Create($sHwnd, $aRect[0], $aRect[1], $aRect[2] - $aRect[0], $aRect[3] - $aRect[1])

    $aProgress[$aProgress[0][0]][1] = $sItemIndex
    $aProgress[$aProgress[0][0]][2] = $sSubItemIndex
    $aProgress[$aProgress[0][0]][3] = $sHwnd

    Return $aProgress[$aProgress[0][0]][0]
EndFunc   ;==>_ListView_InsertProgressBar

Func _Progress_Create($hWnd, $iX, $iY, $iWidth = -1, $iHeight = -1, $iStyle = 0, $iExStyle = 0)
	$iStyle = BitOR($iStyle, $WS_CHILD, $WS_VISIBLE)
	Return _WinAPI_CreateWindowEx($iExStyle, "msctls_progress32", "", $iStyle, $iX, $iY, $iWidth, $iHeight, $hWnd)
EndFunc   ;==>_Progress_Create

Func _ListView_Notify($hWnd, $Msg, $wParam, $lParam)
	If $Msg = $WM_SIZE Then
		_WinAPI_InvalidateRect($hWnd)
		Return $GUI_RUNDEFMSG
	EndIf

    Local $tNMHEADER, $hWndFrom, $iCode, $i

    $tNMHEADER = DllStructCreate($tagNMHEADER, $lParam)
    $hWndFrom = DllStructGetData($tNMHEADER, "hwndFrom")
	$iCode = DllStructGetData($tNMHEADER, "Code")

	Switch $iCode
		Case $HDN_ITEMCHANGED, $HDN_ITEMCHANGEDW, $LVN_ENDSCROLL
			If $iCode <> $LVN_ENDSCROLL Then $hWndFrom = _WinAPI_GetParent($hWndFrom)

			For $i = 1 To $aProgress[0][0]
				If $aProgress[$i][3] = $hWndFrom Then _
				_MoveProgress($hWndFrom, $aProgress[$i][0], $aProgress[$i][1], $aProgress[$i][2])
			Next

			_WinAPI_InvalidateRect($hWndFrom)
	EndSwitch

    Return $GUI_RUNDEFMSG
EndFunc   ;==>_ListView_Notify

Func _MoveProgress($hListView, $hProgress, $sItemIndex, $sSubItemIndex)
	Local $aRect

	If $sSubItemIndex = 0 Then
		$aRect = _GUICtrlListView_GetItemRect($hListView, $sItemIndex, 2)
	Else
		$aRect = _GUICtrlListView_GetSubItemRect($hListView, $sItemIndex, $sSubItemIndex)
	EndIf

	If $aRect[1] < 10 Then
        _WinAPI_ShowWindow($hProgress, $SW_HIDE)
    ElseIf $aRect[1] >= 10 Then
        _WinAPI_ShowWindow($hProgress, $SW_SHOW)
    EndIf

    _WinAPI_MoveWindow($hProgress, $aRect[0], $aRect[1], $aRect[2] - $aRect[0], $aRect[3] - $aRect[1], True)
EndFunc   ;==>_MoveProgress

; #FUNCTION# ====================================================================================================
; Description ...: Sets the color of the indicator bar
; Parameters ....: $hWnd        - Handle to the control
;                  $iColor      - The new progress indicator bar color.  Specify the CLR_DEFAULT value to cause the progress  bar
;                  +to use its default progress indicator bar color.
; Return values .: Success      - The previous progress indicator bar color, or CLR_DEFAULT if the progress indicator  bar  color
;                  +is the default color.
; Author ........: Paul Campbell (PaulIA), Updated By Arcker
; Remarks .......: This message is supported only in the Windows Classic theme
; Related .......:
; ====================================================================================================
Func _Progress_SetBarColor($hWnd, $iColor)
  Return _SendMessage($hWnd, $PBM_SETBARCOLOR, 0, $iColor)
EndFunc

; #FUNCTION# ====================================================================================================
; Description ...: Sets the current position
; Parameters ....: $hWnd        - Handle to the control
;                  $iPos        - The new position
; Return values .: Success      - The previous position
; Author ........: Paul Campbell (PaulIA), Updated By Arcker
; Remarks .......:
; Related .......: _Progress_GetPos
; ====================================================================================================
Func _Progress_SetPos($hWnd, $iPos)
  Return _SendMessage($hWnd, $PBM_SETPOS, $iPos, 0)
EndFunc

; #FUNCTION# ====================================================================================================
; Description ...: Sets the background color in the progress bar
; Parameters ....: $hWnd        - Handle to the control
;                  $iColor      - The new background color.  Specify the CLR_DEFAULT value to cause the progress bar to  use  its
;                  +default background color.
; Return values .: Success      - The previous background color, or CLR_DEFAULT if the background color is the default color.
; Author ........: Paul Campbell (PaulIA), Updated By Arcker
; Remarks .......: This message is supported only in the Windows Classic theme
; Related .......:
; ====================================================================================================
Func _Progress_SetBkColor($hWnd, $iColor)
  Return _SendMessage($hWnd, $PBM_SETBKCOLOR, 0, $iColor)
EndFunc

; #FUNCTION# ====================================================================================================

; Description ...: Specifies the step increment
; Parameters ....: $hWnd        - Handle to the control
;                  $iStep       - Step increment.
; Return values .: Success      - The previous step increment
; Author ........: Paul Campbell (PaulIA)
; Remarks .......: The step increment is the amount by which the progress bar increases its current position whenever you use the
;                  _Progress_StepIt function. By default, the step increment is set to 10.
; Related .......: _Progress_StepIt
; ====================================================================================================
Func _Progress_SetStep($hWnd, $iStep=10)
  Return _SendMessage($hWnd, $PBM_SETSTEP, $iStep, 0)
EndFunc

; #FUNCTION# ====================================================================================================
; Description ...: Advances the current position by the step increment
; Parameters ....: $hWnd        - Handle to the control
; Return values .: Success      - The previous position
; Author ........: Paul Campbell (PaulIA), Updated By Arcker
; Remarks .......:
; Related .......: _Progress_SetStep
; ====================================================================================================
Func _Progress_StepIt($hWnd)
  Return _SendMessage($hWnd, $PBM_STEPIT, 0, 0)
EndFunc

; #FUNCTION# ====================================================================================================
; Description ...: Delete the progressbar control
; Parameters ....: $hWnd        - Handle to the control
; Return values .: Success      - True
;				   Failure		- False
; Author ........: G. Sandler (MrCreatoR), Updated by rasim
; Remarks .......:
; Related .......: _Progress_SetStep
; ====================================================================================================
Func _Progress_Delete($hWnd)
    Local $aTmpArr[1][3]

    For $i = 1 To $aProgress[0][0]
        If $aProgress[$i][0] <> $hWnd Then
            $aTmpArr[0][0] += 1
            ReDim $aTmpArr[$aTmpArr[0][0]+1][4]

            $aTmpArr[$aTmpArr[0][0]][0] = $aProgress[$i][0]
            $aTmpArr[$aTmpArr[0][0]][1] = $aProgress[$i][1]
            $aTmpArr[$aTmpArr[0][0]][2] = $aProgress[$i][2]
            $aTmpArr[$aTmpArr[0][0]][3] = $aProgress[$i][3]
        EndIf
    Next

    $aProgress = $aTmpArr

    Local $aResult = DllCall("User32.dll", "int", "DestroyWindow", "hwnd", $hWnd)
    If @error Then Return SetError(1, 0, 0)

    Return $aResult[0] <> 0
EndFunc