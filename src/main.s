.intel_syntax noprefix

.include "src/system.s"
.include "src/print.s"

.global _start

/* The basis of Brainfuck revolves around the traversal of an array of at least 30000, 8-bit, integer elements, */
.equ NUM_CELLS,             30000
.equ CELL_WIDTH_BITS,       8
.equ BUFFER_SIZE,           2

.macro printr register=rax
    mov         r12, \register
    call        print_signed_int
.endm

.data

help:               .ascii "Brainfuck interpreter\nUsage: ./bf [file]\n"
helpLen             = $ - help
filenotfound:       .ascii "File not found.\n"
filenotfoundLen     = $ - filenotfound
runComplete:        .ascii "\nProgram completed!\n"
runCompleteLen      = $ - runComplete
inputPrompt:        .ascii "\nProgram input: "
inputPromptLen      = $ - inputPrompt
bufferSize:         .quad BUFFER_SIZE


.bss

.lcomm memory NUM_CELLS * CELL_WIDTH_BITS
.lcomm fileDesc SIZE_OF_INT
.lcomm fileBuffer SIZE_OF_POINTER
.lcomm inputBuffer 1

.text

main:
    call		_start

_start:
    /* create a new stack frame */
    push        rbp
    mov         rbp, rsp

    lea         r14, [memory]
    /* argc */
    cmp         qword ptr [rsp + 8], 1
    je          print_help
    /* file name */
    mov         rdi, [rsp + 24]
    call        open_file
    call        read_file
    call        close_file
    call        interpret
    jmp         exit

print_help:
    lea         r12, [help]
    mov         r13, helpLen
    call        print_string
    jmp         exit

open_file:
    mov         rax, SYS_OPEN
    mov         rdx, O_RDONLY
    syscall
    cmp         rax, ENOENT
    je          file_not_found
    mov         [fileDesc], rax
    ret

file_not_found:
    lea         r12, [filenotfound]
    mov         r13, filenotfoundLen
    call        print_string
    jmp         exit

read_file:
    /* find the file size with lseek syscall */
    mov         rax, SYS_LSEEK
    mov         rdi, [fileDesc]
    xor         rsi, rsi
    mov         rdx, SEEK_END 
    syscall
    mov         r15, rax

    /* seek back to the beginning of the file */
    mov         rax, SYS_LSEEK
    mov         rdi, [fileDesc]
    xor         rsi, rsi
    mov         rdx, SEEK_SET
    syscall

    malloc      r15

    mov         rsi, rax
    mov         rax, SYS_READ
    mov         rdi, [fileDesc]
    mov         rdx, r15
    syscall

    ret

close_file:
    mov         rax, SYS_CLOSE
    mov         rdi, [fileDesc]
    syscall
    ret

interpret:
    cmp         byte ptr [rsi], NULL
    je          end_of_file
    cmp         byte ptr [rsi], '+'
    je          increment
    cmp         byte ptr [rsi], '-'
    je          decrement
    cmp         byte ptr [rsi], '>'
    je          move_right
    cmp         byte ptr [rsi], '<'
    je          move_left
    cmp         byte ptr [rsi], '['
    je          loop_begin
    cmp         byte ptr [rsi], ']'
    je          loop_end
    cmp         byte ptr [rsi], '.'
    je          write
    cmp         byte ptr [rsi], ','
    je          read
__interpret_done_step:
    inc         rsi
    jmp         interpret

increment:
    inc         byte ptr [r14]
    jmp         __interpret_done_step

decrement:
    dec         byte ptr [r14]
    jmp         __interpret_done_step

move_right:
    inc         r14
    jmp         __interpret_done_step

move_left:
    dec         r14
    jmp         __interpret_done_step

loop_begin:
    /* TODO: enter only if the cell is not zero
    skip the body if it's zero */
    push        rsi
    jmp         __interpret_done_step

loop_end:
    cmp         byte ptr [r14], 0
    je          jump_out
    pop         rsi
    /* because __interpret_done_step does  inc rsi and we want to cancel that */
    dec         rsi
    jmp         __interpret_done_step

jump_out:
    mov         rax, rsi
    pop         rsi
    mov         rsi, rax
    jmp         __interpret_done_step

write:
    push        rsi
    mov         r12, r14
    mov         r13, 1
    call        print_string
    pop         rsi
    jmp         __interpret_done_step

read:
    push        rsi

    lea         r12, [inputPrompt]
    mov         r13, inputPromptLen
    call        print_string

    mov         rax, SYS_READ
    mov         rdi, STDIN
    lea         rsi, [inputBuffer]
    mov         rdx, 1
    syscall

    mov         al, byte ptr [inputBuffer]
    mov         byte ptr [r14], al

    pop         rsi
    jmp         __interpret_done_step


end_of_file:
    lea         r12, [runComplete]
    mov         r13, runCompleteLen
    call        print_string
    jmp         exit
