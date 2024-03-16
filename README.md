# My printf implementation for x86-64 Windows
A small part of standard printf is implemented, the project was created for educational purposes.

The function is written in NASM. Usage and return value like standard [printf](https://en.cppreference.com/w/c/io/fprintf)

`asm_printf()` uses buffering so it may be necessary to print the buffer manually via `asm_flush()`, for example, at the end of the program. But keep in mind that '\n' calls `asm_flush()`.


The code provides the possibility of output without buffer, but the interface is not implemented

## Supported specifiers

| Type   | Output |
|--------|--------|
| %d      | Signed decimal  |
| %b      | Unsigned binary |
| %o      | Unsigned octal  |
| %x      | Unsigned hexadecimal integer (lowercase) |
| %c      | Single character |
| %s      | Character string |
| %%      | Write a single % |

Percentage is skipped when an unknown specifier is encountered

## Example
```C
#include <stdio.h>
#include "asm_printf.h"

int main()
{
    asm_printf("Hello world!");
    asm_flush();
    return 0;
}
```

## Usage 
Link `asm_printf.obj` and include `"asm_printf.h"`.
