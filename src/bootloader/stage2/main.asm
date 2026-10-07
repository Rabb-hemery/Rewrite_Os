bits 16

section _ENTRY class=CODE

extern _cstart_
global entry

entry:
    ; stage1 a mis ds et es à notre segment : on s'en sert pour la pile
    cli
    mov ax, ds
    mov ss, ax
    mov sp, 0                   ; la pile descend depuis le haut du segment
    mov bp, sp
    sti

    ; stage1 nous donne le lecteur de démarrage dans dl.
    ; On le passe à cstart_ comme argument (cdecl : sur la pile).
    xor dh, dh
    push dx
    call _cstart_

    cli
    hlt
