SECTIONS {
	.libc_init_array : {
		PROVIDE(__libc_init_array_start = .);
		KEEP(*(.init_array))
		PROVIDE(__libc_init_array_end = .);
	}
	.test_array : {
		PROVIDE(__test_array_start = .);
		KEEP(*(.test_array*))
		PROVIDE(__test_array_end = .);
	}
} INSERT AFTER .dynamic;
