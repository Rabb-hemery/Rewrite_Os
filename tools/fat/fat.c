// Petit lecteur FAT12 qui tourne sur ton PC (pas dans l'OS).
// Usage : ./build/tools/fat <image disque> <nom du fichier>
// Exemple : ./build/tools/fat build/main_floppy.img test.txt

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>


// __attribute__((packed)) : interdit au compilateur d'ajouter des octets de
// remplissage, pour que la structure corresponde exactement au disque.
typedef struct
{
    uint8_t  BootJumpInstruction[3];
    uint8_t  OemIdentifier[8];
    uint16_t BytesPerSector;
    uint8_t  SectorsPerCluster;
    uint16_t ReservedSectors;
    uint8_t  FatCount;
    uint16_t DirEntryCount;
    uint16_t TotalSectors;
    uint8_t  MediaDescriptorType;
    uint16_t SectorsPerFat;
    uint16_t SectorsPerTrack;
    uint16_t Heads;
    uint32_t HiddenSectors;
    uint32_t LargeSectorCount;

    // Extended boot record
    uint8_t  DriveNumber;
    uint8_t  _Reserved;
    uint8_t  Signature;
    uint32_t VolumeId;
    uint8_t  VolumeLabel[11];
    uint8_t  SystemId[8];

    // (le code du bootloader est ignoré)
} __attribute__((packed)) BootSector;

typedef struct
{
    uint8_t  Name[11];
    uint8_t  Attributes;
    uint8_t  _Reserved;
    uint8_t  CreatedTimeTenths;
    uint16_t CreatedTime;
    uint16_t CreatedDate;
    uint16_t AccessedDate;
    uint16_t FirstClusterHigh;
    uint16_t ModifiedTime;
    uint16_t ModifiedDate;
    uint16_t FirstClusterLow;
    uint32_t Size;
} __attribute__((packed)) DirectoryEntry;

BootSector g_BootSector;
uint8_t* g_Fat = NULL;
DirectoryEntry* g_RootDirectory = NULL;
uint32_t g_RootDirectoryEnd;   // premier secteur de la zone de données

bool readBootSector(FILE* disk)
{
    return fread(&g_BootSector, sizeof(g_BootSector), 1, disk) > 0;
}

// Lit 'count' secteurs à partir du secteur 'lba' vers 'bufferOut'
bool readSectors(FILE* disk, uint32_t lba, uint32_t count, void* bufferOut)
{
    bool ok = true;
    ok = ok && (fseek(disk, lba * g_BootSector.BytesPerSector, SEEK_SET) == 0);
    ok = ok && (fread(bufferOut, g_BootSector.BytesPerSector, count, disk) == count);
    return ok;
}

bool readFat(FILE* disk)
{
    g_Fat = (uint8_t*) malloc(g_BootSector.SectorsPerFat * g_BootSector.BytesPerSector);
    return readSectors(disk, g_BootSector.ReservedSectors, g_BootSector.SectorsPerFat, g_Fat);
}

bool readRootDirectory(FILE* disk)
{
    uint32_t lba = g_BootSector.ReservedSectors + g_BootSector.SectorsPerFat * g_BootSector.FatCount;
    uint32_t size = sizeof(DirectoryEntry) * g_BootSector.DirEntryCount;
    // arrondi au nombre de secteurs supérieur
    uint32_t sectors = (size + g_BootSector.BytesPerSector - 1) / g_BootSector.BytesPerSector;

    g_RootDirectory = (DirectoryEntry*) malloc(sectors * g_BootSector.BytesPerSector);
    g_RootDirectoryEnd = lba + sectors;
    return readSectors(disk, lba, sectors, g_RootDirectory);
}

DirectoryEntry* findFile(const char* name)
{
    for (uint32_t i = 0; i < g_BootSector.DirEntryCount; i++)
    {
        if (memcmp(name, g_RootDirectory[i].Name, 11) == 0)
            return &g_RootDirectory[i];
    }
    return NULL;
}

bool readFile(DirectoryEntry* fileEntry, FILE* disk, uint8_t* outputBuffer)
{
    bool ok = true;
    uint16_t currentCluster = fileEntry->FirstClusterLow;

    do {
        // les clusters commencent à 2 : on retire 2 pour trouver la position dans la zone de données
        uint32_t lba = g_RootDirectoryEnd + (currentCluster - 2) * g_BootSector.SectorsPerCluster;
        ok = ok && readSectors(disk, lba, g_BootSector.SectorsPerCluster, outputBuffer);
        outputBuffer += g_BootSector.SectorsPerCluster * g_BootSector.BytesPerSector;

        // FAT12 : chaque entrée fait 12 bits (1,5 octet)
        uint32_t fatIndex = currentCluster * 3 / 2;
        if (currentCluster % 2 == 0)
            currentCluster = (*(uint16_t*)(g_Fat + fatIndex)) & 0x0FFF;   // 12 bits de poids faible
        else
            currentCluster = (*(uint16_t*)(g_Fat + fatIndex)) >> 4;       // 12 bits de poids fort

    } while (ok && currentCluster < 0x0FF8);   // >= 0xFF8 : fin de la chaîne

    return ok;
}

// "test.txt" -> "TEST    TXT" (format 8.3 sur 11 caractères, majuscules, complété par des espaces)
void toFatName(const char* in, char out[11])
{
    memset(out, ' ', 11);
    int i = 0, j = 0;
    while (in[i] && in[i] != '.' && j < 8)
        out[j++] = toupper((unsigned char) in[i++]);
    if (in[i] == '.')
    {
        i++;
        j = 8;
        while (in[i] && j < 11)
            out[j++] = toupper((unsigned char) in[i++]);
    }
}

int main(int argc, char** argv)
{
    if (argc < 3)
    {
        printf("Usage : %s <image disque> <nom du fichier>\n", argv[0]);
        return -1;
    }

    FILE* disk = fopen(argv[1], "rb");
    if (!disk)
    {
        fprintf(stderr, "Impossible d'ouvrir l'image %s\n", argv[1]);
        return -1;
    }

    if (!readBootSector(disk))
    {
        fprintf(stderr, "Impossible de lire le boot sector\n");
        return -2;
    }

    if (!readFat(disk))
    {
        fprintf(stderr, "Impossible de lire la FAT\n");
        free(g_Fat);
        return -3;
    }

    if (!readRootDirectory(disk))
    {
        fprintf(stderr, "Impossible de lire le répertoire racine\n");
        free(g_Fat);
        free(g_RootDirectory);
        return -4;
    }

    char fatName[11];
    toFatName(argv[2], fatName);

    DirectoryEntry* fileEntry = findFile(fatName);
    if (!fileEntry)
    {
        fprintf(stderr, "Fichier %s introuvable\n", argv[2]);
        free(g_Fat);
        free(g_RootDirectory);
        return -5;
    }

    // un secteur de plus que nécessaire : readFile lit toujours des secteurs entiers
    uint8_t* buffer = (uint8_t*) malloc(fileEntry->Size + g_BootSector.BytesPerSector);
    if (!readFile(fileEntry, disk, buffer))
    {
        fprintf(stderr, "Impossible de lire le fichier %s\n", argv[2]);
        free(g_Fat);
        free(g_RootDirectory);
        free(buffer);
        return -5;
    }

    for (size_t i = 0; i < fileEntry->Size; i++)
    {
        if (isprint(buffer[i])) fputc(buffer[i], stdout);
        else printf("<%02x>", buffer[i]);
    }
    printf("\n");

    free(buffer);
    free(g_Fat);
    free(g_RootDirectory);
    fclose(disk);
    return 0;
}
