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
; �û���������
; Receives: hWin�Ǵ��ھ��;uMsg����Ϣ���;wParam����Ϣ����
; Returns: none
;-------------------------------------------------------------------------------------------------------
DlgProc proc hWin:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
	mov	eax,uMsg
	
	.if	eax == WM_INITDIALOG;��ʼ������
		invoke init, hWin
		invoke	LoadIcon,hInstance,200
		invoke	SendMessage, hWin, WM_SETICON, 1, eax
	.elseif eax == WM_COMMAND
		mov	eax,wParam
		.if	eax == IDB_EXIT;�����˳���
			invoke	SendMessage, hWin, WM_CLOSE, 0, 0
		.elseif songMenuSize == 0;���ɸ赥��СΪ0
			Ret;�����������������У�����
		.elseif eax == IDC_PlayButton;�����²���/��ͣ��
			invoke playPause, hWin
		.elseif ax == IDC_SongMenu;���赥
			shr eax,16
			.if ax == LBN_SELCHANGE;ѡ������ı�
				invoke SendDlgItemMessage, hWin, IDC_SongMenu, LB_GETCURSEL, 0, 0;���ȡ��ѡ�е��±�
				invoke changeSong,hWin,eax;�ı����
			.endif
		.elseif eax == IDC_PrevSong;�������һ�׸�
			.if currentSongIndex == 0
				mov eax, songMenuSize
				mov currentSongIndex,eax
			.endif
			dec currentSongIndex
			invoke SendDlgItemMessage,hWin, IDC_SongMenu, LB_SETCURSEL, currentSongIndex, 0;�ı�ѡ����
			invoke changeSong,hWin,currentSongIndex;���Ÿ��׸���
		.elseif eax == IDC_NextSong;�������һ�׸�
			inc currentSongIndex
			mov eax, currentSongIndex
			.if eax == songMenuSize
				mov currentSongIndex,0
			.endif
			invoke SendDlgItemMessage,hWin, IDC_SongMenu, LB_SETCURSEL, currentSongIndex, 0;�ı�ѡ����
			invoke changeSong,hWin,currentSongIndex;���Ÿ��׸���
		.endif
		
	.elseif	eax == WM_CLOSE;�����˳�ʱִ��
		invoke closeSong, hWin
		invoke	EndDialog, hWin, 0
	.endif

	xor	eax,eax
	ret
DlgProc endp

;-------------------------------------------------------------------------------------------------------
; ������ֲ������߼��ϵĳ�ʼ����������г�ʼ������д����������У�
; Receives: hWin�Ǵ��ھ����
; Returns: none
;-------------------------------------------------------------------------------------------------------
init proc hWin:DWORD
	;չʾ�赥�е����и���
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
; ��ĳ�׸�
; Receives: index�Ǹ����ڸ赥���±ꣻ
; Requires: currentStatus == 0 ����ǰ״̬������ֹͣ״̬
; Returns: none
;-------------------------------------------------------------------------------------------------------
openSong proc hWin:DWORD, index:DWORD
	mov eax, index
	mov ebx, TYPE songMenu
	mul ebx;��ʱeax�д洢�˵�index�׸��������songMenu��ƫ�Ƶ�ַ
	invoke wsprintf, ADDR mediaCommand, ADDR openSongCommand, ADDR songMenu[eax]._path
	invoke mciSendString, ADDR mediaCommand, NULL, 0, NULL;�򿪸���
	Ret
openSong endp

;-------------------------------------------------------------------------------------------------------
; �������/��ͣ��ťʱ��Ӧ
; Receives: hWin�Ǵ��ھ����
; Returns: none
;-------------------------------------------------------------------------------------------------------
playPause proc hWin:DWORD
	.if currentStatus == 0;����ǰ״̬Ϊֹͣ״̬
		mov currentStatus, 1;תΪ����״̬
		invoke openSong,hWin, currentSongIndex;
		invoke mciSendString, ADDR playSongCommand, NULL, 0, NULL;���Ÿ���
	.elseif currentStatus == 1;����ǰ״̬Ϊ����״̬
		mov currentStatus, 2;תΪ��ͣ״̬
		invoke mciSendString, ADDR pauseSongCommand, NULL, 0, NULL;��ͣ����
	.elseif currentStatus == 2;����ǰ״̬Ϊ��ͣ״̬
		mov currentStatus, 1;תΪ����״̬
		invoke mciSendString, ADDR resumeSongCommand, NULL, 0, NULL;�ָ���������
	.endif
	Ret
playPause endp

;-------------------------------------------------------------------------------------------------------
; �л�����ʱ��Ӧ
; Receives: hWin�Ǵ��ھ��,newSongIndex���µĸ�����songMenu�е��±�
; Returns: none
;-------------------------------------------------------------------------------------------------------
changeSong proc hWin:DWORD, newSongIndex: DWORD
	invoke closeSong,hWin;�ر�֮ǰ�ĸ���
	;���µ�ǰ��������Ϣ
	mov eax, newSongIndex
	mov currentSongIndex, eax
	invoke openSong,hWin, currentSongIndex;���µĸ���
	mov currentStatus, 1;תΪ����״̬
	invoke mciSendString, ADDR playSongCommand, NULL, 0, NULL;���Ÿ���
	Ret
changeSong endp


;-------------------------------------------------------------------------------------------------------
; �رյ�ǰ�ĸ���
; Receives: hWin�Ǵ��ھ����
; Returns: none
;-------------------------------------------------------------------------------------------------------
closeSong proc hWin:DWORD
	.if currentStatus != 0;��ǰ״̬Ϊ���Ż�����ͣ
		invoke mciSendString, ADDR closeSongCommand, NULL, 0, NULL
	.endif
	Ret
closeSong endp

end start