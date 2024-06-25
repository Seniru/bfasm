.intel_syntax noprefix

.global strcmp
.global strlen

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
    cmp         al, NULL
    jne         strlen_loop
    mov         rax, rcx
    pop         rsi
    pop         rcx
    /* substract the null terminator character from the count */
    dec         rax
    ret


/*
	Compares two strings. Returns 1 if equal, returns 0 if not.

	Inputs:
		r12: str1
		r13: str2

	Modifies:
		rax, rbx, rax, rdx

	Output registers:
		rax: return value
*/
strcmp:
	xor			rcx, rcx
	xor			rax, rax
strcmp_loop:
	mov			dl, byte ptr [r12 + rcx]
	mov			bl, byte ptr [r13 + rcx]
	cmp			dl, bl
	jne			str_not_equal
	cmp			dl, NULL
	je			end_string1
	cmp			bl, NULL
	/* since string1 has not reached end yet, 
		string2 reaching the end means they are not equal.
		Therefore, these 2 strings are not equal.
	*/
	je			str_not_equal
	inc			rcx
	jmp			strcmp_loop
end_string1:
	cmp			bl, NULL
	je			str_equal
	jmp			str_not_equal

str_equal:
	mov			rax, 1
	ret
str_not_equal:
	xor			rax, rax
	ret
