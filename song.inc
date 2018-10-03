IFNDEF SONGMENU_INC
SONGMENU_INC EQU <1>

Song STRUCT
	_name BYTE 100 DUP(0);¸èÇúÃû
	_path BYTE 100 DUP(0);¸èÇúÂ·¾¶
Song ends

ELSE
echo -----------------------------------------
echo WARNING Duplicate include file songMenu.inc
echo -----------------------------------------
ENDIF