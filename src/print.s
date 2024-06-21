.intel_syntax noprefix

.data

negative:       .ascii "-"

.text

.intel_syntax noprefix

.global strlen
.global print_string
.global print_usigned_int
.global print_signed_int
.global printf

/*
    Get length of a zero-delimitered string

    Inputs:
        rsi: string

    Modifies:
        rax, rcx

    Output registers:
        rax: length
*/
strlen:
    push        rcx
    push        rsi
    xor         rax, rax
    xor         rcx, rcx

strlen_loop:
    inc         rcx
    lodsb
    cmp         al, 0
    jne         strlen_loop
    /* if al == '\0' */
    mov         rax, rcx
    pop         rsi
    pop         rcx
    /* substract the null terminator character from the count */
    dec         rax
    ret

/*
    Abstraction for write syscall.

    Input registers:
        r12: *buffer
        r13: length

    Modifies:
        rax, rdi, rsi, rdx
*/
print_string:
    mov         rax, SYS_WRITE
    mov         rdi, STDOUT
    mov         rsi, r12
    mov         rdx, r13
    syscall
    ret

/*
    Prints an unsigned int

    Input registers:
        r12: number

    Modifies:
        rax, rcx, rdx, r8, r9

    See also: malloc, free, print_string
*/
print_usigned_int:
    pushr       r12, r13, rbx, rdi
    /* determine how many digits are there in the number */
    mov         rax, r12
    xor         rcx, rcx

digit_counter_loop:
    inc         rcx
    xor         rdx, rdx
    mov         rbx, 10
    /* rax / 10 */
    div         rbx
    /* push remainder to the stack */
    push        rdx
    test        rax, rax
    jnz         digit_counter_loop
    /* allocate memory according to the counted value */
    push        rcx
    malloc      rcx
    pop         rcx

    mov         r8, rcx
    mov         r9, rax
    lea         rdi, [r9] 
    mov         rax, r12
store_digits_loop:
    pop         rax
    add         rax, '0'
    stosb
    loop        store_digits_loop

    lea         r12, [r9]
    mov         r13, r8
    call        print_string
    free        r9, r8
    popr        rdi, rbx, r13, r12
    ret

/*
    Prints a signed int

    Input registers:
        r12: num

    Modifies:
        rax

    See also: print_string, print_usigned_int
*/
print_signed_int:
    push        r12
    push        r13
    mov         rax, 0x8000000000000000
    test        r12, rax
    jnz         print_negative_sign
print_signed_int_cont:
    call        print_usigned_int
    pop         r13
    pop         r12
    ret

print_negative_sign:
    push        r12
    lea         r12, [negative]
    mov         r13, 1
    call        print_string
    pop         r12
    neg         r12
    jmp         print_signed_int_cont

/*
    Own implementation of C's printf (formatted print)

    Inputs: push to the stack

    Modifies:
        rax, rbx, rcx, rdx, rsi, rdi

    See also:
        print_string, print_usigned_int, print_signed_int
*/
printf:
    /* rcx stores the length of the string to print */
    xor         rcx, rcx
    /* rbx stores the index of the string */
    xor         rbx, rbx
    /* rdx stores the current parameter index */
    mov         rdx, 1
    mov         rdi, [rbp - 8]
    mov         rsi, rdi

check_char_loop:
    lodsb
    inc         rcx
    cmp         al, NULL_TERMINATOR
    je          end_string
    cmp         al, '%'
    je          handle_format
    jmp         check_char_loop

    /* print whatever upto now */
print_string_partial:
    pushr       r12, r13, rax, rdi, rsi, rdx, rcx
    mov         r12, rdi
    dec         rcx
    mov         r13, rcx
    call        print_string
    popr        rcx, rdx, rsi, rdi, rax, r13, r12
    mov         rdi, rsi
    xor         rcx, rcx
    ret

handle_format:
    call        print_string_partial
    lodsb
    cmp         al, 'd'
    je          handle_format_signed_ints
    cmp         al, 'u'
    je          handle_format_usigned_ints
    cmp         al, 's'
    je          handle_format_string
    jmp         handle_invalid_format_specifier

handle_format_signed_ints:
    inc         rdx
    pushr       r12, rax, rdi, rsi, rdx, rcx
    /* increment the parameter index */
    mov         rax, -8
    imul        rax, rdx
    mov         r12, [rbp + rax]
    call        print_signed_int
    popr        rcx, rdx, rsi, rdi, rax, r12
    mov         rdi, rsi
    jmp         check_char_loop

handle_format_usigned_ints:
    /* increment the parameter index */
    inc         rdx
    pushr       r12, rax, rdi, rsi, rdx, rcx
    mov         rax, -8
    imul        rax, rdx
    mov         r12, [rbp + rax]
    call        print_usigned_int
    popr        rcx, rdx, rsi, rdi, rax, r12
    mov         rdi, rsi
    jmp         check_char_loop

    jmp         check_char_loop

handle_format_string:
    inc         rdx
    pushr       r12, r13, rax, rdi, rsi, rdx, rcx
    mov         rax, -8
    imul        rax, rdx
    mov         rsi, [rbp + rax]
    call        strlen
    mov         r12, rsi
    mov         r13, rax
    call        print_string
    popr        rcx, rdx, rsi, rdi, rax, r12, r13
    mov         rdi, rsi
    jmp         check_char_loop

handle_invalid_format_specifier:
    pushr       r12, r13, rax, rdi, rsi, rdx, rcx
    /* just print the % */
    lea         r12, [rsi - 1]
    mov         r13, 1
    call        print_string
    popr        rcx, rdx, rsi, rdi, rax, r13, r12
    /* 
    we read the following character to find the format
    however, as the character is not relevant to a format specifier
    we should move rsi back to where that character was
    */
    dec         rsi
    mov         rdi, rsi
    mov         rcx, 1
    jmp         check_char_loop

end_string:
    call        print_string_partial
    ret
