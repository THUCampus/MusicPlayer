IFNDEF SONGMENU_INC
SONGMENU_INC EQU <1>

Song STRUCT
	_name BYTE "夜空中最亮的星",0;歌曲名
	_path BYTE "Music/star.mp3",0;歌曲路径
	_songSize BYTE 0;歌曲大小
Song ends

ELSE
echo -----------------------------------------
echo WARNING Duplicate include file songMenu.inc
echo -----------------------------------------
ENDIF