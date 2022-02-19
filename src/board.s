.include "defs.s"

.segment "ZEROPAGE"

tiles: .res (17 * .sizeof(Tile))
tileIndex1: .res 1
tileIndex2: .res 1
tileIndex3: .res 1
tileIndex4: .res 1
tileRow: .res 1
slideDir: .res 1        ; See DIR_* enums in defs.s
.export tiles, slideDir

.segment "CODE"

; FindTileRow
; Locates up to four tiles in a given row or column (tileRow) and assigns their
; addresses in order to tileIndex1-4. The order is determined by the current
; slide direction (slideDir), where the tiles are always sliding from index 4
; toward index 1.  For instance, if slideDir is DIR_DOWN, then tileIndex1 will
; refer to the tile at the bottom of the board (if any), and tileIndex4 will
; refer to the tile at the top of the board.  If there is no tile in a slot, the
; index value will be $FF.  Only tiles in true board board positions 0, 4, 8,
; and 12 will be found, not intermediate permissions such as 1 or 13.
;
; Params:
; slideDir - Sets whether to search by row or column, and the output order of
;            the tileIndex values.  (See DIR_* enum)
; tileRow - Which row or column to find tiles in (0-3)
FindTileRow:
    ; Clear tileIndex vars
    lda #$FF
    sta tileIndex1
    sta tileIndex2
    sta tileIndex3
    sta tileIndex4
    ldx #0  ; X is index into tiles array
@StartTileCheck:
    jsr GetTilePosOnNonSlideAxis
    tay
    and #$03        ; Must be a multiple of 4
    bne @NextTile
    tya
    lsr
    lsr
    cmp tileRow
    bne @NextTile
    jsr GetTilePosOnSlideAxis
    cmp #0
    bne :+
    stx tileIndex1
    jmp @NextTile
:
    cmp #4
    bne :+
    stx tileIndex2
    jmp @NextTile
:
    cmp #8
    bne :+
    stx tileIndex3
    jmp @NextTile
:
    cmp #12
    bne @NextTile
    stx tileIndex4
    jmp @NextTile

@NextTile:
.repeat .sizeof(Tile)
    inx
.endrepeat
    cpx #(.sizeof(Tile) * 17)
    bne @StartTileCheck

    ; Reverse the pointer order if direction is right or down
    lda slideDir
    cmp #DIR_LEFT
    beq :+
    cmp #DIR_UP
    beq :+
    ldx tileIndex1
    lda tileIndex4
    stx tileIndex4
    sta tileIndex1
    ldx tileIndex2
    lda tileIndex3
    stx tileIndex3
    sta tileIndex2
:
    rts

GetTilePosOnSlideAxis:
    lda slideDir
    cmp #DIR_UP
    beq :+
    cmp #DIR_DOWN
    beq :+
    lda tiles + Tile::xpos, X
    jmp :++
:
    lda tiles + Tile::ypos, X
:
    rts

GetTilePosOnNonSlideAxis:
    lda slideDir
    cmp #DIR_UP
    beq :+
    cmp #DIR_DOWN
    beq :+
    lda tiles + Tile::ypos, X
    jmp :++
:
    lda tiles + Tile::xpos, X
:
    rts

.ifdef TEST
.export FindTileRow, GetTilePosOnNonSlideAxis, GetTilePosOnSlideAxis
.exportzp tileRow, tileIndex1, tileIndex2, tileIndex3, tileIndex4
.endif