#cs ----------------------------------------------------------------------------
 WKHTML2X (PDF/IMG) Class
 Author:    Jefrey <jefrey[at]jefrey.ml>

 Powered by:
   wkhtmltopdf/wkhtmltoimage <http://wkhtmltopdf.org/>

 Using:
   AutoItObject by ProgAndy ET AL <https://www.autoitscript.com/forum/topic/110379-autoitobject-udf/>
   CreateFilesEmbebbed by JScript <https://www.autoitscript.com/forum/topic/132564-createfilesembeddedau3-like-fileinstall/>
#ce ----------------------------------------------------------------------------

#include-once

; Include embebbed EXE files (for a lib, it's better than FileInstall())
#include "wkhtmltopdf.exe.au3"
#include "wkhtmltoimage.exe.au3"

; Include and start AutoItObject
#include "AutoItObject.au3"

_AutoItObject_StartUp()

; Set error handler
Global $oError = ObjEvent("AutoIt.Error", "_ErrFunc")

#Region variables
Global $__WK_Replaces[0][2]

Global $__WKX_Loaded = False

Global $__WKX_2PDF_File = @TempDir & "\wkhtmltopdf.exe"
Global $__WKX_2IMG_File = @TempDir & "\wkhtmltoimage.exe"
#EndRegion

Func _WKHtmlToX_StartUp()
   If FileExists($__WKX_2PDF_File) Then FileDelete($__WKX_2PDF_File)
   If FileExists($__WKX_2IMG_File) Then FileDelete($__WKX_2IMG_File)

   $__WKX_Loaded = True

   _wkhtmltopdf(True)
   _wkhtmltoimage(True)

   OnAutoItExitRegister("_WKHtmlToX_Shutdown")
EndFunc

Func _WKHtmlToX_Shutdown()
   If $__WKX_Loaded Then
	  FileDelete($__WKX_2PDF_File)
	  FileDelete($__WKX_2IMG_File)
   EndIf
EndFunc

Func WKHtmlToX($sTo = "pdf")
   If Not $__WKX_Loaded Then
	  _WKHtmlToX_StartUp()
   EndIf

   Local $oClassObject = _AutoItObject_Class()
   $oClassObject.Create()

   $oClassObject.AddProperty("DebugMode", $ELSCOPE_PUBLIC, False)

   $oClassObject.AddProperty("Input", $ELSCOPE_PUBLIC, Null)
   $oClassObject.AddProperty("Output", $ELSCOPE_PUBLIC, Null)
   $oClassObject.AddProperty("ToFormat", $ELSCOPE_PUBLIC, $sTo) ; It could be just "To" but Au3Check bug didn't allow
   $oClassObject.AddProperty("WorkingDir", $ELSCOPE_PUBLIC, @ScriptDir)

   ; PDF options
   $oClassObject.AddProperty("Collate", $ELSCOPE_PUBLIC, True)
   $oClassObject.AddProperty("CookieJar", $ELSCOPE_PUBLIC, Default)
   $oClassObject.AddProperty("Copies", $ELSCOPE_PUBLIC, 1)
   $oClassObject.AddProperty("Grayscale", $ELSCOPE_PUBLIC, False)
   $oClassObject.AddProperty("LowQuality", $ELSCOPE_PUBLIC, False)
   $oClassObject.AddProperty("MarginBottom", $ELSCOPE_PUBLIC, 10)
   $oClassObject.AddProperty("MarginLeft", $ELSCOPE_PUBLIC, 10)
   $oClassObject.AddProperty("MarginRight", $ELSCOPE_PUBLIC, 10)
   $oClassObject.AddProperty("MarginTop", $ELSCOPE_PUBLIC, 10)
   $oClassObject.AddProperty("Orientation", $ELSCOPE_PUBLIC, "Portrait")
   $oClassObject.AddProperty("PageSize", $ELSCOPE_PUBLIC, "A4")
   $oClassObject.AddProperty("Images", $ELSCOPE_PUBLIC, True)
   $oClassObject.AddProperty("JavascriptDelay", $ELSCOPE_PUBLIC, 200)
   $oClassObject.AddProperty("FooterHtml", $ELSCOPE_PUBLIC, False)
   $oClassObject.AddProperty("HeaderHtml", $ELSCOPE_PUBLIC, False)

   ; Image options
   $oClassObject.AddProperty("CropH", $ELSCOPE_PUBLIC, False)
   $oClassObject.AddProperty("CropW", $ELSCOPE_PUBLIC, False)
   $oClassObject.AddProperty("CropX", $ELSCOPE_PUBLIC, False)
   $oClassObject.AddProperty("CropY", $ELSCOPE_PUBLIC, False)
   $oClassObject.AddProperty("Height", $ELSCOPE_PUBLIC, False)
   $oClassObject.AddProperty("Width", $ELSCOPE_PUBLIC, False)
   $oClassObject.AddProperty("Quality", $ELSCOPE_PUBLIC, False)

   ; Additional arguments
   $oClassObject.AddProperty("Custom", $ELSCOPE_PUBLIC, Null)

   $oClassObject.AddMethod("SetDebugMode", "__WK_DebugMode")
   $oClassObject.AddMethod("Replace", "__WK_Replace")

   $oClassObject.AddMethod("Convert", "__WK__Convert")

   Return $oClassObject.Object
EndFunc

Func __WK_DebugMode($oSelf, $bMode = Default)
   If $bMode = Default Then
	  If $oSelf.DebugMode Then
		 $oSelf.DebugMode = False
	  Else
		 $oSelf.DebugMode = True
	  EndIf
   Else
	  $oSelf.DebugMode = $bMode
   EndIf
   Return True
EndFunc

Func __WK__Convert($oSelf)
   Local $sCmd = Null

   If $oSelf.ToFormat = "pdf" Then
	  If $oSelf.Collate Then
		  $sCmd &= "--collate "
	  Else
		  $sCmd &= "--no-collate "
	  EndIf
	  If $oSelf.CookieJar <> Default Then $sCmd &= "--cookie-jar """ & $oSelf.CookieJar & """ "
	  $sCmd &= "--copies " & $oSelf.Copies & " "
	  If $oSelf.Grayscale Then $sCmd &= "--grayscale "
	  If $oSelf.LowQuality Then $sCmd &= "--lowquality "
	  $sCmd &= "--margin-bottom " & $oSelf.MarginBottom & " "
	  $sCmd &= "--margin-left " & $oSelf.MarginLeft & " "
	  $sCmd &= "--margin-right " & $oSelf.MarginRight & " "
	  $sCmd &= "--margin-top " & $oSelf.MarginTop & " "
	  $sCmd &= "--orientation " & $oSelf.Orientation & " "
	  $sCmd &= "--page-size " & $oSelf.PageSize & " "
	  If Not $oSelf.Images Then $sCmd &= "--no-images "
	  $sCmd &= "--javascript-delay " & $oSelf.JavascriptDelay & " "
	  If $oSelf.FooterHtml Then $sCmd &= "--footer-html " & $oSelf.FooterHtml & " "
	  If $oSelf.FooterHtml Then $sCmd &= "--header-html " & $oSelf.HeaderHtml & " "

	  ; replaces - supported only on PDF
	  $ubound = UBound($__WK_Replaces)
	  If $ubound > 0 Then
		 For $i = 1 To $ubound
			$sCmd &= "--replace """ & $__WK_Replaces[$i][0] & """ """ & $__WK_Replaces[$i][1] & """ "
		 Next
	  EndIf
   Else
		If $oSelf.CropH Then $sCmd &= "--crop-h " & Int($oSelf.CropH)
		If $oSelf.CropW Then $sCmd &= "--crop-w " & Int($oSelf.CropW)
		If $oSelf.CropX Then $sCmd &= "--crop-x " & Int($oSelf.CropX)
		If $oSelf.CropY Then $sCmd &= "--crop-y " & Int($oSelf.CropY)
		If $oSelf.Height Then $sCmd &= "--height " & Int($oSelf.Height)
		If $oSelf.Width Then $sCmd &= "--width " & Int($oSelf.Width)
		If $oSelf.Quality Then $sCmd &= "--quality " & Int($oSelf.Quality)
   EndIf
   $sCmd &= ' ' & $oSelf.Custom & ' "' & $oSelf.Input & '" "' & $oSelf.Output & '"'

   ; end parameters

   If StringLower($oSelf.ToFormat) = "pdf" Then
	  $sExe = $__WKX_2PDF_File
   Else ; img/image/jpg/png/gif/bmp...
	  $sExe = $__WKX_2IMG_File
   EndIf

   If $oSelf.DebugMode Then ConsoleWrite("CmdLine: " & $sExe & " " & $sCmd & " / WorkingDir: " & $oSelf.WorkingDir)

   ; ShellExecuteWait() showed association missing error for $sExe

   If $oSelf.DebugMode Then
	  $sw = @SW_SHOW
   Else
	  $sw = @SW_HIDE
   EndIf

   $run = RunWait($sExe & " " & $sCmd, $oSelf.WorkingDir, $sw)

   Return $run
EndFunc

Func __WK_Replace($oSelf, $sSearch, $sReplace)
   $ubound = UBound($__WK_Replaces)+1
   ReDim $__WK_Replaces[$ubound][2]
   $__WK_Replaces[$ubound][0] = $sSearch
   $__WK_Replaces[$ubound][1] = $sReplace
   Return True
EndFunc

Func _ErrFunc()
    ConsoleWrite("! COM Error !  Number: 0x" & Hex($oError.number, 8) & "   ScriptLine: " & $oError.scriptline & " - " & $oError.windescription & @CRLF)
    Return
EndFunc   ;==>_ErrFunc
