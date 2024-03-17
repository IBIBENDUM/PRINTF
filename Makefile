.PHONY:	clean run run_test

CFLAGS = -lkernel32 -Wl,--default-image-base-low -g
CXX    = g++

compile: asm_printf main test_compile
compile_and_run: compile run
test: asm_printf test_compile run_test

asm_printf:
	nasm -f win64 asm_printf.asm

main:
	$(CXX) -o main main.cpp asm_printf.obj $(CFLAGS)

test_compile:
	$(CXX) -o test test_printf.cpp asm_printf.obj $(CFLAGS)

run:
	main

run_test:
	test

clean:
	del asm_printf.obj main.o test.o
