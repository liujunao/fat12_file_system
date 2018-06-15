; TAB=4
CYLS	equ		10				
		org		0x7c00			; ָ�������װ�ص�ַ
		jmp		entry
		DB		0x90
		DB		"OPENPLAC"		; �����������ƿ����������ַ�����8�ֽڣ�
		DW		512				; ÿ�������Ĵ�С������Ϊ512�ֽڣ�
		DB		1				; �صĴ�С������Ϊ1������
		DW		1				; FAT����ʼλ�ã�һ��ӵ�һ��������ʼ��
		DB		2				; FAT�ĸ���������Ϊ2��
		DW		224				; ��Ŀ¼��С��һ�����224�
		DW		2880			; �ô��̵Ĵ�С��������2880������
		DB		0xf0			; ���̵����ࣨ������0xf0��
		DW		9				; FAT�ĳ��ȣ�������9������
		DW		18				; 1���ŵ�����������������18��
		DW		2				; ��ͷ����������2��
		DD		0				; ��ʹ�÷�����������0��
		DD		2880			; ��дһ�δ��̴�С
		DB		0,0,0x29		; ���岻�����̶�
		DD		0xffffffff		; ������
		DB		"ABCDEFGHIJK"	; �������ƣ�11�ֽڣ�
		DB		"FAT12   "		; ���̸�ʽ���ƣ�8�ֽڣ�
		RESB	18				
; ������
entry:
		mov		AX,0			; ��ʼ���Ĵ���
		mov		SS,AX
		mov		SP,0x7c00
		mov		DS,AX	
		mov		AX,0x0820		; ���ö�����λ��
		mov		ES,AX
		mov		CH,0			; ����0
		mov		DH,0			; ��ͷ0
		mov		CL,2			; ����2
readloop:
		mov		SI,0			; ��¼ʧ�ܴ���
retry:							; ������
		mov		AH,0x02			; AH=0x02 : ����
		mov		AL,1			; 1������
		mov		BX,0
		mov		DL,0x00			; A������
		int		0x13			
		jnc		next			; û����ʱ��ת��next
		add		SI,1			; SI��1
		cmp		SI,5			; �Ƚ�SI��5
		jae		error			; SI >= 5 ʱ��ת��error
		mov		AH,0x00
		mov		DL,0x00			; A������
		int		0x13			; ����������
		jmp		retry
next:
		mov		AX,ES			; ���ڴ��ַ����0x200
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
		DB		0x0a, 0x0a		; ��������
		DB		"load error"
		DB		0x0a			; ����
		DB		0
		RESB	0x7dfe-($-$$)		
		DB		0x55, 0xaa