.text
_error:
    neg x0, x0
    ret

.text ; .section .text.rt.syscall0
.global _rt.syscall0
_rt.syscall0:
    mov     x16, x0
    svc     #0x80
    b.hs    _error
    ret

.text ; .section .text.rt.syscall1
.global _rt.syscall1
_rt.syscall1:
    mov     x16, x0
    mov     x0, x1
    svc     #0x80
    b.hs    _error
    ret

.text ; .section .text.rt.syscall2
.global _rt.syscall2
_rt.syscall2:
    mov     x16, x0
    mov     x0, x1
    mov     x1, x2
    svc     #0x80
    b.hs    _error
    ret

.text ; .section .text.rt.syscall3
.global _rt.syscall3
_rt.syscall3:
    mov     x16, x0
    mov     x0, x1
    mov     x1, x2
    mov     x2, x3
    svc     #0x80
    b.hs    _error
    ret

.text ; .section .text.rt.syscall4
.global _rt.syscall4
_rt.syscall4:
    mov     x16, x0
    mov     x0, x1
    mov     x1, x2
    mov     x2, x3
    mov     x3, x4
    svc     #0x80
    b.hs    _error
    ret

.text ; .section .text.rt.syscall5
.global _rt.syscall5
_rt.syscall5:
    mov     x16, x0
    mov     x0, x1
    mov     x1, x2
    mov     x2, x3
    mov     x3, x4
    mov     x4, x5
    svc     #0x80
    b.hs    _error
    ret

.text ; .section .text.rt.syscall6
.global _rt.syscall6
_rt.syscall6:
    mov     x16, x0
    mov     x0, x1
    mov     x1, x2
    mov     x2, x3
    mov     x3, x4
    mov     x4, x5
    mov     x5, x6
    svc     #0x80
    b.hs    _error
    ret


.text ; .section .text.rt.sys_pipe
.global _rt.sys_pipe
_rt.sys_pipe:
    mov     x9, x1          ; Stash FD array
    mov     x16, x0
    svc     #0x80
    b.hs    _error
    stp     w0, w1, [x9]    ; Save results
    mov     x0, #0          ; Success
    ret

.text ; .section .text.rt.sys_fork
.global _rt.sys_fork
_rt.sys_fork:
    // ARM moves a 1 in to r1 here, but I can't see why.
    mov     x16, x0                     // Syscall code
    svc     #0x80                       // Trap to kernel
    b.hs    _error
    cbz     x1, Lparent                 // x1 == 0 indicates that we are the parent

    // Child
    mov     x0, #0
Lparent:
    ret

.text
.global _rt.get_c_errno
_rt.get_c_errno:
    stp     fp, lr, [sp, #-16]!
    mov     fp, sp
    bl      ___error
    ldr     w0, [x0]
    mov     sp, fp
    ldp     fp, lr, [sp], #16
    ret

.text
.global _rt.set_c_errno
_rt.set_c_errno:
    stp     fp, lr, [sp, #-16]!
    mov     fp, sp

    str     x0, [sp, #-16]!

    bl      ___error

    ldr     x1, [sp, #16]!
    str     x1, [x0]

    mov     sp, fp
    ldp     fp, lr, [sp, #16]!
    ret
