[bits 16]

section     .entry

global      entry
entry:
    ; set up segments and stack
    mov     ax, 0
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    mov     ss, ax
    mov     sp, 0h                          ; starting at 0 because stack grows downward (to 0FFFFh) before writing

    ; save boot disk
    mov     [BootDisk], dl

    ; clear the screen
    mov     ah, 0
    mov     al, 3
    int     10h

    ; enable A20 (fast A20)
    in      al, 92h
    or      al, 02h
    and     al, 0FEh
    out     92h, al

    ; disable NMI and maskable interrupts
    in      al, 70h
    or      al, 80h
    out     70h, al
    cli

    ; set GDT
    lgdt    [GDTR_32]

    ; set Protection Enable (PE)
    mov     eax, cr0
    or      eax, 1
    mov     cr0, eax

    ; jump to 32-bit
    jmp 08h:PMain
PMain:
    [bits 32]
    ; 32-BITS LETS FUCKING GO!!!!!

    mov     ax, 10h
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    mov     ss, ax

    mov     [0B8000h], 'h'
    mov     [0B8002h], 'i'
    mov     [0B8004h], '!'

    cli
    hlt

[bits 16]

section .rodata

global      GDTR_32
global      GDTR_64

GDTR_32: 
    dw      (GDTEnd - GDTStart) - 1
    dd      GDTStart

GDTR_64: 
    dw      (GDTEnd - GDTStart) - 1
    dd      GDTStart
    dd      0

GDTStart:
    ; null entry (entry 00h)
    dq      0h

    ; 32-bit code segment (entry 08h)
    dw      0FFFFh                          ; limit  (00..15)
    dw      00000h                          ; base   (00..15)
    db      000h                            ; base   (16..23)
    db      10011011b                       ; access (present, ring 0, code segment, direction 0, readable)     
    db      11001111b                       ; flags  (4 KiB blocks, 32-bit protected mode) 
                                            ; limit  (16..19)
    db      000h                            ; base   (24..31)

    ; 32-bit data segment (entry 10h)
    dw      0FFFFh                          ; limit  (00..15)
    dw      00000h                          ; base   (00..15)
    db      000h                            ; base   (16..23)
    db      10010011b                       ; access (present, ring 0, data segment, direction 0, writeable)     
    db      11001111b                       ; flags  (4 KiB blocks, 32-bit protected mode) 
                                            ; limit  (16..19)
    db      000h                            ; base   (24..31)

    ; 16-bit code segment (entry 18h)
    dw      0FFFFh                          ; limit  (00..15)
    dw      00000h                          ; base   (00..15)
    db      000h                            ; base   (16..23)   
    db      10011011b                       ; access (present, ring 0, code segment, direction 0, readable)     
    db      10001111b                       ; flags  (4 KiB blocks, 16-bit protected mode) 
                                            ; limit  (16..19)
    db      000h                            ; base   (24..31)

    ; 16-bit data segment (entry 20h)
    dw      0FFFFh                          ; limit  (00..15)
    dw      00000h                          ; base   (00..15)
    db      000h                            ; base   (16..23)   
    db      10010011b                       ; access (present, ring 0, data segment, direction 0, writeable)     
    db      10001111b                       ; flags  (4 KiB blocks, 16-bit protected mode) 
                                            ; limit  (16..19)
    db      000h                            ; base   (24..31)

    ; 64-bit code segment (entry 28h)
    dw      0FFFFh                          ; limit  (00..15)
    dw      00000h                          ; base   (00..15)
    db      000h                            ; base   (16..23)   
    db      10011011b                       ; access (present, ring 0, code segment, direction 0, readable)     
    db      10101111b                       ; flags  (4 KiB blocks, 64-bit long code) 
                                            ; limit  (16..19)
    db      000h                            ; base   (24..31)

    ; 64-bit data segment (entry 30h)
    dw      0FFFFh                          ; limit  (00..15)
    dw      00000h                          ; base   (00..15)
    db      000h                            ; base   (16..23)   
    db      10010011b                       ; access (present, ring 0, data segment, direction 0, writeable)     
    db      10001111b                       ; flags  (4 KiB blocks, 64-bit long data) 
                                            ; limit  (16..19)
    db      000h                            ; base   (24..31)
GDTEnd:

BootDisk:   db 0
