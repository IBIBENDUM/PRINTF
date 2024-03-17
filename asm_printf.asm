;===============================================================================
;                        Custom printf assembly realisation
;===============================================================================

global asm_printf
global asm_flush

extern GetStdHandle
extern WriteConsoleA

;=====================xxxxxxxxx x64 calling convention==========================
; First four arguments are passed in RCX, RDX, R8, R9 (in that order)
; Additional arguments are pushed onto the stack from (right to left)
; Integer return values are returned in RAX if 64 bits or less
; Floating point return values are returned in XMM0
; Parameters less than 64 bits long are not zero extended; the high bits are not zeroed
; The registers RAX, RCX, RDX, R8, R9, R10, R11 are caller-saved
; The registers RBX, RBP, RDI, RSI, RSP, R12, R13, R14, R15 are callee-saved
;===============================================================================

section .text

; TODO: Write a library, include it here. Than make a PR to nasm folk, they really 
;       should have done it themself :)
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

; TODO: Maybe it does copy a character to buffer, but it's sure not it's purpose 
;       (I think you instead meant printing a character, I know this looking at
;       your function name... So no reason for "copy char..." explanation, make
;       it describe purpose, not the way of achieving it).
; --Copy character to buffer procedure------------------------------------------
; brief:        Copy the character to the buffer
;               If the buffer is full outputs it and copies the character
;               Increments R13, needed to count the output characters
; entry:        AL - Character to print
; destroys:     RCX, R13
; ------------------------------------------------------------------------------
print_char:                                                 ; BAH: Should i do it by macro? TODO: Yeah, probably.

                mov  rcx, [buffer.len]
                add  rcx,  buffer
                mov  BYTE  [rcx], al
                inc  QWORD [buffer.len]
                inc  r13                                    ; TODO: Don't do it here... Like why?
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

; TODO: What is this? rbp + r12 seems like a thing I would wanna do out of the blue.
;       If it's a niche macro used in specific place make it look like one.
; --Get argument macro----------------------------------------------------------
; brief:        Gets an argument from the stack and writes it to the specified register
; ------------------------------------------------------------------------------
%macro          .get_arg 1      ; TODO: Name it better .get_stack_arg_by_offset/ (joke .gsabo)
                mov  %1, QWORD [rbp + r12]                 ; BAH: Are there standard constants for type sizes?
                add  r12, 8
%endmacro
; --End of get argument macro---------------------------------------------------

; TODO: The same (sometimes no documentation is better than horrible documentation)
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
; brief:        Loads the data from the given locations, converts them to character string equivalents TODO: (equivalents??)
;               TODO: Is 3.15871421 equivalent to "3.1" with "%f.1" specifier. I think not!
;               and writes the results to stdout
;
; entry:        Arg 1 - Format string
;               ...   - Arguments specifying data to print
;               TODO: How do I know that this is in System V calling convention? Just guess -- hard to do since all your other aren't. 
;                     And you know what? I guessed wrong too! It's Microsoft calling convention, not System V. THIS IS WHY YOU SHOULD WRITE IT EXPLICITLY.
; assumes:      Microsoft x64 calling convention
; calling convention: Microsoft x64 calling convention
; ------------------------------------------------------------------------------
asm_printf:
                                                            ; Prologue
                pop  r10                                    ; Save return value TODO: return address
                push r9, r8, rdx, rcx                       ; See "Microsoft x64 calling convention" in code
                push r10                                    ; Push return value TODO: It does not

                push rbp                                    ; Stack frame
                mov  rbp, rsp                               ;

                push rbx, rdi, rsi, r12, r13                ; See Microsoft x64 calling convention

                xor  r13, r13                               ; R13 := 0 // Number of characters actually printed
                mov  r12, 2 * 8                             ; First argument offset
                .get_arg rsi

.next_sym:      xor  rax, rax
                lodsb                                       ; BAH: Where can I see about comparing mov and lodsb ; TODO: Benchmark it yourself!
                                                            ; and does it make sense to do conditional assembly for different processors?
                cmp  al, '%'
                je   .format_spec

                cmp  al, 0Ah                                ; Print buffer when '\n' occurs
                je   .new_line

                test al, al
                je   .final

.character:     call print_char                             ; BAH: Does it make sense to search for '%' by bytes but copy to the buffer by QWORDs?
                jmp  .next_sym

.new_line:      call  print_char                            ; TODO: You may check for flush necessity here to avoid subsequent flushes
                call  asm_flush                             ; TODO: Instead check in the end should you flush unconditionally
                jmp   .next_sym

.format_spec:   lodsb

                cmp  al, '%'                                ; "...%%..." => '%' TODO: You've already implemented this later
                je   .character

                test al, al                                 ; "...%" => final
                je   .final

                xor  rbx, rbx
                mov  bl, al
                                                            ; Check the boundaries
                cmp  bl, JMP_TABLE.SIZE + 'a' - 1           ; 'a' is needed to not subtract from the register
                ja   .spec_invalid                          ;
                cmp  bl, 'a'                                ;
                jl   .spec_invalid                          ;

                .get_arg  rax                               ; RAX := Argument specifying data to print
                jmp  QWORD [JMP_TABLE + 8 * (rbx - 'a')]    ; OMG THX NASM
;--Printf format specifiers---------------------------------

.spec_invalid:  mov  al, bl
                call print_char
                jmp .next_sym
;BAH: Do I need to make another function to divide by 2^n?

.spec_2n_number 2                                           ; See .spec_2n_number macro
.spec_2n_number 8                                           ;
.spec_2n_number 16                                          ;

.spec_number_10:
                xor  rcx, rcx
                mov  cl, 10                                 ; Number base

.print_signed:  test eax, 80000000h                         ; BAH: What is good way to get an MSB? TODO: can you use (1 << 31)?
                je   .print_unsigned

                mov  ebx, eax                               ; Save registers
                mov  rdx, rcx                               ;

                mov  al,  '-'                               ; TODO: Can you make this happen? .print_char '-' / .print_char rax
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

.final:         mov  rax, r13
                pop  rbx, rdi, rsi, r12, r13                ; See Microsoft x64 calling convention

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
                call GetStdHandle                           ; Retrieve a handle to the standard output TODO: every time?

                mov  rcx,  rax                              ; Handle to the console screen buffer
                                                            ; BAH: Is there a significant difference between mov and lea for constant addresses?
                lea  r9,   [rsp + 40]                       ; A pointer to a variable that receives the number of characters actually written
                mov  QWORD [rsp + 32], 0                    ; Reserved, must be NULL
                call WriteConsoleA                          ; WriteConsole(hConsoleOutput, *lpBuffer, nNumberOfCharsToWrite, lpNumberOfCharsWritten, lpReserved)
                mov  QWORD [buffer.len], 0                  ; Buffer is not cleared, only the length is zeroed

                add  rsp, 8 + 8 + 32
                ret
; --End of flush buffer procedure-----------------------------------------------

; --Flush buffer procedure------------------------------------------------------ TODO: AHHAHAHAHAHAHAHAHAH, Ctrl+C Ctrl+V goes brrrr
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
                lea  rdi, [rbp - 8]                         ; TODO: Comment, also why 8 

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
                equ 128         ; TODO: Why not 10x the space needed
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

.SIZE           equ ($ - JMP_TABLE) / 8

NUMBER_TABLE    db '0123456789abcdef'
