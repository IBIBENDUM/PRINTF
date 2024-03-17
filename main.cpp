#include <stdio.h>
#include "asm_printf.h"

int main()
{
    asm_printf("Hello world!");
    asm_flush();
    return 0;
}
