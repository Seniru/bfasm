.intel_syntax noprefix

.equ NULL,                  0
.equ FALSE,                 0
.equ TRUE,                  1
.equ STDIN,                 0
.equ STDOUT,                1
.equ NULL_TERMINATOR,       0
.equ SIZE_OF_CHAR,          1
.equ SIZE_OF_SHORT,         2
.equ SIZE_OF_INT,           4
.equ SIZE_OF_LONG,          8
.equ SIZE_OF_POINTER,       8

/*  system calls */
.equ SYS_READ,              0
.equ SYS_WRITE,             1
.equ SYS_OPEN, 				2
.equ SYS_CLOSE,				3
.equ SYS_LSEEK,				8
.equ SYS_MMAP,              9
.equ SYS_MUNMAP,            11
.equ SYS_EXIT,              60

/*  flags, options, etc. */
.equ O_RDONLY,				0
.equ PROT_READ,             1
.equ PROT_WRITE,            2
.equ MAP_PRIVATE,           2
.equ MAP_ANONYMOUS,         32
.equ SEEK_SET,				0
.equ SEEK_END,				2
.equ ENOENT,				-2

.global malloc
.global free
.global mmap
.global munmap
.global exit

/*
    Macro to push registers

    Parameters
        r1, r2,...
*/
.macro pushr regs:vararg
    .irp register,\regs
        push \register
    .endr
.endm

/*
    Macro to pop registers

    Parameters:
        r1, r2, ...
*/
.macro popr regs:vararg
    .irp register,\regs
        pop \register
    .endr
.endm
/*
    Macro for mmap, this is not the actual malloc offered by C.
    Instead it uses the mmap syscall

    Parameters:
        size

    Modifies: rax, rcx, rdi, rsi, rdx, r8, r9, r10
    
    Return registers:
        rax: addr

    See also: mmap
*/
.macro malloc size
    push         r12
    mov          r12, \size
    call         mmap
    pop          r12
.endm

/*
    Macro for munmap, this is not the free offered by C.
    Instead it uses munmap syscall.

    Parameters:
        addr, len

    Modifies:
        rax, rdi, rsi

    See also: munmap
        
*/
.macro free addr, len
    push        r12
    push        r13
    mov         r12, \addr
    mov         r13, \len
    call        munmap
    pop         r13
    pop         r12
.endm

.text

/*
    Abstracts the mmap syscall

    Input registers:
        r12: size

    Modifies:
        rax, rcx, rdi, rsi, rdx, r8, r9, r10

    Output registers:
        rax: address
*/
mmap:
    mov         rax, SYS_MMAP
    mov         rdi, NULL
    mov         rsi, r12
    mov         rdx, PROT_READ | PROT_WRITE
    mov         r10, MAP_PRIVATE | MAP_ANONYMOUS
    mov         r8, -1
    mov         r9, 0
    syscall
    ret

/*
    Abstraction for munmap syscall

    Input registers:
        r12: address
        r13: size

    Modifies:
        rax, rdi, rsi
*/
munmap:
    mov         rax, SYS_MUNMAP
    mov         rdi, r12
    mov         rsi, r13
    syscall
    ret


exit:
    leave
    mov         rax, SYS_EXIT
    /* return code (0) */
    xor         rdi, rdi
    syscall
