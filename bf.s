.intel_syntax noprefix

/* System calls */
.equ SYS_EXIT,			60

.global _start

main:
	call		_start

_start:
	/* create a new stack frame */
    push        rbp
    mov         rbp, rsp

exit:
	leave
	mov			rax, SYS_EXIT
	mov			rdi, 0
	syscall
