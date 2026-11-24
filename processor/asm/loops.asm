global MOVAllBytes
global CMPAllBytes
global DECAllBytes

MOVAllBytes:
    xor rax, rax
.loop:
    mov [rsi + rax], al
    inc rax
    cmp rax, rdi
    jb .loop
    ret

CMPAllBytes:
    xor rax, rax
.loop:
    inc rax
    cmp rax, rdi
    jb .loop
    ret

DECAllBytes:
.loop:
    dec rdi
    jnz .loop
    ret
