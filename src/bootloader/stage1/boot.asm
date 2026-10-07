org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

;
; En-tête FAT12 (BPB + EBR)
;
jmp short start
nop

bdb_oem:                    db 'MSWIN4.1'       ; 8 octets
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880             ; 2880 * 512 = 1.44 Mo
bdb_media_descriptor_type:  db 0F0h             ; disquette 3.5 pouces
bdb_sectors_per_fat:        dw 9
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

; Extended boot record
ebr_drive_number:           db 0                ; rempli par le code (lecteur de démarrage)
                            db 0                ; réservé
ebr_signature:              db 29h
ebr_volume_id:              db 12h, 34h, 56h, 78h
ebr_volume_label:           db 'REWRITE OS '    ; 11 octets
ebr_system_id:              db 'FAT12   '       ; 8 octets

;
; Code
;
start:
    jmp main

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

main:
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Certains BIOS lancent le bootloader en 07C0:0000 au lieu de 0000:7C00.
    ; Un retour lointain (retf) force CS = 0.
    push es
    push word .after
    retf
.after:

    ; Le BIOS met le numéro du lecteur de démarrage dans DL
    mov [ebr_drive_number], dl

    ; --- Calculer la position du répertoire racine : réservés + FAT * secteurs_par_FAT ---
    mov ax, [bdb_sectors_per_fat]
    mov bl, [bdb_fat_count]
    xor bh, bh
    mul bx                              ; ax = secteurs_par_FAT * nombre_de_FAT
    add ax, [bdb_reserved_sectors]      ; ax = LBA du répertoire racine
    push ax

    ; --- Calculer sa taille en secteurs : (entrées * 32) / octets_par_secteur, arrondi au supérieur ---
    mov ax, [bdb_dir_entries_count]
    shl ax, 5                           ; ax = entrées * 32
    xor dx, dx
    div word [bdb_bytes_per_sector]
    test dx, dx
    jz .root_dir_after
    inc ax                              ; reste non nul : un secteur de plus
.root_dir_after:

    ; --- Lire le répertoire racine ---
    mov cl, al                          ; cl = nombre de secteurs à lire
    pop ax                              ; ax = LBA du répertoire racine
    mov dl, [ebr_drive_number]
    mov bx, buffer
    call disk_read

    ; --- Chercher stage2.bin ---
    xor bx, bx                          ; bx = numéro de l'entrée en cours
    mov di, buffer                      ; di = entrée en cours (le nom est le premier champ)
.search_stage2:
    mov si, file_stage2_bin
    mov cx, 11                          ; un nom FAT fait 11 caractères
    push di
    repe cmpsb                          ; compare ds:si et es:di tant qu'ils sont égaux
    pop di
    je .found_stage2

    add di, 32                          ; entrée suivante (32 octets)
    inc bx
    cmp bx, [bdb_dir_entries_count]
    jl .search_stage2

    jmp stage2_not_found_error

.found_stage2:
    mov ax, [di + 26]                   ; premier cluster (à l'offset 26 de l'entrée)
    mov [stage2_cluster], ax

    ; --- Lire la table FAT en mémoire ---
    mov ax, [bdb_reserved_sectors]
    mov bx, buffer
    mov cl, [bdb_sectors_per_fat]
    mov dl, [ebr_drive_number]
    call disk_read

    ; --- Charger stage2 cluster par cluster ---
    mov bx, STAGE2_LOAD_SEGMENT
    mov es, bx
    mov bx, STAGE2_LOAD_OFFSET

.load_stage2_loop:
    ; cluster -> secteur : début des données + (cluster - 2). Pour une disquette
    ; 1,44 Mo, les données commencent au secteur 33, donc secteur = cluster + 31.
    mov ax, [stage2_cluster]
    add ax, 31

    mov cl, 1
    mov dl, [ebr_drive_number]
    call disk_read

    add bx, [bdb_bytes_per_sector]      ; attention : déborde au-delà de 64 Ko

    ; --- Cluster suivant, avec la table FAT12 (entrées de 12 bits) ---
    mov ax, [stage2_cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx                              ; ax = cluster * 3 / 2, dx = cluster % 2

    mov si, buffer
    add si, ax
    mov ax, [ds:si]                     ; lit 16 bits à partir de cet octet

    or dx, dx
    jz .even
.odd:
    shr ax, 4                           ; cluster impair : 12 bits de poids fort
    jmp .next_cluster_after
.even:
    and ax, 0x0FFF                      ; cluster pair : 12 bits de poids faible

.next_cluster_after:
    cmp ax, 0x0FF8                      ; >= 0xFF8 : fin de la chaîne
    jae .read_finish

    mov [stage2_cluster], ax
    jmp .load_stage2_loop

.read_finish:
    ; Sauter dans stage2
    mov dl, [ebr_drive_number]          ; on passe le lecteur de démarrage à stage2
    mov ax, STAGE2_LOAD_SEGMENT
    mov ds, ax
    mov es, ax
    jmp STAGE2_LOAD_SEGMENT:STAGE2_LOAD_OFFSET

    jmp wait_key_and_reboot             ; ne devrait jamais arriver

    cli
    hlt

;
; Gestion des erreurs
;
floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot

stage2_not_found_error:
    mov si, msg_stage2_not_found
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h                             ; attend l'appui sur une touche
    jmp 0FFFFh:0                        ; saute au début du BIOS = redémarrage

.halt:
    cli
    hlt
    jmp .halt

;
; Routines disque
;

; Convertit une adresse LBA en CHS
; Entrée : ax = LBA
; Sortie : cx [bits 0-5] = secteur, cx [bits 6-15] = cylindre, dh = tête
lba_to_chs:
    push ax
    push dx

    xor dx, dx
    div word [bdb_sectors_per_track]    ; ax = LBA / secteurs_par_piste, dx = LBA % secteurs_par_piste
    inc dx                              ; dx = secteur
    mov cx, dx

    xor dx, dx
    div word [bdb_heads]                ; ax = cylindre, dx = tête
    mov dh, dl
    mov ch, al
    shl ah, 6
    or cl, ah

    pop ax
    mov dl, al                          ; restaure dl seulement
    pop ax
    ret

; Lit des secteurs sur le disque
; Entrées : ax = LBA, cl = nombre de secteurs (jusqu'à 128), dl = lecteur, es:bx = destination
disk_read:
    push ax
    push bx
    push cx
    push dx
    push di

    push cx
    call lba_to_chs
    pop ax                              ; al = nombre de secteurs

    mov ah, 02h
    mov di, 3                           ; 3 tentatives

.retry:
    pusha
    stc
    int 13h
    jnc .done

    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    jmp floppy_error

.done:
    popa
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Réinitialise le contrôleur de disque (dl = lecteur)
disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret

msg_read_failed:        db 'Read from disk failed!', ENDL, 0
msg_stage2_not_found:   db 'STAGE2.BIN not found!', ENDL, 0
file_stage2_bin:        db 'STAGE2  BIN'
stage2_cluster:         dw 0

STAGE2_LOAD_SEGMENT     equ 0x2000
STAGE2_LOAD_OFFSET      equ 0

times 510-($-$$) db 0
dw 0AA55h

buffer:
