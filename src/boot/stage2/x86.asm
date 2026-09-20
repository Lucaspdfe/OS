[bits 32]

extern GDTR_32

%macro Enter_16R 0
    [bits 32]
    ; jump to 16-bit protected mode
    jmp     18h:.P16Mode
.P16Mode:
    [bits 16]

    ; unset Protection Enable (PE)
    mov     eax, cr0
    and     eax, ~1                 ; ~1 means every bit except the first one
    mov     cr0, eax

    ; long jump to 16-bit real mode
    jmp     00h:.RMode
.RMode:
    sti

    ; setup registers
    mov     ax, 0
    mov     ds, ax
    mov     es, ax
    mov     ss, ax
    ; done!
%endmacro

%macro Enter_32P 0
    [bits 16]
    cli

    ; load GDT
    lgdt    [GDTR_32]

    ; set Protection Enable (PE)
    mov     eax, cr0
    or      eax, 1
    mov     cr0, eax

    ; jump to 32-bit protected mode
    jmp     08h:.PMode
.PMode:
    [bits 32]

    ; setup registers
    mov     ax, 10h
    mov     ds, ax
    mov     es, ax
    mov     ss, ax

    ; done!
%endmacro

; Convert linear address to segment:offset address
; Args:
;    1 - linear address
;    2 - (out) target segment (e.g. es)
;    3 - target lower 16-bit half of #3 (e.g. ax)
%macro LinearToSegOffset 3
    mov     eax, %1
    mov     edx, eax
    shr     eax, 4
    mov     %2, ax
    and     edx, 0xF
    mov     %3, dx
%endmacro

; uint8_t __attribute__((cdecl)) inb(uint16_t port);
global inb
inb:
    ; [esp+0]: return address
    ; [esp+4]: uint16_t port
    ; eax:     zero-extended uint8_t return
    [bits 32]
    mov     dx, [esp + 4]
    xor     eax, eax
    in      al, dx
    ret

; void __attribute__((cdecl)) outb(uint16_t port, uint8_t value);
global outb
outb:
    ; [esp+0]: return address
    ; [esp+4]: uint16_t port
    ; [esp+8]: uint8_t value
    [bits 32]
    mov     dx, [esp + 4]
    mov     al, [esp + 8]
    out     dx, al
    ret

; uint8_t __attribute__((cdecl)) disk_read(uint8_t disk, uint64_t LBA, uint16_t sectors, void* buffer);
global disk_read
disk_read:
    [bits 32]

    ; new call frame
    push    ebp
    mov     ebp, esp

    Enter_16R

    [bits 16]

    ; [ebp+0]:  ebp
    ; [ebp+4]:  return address
    ; [ebp+8]:  uint8_t disk
    ; [ebp+12]: low uint64_t LBA
    ; [ebp+16]: high uint64_t LBA
    ; [ebp+20]: uint16_t sectors
    ; [ebp+24]: void* buffer
    ; eax:      uint8_t return

    ; sector count
    mov     ax, [ebp+20]
    mov     [DAP_SECTORS], ax
    
    ; buffer
    mov     eax, [ebp + 24]       ; buffer linear address
    LinearToSegOffset eax, es, ax
    mov     [DAP_SEGMENT], es
    mov     [DAP_OFFSET], ax

    ; LBA
    mov     eax, [ebp+12]
    mov     [DAP_LBA], eax
    mov     eax, [ebp+16]
    mov     [DAP_LBA+4], eax

    ; Extended Read (ah=0x42)
    mov     dl, [ebp+8]
    mov     si, DAP
    mov     ah, 42h
    int     13h

    jc      .error
.done:
    xor     eax, eax
    jmp     .exit
.error:
    mov     al, ah
    xor     ah, ah
.exit:
    push    eax

    Enter_32P

    pop     eax

    [bits 32]

    mov     esp, ebp
    pop     ebp
    ret

section .data

DAP:
	DAP_SIZE:           db 10h
	DAP_RESERVED:       db 00h
	DAP_SECTORS:        dw 0000h
	DAP_OFFSET:         dw 0000h
	DAP_SEGMENT:        dw 0000h
	DAP_LBA:			dq 00000000h