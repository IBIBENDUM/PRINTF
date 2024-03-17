# My printf implementation for x86-64 Windows
A small part of standard printf is implemented.

The function is written in NASM. Usage and return value like standard [printf](https://en.cppreference.com/w/c/io/fprintf).

`asm_printf()` uses buffering so it may be necessary to print the buffer manually via `asm_flush()`, for example, at the end of the program. But keep in mind that '\n' calls `asm_flush()`.


The code provides the possibility of output without buffer, but the interface is not implemented.

## Supported specifiers

| Type   | Output |
|--------|--------|
| %d      | Signed decimal  |
| %b      | Unsigned binary |
| %o      | Unsigned octal  |
| %x      | Unsigned hexadecimal integer (lowercase) |
| %c      | Single character |
| %s      | Character string |

Percentage is skipped when an unknown specifier is encountered.

## Build
To build the project you need to execute `make compile` in
the project directory.

## Running the example
To run the example execute `make run`.

## Using in your project
If you want to use this function in your projects copy `asm_printf.o` and `asm_printf.h` to the project folder

To get you started quickly let's take a look at a simple working "Hello World" project.

Our Hello World project has one source file `hello.cpp` file and it looks as follows:

```C
#include "asm_printf.h"

int main()
{
    asm_printf("Hello world!");
    asm_flush();
    return 0;
}
```

You could compile it like this via g++:
```
g++ -o hello hello.cpp asm_printf.obj -lkernel32 -Wl,--default-image-base-low
```
**Important!** This is a minimal example you can't remove compile flags, it won't work without them
