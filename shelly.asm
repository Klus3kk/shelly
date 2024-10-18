; I'm using 64-bit registers so no int 0x80 or eax, ebx etc.
section .data
    default_prompt db 0x1B, '[32mshelly> ', 0x1B, '[0m', 0    ; Default prompt in green
    exit_msg db 'Exiting Shelly...', 10, 0                    ; Exit message with newline
    prompt_suffix db '> ', 0x1B, '[0m', 0                     ; Suffix to append to the prompt and reset color

section .bss
    user_input resb 64                                        ; Reserve 64 bytes for user input
    current_prompt resb 64                                    ; Reserve space for the current shell prompt

section .text
    global _start                                             ; Define the program entry point

_start:
    ; Copy default prompt into current_prompt
    lea rsi, [default_prompt]
    lea rdi, [current_prompt]
    call copy_prompt

main_loop:
    ; Display the shell prompt
    lea rsi, [current_prompt] ; address of the current prompt string
    call print_string         ; Print current shell prompt

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
    ; Print the user's input (after `echo `)
    mov rax, 1              ; syscall: sys_write
    mov rdi, 1              ; file descriptor: stdout (1)
    lea rsi, [user_input + 5] ; print everything after 'echo '
    call print_string        ; Use helper to print string

    jmp main_loop           ; Go back to the main loop

handle_shcg:
    ; Clear the current prompt before updating
    mov rcx, 64
    lea rdi, [current_prompt]
    xor rax, rax
    rep stosb               ; Clear current prompt

    ; Change the prompt based on user input after `shcg `
    lea rsi, [user_input + 5]  ; Pointer to the new prompt (after `shcg `)
    lea rdi, [current_prompt]  ; Pointer to the current prompt variable
    call copy_prompt           ; Copy the new prompt character by character

    ; Append '>' to the new prompt and reset color
    lea rsi, [prompt_suffix]   ; Address of the '>' suffix
    lea rdi, [current_prompt + rdx] ; Append after copied prompt
    call copy_prompt           ; Copy '>' to the end of the prompt

    jmp main_loop              ; Go back to the main loop

handle_exit:
    ; Check if the full input is `exit`
    lea rsi, [user_input]      ; Load user input buffer
    cmp dword [rsi], 0x74697865 ; Compare with "exit" in little-endian
    je exit_shell              ; If it's "exit", exit the shell

    ; If not "exit", treat it as regular input
    jmp handle_echo

exit_shell:
    ; Print the exit message with a newline
    lea rsi, [exit_msg]        ; address of the exit message
    call print_string          ; Use helper to print the exit message

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

print_string:
    ; Print string pointed to by rsi
    mov rax, 1              ; syscall: sys_write
    mov rdi, 1              ; file descriptor: stdout
    call strlen             ; Get string length into rdx
    syscall                 ; Perform the syscall
    ret

strlen:
    ; Calculate the length of a string in rsi, store result in rdx
    xor rdx, rdx             ; Clear the length counter
strlen_loop:
    cmp byte [rsi + rdx], 0  ; Check for null terminator
    je strlen_done           ; If null terminator, end the loop
    inc rdx                  ; Increment the length
    jmp strlen_loop          ; Continue loop

strlen_done:
    ret                      ; Return with length in rdx
