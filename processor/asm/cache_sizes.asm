global TestCacheSizes

TestCacheSizes:
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
