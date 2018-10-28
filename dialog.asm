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
	.elseif eax == WM_TIMER;��ʱ����Ϣ
		.if currentStatus == 1
			invoke changeTimeSlider, hWin;���Ľ���������λ��
			invoke repeatControl, hWin;����Ƿ��Ѿ�������ɣ������������ݵ�ǰѭ��ģʽ������Ӧ�ĸ���
		.endif
	.elseif eax == WM_HSCROLL;slider��Ϣ
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
				invoke displayVolume, hWin;����������ʾ����
			.elseif ax == SB_ENDSCROLL;����������Ϣ
				invoke SendDlgItemMessage, hWin, IDC_SongMenu, LB_GETCURSEL, 0, 0;���ȡ��ѡ�е��±�
				.if eax != -1;��ǰ�и�����ѡ�У�����mcisendstring�����������
					invoke changeVolume,hWin
				.endif
				invoke displayVolume, hWin;����������ʾ����
			.endif
			
		.elseif curSlider == IDC_TimeSlider;���ڽ���
			.if ax == SB_ENDSCROLL;����������Ϣ
				invoke SendDlgItemMessage, hWin, IDC_SongMenu, LB_GETCURSEL, 0, 0;���ȡ��ѡ�е��±�
				.if eax != -1;��ǰ�и�����ѡ�У�����mcisendstring�����������
					invoke changeTime, hWin
				.endif
			.endif
		.endif
	.elseif eax == WM_COMMAND
		mov	eax,wParam
		.if	eax == IDB_EXIT;�����˳���
			invoke	SendMessage, hWin, WM_CLOSE, 0, 0
		.elseif eax == IDC_ImportImage;���µ��������
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
		.elseif eax == IDC_PrevImage;�������һ�׸�
			.if currentSongIndex == 0
				mov eax, songMenuSize
				mov currentSongIndex,eax
			.endif
			dec currentSongIndex
			invoke SendDlgItemMessage,hWin, IDC_SongMenu, LB_SETCURSEL, currentSongIndex, 0;�ı�ѡ����
			invoke changeSong,hWin,currentSongIndex;���Ÿ��׸���
		.elseif eax == IDC_NextImage;�������һ�׸�
			inc currentSongIndex
			mov eax, currentSongIndex
			.if eax == songMenuSize
				mov currentSongIndex,0
			.endif
			invoke SendDlgItemMessage,hWin, IDC_SongMenu, LB_SETCURSEL, currentSongIndex, 0;�ı�ѡ����
			invoke changeSong,hWin,currentSongIndex;���Ÿ��׸���
		.elseif eax == IDC_TrashImage
			invoke deleteSong, hWin
		.elseif eax == IDC_SilenceButton;���¾�����ť
			invoke changeSilencState,hWin
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
	invoke SendDlgItemMessage, hWin, IDC_VolumeSlider, TBM_SETRANGEMAX, 0, sliderLength
	invoke SendDlgItemMessage, hWin, IDC_VolumeSlider, TBM_SETPOS, 1, sliderLength
	
	;���ü�ʱ����ÿ0.5s����һ�μ�ʱ����Ϣ
	invoke SetTimer, hWin, 1, 500, NULL
	
	;��ComboBox���������ѭ��ģʽ
	invoke SendDlgItemMessage, hWin, IDC_PlayMode, CB_ADDSTRING, 0, addr singleCirculation
	invoke SendDlgItemMessage, hWin, IDC_PlayMode, CB_ADDSTRING, 0, addr listCirculation
	invoke SendDlgItemMessage, hWin, IDC_PlayMode, CB_SETCURSEL, 0, 0;Ĭ��ѡ�е���ѭ��
	
	invoke changePlayButton,hWin, 0
	mov hasSound, 1
	invoke changeSilenceButton,hWin,hasSound
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
; �ı䲥�Ű�ť
; Receives: hWin�Ǵ��ھ����playing=1��ʾ���������ţ�=0��ʾ������������
; Returns: none
;-------------------------------------------------------------------------------------------------------
changePlayButton proc hWin:DWORD, playing:BYTE
	.if playing == 0;ת����ͣ״̬
		mov eax, 300
	.else;ת������״̬
		mov eax, 301
	.endif
	invoke LoadImage, hInstance, eax,IMAGE_ICON,32,32,NULL
	invoke SendDlgItemMessage,hWin,IDC_PlayButton, BM_SETIMAGE, IMAGE_ICON, eax;�޸İ�ť
	Ret
changePlayButton endp


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
		invoke changeVolume,hWin;�ı�����
		invoke changePlayButton,hWin,1
		
		invoke mciSendString, addr getLengthCommand, addr songLength, 32, NULL;songLength��λ�Ǻ��룬����5��02��=303601
		invoke StrToInt, addr songLength
		invoke SendDlgItemMessage, hWin, IDC_TimeSlider, TBM_SETRANGEMAX, 0, eax;�ѽ������ĳɸ��������ȣ���������һ����
		
		;���㵱ǰ������ʱ�������Ӻ����ʾ��
		invoke StrToInt, addr songLength
		mov edx, 0
		div timeScale
	
		mov edx, 0
		div timeScaleSec
		mov timeMinuteLength, eax
		mov timeSecondLength, edx
	.elseif currentStatus == 1;����ǰ״̬Ϊ����״̬
		mov currentStatus, 2;תΪ��ͣ״̬
		invoke mciSendString, ADDR pauseSongCommand, NULL, 0, NULL;��ͣ����	
		invoke changePlayButton, hWin, 0
		
	.elseif currentStatus == 2;����ǰ״̬Ϊ��ͣ״̬
		mov currentStatus, 1;תΪ����״̬
		invoke mciSendString, ADDR resumeSongCommand, NULL, 0, NULL;�ָ���������
		invoke changePlayButton,hWin,1
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
	invoke changePlayButton,hWin,1
	invoke mciSendString, ADDR playSongCommand, NULL, 0, NULL;���Ÿ���
	invoke changeVolume,hWin;��������Ϊ��ǰ����Slider��ֵ
	
	;����ʱ���������󳤶�Ϊ��������(����)
	invoke mciSendString, addr getLengthCommand, addr songLength, 32, NULL;songLength��λΪ����
	invoke StrToInt, addr songLength
	invoke SendDlgItemMessage, hWin, IDC_TimeSlider, TBM_SETRANGEMAX, 0, eax;�ѽ������ĳɸ��������ȣ���������һ����
	
	;���㵱ǰ������ʱ�������Ӻ����ʾ��
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
	.if hasSound == 1
		invoke wsprintf, addr mediaCommand, addr adjustVolumeCommand, eax
	.else
		invoke wsprintf, addr mediaCommand, addr adjustVolumeCommand, 0
	.endif
	invoke mciSendString, addr mediaCommand, NULL, 0, NULL
	Ret
changeVolume endp


;-------------------------------------------------------------------------------------------------------
; �ı侲����ť
; Receives: hWin�Ǵ��ھ����playing=1��ʾ��������������=0��ʾ������û������
; Returns: none
;-------------------------------------------------------------------------------------------------------
changeSilenceButton proc hWin:DWORD, _hasSound:BYTE
	.if _hasSound == 0;ת����ͣ״̬
		mov eax, 305
	.else;ת������״̬
		mov eax, 304
	.endif
	invoke LoadImage, hInstance, eax,IMAGE_ICON,32,32,NULL
	invoke SendDlgItemMessage,hWin,IDC_SilenceButton, BM_SETIMAGE, IMAGE_ICON, eax;�޸İ�ť
	Ret
changeSilenceButton endp


;-------------------------------------------------------------------------------------------------------
; �л��Ƿ�Ϊ������״̬
; hWin�Ǵ��ھ����
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

;-------------------------------------------------------------------------------------------------------
; ��ǰΪ����״̬ʱ�����ݲ��Ž��ȸı������
; hWin�Ǵ��ھ����
; Returns: none
;-------------------------------------------------------------------------------------------------------
changeTimeSlider proc hWin: DWORD
	local temp: DWORD
	.if currentStatus == 1;����ǰΪ����״̬
		invoke mciSendString, addr getPositionCommand, addr songPosition, 32, NULL;��ȡ��ǰ����λ��
		invoke StrToInt, addr songPosition;��ǰ����ת��int����eax��
		mov temp, eax
		invoke SendDlgItemMessage, hWin, IDC_TimeSlider, TBM_SETPOS, 1, temp
		invoke displayTime, hWin, temp
	.endif
	Ret
changeTimeSlider endp

;-------------------------------------------------------------------------------------------------------
; �������Ļ���λ�ñ��ı�ʱ���������ݽ������ı䲥�Ž���
; �����ǰ�ǲ���״̬����ô����ת����Ӧ���ȣ������ǰ����ͣ״̬����ô��תΪ����״̬����ת����Ӧ���ȣ������ǰΪֹͣ״̬�����κ�����
; hWin�Ǵ��ھ����
; Returns: none
;-------------------------------------------------------------------------------------------------------
changeTime proc hWin: DWORD
	invoke SendDlgItemMessage,hWin,IDC_TimeSlider,TBM_GETPOS,0,0;��ȡ��ǰSlider�α�λ��
	invoke wsprintf, addr mediaCommand, addr setPositionCommand, eax
	invoke mciSendString, addr mediaCommand, NULL, 0, NULL
	.if currentStatus == 1;����״̬
		invoke mciSendString, addr playSongCommand, NULL, 0, NULL
	.elseif currentStatus == 2;��ͣ״̬
		invoke mciSendString, addr playSongCommand, NULL, 0, NULL
		invoke SendDlgItemMessage, hWin, IDC_PlayButton, WM_SETTEXT, 0, addr buttonPause;�޸İ�ť����
		mov currentStatus, 1;תΪ����״̬
	.endif
	Ret
changeTime endp

;-------------------------------------------------------------------------------------------------------
; ���ݽ������ı䴰������ʾ������
; hWin�Ǵ��ھ��, currentPosition�ǵ�ǰ����λ�ã���������λ�����룩
; Returns: none
;-------------------------------------------------------------------------------------------------------
displayTime proc hWin: DWORD, currentPosition: DWORD
	;���㵱ǰ�����Ľ��ȣ����Ӻ����ʾ��
	mov eax, currentPosition
	mov edx, 0
	div timeScale
	
	mov edx, 0
	div timeScaleSec
	mov timeMinutePosition, eax
	mov timeSecondPosition, edx
	invoke wsprintf, addr mediaCommand, addr timeDisplay, timeMinutePosition, timeSecondPosition, timeMinuteLength, timeSecondLength
	invoke SendDlgItemMessage, hWin, IDC_TimeDisplay, WM_SETTEXT, 0, addr mediaCommand;�޸����� 
	Ret
displayTime endp

;-------------------------------------------------------------------------------------------------------
; ���ݽ������ı䴰������ʾ������
; hWin�Ǵ��ھ����
; Returns: none
;-------------------------------------------------------------------------------------------------------
repeatControl proc hWin: DWORD
	local temp: DWORD
	.if currentStatus == 1;����״̬
		invoke StrToInt, addr songLength
		mov temp, eax
		invoke StrToInt, addr songPosition
		.if eax == temp;��������
			invoke SendDlgItemMessage, hWin, IDC_PlayMode, CB_GETCURSEL, 0, 0;�鿴��ǰѡ�е������ţ�0������ѭ����1�����б�ѭ��
			.if eax == SINGLE_REPEAT;����ѭ��
				invoke mciSendString, addr setPosToStartCommand, NULL, 0, NULL;��λ��������ͷ
				invoke mciSendString, addr playSongCommand, NULL, 0, NULL
			.elseif eax == LIST_REPEAT;�б�ѭ��
				invoke SendMessage, hWin, WM_COMMAND, IDC_NextImage, 0;������Ϣ��ģ������"��һ��"��ť
			.endif
		.endif
	.endif
	Ret
repeatControl endp

end start