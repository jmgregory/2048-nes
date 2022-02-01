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

SPRITE_BUFFER = $0200   ; Staging area for sprite data
BOARD_BUFFER = $0300    ; Staging area for main board nametable
BOARD_LEFT_X = 8        ; X coordinate of board left edge in nametable space
BOARD_TOP_Y = 7         ; Y coordinate of board top edge in nametable space

.struct TileDef
    spriteStart     .byte   ; Index into second CHR table
    spriteWidth     .byte   ; How many sprites wide is the number part? (1 or 2)
    patternStart    .byte   ; Index into the first CHR table for the tile (ignoring color)
    color           .byte   ; Which color is the tile? (0-4, where 0=>A, 1=>B, etc.)
.endstruct

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
blitMode:       .res 1  ; 0 = no blit, 1 = horizontal, 2 = vertical
blitCounter:    .res 1  ; Which row/col are we blitting?
blitStartPPU:   .res 2  ; Counter address used in blitting to PPU

; Used by DrawTile routine
tileDrawX:      .res 1  ; X coordinate in board space where to start drawing tile
tileDrawY:      .res 1  ; Y coordinate in board space where to start drawing tile
tilePower:      .res 1  ; Which number tile to draw (0=>1, 1=>2, 2=>4, 3=>8, etc.)
tileRowCounter: .res 1  ; Counter used for drawing tiles
spriteStart:    .res 1  ; Index in CHR table of the tile's number sprites
spriteIndex:    .res 1  ; Next empty index in the SPRITE_BUFFER

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
    lda #$FF    ; Board stage and sprites (0x200-0x3FF) get 0xFF
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

; Gotta write the background attribute table, too
; PPU_ADDR is already at the beginning of the attribute table after the code
; above, so can just keep going from where we left off
    ; Set PPU address to 0x3F00 (palettes)
    bit PPU_STATUS  ; clear PPU address latch
    lda #$23
    sta PPU_ADDR
    lda #$C0
    sta PPU_ADDR
    ldx #$00
    lda #$00 ; Just use the same palette on all tiles
LoadAttributes:
    sta PPU_DATA
    inx
    cpx #$40
    bne LoadAttributes

    ; jsr TestDrawTileShapes
    jsr TestDrawEdgeTiles

; Set blit mode
    lda #1
    sta blitMode

; Enable interrupts
    cli
    ; enable NMI, use second CHAR tile set for backgrounds, use 8x16 sprites
    lda #%10101000
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

WipeSpriteBuffer:
    ldx $00
    stx spriteIndex
    lda $FF     ; Last tile is empty
:
    sta SPRITE_BUFFER, x
    inx
    bne :-
    rts

; Draws a tile on BOARD_BUFFER
; tileDrawX and tileDrawY specify coordinates where to place the tile's top-left corner
; tilePower indicates which tile to draw (0=>1, 1=>2, 2=>4, etc.)
DrawTile:
    lda tileDrawY
    asl A
    asl A
    asl A
    asl A
    clc
    adc tileDrawX
    tax             ; X now has starting index in BOARD_BUFFER
    lda tilePower
    asl A
    asl A
    tay
    lda TileDefinitions+TileDef::patternStart, Y
    tay             ; Y now has starting index in CHR
    lda #0
    sta tileRowCounter
DrawTileRow:
    ; Is this row too high (outside the board?)
    lda tileDrawY
    clc
    adc tileRowCounter
    cmp #$FC
    bcc :+
    iny     ; Increment indices as if we drew the row
    iny
    inx
    inx
    inx
    jmp TileRowDone
:
    lda tileDrawX   ; Is this column outside the board?
    cmp #$FD
    bcs @Col1Done
    tya
    sta BOARD_BUFFER, x
@Col1Done:
    iny
    inx
    lda tileDrawX   ; Is this column outside the board?
    cmp #$FF
    bcs :+
    cmp #15
    bcs @Col2Done
:
    tya
    sta BOARD_BUFFER, x
@Col2Done:
    inx
    lda tileDrawX   ; Is this column outside the board?
    cmp #$FE
    bcs :+
    cmp #14
    bcs @Col3Done
:
    tya
    sta BOARD_BUFFER, x
@Col3Done:
    iny
    inx
    lda tileDrawX
    cmp #13         ; Is this column outside the board?
    bpl TileRowDone
    tya
    sta BOARD_BUFFER, x
TileRowDone:
    lda tileDrawY
    clc
    adc tileRowCounter
    cmp #15
    bne :+
    jmp TileBGDone
:
    inc tileRowCounter
    lda tileRowCounter
    cmp #4
    bne :+
    jmp TileBGDone     ; When tileRowCounter is 4, we're done with the backgrounds
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
TileBGDone:
; Do we even need to draw the sprite?
    lda tileDrawX
    cmp #15
    bpl TileSpriteDone
    cmp #$FE
    bmi TileSpriteDone
    lda tileDrawY
    cmp #15
    bpl TileSpriteDone
    cmp #$FE
    bmi TileSpriteDone
; Left half of sprite
    ; First byte - Y pos
    lda tileDrawY
    clc
    adc #BOARD_TOP_Y
    asl A
    asl A
    asl A
    clc
    adc #7
    ldx spriteIndex
    sta SPRITE_BUFFER, X
    pha     ; store for later
    inx
    ; Second byte - CHR index
    lda tilePower
    asl A
    asl A
    clc
    adc #$40
    ora #$01    ; Make sure using second table for tall sprites
    sta SPRITE_BUFFER, X
    pha     ; store for later
    inx
    ; Third byte - attributes
    lda #$00
    sta SPRITE_BUFFER, X
    inx
    ; Fourth byte - X pos
    lda tileDrawX
    clc
    adc #BOARD_LEFT_X
    asl A
    asl A
    asl A
    clc
    adc #8
    sta SPRITE_BUFFER, X
    pha

; Increment sprite index
    lda spriteIndex
    clc
    adc #4
    sta spriteIndex

; Right half of sprite
    ; Do these in reverse order since we're popping off the stack
    txa
    clc
    adc #4
    tax
    ; Fourth byte - X pos
    pla
    clc
    adc #8
    sta SPRITE_BUFFER, X
    dex
    ; Third byte - attributes
    lda #0
    sta SPRITE_BUFFER, X
    dex
    ; Second byte - CHR index
    pla
    clc
    adc #2
    sta SPRITE_BUFFER, X
    dex
    ; First byte - Y pos
    pla
    sta SPRITE_BUFFER, X

; Increment sprite index
    lda spriteIndex
    clc
    adc #4
    sta spriteIndex

TileSpriteDone:
    rts

Blit16:
    lda BOARD_BUFFER, X
    sta PPU_DATA
    inx
    lda BOARD_BUFFER, X
    sta PPU_DATA
    inx
    lda BOARD_BUFFER, X
    sta PPU_DATA
    inx
    lda BOARD_BUFFER, X
    sta PPU_DATA
    inx
    lda BOARD_BUFFER, X
    sta PPU_DATA
    inx
    lda BOARD_BUFFER, X
    sta PPU_DATA
    inx
    lda BOARD_BUFFER, X
    sta PPU_DATA
    inx
    lda BOARD_BUFFER, X
    sta PPU_DATA
    inx
    lda BOARD_BUFFER, X
    sta PPU_DATA
    inx
    lda BOARD_BUFFER, X
    sta PPU_DATA
    inx
    lda BOARD_BUFFER, X
    sta PPU_DATA
    inx
    lda BOARD_BUFFER, X
    sta PPU_DATA
    inx
    lda BOARD_BUFFER, X
    sta PPU_DATA
    inx
    lda BOARD_BUFFER, X
    sta PPU_DATA
    inx
    lda BOARD_BUFFER, X
    sta PPU_DATA
    inx
    lda BOARD_BUFFER, X
    sta PPU_DATA
    inx
    rts

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

    lda blitMode
    cmp #1
    beq BlitHorizontal
    cmp #2
    beq BlitVertical
    jmp DoneBlitting

BlitVertical:
    jmp DoneBlitting

BlitHorizontal:
    lda blitCounter
    and #$03
    asl A
    asl A
    clc
    adc #BOARD_TOP_Y
    tax
    lsr A
    lsr A
    lsr A
    clc
    adc #$20
    tay         ; Y is high byte of PPU write address
    txa
    asl A
    asl A
    asl A
    asl A
    asl A
    clc
    adc #BOARD_LEFT_X
    sta blitStartPPU
    sty blitStartPPU+1

    lda blitCounter
    and #$03
    asl A
    asl A
    asl A
    asl A
    asl A
    asl A
    tax     ; X is index into BOARD_BUFFER

    ; write first row
    bit PPU_STATUS
    lda blitStartPPU + 1
    sta PPU_ADDR
    lda blitStartPPU
    sta PPU_ADDR
    jsr Blit16

    ; write second row
    lda blitStartPPU
    clc
    adc #32
    sta blitStartPPU
    bcc :+
    inc blitStartPPU + 1
:
    bit PPU_STATUS
    lda blitStartPPU + 1
    sta PPU_ADDR
    lda blitStartPPU
    sta PPU_ADDR
    jsr Blit16

    ; write third row
    lda blitStartPPU
    clc
    adc #32
    sta blitStartPPU
    bcc :+
    inc blitStartPPU + 1
:
    bit PPU_STATUS
    lda blitStartPPU + 1
    sta PPU_ADDR
    lda blitStartPPU
    sta PPU_ADDR
    jsr Blit16

    ; write fourth row
    lda blitStartPPU
    clc
    adc #32
    sta blitStartPPU
    bcc :+
    inc blitStartPPU + 1
:
    bit PPU_STATUS
    lda blitStartPPU + 1
    sta PPU_ADDR
    lda blitStartPPU
    sta PPU_ADDR
    jsr Blit16

    inc blitCounter
    ; jmp DoneBlitting

DoneBlitting:

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
    .byte CLR_BG, CLR_WHITE, CLR_GRAY, CLR_BLACK
    .byte CLR_BG, CLR_WHITE, CLR_GRAY, CLR_BLACK
    .byte CLR_BG, CLR_WHITE, CLR_GRAY, CLR_BLACK
    .byte CLR_BG, CLR_WHITE, CLR_GRAY, CLR_BLACK

TileDefinitions:
    ; sprite-index, sprite-width, tile-start, color
    .byte   0, 1,  0, 0     ; 1
    .byte   1, 1,  0, 0     ; 2
    .byte   2, 1,  0, 0     ; 4
    .byte   3, 1,  0, 0     ; 8
    .byte   4, 2, 16, 0     ; 16
    .byte   6, 2, 16, 0     ; 32
    .byte   8, 2, 16, 0     ; 64
    .byte  10, 2, 16, 0     ; 128
    .byte  12, 2, 48, 0     ; 256
    .byte  14, 2, 48, 0     ; 512
    .byte  32, 2, 48, 0     ; 1024
    .byte  34, 2, 48, 0     ; 2048
    .byte  36, 2, 32, 0     ; 4096
    .byte  38, 2, 32, 0     ; 8192

TestDrawTileShapes:
    lda #$00
    sta tilePower
    sta tileDrawX
    sta tileDrawY
    jsr DrawTile
@NextTile:
    lda tileDrawX
    clc
    adc #$04
    cmp #$10
    bcc :+
    lda tileDrawY
    clc
    adc #$04
    sta tileDrawY
    lda #$00
:
    sta tileDrawX
    lda tilePower
    clc
    adc #$01
    sta tilePower
    jsr DrawTile
    lda tilePower
    cmp #13
    bne @NextTile
    rts

TestDrawEdgeTiles:
    lda #1
    sta tilePower
    lda #0
    sta tileDrawX
    lda #$FD
    sta tileDrawY
    jsr DrawTile

    lda #4
    sta tileDrawX
    lda #$FE
    sta tileDrawY
    jsr DrawTile

    lda #8
    sta tileDrawX
    lda #$FF
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

    lda #12
    sta tileDrawX
    lda #15
    sta tileDrawY
    jsr DrawTile

    lda #8
    sta tileDrawX
    lda #14
    sta tileDrawY
    jsr DrawTile

    lda #4
    sta tileDrawX
    lda #13
    sta tileDrawY
    jsr DrawTile

    lda #$FD
    sta tileDrawX
    lda #12
    sta tileDrawY
    jsr DrawTile

    lda #$FE
    sta tileDrawX
    lda #8
    sta tileDrawY
    jsr DrawTile

    lda #$FF
    sta tileDrawX
    lda #4
    sta tileDrawY
    jsr DrawTile

    rts

.segment "VECTORS"
.word nmi
.word start

.segment "OAM"

.segment "CHARS"
.incbin "2048.chr"
