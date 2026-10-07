org 0x0
bits 16

%define ENDL 0x0D, 0x0A

start:
    ; Le bootloader a déjà réglé DS et ES (segment 0x2000) et la pile.
    mov si, msg_hello
    call puts

.halt:
    cli
    hlt
    jmp .halt

;
; Affiche une chaîne terminée par 0
; Entrée : ds:si = pointeur vers la chaîne
;
puts:
    push si
    push ax
    push bx
.loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    jmp .loop
.done:
    pop bx
    pop ax
    pop si
    ret

msg_hello: db 'Hello world from KERNEL!', ENDL, 0
