INCLUDE		windows.inc
INCLUDE		user32.inc
INCLUDE		kernel32.inc
INCLUDE		comctl32.inc	;windows common controls
INCLUDE		winmm.inc
INCLUDE		comdlg32.inc
INCLUDE		msvcrt.inc
INCLUDE 	shlwapi.inc
INCLUDE 	msvcrt.inc

INCLUDELIB  shlwapi.lib
INCLUDELIB	user32.lib
INCLUDELIB	kernel32.lib
INCLUDELIB	comctl32.lib	;windows common controls
INCLUDELIB	winmm.lib
INCLUDELIB	msvcrt.lib
INCLUDELIB  comdlg32.lib


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

accDecoder PROTO: DWORD, :DWORD;将acc解码成wav
changePlayButton PROTO :DWORD, :BYTE

changeSilenceButton PROTO :DWORD, :BYTE
changeSilencState PROTO : DWORD

;歌曲结构体
Song STRUCT
	_name BYTE 100 DUP(0);歌曲名
	_path BYTE 100 DUP(0);歌曲路径
Song ends

.const
	IDD_MAIN			EQU 1000
	IDB_EXIT			EQU 1001
	;IDC_PrevSong		EQU 1002;上一首歌的按钮
	IDC_PlayButton		EQU 1003;播放按钮
	;IDC_NextSong		EQU 1004;下一首歌的按钮
	IDC_STATIC1007		EQU 1007
	IDC_STATIC1008		EQU 1008
	IDC_TimeSlider		EQU 1006;时间进度条
	IDC_VolumeSlider	EQU 1009;音量
	IDC_SearchEdit		EQU 1010;关键词搜索输入
	;IDC_AddSongButton	EQU 1013;导入新的歌曲的按钮
	IDC_SongMenu		EQU 1016;歌单列表
	;IDC_DeleteSong      EQU 1017;删除歌曲
	IDC_VolumeDisplay	EQU 1019;音量显示
	IDC_PlayMode		EQU 1023;循环模式
	IDC_TimeDisplay		EQU 1024;进度显示
	
	;IDC_PlayImage		EQU 1025;播放键的图片
	IDC_PrevImage		EQU 1028;上一首歌的图片
	IDC_NextImage		EQU 1029;下一首歌的图片
	IDC_ImportImage		EQU 1030;载入本地歌曲的图片
	IDC_TrashImage		EQU 1031;删除歌曲的图片
	IDC_SearchImage		EQU 1032;查询按钮
	IDC_LyricsImage		EQU 1033;歌词按钮
	IDC_VolumeImage		EQU 1034;音量按钮
	IDC_SilenceButton		EQU 1043;静音按钮
	IDC_RecycleButton		EQU 1044;循环模式按钮
	
	MAX_SONG_MENU_SIZE 	EQU 100
	
	SINGLE_REPEAT		EQU 0;单曲循环
	LIST_REPEAT			EQU 1;列表循环
	
.data	
	openSongCommand BYTE 'open "%s" alias currentSong',0;打开歌曲命令
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
	songMenuSize DWORD 0;歌单大小】
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
	
.data?
	hInstance	dd	?
	mediaCommand BYTE ?; 多媒体控制命令(mciSendString需要附加参数时使用）
	hButton dd ?

 