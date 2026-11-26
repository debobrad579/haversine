global CacheSizes
global CacheSizesNonPowerOf2
global CacheReadStrided

; rdi = len, rsi = ptr, rdx = mask
CacheSizes:
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
CacheSizesNonPowerOf2:
    xor rax, rax
    xor r10, r10
    align 64
.loop:
    cmp r10, rdx
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
    add r10, 256
    add rax, 256
    cmp rax, rdi
    jb .loop
    ret
.reset:
    xor r10, r10
    jmp .read

; rdi = len, rsi = ptr, rdx = amount, rcx = stride
CacheReadStrided:
    xor rax, rax
    xor r10, r10
    align 64
.loop:
    cmp r10, rdx
    jae .reset
.read:
    vmovdqu ymm0, [rsi + r10]
    vmovdqu ymm0, [rsi + r10 + 0x20]
    add r10, rcx
    add rax, 64
    cmp rax, rdi
    jb .loop
    ret
.reset:
    xor r10, r10
    jmp .read
