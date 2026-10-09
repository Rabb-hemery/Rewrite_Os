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

;
; bool _cdecl x86_Disk_Reset(uint8_t drive);
;
; Réinitialise le contrôleur de disque. Retourne 1 si ça a marché, 0 sinon.
;
global _x86_Disk_Reset
_x86_Disk_Reset:
    push bp
    mov bp, sp

    mov ah, 0
    mov dl, [bp + 4]            ; dl - lecteur
    stc                         ; certains BIOS ne positionnent pas CF
    int 13h

    mov ax, 1
    sbb ax, 0                   ; ax = 1 - CF : 1 si succès, 0 si échec

    mov sp, bp
    pop bp
    ret

;
; bool _cdecl x86_Disk_Read(uint8_t drive, uint16_t cylinder, uint16_t sector,
;                           uint16_t head, uint8_t count, void far* dataOut);
;
; [bp + 4]  - lecteur
; [bp + 6]  - cylindre
; [bp + 8]  - secteur
; [bp + 10] - tête
; [bp + 12] - nombre de secteurs
; [bp + 14] - pointeur far : offset
; [bp + 16] - pointeur far : segment
;
global _x86_Disk_Read
_x86_Disk_Read:
    push bp
    mov bp, sp

    push bx
    push es

    mov dl, [bp + 4]            ; dl - lecteur

    mov ch, [bp + 6]            ; ch - cylindre (8 bits de poids faible)
    mov cl, [bp + 7]            ; cl - cylindre (2 bits de poids fort)...
    shl cl, 6                   ; ... placés dans les bits 6-7

    mov dh, [bp + 10]           ; dh - tête

    mov al, [bp + 8]            ; secteur dans les bits 0-5 de cl
    and al, 3Fh
    or cl, al

    mov al, [bp + 12]           ; al - nombre de secteurs

    mov bx, [bp + 16]           ; es:bx - pointeur far vers la destination
    mov es, bx
    mov bx, [bp + 14]

    mov ah, 02h
    stc
    int 13h

    mov ax, 1
    sbb ax, 0                   ; 1 si succès, 0 si échec

    pop es
    pop bx

    mov sp, bp
    pop bp
    ret

;
; bool _cdecl x86_Disk_GetDriveParams(uint8_t drive, uint8_t* driveTypeOut,
;                                     uint16_t* cylindersOut, uint16_t* sectorsOut,
;                                     uint16_t* headsOut);
;
; Attention : le BIOS renvoie les plus GRANDS numéros (dernier cylindre, dernière tête),
; pas le nombre de cylindres ou de têtes. Il faut donc ajouter 1 à ces deux valeurs.
;
global _x86_Disk_GetDriveParams
_x86_Disk_GetDriveParams:
    push bp
    mov bp, sp

    push es
    push bx
    push si
    push di

    mov dl, [bp + 4]            ; dl - lecteur
    mov ah, 08h
    mov di, 0                   ; es:di = 0000:0000 (protège contre certains BIOS bogués)
    mov es, di
    stc
    int 13h

    mov ax, 1
    sbb ax, 0                   ; 1 si succès, 0 si échec

    ; type du lecteur (bl)
    mov si, [bp + 6]
    mov [si], bl

    ; cylindres : 8 bits de poids faible dans ch, 2 bits de poids fort dans cl (bits 6-7)
    mov bl, ch
    mov bh, cl
    shr bh, 6
    mov si, [bp + 8]
    mov [si], bx

    ; secteurs : bits 0-5 de cl
    xor ch, ch
    and cl, 3Fh
    mov si, [bp + 10]
    mov [si], cx

    ; têtes : dh
    mov cl, dh
    xor ch, ch
    mov si, [bp + 12]
    mov [si], cx

    pop di
    pop si
    pop bx
    pop es

    mov sp, bp
    pop bp
    ret

;
; Aides du compilateur Open Watcom (appelées par le code C généré, pas par nous).
; Sans bibliothèque standard, il faut les écrire nous-mêmes.
;

; __U4D : division non signée de 32 bits par 32 bits
;   entrée : dividende dans dx:ax, diviseur dans cx:bx
;   sortie : quotient dans dx:ax, reste dans cx:bx
global __U4D_OFF
__U4D_OFF:
    shl edx, 16                 ; dx dans la moitié haute de edx
    mov dx, ax                  ; edx = dividende
    mov eax, edx                ; eax = dividende
    xor edx, edx

    shl ecx, 16                 ; cx dans la moitié haute de ecx
    mov cx, bx                  ; ecx = diviseur

    div ecx                     ; eax = quotient, edx = reste

    mov ebx, edx                ; reste : bx = poids faible
    mov ecx, edx
    shr ecx, 16                 ;         cx = poids fort

    mov edx, eax                ; quotient : ax = poids faible (déjà), dx = poids fort
    shr edx, 16

    ret

; __U4M : multiplication non signée de 32 bits par 32 bits (résultat sur 32 bits)
;   entrée : dx:ax et cx:bx
;   sortie : produit dans dx:ax
global __U4M
__U4M:
    shl edx, 16
    mov dx, ax                  ; edx = 1er facteur
    mov eax, edx                ; eax = 1er facteur

    shl ecx, 16
    mov cx, bx                  ; ecx = 2e facteur

    mul ecx                     ; edx:eax = produit, seul eax nous intéresse
    mov edx, eax
    shr edx, 16                 ; poids fort dans dx, poids faible déjà dans ax

    ret
