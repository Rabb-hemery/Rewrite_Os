bits 16

section _TEXT class=CODE

;
; void _cdecl x86_Video_WriteCharTeletype(char c, uint8_t page);
;
global _x86_Video_WriteCharTeletype
_x86_Video_WriteCharTeletype:

    ; créer un nouveau cadre d'appel
    push bp                     ; sauvegarde l'ancien cadre
    mov bp, sp                  ; nouveau cadre

    ; sauvegarde bx
    push bx

    ; [bp + 0] - ancien cadre
    ; [bp + 2] - adresse de retour (petit modèle mémoire : 2 octets)
    ; [bp + 4] - 1er argument (caractère)
    ; [bp + 6] - 2e argument (page)
    ; les octets sont convertis en mots (on ne peut pas empiler un seul octet)
    mov ah, 0Eh
    mov al, [bp + 2]
    mov bh, [bp + 6]

    int 10h

    ; restaure bx
    pop bx

    ; restaure l'ancien cadre
    mov sp, bp
    pop bp
    ret
