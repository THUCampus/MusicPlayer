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
	
	.if	eax == WM_INITDIALOG
		invoke	LoadIcon,hInstance,200
		invoke	SendMessage, hWin, WM_SETICON, 1, eax
	.elseif eax == WM_COMMAND
		mov	eax,wParam
		.if	eax == IDB_EXIT;�����˳���
			invoke	SendMessage, hWin, WM_CLOSE, 0, 0
		.elseif eax == IDC_PlayButton;���²���/��ͣ��
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
; ������ֲ������߼��ϵĳ�ʼ��
; Receives: none
; Returns: none
;-------------------------------------------------------------------------------------------------------
init proc
	Ret
init endp

;-------------------------------------------------------------------------------------------------------
; �������/��ͣ��ťʱ��Ӧ
; Receives: hWin�Ǵ��ھ����
; Returns: none
;-------------------------------------------------------------------------------------------------------
play proc hWin:DWORD
	.if currentStatus == 0;����ǰ״̬Ϊֹͣ״̬
		mov currentStatus, 1;תΪ����״̬
		invoke wsprintf, ADDR mediaCommand, ADDR openSong, ADDR currentSong._path
		;invoke MessageBox,hWin, ADDR mediaCommand, ADDR mediaCommand, MB_OK
		invoke mciSendString, ADDR mediaCommand, NULL, 0, NULL;�򿪸���
		invoke mciSendString, ADDR playSong, NULL, 0, NULL;���Ÿ���
	.elseif currentStatus == 1;����ǰ״̬Ϊ����״̬
		mov currentStatus, 2;תΪ��ͣ״̬
		invoke mciSendString, ADDR pauseSong, NULL, 0, NULL;��ͣ����
	.elseif currentStatus == 2;����ǰ״̬Ϊ��ͣ״̬
		mov currentStatus, 1;תΪ����״̬
		invoke mciSendString, ADDR resumeSong, NULL, 0, NULL;�ָ���������
	.endif
	Ret
play endp

;-------------------------------------------------------------------------------------------------------
; �˳�����ʱ��Ӧ
; Receives: none
; Returns: none
;-------------------------------------------------------------------------------------------------------
stop proc hWin:DWORD
	.if currentStatus != 0;��ǰ״̬Ϊ���Ż�����ͣ
		invoke mciSendString, ADDR closeSong, NULL, 0, NULL
	.endif
	Ret
stop endp

end start