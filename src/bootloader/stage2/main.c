#include "stdint.h"
#include "stdio.h"

void _cdecl cstart_(uint16_t bootDrive)
{
    (void) bootDrive;   /* pas encore utilisé : servira à lire le disque en C */
    puts("Trying to see if i can change the 'puts', Hello from C!\r\n");
}
