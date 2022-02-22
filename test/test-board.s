.include "../src/defs.s"
.include "helpers.s"

.import FindTileRow, GetTilePosOnNonSlideAxis, GetTilePosOnSlideAxis
.importzp tileRow, tiles, slideDir, tileIndex1, tileIndex2, tileIndex3, tileIndex4

.segment "STARTUP"
.export _main
_main:
    setTestFileName "test-board.s"
    jsr WipeTiles
    jsr TestWipeTiles
    jsr TestGetTilePosOnNonSlideAxis
    jsr TestGetTilePosOnSlideAxis
    jsr TestFindTilesEmpty
    jsr TestFindTilesSingle
    jsr TestFindTilesMultiple
    jsr TestFindTilesOrderReversed
    jsr TestFindTilesIgnoreIntermediatePositions
    printf "All tests in '%s' passed!", #testFileName
    lda #0
    jmp exit

.segment "CODE"
WipeTiles:
    lda #$FF
    ldx #0
:
    stx tempX
    sta tiles, X
    inx
    cpx #(17 * .sizeof(Tile))
    bne :-
    rts

TestWipeTiles:
    setTestName TestWipeTiles
    jsr WipeTiles
    ldx #0
NextTile:
    lda tiles, X
    expectA #$FF, "tiles+X"
    inx
    cpx #(17 * .sizeof(Tile))
    beq :+
    jmp NextTile
:
    rts

TestFindTilesEmpty:
    setTestName TestFindTilesEmpty
    jsr WipeTiles
    lda #0
    sta tileRow
    lda #DIR_LEFT
    sta slideDir
    jsr FindTileRow
    ldy #0
    lda tileIndex1, y
    expectA #$FF, "tileIndex1"
    lda tileIndex2, y
    expectA #$FF, "tileIndex2"
    lda tileIndex3, y
    expectA #$FF, "tileIndex3"
    lda tileIndex4, y
    expectA #$FF, "tileIndex4"
    rts

TestFindTilesSingle:
    setTestName TestFindTiles
    jsr WipeTiles
    lda #0
    sta tiles+Tile::xpos
    sta tiles+Tile::ypos
    sta tiles+Tile::power
    sta tileRow
    lda #DIR_LEFT
    sta slideDir
    jsr FindTileRow

    lda tileIndex1
    expectA #0, "tileIndex1"
    lda tileIndex2
    expectA #$FF, "tileIndex2"
    lda tileIndex3
    expectA #$FF, "tileIndex3"
    lda tileIndex4
    expectA #$FF, "tileIndex4"

    ldx tileIndex1
    lda tiles+Tile::xpos, x
    expectA #0, "tiles[tileIndex1].x"
    lda tiles+Tile::ypos, x
    expectA #0, "tiles[tileIndex1].y"
    lda tiles+Tile::power, x
    expectA #0, "tiles[tileIndex1].power"

    rts

.macro setTile slot, xp, yp, pow
    lda #0
    ldx slot
:
    cpx #0
    beq :+
    dex
    clc
    adc #.sizeof(Tile)
    jmp :-
:
    tax
    lda xp
    sta tiles+Tile::xpos, x
    lda yp
    sta tiles+Tile::ypos, x
    lda pow
    sta tiles+Tile::power, x
.endmacro

TestFindTilesMultiple:
    setTestName TestFindTiles
    jsr WipeTiles
    setTile  #9, #12, #0, #0
    setTile #13, #12, #8, #1
    setTile  #2,  #4, #0, #3
    lda #3  ; => xpos == 12
    sta tileRow
    lda #DIR_UP
    sta slideDir
    jsr FindTileRow

    lda tileIndex1
    expectA #(9*.sizeof(Tile)), "tileIndex1"
    lda tileIndex2
    expectA #$FF, "tileIndex2"
    lda tileIndex3
    expectA #(13*.sizeof(Tile)), "tileIndex3"
    lda tileIndex4
    expectA #$FF, "tileIndex4"

    ldx tileIndex1
    lda tiles+Tile::xpos, x
    expectA #12, "tiles[tileIndex1].x"
    lda tiles+Tile::ypos, x
    expectA #0, "tiles[tileIndex1].y"
    lda tiles+Tile::power, x
    expectA #0, "tiles[tileIndex1].power"

    ldx tileIndex3
    lda tiles+Tile::xpos, x
    expectA #12, "tiles[tileIndex1].x"
    lda tiles+Tile::ypos, x
    expectA #8, "tiles[tileIndex1].y"
    lda tiles+Tile::power, x
    expectA #1, "tiles[tileIndex1].power"

    rts

TestFindTilesOrderReversed:
    setTestName TestFindTilesOrderReversed
    jsr WipeTiles
    setTile  #9, #12, #0, #0
    setTile #13, #12, #8, #1
    setTile  #2,  #4, #0, #3
    lda #3  ; => xpos == 12
    sta tileRow
    lda #DIR_DOWN
    sta slideDir
    jsr FindTileRow

    lda tileIndex4
    expectA #(9*.sizeof(Tile)), "tileIndex4"
    lda tileIndex3
    expectA #$FF, "tileIndex3"
    lda tileIndex2
    expectA #(13*.sizeof(Tile)), "tileIndex2"
    lda tileIndex1
    expectA #$FF, "tileIndex1"

    ldx tileIndex4
    lda tiles+Tile::xpos, x
    expectA #12, "tiles[tileIndex4].x"
    lda tiles+Tile::ypos, x
    expectA #0, "tiles[tileIndex4].y"
    lda tiles+Tile::power, x
    expectA #0, "tiles[tileIndex4].power"

    ldx tileIndex2
    lda tiles+Tile::xpos, x
    expectA #12, "tiles[tileIndex2].x"
    lda tiles+Tile::ypos, x
    expectA #8, "tiles[tileIndex2].y"
    lda tiles+Tile::power, x
    expectA #1, "tiles[tileIndex2].power"

    rts

TestFindTilesIgnoreIntermediatePositions:
    setTestName TestFindTilesIgnoreIntermediatePositions
    jsr WipeTiles
    setTile #13,  #0, #4, #0
    setTile  #9,  #1, #4, #1
    setTile  #3,  #2, #4, #2
    setTile  #0,  #3, #4, #3
    setTile #16, #12, #4, #4
    setTile  #8,  #7, #4, #5
    setTile  #2, #17, #4, #6
    setTile #10, #18, #4, #7
    setTile  #5, #19, #4, #8
    lda #1  ; => ypos == 4
    sta tileRow
    lda #DIR_LEFT
    sta slideDir
    jsr FindTileRow

    lda tileIndex1
    expectA #(13*.sizeof(Tile)), "tileIndex1"
    lda tileIndex2
    expectA #$FF, "tileIndex2"
    lda tileIndex3
    expectA #$FF, "tileIndex3"
    lda tileIndex4
    expectA #(16*.sizeof(Tile)), "tileIndex4"

    ldx tileIndex1
    lda tiles+Tile::xpos, x
    expectA #0, "tiles[tileIndex4].x"
    lda tiles+Tile::ypos, x
    expectA #4, "tiles[tileIndex4].y"
    lda tiles+Tile::power, x
    expectA #0, "tiles[tileIndex4].power"

    ldx tileIndex4
    lda tiles+Tile::xpos, x
    expectA #12, "tiles[tileIndex2].x"
    lda tiles+Tile::ypos, x
    expectA #4, "tiles[tileIndex2].y"
    lda tiles+Tile::power, x
    expectA #4, "tiles[tileIndex2].power"

    rts

TestGetTilePosOnSlideAxis:
    setTestName TestGetTilePosOnSlideAxis
    jsr WipeTiles
    setTile  #9,  #1, #4, #1
    lda #DIR_LEFT
    sta slideDir

    ldx #9*.sizeof(Tile)
    jsr GetTilePosOnSlideAxis
    expectA #1, "A"

    ldx #0*.sizeof(Tile)
    jsr GetTilePosOnSlideAxis
    expectA #$FF, "A"

    lda #DIR_UP
    sta slideDir

    ldx #9*.sizeof(Tile)
    jsr GetTilePosOnSlideAxis
    expectA #4, "A"

    ldx #0*.sizeof(Tile)
    jsr GetTilePosOnSlideAxis
    expectA #$FF, "A"

    rts

TestGetTilePosOnNonSlideAxis:
    setTestName TestGetTilePosOnNonSlideAxis
    jsr WipeTiles
    setTile  #9,  #1, #4, #1
    lda #DIR_LEFT
    sta slideDir

    ldx #9*.sizeof(Tile)
    jsr GetTilePosOnNonSlideAxis
    expectA #4, "A"

    ldx #0*.sizeof(Tile)
    jsr GetTilePosOnNonSlideAxis
    expectA #$FF, "A"

    lda #DIR_DOWN
    sta slideDir

    ldx #9*.sizeof(Tile)
    jsr GetTilePosOnNonSlideAxis
    expectA #1, "A"

    ldx #0*.sizeof(Tile)
    jsr GetTilePosOnNonSlideAxis
    expectA #$FF, "A"

    rts

DumpTiles:
    ldy #0
    ldx #0
DumpNextTile:
    lda tiles+Tile::xpos, x
    printf "Tile %0d xpos = %d", tempY, tempA
    lda tiles+Tile::ypos, x
    printf "Tile %0d ypos = %d", tempY, tempA
    lda tiles+Tile::power, x
    printf "Tile %0d power = %d", tempY, tempA
    lda tiles+Tile::velocity, x
    printf "Tile %0d velocity = %d", tempY, tempA
    printf ""
.repeat .sizeof(Tile)
    inx
.endrepeat
    iny
    cpy #17
    beq :+
    jmp DumpNextTile
:
    printf "tileIndex1 = %d", tileIndex1
    printf "tileIndex2 = %d", tileIndex2
    printf "tileIndex3 = %d", tileIndex3
    printf "tileIndex4 = %d", tileIndex4
    rts