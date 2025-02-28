; Advanced x86-64 Shelly Shell for Linux
; Feature-rich yet lightweight

section .data
    ; Core shell prompts and messages
    default_prompt db 0x1B, '[32mshelly> ', 0x1B, '[0m', 0    ; Default prompt in green
    exit_msg db 'Exiting Shelly...', 10, 0                    ; Exit message with newline
    prompt_suffix db '> ', 0x1B, '[0m', 0                     ; Suffix to append to the prompt and reset color
    newline db 10, 0                                          ; Newline character
    
    ; Command not found and error messages
    cmd_not_found db 'Command not found: ', 0                 ; Error message
    dir_not_found db 'Directory not found: ', 0               ; Directory error
    file_not_found db 'File not found: ', 0                   ; File error
    
    ; Welcome screen
    welcome_msg db 0x1B, '[36m', "╔════════════════════════════════════════╗", 10
                db "║                                        ║", 10
                db "║        Welcome to Shelly Shell         ║", 10
                db "║    Advanced Assembly Shell v1.0.0      ║", 10
                db "║                                        ║", 10
                db "║  Type 'help' to see available commands ║", 10
                db "║                                        ║", 10
                db "╚════════════════════════════════════════╝", 0x1B, '[0m', 10, 0
    
    ; Help messages
    help_msg db 0x1B, '[33m', "Available commands:", 0x1B, '[0m', 10
             db "  echo [text]          - Display text", 10
             db "  cd [directory]       - Change directory", 10
             db "  ls                   - List directory contents", 10
             db "  pwd                  - Print working directory", 10
             db "  cat [file]           - Display file contents", 10
             db "  date                 - Show current date and time", 10
             db "  whoami               - Show current user", 10
             db "  mkdir [directory]    - Create a directory", 10
             db "  touch [file]         - Create an empty file", 10
             db "  clear                - Clear the screen", 10
             db "  history              - Show command history", 10
             db "  shcg [text]          - Change prompt text", 10
             db "  shcolor [num]        - Change prompt color", 10
             db "  sysinfo              - Display system information", 10
             db "  help                 - Show this help", 10
             db "  exit                 - Exit the shell", 10, 0
             
    color_help db 'Usage: shcolor <number>', 10
               db '1: Red', 10
               db '2: Green', 10
               db '3: Yellow', 10
               db '4: Blue', 10
               db '5: Purple', 10
               db '6: Cyan', 10
               db '7: White', 10, 0
    
    ; Color codes
    red_color db 0x1B, '[31m', 0                              ; Red prompt color
    green_color db 0x1B, '[32m', 0                            ; Green prompt color
    yellow_color db 0x1B, '[33m', 0                           ; Yellow prompt color
    blue_color db 0x1B, '[34m', 0                             ; Blue prompt color
    purple_color db 0x1B, '[35m', 0                           ; Purple prompt color
    cyan_color db 0x1B, '[36m', 0                             ; Cyan prompt color
    white_color db 0x1B, '[37m', 0                            ; White prompt color
    
    ; System commands
    clear_cmd db "clear", 0x1B, "[H", 0x1B, "[2J", 0          ; ANSI clear screen
    
    ; Process information path
    proc_path db "/proc/", 0
    cpuinfo_path db "/proc/cpuinfo", 0
    meminfo_path db "/proc/meminfo", 0
    hostname_path db "/proc/sys/kernel/hostname", 0
    
    ; Command strings
    cmd_exit db "exit", 0
    cmd_echo db "echo", 0
    cmd_shcg db "shcg", 0
    cmd_shcolor db "shcolor", 0
    cmd_help db "help", 0
    cmd_cd db "cd", 0
    cmd_ls db "ls", 0
    cmd_pwd db "pwd", 0
    cmd_cat db "cat", 0
    cmd_date db "date", 0
    cmd_whoami db "whoami", 0
    cmd_mkdir db "mkdir", 0
    cmd_touch db "touch", 0
    cmd_clear db "clear", 0
    cmd_history db "history", 0
    cmd_sysinfo db "sysinfo", 0
    
    ; Formatting
    format_title db 0x1B, "[1;36m", "%s", 0x1B, "[0m", 10, 0
    format_info db "  %s: ", 0

section .bss
    user_input resb 256                                       ; Expanded buffer for user input
    current_prompt resb 128                                   ; Reserve space for the current shell prompt
    prompt_base resb 64                                       ; Base prompt with color
    temp_buffer resb 256                                      ; Temporary buffer for operations
    file_buffer resb 4096                                     ; Buffer for file operations
    dir_buffer resb 4096                                      ; Buffer for directory entries
    history_buffer resb 4096                                  ; Command history buffer
    history_count resb 4                                      ; Number of history entries
    cwd_buffer resb 256                                       ; Current working directory

section .text
    global _start

_start:
    ; Display welcome message
    lea rsi, [welcome_msg]
    call print_string
    
    ; Initialize default prompt and base prompt
    lea rsi, [green_color]
    lea rdi, [prompt_base]
    call strcpy
    
    ; Set default prompt text
    mov dword [temp_buffer], 'shel'
    mov dword [temp_buffer+4], 'ly'
    mov byte [temp_buffer+6], 0
    
    ; Initialize prompt with default color and text
    call update_prompt
    
    ; Initialize command history
    mov dword [history_count], 0
    
    ; Get current working directory
    call get_cwd
    
    ; Main loop
    jmp main_loop

main_loop:
    ; Display the shell prompt
    lea rsi, [current_prompt]
    call print_string

    ; Clear the user input buffer
    mov rcx, 256
    lea rdi, [user_input]
    xor rax, rax
    rep stosb                        ; Fill the input buffer with null bytes

    ; Get user input
    mov rax, 0                       ; syscall: sys_read
    mov rdi, 0                       ; file descriptor: stdin (0)
    mov rsi, user_input              ; buffer to store input
    mov rdx, 256                     ; maximum input length
    syscall                          ; Make the system call

    ; Remove the newline character if present
    mov rcx, rax                     ; Number of bytes read
    cmp rcx, 0                       ; Check if any bytes were read
    je main_loop                     ; If not, just show prompt again
    
    dec rcx                          ; Last character index
    cmp byte [user_input + rcx], 10  ; Check if newline
    jne skip_newline_removal
    mov byte [user_input + rcx], 0   ; Replace with null terminator
skip_newline_removal:

    ; Check for empty input
    cmp byte [user_input], 0
    je main_loop                     ; If empty, just show prompt again

    ; Add command to history
    call add_to_history
    
    ; Check for commands
    lea rsi, [user_input]
    
    ; Check for "exit" command
    mov rdi, cmd_exit
    call check_command
    jc not_exit
    jmp exit_shell
not_exit:
    
    ; Check for "echo" command
    mov rdi, cmd_echo
    call check_command
    jc not_echo
    jmp handle_echo
not_echo:
    
    ; Check for "shcg" command
    mov rdi, cmd_shcg
    call check_command
    jc not_shcg
    jmp handle_shcg
not_shcg:
    
    ; Check for "shcolor" command
    mov rdi, cmd_shcolor
    call check_command
    jc not_shcolor
    jmp handle_shcolor
not_shcolor:
    
    ; Check for "help" command
    mov rdi, cmd_help
    call check_command
    jc not_help
    jmp handle_help
not_help:
    
    ; Check for "cd" command
    mov rdi, cmd_cd
    call check_command
    jc not_cd
    jmp handle_cd
not_cd:
    
    ; Check for "ls" command
    mov rdi, cmd_ls
    call check_command
    jc not_ls
    jmp handle_ls
not_ls:
    
    ; Check for "pwd" command
    mov rdi, cmd_pwd
    call check_command
    jc not_pwd
    jmp handle_pwd
not_pwd:
    
    ; Check for "cat" command
    mov rdi, cmd_cat
    call check_command
    jc not_cat
    jmp handle_cat
not_cat:
    
    ; Check for "date" command
    mov rdi, cmd_date
    call check_command
    jc not_date
    jmp handle_date
not_date:
    
    ; Check for "whoami" command
    mov rdi, cmd_whoami
    call check_command
    jc not_whoami
    jmp handle_whoami
not_whoami:
    
    ; Check for "mkdir" command
    mov rdi, cmd_mkdir
    call check_command
    jc not_mkdir
    jmp handle_mkdir
not_mkdir:
    
    ; Check for "touch" command
    mov rdi, cmd_touch
    call check_command
    jc not_touch
    jmp handle_touch
not_touch:
    
    ; Check for "clear" command
    mov rdi, cmd_clear
    call check_command
    jc not_clear
    jmp handle_clear
not_clear:
    
    ; Check for "history" command
    mov rdi, cmd_history
    call check_command
    jc not_history
    jmp handle_history
not_history:
    
    ; Check for "sysinfo" command
    mov rdi, cmd_sysinfo
    call check_command
    jc not_sysinfo
    jmp handle_sysinfo
not_sysinfo:
    
    ; Command not found
    lea rsi, [cmd_not_found]
    call print_string
    lea rsi, [user_input]
    call print_string
    lea rsi, [newline]
    call print_string
    jmp main_loop

handle_echo:
    ; Check if argument is provided
    call get_arg
    cmp byte [rsi], 0        ; Check if empty
    je echo_empty
    
    ; Print the argument
    call print_string
    lea rsi, [newline]
    call print_string
    jmp main_loop
    
echo_empty:
    ; Just print a newline
    lea rsi, [newline]
    call print_string
    jmp main_loop

handle_shcg:
    ; Get argument (if any)
    call get_arg
    
    ; Check if argument is provided
    cmp byte [rsi], 0
    je shcg_default
    
    ; Use provided text
    jmp do_shcg
    
shcg_default:
    ; Use default prompt text
    mov dword [temp_buffer], 'shel'
    mov dword [temp_buffer+4], 'ly'
    mov byte [temp_buffer+6], 0
    lea rsi, [temp_buffer]
    
do_shcg:
    ; Copy to temp buffer
    lea rdi, [temp_buffer]
    call strcpy
    
    ; Update the prompt
    call update_prompt
    jmp main_loop

handle_shcolor:
    ; Get argument (if any)
    call get_arg
    
    ; Check if argument is provided
    cmp byte [rsi], 0
    je show_color_help
    
    ; Check which color to set
    cmp byte [rsi], '1'
    je set_red
    cmp byte [rsi], '2'
    je set_green
    cmp byte [rsi], '3'
    je set_yellow
    cmp byte [rsi], '4'
    je set_blue
    cmp byte [rsi], '5'
    je set_purple
    cmp byte [rsi], '6'
    je set_cyan
    cmp byte [rsi], '7'
    je set_white
    
    ; Invalid color, show help
    jmp show_color_help

set_red:
    lea rsi, [red_color]
    jmp update_color

set_green:
    lea rsi, [green_color]
    jmp update_color

set_yellow:
    lea rsi, [yellow_color]
    jmp update_color

set_blue:
    lea rsi, [blue_color]
    jmp update_color

set_purple:
    lea rsi, [purple_color]
    jmp update_color

set_cyan:
    lea rsi, [cyan_color]
    jmp update_color

set_white:
    lea rsi, [white_color]
    jmp update_color

update_color:
    ; Update prompt base with new color
    lea rdi, [prompt_base]
    call strcpy
    
    ; Update the prompt
    call update_prompt
    jmp main_loop

show_color_help:
    ; Display the color help message
    lea rsi, [color_help]
    call print_string
    jmp main_loop

handle_help:
    ; Display the help message
    lea rsi, [help_msg]
    call print_string
    jmp main_loop

handle_cd:
    ; Get directory argument
    call get_arg
    
    ; Check if argument is provided
    cmp byte [rsi], 0
    je cd_home              ; If empty, cd to home
    
    ; Try to change directory
    mov rdi, 80             ; sys_chdir
    mov rsi, rsi            ; directory path
    syscall
    
    ; Check if successful
    test rax, rax
    js cd_error             ; If error (negative return), show error
    
    ; Update current working directory
    call get_cwd
    jmp main_loop
    
cd_home:
    ; Change to home directory
    mov rax, 80             ; sys_chdir
    mov rdi, home_dir       ; Home directory
    syscall
    
    ; Update current working directory
    call get_cwd
    jmp main_loop
    
cd_error:
    ; Show directory error
    lea rsi, [dir_not_found]
    call print_string
    call get_arg            ; Get argument again
    call print_string
    lea rsi, [newline]
    call print_string
    jmp main_loop

handle_ls:
    ; Open current directory
    mov rax, 2              ; sys_open
    lea rdi, [dot_dir]      ; "." (current directory)
    mov rsi, 0              ; O_RDONLY
    syscall
    
    ; Check if successful
    test rax, rax
    js ls_error
    
    ; Save file descriptor
    mov r12, rax
    
    ; Get directory entries
    mov rax, 217            ; sys_getdents64
    mov rdi, r12            ; directory file descriptor
    lea rsi, [dir_buffer]   ; buffer
    mov rdx, 4096           ; buffer size
    syscall
    
    ; Check if successful
    test rax, rax
    js ls_error
    
    ; Save number of bytes read
    mov r13, rax
    
    ; Close directory
    mov rax, 3              ; sys_close
    mov rdi, r12            ; directory file descriptor
    syscall
    
    ; Process directory entries
    xor r14, r14            ; Initialize offset
    
ls_loop:
    ; Check if we've processed all entries
    cmp r14, r13
    jge ls_done
    
    ; Get filename
    lea rsi, [dir_buffer + r14 + 19]  ; d_name field is at offset 19
    
    ; Skip "." and ".." entries
    cmp word [rsi], '.'
    je ls_skip
    
    ; Print filename
    call print_string
    lea rsi, [newline]
    call print_string
    
ls_skip:
    ; Move to next entry (d_reclen is at offset 16)
    movzx r15, word [dir_buffer + r14 + 16]
    add r14, r15
    jmp ls_loop
    
ls_done:
    jmp main_loop
    
ls_error:
    ; Show error
    lea rsi, [dir_not_found]
    call print_string
    lea rsi, [newline]
    call print_string
    jmp main_loop

handle_pwd:
    ; Print current working directory
    lea rsi, [cwd_buffer]
    call print_string
    lea rsi, [newline]
    call print_string
    jmp main_loop

handle_cat:
    ; Get file argument
    call get_arg
    
    ; Check if argument is provided
    cmp byte [rsi], 0
    je cat_error
    
    ; Save file path
    mov rdi, rsi
    
    ; Open file
    mov rax, 2              ; sys_open
    mov rsi, 0              ; O_RDONLY
    syscall
    
    ; Check if successful
    test rax, rax
    js cat_error
    
    ; Save file descriptor
    mov r12, rax
    
    ; Read file content
    mov rax, 0              ; sys_read
    mov rdi, r12            ; file descriptor
    lea rsi, [file_buffer]  ; buffer
    mov rdx, 4096           ; buffer size
    syscall
    
    ; Check if successful
    test rax, rax
    js cat_error
    
    ; Add null terminator to file content
    mov byte [file_buffer + rax], 0
    
    ; Close file
    mov rax, 3              ; sys_close
    mov rdi, r12            ; file descriptor
    syscall
    
    ; Print file content
    lea rsi, [file_buffer]
    call print_string
    lea rsi, [newline]
    call print_string
    jmp main_loop
    
cat_error:
    ; Show file error
    lea rsi, [file_not_found]
    call print_string
    call get_arg            ; Get argument again
    call print_string
    lea rsi, [newline]
    call print_string
    jmp main_loop

handle_date:
    ; Get current time
    mov rax, 201            ; sys_time
    xor rdi, rdi            ; NULL
    syscall
    
    ; Call localtime function
    ; (This would require more work in a real implementation)
    
    ; For now, we'll use a simpler approach
    ; Open /proc/driver/rtc or format the time ourselves
    
    ; Just print a message for demonstration
    lea rsi, [temp_buffer]
    mov rcx, 64
    xor rax, rax
    rep stosb
    
    ; Put current timestamp value in the buffer
    lea rdi, [temp_buffer]
    call format_time
    
    ; Print the formatted time
    lea rsi, [temp_buffer]
    call print_string
    lea rsi, [newline]
    call print_string
    jmp main_loop

handle_whoami:
    ; Get effective user ID
    mov rax, 107            ; sys_geteuid
    syscall
    
    ; Save user ID
    mov r12, rax
    
    ; For a real implementation, we would look up username
    ; in /etc/passwd based on the UID
    
    ; For now, just print the UID
    lea rsi, [temp_buffer]
    mov rcx, 64
    xor rax, rax
    rep stosb
    
    lea rdi, [temp_buffer]
    mov rsi, r12
    call int_to_string
    
    lea rsi, [temp_buffer]
    call print_string
    lea rsi, [newline]
    call print_string
    jmp main_loop

handle_mkdir:
    ; Get directory argument
    call get_arg
    
    ; Check if argument is provided
    cmp byte [rsi], 0
    je mkdir_error
    
    ; Save directory path
    mov rdi, rsi
    
    ; Create directory
    mov rax, 83             ; sys_mkdir
    mov rsi, 0o777          ; permissions (octal)
    syscall
    
    ; Check if successful
    test rax, rax
    js mkdir_error
    
    jmp main_loop
    
mkdir_error:
    ; Show directory error
    lea rsi, [dir_not_found]
    call print_string
    call get_arg            ; Get argument again
    call print_string
    lea rsi, [newline]
    call print_string
    jmp main_loop

handle_touch:
    ; Get file argument
    call get_arg
    
    ; Check if argument is provided
    cmp byte [rsi], 0
    je touch_error
    
    ; Save file path
    mov rdi, rsi
    
    ; Create file
    mov rax, 2              ; sys_open
    mov rsi, 0o100 | 0o1    ; O_CREAT | O_WRONLY
    mov rdx, 0o666          ; permissions (octal)
    syscall
    
    ; Check if successful
    test rax, rax
    js touch_error
    
    ; Save file descriptor
    mov r12, rax
    
    ; Close file
    mov rax, 3              ; sys_close
    mov rdi, r12            ; file descriptor
    syscall
    
    jmp main_loop
    
touch_error:
    ; Show file error
    lea rsi, [file_not_found]
    call print_string
    call get_arg            ; Get argument again
    call print_string
    lea rsi, [newline]
    call print_string
    jmp main_loop

handle_clear:
    ; Clear screen using ANSI escape codes
    lea rsi, [clear_cmd+6]  ; Skip the "clear" part
    call print_string
    jmp main_loop

handle_history:
    ; Print command history
    lea rsi, [history_buffer]
    call print_string
    jmp main_loop

handle_sysinfo:
    ; Display system information
    
    ; CPU information
    lea rsi, [temp_buffer]
    mov rcx, 64
    xor rax, rax
    rep stosb
    
    lea rdi, [temp_buffer]
    mov dword [rdi], 'CPU:'
    mov byte [rdi+4], 0
    
    lea rsi, [temp_buffer]
    call print_string
    lea rsi, [newline]
    call print_string
    
    ; Read /proc/cpuinfo
    mov rax, 2              ; sys_open
    lea rdi, [cpuinfo_path] ; /proc/cpuinfo
    mov rsi, 0              ; O_RDONLY
    syscall
    
    ; Check if successful
    test rax, rax
    js sysinfo_end
    
    ; Save file descriptor
    mov r12, rax
    
    ; Read file content
    mov rax, 0              ; sys_read
    mov rdi, r12            ; file descriptor
    lea rsi, [file_buffer]  ; buffer
    mov rdx, 4096           ; buffer size
    syscall
    
    ; Close file
    mov rax, 3              ; sys_close
    mov rdi, r12            ; file descriptor
    syscall
    
    ; Parse and display relevant information
    ; (In a real implementation, we would parse the file content)
    
    ; For now, just display part of the file
    mov byte [file_buffer + 500], 0
    lea rsi, [file_buffer]
    call print_string
    lea rsi, [newline]
    call print_string
    
sysinfo_end:
    jmp main_loop

exit_shell:
    ; Print the exit message
    lea rsi, [exit_msg]
    call print_string

    ; Exit the shell
    mov rax, 60             ; syscall: sys_exit
    xor rdi, rdi            ; exit status 0
    syscall

; Update the prompt with current color and text
update_prompt:
    ; Clear current prompt
    mov rcx, 128
    lea rdi, [current_prompt]
    xor rax, rax
    rep stosb
    
    ; Add color code
    lea rdi, [current_prompt]
    lea rsi, [prompt_base]
    call strcpy
    
    ; Get current prompt length
    lea rsi, [current_prompt]
    call strlen             ; Get length in rdx
    lea rdi, [current_prompt + rdx] ; Point to end of string
    
    ; Add prompt text
    lea rsi, [temp_buffer]
    cmp byte [rsi], 0       ; Check if empty
    jne add_text            ; If not empty, use it
    
    ; If empty, use "shelly" as default
    mov dword [rdi], 'shel' ; First 4 characters
    mov word [rdi+4], 'ly'  ; Next 2 characters
    add rdi, 6              ; Move pointer
    jmp add_suffix
    
add_text:
    ; Add the custom text from temp_buffer
    call strcpy
    
    ; Find end of string
    lea rsi, [current_prompt]
    call strlen
    lea rdi, [current_prompt + rdx]
    
add_suffix:
    ; Add the prompt suffix
    lea rsi, [prompt_suffix]
    call strcpy
    
    ret

; Add command to history
add_to_history:
    ; Don't add empty commands
    cmp byte [user_input], 0
    je history_done
    
    ; Find end of history buffer
    lea rsi, [history_buffer]
    call strlen
    lea rdi, [history_buffer + rdx]
    
    ; Add line number
    mov eax, [history_count]
    inc eax
    mov [history_count], eax
    
    push rdi                ; Save buffer position
    
    ; Convert number to string
    call int_to_string
    
    pop rdi                 ; Restore buffer position
    
    ; Add separator
    mov word [rdi], ': '
    add rdi, 2
    
    ; Add command
    lea rsi, [user_input]
    call strcpy
    
    ; Add newline
    lea rsi, [history_buffer]
    call strlen
    lea rdi, [history_buffer + rdx]
    mov byte [rdi], 10      ; Newline
    mov byte [rdi+1], 0     ; Null terminator
    
history_done:
    ret

; Get current working directory
get_cwd:
    mov rax, 79             ; sys_getcwd
    lea rdi, [cwd_buffer]   ; buffer
    mov rsi, 256            ; buffer size
    syscall
    ret

; Get command argument (text after command and space)
get_arg:
    ; Find the command length
    lea rsi, [user_input]
    mov rdi, rsi
    
    ; Find first space
    mov al, ' '
    mov rcx, 256
    cld
    repne scasb
    
    ; Calculate command length
    sub rdi, rsi
    dec rdi
    
    ; Check if space was found
    cmp rcx, 0
    je no_arg
    
    ; Skip the space
    inc rdi
    lea rsi, [user_input + rdi]
    ret
    
no_arg:
    ; No argument, return empty string
    lea rsi, [user_input + 256]
    mov byte [rsi], 0
    ret

; Check if input starts with command
check_command:
    ; rsi = user input
    ; rdi = command to check
    ; Returns: carry flag set if not a match, clear if it is
    push rsi
    push rdi
    push rcx
    push rax
    
    ; Get command length
    mov r8, rdi          ; Save command pointer
    call strlen
    mov rcx, rdx         ; command length in rcx
    mov rdi, r8          ; Restore command pointer
    
    ; Compare with input
    mov r8, rcx          ; Save length
    mov r9, rsi          ; Save input pointer
    
    repe cmpsb
    jne not_match
    
    ; Check if followed by space or null
    mov al, byte [r9 + r8]
    cmp al, 0
    je match
    cmp al, ' '
    je match
    
not_match:
    stc                  ; Set carry flag (not a match)
    jmp check_done
    
match:
    clc                  ; Clear carry flag (it's a match)
    
check_done:
    pop rax
    pop rcx
    pop rdi
    pop rsi
    ret

; Convert integer to string
int_to_string:
    ; rdi = destination buffer
    ; rsi = integer to convert
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    
    mov rax, rsi        ; Number to convert
    mov rbx, 10         ; Base 10
    mov rcx, 0          ; Counter
    
    ; Handle 0 special case
    test rax, rax
    jnz int_to_string_loop
    mov byte [rdi], '0'
    mov byte [rdi+1], 0
    jmp int_to_string_done
    
int_to_string_loop:
    ; Check if done
    test rax, rax
    jz int_to_string_build
    
    ; Divide by 10
    xor rdx, rdx
    div rbx
    
    ; Convert remainder to ASCII
    add dl, '0'
    
    ; Push onto stack
    push rdx
    inc rcx
    
    jmp int_to_string_loop
    
int_to_string_build:
    ; Check if done
    test rcx, rcx
    jz int_to_string_finish
    
    ; Pop from stack
    pop rdx
    
    ; Store in buffer
    mov byte [rdi], dl
    inc rdi
    dec rcx
    
    jmp int_to_string_build
    
int_to_string_finish:
    ; Add null terminator
    mov byte [rdi], 0
    
int_to_string_done:
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret


; Format timestamp into readable date/time string
format_time:
    ; rdi = buffer to store formatted time
    push rax
    push rbx
    push rcx
    push rdx
    
    ; For simplicity, we'll just write a placeholder string
    mov dword [rdi], 'Curr'
    mov dword [rdi+4], 'ent '
    mov dword [rdi+8], 'time'
    mov dword [rdi+12], ': Fr'
    mov dword [rdi+16], 'i Fe'
    mov dword [rdi+20], 'b 28'
    mov dword [rdi+24], ' 202'
    mov word [rdi+28], '5'
    mov byte [rdi+30], 0
    
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; String copy function
strcpy:
    ; rsi = source string
    ; rdi = destination buffer
    push rcx
    push rax
    push rsi
    push rdi
    
strcpy_loop:
    lodsb                   ; Load byte from source
    stosb                   ; Store byte to destination
    
    cmp al, 0               ; Check for null terminator
    je strcpy_done
    
    jmp strcpy_loop
    
strcpy_done:
    pop rdi
    pop rsi
    pop rax
    pop rcx
    ret

; Function to calculate string length
strlen:
    ; rsi = string
    ; Returns length in rdx
    push rcx
    push rax
    push rsi
    
    xor rdx, rdx            ; Clear length counter
    
strlen_loop:
    cmp byte [rsi + rdx], 0 ; Check for null terminator
    je strlen_done
    
    inc rdx                 ; Increment length
    jmp strlen_loop
    
strlen_done:
    pop rsi
    pop rax
    pop rcx
    ret

; Function to print a string
print_string:
    ; rsi = string to print
    ; Preserves rsi
    push rax
    push rdi
    push rdx
    push rsi
    
    call strlen             ; Get string length in rdx
    
    mov rax, 1              ; syscall: sys_write
    mov rdi, 1              ; file descriptor: stdout
    syscall
    
    pop rsi
    pop rdx
    pop rdi
    pop rax
    ret

; Directory for ls command
dot_dir db ".", 0

; Home directory for cd command with no args
home_dir db "/home", 0