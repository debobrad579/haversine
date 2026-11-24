global MOVAllBytes
global CMPAllBytes
global DECAllBytes

global NOP3x1AllBytes
global NOP1x3AllBytes
global NOP1x9AllBytes

global ConditionalNOP

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

NOP3x1AllBytes:
    xor rax, rax
.loop:
    db 0x0f, 0x1f, 0x00
    inc rax
    cmp rax, rdi
    jb .loop
    ret

NOP1x3AllBytes:
    xor rax, rax
.loop:
    nop
    nop
    nop
    inc rax
    cmp rax, rdi
    jb .loop
    ret

NOP1x9AllBytes:
    xor rax, rax
.loop:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    inc rax
    cmp rax, rdi
    jb .loop
    ret

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
