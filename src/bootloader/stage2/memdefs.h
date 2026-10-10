#pragma once

/*
 * Carte de la mémoire basse (mode réel), d'après le wiki OSDev :
 *
 * 0x00000000 - 0x000003FF - table des vecteurs d'interruption
 * 0x00000400 - 0x000004FF - zone de données du BIOS
 * 0x00000500 - 0x00010500 - notre pilote FAT (ci-dessous)
 * 0x00020000 - 0x00030000 - stage 2 (chargée par la stage 1)
 * 0x00030000 - 0x00080000 - libre
 * 0x00080000 - 0x0009FFFF - zone de données étendue du BIOS
 * 0x000A0000 - 0x000C7FFF - vidéo
 * 0x000C8000 - 0x000FFFFF - ROM du BIOS
 */

/* Pointeur « far » = segment:offset. Segment 0x0050, offset 0 : adresse physique 0x00500. */
#define MEMORY_FAT_ADDR     ((void far*) 0x00500000)
#define MEMORY_FAT_SIZE     0x00010000      /* 64 Ko au maximum */
