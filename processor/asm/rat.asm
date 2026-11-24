global RATAdd
global RATMovAdd

RATAdd:
align 64
.loop:
    add rcx, 1
    add rcx, 1
    dec rdi
    jnz .loop
    ret

RATMovAdd:
align 64
.loop:
    mov rcx, rdi
    add rcx, 1
    mov rcx, rdi
    add rcx, 1
    dec rdi
    jnz .loop
    ret

; RAT Homework:
mov rax, 1      ; rax -> s0
mov rbx, 2      ; rbx -> s1
mov rcx, 3      ; rcx -> s2
mov rdx, 4      ; rdx -> s3
add rax, rbx    ; rax -> s4, s0 + s1; rflags -> s21
add rcx, rdx    ; rcx -> s5, s2 + s3; rflags -> s22
add rax, rcx    ; rax -> s6, s4 + s5; rflags -> s23
mov rcx, rbx    ; rcx -> s7, s1
inc rax         ; rax -> s8, s6 + 1; rflags -> s24 (CF from s23)
dec rcx         ; rcx -> s9, s7 - 1; rflags -> s25 (CF from s24)
sub rax, rbx    ; rax -> s10, s8 - s1; rflags -> s26
sub rcx, rdx    ; rcx -> s11, s9 - s3; rflags -> s27
sub rax, rcx    ; rax -> s12, s10 - s11; rflags -> s28

; Challenge Homework:
mov rsp, 4096       ; rsp -> s13
top:                
    pop rcx         ; rcx -> s14, [s13]; rsp -> s15, s13 + 8; 
    sub rsp, rdx    ; rsp -> s16, s15 - s3; rflags -> s29
    mov rbx, rax    ; rbx -> s17, s12
    shl rbx, 0      ; rbx -> s18, s17 << 0
    not rbx         ; rbx -> s19, ~s18
    loopne top      ; rcx -> s20, s14 - 1; jump to top if s20 != 0 && (s29 & 0x40) == 0
