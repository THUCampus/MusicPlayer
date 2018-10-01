include		windows.inc
include		user32.inc
include		kernel32.inc
include		comctl32.inc	;windows common controls
INCLUDE winmm.inc

includelib	user32.lib
includelib	kernel32.lib
includelib	comctl32.lib	;windows common controls
INCLUDELIB winmm.lib

DlgProc		PROTO	:DWORD,:DWORD,:DWORD,:DWORD

.const
IDD_MAIN		EQU 1000
IDB_EXIT		EQU 1001
IDC_PrevSong		EQU 1002
IDC_PlayButton		EQU 1003
IDC_NextSong		EQU 1004

.data
	FileName BYTE "star.mp3",0
	OPENMP3 BYTE "open star.mp3 alias mysong",0
	PLAYMP3 BYTE "play mysong wait",0

.data?
hInstance	dd	?