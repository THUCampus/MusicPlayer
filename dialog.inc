INCLUDE		windows.inc
INCLUDE		user32.inc
INCLUDE		kernel32.inc
INCLUDE		comctl32.inc	;windows common controls
INCLUDE		winmm.inc
INCLUDE		comdlg32.inc
INCLUDE		msvcrt.inc
INCLUDE 	shlwapi.inc
INCLUDE 	msvcrt.inc
INCLUDE gdi32.inc
INCLUDE gdiplus.inc
INCLUDE wsock32.inc

INCLUDELIB  shlwapi.lib
INCLUDELIB	user32.lib
INCLUDELIB	kernel32.lib
INCLUDELIB	comctl32.lib	;windows common controls
INCLUDELIB	winmm.lib
INCLUDELIB	msvcrt.lib
INCLUDELIB  comdlg32.lib
INCLUDELIB gdi32.lib
INCLUDELIB gdiplus.lib
INCLUDELIB wsock32.lib

;请将函数声明写在此处
DlgProc		PROTO	:DWORD,:DWORD,:DWORD,:DWORD
init PROTO :DWORD
openSong PROTO:DWORD, :DWORD
playPause PROTO :DWORD
closeSong PROTO :DWORD
changeSong PROTO :DWORD, :DWORD
addSong PROTO :DWORD
deleteSong PROTO :DWORD
loadFile PROTO :DWORD
saveFile PROTO :DWORD
changeVolume PROTO :DWORD
displayVolume PROTO	:DWORD
changeTimeSlider PROTO  :DWORD
changeTime PROTO  :DWORD
repeatControl PROTO  :DWORD
displayTime PROTO  :DWORD, :DWORD

changeSilenceButton PROTO :DWORD, :BYTE
changeSilencState PROTO : DWORD

changeRecycleButton PROTO :DWORD
changeRecycleState PROTO : DWORD

searchSong PROTO: DWORD
changePlayButton PROTO :DWORD, :BYTE
displaySearchResult PROTO :DWORD
downloadSong PROTO :DWORD

replaceChar PROTO, :PTR BYTE, :DWORD,:BYTE, :BYTE

readLrcFile PROTO:DWORD, :DWORD
displayLyric PROTO:DWORD
switchLyricDisplay PROTO:DWORD

;歌曲结构体
Song STRUCT
	_name BYTE 100 DUP(0);歌曲名
	_path BYTE 100 DUP(0);歌曲路径
Song ends

;搜索结果结构体
SearchResult STRUCT
	_name BYTE 100 DUP(0);歌曲名（包括歌手）
	_id BYTE 20 DUP(0);歌曲id
SearchResult ends

;酷我音乐lrc文件歌词结构体
Lyric STRUCT
	_sentence BYTE 100 DUP(0);歌词
	_time DWORD 0;歌词开始位置（单位：毫秒）
Lyric ends

RGB macro red,green,blue
	xor eax,eax
	mov ah,blue
	shl eax,8
	mov ah,green
	mov al,red
endm

.const
	IDD_MAIN			EQU 1000
	IDB_EXIT			EQU 1001
	IDC_PlayButton		EQU 1003;播放按钮
	IDC_STATIC1007		EQU 1007
	IDC_STATIC1008		EQU 1008
	IDC_TimeSlider		EQU 1006;时间进度条
	IDC_VolumeSlider	EQU 1009;音量
	IDC_SearchEdit		EQU 1010;关键词搜索输入
	IDC_SongMenu		EQU 1016;歌单列表
	IDC_VolumeDisplay	EQU 1019;音量显示
	IDC_TimeDisplay		EQU 1024;进度显示
	
	IDC_PrevImage		EQU 1028;上一首歌的图片
	IDC_NextImage		EQU 1029;下一首歌的图片
	IDC_ImportImage		EQU 1030;载入本地歌曲的图片
	IDC_TrashImage		EQU 1031;删除歌曲的图片
	IDC_SearchImage		EQU 1032;查询按钮
	IDC_LyricsImage		EQU 1033;歌词按钮
	IDC_SilenceButton		EQU 1043;静音按钮
	IDC_RecycleButton		EQU 1044;循环模式按钮
	IDC_LyricsEdit		EQU 1052;歌词显示
	IDC_SearchSongList		EQU 1053;搜索结果的展示
	IDC_refreshImage		EQU 1056;搜索结果刷新

	MAX_SONG_MENU_SIZE 	EQU 100
	
	SINGLE_REPEAT		EQU 0;单曲循环
	LIST_REPEAT			EQU 1;列表循环
	WM_SHELLNOTIFY    	equ WM_USER+5 
	
.data	
	openSongCommand BYTE 'open "%s" alias currentSong type mpegvideo',0;打开歌曲命令
	playSongCommand BYTE "play currentSong", 0;播放歌曲命令
	pauseSongCommand BYTE "pause currentSong",0;暂停歌曲命令
	resumeSongCommand BYTE "resume currentSong",0;恢复歌曲播放命令
	closeSongCommand BYTE "close currentSong",0;关闭当前歌曲命令
	songMenuFilename BYTE "\\song.dat",0 ;歌单保存位置
	adjustVolumeCommand BYTE "setaudio currentSong volume to %d",0;调整音量命令
	getLengthCommand BYTE "status currentSong length", 0;获取歌曲长度命令
	getPositionCommand BYTE "status currentSong position", 0;获取歌曲当前播放位置命令
	setPositionCommand BYTE "seek currentSong to %d", 0;设置歌曲当前播放位置命令
	setPosToStartCommand BYTE "seek currentSong to start", 0;设置歌曲当前播放位置到开头
	
	debug BYTE '%d',0;调试信息
	int2str BYTE '%d',0;int转str辅助用
	curSlider DWORD ?;当前发送消息的进度条
	songLength BYTE 32 dup(0);当前歌曲长度（单位：毫秒）
	songPosition BYTE 32 dup(0);当前播放进度（单位：毫秒）
	sliderLength DWORD 1000;音量条长度
	singleCirculation BYTE "单曲循环", 0
	listCirculation BYTE "列表循环", 0
	timeScale DWORD 1000;秒和毫秒进制
	timeScaleSec DWORD 60;秒和分钟进制
	timeMinutePosition DWORD 0;当前歌曲长度（分钟取整）
	timeSecondPosition DWORD 0;当前歌曲长度（秒取整）
	timeMinuteLength DWORD 0;当前歌曲进度（分钟取整）
	timeSecondLength DWORD 0;当前歌曲进度（秒取整）
	timeDisplay BYTE "%d:%d/%d:%d", 0;用于进度显示
	isDraggingTimeSlider DWORD 0;是否正在拖动进度条，0-否，1-是
		
	;播放/暂停按钮文字
	buttonPlay BYTE "播放", 0
	buttonPause BYTE "暂停", 0
	
	repeatStatus BYTE 0;当前的循环模式
	;0:列表循环
	;1:单曲循环
	
	currentStatus BYTE 0;当前的播放状态
	;0:停止状态
	;1:播放状态
	;2:暂停状态
	currentSongIndex DWORD 0;当前歌曲在歌单中的下标
	
	;---歌单信息,将其内容写在文件中---
	songMenu Song 100 dup(<"1", "1">)
	songMenuSize DWORD 0;歌单大小
	;---歌单信息---
	
	;---打开文件对话框---
	openfilename OPENFILENAME <>
	szLoadTitle BYTE '选择歌曲', 0
	szInitDir BYTE '\\', 0
	szOpenFileNames BYTE 8000 DUP(0)
	szFileName BYTE 100 DUP(0)
	szPath BYTE 100 DUP(0)
	nMaxFile = SIZEOF szOpenFileNames
	szBaseDir BYTE 256 DUP(0)
	sep BYTE '\\'
	szWarningTitle BYTE 'Warning', 0
	szWarning BYTE '请选择要删除的歌曲', 0
	;---打开文件对话框---
	
	hasSound BYTE 1;是否有声音
	
	searchInputText DB 50 DUP(0);搜索栏输入文本
	searchResults SearchResult 20 dup(<"1","1">);搜索结果
	
	lyricArray Lyric 500 dup(<>);存储当前播放歌曲的歌词信息的数组
	lyricLines dword 0;当前播放歌曲总共的歌词行数
	
	lyricAddrs dword 1000 dup(0);每句歌词地址
	lyricTimes dword 1000 dup(0);每句歌词对应的时间
	currentLyricIndex dword 0;现在到了第几句歌词（从下标0开始）
	maxLyricIndex dword 0;当前歌曲最大的歌词下标（歌词行数减1）
	
	lyricNextSentence byte "[", 0
	hasLyric byte 0;当前歌曲是否有对应的歌词文件，有=1，无=0
	noLyricText byte "暂无歌词",0
	longStr byte 1000 dup(0)
	lrcSuffix byte ".lrc", 0
	point byte ".", 0
	lrcBuffer byte 100000 dup(0)
	lrcFile byte 1000 dup(0)
	actualReadBytes dword 0
	lyricPreparation byte "······",0
	lyricVisible dword 1;是否显示歌词
	lyricEmpty byte 0;不显示歌词时用的字符串
	
	guiWorkingDir BYTE 200 DUP(0);GUI主程序的工作路径
.data?
	hInstance	dd	?
	mediaCommand BYTE ?; 多媒体控制命令(mciSendString需要附加参数时使用）
	hButton dd ?

 