global Write_x1
global Write_x2
global Write_x3
global Write_x4

Write_x1:
    align 64
.loop:
    mov qword [rsi], rax
    sub rdi, 8
    jnle .loop
    ret

Write_x2:
    align 64
.loop:
    mov qword [rsi], rax
    mov qword [rsi], rax
    sub rdi, 16
    jnle .loop
    ret

Write_x3:
    align 64
.loop:
    mov qword [rsi], rax
    mov qword [rsi], rax
    mov qword [rsi], rax
    sub rdi, 24
    jnle .loop
    ret

Write_x4:
    align 64
.loop:
    mov qword [rsi], rax
    mov qword [rsi], rax
    mov qword [rsi], rax
    mov qword [rsi], rax
    sub rdi, 32
    jnle .loop
    ret
