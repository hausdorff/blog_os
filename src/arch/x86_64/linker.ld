/* Linker script builds an ELF executable that can be booted through GRUB. This
 * looks something like this (though perhaps with different addresses):
 *
 *   Idx Name          Size      Address          Type
 *     0               00000000 0000000000000000
 *     1 .boot         00000018 0000000000100000 DATA
 *     2 .text         00000100 0000000000100020 TEXT DATA
 *     3 .bss          00003040 0000000000101000 BSS
 *
 *   SYMBOL TABLE:
 *   0000000000000000         *UND*		 00000000
 *   0000000000100000 l    d  .boot		 00000000 .boot
 *   0000000000100020 l    d  .text		 00000000 .text
 *   0000000000101000 l    d  .bss		 00000000 .bss
 *   0000000000000000 l    df *ABS*		 00000000 src/arch/x86_64/multiboot_header.asm
 *   0000000000100000         .boot		 00000000 header_start
 *   0000000000100018         .boot		 00000000 header_end
 *   0000000000000000 l    df *ABS*		 00000000 src/arch/x86_64/boot.asm
 *   0000000000100049         .text		 00000000 check_multiboot
 *   0000000000100051         .text		 00000000 check_multiboot.no_multiboot
 *   0000000000100058         .text		 00000000 check_cpuid
 *   000000000010006c         .text		 00000000 check_cpuid.no_cpuid
 *   0000000000100073         .text		 00000000 check_long_mode
 *   0000000000100091         .text		 00000000 check_long_mode.no_long_mode
 *   0000000000100095         .text		 00000000 set_up_page_tables
 *   00000000001000b4         .text		 00000000 set_up_page_tables.map_p2_table
 *   00000000001000d1         .text		 00000000 enable_paging
 *   00000000001000fc         .text		 00000000 error
 *   0000000000101000         .bss		 00000000 p4_table
 *   0000000000102000         .bss		 00000000 p3_table
 *   0000000000103000         .bss		 00000000 p2_table
 *   0000000000104000         .bss		 00000000 stack_bottom
 *   0000000000104040         .bss		 00000000 stack_top
 *   0000000000000000 l    df *ABS*		 00000000
 *   0000000000100120 l       .text		 00000000 _GLOBAL_OFFSET_TABLE_
 *   0000000000100020         .text		 00000000 start
 */

ENTRY(start)

SECTIONS {
    . = 1M;  /* Start at 1MiB to avoid things like VGA buffer. */

    .boot :
    {
        /* ensure that the multiboot header is at the beginning */
        *(.multiboot_header)
    }

    .text :
    {
        *(.text)
    }
}
