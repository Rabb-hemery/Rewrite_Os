#!/bin/bash
# Laboratoire de bugs : introduit un bug connu dans le pilote FAT (src/bootloader/stage2/fat.c).
#
# Usage :  tools/bug.sh list        liste les bugs
#          tools/bug.sh 1 .. 5      introduit le bug choisi (remplace le bug précédent)
#          tools/bug.sh restore     remet le fichier d'origine
#
# L'original est sauvegardé dans tools/.bug_backup/fat.c la première fois.

FAT=src/bootloader/stage2/fat.c
BACKUP_DIR=tools/.bug_backup
BACKUP=$BACKUP_DIR/fat.c

if [ ! -f "$FAT" ]; then
    echo "Lance ce script depuis le dossier RewriteOS (là où se trouve le Makefile)."
    exit 1
fi

case "$1" in
    list)
        echo "1 : l'extension du nom n'est pas mise en majuscules (test.txt devient introuvable)"
        echo "2 : le tampon n'est pas rechargé quand il est vidé pile (gros fichier corrompu)"
        echo "3 : on interdit de lire un sous-dossier, dont la taille est 0 (mydir/test.txt introuvable)"
        echo "4 : la table FAT est lue avec un pointeur near au lieu de far (gros fichier faux, mais OK sur le PC)"
        echo "5 : la racine n'est pas rechargée à chaque ouverture (visible avec plus de 16 fichiers à la racine)"
        exit 0
        ;;
    restore)
        if [ -f "$BACKUP" ]; then
            cp "$BACKUP" "$FAT"
            echo "fat.c remis à son état d'origine."
        else
            echo "Aucune sauvegarde : rien à restaurer."
        fi
        exit 0
        ;;
    1|2|3|4|5)
        mkdir -p "$BACKUP_DIR"
        [ -f "$BACKUP" ] || cp "$FAT" "$BACKUP"
        cp "$BACKUP" "$FAT"
        ;;
    *)
        echo "Usage : $0 list | 1 | 2 | 3 | 4 | 5 | restore"
        exit 1
        ;;
esac

case "$1" in
    1) sed -i 's/fatName\[8 + i\] = toupper(dot\[1 + i\]);/fatName[8 + i] = dot[1 + i];/' "$FAT" ;;
    2) sed -i 's/if (leftInBuffer == take)/if (byteCount > 0)/' "$FAT" ;;
    3) sed -i 's/if (!fd->Public.IsDirectory || (fd->Public.IsDirectory && fd->Public.Size != 0))/if (1)/' "$FAT" ;;
    4) sed -i 's|(\*(uint16_t far\*) (g_Fat + fatIndex))|(*(uint16_t*) (uint16_t) (g_Fat + fatIndex))|g' "$FAT" ;;
    5) sed -i '/^FAT_File far\* FAT_Open/,$ s|if (!FAT_RewindRootDirectory(disk))|g_Data->RootDirectory.Public.Position = 0; g_Data->RootDirectory.CurrentCluster = g_Data->RootDirectory.FirstCluster; if (0)|' "$FAT" ;;
esac

if cmp -s "$BACKUP" "$FAT"; then
    echo "Erreur : le bug $1 n'a pas pu être introduit (fat.c n'a pas changé)."
    cp "$BACKUP" "$FAT"
    exit 1
fi

echo "Bug $1 introduit. Voici ce qui a changé :"
diff "$BACKUP" "$FAT" | grep '^[<>]'
echo
echo "Lance maintenant : make run   (puis  tools/bug.sh restore  quand tu as fini)"
