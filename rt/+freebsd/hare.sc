PHDRS {
	headers PT_PHDR PHDRS;
	text PT_LOAD FILEHDR PHDRS;
	data PT_LOAD;
}
ENTRY(_start);
SECTIONS {
	. = 0x8000000;
	.text : {
		KEEP (*(.text))
		*(.text.*)
	} :text
	. = 0x80000000;
	.data : {
		KEEP (*(.data))
		*(.data.*)
	} :data

	.init_array : {
		PROVIDE_HIDDEN (__init_array_start = .);
		KEEP (*(.init_array))
		PROVIDE_HIDDEN (__init_array_end = .);
	} :data

	.fini_array : {
		PROVIDE_HIDDEN (__fini_array_start = .);
		KEEP (*(.fini_array))
		PROVIDE_HIDDEN (__fini_array_end = .);
	} :data

	.test_array : {
		PROVIDE_HIDDEN (__test_array_start = .);
		KEEP (*(.test_array))
		PROVIDE_HIDDEN (__test_array_end = .);
	} :data

	.bss : {
		KEEP (*(.bss))
		*(.bss.*)
	} :data
}
