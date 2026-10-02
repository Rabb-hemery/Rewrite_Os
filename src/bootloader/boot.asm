org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

;
; En-tête FAT12 (BPB + EBR) : obligatoire pour que l'image reste un disque FAT12 valide
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
ebr_drive_number:           db 0                ; sera utile au jour 3
                            db 0                ; réservé
ebr_signature:              db 29h
ebr_volume_id:              db 12h, 34h, 56h, 78h
ebr_volume_label:           db 'REWRITE OS '    ; 11 octets, complété par des espaces
ebr_system_id:              db 'FAT12   '       ; 8 octets, complété par des espaces

;
; Code
;
start:
    jmp main

; Affiche une chaîne terminée par 0
; Entrée : ds:si = pointeur vers la chaîne
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

    mov si, msg_hello
    call puts
    hlt

.halt:
    jmp .halt

msg_hello: db 'Hello from the bootloader!', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h
