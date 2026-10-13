/*
 * Le pilote FAT de la stage 2 (fat.c), compilé et lancé sur le PC.
 * Sur le PC on peut utiliser gdb, valgrind, printf partout... et comparer avec l'OS.
 *
 * Usage : fathost <image> <chemin> [<chemin> ...]
 *   - pour un fichier : affiche sa longueur et la somme de ses octets (même format que dans l'OS)
 *   - pour un dossier : affiche les noms des entrées
 * Option : lire par morceaux de N octets avec  FATHOST_CHUNK=N fathost ...
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include "disk.h"
#include "fat.h"

char g_HostFatMemory[0x10000];

bool DISK_ReadSectors(DISK* disk, uint32_t lba, uint8_t sectors, void* dataOut)
{
    if (fseek(disk->file, (long) lba * 512, SEEK_SET) != 0)
        return false;
    return fread(dataOut, 512, sectors, disk->file) == sectors;
}

static void show(DISK* disk, const char* path, unsigned chunk)
{
    FAT_File* fd = FAT_Open(disk, path);
    if (fd == NULL)
    {
        printf("%s : introuvable\n", path);
        return;
    }

    if (fd->IsDirectory)
    {
        FAT_DirectoryEntry entry;
        printf("%s :\n", path);
        while (FAT_ReadEntry(disk, fd, &entry) && entry.Name[0] != '\0')
            printf("  [%.11s]\n", (char*) entry.Name);
    }
    else
    {
        uint8_t buf[4096];
        uint32_t total = 0, sum = 0, got;
        if (chunk > sizeof(buf)) chunk = sizeof(buf);
        while ((got = FAT_Read(disk, fd, chunk, buf)))
        {
            for (uint32_t i = 0; i < got; i++) sum += buf[i];
            total += got;
        }
        printf("%s (morceaux de %u) : len=%u sum=%u\n", path, chunk, (unsigned) total, (unsigned) sum);
    }
    FAT_Close(fd);
}

int main(int argc, char** argv)
{
    if (argc < 3)
    {
        printf("Usage : %s <image> <chemin> [<chemin> ...]\n", argv[0]);
        return 1;
    }

    DISK disk;
    disk.file = fopen(argv[1], "rb");
    if (!disk.file)
    {
        printf("Impossible d'ouvrir %s\n", argv[1]);
        return 1;
    }

    if (!FAT_Initialize(&disk))
    {
        printf("FAT_Initialize a echoue\n");
        return 1;
    }

    unsigned chunk = getenv("FATHOST_CHUNK") ? (unsigned) atoi(getenv("FATHOST_CHUNK")) : 100;
    for (int i = 2; i < argc; i++)
        show(&disk, argv[i], chunk);

    fclose(disk.file);
    return 0;
}
