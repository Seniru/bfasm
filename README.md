
# bfasm
> Brainfuck interpreter and debugger written in Assembly

### Usage
```bat
Usage: ./bf [options] [--file filename | --code code]
-f, --file filename :	Read the code from the file
-c, --code code :	Program passed in as a string

Options:
-d, --debug :	Start the program in the debugging mode
```

### Features

- Brainfuck interpreter:
  - Interpret Brainfuck code from a file (`--file [filename]` option) or pass the code as an argument (`--code [code]` option)
- Debugger:
  - Enter the debugging mode with the `--debug` option. This debugger is heavily inspired from the GDB's designs. The debugger includes 3 layouts for memory, code and output. Press enter key to step into the next instruction. Scroll support is enabled for memory viewer. 

### About Brainfuck

Brainfuck is an esoteric language consisting with only 8 operators. Brainfuck operates on an array of memory cells, each initially set to zero. (In the original implementation, the array was 30,000 cells long, but this may not be part of the language specification; different sizes for the array length and cell size give different variants of the language). There is a  [pointer](https://esolangs.org/wiki/Pointer "Pointer"), initially pointing to the first memory cell. *(defintion from [esolangs.org](https://esolangs.org/wiki/Brainfuck))*

The commands are: 

|Command|Description|
|--|--|
|`+`|Incrememnt the memory cell at the pointer|
|`-`|Decrement the memory cell at the pointer|
|`>`|Move the pointer to the right|
|`<`|Move the pointer to the left|
|`.`|Output the value (corresponding ASCII value) of the current cell|
|`,`|Input a character and store it's ASCII value in the current cell|
|`[`|Enter if the current cell value is not 0, else skip to the matching `]`|
|`]`|Loop back to the matching `[` if the current cell value is not 0. Exit the loop otherwise|

Check [esolangs.org](https://esolangs.org/wiki/Brainfuck) for more detailed information about Brainfuck

### Why assembly?
There are 2 reasons to choose assembly as the primary developement language for this projrect.
Number one, and the primary reasons is to just flex on people. Both assembly and brainfuck are considered to be some hardcore stuff among many people. That being said, I'm not the smartest person alive. So if there are any issues in these codes, I'd love to humbly listen and learn.

Reason number two is that brainfuck feels very close to assembly. It is just incrementing and decrementing stuff, moving around places, and doing basic I/O.


### Building

This project uses system calls provided by Linux so right now this project only supports Linux platforms.

Tested on Ubuntu 22.04.4 LTS x86_64 

Following tools are required for building
- gcc (this project uses the `as` assembler provided by gcc)
- make
- Additionally, you will require git if you want to clone

Check your distribution's documentation on how to install these.

To make this project follow these steps

```bash
# first clone the repo
git clone https://github.com/Seniru/bfasm
cd bfasm
# then just make
make
```
Run `make test` to run tests

### Contributing
Here are some ways you can contribute to this project

- Writing some tests (add more cool and relevant brainfuck programs  inside the `test` directory)
- Bug fixes
- New features, etc.
