.386

.model	flat, stdcall
option	casemap :none

include		dialog.inc

;18/10/19 todo list:
;��ȡ����������Ͻ��������ڵ�������
;�÷��ӣ������ʽ��ʾ��ǰ����
;ʵ�ֵ���ѭ����ֱ����mci���
;ʵ���б�ѭ����д��������

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
		invoke loadFile, hWin
		invoke init, hWin
		invoke	LoadIcon,hInstance,200
		invoke	SendMessage, hWin, WM_SETICON, 1, eax
		
		;htxtest
		;invoke wsprintf,addr wsprintftest,addr debug,addr playSongCommand,addr playSongCommand,integertest
		;invoke MessageBox,hWin,addr wsprintftest, addr htxtest, MB_OK
		;htxtest over
		
	.elseif eax == WM_HSCROLL;slider��Ϣ
		;todo htx
		;��ȡ������Ϣ��Slider�Ŀؼ��Ų�����curSlider������
		invoke GetDlgCtrlID,lParam
		mov curSlider,eax
		
		mov ax,WORD PTR wParam;wParam�ĵ�λ�ִ�����Ϣ���
		.if curSlider == IDC_VolumeSlider;��������
			.if ax == SB_THUMBTRACK;������Ϣ
				invoke SendDlgItemMessage, hWin, IDC_SongMenu, LB_GETCURSEL, 0, 0;���ȡ��ѡ�е��±�
				.if eax != -1;��ǰ�и�����ѡ�У�����mcisendstring�����������
					invoke changeVolume,hWin
				.endif
				;����������ʾ����
				invoke displayVolume, hWin
			.elseif ax == SB_ENDSCROLL;����������Ϣ
				invoke SendDlgItemMessage, hWin, IDC_SongMenu, LB_GETCURSEL, 0, 0;���ȡ��ѡ�е��±�
				.if eax != -1;��ǰ�и�����ѡ�У�����mcisendstring�����������
					invoke changeVolume,hWin
				.endif
				;����������ʾ����
				invoke displayVolume, hWin
			
			;invoke SendDlgItemMessage,hWin,curSlider,TBM_GETPOS,0,0
			;invoke wsprintf,addr wsprintftest,addr int2str,eax
			;invoke MessageBox,hWin,addr wsprintftest,addr htxtest,MB_OK
			.endif
			
		.elseif curSlider == IDC_TimeSlider;���ڽ���
			.if ax == SB_THUMBTRACK;����������Ϣ
			inc htxtesttimes
			;invoke MessageBox,hWin,addr wsprintftest, addr htxtest, MB_OK
			.elseif ax == SB_ENDSCROLL
			
			;invoke wsprintf,addr wsprintftest,addr int2str,htxtesttimes
			;invoke MessageBox,hWin,addr wsprintftest,addr htxtest,MB_OK
			invoke SendDlgItemMessage,hWin,curSlider,TBM_GETPOS,0,0
			invoke wsprintf,addr wsprintftest,addr int2str,eax
			invoke MessageBox,hWin,addr wsprintftest,addr htxtest,MB_OK
			.endif
		.endif
		
		
		
	.elseif eax == WM_COMMAND
		mov	eax,wParam
		.if	eax == IDB_EXIT;�����˳���
			invoke	SendMessage, hWin, WM_CLOSE, 0, 0
		.elseif eax == IDC_AddSongButton;���µ��������
			invoke addSong, hWin
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
		.elseif eax == IDC_DeleteSong
			invoke deleteSong, hWin
		.endif
		
	.elseif	eax == WM_CLOSE;�����˳�ʱִ��
		invoke closeSong, hWin
		invoke saveFile, hWin
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
	.IF ecx > 0
		L1:
			push ecx
			invoke SendDlgItemMessage, hWin, IDC_SongMenu, LB_ADDSTRING, 0, ADDR (Song PTR [esi])._name
			add esi, TYPE songMenu
			pop ecx
		loop L1
	.ENDIF
	
	;��ʼ����������ΧΪ0-1000����ʼֵΪ1000
	invoke SendDlgItemMessage, hWin, IDC_VolumeSlider, TBM_SETRANGEMIN, 0, 0
	invoke SendDlgItemMessage, hWin, IDC_VolumeSlider, TBM_SETRANGEMAX, 0, 1000
	invoke SendDlgItemMessage, hWin, IDC_VolumeSlider, TBM_SETPOS, 1, 1000
	
	;��ʼ����������ΧΪ0-200
	invoke SendDlgItemMessage, hWin, IDC_TimeSlider, TBM_SETRANGEMIN, 0, 0
	invoke SendDlgItemMessage, hWin, IDC_TimeSlider, TBM_SETRANGEMAX, 0, 200
	
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
		invoke SendDlgItemMessage, hWin, IDC_SongMenu, LB_SETCURSEL, currentSongIndex, 0;�ı�ѡ����
		invoke openSong,hWin, currentSongIndex;
		invoke mciSendString, ADDR playSongCommand, NULL, 0, NULL;���Ÿ���
		invoke changeVolume,hWin
		invoke SendDlgItemMessage, hWin, IDC_PlayButton, WM_SETTEXT, 0, addr buttonPause;�޸İ�ť����
	.elseif currentStatus == 1;����ǰ״̬Ϊ����״̬
		mov currentStatus, 2;תΪ��ͣ״̬
		invoke mciSendString, ADDR pauseSongCommand, NULL, 0, NULL;��ͣ����
		invoke SendDlgItemMessage, hWin, IDC_PlayButton, WM_SETTEXT, 0, addr buttonPlay;�޸İ�ť����
	.elseif currentStatus == 2;����ǰ״̬Ϊ��ͣ״̬
		mov currentStatus, 1;תΪ����״̬
		invoke mciSendString, ADDR resumeSongCommand, NULL, 0, NULL;�ָ���������
		invoke SendDlgItemMessage, hWin, IDC_PlayButton, WM_SETTEXT, 0, addr buttonPause;�޸İ�ť����
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
	invoke SendDlgItemMessage, hWin, IDC_PlayButton, WM_SETTEXT, 0, addr buttonPause;�޸İ�ť����
	invoke mciSendString, ADDR playSongCommand, NULL, 0, NULL;���Ÿ���
	
	;��������Ϊ��ǰ����Slider��ֵ
	invoke changeVolume,hWin
	Ret
changeSong endp


;-------------------------------------------------------------------------------------------------------
; �رյ�ǰ�ĸ���
; Receives: hWin�Ǵ��ھ����
; Returns: none
;-------------------------------------------------------------------------------------------------------
closeSong proc uses eax hWin:DWORD 
	.if currentStatus != 0;��ǰ״̬Ϊ���Ż�����ͣ
		invoke mciSendString, ADDR closeSongCommand, NULL, 0, NULL
	.endif
	Ret
closeSong endp

;-------------------------------------------------------------------------------------------------------
; �����µĸ���
; hWin�Ǵ��ھ����
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
; �Ӹ赥�ļ���ȡ����
; hWin�Ǵ��ھ����
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
; ��������б��ļ�
; hWin�Ǵ��ھ����
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
; ɾ�������б���ѡ�е�����
; hWin�Ǵ��ھ����
; Returns: none
;-------------------------------------------------------------------------------------------------------
deleteSong proc hWin: DWORD
	invoke SendDlgItemMessage, hWin, IDC_SongMenu, LB_GETCURSEL, 0, 0;���ȡ��ѡ�е��±�
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
; �ı�����
; hWin�Ǵ��ھ����
; Returns: none
;-------------------------------------------------------------------------------------------------------
changeVolume proc hWin:	DWORD
	invoke SendDlgItemMessage,hWin,IDC_VolumeSlider,TBM_GETPOS,0,0;��ȡ��ǰSlider�α�λ��
	invoke wsprintf, addr mediaCommand, addr adjustVolumeCommand, eax
	invoke mciSendString, addr mediaCommand, NULL, 0, NULL
	Ret
changeVolume endp

;-------------------------------------------------------------------------------------------------------
; �ı�������ʾ����ֵ
; hWin�Ǵ��ھ����
; Returns: none
;-------------------------------------------------------------------------------------------------------
displayVolume proc hWin: DWORD
	local extend32: DWORD
	invoke SendDlgItemMessage,hWin,IDC_VolumeSlider,TBM_GETPOS,0,0;��ȡ��ǰSlider�α�λ��
	;����������ʾ����
	mov extend32, 10
	mov edx, 0
	div extend32
	invoke wsprintf, addr mediaCommand, addr int2str, eax
	invoke SendDlgItemMessage, hWin, IDC_VolumeDisplay, WM_SETTEXT, 0, addr mediaCommand
	Ret
displayVolume endp

end start