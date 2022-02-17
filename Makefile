default: 2048.nes

.PHONY: run
run: 2048.nes
	fceux 2048.nes

OBJS := 2048.o \
		blit.o \
		drawing.o \
		header.o \
		nmi.o \
		startup.o \
		tests.o \
		tile-lookups.o \

2048.nes: $(addprefix obj/,$(OBJS))
	ld65 -o $@ $^ -t nes --dbgfile 2048.nes.db

obj/%.o: src/%.s
	@mkdir -p obj
	ca65 -o $@ $< --debug-info
obj/2048.o: data/2048.chr data/board-background.nam

.PHONY: clean
clean:
	-rm -rf obj 2048.nes 2048.nes.db
