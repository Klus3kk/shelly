; I'm using 64-bit registers so no int 0x80 or eax, ebx etc.

section .data
    default_prompt db 0x1B, '[32mshelly> ', 0x1B, '[0m', 0    ; Default prompt in green
    exit_msg db 'Exiting Shelly...', 10, 0                    ; Exit message with newline
    prompt_suffix db '> ', 0x1B, '[0m', 0                     ; Suffix to append to the prompt and reset color
    help_msg db 'Usage: shcolor <number>\n1: Red\n2: Green\n3: Yellow\n4: Blue\n', 0
    red_color db 0x1B, '[31m', 0                              ; Red prompt color
    green_color db 0x1B, '[32m', 0                            ; Green prompt color
    yellow_color db 0x1B, '[33m', 0                           ; Yellow prompt color
    blue_color db 0x1B, '[34m', 0                             ; Blue prompt color

section .bss
    user_input resb 64                                        ; Reserve 64 bytes for user input
    current_prompt resb 64                                    ; Reserve space for the current shell prompt
    prompt_base resb 64                                       ; Base prompt, will change with shcolor

section .text
    global _start                                             ; Define the program entry point

_start:
    ; Initialize default prompt and base prompt to green shelly>
    lea rsi, [default_prompt]
    lea rdi, [current_prompt]
    call copy_prompt

    lea rsi, [green_color]        ; Set default color (green)
    lea rdi, [prompt_base]
    call copy_prompt
    lea rsi, [prompt_suffix]       ; Append '>'
    lea rdi, [prompt_base + 5]
    call copy_prompt

main_loop:
    ; Display the shell prompt
    lea rsi, [current_prompt]      ; address of the current prompt string
    call print_string              ; Print current shell prompt

    ; Clear the user input buffer
    mov rcx, 64
    lea rdi, [user_input]
    xor rax, rax
    rep stosb                      ; Fill the input buffer with null bytes

    ; Get user input
    mov rax, 0                     ; syscall: sys_read
    mov rdi, 0                     ; file descriptor: stdin (0)
    mov rsi, user_input            ; buffer to store input
    mov rdx, 64                    ; maximum input length
    syscall                        ; Make the system call

    ; Check for `exit` command
    lea rsi, [user_input]          ; Load the address of the input buffer
    cmp byte [rsi], 'e'            ; Compare the first character to 'e'
    je handle_exit                 ; If first character is 'e', check for `exit`

    ; Check for `echo` command
    cmp byte [rsi], 'e'            ; Check if the first character is 'e' for 'echo'
    je handle_echo                 ; If echo, handle the echo command

    ; Check for `shcg` command
    cmp byte [rsi], 's'            ; Check if first character is 's' for 'shcg'
    je handle_shcg                 ; If shcg, handle changing the prompt

    ; Check for `shcolor` command
    cmp byte [rsi + 6], 'c'        ; Check for 'shcolor'
    je handle_shcolor

    jmp main_loop                  ; Loop back to prompt for next command

handle_echo:
    ; Print the user's input (after `echo `)
    mov rax, 1                     ; syscall: sys_write
    mov rdi, 1                     ; file descriptor: stdout (1)
    lea rsi, [user_input + 5]      ; print everything after 'echo '
    call print_string              ; Use helper to print string
    jmp main_loop                  ; Go back to the main loop

handle_shcg:
    ; Clear the current prompt before updating
    mov rcx, 64
    lea rdi, [current_prompt]
    xor rax, rax
    rep stosb                      ; Clear current prompt

    ; Change the prompt based on user input after `shcg `
    lea rsi, [prompt_base]          ; Load the base (colored part)
    lea rdi, [current_prompt]       ; Store to current prompt
    call copy_prompt                ; Copy the color part of the prompt

    lea rsi, [user_input + 5]       ; Pointer to the new prompt (after `shcg `)
    lea rdi, [current_prompt + 5]   ; Append to colored prompt
    call copy_prompt                ; Copy the new prompt text

    lea rsi, [prompt_suffix]        ; Append '>'
    lea rdi, [current_prompt + rdx] ; Add the final part (>)
    call copy_prompt                ; Complete the prompt

    ; Immediately go back to the main loop without adding new lines
    jmp main_loop

handle_shcolor:
    ; Check if no argument was given (only `shcolor`)
    cmp byte [user_input + 7], 0
    je show_help                    ; If no argument, show help

    ; Get the color argument (e.g., `shcolor 1`)
    lea rsi, [user_input + 7]
    cmp byte [rsi], '1'
    je set_red
    cmp byte [rsi], '2'
    je set_green
    cmp byte [rsi], '3'
    je set_yellow
    cmp byte [rsi], '4'
    je set_blue

    jmp main_loop                   ; If no valid argument, ignore

set_red:
    lea rsi, [red_color]
    lea rdi, [prompt_base]
    call copy_prompt
    lea rsi, [prompt_suffix]        ; Add '>'
    lea rdi, [prompt_base + 5]
    call copy_prompt
    jmp main_loop

set_green:
    lea rsi, [green_color]
    lea rdi, [prompt_base]
    call copy_prompt
    lea rsi, [prompt_suffix]        ; Add '>'
    lea rdi, [prompt_base + 5]
    call copy_prompt
    jmp main_loop

set_yellow:
    lea rsi, [yellow_color]
    lea rdi, [prompt_base]
    call copy_prompt
    lea rsi, [prompt_suffix]        ; Add '>'
    lea rdi, [prompt_base + 5]
    call copy_prompt
    jmp main_loop

set_blue:
    lea rsi, [blue_color]
    lea rdi, [prompt_base]
    call copy_prompt
    lea rsi, [prompt_suffix]        ; Add '>'
    lea rdi, [prompt_base + 5]
    call copy_prompt
    jmp main_loop

show_help:
    ; Display the help message for `shcolor`
    lea rsi, [help_msg]
    call print_string
    jmp main_loop

handle_exit:
    ; Check if the full input is `exit`
    lea rsi, [user_input]           ; Load user input buffer
    cmp dword [rsi], 0x74697865     ; Compare with "exit" in little-endian
    je exit_shell                   ; If it's "exit", exit the shell

    ; If not "exit", treat it as regular input
    jmp handle_echo

exit_shell:
    ; Print the exit message with a newline
    lea rsi, [exit_msg]             ; address of the exit message
    call print_string               ; Use helper to print the exit message

    ; Exit the shell
    mov rax, 60                     ; syscall: sys_exit (60 in 64-bit)
    xor rdi, rdi                    ; exit status 0
    syscall                         ; Make the system call

copy_prompt:
    ; Copy user input (new prompt) to current_prompt
    mov rcx, 64                     ; Max 64 characters
copy_loop:
    lodsb                           ; Load byte from source (user_input)
    stosb                           ; Store byte to destination (current_prompt)
    cmp al, 0                       ; If null terminator, stop copying
    je done_copying
    loop copy_loop                  ; Repeat until all bytes are copied

done_copying:
    ret                             ; Return from function

print_string:
    ; Print string pointed to by rsi
    mov rax, 1                      ; syscall: sys_write
    mov rdi, 1                      ; file descriptor: stdout
    call strlen                     ; Get string length into rdx
    syscall                         ; Perform the syscall
    ret

strlen:
    ; Calculate the length of a string in rsi, store result in rdx
    xor rdx, rdx                    ; Clear the length counter
strlen_loop:
    cmp byte [rsi + rdx], 0         ; Check for null terminator
    je strlen_done                  ; If null terminator, end the loop
    inc rdx                         ; Increment the length
    jmp strlen_loop                 ; Continue loop

strlen_done:
    ret                             ; Return with length in rdx
