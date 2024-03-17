#include <stdio.h>
#include "colors.h"

#include "asm_printf.h"

int main()
{
    // BAH: It’s worth doing normal unit tests, but I don’t want to yet

    asm_printf(PAINT_TEXT(COLOR_LIGHT_YELLOW, "asm_printf:\t"));
    asm_printf("%%s: %s  ", "String");
    asm_printf("%%c: %c  ", 'C');
    asm_printf("%%d: %d  ", 12345);
    asm_printf("%%d: %d  ", -12345);
    asm_printf("%%o: %o  ", 12345);
    asm_printf("%%x: %x  ", 12345);
    asm_printf("%%b: %b\n", 12345);
    asm_flush();

        printf(PAINT_TEXT(COLOR_LIGHT_YELLOW, "printf:\t\t"));
        printf("%%s: %s  ", "String");
        printf("%%c: %c  ", 'C');
        printf("%%d: %d  ", 12345);
        printf("%%d: %d  ", -12345);
        printf("%%o: %o  ", 12345);
        printf("%%x: %x  ", 12345);
        printf("%%b: Hehehe\n");

    return 0;
}
