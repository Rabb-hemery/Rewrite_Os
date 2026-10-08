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
    mov al, [bp + 4]
    mov bh, [bp + 6]

    int 10h

    ; restaure bx
    pop bx

    ; restaure l'ancien cadre
    mov sp, bp
    pop bp
    ret

;
; void _cdecl x86_div64_32(uint64_t dividend, uint32_t divisor, uint64_t* quotientOut, uint32_t* remainderOut);
;
; Divise un nombre de 64 bits par un nombre de 32 bits, en deux divisions de 32 bits
; (la division longue de l'école).
;
global _x86_div64_32
_x86_div64_32:

    ; créer un nouveau cadre d'appel
    push bp                     ; sauvegarde l'ancien cadre
    mov bp, sp                  ; nouveau cadre

    push bx

    ; [bp + 4]  - dividende, 32 bits de poids faible
    ; [bp + 8]  - dividende, 32 bits de poids fort
    ; [bp + 12] - diviseur (32 bits)
    ; [bp + 16] - pointeur vers le quotient (64 bits)
    ; [bp + 18] - pointeur vers le reste (32 bits)

    ; 1re division : les 32 bits de poids fort
    mov eax, [bp + 8]           ; eax <- poids fort du dividende
    mov ecx, [bp + 12]          ; ecx <- diviseur
    xor edx, edx
    div ecx                     ; eax = quotient, edx = reste

    ; range les 32 bits de poids fort du quotient
    mov bx, [bp + 16]
    mov [bx + 4], eax

    ; 2e division : les 32 bits de poids faible
    mov eax, [bp + 4]           ; eax <- poids faible du dividende
                                ; edx contient déjà l'ancien reste
    div ecx

    ; range le reste du quotient et le reste
    mov [bx], eax
    mov bx, [bp + 18]
    mov [bx], edx

    pop bx

    ; restaure l'ancien cadre
    mov sp, bp
    pop bp
    ret
