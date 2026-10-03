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
ebr_drive_number:           db 0                ; rempli par le code (numéro du lecteur donné par le BIOS)
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

    ; Le BIOS met le numéro du lecteur de démarrage dans DL
    mov [ebr_drive_number], dl

    ; Lire le secteur LBA 1 vers la mémoire à l'adresse es:bx = 0x0000:0x7E00
    mov ax, 5000               ; LBA = 1
    mov cl, 1               ; nombre de secteurs à lire
    mov bx, 0x7E00          ; destination
    call disk_read

    mov si, msg_read_ok
    call puts

    cli                     ; désactive les interruptions pour que hlt reste arrêté
    hlt

;
; Gestion des erreurs
;
floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h                 ; attend l'appui sur une touche
    jmp 0FFFFh:0            ; saute au début du BIOS = redémarrage

.halt:
    cli
    hlt
    jmp .halt

;
; Routines disque
;

;
; Convertit une adresse LBA en adresse CHS
; Entrée : ax = adresse LBA
; Sortie : cx [bits 0-5]  = numéro de secteur
;          cx [bits 6-15] = numéro de cylindre
;          dh             = numéro de tête
;
lba_to_chs:
    push ax
    push dx

    xor dx, dx                          ; dx = 0
    div word [bdb_sectors_per_track]    ; ax = LBA / secteurs_par_piste
                                        ; dx = LBA % secteurs_par_piste
    inc dx                              ; dx = secteur (commence à 1)
    mov cx, dx                          ; cx = secteur

    xor dx, dx                          ; dx = 0
    div word [bdb_heads]                ; ax = cylindre
                                        ; dx = tête
    mov dh, dl                          ; dh = tête
    mov ch, al                          ; ch = 8 bits de poids faible du cylindre
    shl ah, 6
    or cl, ah                           ; 2 bits de poids fort du cylindre dans cl

    pop ax
    mov dl, al                          ; restaure dl seulement (dh est la sortie)
    pop ax
    ret

;
; Lit des secteurs sur le disque
; Entrées : ax = adresse LBA
;           cl = nombre de secteurs à lire (jusqu'à 128)
;           dl = numéro du lecteur
;           es:bx = adresse mémoire de destination
;
disk_read:
    push ax
    push bx
    push cx
    push dx
    push di

    push cx                 ; sauvegarde cl (nombre de secteurs)
    call lba_to_chs
    pop ax                  ; al = nombre de secteurs

    mov ah, 02h
    mov di, 3               ; 3 tentatives (les disquettes sont peu fiables)

.retry:
    pusha                   ; sauvegarde tous les registres
    stc                     ; certains BIOS ne positionnent pas CF
    int 13h
    jnc .done               ; CF = 0 : lecture réussie

    popa                    ; échec : restaure, réinitialise le contrôleur, réessaie
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    jmp floppy_error        ; toutes les tentatives ont échoué

.done:
    popa
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;
; Réinitialise le contrôleur de disque
; Entrée : dl = numéro du lecteur
;
disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret

msg_read_ok:        db 'Read from disk!', ENDL, 0
msg_read_failed:    db 'Read from disk failed!', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h
