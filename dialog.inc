INCLUDE		windows.inc
INCLUDE		user32.inc
INCLUDE		kernel32.inc
INCLUDE		comctl32.inc	;windows common controls
INCLUDE winmm.inc
INCLUDE song.inc
INCLUDE msvcrt.inc

INCLUDELIB	user32.lib
INCLUDELIB	kernel32.lib
INCLUDELIB	comctl32.lib	;windows common controls
INCLUDELIB winmm.lib
INCLUDELIB msvcrt.lib

;请将函数声明写在此处
DlgProc		PROTO	:DWORD,:DWORD,:DWORD,:DWORD
init PROTO :DWORD
openSong PROTO:DWORD, :DWORD
playPause PROTO :DWORD
closeSong PROTO :DWORD
changeSong PROTO :DWORD, :DWORD

.const
	IDD_MAIN		EQU 1000
	IDB_EXIT		EQU 1001
	IDC_PrevSong		EQU 1002;上一首歌的按钮
	IDC_PlayButton		EQU 1003;播放按钮
	IDC_NextSong		EQU 1004;下一首歌的按钮
	IDC_STATIC1007		EQU 1007
	IDC_STATIC1008		EQU 1008
	IDC_TimeSlider		EQU 1006;时间进度条
	IDC_VolumnSlider		EQU 1009;音量
	IDC_SearchEdit		EQU 1010;关键词搜索输入
	IDC_AddSongButton		EQU 1013;导入新的歌曲的按钮
	IDC_SongMenu		EQU 1016;歌单列表
	
.data	
	openSongCommand BYTE "open %s alias currentSong",0;打开歌曲命令
	playSongCommand BYTE "play currentSong", 0;播放歌曲命令
	pauseSongCommand BYTE "pause currentSong",0;暂停歌曲命令
	resumeSongCommand BYTE "resume currentSong",0;恢复歌曲播放命令
	closeSongCommand BYTE "close currentSong",0;关闭当前歌曲命令
	
	debug BYTE "%d",0;调试信息

	currentStatus BYTE 0;当前的播放状态
	;0:停止状态
	;1:播放状态
	;2:暂停状态
	currentSongIndex DWORD 0;当前歌曲在歌单中的下标
	
	;---歌单信息,暂时将其内容直接写在代码中---
	songMenu Song <"夜空中最亮的星","Music/star.mp3">,
	<"平凡之路","Music/road.mp3">,
	<"阳光宅男","Music/sun.mp3">
	songMenuSize DWORD 3;歌单大小
	;---歌单信息---

.data?
	hInstance	dd	?
	mediaCommand BYTE ?; 多媒体控制命令(mciSendString需要附加参数时使用）

