// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export def SYS_syscall                         : u64 =   0;
export def SYS_exit                            : u64 =   1;
export def SYS_fork                            : u64 =   2;
export def SYS_read                            : u64 =   3;
export def SYS_write                           : u64 =   4;
export def SYS_open                            : u64 =   5;
export def SYS_close                           : u64 =   6;
export def SYS_wait4                           : u64 =   7;
			// 8  old creat
export def SYS_link                            : u64 =   9;
export def SYS_unlink                          : u64 =  10;
			// 11  old execv
export def SYS_chdir                           : u64 =  12;
export def SYS_fchdir                          : u64 =  13;
export def SYS_mknod                           : u64 =  14;
export def SYS_chmod                           : u64 =  15;
export def SYS_chown                           : u64 =  16;
			// 17  old break
export def SYS_getfsstat                       : u64 =  18;
			// 19  old lseek
export def SYS_getpid                          : u64 =  20;
			// 21  old mount
			// 22  old umount
export def SYS_setuid                          : u64 =  23;
export def SYS_getuid                          : u64 =  24;
export def SYS_geteuid                         : u64 =  25;
export def SYS_ptrace                          : u64 =  26;
export def SYS_recvmsg                         : u64 =  27;
export def SYS_sendmsg                         : u64 =  28;
export def SYS_recvfrom                        : u64 =  29;
export def SYS_accept                          : u64 =  30;
export def SYS_getpeername                     : u64 =  31;
export def SYS_getsockname                     : u64 =  32;
export def SYS_access                          : u64 =  33;
export def SYS_chflags                         : u64 =  34;
export def SYS_fchflags                        : u64 =  35;
export def SYS_sync                            : u64 =  36;
export def SYS_kill                            : u64 =  37;
			// 38  old stat
export def SYS_getppid                         : u64 =  39;
			// 40  old lstat
export def SYS_dup                             : u64 =  41;
export def SYS_pipe                            : u64 =  42;
export def SYS_getegid                         : u64 =  43;
			// 44  old profil
			// 45  old ktrace
export def SYS_sigaction                       : u64 =  46;
export def SYS_getgid                          : u64 =  47;
export def SYS_sigprocmask                     : u64 =  48;
export def SYS_getlogin                        : u64 =  49;
export def SYS_setlogin                        : u64 =  50;
export def SYS_acct                            : u64 =  51;
export def SYS_sigpending                      : u64 =  52;
export def SYS_sigaltstack                     : u64 =  53;
export def SYS_ioctl                           : u64 =  54;
export def SYS_reboot                          : u64 =  55;
export def SYS_revoke                          : u64 =  56;
export def SYS_symlink                         : u64 =  57;
export def SYS_readlink                        : u64 =  58;
export def SYS_execve                          : u64 =  59;
export def SYS_umask                           : u64 =  60;
export def SYS_chroot                          : u64 =  61;
			// 62  old fstat
			// 63  used internally and reserved
			// 64  old getpagesize
export def SYS_msync                           : u64 =  65;
export def SYS_vfork                           : u64 =  66;
			// 67  old vread
			// 68  old vwrite
			// 69  old sbrk
			// 70  old sstk
			// 71  old mmap
			// 72  old vadvise
export def SYS_munmap                          : u64 =  73;
export def SYS_mprotect                        : u64 =  74;
export def SYS_madvise                         : u64 =  75;
			// 76  old vhangup
			// 77  old vlimit
export def SYS_mincore                         : u64 =  78;
export def SYS_getgroups                       : u64 =  79;
export def SYS_setgroups                       : u64 =  80;
export def SYS_getpgrp                         : u64 =  81;
export def SYS_setpgid                         : u64 =  82;
export def SYS_setitimer                       : u64 =  83;
			// 84  old wait
export def SYS_swapon                          : u64 =  85;
export def SYS_getitimer                       : u64 =  86;
			// 87  old gethostname
			// 88  old sethostname
export def SYS_getdtablesize                   : u64 =  89;
export def SYS_dup2                            : u64 =  90;
			// 91  old getdopt
export def SYS_fcntl                           : u64 =  92;
export def SYS_select                          : u64 =  93;
			// 94  old setdopt
export def SYS_fsync                           : u64 =  95;
export def SYS_setpriority                     : u64 =  96;
export def SYS_socket                          : u64 =  97;
export def SYS_connect                         : u64 =  98;
			// 99  old accept
export def SYS_getpriority                     : u64 = 100;
			// 101  old send
			// 102  old recv
			// 103  old sigreturn
export def SYS_bind                            : u64 = 104;
export def SYS_setsockopt                      : u64 = 105;
export def SYS_listen                          : u64 = 106;
			// 107  old vtimes
			// 108  old sigvec
			// 109  old sigblock
			// 110  old sigsetmask
export def SYS_sigsuspend                      : u64 = 111;
			// 112  old sigstack
			// 113  old recvmsg
			// 114  old sendmsg
			// 115  old vtrace
export def SYS_gettimeofday                    : u64 = 116;
export def SYS_getrusage                       : u64 = 117;
export def SYS_getsockopt                      : u64 = 118;
			// 119  old resuba
export def SYS_readv                           : u64 = 120;
export def SYS_writev                          : u64 = 121;
export def SYS_settimeofday                    : u64 = 122;
export def SYS_fchown                          : u64 = 123;
export def SYS_fchmod                          : u64 = 124;
			// 125  old recvfrom
export def SYS_setreuid                        : u64 = 126;
export def SYS_setregid                        : u64 = 127;
export def SYS_rename                          : u64 = 128;
			// 129  old truncate
			// 130  old ftruncate
export def SYS_flock                           : u64 = 131;
export def SYS_mkfifo                          : u64 = 132;
export def SYS_sendto                          : u64 = 133;
export def SYS_shutdown                        : u64 = 134;
export def SYS_socketpair                      : u64 = 135;
export def SYS_mkdir                           : u64 = 136;
export def SYS_rmdir                           : u64 = 137;
export def SYS_utimes                          : u64 = 138;
export def SYS_futimes                         : u64 = 139;
export def SYS_adjtime                         : u64 = 140;
			// 141  old getpeername
export def SYS_gethostuuid                     : u64 = 142;
			// 143  old sethostid
			// 144  old getrlimit
			// 145  old setrlimit
			// 146  old killpg
export def SYS_setsid                          : u64 = 147;
			// 148  old setquota
			// 149  old qquota
			// 150  old getsockname
export def SYS_getpgid                         : u64 = 151;
export def SYS_setprivexec                     : u64 = 152;
export def SYS_pread                           : u64 = 153;
export def SYS_pwrite                          : u64 = 154;
export def SYS_nfssvc                          : u64 = 155;
			// 156  old getdirentries
export def SYS_statfs                          : u64 = 157;
export def SYS_fstatfs                         : u64 = 158;
export def SYS_unmount                         : u64 = 159;
			// 160  old async_daemon
export def SYS_getfh                           : u64 = 161;
			// 162  old getdomainname
			// 163  old setdomainname
			// 164
export def SYS_quotactl                        : u64 = 165;
			// 166  old exportfs
export def SYS_mount                           : u64 = 167;
			// 168  old ustat
export def SYS_csops                           : u64 = 169;
export def SYS_csops_audittoken                : u64 = 170;
			// 171  old wait3
			// 172  old rpause
export def SYS_waitid                          : u64 = 173;
			// 174  old getdents
			// 175  old gc_control
			// 176  old add_profil
export def SYS_kdebug_typefilter               : u64 = 177;
export def SYS_kdebug_trace_string             : u64 = 178;
export def SYS_kdebug_trace64                  : u64 = 179;
export def SYS_kdebug_trace                    : u64 = 180;
export def SYS_setgid                          : u64 = 181;
export def SYS_setegid                         : u64 = 182;
export def SYS_seteuid                         : u64 = 183;
export def SYS_sigreturn                       : u64 = 184;
			// 185  old chud
export def SYS_thread_selfcounts               : u64 = 186;
export def SYS_fdatasync                       : u64 = 187;
export def SYS_stat                            : u64 = 188;
export def SYS_fstat                           : u64 = 189;
export def SYS_lstat                           : u64 = 190;
export def SYS_pathconf                        : u64 = 191;
export def SYS_fpathconf                       : u64 = 192;
			// 193  old getfsstat
export def SYS_getrlimit                       : u64 = 194;
export def SYS_setrlimit                       : u64 = 195;
export def SYS_getdirentries                   : u64 = 196;
export def SYS_mmap                            : u64 = 197;
			// 198  old __syscall
export def SYS_lseek                           : u64 = 199;
export def SYS_truncate                        : u64 = 200;
export def SYS_ftruncate                       : u64 = 201;
export def SYS_sysctl                          : u64 = 202;
export def SYS_mlock                           : u64 = 203;
export def SYS_munlock                         : u64 = 204;
export def SYS_undelete                        : u64 = 205;
			// 206  old ATsocket
			// 207  old ATgetmsg
			// 208  old ATputmsg
			// 209  old ATsndreq
			// 210  old ATsndrsp
			// 211  old ATgetreq
			// 212  old ATgetrsp
			// 213  Reserved for AppleTalk
			// 214
			// 215
export def SYS_open_dprotected_np              : u64 = 216;
export def SYS_fsgetpath_ext                   : u64 = 217;
			// 218  old lstatv
			// 219  old fstatv
export def SYS_getattrlist                     : u64 = 220;
export def SYS_setattrlist                     : u64 = 221;
export def SYS_getdirentriesattr               : u64 = 222;
export def SYS_exchangedata                    : u64 = 223;
			// 224  old checkuseraccess or fsgetpath
export def SYS_searchfs                        : u64 = 225;
export def SYS_delete                          : u64 = 226;
export def SYS_copyfile                        : u64 = 227;
export def SYS_fgetattrlist                    : u64 = 228;
export def SYS_fsetattrlist                    : u64 = 229;
export def SYS_poll                            : u64 = 230;
			// 231  old watchevent
			// 232  old waitevent
			// 233  old modwatch
export def SYS_getxattr                        : u64 = 234;
export def SYS_fgetxattr                       : u64 = 235;
export def SYS_setxattr                        : u64 = 236;
export def SYS_fsetxattr                       : u64 = 237;
export def SYS_removexattr                     : u64 = 238;
export def SYS_fremovexattr                    : u64 = 239;
export def SYS_listxattr                       : u64 = 240;
export def SYS_flistxattr                      : u64 = 241;
export def SYS_fsctl                           : u64 = 242;
export def SYS_initgroups                      : u64 = 243;
export def SYS_posix_spawn                     : u64 = 244;
export def SYS_ffsctl                          : u64 = 245;
			// 246
export def SYS_nfsclnt                         : u64 = 247;
export def SYS_fhopen                          : u64 = 248;
			// 249
export def SYS_minherit                        : u64 = 250;
export def SYS_semsys                          : u64 = 251;
export def SYS_msgsys                          : u64 = 252;
export def SYS_shmsys                          : u64 = 253;
export def SYS_semctl                          : u64 = 254;
export def SYS_semget                          : u64 = 255;
export def SYS_semop                           : u64 = 256;
			// 257  old semconfig
export def SYS_msgctl                          : u64 = 258;
export def SYS_msgget                          : u64 = 259;
export def SYS_msgsnd                          : u64 = 260;
export def SYS_msgrcv                          : u64 = 261;
export def SYS_shmat                           : u64 = 262;
export def SYS_shmctl                          : u64 = 263;
export def SYS_shmdt                           : u64 = 264;
export def SYS_shmget                          : u64 = 265;
export def SYS_shm_open                        : u64 = 266;
export def SYS_shm_unlink                      : u64 = 267;
export def SYS_sem_open                        : u64 = 268;
export def SYS_sem_close                       : u64 = 269;
export def SYS_sem_unlink                      : u64 = 270;
export def SYS_sem_wait                        : u64 = 271;
export def SYS_sem_trywait                     : u64 = 272;
export def SYS_sem_post                        : u64 = 273;
export def SYS_sysctlbyname                    : u64 = 274;
			// 275  old sem_init
			// 276  old sem_destroy
export def SYS_open_extended                   : u64 = 277;
export def SYS_umask_extended                  : u64 = 278;
export def SYS_stat_extended                   : u64 = 279;
export def SYS_lstat_extended                  : u64 = 280;
export def SYS_fstat_extended                  : u64 = 281;
export def SYS_chmod_extended                  : u64 = 282;
export def SYS_fchmod_extended                 : u64 = 283;
export def SYS_access_extended                 : u64 = 284;
export def SYS_settid                          : u64 = 285;
export def SYS_gettid                          : u64 = 286;
export def SYS_setsgroups                      : u64 = 287;
export def SYS_getsgroups                      : u64 = 288;
export def SYS_setwgroups                      : u64 = 289;
export def SYS_getwgroups                      : u64 = 290;
export def SYS_mkfifo_extended                 : u64 = 291;
export def SYS_mkdir_extended                  : u64 = 292;
export def SYS_identitysvc                     : u64 = 293;
export def SYS_shared_region_check_np          : u64 = 294;
			// 295  old shared_region_map_np
export def SYS_vm_pressure_monitor             : u64 = 296;
export def SYS_psynch_rw_longrdlock            : u64 = 297;
export def SYS_psynch_rw_yieldwrlock           : u64 = 298;
export def SYS_psynch_rw_downgrade             : u64 = 299;
export def SYS_psynch_rw_upgrade               : u64 = 300;
export def SYS_psynch_mutexwait                : u64 = 301;
export def SYS_psynch_mutexdrop                : u64 = 302;
export def SYS_psynch_cvbroad                  : u64 = 303;
export def SYS_psynch_cvsignal                 : u64 = 304;
export def SYS_psynch_cvwait                   : u64 = 305;
export def SYS_psynch_rw_rdlock                : u64 = 306;
export def SYS_psynch_rw_wrlock                : u64 = 307;
export def SYS_psynch_rw_unlock                : u64 = 308;
export def SYS_psynch_rw_unlock2               : u64 = 309;
export def SYS_getsid                          : u64 = 310;
export def SYS_settid_with_pid                 : u64 = 311;
export def SYS_psynch_cvclrprepost             : u64 = 312;
export def SYS_aio_fsync                       : u64 = 313;
export def SYS_aio_return                      : u64 = 314;
export def SYS_aio_suspend                     : u64 = 315;
export def SYS_aio_cancel                      : u64 = 316;
export def SYS_aio_error                       : u64 = 317;
export def SYS_aio_read                        : u64 = 318;
export def SYS_aio_write                       : u64 = 319;
export def SYS_lio_listio                      : u64 = 320;
			// 321  old __pthread_cond_wait
export def SYS_iopolicysys                     : u64 = 322;
export def SYS_process_policy                  : u64 = 323;
export def SYS_mlockall                        : u64 = 324;
export def SYS_munlockall                      : u64 = 325;
			// 326
export def SYS_issetugid                       : u64 = 327;
export def SYS___pthread_kill                  : u64 = 328;
export def SYS___pthread_sigmask               : u64 = 329;
export def SYS___sigwait                       : u64 = 330;
export def SYS___disable_threadsignal          : u64 = 331;
export def SYS___pthread_markcancel            : u64 = 332;
export def SYS___pthread_canceled              : u64 = 333;
export def SYS___semwait_signal                : u64 = 334;
			// 335  old utrace
export def SYS_proc_info                       : u64 = 336;
export def SYS_sendfile                        : u64 = 337;
export def SYS_stat64                          : u64 = 338;
export def SYS_fstat64                         : u64 = 339;
export def SYS_lstat64                         : u64 = 340;
export def SYS_stat64_extended                 : u64 = 341;
export def SYS_lstat64_extended                : u64 = 342;
export def SYS_fstat64_extended                : u64 = 343;
export def SYS_getdirentries64                 : u64 = 344;
export def SYS_statfs64                        : u64 = 345;
export def SYS_fstatfs64                       : u64 = 346;
export def SYS_getfsstat64                     : u64 = 347;
export def SYS___pthread_chdir                 : u64 = 348;
export def SYS___pthread_fchdir                : u64 = 349;
export def SYS_audit                           : u64 = 350;
export def SYS_auditon                         : u64 = 351;
			// 352
export def SYS_getauid                         : u64 = 353;
export def SYS_setauid                         : u64 = 354;
			// 355  old getaudit
			// 356  old setaudit
export def SYS_getaudit_addr                   : u64 = 357;
export def SYS_setaudit_addr                   : u64 = 358;
export def SYS_auditctl                        : u64 = 359;
export def SYS_bsdthread_create                : u64 = 360;
export def SYS_bsdthread_terminate             : u64 = 361;
export def SYS_kqueue                          : u64 = 362;
export def SYS_kevent                          : u64 = 363;
export def SYS_lchown                          : u64 = 364;
			// 365  old stack_snapshot
export def SYS_bsdthread_register              : u64 = 366;
export def SYS_workq_open                      : u64 = 367;
export def SYS_workq_kernreturn                : u64 = 368;
export def SYS_kevent64                        : u64 = 369;
export def SYS___old_semwait_signal            : u64 = 370;
export def SYS___old_semwait_signal_nocancel   : u64 = 371;
export def SYS_thread_selfid                   : u64 = 372;
export def SYS_ledger                          : u64 = 373;
export def SYS_kevent_qos                      : u64 = 374;
export def SYS_kevent_id                       : u64 = 375;
			// 376
			// 377
			// 378
			// 379
export def SYS___mac_execve                    : u64 = 380;
export def SYS___mac_syscall                   : u64 = 381;
export def SYS___mac_get_file                  : u64 = 382;
export def SYS___mac_set_file                  : u64 = 383;
export def SYS___mac_get_link                  : u64 = 384;
export def SYS___mac_set_link                  : u64 = 385;
export def SYS___mac_get_proc                  : u64 = 386;
export def SYS___mac_set_proc                  : u64 = 387;
export def SYS___mac_get_fd                    : u64 = 388;
export def SYS___mac_set_fd                    : u64 = 389;
export def SYS___mac_get_pid                   : u64 = 390;
			// 391
			// 392
			// 393
export def SYS_pselect                         : u64 = 394;
export def SYS_pselect_nocancel                : u64 = 395;
export def SYS_read_nocancel                   : u64 = 396;
export def SYS_write_nocancel                  : u64 = 397;
export def SYS_open_nocancel                   : u64 = 398;
export def SYS_close_nocancel                  : u64 = 399;
export def SYS_wait4_nocancel                  : u64 = 400;
export def SYS_recvmsg_nocancel                : u64 = 401;
export def SYS_sendmsg_nocancel                : u64 = 402;
export def SYS_recvfrom_nocancel               : u64 = 403;
export def SYS_accept_nocancel                 : u64 = 404;
export def SYS_msync_nocancel                  : u64 = 405;
export def SYS_fcntl_nocancel                  : u64 = 406;
export def SYS_select_nocancel                 : u64 = 407;
export def SYS_fsync_nocancel                  : u64 = 408;
export def SYS_connect_nocancel                : u64 = 409;
export def SYS_sigsuspend_nocancel             : u64 = 410;
export def SYS_readv_nocancel                  : u64 = 411;
export def SYS_writev_nocancel                 : u64 = 412;
export def SYS_sendto_nocancel                 : u64 = 413;
export def SYS_pread_nocancel                  : u64 = 414;
export def SYS_pwrite_nocancel                 : u64 = 415;
export def SYS_waitid_nocancel                 : u64 = 416;
export def SYS_poll_nocancel                   : u64 = 417;
export def SYS_msgsnd_nocancel                 : u64 = 418;
export def SYS_msgrcv_nocancel                 : u64 = 419;
export def SYS_sem_wait_nocancel               : u64 = 420;
export def SYS_aio_suspend_nocancel            : u64 = 421;
export def SYS___sigwait_nocancel              : u64 = 422;
export def SYS___semwait_signal_nocancel       : u64 = 423;
export def SYS___mac_mount                     : u64 = 424;
export def SYS___mac_get_mount                 : u64 = 425;
export def SYS___mac_getfsstat                 : u64 = 426;
export def SYS_fsgetpath                       : u64 = 427;
export def SYS_audit_session_self              : u64 = 428;
export def SYS_audit_session_join              : u64 = 429;
export def SYS_fileport_makeport               : u64 = 430;
export def SYS_fileport_makefd                 : u64 = 431;
export def SYS_audit_session_port              : u64 = 432;
export def SYS_pid_suspend                     : u64 = 433;
export def SYS_pid_resume                      : u64 = 434;
export def SYS_pid_hibernate                   : u64 = 435;
export def SYS_pid_shutdown_sockets            : u64 = 436;
			// 437  old shared_region_slide_np
export def SYS_shared_region_map_and_slide_np  : u64 = 438;
export def SYS_kas_info                        : u64 = 439;
export def SYS_memorystatus_control            : u64 = 440;
export def SYS_guarded_open_np                 : u64 = 441;
export def SYS_guarded_close_np                : u64 = 442;
export def SYS_guarded_kqueue_np               : u64 = 443;
export def SYS_change_fdguard_np               : u64 = 444;
export def SYS_usrctl                          : u64 = 445;
export def SYS_proc_rlimit_control             : u64 = 446;
export def SYS_connectx                        : u64 = 447;
export def SYS_disconnectx                     : u64 = 448;
export def SYS_peeloff                         : u64 = 449;
export def SYS_socket_delegate                 : u64 = 450;
export def SYS_telemetry                       : u64 = 451;
export def SYS_proc_uuid_policy                : u64 = 452;
export def SYS_memorystatus_get_level          : u64 = 453;
export def SYS_system_override                 : u64 = 454;
export def SYS_vfs_purge                       : u64 = 455;
export def SYS_sfi_ctl                         : u64 = 456;
export def SYS_sfi_pidctl                      : u64 = 457;
export def SYS_coalition                       : u64 = 458;
export def SYS_coalition_info                  : u64 = 459;
export def SYS_necp_match_policy               : u64 = 460;
export def SYS_getattrlistbulk                 : u64 = 461;
export def SYS_clonefileat                     : u64 = 462;
export def SYS_openat                          : u64 = 463;
export def SYS_openat_nocancel                 : u64 = 464;
export def SYS_renameat                        : u64 = 465;
export def SYS_faccessat                       : u64 = 466;
export def SYS_fchmodat                        : u64 = 467;
export def SYS_fchownat                        : u64 = 468;
export def SYS_fstatat                         : u64 = 469;
export def SYS_fstatat64                       : u64 = 470;
export def SYS_linkat                          : u64 = 471;
export def SYS_unlinkat                        : u64 = 472;
export def SYS_readlinkat                      : u64 = 473;
export def SYS_symlinkat                       : u64 = 474;
export def SYS_mkdirat                         : u64 = 475;
export def SYS_getattrlistat                   : u64 = 476;
export def SYS_proc_trace_log                  : u64 = 477;
export def SYS_bsdthread_ctl                   : u64 = 478;
export def SYS_openbyid_np                     : u64 = 479;
export def SYS_recvmsg_x                       : u64 = 480;
export def SYS_sendmsg_x                       : u64 = 481;
export def SYS_thread_selfusage                : u64 = 482;
export def SYS_csrctl                          : u64 = 483;
export def SYS_guarded_open_dprotected_np      : u64 = 484;
export def SYS_guarded_write_np                : u64 = 485;
export def SYS_guarded_pwrite_np               : u64 = 486;
export def SYS_guarded_writev_np               : u64 = 487;
export def SYS_renameatx_np                    : u64 = 488;
export def SYS_mremap_encrypted                : u64 = 489;
export def SYS_netagent_trigger                : u64 = 490;
export def SYS_stack_snapshot_with_config      : u64 = 491;
export def SYS_microstackshot                  : u64 = 492;
export def SYS_grab_pgo_data                   : u64 = 493;
export def SYS_persona                         : u64 = 494;
			// 495
export def SYS_mach_eventlink_signal           : u64 = 496;
export def SYS_mach_eventlink_wait_until       : u64 = 497;
export def SYS_mach_eventlink_signal_wait_until: u64 = 498;
export def SYS_work_interval_ctl               : u64 = 499;
export def SYS_getentropy                      : u64 = 500;
export def SYS_necp_open                       : u64 = 501;
export def SYS_necp_client_action              : u64 = 502;
export def SYS___nexus_open                    : u64 = 503;
export def SYS___nexus_register                : u64 = 504;
export def SYS___nexus_deregister              : u64 = 505;
export def SYS___nexus_create                  : u64 = 506;
export def SYS___nexus_destroy                 : u64 = 507;
export def SYS___nexus_get_opt                 : u64 = 508;
export def SYS___nexus_set_opt                 : u64 = 509;
export def SYS___channel_open                  : u64 = 510;
export def SYS___channel_get_info              : u64 = 511;
export def SYS___channel_sync                  : u64 = 512;
export def SYS___channel_get_opt               : u64 = 513;
export def SYS___channel_set_opt               : u64 = 514;
export def SYS_ulock_wait                      : u64 = 515;
export def SYS_ulock_wake                      : u64 = 516;
export def SYS_fclonefileat                    : u64 = 517;
export def SYS_fs_snapshot                     : u64 = 518;
export def SYS_register_uexc_handler           : u64 = 519;
export def SYS_terminate_with_payload          : u64 = 520;
export def SYS_abort_with_payload              : u64 = 521;
export def SYS_necp_session_open               : u64 = 522;
export def SYS_necp_session_action             : u64 = 523;
export def SYS_setattrlistat                   : u64 = 524;
export def SYS_net_qos_guideline               : u64 = 525;
export def SYS_fmount                          : u64 = 526;
export def SYS_ntp_adjtime                     : u64 = 527;
export def SYS_ntp_gettime                     : u64 = 528;
export def SYS_os_fault_with_payload           : u64 = 529;
export def SYS_kqueue_workloop_ctl             : u64 = 530;
export def SYS___mach_bridge_remote_time       : u64 = 531;
export def SYS_coalition_ledger                : u64 = 532;
export def SYS_log_data                        : u64 = 533;
export def SYS_memorystatus_available_memory   : u64 = 534;
			// 535
export def SYS_shared_region_map_and_slide_2_np: u64 = 536;
export def SYS_pivot_root                      : u64 = 537;
export def SYS_task_inspect_for_pid            : u64 = 538;
export def SYS_task_read_for_pid               : u64 = 539;
export def SYS_preadv                          : u64 = 540;
export def SYS_pwritev                         : u64 = 541;
export def SYS_preadv_nocancel                 : u64 = 542;
export def SYS_pwritev_nocancel                : u64 = 543;
export def SYS_ulock_wait2                     : u64 = 544;
export def SYS_proc_info_extended_id           : u64 = 545;
export def SYS_MAXSYSCALL                      : u64 = 546;
export def SYS_invalid                         : u64 =  63;
