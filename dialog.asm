.386

.model	flat, stdcall
option	casemap :none

INCLUDE		dialog.inc

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
		invoke loadFile, hWin
		invoke init, hWin
		invoke	LoadIcon,hInstance,200
		invoke	SendMessage, hWin, WM_SETICON, 1, eax
	.elseif eax == WM_TIMER;计时器消息
		.if currentStatus == 1
			invoke changeTimeSlider, hWin;更改进度条滑块位置
			invoke repeatControl, hWin;检测是否已经播放完成，若已完成则根据当前循环模式播放相应的歌曲
		.endif
	.elseif eax == WM_HSCROLL;slider消息
		;获取发送消息的Slider的控件号并存在curSlider变量里
		invoke GetDlgCtrlID,lParam
		mov curSlider,eax
		mov ax,WORD PTR wParam;wParam的低位字代表消息类别
		.if curSlider == IDC_VolumeSlider;调节音量
			.if ax == SB_THUMBTRACK;滚动消息
				invoke SendDlgItemMessage, hWin, IDC_SongMenu, LB_GETCURSEL, 0, 0;则获取被选中的下标
				.if eax != -1;当前有歌曲被选中，则发送mcisendstring命令调整音量
					invoke changeVolume,hWin
				.endif
				invoke displayVolume, hWin;设置文字显示音量
			.elseif ax == SB_ENDSCROLL;滚动结束消息
				invoke SendDlgItemMessage, hWin, IDC_SongMenu, LB_GETCURSEL, 0, 0;则获取被选中的下标
				.if eax != -1;当前有歌曲被选中，则发送mcisendstring命令调整音量
					invoke changeVolume,hWin
				.endif
				invoke displayVolume, hWin;设置文字显示音量
			.endif
			
		.elseif curSlider == IDC_TimeSlider;调节进度
			.if ax == SB_ENDSCROLL;滚动结束消息
				invoke SendDlgItemMessage, hWin, IDC_SongMenu, LB_GETCURSEL, 0, 0;则获取被选中的下标
				.if eax != -1;当前有歌曲被选中，则发送mcisendstring命令调整进度
					invoke changeTime, hWin
				.endif
			.endif
		.endif
	.elseif eax == WM_COMMAND
		mov	eax,wParam
		.if	eax == IDB_EXIT;按下退出键
			invoke	SendMessage, hWin, WM_CLOSE, 0, 0
		.elseif eax == IDC_ImportImage;按下导入歌曲键
			invoke addSong, hWin
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
		.elseif eax == IDC_PrevImage;若点击上一首歌
			.if currentSongIndex == 0
				mov eax, songMenuSize
				mov currentSongIndex,eax
			.endif
			dec currentSongIndex
			invoke SendDlgItemMessage,hWin, IDC_SongMenu, LB_SETCURSEL, currentSongIndex, 0;改变选中项
			invoke changeSong,hWin,currentSongIndex;播放该首歌曲
		.elseif eax == IDC_NextImage;若点击下一首歌
			inc currentSongIndex
			mov eax, currentSongIndex
			.if eax == songMenuSize
				mov currentSongIndex,0
			.endif
			invoke SendDlgItemMessage,hWin, IDC_SongMenu, LB_SETCURSEL, currentSongIndex, 0;改变选中项
			invoke changeSong,hWin,currentSongIndex;播放该首歌曲
		.elseif eax == IDC_TrashImage
			invoke deleteSong, hWin
		.elseif eax == IDC_SilenceButton;按下静音按钮
			invoke changeSilencState,hWin
		.endif
		
	.elseif	eax == WM_CLOSE;程序退出时执行
		invoke closeSong, hWin
		invoke saveFile, hWin
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
	.IF ecx > 0
		L1:
			push ecx
			invoke SendDlgItemMessage, hWin, IDC_SongMenu, LB_ADDSTRING, 0, ADDR (Song PTR [esi])._name
			add esi, TYPE songMenu
			pop ecx
		loop L1
	.ENDIF
	
	;初始化音量条范围为0-1000，初始值为1000
	invoke SendDlgItemMessage, hWin, IDC_VolumeSlider, TBM_SETRANGEMIN, 0, 0
	invoke SendDlgItemMessage, hWin, IDC_VolumeSlider, TBM_SETRANGEMAX, 0, sliderLength
	invoke SendDlgItemMessage, hWin, IDC_VolumeSlider, TBM_SETPOS, 1, sliderLength
	
	;设置计时器，每0.5s发送一次计时器消息
	invoke SetTimer, hWin, 1, 500, NULL
	
	;向ComboBox里添加两项循环模式
	invoke SendDlgItemMessage, hWin, IDC_PlayMode, CB_ADDSTRING, 0, addr singleCirculation
	invoke SendDlgItemMessage, hWin, IDC_PlayMode, CB_ADDSTRING, 0, addr listCirculation
	invoke SendDlgItemMessage, hWin, IDC_PlayMode, CB_SETCURSEL, 0, 0;默认选中单曲循环
	
	invoke changePlayButton,hWin, 0
	mov hasSound, 1
	invoke changeSilenceButton,hWin,hasSound
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
; 改变播放按钮
; Receives: hWin是窗口句柄；playing=1表示接下来播放，=0表示接下来不播放
; Returns: none
;-------------------------------------------------------------------------------------------------------
changePlayButton proc hWin:DWORD, playing:BYTE
	.if playing == 0;转到暂停状态
		mov eax, 300
	.else;转到播放状态
		mov eax, 301
	.endif
	invoke LoadImage, hInstance, eax,IMAGE_ICON,32,32,NULL
	invoke SendDlgItemMessage,hWin,IDC_PlayButton, BM_SETIMAGE, IMAGE_ICON, eax;修改按钮
	Ret
changePlayButton endp


;-------------------------------------------------------------------------------------------------------
; 点击播放/暂停按钮时响应
; Receives: hWin是窗口句柄；
; Returns: none
;-------------------------------------------------------------------------------------------------------
playPause proc hWin:DWORD
	.if currentStatus == 0;若当前状态为停止状态
		mov currentStatus, 1;转为播放状态
		invoke SendDlgItemMessage, hWin, IDC_SongMenu, LB_SETCURSEL, currentSongIndex, 0;改变选中项
		invoke openSong,hWin, currentSongIndex;
		invoke mciSendString, ADDR playSongCommand, NULL, 0, NULL;播放歌曲
		invoke changeVolume,hWin;改变音量
		invoke changePlayButton,hWin,1
		
		invoke mciSendString, addr getLengthCommand, addr songLength, 32, NULL;songLength单位是毫秒，例：5分02秒=303601
		invoke StrToInt, addr songLength
		invoke SendDlgItemMessage, hWin, IDC_TimeSlider, TBM_SETRANGEMAX, 0, eax;把进度条改成跟歌曲长度（毫秒数）一样长
		
		;计算当前歌曲的时长（分钟和秒表示）
		invoke StrToInt, addr songLength
		mov edx, 0
		div timeScale
	
		mov edx, 0
		div timeScaleSec
		mov timeMinuteLength, eax
		mov timeSecondLength, edx
	.elseif currentStatus == 1;若当前状态为播放状态
		mov currentStatus, 2;转为暂停状态
		invoke mciSendString, ADDR pauseSongCommand, NULL, 0, NULL;暂停歌曲	
		invoke changePlayButton, hWin, 0
		
	.elseif currentStatus == 2;若当前状态为暂停状态
		mov currentStatus, 1;转为播放状态
		invoke mciSendString, ADDR resumeSongCommand, NULL, 0, NULL;恢复歌曲播放
		invoke changePlayButton,hWin,1
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
	invoke changePlayButton,hWin,1
	invoke mciSendString, ADDR playSongCommand, NULL, 0, NULL;播放歌曲
	invoke changeVolume,hWin;设置音量为当前音量Slider的值
	
	;设置时间进度条最大长度为歌曲长度(毫秒)
	invoke mciSendString, addr getLengthCommand, addr songLength, 32, NULL;songLength单位为毫秒
	invoke StrToInt, addr songLength
	invoke SendDlgItemMessage, hWin, IDC_TimeSlider, TBM_SETRANGEMAX, 0, eax;把进度条改成跟歌曲长度（毫秒数）一样长
	
	;计算当前歌曲的时长（分钟和秒表示）
	invoke StrToInt, addr songLength
	mov edx, 0
	div timeScale
	
	mov edx, 0
	div timeScaleSec
	mov timeMinuteLength, eax
	mov timeSecondLength, edx
	Ret
changeSong endp


;-------------------------------------------------------------------------------------------------------
; 关闭当前的歌曲
; Receives: hWin是窗口句柄；
; Returns: none
;-------------------------------------------------------------------------------------------------------
closeSong proc uses eax hWin:DWORD 
	.if currentStatus != 0;当前状态为播放或者暂停
		invoke mciSendString, ADDR closeSongCommand, NULL, 0, NULL
	.endif
	Ret
closeSong endp

;-------------------------------------------------------------------------------------------------------
; 导入新的歌曲
; hWin是窗口句柄；
; Returns: none
;-------------------------------------------------------------------------------------------------------
addSong proc uses eax ebx esi edi hWin:DWORD
	LOCAL nLen: DWORD
	LOCAL curOffset: DWORD
	LOCAL originOffset: DWORD
	LOCAL curSize: DWORD
	mov al,0
	mov edi, OFFSET openfilename
	mov ecx, SIZEOF openfilename
	cld
	rep stosb
	mov openfilename.lStructSize, SIZEOF openfilename
	mov eax, hWin
	mov openfilename.hwndOwner, eax
	mov eax, OFN_ALLOWMULTISELECT
	or eax, OFN_EXPLORER
	mov openfilename.Flags, eax
	mov openfilename.nMaxFile, nMaxFile
	mov openfilename.lpstrTitle, OFFSET szLoadTitle
	mov openfilename.lpstrInitialDir, OFFSET szInitDir
	mov openfilename.lpstrFile, OFFSET szOpenFileNames
	invoke GetOpenFileName, ADDR openfilename
	.IF eax == 1
		invoke lstrcpyn, ADDR szPath, ADDR szOpenFileNames, openfilename.nFileOffset
		invoke lstrlen, ADDR szPath
		mov nLen, eax
		mov ebx, eax
		mov al, szPath[ebx]
		.IF al != sep
			mov al, sep
			mov szPath[ebx], al
			mov szPath[ebx + 1], 0
		.ENDIF
		mov ebx, songMenuSize
		mov curSize, ebx
		mov edi, OFFSET songMenu
		mov eax, SIZEOF Song
		mul ebx
		add edi, eax
		mov curOffset, edi
		mov originOffset, edi
		mov esi, OFFSET szOpenFileNames
		mov eax, 0
		mov ax, openfilename.nFileOffset
		add esi, eax
		mov al, [esi]
		.WHILE al != 0
			mov szFileName, 0
			invoke lstrcat, ADDR szFileName, ADDR szPath
			invoke lstrcat, ADDR szFileName, esi
			mov edi, curOffset
			add curOffset, SIZEOF Song
			invoke lstrcpy, edi, esi
			add edi, 100
			invoke lstrcpy, edi, ADDR szFileName
			invoke lstrlen, esi
			inc eax
			add esi, eax
			add songMenuSize, 1
			mov al, [esi]
		.ENDW
		mov esi, originOffset
		mov ecx, songMenuSize
		sub ecx, curSize
		.IF ecx > 0
			L1:
				push ecx
				invoke SendDlgItemMessage, hWin, IDC_SongMenu, LB_ADDSTRING, 0, ADDR (Song PTR [esi])._name
				add esi, TYPE songMenu
				pop ecx
			loop L1
		.ENDIF
	.ENDIF
	ret
addSong endp

;-------------------------------------------------------------------------------------------------------
; 从歌单文件读取歌曲
; hWin是窗口句柄；
; Returns: none
;-------------------------------------------------------------------------------------------------------
loadFile proc uses eax hWin:DWORD
	LOCAL hFile: DWORD
	LOCAL bytesRead: DWORD
	invoke crt__getcwd, ADDR szBaseDir, SIZEOF szBaseDir
	invoke lstrcpy, ADDR szFileName, ADDR szBaseDir
	invoke lstrcat, ADDR szFileName, ADDR songMenuFilename
	INVOKE CreateFile, ADDR szFileName, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
	mov hFile, eax
	.IF hFile == INVALID_HANDLE_VALUE
		mov songMenuSize, 0
	.ELSE
		INVOKE ReadFile, hFile, ADDR songMenuSize, SIZEOF songMenuSize, ADDR bytesRead, NULL
		.IF bytesRead != SIZEOF songMenuSize
			mov songMenuSize, 0
		.ELSE
			INVOKE ReadFile, hFile, ADDR songMenu, SIZEOF songMenu, ADDR bytesRead, NULL
			.IF bytesRead != SIZEOF songMenu
				mov songMenuSize, 0
			.ENDIF
		.ENDIF
	.ENDIF
	INVOKE CloseHandle, hFile
	ret
loadFile endp

;-------------------------------------------------------------------------------------------------------
; 保存歌曲列表到文件
; hWin是窗口句柄；
; Returns: none
;-------------------------------------------------------------------------------------------------------
saveFile proc hWin:DWORD
	LOCAL hFile: HANDLE
	LOCAL bytesWritten: DWORD
	invoke lstrcat, ADDR szBaseDir, ADDR songMenuFilename
	INVOKE CreateFile, ADDR szBaseDir, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
	mov hFile, eax
	.IF hFile == INVALID_HANDLE_VALUE
		ret
	.ENDIF
	INVOKE WriteFile, hFile, ADDR songMenuSize, SIZEOF songMenuSize, ADDR bytesWritten, NULL
	INVOKE WriteFile, hFile, ADDR songMenu, SIZEOF songMenu, ADDR bytesWritten, NULL
	INVOKE CloseHandle, hFile
	ret
saveFile endp

;-------------------------------------------------------------------------------------------------------
; 删除歌曲列表中选中的曲子
; hWin是窗口句柄；
; Returns: none
;-------------------------------------------------------------------------------------------------------
deleteSong proc hWin: DWORD
	invoke SendDlgItemMessage, hWin, IDC_SongMenu, LB_GETCURSEL, 0, 0;则获取被选中的下标
	.IF eax == -1
		invoke MessageBox, hWin, ADDR szWarning, ADDR szWarningTitle, MB_OK
	.ELSE
		push eax
		invoke SendDlgItemMessage, hWin, IDC_SongMenu, LB_DELETESTRING, eax, 0
		pop eax
		mov ebx, eax
		add ebx, 1
		mov edi, OFFSET songMenu
		mov edx, SIZEOF Song
		mul edx
		add edi, eax
		mov esi, edi
		add esi, SIZEOF Song
		.while ebx < songMenuSize
			mov ecx, SIZEOF Song
			cld
			rep movsb
			add ebx, 1
		.endw
		sub songMenuSize, 1
	.ENDIF
	ret
deleteSong endp

;-------------------------------------------------------------------------------------------------------
; 改变音量
; hWin是窗口句柄；
; Returns: none
;-------------------------------------------------------------------------------------------------------
changeVolume proc hWin:	DWORD
	invoke SendDlgItemMessage,hWin,IDC_VolumeSlider,TBM_GETPOS,0,0;获取当前Slider游标位置
	.if hasSound == 1
		invoke wsprintf, addr mediaCommand, addr adjustVolumeCommand, eax
	.else
		invoke wsprintf, addr mediaCommand, addr adjustVolumeCommand, 0
	.endif
	invoke mciSendString, addr mediaCommand, NULL, 0, NULL
	Ret
changeVolume endp


;-------------------------------------------------------------------------------------------------------
; 改变静音按钮
; Receives: hWin是窗口句柄；playing=1表示接下来有声音，=0表示接下来没有声音
; Returns: none
;-------------------------------------------------------------------------------------------------------
changeSilenceButton proc hWin:DWORD, _hasSound:BYTE
	.if _hasSound == 0;转到暂停状态
		mov eax, 305
	.else;转到播放状态
		mov eax, 304
	.endif
	invoke LoadImage, hInstance, eax,IMAGE_ICON,32,32,NULL
	invoke SendDlgItemMessage,hWin,IDC_SilenceButton, BM_SETIMAGE, IMAGE_ICON, eax;修改按钮
	Ret
changeSilenceButton endp


;-------------------------------------------------------------------------------------------------------
; 切换是否为静音的状态
; hWin是窗口句柄；
; Returns: none
;-------------------------------------------------------------------------------------------------------
changeSilencState proc hWin: DWORD
	.if hasSound == 1
		mov hasSound, 0
		invoke changeSilenceButton,hWin, hasSound
	.else
		mov hasSound,1
		invoke changeSilenceButton,hWin,hasSound
	.endif
	invoke changeVolume,hWin
	Ret
changeSilencState endp

;-------------------------------------------------------------------------------------------------------
; 改变音量显示的数值
; hWin是窗口句柄；
; Returns: none
;-------------------------------------------------------------------------------------------------------
displayVolume proc hWin: DWORD
	local extend32: DWORD
	invoke SendDlgItemMessage,hWin,IDC_VolumeSlider,TBM_GETPOS,0,0;获取当前Slider游标位置
	;设置文字显示音量
	mov extend32, 10
	mov edx, 0
	div extend32
	invoke wsprintf, addr mediaCommand, addr int2str, eax
	invoke SendDlgItemMessage, hWin, IDC_VolumeDisplay, WM_SETTEXT, 0, addr mediaCommand
	Ret
displayVolume endp

;-------------------------------------------------------------------------------------------------------
; 当前为播放状态时，根据播放进度改变进度条
; hWin是窗口句柄；
; Returns: none
;-------------------------------------------------------------------------------------------------------
changeTimeSlider proc hWin: DWORD
	local temp: DWORD
	.if currentStatus == 1;若当前为播放状态
		invoke mciSendString, addr getPositionCommand, addr songPosition, 32, NULL;获取当前播放位置
		invoke StrToInt, addr songPosition;当前进度转成int存在eax里
		mov temp, eax
		invoke SendDlgItemMessage, hWin, IDC_TimeSlider, TBM_SETPOS, 1, temp
		invoke displayTime, hWin, temp
	.endif
	Ret
changeTimeSlider endp

;-------------------------------------------------------------------------------------------------------
; 进度条的滑块位置被改变时触发，根据进度条改变播放进度
; 如果当前是播放状态，那么将跳转到相应进度；如果当前是暂停状态，那么将转为播放状态并跳转到相应进度；如果当前为停止状态则不做任何事情
; hWin是窗口句柄；
; Returns: none
;-------------------------------------------------------------------------------------------------------
changeTime proc hWin: DWORD
	invoke SendDlgItemMessage,hWin,IDC_TimeSlider,TBM_GETPOS,0,0;获取当前Slider游标位置
	invoke wsprintf, addr mediaCommand, addr setPositionCommand, eax
	invoke mciSendString, addr mediaCommand, NULL, 0, NULL
	.if currentStatus == 1;播放状态
		invoke mciSendString, addr playSongCommand, NULL, 0, NULL
	.elseif currentStatus == 2;暂停状态
		invoke mciSendString, addr playSongCommand, NULL, 0, NULL
		invoke SendDlgItemMessage, hWin, IDC_PlayButton, WM_SETTEXT, 0, addr buttonPause;修改按钮文字
		mov currentStatus, 1;转为播放状态
	.endif
	Ret
changeTime endp

;-------------------------------------------------------------------------------------------------------
; 根据进度条改变窗口中显示的数字
; hWin是窗口句柄, currentPosition是当前播放位置（整数；单位：毫秒）
; Returns: none
;-------------------------------------------------------------------------------------------------------
displayTime proc hWin: DWORD, currentPosition: DWORD
	;计算当前歌曲的进度（分钟和秒表示）
	mov eax, currentPosition
	mov edx, 0
	div timeScale
	
	mov edx, 0
	div timeScaleSec
	mov timeMinutePosition, eax
	mov timeSecondPosition, edx
	invoke wsprintf, addr mediaCommand, addr timeDisplay, timeMinutePosition, timeSecondPosition, timeMinuteLength, timeSecondLength
	invoke SendDlgItemMessage, hWin, IDC_TimeDisplay, WM_SETTEXT, 0, addr mediaCommand;修改文字 
	Ret
displayTime endp

;-------------------------------------------------------------------------------------------------------
; 根据进度条改变窗口中显示的数字
; hWin是窗口句柄；
; Returns: none
;-------------------------------------------------------------------------------------------------------
repeatControl proc hWin: DWORD
	local temp: DWORD
	.if currentStatus == 1;播放状态
		invoke StrToInt, addr songLength
		mov temp, eax
		invoke StrToInt, addr songPosition
		.if eax == temp;播放完了
			invoke SendDlgItemMessage, hWin, IDC_PlayMode, CB_GETCURSEL, 0, 0;查看当前选中的项的序号，0代表单曲循环，1代表列表循环
			.if eax == SINGLE_REPEAT;单曲循环
				invoke mciSendString, addr setPosToStartCommand, NULL, 0, NULL;定位到歌曲开头
				invoke mciSendString, addr playSongCommand, NULL, 0, NULL
			.elseif eax == LIST_REPEAT;列表循环
				invoke SendMessage, hWin, WM_COMMAND, IDC_NextImage, 0;发送消息，模拟点击了"下一首"按钮
			.endif
		.endif
	.endif
	Ret
repeatControl endp

end start