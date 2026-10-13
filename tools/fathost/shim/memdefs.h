#pragma once

/* sur le PC, la « zone du pilote FAT » est simplement un tableau */
extern char g_HostFatMemory[];

#define MEMORY_FAT_ADDR     ((void*) g_HostFatMemory)
#define MEMORY_FAT_SIZE     0x00010000
