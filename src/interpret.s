.intel_syntax noprefix

.global interpret

.equ OUTPUT_BUFFER_SIZE,        3

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
    mov         qword ptr [currentInstruction], rsi
    cmp         byte ptr [debugFlagSet], TRUE
    je          input_process
    jmp         interpret

increment:
    inc         byte ptr [r14]
    jmp         __interpret_done_step

decrement:
    dec         byte ptr [r14]
    jmp         __interpret_done_step

move_right:
    inc         r14
    inc			qword ptr [pointer]
    jmp         __interpret_done_step

move_left:
    dec         r14
    dec         qword ptr [pointer]
    jmp         __interpret_done_step

loop_begin:
    xor         rcx, rcx
    cmp         byte ptr [r14], 0
    je          skip_loop
    push        rsi
    jmp         __interpret_done_step

skip_loop:
    lodsb
    cmp         al, '['
    je          skip_new_loop_begin
    cmp         al, ']'
    je          close_loop
__skip_loop_cont:
    jmp         skip_loop

skip_new_loop_begin:
    inc         rcx
    jmp         __skip_loop_cont

close_loop:
    dec         rcx
    dec         rsi
    cmp         rcx, 0
    je          __interpret_done_step
    inc         rsi
    jmp         __skip_loop_cont

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
    push        rcx
    mov         r12, r14
    mov         r13, 1
    call        print_string
    
    cmp         byte ptr [debugFlagSet], TRUE
    je          write_debug_output
__write_cont:    

    pop         rcx
    pop         rsi
    jmp         __interpret_done_step

write_debug_output:
    cmp         qword ptr [outputBufferPos], OUTPUT_BUFFER_SIZE
    jge         debug_output_reset
__write_debug_output_cont:
    lea         rsi, [outputBuffer]
    add         rsi, qword ptr [outputBufferPos]
    mov         cl, byte ptr [r14]
    mov         byte ptr [rsi], cl
    inc         qword ptr [outputBufferPos]
    jmp         __write_cont

debug_output_reset:
    mov         qword ptr [outputBufferPos], 0
    jmp         __write_debug_output_cont

read:
    push        rsi

    mov         rax, SYS_READ
    mov         rdi, STDIN
    lea         rsi, [inputBuffer]
    mov         rdx, 1
    syscall

    mov         al, byte ptr [inputBuffer]
    mov         byte ptr [r14], al

    pop         rsi
    jmp         __interpret_done_step

