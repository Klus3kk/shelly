section .data ; Static data
    prompt db 'shelly> ', 0 ; db - define byte, null terminated
    exit_msg db 'Exiting Shelly...', 0
    echo_msg db 'Echo: ', 0

section .bss ; Uninitialized data
    user_input resb 64 ; Reverse byte

section .text ; Code that will be executed
    global _start ; Entry point

_start:
    ; Main loop
main_loop:
    ; Display prompt
    mov eax, 4      ; sys_write
    mov ebx, 1      ; stdout
    mov ecx, prompt ; address of prompt
    mov edx, 8      ; length of prompt
    int 0x80        ; Print on the screen

    ; Get user input
    mov eax, 3          ; sys_read
    mov ebx, 0          ; stdin
    mov ecx, user_input ; buffer for input
    mov edx, 64         ; max length
    int 0x80            

    ; Check for `exit`
    mov ecx, user_input
    cmp byte [ecx], 'e'
    je exit_shell

    ; Check for `echo`
    cmp byte [ecx], 'e'
    je echo_command

    jmp main_loop

echo_command:
    ; Echo the user input
    mov eax, 4
    mov ebx, 1
    mov ecx, echo_msg
    mov edx, 6
    int 0x80

    ; Echo the actual text typed by user
    mov eax, 4
    mov ebx, 1
    mov ecx, user_input
    mov edx, 64
    int 0x80
    jmp main_loop    

exit_shell:
   ; Exit the shell
   mov eax, 4
   mov ebx, 1
   mov ecx, exit_msg
   mov edx, 18
   int 0x80
   mov eax, 1          ; sys_exit
   xor ebx, ebx        ; status 0
   int 0x80