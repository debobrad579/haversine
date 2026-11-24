global TestCacheSizes

TestCacheSizes:
    xor rax, rax
    xor rcx, rcx
    align 64
.loop:
    vmovdqu ymm0, [rsi + rax]
    vmovdqu ymm0, [rsi + rax + 32]
    vmovdqu ymm0, [rsi + rax + 64]
    vmovdqu ymm0, [rsi + rax + 96]
    add rax, 128
    and rax, rdx
    add rcx, 128
    cmp rcx, rdi
    jb .loop
    ret
