#include <stdio.h>

extern "C" int  asm_printf(const char* format, ...);
extern "C" void asm_flush();

int main()
{
    asm_printf("Hello world!\n");
    asm_flush();
    return 0;
}
