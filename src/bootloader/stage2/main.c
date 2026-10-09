#include "stdint.h"
#include "stdio.h"
#include "disk.h"

void _cdecl cstart_(uint16_t bootDrive)
{
    DISK disk;
    uint8_t sector[512];

    if (!DISK_Initialize(&disk, bootDrive))
    {
        printf("Disk init error\r\n");
        goto end;
    }

    printf("Disk %u : %u cylindres, %u tetes, %u secteurs par piste\r\n",
           disk.id, disk.cylinders, disk.heads, disk.sectors);

    /* Le secteur 19 est le début du répertoire racine : on lit les noms de fichiers */
    if (!DISK_ReadSectors(&disk, 19, 1, sector))
    {
        printf("Read error\r\n");
        goto end;
    }

    printf("Repertoire racine :\r\n");
    for (int i = 0; i < 16; i++)
    {
        uint8_t* entry = sector + i * 32;

        if (entry[0] == 0)          /* plus aucune entrée */
            break;
        if (entry[11] == 0x0F)      /* entrée de nom long : on l'ignore */
            continue;

        printf("  ");
        for (int j = 0; j < 11; j++)
            putc(entry[j]);
        printf("\r\n");
    }

end:
    for (;;);
}
