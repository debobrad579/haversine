global Write_4x2
global Write_8x2
global Write_16x2
global Write_32x2

Write_4x2:
    xor rax, rax
    align 64
.loop:
    mov [rsi], r8d
    mov [rsi + 4], r8d
    add rax, 8
    cmp rax, rdi
    jb .loop
    ret

Write_8x2:
    xor rax, rax
    align 64
.loop:
    mov [rsi], r8
    mov [rsi + 8], r8
    add rax, 16
    cmp rax, rdi
    jb .loop
    ret

Write_16x2:
    xor rax, rax
    align 64
.loop:
    vmovdqu [rsi], xmm0,
    vmovdqu [rsi + 16], xmm0
    add rax, 32
    cmp rax, rdi
    jb .loop
    ret

Write_32x2:
    xor rax, rax
    align 64
.loop:
    vmovdqu [rsi], ymm0
    vmovdqu [rsi + 32], ymm0
    add rax, 64
    cmp rax, rdi
    jb .loop
    ret
