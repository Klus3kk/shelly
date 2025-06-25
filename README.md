# Shelly

**Shelly** is a minimalistic shell built in NASM assembly language. It provides basic command-line functionality, allowing users to interact with commands like `echo` and `exit`. The shell loops through user input, echoing back text and responding to basic commands.

## Key Features

- Basic commands (`echo`, `exit`)
- Customizable prompts with symbols and colors
- Written in pure NASM assembly for a low-level system experience

## Commands

### `echo <text>`
- **Description**: Prints the specified text to the console.
- **Usage**: `echo hello` will display `hello`.

### `exit`
- **Description**: Exits the shell and displays the exit message.
- **Usage**: Simply type `exit` to leave the shell.

### `shcg <new_prompt>`
- **Description**: Changes the current prompt to a new value specified by the user.
- **Usage**: `shcg myprompt` will change the prompt to `myprompt>`.

### `shcolor <number>`
- **Description**: Changes the color of the shell prompt. Valid color numbers:
  - `1`: Red
  - `2`: Green
  - `3`: Yellow
  - `4`: Blue
- **Usage**: `shcolor 3` will change the prompt color to yellow.
- **Help**: Typing `shcolor` without an argument will display usage information.

## Getting Started
1. Assemble the code using NASM: `nasm -f elf64 shelly.asm`
2. Link the object file: `ld -o shelly shelly.o`
3. Run the shell: `./shelly`
