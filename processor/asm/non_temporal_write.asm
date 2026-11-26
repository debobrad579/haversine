global WriteEvery256Read
global WriteEvery256ReadNT

WriteEvery256Read:
    mov rax, 4096
    xor rcx, rcx
    align 64
.outer:
    vmovdqu ymm0, [rsi + rcx]
    vmovdqu ymm0, [rsi + rcx + 0x20]
    vmovdqu ymm0, [rsi + rcx + 0x40]
    vmovdqu ymm0, [rsi + rcx + 0x60]
    vmovdqu ymm0, [rsi + rcx + 0x80]
    vmovdqu ymm0, [rsi + rcx + 0xa0]
    vmovdqu ymm0, [rsi + rcx + 0xc0]
    vmovdqu ymm0, [rsi + rcx + 0xe0]
    .inner:
	vmovdqa [rsi + rax], ymm0
	vmovdqa [rsi + rax + 0x20], ymm0
	vmovdqa [rsi + rax + 0x40], ymm0
	vmovdqa [rsi + rax + 0x60], ymm0
	add rax, 128
	cmp rax, rdi
	jb .inner
    mov rax, 4096
    add rcx, 256
    cmp rcx, 4096
    jne .outer
    ret

WriteEvery256ReadNT:
    mov rax, 4096
    xor rcx, rcx
    align 64
.outer:
    vmovdqu ymm0, [rsi + rcx]
    vmovdqu ymm0, [rsi + rcx + 0x20]
    vmovdqu ymm0, [rsi + rcx + 0x40]
    vmovdqu ymm0, [rsi + rcx + 0x60]
    vmovdqu ymm0, [rsi + rcx + 0x80]
    vmovdqu ymm0, [rsi + rcx + 0xa0]
    vmovdqu ymm0, [rsi + rcx + 0xc0]
    vmovdqu ymm0, [rsi + rcx + 0xe0]
    .inner:
	vmovntdq [rsi + rax], ymm0
	vmovntdq [rsi + rax + 0x20], ymm0
	vmovntdq [rsi + rax + 0x40], ymm0
	vmovntdq [rsi + rax + 0x60], ymm0
	add rax, 128
	cmp rax, rdi
	jb .inner
    mov rax, 4096
    add rcx, 256
    cmp rcx, 4096
    jne .outer
    ret
