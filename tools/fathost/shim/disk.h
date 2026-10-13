#pragma once

#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>

/* version « PC » de la structure DISK : un fichier image au lieu d'un vrai lecteur */
typedef struct
{
    FILE* file;
} DISK;

bool DISK_ReadSectors(DISK* disk, uint32_t lba, uint8_t sectors, void* dataOut);
