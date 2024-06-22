.PHONY: clean test

all: bf

bf:
	@echo "Making bf..."
	gcc -x assembler -c src/main.s && ld -o bf main.o

test: bf
	@echo "Starting tests..."
	./test./test.sh

clean:
	rm bf main.o
