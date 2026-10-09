#include "disk.h"
#include "x86.h"

bool DISK_Initialize(DISK* disk, uint8_t driveNumber)
{
    uint8_t driveType;
    uint16_t cylinders, sectors, heads;

    disk->id = driveNumber;

    if (!x86_Disk_GetDriveParams(disk->id, &driveType, &cylinders, &sectors, &heads))
        return false;

    /* Le BIOS donne le plus grand numéro de cylindre et de tête (ils commencent à 0) :
       le nombre de cylindres et de têtes, c'est ce numéro + 1. */
    disk->cylinders = cylinders + 1;
    disk->heads = heads + 1;
    disk->sectors = sectors;         /* les secteurs commencent à 1 : déjà un nombre */

    return true;
}

void DISK_LBA2CHS(DISK* disk, uint32_t lba, uint16_t* cylinderOut, uint16_t* sectorOut, uint16_t* headOut)
{
    /* secteur = (LBA % secteurs par piste) + 1 */
    *sectorOut = lba % disk->sectors + 1;

    /* cylindre = (LBA / secteurs par piste) / têtes */
    *cylinderOut = (lba / disk->sectors) / disk->heads;

    /* tête = (LBA / secteurs par piste) % têtes */
    *headOut = (lba / disk->sectors) % disk->heads;
}

bool DISK_ReadSectors(DISK* disk, uint32_t lba, uint8_t sectors, void far* dataOut)
{
    uint16_t cylinder, sector, head;

    DISK_LBA2CHS(disk, lba, &cylinder, &sector, &head);

    /* les disquettes sont peu fiables : 3 tentatives, avec réinitialisation entre deux */
    for (int i = 0; i < 3; i++)
    {
        if (x86_Disk_Read(disk->id, cylinder, sector, head, sectors, dataOut))
            return true;

        x86_Disk_Reset(disk->id);
    }

    return false;
}
