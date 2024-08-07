__TCM_BASE = 0x00000000;
__TCM_SIZE = 0x00008000;

__RAM_BASE = 0x10000000;
__RAM_SIZE = 0x00080000;

MEMORY
{
  TCM (rx)  : ORIGIN = __TCM_BASE, LENGTH = __TCM_SIZE
  RAM  (rwx) : ORIGIN = __RAM_BASE, LENGTH = __RAM_SIZE
}


/* Linker script to place sections and symbol values.
 * It references following symbols, which must be defined in code:
 *   vectors : Entry point
 *
 * It defines following symbols, which code can use without definition:
 *   __code_start
 *   __exidx_start
 *   __exidx_end
 *   __data_start
 *   __data_end
 *   __preinit_array_start
 *   __preinit_array_end
 *   __init_array_start
 *   __init_array_end
 *   __fini_array_start
 *   __fini_array_end
 *   __bss_start__
 *   __bss_end__
 *   __stack
 */
ENTRY(_start)

SECTIONS
{
	.text_boot :
    {
        *(.vectors*)
    } > TCM
    
    .text :
    {
        __code_start = .;
        KEEP (*(SORT_NONE(.init)))
        *(.text*)
        KEEP (*(SORT_NONE(.fini)))

        /* .ctors */
        *crtbegin.o(.ctors)
        *crtbegin?.o(.ctors)
        *(EXCLUDE_FILE(*crtend?.o *crtend.o) .ctors)
        *(SORT(.ctors.*))
        *(.ctors)

        /* .dtors */
        *crtbegin.o(.dtors)
        *crtbegin?.o(.dtors)
        *(EXCLUDE_FILE(*crtend?.o *crtend.o) .dtors)
        *(SORT(.dtors.*))
        *(.dtors)

        *(.rodata .rodata.* .gnu.linkonce.r.*)

        KEEP (*(.eh_frame))
    } > RAM

    .ARM.extab :
    {
        *(.ARM.extab* .gnu.linkonce.armextab.*)
    } > RAM

    .ARM.exidx :
    {
        __exidx_start = .;
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
        __exidx_end = .;
        __code_end = .;
    } > RAM

    __etext = ALIGN(8);

    .data : AT (__etext)
    {
        __data_start = . ;
        *(.data .data.* .gnu.linkonce.d.*)
        SORT(CONSTRUCTORS)

        . = ALIGN(4);
        /* preinit data */
        PROVIDE_HIDDEN (__preinit_array_start = .);
        KEEP (*(.preinit_array))
        PROVIDE_HIDDEN (__preinit_array_end = .);

        . = ALIGN(4);
        /* init data */
        PROVIDE_HIDDEN (__init_array_start = .);
        KEEP (*(SORT(.init_array.*)))
        KEEP (*(.init_array))
        PROVIDE_HIDDEN (__init_array_end = .);

        . = ALIGN(4);
        /* finit data */
        PROVIDE_HIDDEN (__fini_array_start = .);
        KEEP (*(SORT(.fini_array.*)))
        KEEP (*(.fini_array))
        PROVIDE_HIDDEN (__fini_array_end = .);

        KEEP (*(.jcr*))
        __data_end = . ;        
    } > RAM

    .bss :
    {
        . = ALIGN(4);
        __bss_start__ = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(64);
        __bss_end__ = .;
    } > RAM AT > RAM

    .heap (NOLOAD) :
    {
        . = ALIGN(8);
        __heap_start = .;
        __end__ = .;
        PROVIDE(end = .);
        . = . + 0x1000;
        __heap_end = .;
    } > RAM

    .stack (NOLOAD) :
    {
        . = ALIGN(8);
        . = . + 0x8000;
        __stack = .;
    } > RAM
}
