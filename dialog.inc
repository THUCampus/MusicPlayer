INCLUDE		windows.inc
INCLUDE		user32.inc
INCLUDE		kernel32.inc
INCLUDE		comctl32.inc	;windows common controls
INCLUDE winmm.inc
;INCLUDE song.inc

INCLUDELIB	user32.lib
INCLUDELIB	kernel32.lib
INCLUDELIB	comctl32.lib	;windows common controls
INCLUDELIB winmm.lib

DlgProc		PROTO	:DWORD,:DWORD,:DWORD,:DWORD

Song STRUCT
	_name BYTE ?;歌曲名
	_path BYTE ?;歌曲路径
	_size BYTE ?;歌曲大小
Song ends

.const
IDD_MAIN		EQU 1000
IDB_EXIT		EQU 1001
IDC_PrevSong		EQU 1002;上一首歌的按钮
IDC_PlayButton		EQU 1003;播放按钮
IDC_NextSong		EQU 1004;下一首歌的按钮
IDC_SongMenu		EQU 1005;歌单列表
IDC_STATIC1007		EQU 1007
IDC_STATIC1008		EQU 1008
IDC_TimeSlider		EQU 1006;时间进度条
IDC_VolumnSlider		EQU 1009;音量
IDC_SearchEdit		EQU 1010;关键词搜索输入
IDC_AddSongButton		EQU 1013;导入新的歌曲的按钮

.data
	FileName BYTE "star.mp3",0
	OPENMP3 BYTE "open star.mp3 alias mysong",0
	PLAYMP3 BYTE "play mysong wait",0

.data?
hInstance	dd	?
mediaCommand BYTE ?; 多媒体控制命令
;currentSong Song <"夜空中最亮的星","star.mp3","2">;当前歌曲
currentSong Song <>;当前歌曲