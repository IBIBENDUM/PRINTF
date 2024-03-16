;===============================================================================
;                        Custom printf assembly realisation
;===============================================================================

global asm_printf
global asm_flush

extern GetStdHandle
extern WriteConsoleA

; BAH: Make correct return value

;=====================Microsoft x64 calling convention==========================
; First four arguments are passed in RCX, RDX, R8, R9 (in that order)
; Additional arguments are pushed onto the stack from (right to left)
; Integer return values are returned in RAX if 64 bits or less
; Floating point return values are returned in XMM0
; Parameters less than 64 bits long are not zero extended; the high bits are not zeroed
; The registers RAX, RCX, RDX, R8, R9, R10, R11 are caller-saved
; The registers RBX, RBP, RDI, RSI, RSP, R12, R13, R14, R15 are callee-saved
;===============================================================================

section .text

; --Multiple push macro---------------------------------------------------------
; brief:        Push multiple elements
;               Arguments separated by commas
; ------------------------------------------------------------------------------
%macro          push  1-*                                   ; Number of parameters from one to any
                                                            ; %0 - The number of parameters received
                %rep  %0                                    ; Repeate for every argument
                push  %1                                    ; Push first argument
                %rotate 1                                   ; The macro parameters are rotated to the left,
                                                            ; so original second argument is now available as %1
                %endrep
%endmacro
; --End of multiple push macro--------------------------------------------------

; --Multiple pop macro----------------------------------------------------------
; brief:        Pop multiple elements
;               Arguments separated by commas
; attention:    Arguments pops in reverse order!
;               This is done for ease of use multiple push and multiple pop
; ------------------------------------------------------------------------------
%macro          pop  1-*                                    ; See push macro for an explanation
                %rep %0
                %rotate -1
                pop  %1
                %endrep
%endmacro
; --End of multiple pop macro---------------------------------------------------

; --Copy character to buffer procedure------------------------------------------
; brief:        Copy the character to the buffer
;               If the buffer is full outputs it and copies the character
; entry:        AL - Character to print
; destroys:     RCX
; ------------------------------------------------------------------------------
print_char:                                                 ; BAH: Should i do it by macro?

                mov  rcx, [buffer.len]
                add  rcx,  buffer
                mov  BYTE  [rcx], al
                inc  QWORD [buffer.len]
                                                            ; BAH: Buffer overflow check only after writing,
                                                            ; so that output can be output without a buffer.
                                                            ; How can I do this better?
                cmp  rcx, buffer + BUF_CAPACITY - 1
                jl   .final
                push rax, rdx, r8, r9
                call asm_flush
                pop  rax, rdx, r8, r9
.final:         ret
; --End of copy character to buffer procedure-----------------------------------

; --Get argument macro----------------------------------------------------------
; brief:        Gets an argument from the stack and writes it to the specified register
; ------------------------------------------------------------------------------
%macro          .get_arg 1
                mov  %1, QWORD [rbp + r12]                 ; BAH: Are there standard constants for type sizes?
                add  r12, 8
%endmacro
; --End of get argument macro---------------------------------------------------

; --Number specifier macro------------------------------------------------------
; brief:        Create mark e.g. asm_printf.spec_number_2 to output the number as a string
; ------------------------------------------------------------------------------
%macro          .spec_2n_number 1
.spec_number_%1:
                xor  rcx, rcx
                mov  cl, %1                                 ; Number base
                jmp  asm_printf.print_unsigned
%endmacro
; --End of number specifier macro-----------------------------------------------

; --Copy character to buffer procedure------------------------------------------
; brief:        Loads the data from the given locations, converts them to character string equivalents
;               and writes the results to stdout
; entry:        Arg 1 - Format string
;               ...   - Arguments specifying data to print
; assumes:      Microsoft x64 calling convention
; ------------------------------------------------------------------------------
asm_printf:
                                                            ; Prologue
                pop  r10                                    ; Save return value
                push r9, r8, rdx, rcx                       ; See "Microsoft x64 calling convention" in code
                push r10                                    ; Push return value
                push rbp                                    ; Stack frame
                mov  rbp, rsp                               ;

                push rbx, rdi, rsi                          ; See Microsoft x64 calling convention

                mov  r12, 2 * 8                             ; First argument offset
                .get_arg rsi

.next_sym:      xor  rax, rax
                lodsb                                       ; BAH: Where can I see about comparing mov and lodsb
                                                            ; and does it make sense to do conditional assembly for different processors?
                cmp  al, '%'
                je   .format_spec

                cmp  al, 0Ah                                ; Print buffer when '\n' occurs
                je   .new_line

                test al, al
                je   .final

.character:     call print_char                             ; BAH: Does it make sense to search for '%' by bytes but copy to the buffer by QWORDs?
                jmp  .next_sym

.new_line:      call  asm_flush
                jmp  .character

.format_spec:   xor  rax, rax                               ; Maybe I should zeroize the high bits after the al checks?
                lodsb

                cmp  al, '%'                                ; "...%%..." => '%'
                je   .character

                test al, al                                 ; "...%" => final
                je   .final

                sub  al, 'a'                                ; AL := index in JMP_TABLE

                cmp  al, JMP_TABLE.SIZE                     ; Check the boundaries
                ja   .spec_invalid                          ;
                cmp  al, 0                                  ;
                jl   .spec_invalid                          ;

                mov  rbx, rax
                .get_arg  rax                               ; BAH: Is it worth saving on code size here?
                jmp  QWORD [JMP_TABLE + 8 * rbx]            ; OMG THX NASM
;--Printf format specifiers---------------------------------

.spec_invalid:  call print_char
                jmp .next_sym

;BAH: Do I need to make another function to divide by 2^n?

.spec_2n_number 2                                           ; See .spec_2n_number macro
.spec_2n_number 8                                           ;
.spec_2n_number 16                                          ;

.spec_number_10:
                xor  rcx, rcx
                mov  cl, 10                                 ; Number base

.print_signed:  test eax, 80000000h                         ; BAH: What is good way to get an MSB?
                je   .print_unsigned

                mov  ebx, eax                               ; Save registers
                mov  rdx, rcx                               ;

                mov  al,  '-'
                call print_char

                mov  rcx, rdx                               ; Load registers
                mov  eax, ebx                               ;

                neg  eax                                    ; Because sizeof(int) == 4
.print_unsigned:
                mov  eax, eax                               ; Zero out the higher 32 bits
                call print_num
                jmp  .next_sym

.spec_string:   mov  rdi, rax
                call print_str
                jmp  .next_sym
;--End of printf format specifiers--------------------------

.final:         pop  rbx, rdi, rsi                          ; See Microsoft x64 calling convention

                pop  rbp                                    ; Epilogue
                pop  r10                                    ; Save return value
                add  rsp, 4 * 8                             ; Skip pushed registers
                push r10                                    ; Push return value

                ret
; --End of asm printf procedure-------------------------------------------------

%define STD_OUTPUT_HANDLE -11

; --Flush full buffer procedure-------------------------------------------------
; brief:        Output the buffer to the console using the WriteConsoleA func
; destroys:     RAX, RCX, RDX, R8, R9
; ------------------------------------------------------------------------------
asm_flush:
                lea  rdx, [buffer]
                mov  r8,  [buffer.len]
                call flush_buffer
                ret
; --End of flush full buffer procedure------------------------------------------

; --Flush buffer procedure------------------------------------------------------
; brief:        Output the buffer to the console using the WriteConsoleA func
; entry:        RDX - Pointer to a buffer
;               R8  - The number of characters to be written
; destroys:     RAX, RCX, R9
; ------------------------------------------------------------------------------
flush_buffer:
                sub  rsp, 8 + 8 + 32                        ; Reserve shadow space and align stack by 16
                                                            ; BAH: I don't fully understand it.
                mov  rcx, STD_OUTPUT_HANDLE
                call GetStdHandle                           ; Retrieve a handle to the standard output

                mov  rcx,  rax                              ; Handle to the console screen buffer
                                                            ; BAH: Is there a significant difference between mov and lea for constant addresses?
                lea  r9,   [rsp + 40]                       ; A pointer to a variable that receives the number of characters actually written
                mov  QWORD [rsp + 32], 0                    ; Reserved, must be NULL
                call WriteConsoleA                          ; WriteConsole(hConsoleOutput, *lpBuffer, nNumberOfCharsToWrite, lpNumberOfCharsWritten, lpReserved)
                mov  QWORD [buffer.len], 0                  ; Buffer is not cleared, only the length is zeroed

                add  rsp, 8 + 8 + 32
                ret
; --End of flush buffer procedure-----------------------------------------------

; --Flush buffer procedure------------------------------------------------------
; brief:        Converts a unsigned number to a string and writes it to the buffer
; entry:        RAX - Output number
;               RCX - Number base
; destroys:     RAX, RBX, RCX, RDX, RDI, R8, R9
; ------------------------------------------------------------------------------
print_num:
                push rbp                                    ; Prologue
                mov  rbp, rsp                               ;
                sub  rsp, NUM_BUF_CAPACITY                  ; Local buffer for number

                xor  r8,  r8                                ; R8 := Number of symbols
                lea  rdi, [rbp - 8]

.print_digit:   xor  rdx, rdx                               ; We work with 64-bit numbers
                div  rcx                                    ; Divide by the base
                mov  bl,  [NUMBER_TABLE + rdx]              ; You cannot mov from mem to mem
                mov  [rdi], bl
                dec  rdi
                inc  r8

                test rax, rax
                jne  .print_digit

                inc  rdi
.cpy_num_to_buf:
                mov  al, [rdi]
                inc  rdi
                dec  r8
                call print_char
                test r8, r8
                jne  .cpy_num_to_buf

                add  rsp, NUM_BUF_CAPACITY                  ; Epilogue
                pop  rbp                                    ;
                ret
; --End of flush buffer procedure-----------------------------------------------

; --Print string procedure------------------------------------------------------
; brief:        Output the string character by character until '\0'
; entry:        RDI - Output string
; destroys:     AL, RDI, RCX
; ------------------------------------------------------------------------------
print_str:      mov  al, [rdi]                              ; AL := *RDI
                inc  rdi
                test al, al
                je   .final
                call print_char
                jmp  print_str
.final:         ret
; --End of print string procedure-----------------------------------------------

section .data
NUM_BUF_CAPACITY \
                equ 128
BUF_CAPACITY    equ 128
buffer:         times BUF_CAPACITY db 0
.len:           dq 0

JMP_TABLE:      dq asm_printf.spec_invalid                  ; %a
                dq asm_printf.spec_number_2                 ; %b
                dq asm_printf.character                     ; %c
                dq asm_printf.spec_number_10                ; %d

                times 'n' - 'e' + 1 \
                        dq asm_printf.spec_invalid          ; %e - %n

                dq asm_printf.spec_number_8                 ; %o

                times 'r' - 'p' + 1 \
                        dq asm_printf.spec_invalid          ; %p - %r

                dq asm_printf.spec_string                   ; %s

                times 'w' - 't' + 1 \
                        dq asm_printf.spec_invalid          ; %t - %w

                dq asm_printf.spec_number_16                ; %x

                times 'z' - 'y' + 1 \
                        dq asm_printf.spec_invalid          ; %y - %z

.SIZE           equ $ - JMP_TABLE

NUMBER_TABLE    db '0123456789abcdef'
