SECTIONS {
  . = 0x10000;
  .text : { *(.text) }
  . = 0x8000000;
  .data : { *(.data) }

  .init_array : {
	  PROVIDE_HIDDEN (__init_array_start = .);
	  KEEP (*(.init_array))
	  PROVIDE_HIDDEN (__init_array_end = .);
  }

  .fini_array : {
	  PROVIDE_HIDDEN (__fini_array_start = .);
	  KEEP (*(.fini_array))
	  PROVIDE_HIDDEN (__fini_array_end = .);
  }

  .test_array : {
	  PROVIDE_HIDDEN (__test_array_start = .);
	  KEEP (*(.test_array))
	  PROVIDE_HIDDEN (__test_array_end = .);
  }

  .bss : { *(.bss) }
}
