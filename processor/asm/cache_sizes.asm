global TestCacheSizesPowerOf2
global TestCacheSizes

; rdi = len, rsi = ptr, rdx = mask
TestCacheSizesPowerOf2:
    xor rax, rax
    align 64
.loop:
    vmovdqu ymm0, [rsi + rax]
    vmovdqu ymm0, [rsi + rax + 0x20]
    vmovdqu ymm0, [rsi + rax + 0x40]
    vmovdqu ymm0, [rsi + rax + 0x60]
    add rax, 128
    and rax, rdx
    sub rdi, 128
    jnz .loop
    ret

; rdi = len, rsi = ptr, rdx = amount
TestCacheSizes:
    xor rax, rax
    xor rcx, rcx
    align 64
.loop:
    cmp rcx, rdx
    jae .reset
.read:
    vmovdqu ymm0, [rsi + rcx]
    vmovdqu ymm0, [rsi + rcx + 0x20]
    vmovdqu ymm0, [rsi + rcx + 0x40]
    vmovdqu ymm0, [rsi + rcx + 0x60]
    vmovdqu ymm0, [rsi + rcx + 0x80]
    vmovdqu ymm0, [rsi + rcx + 0xa0]
    vmovdqu ymm0, [rsi + rcx + 0xe0]
    vmovdqu ymm0, [rsi + rcx + 0xc0]
    add rcx, 256
    add rax, 256
    cmp rax, rdi
    jb .loop
    ret
.reset:
    xor rcx, rcx
    jmp .read
