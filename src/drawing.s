.include "defs.s"

.import TileDefinitions, TileColorLookups, PaletteData, BackgroundPatternTable

.struct TileDef
    patternStart    .byte   ; Index into the first CHR table for the tile (ignoring color)
    color           .byte   ; Which color is the tile? (0-4, where 0=>A, 1=>B, etc.)
.endstruct

.segment "ZEROPAGE"

; Used by DrawTile routine
tileDrawX:      .res 1  ; X coordinate in board space where to start drawing tile
tileDrawY:      .res 1  ; Y coordinate in board space where to start drawing tile
tilePower:      .res 1  ; Which number tile to draw (0=>1, 1=>2, 2=>4, 3=>8, etc.)
.export tileDrawX, tileDrawY, tilePower

tileRowCounter: .res 1  ; Counter used for drawing tiles
tileColor:      .res 1  ; Internal variable used for drawing tiles
colorLookup:    .res 1  ; Used in palette mapping
attrIndex:      .res 1  ; Index into attr buffer, used in palette mapping
spriteIndex:    .res 1  ; Next empty index in the SPRITE_BUFFER
spriteX:        .res 1  ; Used in tile sprite drawing
spriteY:        .res 1  ; Used in tile sprite drawing
spriteCHRIndex: .res 1  ; Used in tile sprite drawing

.segment "CODE"

.export WipeBoardBuffer
WipeBoardBuffer:
    ldx #0
    ldy #0
@WipeBoardRow:
    lda BackgroundPatternTable + (BOARD_TOP_Y * 32) + BOARD_LEFT_X, X
    sta BOARD_BUFFER, y
    sta BOARD_BUFFER + 64, y
    sta BOARD_BUFFER + 128, y
    sta BOARD_BUFFER + 192, y
    inx
    iny
    txa
    and #$0F
    bne @WipeBoardRow
    txa
    clc
    adc #16
    bcs :+
    tax
    jmp @WipeBoardRow
:
    ldx #0
    lda #0
:
    sta COLOR_BUFFER, X
    inx
    bne :-
    rts

.export WipeSpriteBuffer
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
.export DrawTile
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
    tay
    lda TileDefinitions+TileDef::color, Y
    sta tileColor
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
    sta BOARD_BUFFER, X
    lda tileColor
    sta COLOR_BUFFER, X
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
    lda tileColor
    sta COLOR_BUFFER, X
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
    lda tileColor
    sta COLOR_BUFFER, X
@Col3Done:
    iny
    inx
    lda tileDrawX
    cmp #13         ; Is this column outside the board?
    bpl TileRowDone
    tya
    sta BOARD_BUFFER, x
    lda tileColor
    sta COLOR_BUFFER, X
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

; If there are any existing sprites under this tile, drop them off the screen
    ldx #0
@CheckNextSprite:
    lda SPRITE_BUFFER, X
    cmp #$FF
    beq @SpriteNoCollision
    lda tileDrawY
    clc
    adc #BOARD_TOP_Y
    asl
    asl
    asl
    sec
    sbc #1
    cmp SPRITE_BUFFER, X
    beq @CheckSpriteX
    clc
    adc #8
    cmp SPRITE_BUFFER, X
    beq @CheckSpriteX
    clc
    adc #8
    cmp SPRITE_BUFFER, X
    beq @CheckSpriteX
    clc
    adc #8
    cmp SPRITE_BUFFER, X
    beq @CheckSpriteX
    jmp @SpriteNoCollision
@CheckSpriteX:
    inx     ; Go to sprite X coord byte
    inx
    inx
    lda tileDrawX
    clc
    adc #BOARD_LEFT_X
    asl
    asl
    asl
    cmp SPRITE_BUFFER, X
    beq @SpriteCollision
    clc
    adc #8
    cmp SPRITE_BUFFER, X
    beq @SpriteCollision
    clc
    adc #8
    cmp SPRITE_BUFFER, X
    beq @SpriteCollision
    clc
    adc #8
    cmp SPRITE_BUFFER, X
    beq @SpriteCollision
    jmp @SpriteNoCollision
@SpriteCollision:
    dex
    dex
    dex
    lda #$FF
    sta SPRITE_BUFFER, X
@SpriteNoCollision:
    txa
    and #%11111100  ; Make sure we're at first byte of sprite (Y-pos)
    tax
    inx             ; Increment to next sprite
    inx
    inx
    inx
    bne @CheckNextSprite

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

    jsr SetUpTileSpriteVars

TileSpriteTopLeft:
    ; Do we draw this corner?
    lda tileDrawY
    cmp #$FF
    bmi :+
    lda tileDrawX
    cmp #$FF
    bmi TileSpriteTopRight
    jsr WriteTileSpriteBytes
    jmp TileSpriteTopRight
:
    inc spriteCHRIndex
    jmp TileSpriteBottomLeft

TileSpriteTopRight:
    ; Increment indices
    inc spriteCHRIndex
    ; Do we draw this corner?
    lda tileDrawX
    cmp #14
    bpl TileSpriteBottomLeft
    lda spriteX
    clc
    adc #8
    sta spriteX
    jsr WriteTileSpriteBytes
    ; Reset X coord
    lda spriteX
    sec
    sbc #8
    sta spriteX

TileSpriteBottomLeft:
    ; Increment indices
    lda spriteCHRIndex
    clc
    adc #$0F
    sta spriteCHRIndex
    lda spriteY
    clc
    adc #8
    sta spriteY
    ; Do we draw this corner?
    lda tileDrawY
    cmp #14
    bpl TileSpriteDone
    lda tileDrawX
    cmp #$FF
    bmi TileSpriteBottomRight
    jsr WriteTileSpriteBytes

TileSpriteBottomRight:
    ; Increment indices
    inc spriteCHRIndex
    lda spriteX
    clc
    adc #8
    sta spriteX
    ; Do we draw this corner?
    lda tileDrawX
    cmp #14
    bpl TileSpriteDone
    jsr WriteTileSpriteBytes

TileSpriteDone:
    rts

SetUpTileSpriteVars:
    ; Y coord
    lda tileDrawY
    clc
    adc #BOARD_TOP_Y
    asl A       ; Multiply by 8 scanlines
    asl A
    asl A
    clc         ; Add padding inside the tile (PPU draws sprite on next line, so 8 - 1 => 7)
    adc #7
    sta spriteY
    ; X coord
    lda tileDrawX
    clc
    adc #BOARD_LEFT_X
    asl A
    asl A
    asl A
    clc
    adc #8
    sta spriteX
    ; CHR Index
    lda tilePower
    asl A
    cmp #$10
    bmi :+
    clc
    adc #$10
:
    sta spriteCHRIndex
    rts

WriteTileSpriteBytes:
    ; First byte - Y pos
    ldx spriteIndex
    lda spriteY
    sta SPRITE_BUFFER, X
    inx
    ; Second byte - CHR index
    lda spriteCHRIndex
    sta SPRITE_BUFFER, X
    inx
    ; Third byte - attributes
    lda tileColor
    bne :+
    lda #$01    ; Second sprite palette
    jmp @StoreThirdByte
:
    lda #$00
@StoreThirdByte:
    sta SPRITE_BUFFER, X
    inx
    ; Fourth byte - X pos
    lda spriteX
    sta SPRITE_BUFFER, X
    inx
    ; Increment sprite index
    stx spriteIndex
    rts

.export PaintAttributeBuffer
PaintAttributeBuffer:
    ldx #$00
    stx attrIndex
BeginPaintQuadrant:
    ; top left
    lda COLOR_BUFFER, X
    asl A
    asl A
    tay
    txa
    clc
    adc #$11
    tax
    tya
    ora COLOR_BUFFER, X
    tay
    txa
    sec
    sbc #$0F
    tax
    lda TileColorLookups, Y
    sta colorLookup
    and #$30
    lsr A
    lsr A
    lsr A
    lsr A
    ldy attrIndex
    ora ATTR_BUFFER, Y
    sta ATTR_BUFFER, Y
    jsr IncrementBoardBufferColors
    ; top right
    lda COLOR_BUFFER, X
    asl A
    asl A
    tay
    txa
    clc
    adc #$11
    tax
    tya
    ora COLOR_BUFFER, X
    tay
    txa
    sec
    sbc #$0F
    tax
    lda TileColorLookups, Y
    sta colorLookup
    and #$30
    lsr A
    lsr A
    ldy attrIndex
    ora ATTR_BUFFER, Y
    sta ATTR_BUFFER, Y
    jsr IncrementBoardBufferColors
    ; bottom left
    txa
    clc
    adc #$1C
    tax
    lda COLOR_BUFFER, X
    asl A
    asl A
    tay
    txa
    clc
    adc #$11
    tax
    tya
    ora COLOR_BUFFER, X
    tay
    txa
    sec
    sbc #$0F
    tax
    lda TileColorLookups, Y
    sta colorLookup
    and #$30
    ldy attrIndex
    ora ATTR_BUFFER, Y
    sta ATTR_BUFFER, Y
    jsr IncrementBoardBufferColors
    ; bottom right
    lda COLOR_BUFFER, X
    asl A
    asl A
    tay
    txa
    clc
    adc #$11
    tax
    tya
    ora COLOR_BUFFER, X
    tay
    txa
    sec
    sbc #$0F
    tax
    lda TileColorLookups, Y
    sta colorLookup
    and #$30
    asl A
    asl A
    ldy attrIndex
    ora ATTR_BUFFER, Y
    sta ATTR_BUFFER, Y
    jsr IncrementBoardBufferColors

    inc attrIndex
    txa
    sec
    sbc #$20
    tax

    ;Check if we're done
    lda attrIndex
    cmp #$10
    bpl DonePaletteMap
    ; Check if we need to move to next row
    and #$03
    cmp #$00
    bne :+
    txa
    clc
    adc #$30
    tax
:
    jmp BeginPaintQuadrant

DonePaletteMap:
    rts

COLOR_BUMP_INCREMENT = $50  ; $10 is one row in the CHR table

IncrementBoardBufferColors:
    ; Stash X and Y
    txa
    pha
    tya
    pha
    ; X to top-left corner
    dex
    dex
    ; Get CHR increment factor
    lda colorLookup
    beq @Done
    and #$02
    bne :+
    inx
    jmp @TopRight
:
    ; Add to existing CHR index
    lda BOARD_BUFFER, X
    clc
    adc #COLOR_BUMP_INCREMENT
    sta BOARD_BUFFER, X
    ; Move down a row in the board buffer
    txa
    clc
    adc #$10
    tax
    ; Add to this CHR index, too
    lda BOARD_BUFFER, X
    clc
    adc #COLOR_BUMP_INCREMENT
    sta BOARD_BUFFER, X
    ; Move X to top-right corner
    txa
    sec
    sbc #$0F
    tax
@TopRight:
    ; Get CHR increment factor
    lda colorLookup
    and #$01
    bne :+
    jmp @Done
:
    ; Add to existing CHR index
    lda BOARD_BUFFER, X
    clc
    adc #COLOR_BUMP_INCREMENT
    sta BOARD_BUFFER, X
    ; Move down a row in the board buffer
    txa
    clc
    adc #$10
    tax
    ; Add to this CHR index, too
    lda BOARD_BUFFER, X
    clc
    adc #COLOR_BUMP_INCREMENT
    sta BOARD_BUFFER, X
@Done:
    ; Restore Y and X
    pla
    tay
    pla
    tax
    ; Return
    rts
