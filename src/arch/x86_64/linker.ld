/* Linker script builds an ELF executable that can be booted through GRUB. */

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
