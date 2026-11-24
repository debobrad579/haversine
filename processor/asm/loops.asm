global MOVAllBytes
global CMPAllBytes
global DECAllBytes

global NOP3x1AllBytes
global NOP1x3AllBytes
global NOP1x9AllBytes

global ConditionalNOP

global NOPAligned64
global NOPAligned1
global NOPAligned15
global NOPAligned31
global NOPAligned63

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

NOPAligned64:
    xor rax, rax
align 64
.loop:
    inc rax
    cmp rax, rdi
    jb .loop
    ret

NOPAligned1:
    xor rax, rax
align 64
nop
.loop:
    inc rax
    cmp rax, rdi
    jb .loop
    ret

NOPAligned15:
    xor rax, rax
align 64
%rep 15
nop
%endrep
.loop:
    inc rax
    cmp rax, rdi
    jb .loop
    ret

NOPAligned31:
    xor rax, rax
align 64
%rep 31
nop
%endrep
.loop:
    inc rax
    cmp rax, rdi
    jb .loop
    ret

NOPAligned63:
    xor rax, rax
align 64
%rep 63
nop
%endrep
.loop:
    inc rax
    cmp rax, rdi
    jb .loop
    ret
