.386
.MODEL flat, stdcall
option casemap:none

OPTION PROC:PRIVATE

INCLUDE windows.inc
INCLUDE kernel32.inc
INCLUDELIB kernel32.lib
INCLUDE masm32.inc
INCLUDELIB masm32.lib
include msvcrt.inc
includelib msvcrt.lib
include user32.inc
includelib user32.lib

accDecoder2 PROTO :DWORD, :DWORD

.code
;-------------------------------------------------------------------------------------------------------
; 将acc文件解码成wav格式文件
; inputName是acc文件的路径名字符串的地址，outputName是wav文件的路径名字符串的地址
; 目前是解码完毕，函数才会返回
; Example:
;	.data
;		inputName db "Safe And Sound-Taylor Swift.aac",0
;		outputName db "output.wav",0
;	.code
;		invoke accDecoder, ADDR inputName, ADDR outputName
; Returns: none
;-------------------------------------------------------------------------------------------------------

accDecoder2 PROC PUBLIC inputName:DWORD, outputName:DWORD

.data
	PrcName db 'faad.exe',0
	CmdLineFormat db 'faad -o "%s" "%s"',0
	szPause db 'pause',0
	FailInfo db "Fail to create a process",0
	CmdLine db 200 DUP(0)	

.data?
	SUInfo  STARTUPINFO <>
	PrcInfo PROCESS_INFORMATION <>
.code 	
	invoke crt_memset, ADDR SUInfo, 0, sizeof SUInfo
	mov SUInfo.cb, sizeof SUInfo
	mov SUInfo.dwFlags, STARTF_USESHOWWINDOW 
	mov SUInfo.wShowWindow, 0 
	invoke crt_memset, ADDR PrcInfo, 0, sizeof PrcInfo
	
	invoke crt_sprintf, ADDR CmdLine, ADDR CmdLineFormat, outputName, inputName

	INVOKE  CreateProcess,ADDR PrcName,ADDR CmdLine,
                NULL, NULL,CREATE_NO_WINDOW,
                0,NULL,NULL,
                ADDR SUInfo,ADDR PrcInfo
	.if eax == 0
		invoke crt_printf, ADDR FailInfo
	.elseif
		;Wait until child process exits.
		invoke WaitForSingleObject, PrcInfo.hProcess, INFINITE

		;Close process and thread handles. 
		invoke CloseHandle,PrcInfo.hProcess
		invoke CloseHandle,PrcInfo.hThread 
	.endif
	ret
accDecoder2 ENDP

END