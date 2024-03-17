.PHONY:	clean run compile compile_and_run

CFLAGS = -lkernel32 -Wl,--default-image-base-low -g
CXX = g++

compile_and_run: compile run
test: asm_printf test_compile run_test
compile: asm_printf main test_compile

asm_printf:
	nasm -f win64 asm_printf.asm

main:
	$(CC) -o main.exe main.cpp asm_printf.obj $(CFLAGS)

test_compile:
	$(CC) -o test.exe test_printf.cpp asm_printf.obj $(CFLAGS)

run:
	main.exe

run_test:
	test.exe

clean:
	del asm_printf.obj main.o test.o
