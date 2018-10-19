INCLUDE		windows.inc
INCLUDE		user32.inc
INCLUDE		kernel32.inc
INCLUDE		comctl32.inc	;windows common controls
INCLUDE		winmm.inc
INCLUDE		comdlg32.inc
INCLUDE		msvcrt.inc

;INCLUDE song.inc
INCLUDE msvcrt.inc

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
changeVolume PROTO	:DWORD

;歌曲结构体
Song STRUCT
	_name BYTE 100 DUP(0);歌曲名
	_path BYTE 100 DUP(0);歌曲路径
Song ends

.const
	IDD_MAIN		EQU 1000
	IDB_EXIT		EQU 1001
	IDC_PrevSong		EQU 1002;上一首歌的按钮
	IDC_PlayButton		EQU 1003;播放按钮
	IDC_NextSong		EQU 1004;下一首歌的按钮
	IDC_STATIC1007		EQU 1007
	IDC_STATIC1008		EQU 1008
	IDC_TimeSlider		EQU 1006;时间进度条
	IDC_VolumeSlider		EQU 1009;音量
	IDC_SearchEdit		EQU 1010;关键词搜索输入
	IDC_AddSongButton		EQU 1013;导入新的歌曲的按钮
	IDC_SongMenu		EQU 1016;歌单列表
	IDC_DeleteSong      EQU 1017;删除歌曲
	IDC_STATIC1018		EQU 1018;htxtest
	
	MAX_SONG_MENU_SIZE EQU 100
	
.data	
	openSongCommand BYTE 'open "%s" alias currentSong',0;打开歌曲命令
	playSongCommand BYTE "play currentSong", 0;播放歌曲命令
	pauseSongCommand BYTE "pause currentSong",0;暂停歌曲命令
	resumeSongCommand BYTE "resume currentSong",0;恢复歌曲播放命令
	closeSongCommand BYTE "close currentSong",0;关闭当前歌曲命令
	songMenuFilename BYTE "\\song.dat",0 ;歌单保存位置
	adjustVolumeCommand BYTE "setaudio currentSong volume to %d",0;调整音量命令
	
	debug BYTE 'haha%s%s%dheihei',0;调试信息
	debugint BYTE '%d',0
	htxtest BYTE "htxtest",0
	integertest BYTE 48
	wsprintftest BYTE 100 DUP(0)
	htxtesttimes DWORD 0
	curSlider DWORD ?

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

.data?
	hInstance	dd	?
	mediaCommand BYTE ?; 多媒体控制命令(mciSendString需要附加参数时使用）

 