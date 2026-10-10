#include "stdint.h"
#include "stdio.h"
#include "disk.h"
#include "fat.h"

void _cdecl cstart_(uint16_t bootDrive)
{
    DISK disk;

    if (!DISK_Initialize(&disk, bootDrive))
    {
        printf("Disk init error\r\n");
        goto end;
    }

    if (!FAT_Initialize(&disk))
    {
        printf("FAT init error\r\n");
        goto end;
    }

    /* 1) lister le répertoire racine */
    FAT_File far* fd = FAT_Open(&disk, "/");
    FAT_DirectoryEntry entry;

    printf("Repertoire racine :\r\n");
    while (FAT_ReadEntry(&disk, fd, &entry) && entry.Name[0] != '\0')
    {
        printf("  ");
        for (int i = 0; i < 11; i++)
            putc(entry.Name[i]);
        printf("\r\n");
    }
    FAT_Close(fd);

    /* 2) essayer d'ouvrir un fichier qui n'existe pas */
 char buffer[100];
     uint32_t read;
 
     printf("Contenu de test.txt :\r\n");
     fd = FAT_Open(&disk, "test.txt");
     while ((read = FAT_Read(&disk, fd, sizeof(buffer), buffer)))
     {
         for (uint32_t i = 0; i < read; i++)
         {
             if (buffer[i] == '\n')
                 putc('\r');             /* le BIOS ne revient au début de la ligne qu'avec un retour chariot */
             putc(buffer[i]);
         }
     }
     FAT_Close(fd);

end:
    for (;;);
}
