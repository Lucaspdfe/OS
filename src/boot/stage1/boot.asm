org  	7C00h
bits 	16

%define NL 0x0D, 0x0A


jmp 	short boot
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
EBR_ROOT_DIR_CLUSTER:		equ BPB_START + 2Ch		; dword
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

	; put the expected values in DAP
	mov 	ah, 16
	mov 	[DAP_PacketSize], ah

	; save drive number
	mov 	[EBR_DRIVE_NUMBER], dl

	; print loading message
	mov		si, loading_msg
	call 	puts

	; some BIOSes put us in 07C0:0000 instead of the expected 0000:7C00
	jmp 	0000h:main
main:
	; calculate first data sector
	movzx 	eax, word [BPB_RESERVED_SECTORS]		; eax = fat_boot->reserved_sector_count
	movzx 	ecx, byte [BPB_FATS]					
	imul 	ecx, dword [EBR_SECTORS_PER_FAT32]		; ecx = (fat_boot->table_count * fat_size)
	add 	eax, ecx								; eax = fat_boot->reserved_sector_count + (fat_boot->table_count * fat_size)
													; we ignore root_dir_sectors because it will always end up in 0 by FAT32 standard
	add		eax, dword [BPB_HIDDEN_SECTORS]			; forgot about the previous 1M (this is the VBR)
	mov 	dword [first_data_sector], eax

	; Find the LBA sector of the root directory
	mov 	eax, [EBR_ROOT_DIR_CLUSTER]
	call 	cluster2lba

	; read root directory's first cluster into 0x8000 (I am NOT following the FAT chain for the root directory, after I find the file and read it I'll start developing the cluster read...)
													; eax is already defined
	movzx 	cx, byte [BPB_SECTORS_PER_CLUSTER]
	mov 	bx, 8000h
	call 	disk_read

	; root directory is now at 8000h

	; find stage2
	mov 	bx, 8000h
.search_loop:
	cmp 	byte [bx], 0							; compare if we're in the end of the root directory
	je 		file_not_found
	mov 	di, bx									; di = directory entry
	mov 	si, STAGE2_FILENAME						; si = stage2 filename
	mov 	cx, 11									; cx = size of the filename
	repe 	cmpsb									; compare if the filename is the same as stage2
	je 		.found_file								; if yes file found
	add 	bx, 20h									; go to next directory entry
	jmp 	.search_loop
.found_file:
	; bx now contains the address for the directory entry
	movzx	eax, word [bx+26]						; eax = 0000LLLL
	movzx 	edx, word [bx+20]						; edx = 0000HHHH
	shl		edx, 16									; edx = HHHH0000
	or 		eax, edx								; eax = HHHHLLLL

	mov		bx, 500h
.read_loop:
	mov 	edx, eax								; save cluster
	call 	cluster2lba
	movzx	cx, byte [BPB_SECTORS_PER_CLUSTER]
	call	disk_read
	add		bx, word [BPB_BYTES_PER_SECTOR]
	mov 	eax, edx
	call 	next_cluster
	cmp		eax, 0x0FFFFFF7
	ja		.file_read								; jump if greater (is greater than or equal to (>=) 0x0FFFFFF8)
	je 		file_error								; if equals 0x0FFFFFF7 then this cluster has been marked as "bad"
	jmp 	.read_loop
.file_read:
	mov 	si, 500h
	call	puts

	jmp 	halt

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

;
; cluster2lba: converts cluster to lba
;
; args:
;	- eax: cluster
; output:
;	- eax: lba
;
cluster2lba:
	sub 	eax, 2									; eax = cluster - 2
	movzx 	ecx, byte [BPB_SECTORS_PER_CLUSTER]
	imul 	eax, ecx								; eax = (cluster - 2) * fat_boot->sectors_per_cluster
	add 	eax, dword [first_data_sector]			; eax = ((cluster - 2) * fat_boot->sectors_per_cluster) + first_data_sector
	ret

;
; disk_read: reads from disk
;
; args:
;	- eax: LBA
;	- cx: number of sectors to read
;	- es:bx: output buffer
;
disk_read:
	push 	dx
	push 	eax

	; set all necessary DAP variables
	mov 	[DAP_LBA], eax
	mov 	[DAP_Sectors], cx
	mov 	ax, es
	mov 	[DAP_SegmentOut], ax
	mov 	[DAP_OffsetOut], bx

	; call Extended Read (ah=42h)
	stc
	mov 	si, DAP
	mov 	ah, 42h
	mov		dl, [EBR_DRIVE_NUMBER]
	int 	13h
	jc 		read_error

	pop 	eax
	pop 	dx
	ret

;
; next_cluster: finds next cluster in FAT chain
;
; args:
;	- eax: current cluster
; output:
;	- eax: next cluster
;
next_cluster:
	push 	bx
	push 	ecx
	push 	edx

	; formula: fat_sector = first_fat_sector + ((cluster * 4) / sector_size)
	shl 	eax, 2 									; eax = cluster * 4
	xor 	edx, edx
	movzx 	ecx, word [BPB_BYTES_PER_SECTOR]
	div 	ecx										; eax = (cluster * 4) / sector_size
	movzx 	ecx, word [BPB_RESERVED_SECTORS]
	add		eax, ecx								; eax = first_fat_sector + ((cluster * 4) / sector_size)
	add 	eax, [BPB_HIDDEN_SECTORS]				; adds the hidden sectors
	
	; eax is the sector, edx is the sector offset (the byte where the cluster is at)
	mov		cx, 1									; 1 sector to read
	mov 	bx, 8000h
	call	disk_read

	mov 	bx, 8000h
	add		bx, dx 									; yes, I am adding only the low 16-bytes, only because a sector is smaller than 65536
	mov 	eax, dword [bx]							; table_value = *(unsigned int*)&FAT_table[ent_offset];
	and		eax, 0FFFFFFFh							; if (fat32) table_value &= 0x0FFFFFFF;

	pop 	edx
	pop 	ecx
	pop 	bx
	ret

; errors
read_error:
    mov     si, read_error_msg
    jmp		short error
file_error:
    mov     si, file_error_msg
    jmp     short error
file_not_found:
    mov     si, file_not_found_msg
error:
    call    puts
halt:
    cli
    hlt

; data
loading_msg:			db "[S1] Loading... ", NL, 0
read_error_msg:			db "[S1] E1!", NL, 0		; Read failed!
file_not_found_msg:		db "[S1] E2!", NL, 0		; Stage2 not found!
file_error_msg:			db "[S1] E3!", NL, 0		; File corrupted! (bad cluster)
STAGE2_FILENAME:    	db "TEST    TXT"

times 510-($-$$) db 0
db 0x55, 0xAA

; Disk Address Packet
DAP:
	DAP_PacketSize:		db 0
	DAP_Reserved:		db 0
	DAP_Sectors:		dw 0
	DAP_OffsetOut:		dw 0
	DAP_SegmentOut:		dw 0
	DAP_LBA:			dq 0

first_data_sector:  	dd 0