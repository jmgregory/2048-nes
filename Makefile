default: 2048.nes

.PHONY: run
run: 2048.nes
	fceux 2048.nes

2048.nes: 2048.o
	ld65 -o 2048.nes 2048.o -t nes --dbgfile 2048.nes.db

2048.o: 2048.s 2048.chr
	ca65 -o 2048.o 2048.s --debug-info

.PHONY: clean
clean:
	-rm -f 2048.o 2048.nes 2048.nes.db
