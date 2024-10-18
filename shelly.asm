; I'm using 64-bit registers so no int 0x80 or eax, ebx etc.

section .data
    default_prompt db 'shelly> ', 0         ; Default prompt
    exit_msg db 'Exiting Shelly...', 0      ; Exit message
    echo_msg db 'Echo: ', 0                 ; Echo prefix

section .bss
    user_input resb 64                      ; Reserve 64 bytes for user input
    current_prompt resb 64                  ; Reserve space for the current shell prompt

section .text
    global _start                           ; Define the program entry point

_start:
    ; Copy default prompt into current_prompt
    lea rsi, [default_prompt]
    lea rdi, [current_prompt]
    call copy_prompt

    ; Main loop
main_loop:
    ; Display the shell prompt
    mov rax, 1              ; syscall: sys_write
    mov rdi, 1              ; file descriptor: stdout (1)
    lea rsi, [current_prompt] ; address of the current prompt string
    mov rdx, 64             ; max length of the prompt
    syscall                 ; Make the system call

    ; Get user input
    mov rax, 0              ; syscall: sys_read
    mov rdi, 0              ; file descriptor: stdin (0)
    mov rsi, user_input     ; buffer to store input
    mov rdx, 64             ; maximum input length
    syscall                 ; Make the system call

    ; Check for `exit` command
    lea rsi, [user_input]    ; Load the address of the input buffer
    cmp byte [rsi], 'e'      ; Compare the first character to 'e'
    je handle_exit           ; If first character is 'e', check for `exit`

    ; Check for `echo` command
    cmp byte [rsi], 'e'      ; Check if the first character is 'e' for 'echo'
    je handle_echo           ; If echo, handle the echo command

    ; Check for `shcg` command
    cmp byte [rsi], 's'      ; Check if first character is 's' for 'shcg'
    je handle_shcg           ; If shcg, handle changing the prompt

    jmp main_loop            ; Loop back to prompt for next command

handle_echo:
    ; Print the 'Echo: ' message
    mov rax, 1              ; syscall: sys_write
    mov rdi, 1              ; file descriptor: stdout (1)
    lea rsi, [echo_msg]     ; address of the echo message
    mov rdx, 6              ; length of the echo message
    syscall                 ; Make the system call

    ; Print the user's input (after `echo`)
    mov rax, 1              ; syscall: sys_write
    mov rdi, 1              ; file descriptor: stdout (1)
    lea rsi, [user_input + 5] ; print everything after 'echo '
    mov rdx, 59             ; print up to 59 characters after 'echo '
    syscall                 ; Make the system call

    jmp main_loop           ; Go back to the main loop

handle_shcg:
    ; Change the prompt based on user input after `shcg `
    lea rsi, [user_input + 5]  ; Pointer to the new prompt (after `shcg `)
    lea rdi, [current_prompt]  ; Pointer to the current prompt variable
    call copy_prompt           ; Call function to copy the new prompt

    jmp main_loop              ; Go back to the main loop

handle_exit:
    ; Check if the full input is `exit`
    lea rsi, [user_input]      ; Load user input buffer
    cmp dword [rsi], 0x74697865 ; Compare with "exit" in little-endian
    je exit_shell              ; If it's "exit", exit the shell

    ; If not "exit", treat it as regular input
    jmp handle_echo

exit_shell:
    ; Print the exit message
    mov rax, 1              ; syscall: sys_write
    mov rdi, 1              ; file descriptor: stdout (1)
    lea rsi, [exit_msg]     ; address of the exit message
    mov rdx, 18             ; length of the exit message
    syscall                 ; Make the system call

    ; Exit the shell
    mov rax, 60             ; syscall: sys_exit (60 in 64-bit)
    xor rdi, rdi            ; exit status 0
    syscall                 ; Make the system call

copy_prompt:
    ; Copy user input (new prompt) to current_prompt
    mov rcx, 64              ; Max 64 characters
copy_loop:
    lodsb                    ; Load byte from source (user_input)
    stosb                    ; Store byte to destination (current_prompt)
    cmp al, 0                ; If null terminator, stop copying
    je done_copying
    loop copy_loop           ; Repeat until all bytes are copied

done_copying:
    ret                      ; Return from function
