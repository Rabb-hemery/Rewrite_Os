#include "stdio.h"
#include "x86.h"

void _cdecl putc(char c)
{
    x86_Video_WriteCharTeletype(c, 0);
}

void _cdecl puts(const char* str)
{
    while (*str)
    {
        putc(*str);
        str++;
    }
}
