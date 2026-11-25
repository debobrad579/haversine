global L1CacheRead
global L1CacheReadUnaligned
global L2CacheRead
global L2CacheReadUnaligned
global L3CacheRead
global L3CacheReadUnaligned
global MainMemoryRead
global MainMemoryReadUnaligned

L1CacheRead:
    mov edx, 0b111_1111_1111_1111 ; 32k
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

L1CacheReadUnaligned:
    mov edx, 0b111_1111_1111_1111 ; 32k
    xor rax, rax
    align 64
.loop:
    vmovdqu ymm0, [rsi + rax + 0x10]
    vmovdqu ymm0, [rsi + rax + 0x30]
    vmovdqu ymm0, [rsi + rax + 0x50]
    vmovdqu ymm0, [rsi + rax + 0x70]
    add rax, 128
    and rax, rdx
    sub rdi, 128
    jnz .loop
    ret

L2CacheRead:
    mov edx, 0b1_1111_1111_1111_1111 ; 128k
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

L2CacheReadUnaligned:
    mov edx, 0b1_1111_1111_1111_1111 ; 128k
    xor rax, rax
    align 64
.loop:
    vmovdqu ymm0, [rsi + rax + 0x10]
    vmovdqu ymm0, [rsi + rax + 0x30]
    vmovdqu ymm0, [rsi + rax + 0x50]
    vmovdqu ymm0, [rsi + rax + 0x70]
    add rax, 128
    and rax, rdx
    sub rdi, 128
    jnz .loop
    ret

L3CacheRead:
    mov edx, 0b111_1111_1111_1111_1111 ; 512k
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

L3CacheReadUnaligned:
    mov edx, 0b111_1111_1111_1111_1111 ; 512k
    xor rax, rax
    align 64
.loop:
    vmovdqu ymm0, [rsi + rax + 0x10]
    vmovdqu ymm0, [rsi + rax + 0x30]
    vmovdqu ymm0, [rsi + rax + 0x50]
    vmovdqu ymm0, [rsi + rax + 0x70]
    add rax, 128
    and rax, rdx
    sub rdi, 128
    jnz .loop
    ret

MainMemoryRead:
    mov edx, 0b1111_1111_1111_1111_1111_1111_1111 ; 256M
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

MainMemoryReadUnaligned:
    mov edx, 0b1111_1111_1111_1111_1111_1111_1111 ; 256M
    xor rax, rax
    align 64
.loop:
    vmovdqu ymm0, [rsi + rax + 0x10]
    vmovdqu ymm0, [rsi + rax + 0x30]
    vmovdqu ymm0, [rsi + rax + 0x50]
    vmovdqu ymm0, [rsi + rax + 0x70]
    add rax, 128
    and rax, rdx
    sub rdi, 128
    jnz .loop
    ret
