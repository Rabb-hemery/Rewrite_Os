#include "fat.h"
#include "stdio.h"
#include "memdefs.h"
#include "memory.h"
#include "string.h"
#include "ctype.h"

#define SECTOR_SIZE             512
#define MAX_PATH_SIZE           256
#define MAX_FILE_HANDLES        10
#define ROOT_DIRECTORY_HANDLE   -1

#pragma pack(push, 1)

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

    /* extended boot record */
    uint8_t  DriveNumber;
    uint8_t  _Reserved;
    uint8_t  Signature;
    uint32_t VolumeId;
    uint8_t  VolumeLabel[11];
    uint8_t  SystemId[8];

    /* le code du bootloader qui suit ne nous intéresse pas */
} FAT_BootSector;

#pragma pack(pop)

typedef struct
{
    uint8_t  Buffer[SECTOR_SIZE];       /* le secteur en cours de lecture */
    FAT_File Public;                    /* la partie visible par l'utilisateur */
    bool     Opened;
    uint32_t FirstCluster;
    uint32_t CurrentCluster;
    uint32_t CurrentSectorInCluster;
} FAT_FileData;

typedef struct
{
    union
    {
        FAT_BootSector BootSector;
        uint8_t        BootSectorBytes[SECTOR_SIZE];
    } BS;

    FAT_FileData RootDirectory;
    FAT_FileData OpenedFiles[MAX_FILE_HANDLES];
} FAT_Data;

/* Pas de malloc ici : les gros tampons sont dans une zone de mémoire que l'on choisit nous-mêmes */
static FAT_Data far* g_Data;
static uint8_t far*  g_Fat;
static uint32_t      g_DataSectionLba;

static uint32_t minimum(uint32_t a, uint32_t b)
{
    return a < b ? a : b;
}

static bool FAT_ReadBootSector(DISK* disk)
{
    return DISK_ReadSectors(disk, 0, 1, g_Data->BS.BootSectorBytes);
}

static bool FAT_ReadFat(DISK* disk)
{
    return DISK_ReadSectors(disk, g_Data->BS.BootSector.ReservedSectors,
                            g_Data->BS.BootSector.SectorsPerFat, g_Fat);
}

/* Place le répertoire racine au début et recharge son premier secteur dans le tampon */
static bool FAT_RewindRootDirectory(DISK* disk)
{
    g_Data->RootDirectory.Public.Position = 0;
    g_Data->RootDirectory.CurrentCluster = g_Data->RootDirectory.FirstCluster;

    return DISK_ReadSectors(disk, g_Data->RootDirectory.FirstCluster, 1, g_Data->RootDirectory.Buffer);
}

bool FAT_Initialize(DISK* disk)
{
    /* la zone mémoire du pilote */
    g_Data = (FAT_Data far*) MEMORY_FAT_ADDR;

    /* lire le boot sector */
    if (!FAT_ReadBootSector(disk))
    {
        printf("FAT: read boot sector failed\r\n");
        return false;
    }

    /* la table FAT vient juste après la structure FAT_Data */
    g_Fat = (uint8_t far*) g_Data + sizeof(FAT_Data);
    uint32_t fatSize = (uint32_t) g_Data->BS.BootSector.BytesPerSector * g_Data->BS.BootSector.SectorsPerFat;
    if (sizeof(FAT_Data) + fatSize >= MEMORY_FAT_SIZE)
    {
        printf("FAT: not enough memory to read the FAT\r\n");
        return false;
    }

    if (!FAT_ReadFat(disk))
    {
        printf("FAT: read FAT failed\r\n");
        return false;
    }

    /* ouvrir le répertoire racine comme un fichier ordinaire */
    uint32_t rootDirLba = g_Data->BS.BootSector.ReservedSectors +
                          g_Data->BS.BootSector.SectorsPerFat * g_Data->BS.BootSector.FatCount;
    uint32_t rootDirSize = sizeof(FAT_DirectoryEntry) * g_Data->BS.BootSector.DirEntryCount;

    g_Data->RootDirectory.Public.Handle = ROOT_DIRECTORY_HANDLE;
    g_Data->RootDirectory.Public.IsDirectory = true;
    g_Data->RootDirectory.Public.Position = 0;
    g_Data->RootDirectory.Public.Size = rootDirSize;
    g_Data->RootDirectory.Opened = true;
    g_Data->RootDirectory.FirstCluster = rootDirLba;     /* pour la racine, un « cluster » est en fait un secteur */
    g_Data->RootDirectory.CurrentCluster = rootDirLba;
    g_Data->RootDirectory.CurrentSectorInCluster = 0;

    if (!FAT_RewindRootDirectory(disk))
    {
        printf("FAT: read root directory failed\r\n");
        return false;
    }

    /* début de la zone de données */
    uint32_t rootDirSectors = (rootDirSize + g_Data->BS.BootSector.BytesPerSector - 1) /
                              g_Data->BS.BootSector.BytesPerSector;
    g_DataSectionLba = rootDirLba + rootDirSectors;

    /* aucun fichier n'est ouvert au départ */
    for (int i = 0; i < MAX_FILE_HANDLES; i++)
        g_Data->OpenedFiles[i].Opened = false;

    return true;
}

static uint32_t FAT_ClusterToLba(uint32_t cluster)
{
    return g_DataSectionLba + (cluster - 2) * g_Data->BS.BootSector.SectorsPerCluster;
}

/* Ouvre un fichier ou un dossier à partir de son entrée de répertoire */
static FAT_File far* FAT_OpenEntry(DISK* disk, FAT_DirectoryEntry* entry)
{
    /* chercher une poignée libre */
    int handle = -1;
    for (int i = 0; i < MAX_FILE_HANDLES && handle < 0; i++)
    {
        if (!g_Data->OpenedFiles[i].Opened)
            handle = i;
    }

    if (handle < 0)
    {
        printf("FAT: out of file handles\r\n");
        return NULL;
    }

    /* remplir la structure */
    FAT_FileData far* fd = &g_Data->OpenedFiles[handle];
    fd->Public.Handle = handle;
    fd->Public.IsDirectory = (entry->Attributes & FAT_ATTRIBUTE_DIRECTORY) != 0;
    fd->Public.Position = 0;
    fd->Public.Size = entry->Size;
    fd->FirstCluster = entry->FirstClusterLow + ((uint32_t) entry->FirstClusterHigh << 16);
    fd->CurrentCluster = fd->FirstCluster;
    fd->CurrentSectorInCluster = 0;

    if (!DISK_ReadSectors(disk, FAT_ClusterToLba(fd->CurrentCluster), 1, fd->Buffer))
    {
        printf("FAT: open entry failed - read error\r\n");
        return NULL;
    }

    fd->Opened = true;
    return &fd->Public;
}

/* Cluster suivant dans la chaîne : les entrées de la FAT12 font 12 bits */
static uint32_t FAT_NextCluster(uint32_t currentCluster)
{
    uint32_t fatIndex = currentCluster * 3 / 2;

    if (currentCluster % 2 == 0)
        return (*(uint16_t far*) (g_Fat + fatIndex)) & 0x0FFF;
    else
        return (*(uint16_t far*) (g_Fat + fatIndex)) >> 4;
}

uint32_t FAT_Read(DISK* disk, FAT_File far* file, uint32_t byteCount, void* dataOut)
{
    /* retrouver les données internes du fichier */
    FAT_FileData far* fd = (file->Handle == ROOT_DIRECTORY_HANDLE)
        ? &g_Data->RootDirectory
        : &g_Data->OpenedFiles[file->Handle];

    uint8_t* u8DataOut = (uint8_t*) dataOut;

    /* ne pas lire au-delà de la fin du fichier (un sous-dossier a une taille de 0 :
       on le lit jusqu'à la fin de sa chaîne de clusters) */
    if (!fd->Public.IsDirectory || (fd->Public.IsDirectory && fd->Public.Size != 0))
        byteCount = minimum(byteCount, fd->Public.Size - fd->Public.Position);

    while (byteCount > 0)
    {
        uint32_t leftInBuffer = SECTOR_SIZE - (fd->Public.Position % SECTOR_SIZE);
        uint32_t take = minimum(byteCount, leftInBuffer);

        memcpy(u8DataOut, fd->Buffer + fd->Public.Position % SECTOR_SIZE, take);
        u8DataOut += take;
        fd->Public.Position += take;
        byteCount -= take;

        /* le tampon est vide : charger le secteur suivant.
           (Il faut tester « leftInBuffer == take », pas « byteCount > 0 » :
            on peut avoir vidé le tampon exactement en lisant tout ce qui était demandé.) */
        if (leftInBuffer == take)
        {
            if (fd->Public.Handle == ROOT_DIRECTORY_HANDLE)
            {
                /* la racine n'est pas dans la FAT : on passe simplement au secteur suivant */
                ++fd->CurrentCluster;

                if (!DISK_ReadSectors(disk, fd->CurrentCluster, 1, fd->Buffer))
                {
                    printf("FAT: read error\r\n");
                    break;
                }
            }
            else
            {
                /* prochain secteur du cluster, ou prochain cluster d'après la FAT */
                if (++fd->CurrentSectorInCluster >= g_Data->BS.BootSector.SectorsPerCluster)
                {
                    fd->CurrentSectorInCluster = 0;
                    fd->CurrentCluster = FAT_NextCluster(fd->CurrentCluster);
                }

                if (fd->CurrentCluster >= 0xFF8)
                {
                    /* fin de la chaîne : c'est la fin du fichier */
                    fd->Public.Size = fd->Public.Position;
                    break;
                }

                if (!DISK_ReadSectors(disk, FAT_ClusterToLba(fd->CurrentCluster) + fd->CurrentSectorInCluster,
                                      1, fd->Buffer))
                {
                    printf("FAT: read error\r\n");
                    break;
                }
            }
        }
    }

    return u8DataOut - (uint8_t*) dataOut;
}

bool FAT_ReadEntry(DISK* disk, FAT_File far* file, FAT_DirectoryEntry* dirEntry)
{
    return FAT_Read(disk, file, sizeof(FAT_DirectoryEntry), dirEntry) == sizeof(FAT_DirectoryEntry);
}

void FAT_Close(FAT_File far* file)
{
    if (file->Handle == ROOT_DIRECTORY_HANDLE)
    {
        /* la racine reste toujours ouverte : on la remet juste au début
           (son premier secteur est rechargé par FAT_Open, qui a accès au disque) */
        file->Position = 0;
        g_Data->RootDirectory.CurrentCluster = g_Data->RootDirectory.FirstCluster;
    }
    else
    {
        g_Data->OpenedFiles[file->Handle].Opened = false;
    }
}

/* Cherche un fichier par son nom (« test.txt ») dans un dossier ouvert */
static bool FAT_FindFile(DISK* disk, FAT_File far* file, const char* name, FAT_DirectoryEntry* entryOut)
{
    char fatName[12];
    FAT_DirectoryEntry entry;

    /* convertir « test.txt » en « TEST    TXT » : 8 caractères pour le nom, 3 pour l'extension,
       en majuscules, complétés par des espaces */
    memset(fatName, ' ', 11);
    fatName[11] = '\0';

    const char* dot = strchr(name, '.');
    unsigned nameLength = dot ? (unsigned) (dot - name) : strlen(name);

    for (unsigned i = 0; i < 8 && i < nameLength; i++)
        fatName[i] = toupper(name[i]);

    if (dot != NULL)
    {
        for (unsigned i = 0; i < 3 && dot[1 + i]; i++)
            fatName[8 + i] = toupper(dot[1 + i]);
    }

    /* parcourir les entrées jusqu'à la fin du dossier (premier octet à 0) */
    while (FAT_ReadEntry(disk, file, &entry) && entry.Name[0] != '\0')
    {
        if (memcmp(fatName, entry.Name, 11) == 0)
        {
            *entryOut = entry;
            return true;
        }
    }

    return false;
}

/* Ouvre un fichier ou un dossier à partir de son chemin (« /dossier/fichier.txt ») */
FAT_File far* FAT_Open(DISK* disk, const char* path)
{
    char name[MAX_PATH_SIZE];

    /* ignorer le « / » du début */
    if (path[0] == '/')
        path++;

    /* on part toujours de la racine, rechargée depuis le disque */
    FAT_File far* current = &g_Data->RootDirectory.Public;
    if (!FAT_RewindRootDirectory(disk))
    {
        printf("FAT: read root directory failed\r\n");
        return NULL;
    }

    while (*path)
    {
        /* extraire le prochain élément du chemin */
        bool isLast = false;
        const char* delim = strchr(path, '/');
        if (delim != NULL)
        {
            memcpy(name, path, delim - path);
            name[delim - path] = '\0';
            path = delim + 1;
        }
        else
        {
            unsigned len = strlen(path);
            memcpy(name, path, len);
            name[len] = '\0';
            path += len;
            isLast = true;
        }

        /* le chercher dans le dossier courant */
        FAT_DirectoryEntry entry;
        if (FAT_FindFile(disk, current, name, &entry))
        {
            FAT_Close(current);

            /* un élément au milieu du chemin doit être un dossier */
            if (!isLast && (entry.Attributes & FAT_ATTRIBUTE_DIRECTORY) == 0)
            {
                printf("FAT: %s is not a directory\r\n", name);
                return NULL;
            }

            current = FAT_OpenEntry(disk, &entry);
            if (current == NULL)
                return NULL;
        }
        else
        {
            FAT_Close(current);

            printf("FAT: %s not found\r\n", name);
            return NULL;
        }
    }

    return current;
}
