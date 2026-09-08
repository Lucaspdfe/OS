org  	7C00h
bits 	16

%define NL 0x0D, 0x0A


jmp short boot
nop

%define BPB_START 7C00h


; -- BIOS Parameter Block (BPB) --
BPB_JUMP:					equ BPB_START + 00h		; 3 bytes
BPB_OEM:					equ BPB_START + 03h		; qword
BPB_BYTES_PER_SECTOR:		equ BPB_START + 0Bh		; word
BPB_SECTORS_PER_CLUSTER:	equ BPB_START + 0Dh		; byte
BPB_RESERVED_SECTORS:		equ BPB_START + 0Eh		; word
BPB_FATS:					equ BPB_START + 10h		; byte
BPB_ROOT_DIR_ENTRIES:		equ BPB_START + 11h		; word
BPB_TOTAL_SECTORS16:		equ BPB_START + 13h		; word
BPB_MEDIA_DESC_TYPE:		equ BPB_START + 15h		; byte
BPB_SECTORS_PER_FAT16:		equ BPB_START + 16h		; word
BPB_SECTORS_PER_TRACK:		equ BPB_START + 18h		; word
BPB_HEADS:					equ BPB_START + 1Ah		; word
BPB_HIDDEN_SECTORS:			equ BPB_START + 1Ch		; dword
BPB_TOTAL_SECTORS32:		equ BPB_START + 20h		; dword

; -- Extended Boot Record (EBR) --
EBR_SECTORS_PER_FAT32:		equ BPB_START + 24h		; dword
EBR_FLAGS:					equ BPB_START + 28h		; word
EBR_FAT_VERSION:			equ BPB_START + 2Ah		; word
EBR_CLUSTER_ROOT_DIR:		equ BPB_START + 2Ch		; dword
EBR_FSINFO_SECTOR:			equ BPB_START + 30h		; word
EBR_BACKUP_SECTOR:			equ BPB_START + 32h		; word
EBR_RESERVED:				equ BPB_START + 34h		; 12 bytes
EBR_DRIVE_NUMBER:			equ BPB_START + 40h		; byte
EBR_RESERVED_NT:			equ BPB_START + 41h		; byte
EBR_SIGNATURE:				equ BPB_START + 42h		; byte
EBR_SERIAL:					equ BPB_START + 43h		; dword
EBR_VOLUME_LABEL:			equ BPB_START + 47h		; 11 bytes
EBR_FS_IDENTIFIER:			equ BPB_START + 52h		; qword

times 5Ah-($-$$) db 0

boot:
	cld
	
	; set up segments and stack
	xor 	ax, ax
	mov 	ds, ax
	mov 	es, ax
	mov 	ss, ax
	mov 	sp, 0x7C00

	; save drive number
	mov [EBR_DRIVE_NUMBER], dl

	; clear screen
	mov 	ah, 0
	mov 	al, 3
	int 	10h

	; print loading message
	mov		si, loading_msg
	call 	puts

	cli
	hlt

;
; puts: prints a string to the screen
;
; args:
;	- ds:si: string pointer
;
puts:
	mov   	ah, 0x0e
.loop:
	lodsb
	test	al, al
	jz		.end
	int 	10h
	jmp 	.loop
.end:
	ret

loading_msg:		db "Loading...", 0

times 510-($-$$) db 0
db 0x55, 0xAA
