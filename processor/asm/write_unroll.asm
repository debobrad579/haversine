global Write_x1
global Write_x2
global Write_x3
global Write_x4

Write_x1:
    align 64
.loop:
    mov qword [rsi], rax
    sub rdi, 1
    jnle .loop
    ret

Write_x2:
    align 64
.loop:
    mov qword [rsi], rax
    mov qword [rsi], rax
    sub rdi, 2
    jnle .loop
    ret

Write_x3:
    align 64
.loop:
    mov qword [rsi], rax
    mov qword [rsi], rax
    mov qword [rsi], rax
    sub rdi, 3
    jnle .loop
    ret

Write_x4:
    align 64
.loop:
    mov qword [rsi], rax
    mov qword [rsi], rax
    mov qword [rsi], rax
    mov qword [rsi], rax
    sub rdi, 4
    jnle .loop
    ret
