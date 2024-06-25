
# bfasm
> Brainfuck interpreter written in Assembly

### Usage
```bat
Usage: ./bf [--file filename | --code code]
Options:
-f, --file filename :   Read the code from the file
-c, --code code :       Program passed in as a string
```

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
