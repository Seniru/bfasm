all: bf

bf:
	gcc -x assembler -c src/main.s && ld -o bf main.o

clean:
	rm bf main.o
