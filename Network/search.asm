;实现根据关键词搜索相关的歌曲
.386
.model flat, stdcall
.stack 4096

OPTION CASEMAP: NONE

include wsock32.inc
includelib wsock32.lib
include msvcrt.inc
includelib msvcrt.lib
include windows.inc
include kernel32.inc
includelib kernel32.lib


ExitProcess PROTO, dwExitCode:DWORD
getWebResult PROTO url: DWORD
getSearchResult PROTO key: DWORD
getDownloadLink PROTO sid: DWORD
getArg PROTO :DWORD, :DWORD
Str_length PROTO :PTR BYTE
writeToFile PROTO :DWORD, :DWORD

.data
CommandLine DWORD 0
ArgLine BYTE 100 DUP(0)
SearchResultFile BYTE "searchResult.txt",0
format DB "%s", 0DH, 0AH, 0DH, 0AH, 0

.code
main PROC
	INVOKE GetCommandLine
	mov CommandLine ,eax
	invoke crt_printf, addr format, eax
	invoke Str_length, CommandLine
	invoke getArg, CommandLine, eax
	.if eax != 0
		invoke getSearchResult, eax
		invoke writeToFile, addr SearchResultFile,eax
	.endif
    INVOKE ExitProcess, 0
main ENDP

;获取字符串的长度
;pString是指向该字符串地址的指针
Str_length PROC USES edi,
    pString:PTR BYTE
    mov edi,pString
    mov eax,0
L1: cmp BYTE PTR[edi],0 
	je L2
    inc edi
    inc eax
    jmp L1
L2: ret 
Str_length ENDP

getArg PROC commandPtr:DWORD, len:DWORD
	cld
	mov al, 20H
	mov edi, commandPtr
	mov ecx, len
	repne scasb
	.if ecx > 0
		add edi, 1
		mov eax, edi
		;invoke crt_printf, eax
	.elseif
		mov eax,0
	.endif
	ret
getArg ENDP

writeToFile PROC fileNamePtr:DWORD, stringPtr:DWORD
.data
	errorMessage BYTE "文件打开失败",0
.data?
	hFile HANDLE ?
.code
	invoke CreateFile,fileNamePtr,GENERIC_READ OR GENERIC_WRITE,FILE_SHARE_READ OR FILE_SHARE_WRITE, NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
	mov hFile,eax
    .if hFile == INVALID_HANDLE_VALUE
		invoke crt_printf, addr errorMessage
	.else
		invoke Str_length, stringPtr
		invoke WriteFile, hFile, stringPtr, eax, NULL, NULL
	.endif
	ret
writeToFile ENDP

.code
; getSearchResult: 根据搜索关键词获取搜索结果
; 参数: key, DWORD类型, 字符串指针, 内容为关键词
; 返回值: eax, 搜索结果开始的位置，为字符串指针
; 返回结果的格式为: "歌曲名和歌手#歌曲id$歌曲名和歌手#歌曲id&歌曲名和歌手#歌曲id..."共20条，同时保证歌曲名和歌曲id中没有其它的'$'和'#'
; 特殊情况: 特殊的关键词可能导致返回结果不足20条
getSearchResult PROC key: DWORD
.data
	search_head DB "/search?key=", 0
	search_buf DB 1024 DUP(0)

.code
	; 构造搜索连接的url
	INVOKE lstrcpy, ADDR search_buf, ADDR search_head
	INVOKE lstrcat, ADDR search_buf, key
	; 访问服务器并拿到结果
	INVOKE getWebResult, ADDR search_buf
	ret
getSearchResult ENDP

; getSearchResult: 根据搜索歌曲id获取歌曲下载链接
; 参数: sid, DWORD类型, 字符串指针, 内容为歌曲id
; 返回值: eax, 下载链接开始的位置，为字符串指针
getDownloadLink PROC sid: DWORD
.data
	get_url_head DB "/get_url?sid=", 0
	get_url_buf DB 1024 DUP(0)

.code
	; 构造下载连接的url
	INVOKE lstrcpy, ADDR get_url_buf, ADDR get_url_head
	INVOKE lstrcat, ADDR get_url_buf, sid
	; 访问服务器并拿到结果
	INVOKE getWebResult, ADDR get_url_buf
	ret
getDownloadLink ENDP

; getWebResult: 连接asm.wu-c.cn服务器并获取结果
; 参数: url, DWORD类型, 字符串指针, 内容为要访问的url
; 返回值: eax, 返回结果开始的位置，为字符串指针
getWebResult PROC uses esi edi url: DWORD
	LOCAL sock_data: WSADATA
	LOCAL s_addr: sockaddr_in
	LOCAL sock: DWORD
	LOCAL n: DWORD
	LOCAL p: DWORD

.data
	server_ip DB "47.94.101.6", 0
	request_head DB "GET ", 0
	request_tail DB " HTTP/1.1", 0DH, 0AH, "Host: asm.wu-c.cn", 0DH, 0AH, "Connection:Close", 0DH, 0AH, 0DH, 0AH, 0
	crlf2 DB 0DH, 0AH
	crlf DB 0DH, 0AH, 0
	request DB 1024 DUP(0)
	result DB 2048 DUP(0)
	BUFSIZE = 1024

.code
	; 初始化
	INVOKE WSAStartup, 22h, ADDR sock_data

	.IF eax != 0
		ret
	.ENDIF

	; 设置服务器ip和端口
	lea esi, s_addr
	mov WORD PTR [esi], AF_INET
	INVOKE htons, 80
	mov WORD PTR [esi + 2], ax
	INVOKE inet_addr, ADDR server_ip
	mov DWORD PTR [esi + 4], eax

	; 创建并连接socket
	INVOKE socket, AF_INET, SOCK_STREAM, IPPROTO_TCP
	mov sock, eax
	lea esi, s_addr
	INVOKE connect, sock, esi, SIZEOF sockaddr_in

	.IF sock == -1 || sock == -2
		ret
	.ENDIF

	; 构造http请求头
	INVOKE lstrcpy, ADDR request, ADDR request_head
	INVOKE lstrcat, ADDR request, url
	INVOKE lstrcat, ADDR request, ADDR request_tail
	INVOKE lstrlen, ADDR request

	; 发送http请求
	INVOKE send, sock, ADDR request, eax, 0

	; 接受http响应结果
	mov n, eax
	mov esi, OFFSET result
	.WHILE n > 0
		INVOKE recv, sock, esi, BUFSIZE, 0
		mov n, eax
		add esi, n
	.ENDW

	; 从http响应中提取body
	push OFFSET crlf2
	push OFFSET result
	call crt_strstr
	add esp, 8
	add eax, 4
	push OFFSET crlf
	push eax
	call crt_strstr
	add esp, 8
	add eax, 2
	mov p, eax
	push OFFSET crlf
	push p
	call crt_strstr
	add esp, 8
	mov BYTE PTR [eax], 0

	; 清理
	INVOKE WSACleanup

	; 保存返回结果地址到eax中
	mov eax, p
	ret
getWebResult ENDP

END