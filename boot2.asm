; TAB=4
CYLS	equ		10				
		org		0x7c00			; 指明程序的装载地址
		jmp		entry
		DB		0x90
		DB		"OPENPLAC"		; 启动区的名称可以是任意字符串（8字节）
		DW		512				; 每个扇区的大小（必须为512字节）
		DB		1				; 簇的大小（必须为1扇区）
		DW		1				; FAT的起始位置（一般从第一个扇区开始）
		DB		2				; FAT的个数（必须为2）
		DW		224				; 根目录大小（一般设成224项）
		DW		2880			; 该磁盘的大小（必须是2880扇区）
		DB		0xf0			; 磁盘的种类（必须是0xf0）
		DW		9				; FAT的长度（必须是9扇区）
		DW		18				; 1个磁道的扇区数（必须是18）
		DW		2				; 磁头数（必须是2）
		DD		0				; 不使用分区（必须是0）
		DD		2880			; 重写一次磁盘大小
		DB		0,0,0x29		; 意义不明，固定
		DD		0xffffffff		; 卷标号码
		DB		"ABCDEFGHIJK"	; 磁盘名称（11字节）
		DB		"FAT12   "		; 磁盘格式名称（8字节）
		RESB	18				
; 主代码
entry:
		mov		AX,0			; 初始化寄存器
		mov		SS,AX
		mov		SP,0x7c00
		mov		DS,AX	
		mov		AX,0x0820		; 设置读磁盘位置
		mov		ES,AX
		mov		CH,0			; 柱面0
		mov		DH,0			; 磁头0
		mov		CL,2			; 扇区2
readloop:
		mov		SI,0			; 记录失败次数
retry:							; 读软盘
		mov		AH,0x02			; AH=0x02 : 读盘
		mov		AL,1			; 1个扇区
		mov		BX,0
		mov		DL,0x00			; A驱动器
		int		0x13			
		jnc		next			; 没出错时跳转到next
		add		SI,1			; SI加1
		cmp		SI,5			; 比较SI与5
		jae		error			; SI >= 5 时跳转到error
		mov		AH,0x00
		mov		DL,0x00			; A驱动器
		int		0x13			; 重置驱动器
		jmp		retry
next:
		mov		AX,ES			; 把内存地址后移0x200
		add		AX,0x0020
		mov		ES,AX			
		add		CL,1			
		cmp		CL,18			
		jbe		readloop		
		mov		CL,1
		add		DH,1
		cmp		DH,2
		jb		readloop		
		mov		DH,0
		add		CH,1
		cmp		CH,CYLS
		jb		readloop		
		mov		[0x0ff0],CH		
		jmp		0x8200
error:
		mov		SI,msg
putloop:
		mov		AL,[SI]
		add		SI,1			
		cmp		AL,0
		je		fin
		mov		AH,0x0e			
		mov		BX,15			
		int		0x10			
		jmp		putloop
fin:
		hlt						
		jmp		fin				
msg:
		DB		0x0a, 0x0a		; 换行两次
		DB		"load error"
		DB		0x0a			; 换行
		DB		0
		RESB	0x7dfe-($-$$)		
		DB		0x55, 0xaa