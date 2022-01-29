; definitions
PPU_CTRL      = $2000
PPU_MASK      = $2001
PPU_STATUS    = $2002
PPU_SCROLL    = $2005
PPU_ADDR      = $2006
PPU_DATA      = $2007
OAM_ADDRESS   = $2003
OAM_DMA       = $4014
APU_DMC       = $4010
APU_STATUS    = $4015
APU_FRAME_CTR = $4017

BOARD_BUFFER = $0300    ; Staging area for main board nametable

.segment "HEADER"
; iNES header
; see http://wiki.nesdev.com/w/index.php/INES
.byte $4e, $45, $53, $1a ; "NES" followed by MS-DOS EOF
.byte $02                ; size of PRG ROM in 16 KiB units
.byte $01                ; size of CHR ROM in 8 KiB units
.byte $00                ; horizontal mirroring, mapper 000 (NROM)
.byte $00                ; mapper 000 (NROM)
.byte $00                ; size of PRG RAM in 8 KiB units
.byte $00                ; NTSC
.byte $00                ; unused
.res 5, $00              ; zero-filled

.segment "ZEROPAGE"
blitMode: .res 1        ; 0 = no blit, 1 = horizontal, 2 = vertical
tileDrawX: .res 1       ; X coordinate in board space where to start drawing tile
tileDrawY: .res 1       ; Y coordinate in board space where to start drawing tile
tileStart: .res 1       ; Index in CHR table of which tile to draw
tileRowCounter: .res 1  ; Counter used for drawing tile

.segment "STARTUP"

start:
    sei  ; ignore IRQ
    cld  ; disable decimal mode
    
    ; Disable APU interrupts
    ldx #$40
    stx APU_FRAME_CTR
    ldx #$00
    stx APU_DMC

    ; setup stack at 0xFF
    ldx #$FF
    txs

    ; Turn off PPU
    inx ; X => 0
    stx PPU_CTRL
    stx PPU_MASK

; Wait for a VBLANK
:
    bit $2002
    bpl :-

; Zero out RAM from 0x0000 - 0x07FF
    txa     ; A == 0
ClearMem:
    sta $00, x
    sta $100, x
    lda #$FF    ; Board stage and sprites (0x200-0x2FF) get 0xFF
    sta $200, x
    sta $300, x
    lda #$00
    sta $400, x
    sta $500, x
    sta $600, x
    sta $700, x
    inx
    bne ClearMem    ; branches when X != 0

; Wait for another VBLANK
:
    bit $2002
    bpl :-

; Set OAM DMA start address to 0x200
    lda #$02
    sta OAM_DMA
    nop

; Set up palettes in PPU
    ; Set PPU address to 0x3F00 (palettes)
    bit PPU_STATUS  ; clear PPU address latch
    lda #$3F
    sta PPU_ADDR
    lda #$00
    sta PPU_ADDR
    ldx #$00
LoadPalettes:
    lda PaletteData, X
    sta PPU_DATA
    inx
    cpx #$20
    bne LoadPalettes

; Draw some tiles
    lda #0
    sta tileStart
    sta tileDrawX
    sta tileDrawY
    jsr DrawTile

    lda #15
    sta tileDrawX
    lda #0
    sta tileDrawY
    jsr DrawTile

    lda #14
    sta tileDrawX
    lda #4
    sta tileDrawY
    jsr DrawTile

    lda #13
    sta tileDrawX
    lda #8
    sta tileDrawY
    jsr DrawTile

    lda #0
    sta tileDrawX
    lda #15
    sta tileDrawY
    jsr DrawTile

    lda #4
    sta tileDrawX
    lda #14
    sta tileDrawY
    jsr DrawTile

    lda #8
    sta tileDrawX
    lda #13
    sta tileDrawY
    jsr DrawTile

; Gotta write the background attribute table, too
; PPU_ADDR is already at the beginning of the attribute table after the code
; above, so can just keep going from where we left off
    ldx #$00
    lda #$00 ; Just use the same palette on all tiles
LoadAttributes:
    sta PPU_DATA
    inx
    cpx #$40
    bne LoadAttributes

; Set up our sprites in RAM
    ldx #$00
LoadSprites:
    lda SpriteData, X
    sta $200, X
    inx
    cpx #$20
    bne LoadSprites

; Enable interrupts
    cli
    ; enable NMI, use second CHAR tile set for backgrounds
    lda #%10010000
    sta PPU_CTRL
    ; Enable sprites and background
    lda #%00011110
    sta PPU_MASK

.segment "CODE"

Loop:
    jmp Loop

WipeBoardBuffer:
    ldx $00
    lda $FF     ; Last tile is empty
:
    sta BOARD_BUFFER, x
    inx
    bne :-
    rts

; Draws a tile on BOARD_BUFFER
; tileDrawX and tileDrawY specify coordinates where to place the tile's top-left corner
; tileStart is an index in the CHR table where the desired tile begins
DrawTile:
    lda tileDrawY
    asl A
    asl A
    asl A
    asl A
    clc
    adc tileDrawX
    tax             ; X now has starting index in BOARD_BUFFER
    ldy tileStart
    lda #0
    sta tileRowCounter
DrawTileRow:
    tya
    sta BOARD_BUFFER, x
    iny
    inx
    lda tileDrawX   ; Is this the last column?
    cmp #15
    bne :+
    iny
    inx
    inx
    jmp TileRowDone
:
    tya
    sta BOARD_BUFFER, x
    inx
    lda tileDrawX
    cmp #14         ; Is this the next-to-last column?
    bne :+
    iny
    inx
    jmp TileRowDone
:
    tya
    sta BOARD_BUFFER, x
    iny
    inx
    lda tileDrawX
    cmp #13         ; Is this the next-next-to-last column?
    bne :+
    jmp TileRowDone
:
    tya
    sta BOARD_BUFFER, x
TileRowDone:
    lda tileDrawY
    clc
    adc tileRowCounter
    cmp #15
    bne :+
    rts
:
    inc tileRowCounter
    lda tileRowCounter
    cmp #4
    bne :+
    rts     ; When tileRowCounter is 4, we're done
:
    cmp #2
    bne :+
    dey
    dey
    dey
:
    iny
    ; Increment X by 13 to draw on the next row
    txa
    clc
    adc #13
    tax
    jmp DrawTileRow

nmi:
; Save CPU state
    pha
    txa
    pha
    tya
    pha

; Sprite load
    ; Tell PPU to DMA copy sprite data from 0x0200
    lda #$02
    sta OAM_DMA
    nop

; Reset PPU scroll to avoid trouble
    lda #$00
    sta $2005
    sta $2005

; Restore CPU state
    pla
    tay
    pla
    tax
    pla

; NMI done
    rti

CLR_BG = $20 ; Background color
CLR_TA = $35 ; First tile color
CLR_TB = $21 ; Second tile color
CLR_TC = $11 ; Third tile color
CLR_TD = $25 ; Fourth tile color
CLR_TE = $15 ; Fifth tile color
CLR_WHITE = $30
CLR_GRAY = $2D
CLR_BLACK = $1D

PaletteData:
    ; Backgrounds
    ; Intent here is for every pair of colors to be available on at least one
    ; palette
    .byte CLR_BG, CLR_TA, CLR_TB, CLR_TC
    .byte CLR_BG, CLR_TA, CLR_TB, CLR_TD
    .byte CLR_BG, CLR_TA, CLR_TB, CLR_TE
    .byte CLR_BG, CLR_TC, CLR_TD, CLR_TE
    ; Sprites
    .byte CLR_BG, CLR_GRAY, CLR_WHITE, CLR_BLACK
    .byte CLR_BG, CLR_GRAY, CLR_WHITE, CLR_BLACK
    .byte CLR_BG, CLR_GRAY, CLR_WHITE, CLR_BLACK
    .byte CLR_BG, CLR_GRAY, CLR_WHITE, CLR_BLACK

SpriteData:
  .byte $08, $00, $00, $08
  .byte $08, $01, $00, $10
  .byte $10, $02, $00, $08
  .byte $10, $03, $00, $10
  .byte $18, $04, $00, $08
  .byte $18, $05, $00, $10
  .byte $20, $06, $00, $08
  .byte $20, $07, $00, $10

.segment "VECTORS"
.word nmi
.word start

.segment "OAM"

.segment "CHARS"
.incbin "2048.chr"
