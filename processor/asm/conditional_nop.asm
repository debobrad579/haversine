global ConditionalNOP

ConditionalNOP:
    xor rax, rax
.loop:
    test byte [rsi + rax], 1
    jnz .skip
    nop
.skip:
    inc rax
    cmp rax, rdi
    jb .loop
    ret
