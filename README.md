# MusicPlayer

## 功能（长期目标）

- WAV/MP3 等常用格式的音频文件的解码
- 播放、暂停、上一首、下一首
- 曲目的管理（显示所有歌曲的信息，同时提供增加歌曲、删除歌曲、喜欢、加入自定义歌单的操作）
- 播放模式的选择（单曲循环、随机循环、全部循环）
- 歌词的显示
- 提供关键词搜索功能
-（选做）将关键词搜索从本地的范围扩大到全网

## 开发环境
- 操作系统：Windows
- 编辑器：WinASM
- 汇编器：MASM32

## 待完成（近期目标）
### Task1
- 实现进度选择
- 实现音量选择
- 支持单曲循环和全部循环两种模式

### Task2
- upload函数中将SongMenu的内容存到本地磁盘
- load函数将SongMenu的内容从本地磁盘读取到内存
- 按下导入歌曲按钮后，能够增加歌曲（最好是弹出一个文件选择栏，如果技术实现上存在困难，也可以采用填空的形式）
-（可选） 实现歌曲的删除（删除方式可自由发挥）
- 注意：歌单为空时可能会出现一些奇怪的问题

### Task3
- 完成上述任务后如果有人还有空闲时间和意愿的话，可以考虑实现，关键词搜索功能。
