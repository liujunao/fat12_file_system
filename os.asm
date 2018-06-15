ORG     0x8200
;section .data
%macro touch 1
    ;清空以前的数据
    mov cx, 0
    mov bx, touch_filename
    %%clear_name:
        mov di, cx
        mov byte [bx+di], ' '
        inc cx
        cmp cx, 11
        jl %%clear_name
    mov cx, 0
    mov bx, touch_fileContent
    %%clear_file:
        mov di, cx
        mov byte [bx+di], 0
        inc cx
        cmp cx, 0x200
        jl %%clear_file
    mov bx, touch_filename
    mov cx, 0
    %%movByte:
        mov di, cx
        cmp byte [%1+di], ' '
        je %%afterCopyName
        mov ax, [%1+di]
        mov [bx+di], ax
        inc cx
        jmp %%movByte
    %%afterCopyName:
        mov bx, touch_fileContent
        inc cx
        mov si, 0
    %%movContent:
        mov di, cx
        cmp byte [%1+di], ' '
        je %%afterCopyContent
        mov ax, [%1+di]
        mov [bx+si], ax
        inc cx
        inc si
        jmp %%movContent
    %%afterCopyContent:
    mov [filesize], si
    call select
    call write_fat
    call write_con
%endmacro

%macro judge_char 1
    xor ax, ax
is_number:					; 判断是否为数字
    cmp %1, 48
    jnge is_uppercase       
    cmp %1, 57
    jng is_end            	
is_uppercase:				; 判断是否是大写字母
    cmp %1, 65
    jnge is_lowercase       
    cmp %1, 90
    jng is_end            	
is_lowercase:				; 判断是否是小写字母
    cmp %1, 97
    jnge is_blank        	
    cmp %1, 122
    jng is_end               
is_blank:					; 判断是否是空格
    cmp %1, 0x20
    je is_end
is_dot:						; 判断是否是符号 "."
    cmp %1, 0x2E
    je is_end
mov ax, 1
is_end:
%endmacro

%macro seek 1
mov si, 0
mov bx, oneSecFile
%%seek_file:
    xor cx, cx
    %%com_char:
        mov di, cx
        mov ah, [%1+di]
        cmp ah, [bx+di]
        jne %%not_match
        inc cx
        cmp cx, 11
        jne %%com_char
    mov dx, [bx+file.first_clus]
    mov al, 0x0d
    mov ah, 0x0e
    int 0x10
    mov al, 0x0a
    mov ah, 0x0e
    int 0x10
    jmp %%found
    %%not_match:
        add bx, 32
    add si, 1
    cmp si, 16
    jl %%seek_file
    mov al, 0
    jmp %%end2
%%found:
    mov ax, [bx+file.file_size]
    mov [fileSize], ax
    mov al, 1
%%end2:
%endmacro

%macro IO_BIOS 7
mov si, 0
%%re_bios:
    mov ax, 0
    mov es, ax
    mov ch, %1
    mov dh, %2
    mov cl, %3       
    mov ah, %4
    mov al, %5
    mov bx, %6
    mov dl, 0x01
    int 0x13
    jnc %7
    add si, 1
    cmp si, 5
    jae %%err_bios
    MOV AH,0x00
    MOV DL,0x01 	
    INT 0x13 		
    jmp %%re_bios
%%err_bios:
    mov al, ah
    MOV AH,0x0e
    int 0x10
    mov ah, 0x0e
    mov al, ' '
    int 0x10
    mov al, 'e'
    int 0x10
    mov al, 'r'
    int 0x10
    mov al, 'r'
    int 0x10
    mov al, ' '
    int 0x10
%endmacro

fatContent:
    DB      0xeb, 0x4e, 0x90
    DB      "RUANJIAN"      ; 启动区的名称可以是任意字符串（8字节）
    DW      512             ; 每个扇区的大小（必须为512字节）
    DB      1               ; 簇的大小（必须为1扇区）
    DW      1               ; FAT的起始位置（一般从第一个扇区开始）
    DB      2               ; FAT的个数（必须为2）
    DW      224             ; 根目录大小（一般设成224项）
    DW      2880            ; 该磁盘的大小（必须是2880扇区）
    DB      0xf0            ; 磁盘的种类（必须是0xf0）
    DW      9               ; FAT的长度（必须是9扇区）
    DW      18              ; 1个磁道的扇区数（必须是18）
    DW      2               ; 磁头数（必须是2）
    DD      0               ; 不使用分区（必须是0）
    DD      2880            ; 重写一次磁盘大小
    DB      0,0,0x29        ; 意义不明，固定
    DD      0xffffffff      ; 卷标号码
    DB      "RUANJIANOS "   ; 磁盘名称（11字节）
    DB      "FAT12   "      ; 磁盘格式名称（8字节）
res:
    resb    0x0014e-($-fatContent)
final:
    resb    0xb0
    DB      0x55, 0xaa
FAT:
    resb    0x200
oneSecFile:
    resb    0x200
fileContent:
    resb    0x200
fileSize:
    resb    2
command: db "                              "
jmp boot
touch_filename: db "           "
touch_fileContent:
    resb 0x200
filesize:
    resb 2
blank:
    resb 0x200
	
read_fat:
    IO_BIOS 0, 0, 2, 0x02, 1, FAT, read_next
    read_next:
    ret
oneFAT:
    resb 2
fat_res:
    resb 2
culNum:
    resb 2
read_one:
    mov cx, [culNum]
    push cx
    mov ax, cx
    cwd
    mov cx, 2
    idiv cx
    pop cx
    add ax, cx       
    mov bx, ax
    mov ax, [FAT+bx]
    mov [oneFAT], ax
    cmp dx, 0
    je read_odd   
    read_even:
        sar ax, 4
        mov [fat_res], ax
        ret
    read_odd:
        and ax, 0x0fff
        mov [fat_res], ax
    ret
select:
    mov cx, 2
    loop_:
        mov [culNum], cx
        call read_one
        mov ax, [fat_res]
        cmp ax, 0
        je select_on
        inc cx
        cmp cx, 340
        jl loop_
    select_on:
        mov ax, [oneFAT]
        cmp dx, 0
        je write_odd
        write_even:
            xor ax, 0xfff0
            jmp write_after
        write_odd:
            xor ax, 0x0fff
        write_after:
            mov [FAT+bx], ax
            IO_BIOS 0, 0, 2, 0x03, 1, FAT, write_after2
        write_after2:
            IO_BIOS 0, 0, 11, 0x03, 1, FAT, write_after3
        write_after3:
    ret
cul: resb 2
write_fat:
    mov ax, cx
    mov [cul], ax
    mov cx, 0
    mov bx, oneSecFile
    find_file:
        cmp byte [bx], 0
        je foundPos
        add bx, 32
        inc cx
        cmp cx, 16
        jl find_file
    foundPos:
        mov cx, 0
        movNameToSec:
            mov di, cx
            mov dl, [touch_filename+di]
            mov [bx+di], dl
            inc cx
            cmp cx, 11
            jl movNameToSec
        mov [bx+file.first_clus], ax    
        mov ax, [filesize]
        mov [bx+file.file_size], ax     
    IO_BIOS byte [currentDirSector], byte [currentDirSector+1], byte [currentDirSector+2], 0x03, 1, oneSecFile, write_sec
    write_sec:
    ret
write_con:
    mov ax, [cul]
    call workout
    
    IO_BIOS ch, dh, cl, 0x03, 1, touch_fileContent, write_after_con
    write_after_con:
    ret
input:
    mov cx, 0
    clear_command:
    mov di, cx
    mov byte [command+di], ' '
    inc cx
    cmp cx, 30
    jl clear_command
    mov bx, 0
get_key:
    mov ah, 0x00
    int 0x16
    cmp al, 0x0d
    je command_key
    MOV AH,0x0e
    int 0x10
    mov [command+bx], al
    inc bx
    jmp get_key
    command_key:
        cmp byte [command], 'f'
        je format_
        cmp byte [command], 'r'
        je read_
        cmp byte [command], 'w'
        je write_
		cmp byte [command], 'h'
        je help_
	
    format_:
        IO_BIOS 0, 0, 1, 0x03, 1, fatContent, writeRoot
        writeRoot:
        IO_BIOS 0, 1, 2, 0x03, 1, blank, next_format
        next_format:
        call read
        mov al, 0x0d
        mov ah, 0x0e
        int 0x10
        mov al, 0x0a
        mov ah, 0x0e
        int 0x10
        ret
    read_:
        seek command+2
        call cat
        ret
    write_:
        touch command+2
        mov al, 0x0d
        mov ah, 0x0e
        int 0x10
        mov al, 0x0a
        mov ah, 0x0e
        int 0x10
        ret
		
	help_:
	    mov ah,03h
		int 10h
		mov ax,cs
		mov es,ax
		mov ax,help
		mov bp,ax
		mov ax,01301h
		mov al,0                          
		mov cx, helplen
		int 10h
		mov al,0x0a
		mov ah,0eh
		int 10h
		mov al,0x0a
		mov ah,0eh
		int 10h
		mov al,0x0d
		mov ah,0eh
		mov bx,0ch
		int 10h
		ret
		
read:
    mov byte [currentDirSector], 0
    mov byte [currentDirSector+1], 1
    mov byte [currentDirSector+2], 2
    IO_BIOS 0, 1, 2, 0x02, 1, oneSecFile, next_read
	next_read:   
		mov si, 0
		mov bx, oneSecFile
	print_name:
		xor cx, cx
		loop_11:
			mov di, cx
			judge_char byte [bx+di]
			cmp ax, 1
			je not_print
			inc cx
			cmp cx, 11
			jne loop_11
		xor cx, cx
		loop_print_char:
			mov di, cx
			mov al, [bx+di]
			mov ah, 0x0e
			int 0x10
			inc cx
			cmp cx, 11
			jne loop_print_char
		cmp byte [bx+11], 16
		jne print_enter
		mov al, '.'
		mov ah, 0x0e
		int 0x10
		print_enter:
		mov al, 0x0d
		mov ah, 0x0e
		int 0x10
		mov al, 0x0a
		mov ah, 0x0e
		int 0x10
		not_print:
			add bx, 32
		add si, 1
		cmp si, 16
		jl print_name
	ret

cat:
    cmp al, 0
    je cat_blank
    mov ax, dx
    call workout
    IO_BIOS ch, dh, cl, 0x02, 1, fileContent, read_file
    read_file:
        mov bx, 0
        rd_loop:
            mov al, [fileContent+bx]
            mov ah, 0x0e
            int 0x10
            inc bx
            cmp bx, [fileSize]
            jl rd_loop
        mov al, 0x0d
        mov ah, 0x0e
        int 0x10
        mov al, 0x0a
        mov ah, 0x0e
        int 0x10
        ret
        mov ah, 0x03
        mov bh, 1
        int 0x10
        mov cx, 0x10
        mov bp, fileContent
        mov ax, 0
        mov es, ax
        mov ah, 0x13
        mov al, 1
        int 0x10
    ret
    cat_blank:
        mov al, "B"
        mov ah, 0x0e
        int 0x10
    ret
	
	
struc   file
    .dir_name   resb    11
    .dir_attr   resb    1
    .reserved   resb    10
    .w_time     resb    2
    .w_date     resb    2
    .first_clus resb    2
    .file_size  resb    4
    .size:
endstruc

fill_fat:
	mov si, 0
retry_fill_fat:
    mov ax, 0
    mov es, ax
    mov ch, 0
    mov dh, 0
    mov cl, 2      
    mov ah, 0x02
    mov al, 1
    mov bx, FAT
    mov dl, 0x01
    int 0x13
    jnc next_fat
    add si, 1
    cmp si, 5
    jae error_fat
    MOV AH,0x00
    MOV DL,0x01
    INT 0x13
    jmp retry_fill_fat
error_fat:
    mov al, ah
    MOV AH,0x0e
    int 0x10
    mov ah, 0x0e
    mov al, ' '
    int 0x10
    mov al, 'e'
    int 0x10
    mov al, 'r'
    int 0x10
    mov al, 'r'
    int 0x10
    mov al, ' '
    int 0x10
next_fat:
    ret
workout:
    add ax, 31      
    cwd
    mov cx, 36
    idiv cx
    mov ch, al
    inc dx
    cmp dx, 19
    mov dh, 0
    jl finish
    sub dl, 18
    mov dh ,1
    finish:
    mov cl, dl
    ret
currentDirSector:
    resb 3

enter_dir:
    mov ax, 15
    call workout
    IO_BIOS ch, dh, cl, 0x02, 1, oneSecFile, next_read
    ret
	
format:
	mov si, 0
retry:
    mov ax, 0
    mov es, ax
    mov ch, 0
    mov dh, 0
    mov cl, 1       
    mov ah, 0x03
    mov al, 1
    mov bx, fatContent
    mov dl, 0x01
    int 0x13
    jnc next
    add si, 1
    cmp si, 5
    jae error
    MOV AH,0x00
    MOV DL,0x01
    INT 0x13
    jmp retry
	
error:
    mov al, ah
    MOV AH,0x0e
    int 0x10
    mov ah, 0x0e
    mov al, ' '
    int 0x10
    mov al, 'e'
    int 0x10
    mov al, 'r'
    int 0x10
    mov al, 'r'
    int 0x10
    mov al, ' '
    int 0x10
next:
    ret
log:
    mov ah, 0x0e
    mov al, ' '
    int 0x10
    mov al, 'l'
    int 0x10
    mov al, 'o'
    int 0x10
    mov al, 'g'
    int 0x10
    mov al, ' '
    int 0x10
    ret
boot:
    call read
main:
    call input
    jmp main
fin:
		HLT
		JMP		fin
		
help:
		db 'w+filename+content => create file and write content to file...   r+filename =>  read file    f => format floppy'
helplen equ $-help		