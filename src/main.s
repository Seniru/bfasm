.intel_syntax noprefix

.include "src/system.s"
.include "src/string.s"
.include "src/print.s"
.include "src/interpret.s"

.global _start

/* The basis of Brainfuck revolves around the traversal of an array of at least 30000, 8-bit, integer elements, */
.equ NUM_CELLS,             30000
.equ CELL_WIDTH_BITS,       8
.equ BUFFER_SIZE,           2
.equ ESCAPE_CHARACTER,      27

.macro printr register=rax
    mov         r12, \register
    call        print_signed_int
.endm

.macro printchar character
    pushr   r12, r13, rax, rbx, rcx, rdx, rsi, rdi
    lea     r12, \character
    mov     r13, 1
    call    print_string
    popr    rdi, rsi, rdx, rcx, rbx, rax, r13, r12
.endm

.macro printunicode character
    pushr   r12, r13, rax, rbx, rcx, rdx, rsi, rdi
    lea     r12, \character
    mov     r13, 3
    call    print_string
    popr    rdi, rsi, rdx, rcx, rbx, rax, r13, r12
.endm

.macro printunicode_nopreserve character
    lea     r12, \character
    mov     r13, 3
    call    print_string

.endm

.macro printchar_nopreserve character
    lea     r12, \character
    mov     r13, 1
    call    print_string
.endm

.macro is_flag flagname
    lea         r13, \flagname
    push        rcx
    call        strcmp
    pop         rcx
    cmp         rax, TRUE
.endm

.macro p_repeat character time
    malloc      \time
    mov         rdi, rax
    mov         rax, [\character]
    mov         rcx, \time
    rep stos    byte ptr [rdi]
    sub         rdi, \time
    mov         r12, rdi
    mov         r13, \time
    call        print_string
    free        rdi, \time
.endm

.data

help:               .ascii "Brainfuck interpreter\n"
                    .ascii "Usage: ./bf [options] [--file filename | --code code]\n"
                    .ascii "-f, --file filename :\tRead the code from the file\n"
                    .ascii "-c, --code code :\tProgram passed in as a string\n"
                    .ascii "\nOptions:\n"
                    .ascii "-d, --debug :\tStart the program in the debugging mode\n"
helpLen             = $ - help

filenotfound:       .ascii "File not found.\n"
filenotfoundLen     = $ - filenotfound
runComplete:        .ascii "\nProgram completed!\n"
runCompleteLen      = $ - runComplete
inputPrompt:        .ascii "\nProgram input: "
inputPromptLen      = $ - inputPrompt
errAmbigiousFlag:   .ascii "Error: Ambibious flag\n"
errAmbigiousFlagLen = $ - errAmbigiousFlag
errUnknownFlag:     .ascii "Error: Unknown flag\n"
errUnknownFlagLen   = $ - errUnknownFlag
errInvalidArg:      .ascii "Error: Invalid argument\n"
errInvalidArgLen    = $ - errInvalidArg

codeLabel:          .ascii "[Code]"
codeLabelLen        = $ - codeLabel
memoryLabel:        .ascii "[Memory]"
memoryLabelLen      = $ - memoryLabel
outputLabel:        .ascii "\033[0m\033[1;7m Output"
outputLabelLen      = $ - outputLabel
pointerLabel:       .ascii "Pointer: "
pointerLabelLen     = $ - pointerLabel

partition.horizontalwall:     .byte 0xe2, 0x94, 0x80 # ─
partition.verticalwall:       .byte 0xe2, 0x94, 0x82 # │
partition.topleftwall:        .byte 0xe2, 0x94, 0x8c # ┌
partition.toprightwall:       .byte 0xe2, 0x94, 0x90 # ┐
partition.bottomleftwall:     .byte 0xe2, 0x94, 0x94 # └
partition.bottomrightwall:    .byte 0xe2, 0x94, 0x98 # ┘

bufferSize:         .quad BUFFER_SIZE
currentProcess:     .quad 0
pointer:            .quad 0
outputBufferPos:    .quad 0
scrollY:            .short 0
curInstDisplayable: .byte TRUE
finished:           .short FALSE
fileFlagSet:        .byte FALSE
codeFlagSet:        .byte FALSE
debugFlagSet:       .byte FALSE
memoryOffset:       .quad memory
codeOffset:         .quad 0

fileFlagName1:      .asciz "-f"
fileFlagName2:      .asciz "--file"
codeFlagName1:      .asciz "-c"
codeFlagName2:      .asciz "--code"
debugFlagName1:     .asciz "-d"
debugFlagName2:     .asciz "--debug"

smcup:              .ascii "\033[?1049h"
rmcup:              .ascii "\033[?1049l"
clr:                .ascii "\033[2J\033[H"
reset:              .ascii "\033[0m"
bold:               .ascii "\033[1m"
inverse:            .ascii "\033[7m"
red:                .ascii "\033[31m"
yellow:             .ascii "\033[33m"
blue:               .ascii "\033[34m"
cyan:               .ascii "\033[36m"
white:              .ascii "\033[37m"
grey:               .ascii "\033[90m"
bgWhite:            .ascii "\033[;100m"
newline:            .ascii "\n"
space:              .ascii " "
colon:              .ascii ": "


/*
struct sigaction {
    void        (*sa_handler)(int);
    void        (*sa_sigaction)(int, siginfo_t *, void *);
    sigset_t    sa_mask;
    int         sa_flags;
    void        (*sa_restorer)(void);
};
*/
sigaction_winch:
    .quad init_debug_window
    .quad 0x04000000
    .quad winch_restorer
    .quad 


.bss

.lcomm memory NUM_CELLS * CELL_WIDTH_BITS
.lcomm fileDesc SIZE_OF_INT
.lcomm fileBuffer SIZE_OF_POINTER
.lcomm inputBuffer 2
.lcomm fileFlag SIZE_OF_POINTER
.lcomm codeFlag SIZE_OF_POINTER
.lcomm winsize 2 * SIZE_OF_SHORT
.lcomm panelHeight SIZE_OF_SHORT /* floor(winsize.columns / 3) */
.lcomm pointersPerLine SIZE_OF_SHORT
.lcomm memoryCellRows SIZE_OF_SHORT
.lcomm old_termios SIZEOF_TERMIOS
.lcomm new_termios SIZEOF_TERMIOS
.lcomm code SIZE_OF_POINTER
.lcomm currentInstruction SIZE_OF_POINTER
.lcomm outputBuffer 1024 /* 1kb */

.text

main:
    call		_start

_start:
    /* create a new stack frame */
    push        rbp
    mov         rbp, rsp

    call        config_terminal_settings
    lea         r14, [memory]
    /* argc */
    cmp         qword ptr [rsp + 8], 1
    je          print_help

    call        parse_args

    cmp         byte ptr [fileFlagSet], TRUE
    je          handle_file
    cmp         byte ptr [codeFlagSet], TRUE
    je          handle_code

__main_cont1:
    mov         qword ptr [currentInstruction], rsi
    cmp         byte ptr [debugFlagSet], TRUE
    je          debug
__main_cont2:
    call        interpret
    jmp         exit

debug:
    push        rsi
    lea         r12, [smcup]
    mov         r13, 8
    call        print_string

    mov         rax, SYS_RT_SIGACTION
    mov         rdi, SIG_WINCH
    lea         rsi, [sigaction_winch]
    xor         rdx, rdx
    mov         r10, 0x08
    syscall
    call        init_debug_window
    pop         rsi
    jmp         input_process
   


input_process:
    push        rsi
redraw_debug_window:
    xor         rax, rax
    call        draw_debug_window
     /* if return from draw_debug_window is 1, a redraw is requested */
    cmp         rax, 1
    je          redraw_debug_window

    mov         rax, SYS_READ
    mov         rdi, STDIN
    lea         rsi, [inputBuffer]
    mov         rdx, 1
    syscall
    mov         al, byte ptr [rsi]
    cmp         al, '\n'
    je          interpret_once
    cmp         al, ESCAPE_CHARACTER
    je          handle_escapes
    pop         rsi
    jmp         input_process
interpret_once:
    pop         rsi        
    jmp         interpret

handle_escapes:
    /* get the sequence */
    mov         rax, SYS_READ
    mov         rdi, STDIN
    lea         rsi, [inputBuffer]
    mov         rdx, 2
    syscall

    xor         rax, rax
    mov         al, byte ptr [rsi + 1]
    cmp         al, 'A'
    je          scroll_up
    cmp         al, 'B'
    je          scroll_down

    pop         rsi
    jmp         input_process

scroll_down:
    inc         word ptr [scrollY]
    pop         rsi
    jmp         input_process

scroll_up:
    dec         word ptr [scrollY]
    cmp         word ptr [scrollY], 0
    jle         scroll_reset_up
    pop         rsi
    jmp         input_process

scroll_reset_up:
    mov         word ptr [scrollY], 0
    pop         rsi
    jmp         input_process


print_help:
    lea         r12, [help]
    mov         r13, helpLen
    call        print_string
    jmp         exit

parse_args:
    mov         rcx, 1
parse_args_loop:
    mov         rsi, qword ptr [rsp + 24 + rcx * SIZE_OF_POINTER]
    lodsb
    cmp         al, '-'
    je          set_flag
    jmp         invalid_argument
__parse_args_loop_cont:
    inc         rcx
    cmp         rcx, qword ptr [rsp + 16]
    jl          parse_args_loop
    ret

set_flag:
    mov         r12, qword ptr [rsp + 24 + rcx * SIZE_OF_POINTER]
    is_flag     [fileFlagName1]
    je          set_file_flag
    is_flag     [fileFlagName2]
    je          set_file_flag
    is_flag     [codeFlagName1]
    je          set_code_flag
    is_flag     [codeFlagName2]
    je          set_code_flag
    is_flag     [debugFlagName1]
    je          set_debug_flag
    is_flag     [debugFlagName2]
    je          set_debug_flag
    jmp         unknown_flag

set_file_flag:
    cmp         byte ptr [fileFlagSet], TRUE
    je          ambigious_flag
    cmp         byte ptr [codeFlagSet], TRUE
    je          ambigious_flag
    mov         byte ptr [fileFlagSet], TRUE
    inc         rcx
    mov         rax, qword ptr [rsp + 24 + rcx * SIZE_OF_POINTER]
    mov         qword ptr [fileFlag], rax     
    jmp         __parse_args_loop_cont

set_code_flag:
    cmp         byte ptr [fileFlagSet], TRUE
    je          ambigious_flag
    cmp         byte ptr [codeFlagSet], TRUE
    je          ambigious_flag
    mov         byte ptr [codeFlagSet], TRUE
    inc         rcx
    mov         rax, qword ptr [rsp + 24 + rcx * SIZE_OF_POINTER]
    mov         qword ptr [codeFlag], rax
    jmp         __parse_args_loop_cont

set_debug_flag:
    mov         byte ptr [debugFlagSet], TRUE
    jmp         __parse_args_loop_cont

ambigious_flag:
    lea         r12, [errAmbigiousFlag]
    mov         r13, errAmbigiousFlagLen
    call        print_string
    jmp         exit

unknown_flag:
    lea         r12, [errUnknownFlag]
    mov         r13, errUnknownFlagLen
    call        print_string
    jmp         exit

invalid_argument:
    lea         r12, [errInvalidArg]
    mov         r13, errInvalidArgLen
    call        print_string
    jmp         exit

update_dimensions:
    mov         rax, SYS_IOCTL
    mov         rdi, STDIN
    mov         rsi, TIOCGWINSZ
    lea         rdx, [winsize]
    syscall

    xor         rax, rax
    xor         rbx, rbx
    xor         rdx, rdx
    mov         ax, [winsize]
    mov         bx, 3
    div         bx
    mov         [panelHeight], al

    xor         rax, rax
    mov         al, byte ptr [winsize + 2]
    sub         ax, 10
    mov         bx, 4
    idiv        bx
    mov         byte ptr [pointersPerLine], al

    mov         al, byte ptr [panelHeight]
    sub         al, 4
    mov         byte ptr [memoryCellRows], al

    ret

init_debug_window:
    call        update_dimensions
    call        draw_debug_window
    ret

draw_debug_window:
    lea         r12, [clr]
    mov         r13, 7
    call        print_string

    call        draw_memory_panel
    printchar   [newline]
    call        draw_code_panel
    cmp         rax, 1
    je          __draw_debug_window_ret
    printchar   [newline]
    call        draw_output_panel
    xor         rax, rax
__draw_debug_window_ret:
    ret

draw_code_panel:
    printunicode_nopreserve [partition.topleftwall]
    printunicode_nopreserve [partition.horizontalwall]
    lea         r12, [bold]
    mov         r13, 4
    call        print_string
    lea         r12, [codeLabel]
    mov         r13, codeLabelLen
    call        print_string
    /* calculate how much columns left to fill */
    xor         rcx, rcx
    mov         cx, word ptr [winsize + 2]
    sub         cx, codeLabelLen
    sub         cx, 3
draw_code_panel_topwall_loop:
    push        rcx
    printunicode_nopreserve [partition.horizontalwall]
    pop         rcx
    loop        draw_code_panel_topwall_loop
    printunicode_nopreserve [partition.toprightwall]
    printchar   [newline]

    /* code partition */
    printunicode_nopreserve [partition.verticalwall]
    printchar   [space]
    lea         r12, [reset]
    mov         r13, 4
    call        print_string

    call        print_code
    cmp         rax, 1
    je          __draw_code_panel_ret
    
    printunicode_nopreserve [partition.bottomleftwall]
    xor         rcx, rcx
    mov         cx, word ptr [winsize + 2]
    sub         cx, 2
draw_code_panel_bottomwall_loop:
    push        rcx
    printunicode_nopreserve [partition.horizontalwall]
    pop         rcx
    loop        draw_code_panel_bottomwall_loop
    printunicode_nopreserve [partition.bottomrightwall]
    xor         rax, rax
__draw_code_panel_ret:
    ret

print_code:
    mov         byte ptr [curInstDisplayable], FALSE
    push        rsi
    mov         rbx, qword ptr [currentInstruction]
    inc         rbx
    mov         rsi, qword ptr [code]
    #add         rsi, 4
    add         rsi, qword ptr [codeOffset]
    xor         rcx, rcx
    mov         rdx, 2
print_code_loop:
    inc         cx
    lodsb
    cmp         rsi, rbx
    je          highlight_current_operator
__print_code_loop_cont:
    cmp         al, NULL
    je          print_code_end
    cmp         al, '\n'
    je          print_code_newline

    pushr       rax, rsi, rcx, rdx, rbx
    dec         rsi
    call        highlight_operator
    lea         r12, [reset]
    mov         r13, 4
    call        print_string
    popr        rbx, rdx, rcx, rsi, rax

    jmp         print_code_loop

highlight_operator:
    push        rsi
    
    lea         r12, [grey]
    lea         rax, [red]
    mov         r13, 5
    mov         rbx, 5

    cmp         byte ptr [rsi], '<'
    cmove       r12, rax
    cmp         byte ptr [rsi], '>'
    cmove       r12, rax

    lea         rax, [blue]
    cmp         byte ptr [rsi], '+'
    cmove       r12, rax
    cmp         byte ptr [rsi], '-'
    cmove       r12, rax

    lea         rax, [white]
    cmp         byte ptr [rsi], '['
    cmove       r12, rax
    cmp         byte ptr [rsi], ']'
    cmove       r12, rax
    cmp         byte ptr [rsi], '.'
    cmove       r12, rax
    cmp         byte ptr [rsi], ','
    cmove       r12, rax
    
    mov         r13, 5
    call        print_string

    pop         rsi
    push        rsi
    mov         r12, rsi
    mov         r13, 1
    call        print_string
    lea         r12, [reset]
    mov         r13, 4
    call        print_string
    pop         rsi
    ret

highlight_current_operator:
    mov         byte ptr [curInstDisplayable], TRUE

    pushr       rsi, rax, rbx, rcx, rdx
    lea         r12, [bgWhite]
    mov         r13, 7
    call        print_string
    popr        rdx, rcx, rbx, rax, rsi
    jmp         __print_code_loop_cont

print_code_newline:
    inc         rdx
    cmp         dl, byte ptr [panelHeight]
    je          print_code_end
    push        rbx
    xor         rbx, rbx
    add         cx, 2
    mov         bl, byte ptr [winsize + 2]
    sub         bx, cx
    mov         r15, rbx
    pushr       rsi, rdx
    p_repeat    space, r15
    lea         r12, [cyan]
    mov         r13, 5
    call        print_string
    printunicode [partition.verticalwall]
    printchar   [newline]
    printunicode [partition.verticalwall]
    lea         r12, [reset]
    mov         r13, 4
    call        print_string
    printchar   [space]
    popr        rdx, rsi
    xor         rcx, rcx
    pop         rbx
    jmp         print_code_loop

print_code_end:
    /* check if we could display the current instruction */
    xor         rax, rax    
    cmp         byte ptr [curInstDisplayable], FALSE
    je         adjust_code_buffer
    
    xor         rbx, rbx
    mov         bl, byte ptr [winsize + 2]
    sub         bx, cx
    sub         bx, 2
    mov         r15, rbx
    push        rdx
    p_repeat    space, r15
    lea         r12, [cyan]
    mov         r13, 5
    call        print_string
    printunicode_nopreserve [partition.verticalwall]
    printchar   [newline]
    pop         rdx
    /* fill out the rest of the panel if the code is short */
    xor         rcx, rcx
    mov         cl, byte ptr [panelHeight]
    cmp         rdx, rcx
    jl          print_code_fill_remainder
__print_code_end_cont:
    xor         rax, rax
    pop         rsi
    ret

adjust_code_buffer:
    mov         rbx, qword ptr [code]
    mov         rsi, qword ptr [currentInstruction]
    #sub         qword ptr [codeOffset], rsi
    sub         rsi, rbx
    #printr      rbx
    #mov         qword ptr [codeOffset], rbx
    mov         qword ptr [codeOffset], rsi
    /* return with 1 to indicate redraw */
    mov         rax, 1
    pop         rsi
    ret


print_code_fill_remainder:
    sub         rcx, rdx
    sub         rcx, 1
    xor         rax, rax
    mov         al, byte ptr [winsize + 2]
    mov         r15, rax
    sub         r15, 2
print_code_fill_remainder_loop:
    push        rcx
    # printchar_nopreserve [newline]
    printunicode_nopreserve [partition.verticalwall]
    p_repeat    space, r15

    printunicode_nopreserve [partition.verticalwall]
    printchar_nopreserve [newline]
    pop         rcx
    /* can't use loop because the loop label is out of reach according to stackoverflow */
    /* https://stackoverflow.com/questions/22672809/why-does-the-loop-instruction-result-in-value-of-288-too-large-for-field-of-1 */
    /* loop        print_code_fill_remainder_loop */
    dec         rcx
    cmp         rcx, 0
    jg          print_code_fill_remainder_loop
    jmp         __print_code_end_cont

    

draw_memory_panel:
    lea         r12, [cyan]
    mov         r13, 5
    call        print_string
    printunicode_nopreserve [partition.topleftwall]
    printunicode_nopreserve [partition.horizontalwall]
    lea         r12, [bold]
    mov         r13, 4
    call        print_string
    lea         r12, [memoryLabel]
    mov         r13, memoryLabelLen
    call        print_string
    /* calculate how much columns left to fill */
    xor         rcx, rcx
    mov         cx, word ptr [winsize + 2]
    sub         cx, memoryLabelLen
    sub         cx, 3
draw_memory_panel_topwall_loop:
    push        rcx
    printunicode_nopreserve [partition.horizontalwall]
    pop         rcx
    loop        draw_memory_panel_topwall_loop
    printunicode_nopreserve [partition.toprightwall]
    printchar   [newline]

    printunicode_nopreserve [partition.verticalwall]
    lea         r12, [reset]
    mov         r13, 4
    call        print_string
    printchar   [space]

    /* print the pointer label */
    lea         r12, [yellow]
    mov         r13, 5
    call        print_string
    lea         r12, [pointerLabel]
    mov         r13, pointerLabelLen
    call        print_string
    lea         r12, [reset]
    mov         r13, 4
    call        print_string
    
    mov         r12, qword ptr [pointer]
    mov         r13, 5
    push        rsi
    call        print_int_padded
    pop         rsi

    xor         rax, rax
    mov         al, byte ptr [winsize + 2]
    mov         r15, rax
    sub         r15, pointerLabelLen
    sub         r15, 8
    p_repeat    space, r15
    lea         r12, [cyan]
    mov         r13, 5
    call        print_string
    printunicode_nopreserve [partition.verticalwall]
    printchar   [newline]

    /* newline for a nice interface design */
    lea         r12, [cyan]
    mov         r13, 5
    call        print_string
    printunicode_nopreserve [partition.verticalwall]
    xor         rax, rax
    mov         al, byte ptr [winsize + 2]
    mov         r15, rax
    sub         r15, 2
    p_repeat    space, r15
    printunicode_nopreserve [partition.verticalwall]
    printchar   [newline]

    /* memory partition */
    xor         rdx, rdx
    /* r10 is the starting cell */
    xor         rax, rax
    mov         ax, word ptr [scrollY]
    imul        ax, [pointersPerLine]
    mov         r10, rax
print_cell_rows_loop:
    push        rdx
    lea         r12, [cyan]
    mov         r13, 5
    call        print_string
    printunicode_nopreserve [partition.verticalwall]
    printchar   [space]
    lea         r12, [blue]
    mov         r13, 5
    call        print_string

    pop         rdx
    push        rdx
    add         dx, word ptr [scrollY]
    xor         rax, rax
    push        r10
    mov         al, byte ptr [pointersPerLine]
    imul        dl
    mov         r12, rax
    mov         r13, 5
    call        print_int_padded
    pop         r10
    lea         r12, [colon]
    mov         r13, 2
    call        print_string
    lea         r12, [reset]
    mov         r13, 4
    call        print_string

    xor         rcx, rcx
    mov         cl, byte ptr [pointersPerLine]
print_cells_loop:
    push        rcx
    cmp         r10, qword ptr [pointer]
    je          highlight_current_cell
    xor         rax, rax
    mov         rbx, [memoryOffset]
    mov         al, byte ptr [rbx + r10]
    mov         r12, rax
    mov         r13, 3
    push        r10
    call        print_int_padded
    pop         r10
__print_cells_loop_cont:
    printchar   [space]
    pop         rcx
    inc         r10
    loop        print_cells_loop
    printchar   [space]

    xor         rax, rax
    xor         rbx, rbx
    mov         al, byte ptr [pointersPerLine]
    imul        ax, 4
    mov         bx, [winsize + 2]
    sub         bx, ax
    sub         bx, 11
    mov         r15, rbx
    p_repeat    space, r15
    lea         r12, [cyan]
    mov         r13, 5
    call        print_string
    printunicode_nopreserve [partition.verticalwall]
    printchar   [newline]

    pop         rdx
    inc         dl
    cmp         dl, byte ptr [memoryCellRows]
    jl          print_cell_rows_loop


    /* end the panel */
    printunicode_nopreserve [partition.bottomleftwall]
    xor         rcx, rcx
    mov         cx, word ptr [winsize + 2]
    sub         cx, 2
draw_memory_panel_bottomwall_loop:
    push        rcx
    printunicode_nopreserve [partition.horizontalwall]
    pop         rcx
    loop        draw_memory_panel_bottomwall_loop
    printunicode_nopreserve [partition.bottomrightwall]
    ret

highlight_current_cell:
    lea         r12, [bgWhite]
    mov         r13, 7
    call        print_string
    
    xor         rax, rax
    mov         rbx, [memoryOffset]
    mov         al, byte ptr [rbx + r10]
    mov         r12, rax
    mov         r13, 3
    push        r10
    call        print_int_padded

    lea         r12, [reset]
    mov         r13, 4
    call        print_string
    pop         r10

    jmp         __print_cells_loop_cont


draw_output_panel:
    lea         r12, [outputLabel]
    mov         r13, outputLabelLen
    call        print_string
    xor         rcx, rcx
    mov         cx, word ptr [winsize + 2]
    sub         cx, 7
    mov         r15, rcx
    p_repeat    [space], r15
    lea         r12, [reset]
    mov         r13, 4
    call        print_string
    printchar_nopreserve [newline]

    lea         r12, [outputBuffer]
    mov         r13, qword ptr [outputBufferPos]
    call        print_string
    ret


handle_code:
    mov        rsi, qword ptr [codeFlag]
    mov        qword ptr [code], rsi
    jmp         __main_cont1

handle_file:
    /* file name */
    mov         rdi, qword ptr [fileFlag]
    # mov         rdi, [rdi]
    call        open_file
    call        read_file
    call        close_file
    jmp         __main_cont1

open_file:
    mov         rax, SYS_OPEN
    xor         rsi, rsi
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

    mov         qword ptr [code], rsi

    ret

close_file:
    mov         rax, SYS_CLOSE
    mov         rdi, [fileDesc]
    syscall
    ret



config_terminal_settings:
    /* save original terminal settings */
    tcgets      [old_termios]
    /* copy old settings into new settings */
    tcgets      [new_termios]
    /* modify new settings */
    and         word ptr [new_termios + 12], CLEAR_FLAG
    mov         byte ptr [new_termios + 18 + VMIN], 1
    mov         byte ptr [new_termios + 18 + VTIME], 3

    mov         rax, SYS_IOCTL
    mov         rdi, STDIN
    mov         rsi, TCSETS
    lea         rdx, [new_termios]
    syscall
    ret

reset_terminal:
    lea         r12, [rmcup]
    mov         r13, 9
    call        print_string
    jmp         __end_of_file_cont

winch_restorer:
    mov         rax, SYS_RT_SIGRETURN
    xor         rdi, rdi
    syscall
    ret

end_of_file:
    mov         byte ptr [finished], TRUE
    cmp         byte ptr [debugFlagSet], TRUE
    je          reset_terminal
__end_of_file_cont:
    lea         r12, [runComplete]
    mov         r13, runCompleteLen
    call        print_string
    /* reset termio settings */
    mov         rax, SYS_IOCTL
    mov         rdi, STDIN
    mov         rsi, TCSETS
    lea         rdx, [old_termios]
    syscall

    jmp         exit
