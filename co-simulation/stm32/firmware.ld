MEMORY {
  FLASH : ORIGIN = 0x08000000, LENGTH = 1024K
  RAM : ORIGIN = 0x20000000, LENGTH = 128K
}
ENTRY(Reset)
SECTIONS {
  .vectors ORIGIN(FLASH) : {
    LONG(0x20020000);
    LONG(Reset);
    . = ORIGIN(FLASH) + 60;
    LONG(SysTick);
  } > FLASH
  .text : { *(.text*) *(.rodata*) } > FLASH
  .bss (NOLOAD) : { *(.bss*) *(COMMON) } > RAM
  /DISCARD/ : { *(.ARM.exidx*) *(.note.gnu.build-id*) }
}
