global PeriodicRead
global PeriodicPrefetchedRead

; rdi = outer loop count, rsi = ptr, rdx = inner loop count
PeriodicRead:
    align 64
.outer_loop:
    vmovdqa ymm0, [rsi]
    vmovdqa ymm1, [rsi + 0x20]
    mov rsi, [rsi]
    mov r10, rdx
    .inner_loop:
	vpxor ymm0, ymm1
	vpaddd ymm0, ymm1
	dec r10
	jnz .inner_loop
    dec rdi
    jnz .outer_loop
    ret

; rdi = outer loop count, rsi = ptr, rdx = inner loop count
PeriodicPrefetchedRead:
    align 64
.outer_loop:
    vmovdqa ymm0, [rsi]
    vmovdqa ymm1, [rsi + 0x20]
    mov rsi, [rsi]
    mov r10, rdx
    prefetcht0 [rsi]
    .inner_loop:
	vpxor ymm0, ymm1
	vpaddd ymm0, ymm1
	dec r10
	jnz .inner_loop
    dec rdi
    jnz .outer_loop
    ret
