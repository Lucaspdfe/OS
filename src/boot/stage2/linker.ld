ENTRY(entry)

SECTIONS {
    . = 500h;

    .entry : {
        KEEP(*(.entry))
    }

    .text : {
        *(.text)
        *(.text.*)
    }

    .rodata :
    {
        *(.rodata)
        *(.rodata.*)
    }

    .data :
    {
        *(.data)
        *(.data.*)
    }

    _bss_start = .;
    .bss :
    {
        *(COMMON)
        *(.bss)
        *(.bss.*)
    }
    _bss_end = .;
}