.386

.model	flat, stdcall
option	casemap :none

include		dialog.inc

.code
start:
	invoke	GetModuleHandle, NULL
	mov	hInstance, eax
	invoke	InitCommonControls
	invoke	DialogBoxParam, hInstance, IDD_MAIN, 0, offset DlgProc, 0
	invoke	ExitProcess, eax

;-------------------------------------------------------------------------------------------------------
; 用户交互界面
; Receives: hWin是窗口句柄;uMsg是消息类别;wParam是消息参数
; Returns: none
;-------------------------------------------------------------------------------------------------------
DlgProc proc hWin:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
	mov	eax,uMsg
	
	.if	eax == WM_INITDIALOG
		invoke	LoadIcon,hInstance,200
		invoke	SendMessage, hWin, WM_SETICON, 1, eax
	.elseif eax == WM_COMMAND
		mov	eax,wParam
		.if	eax == IDB_EXIT;按下退出键
			invoke	SendMessage, hWin, WM_CLOSE, 0, 0
		.elseif eax == IDC_PlayButton;按下播放/暂停键
			invoke play, hWin
		.endif
	.elseif	eax == WM_CLOSE
		invoke stop, hWin
		invoke	EndDialog, hWin, 0
	.endif

	xor	eax,eax
	ret
DlgProc endp

;-------------------------------------------------------------------------------------------------------
; 完成音乐播放器逻辑上的初始化
; Receives: none
; Returns: none
;-------------------------------------------------------------------------------------------------------
init proc
	Ret
init endp

;-------------------------------------------------------------------------------------------------------
; 点击播放/暂停按钮时响应
; Receives: hWin是窗口句柄；
; Returns: none
;-------------------------------------------------------------------------------------------------------
play proc hWin:DWORD
	.if currentStatus == 0;若当前状态为停止状态
		mov currentStatus, 1;转为播放状态
		invoke wsprintf, ADDR mediaCommand, ADDR openSong, ADDR currentSong._path
		;invoke MessageBox,hWin, ADDR mediaCommand, ADDR mediaCommand, MB_OK
		invoke mciSendString, ADDR mediaCommand, NULL, 0, NULL;打开歌曲
		invoke mciSendString, ADDR playSong, NULL, 0, NULL;播放歌曲
	.elseif currentStatus == 1;若当前状态为播放状态
		mov currentStatus, 2;转为暂停状态
		invoke mciSendString, ADDR pauseSong, NULL, 0, NULL;暂停歌曲
	.elseif currentStatus == 2;若当前状态为暂停状态
		mov currentStatus, 1;转为播放状态
		invoke mciSendString, ADDR resumeSong, NULL, 0, NULL;恢复歌曲播放
	.endif
	Ret
play endp

;-------------------------------------------------------------------------------------------------------
; 退出程序时响应
; Receives: none
; Returns: none
;-------------------------------------------------------------------------------------------------------
stop proc hWin:DWORD
	.if currentStatus != 0;当前状态为播放或者暂停
		invoke mciSendString, ADDR closeSong, NULL, 0, NULL
	.endif
	Ret
stop endp

end start