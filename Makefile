all: bf

bf:
	gcc -x assembler -c bf.s && ld -o bf bf.o

clean:
	rm bf bf.o
