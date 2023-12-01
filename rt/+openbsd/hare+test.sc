SECTIONS {
	.test_array : {
		PROVIDE(__test_array_start	= .);
		KEEP(*(.test_array*))
		PROVIDE(__test_array_end	= .);
	}
} INSERT AFTER .bss; /* .bss was choosen arbitrarily. */
