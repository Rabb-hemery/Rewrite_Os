#include "stdint.h"
#include "stdio.h"
#include "disk.h"
#include "fat.h"

/* Lit tout le fichier par morceaux de `chunk` octets et compare la longueur et la somme des octets
   avec les valeurs attendues (calculées sur le PC avec Python ou sum). */
static void check(DISK* disk, const char* path, uint16_t chunk, uint32_t expectedLen, uint32_t expectedSum)
{
    uint8_t buf[512];
    uint32_t total = 0, sum = 0, got;
    FAT_File far* fd = FAT_Open(disk, path);

    printf("%s (%u) : ", path, chunk);

    if (fd == NULL)
    {
        printf("ECHEC (introuvable)\r\n");
        return;
    }

    while ((got = FAT_Read(disk, fd, chunk, buf)))
    {
        for (uint32_t i = 0; i < got; i++)
            sum += buf[i];
        total += got;
    }
    FAT_Close(fd);

    if (total == expectedLen && sum == expectedSum)
        printf("OK\r\n");
    else
        printf("ECHEC (len=%lu sum=%lu)\r\n", total, sum);
}

void _cdecl cstart_(uint16_t bootDrive)
{
    DISK disk;

    if (!DISK_Initialize(&disk, bootDrive) || !FAT_Initialize(&disk))
    {
        printf("Init error\r\n");
        goto end;
    }

    /* test.txt : 52 octets ; bigfile.txt : 8893 octets (les nombres de 1 a 2000) */
    check(&disk, "test.txt", 64, 52, 4487);
    check(&disk, "mydir/test.txt", 64, 52, 4487);
    check(&disk, "bigfile.txt", 100, 8893, 378866);
    check(&disk, "bigfile.txt", 64, 8893, 378866);
    check(&disk, "/BIGFILE.TXT", 512, 8893, 378866);

end:
    for (;;);
}
