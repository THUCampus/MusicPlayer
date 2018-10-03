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
	
	.if	eax == WM_INITDIALOG;初始化界面
		invoke init, hWin
		invoke	LoadIcon,hInstance,200
		invoke	SendMessage, hWin, WM_SETICON, 1, eax
	.elseif eax == WM_COMMAND
		mov	eax,wParam
		.if	eax == IDB_EXIT;按下退出键
			invoke	SendMessage, hWin, WM_CLOSE, 0, 0
		.elseif songMenuSize == 0;若干歌单大小为0
			Ret;则下述操作都不进行！！！
		.elseif eax == IDC_PlayButton;若按下播放/暂停键
			invoke playPause, hWin
		.elseif ax == IDC_SongMenu;若歌单
			shr eax,16
			.if ax == LBN_SELCHANGE;选中项发生改变
				invoke SendDlgItemMessage, hWin, IDC_SongMenu, LB_GETCURSEL, 0, 0;则获取被选中的下标
				invoke changeSong,hWin,eax;改变歌曲
			.endif
		.elseif eax == IDC_PrevSong;若点击上一首歌
			.if currentSongIndex == 0
				mov eax, songMenuSize
				mov currentSongIndex,eax
			.endif
			dec currentSongIndex
			invoke SendDlgItemMessage,hWin, IDC_SongMenu, LB_SETCURSEL, currentSongIndex, 0;改变选中项
			invoke changeSong,hWin,currentSongIndex;播放该首歌曲
		.elseif eax == IDC_NextSong;若点击下一首歌
			inc currentSongIndex
			mov eax, currentSongIndex
			.if eax == songMenuSize
				mov currentSongIndex,0
			.endif
			invoke SendDlgItemMessage,hWin, IDC_SongMenu, LB_SETCURSEL, currentSongIndex, 0;改变选中项
			invoke changeSong,hWin,currentSongIndex;播放该首歌曲
		.endif
		
	.elseif	eax == WM_CLOSE;程序退出时执行
		invoke closeSong, hWin
		invoke	EndDialog, hWin, 0
	.endif

	xor	eax,eax
	ret
DlgProc endp

;-------------------------------------------------------------------------------------------------------
; 完成音乐播放器逻辑上的初始化（请把所有初始化工作写在这个函数中）
; Receives: hWin是窗口句柄；
; Returns: none
;-------------------------------------------------------------------------------------------------------
init proc hWin:DWORD
	;展示歌单中的所有歌曲
	mov esi, offset songMenu
	mov ecx, songMenuSize
	L1:
		push ecx
		invoke SendDlgItemMessage, hWin, IDC_SongMenu, LB_ADDSTRING, 0, ADDR (Song PTR [esi])._name
		add esi, TYPE songMenu
		pop ecx
	loop L1

	Ret
init endp

;-------------------------------------------------------------------------------------------------------
; 打开某首歌
; Receives: index是歌曲在歌单中下标；
; Requires: currentStatus == 0 即当前状态必须是停止状态
; Returns: none
;-------------------------------------------------------------------------------------------------------
openSong proc hWin:DWORD, index:DWORD
	mov eax, index
	mov ebx, TYPE songMenu
	mul ebx;此时eax中存储了第index首歌曲相对于songMenu的偏移地址
	invoke wsprintf, ADDR mediaCommand, ADDR openSongCommand, ADDR songMenu[eax]._path
	invoke mciSendString, ADDR mediaCommand, NULL, 0, NULL;打开歌曲
	Ret
openSong endp

;-------------------------------------------------------------------------------------------------------
; 点击播放/暂停按钮时响应
; Receives: hWin是窗口句柄；
; Returns: none
;-------------------------------------------------------------------------------------------------------
playPause proc hWin:DWORD
	.if currentStatus == 0;若当前状态为停止状态
		mov currentStatus, 1;转为播放状态
		invoke openSong,hWin, currentSongIndex;
		invoke mciSendString, ADDR playSongCommand, NULL, 0, NULL;播放歌曲
	.elseif currentStatus == 1;若当前状态为播放状态
		mov currentStatus, 2;转为暂停状态
		invoke mciSendString, ADDR pauseSongCommand, NULL, 0, NULL;暂停歌曲
	.elseif currentStatus == 2;若当前状态为暂停状态
		mov currentStatus, 1;转为播放状态
		invoke mciSendString, ADDR resumeSongCommand, NULL, 0, NULL;恢复歌曲播放
	.endif
	Ret
playPause endp

;-------------------------------------------------------------------------------------------------------
; 切换歌曲时响应
; Receives: hWin是窗口句柄,newSongIndex是新的歌曲在songMenu中的下标
; Returns: none
;-------------------------------------------------------------------------------------------------------
changeSong proc hWin:DWORD, newSongIndex: DWORD
	invoke closeSong,hWin;关闭之前的歌曲
	;更新当前歌曲的信息
	mov eax, newSongIndex
	mov currentSongIndex, eax
	invoke openSong,hWin, currentSongIndex;打开新的歌曲
	mov currentStatus, 1;转为播放状态
	invoke mciSendString, ADDR playSongCommand, NULL, 0, NULL;播放歌曲
	Ret
changeSong endp


;-------------------------------------------------------------------------------------------------------
; 关闭当前的歌曲
; Receives: hWin是窗口句柄；
; Returns: none
;-------------------------------------------------------------------------------------------------------
closeSong proc hWin:DWORD
	.if currentStatus != 0;当前状态为播放或者暂停
		invoke mciSendString, ADDR closeSongCommand, NULL, 0, NULL
	.endif
	Ret
closeSong endp

end start