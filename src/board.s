.include "defs.s"

.segment "ZEROPAGE"

tiles: .res (17 * .sizeof(Tile))
tileIndex1: .res 1
tileIndex2: .res 1
tileIndex3: .res 1
tileIndex4: .res 1
tileRow: .res 1
slideDir: .res 1        ; See DIR_* enums in defs.s
currentPower: .res 1    ; temp var used by CalculateTileTransitions
.export tiles, slideDir

.segment "CODE"

; CalculateTileTransitions
; Calculates the slide velocities and resulting powers for the four tiles
; indexed by tileIndex1-4.  Velocities are in board-space units (A velocity of
; -1 will move 1 full tile to the left after 4 frames).  If the tile is
; disappearing because another tile will merge into it, its new power is set to
; $FF.
;
; Params:
; tileIndex[1-4] - Indices into the tiles array for up to four tiles in the same
;                  row or column.  Tiles with index $FF will be considered empty
;                  slots.
CalculateTileTransitions:
    ldy #0  ; Y will be velocity counter
    ldx tileIndex1
    cpx #$FF
    bne :+
    ; No tile in slot 1
    jsr @IncrementVelocity
    jmp @Tile2
:
    ; There is a tile in slot 1
    lda #0  ; Tile in slot 1 never moves
    sta tiles + Tile::velocity, X
    ; Find the next tile and see if it will merge with this one
    lda tiles + Tile::powers, X
    and #$0F
    sta currentPower
    ldx tileIndex2
    cpx #$FF
    beq @Tile2Empty
    ; There is a tile in slot 2
    lda tiles + Tile::powers, X
    and #$0F
    cmp currentPower
    bne @Tile2NoMatch
    ; Tile in slot 2 matches
    jsr @IncrementVelocity
    tya
    sta tiles + Tile::velocity, X
    ; Set tile 2 newPower accordingly
    jsr SetTilePowerIncrease
    ; Mark tile 1 for removal
    ldx tileIndex1
    jsr SetTileDisappears
    jmp @Tile3
@Tile2NoMatch:
    ; Tile in slot 2 is not a match
    tya
    sta tiles + Tile::velocity, X
    jsr SetTilePowerConstant
    ldx tileIndex1
    jsr SetTilePowerConstant
    jmp @Tile2
@Tile2Empty:
    jsr @IncrementVelocity
    ldx tileIndex3
    cpx #$FF
    beq @Tile3Empty
    ; There is a tile in slot 3
    lda tiles + Tile::powers, X
    and #$0F
    cmp currentPower
    bne @Tile3NoMatch
    ; Tile in slot 3 matches
    jsr @IncrementVelocity
    tya
    sta tiles + Tile::velocity, X
    ; Set its newPower accordingly
    jsr SetTilePowerIncrease
    ldx tileIndex1
    jsr SetTileDisappears
    jmp @Tile4
@Tile3NoMatch:
    ; Tile in slot 3 is not a match
    tya
    sta tiles + Tile::velocity, X
    jsr SetTilePowerConstant
    ldx tileIndex1
    jsr SetTilePowerConstant
    jmp @Tile3
@Tile3Empty:
    jsr @IncrementVelocity
    ldx tileIndex4
    cpx #$FF
    bne :+
    ldx tileIndex1
    jsr SetTilePowerConstant
    jmp @Done
:
    ; There is a tile in slot 4
    lda tiles + Tile::powers, X
    and #$0F
    cmp currentPower
    bne @Tile4NoMatch
    ; Tile in slot 4 matches
    jsr @IncrementVelocity
    tya
    sta tiles + Tile::velocity, X
    ; Set its newPower accordingly
    jsr SetTilePowerIncrease
    ldx tileIndex1
    jsr SetTileDisappears
    jmp @Done
@Tile4NoMatch:
    ; Tile in slot 4 is not a match
    tya
    sta tiles + Tile::velocity, X
    jsr SetTilePowerConstant
    ldx tileIndex1
    jsr SetTilePowerConstant
    jmp @Done
@Tile2:
    ldx tileIndex2
    cpx #$FF
    bne :+
    ; No tile in slot 2
    jsr @IncrementVelocity
    jmp @Tile3
:
    ; There is a tile in slot 2
    tya
    sta tiles + Tile::velocity, X
    ; Find the next tile and see if it will merge with this one
    lda tiles + Tile::powers, X
    and #$0F
    sta currentPower
    ldx tileIndex3
    cpx #$FF
    beq @Tile3Empty2
    ; There is a tile in slot 3
    lda tiles + Tile::powers, X
    and #$0F
    cmp currentPower
    bne @Tile3NoMatch2
    ; Tile in slot 3 matches
    jsr @IncrementVelocity
    tya
    sta tiles + Tile::velocity, X
    ; Set tile 3 newPower accordingly
    jsr SetTilePowerIncrease
    ; Mark tile 2 for removal
    ldx tileIndex2
    jsr SetTileDisappears
    jmp @Tile4
@Tile3NoMatch2:
    ; Tile in slot 3 is not a match
    tya
    sta tiles + Tile::velocity, X
    jsr SetTilePowerConstant
    ldx tileIndex2
    jsr SetTilePowerConstant
    jmp @Tile3
@Tile3Empty2:
    jsr @IncrementVelocity
    ldx tileIndex4
    cpx #$FF
    bne :+
    ldx tileIndex2
    jsr SetTilePowerConstant
    jmp @Done
:
    ; There is a tile in slot 4
    lda tiles + Tile::powers, X
    and #$0F
    cmp currentPower
    bne @Tile4NoMatch2
    ; Tile in slot 4 matches
    jsr @IncrementVelocity
    tya
    sta tiles + Tile::velocity, X
    ; Set its newPower accordingly
    jsr SetTilePowerIncrease
    ldx tileIndex2
    jsr SetTileDisappears
    jmp @Done
@Tile4NoMatch2:
    ; Tile in slot 4 is not a match
    tya
    sta tiles + Tile::velocity, X
    jsr SetTilePowerConstant
    ldx tileIndex2
    jsr SetTilePowerConstant
    jmp @Done
@Tile3:
    ldx tileIndex3
    cpx #$FF
    bne :+
    ; No tile in slot 3
    jsr @IncrementVelocity
    jmp @Tile4
:
    ; There is a tile in slot 3
    tya
    sta tiles + Tile::velocity, X
    ; Find the next tile and see if it will merge with this one
    lda tiles + Tile::powers, X
    and #$0F
    sta currentPower
    ldx tileIndex4
    cpx #$FF
    bne :+
    ldx tileIndex3
    jsr SetTilePowerConstant
    jmp @Done
:
    ; There is a tile in slot 4
    lda tiles + Tile::powers, X
    and #$0F
    cmp currentPower
    bne @Tile4NoMatch3
    ; Tile in slot 4 matches
    jsr @IncrementVelocity
    tya
    sta tiles + Tile::velocity, X
    ; Set tile 4 newPower accordingly
    jsr SetTilePowerIncrease
    ; Mark tile 3 for removal
    ldx tileIndex3
    jsr SetTileDisappears
    jmp @Done
@Tile4NoMatch3:
    ; Tile in slot 4 is not a match
    tya
    sta tiles + Tile::velocity, X
    jsr SetTilePowerConstant
    ldx tileIndex3
    jsr SetTilePowerConstant
    jmp @Done
@Tile4:
    ldx tileIndex4
    tya
    sta tiles + Tile::velocity, X
    jsr SetTilePowerConstant
@Done:
    rts
@IncrementVelocity:
    lda slideDir
    cmp #DIR_LEFT
    beq :+
    cmp #DIR_UP
    beq :+
    iny
    rts
:
    dey
    rts

; SetTilePowerIncrease
; Sets a tile's new power (high nibble) to one greater than its current power
; (low nibble).
;
; Params:
; X - index into tiles array
SetTilePowerIncrease:
    lda tiles + Tile::powers, X
    clc
    adc #1
    asl
    asl
    asl
    asl
    ora tiles + Tile::powers, X
    sta tiles + Tile::powers, X
    rts

; SetTilePowerConstant
; Sets a tile's new power (high nibble) to the same as its current power (low
; nibble).
;
; Params:
; X - index into tiles array
SetTilePowerConstant:
    lda tiles + Tile::powers, X
    asl
    asl
    asl
    asl
    ora tiles + Tile::powers, X
    sta tiles + Tile::powers, X
    rts

; SetTileDisappears
; Sets a tile's new power (high nibble) to $F to indicate this tile will
; disappear from the board.
;
; Params:
; X - index into tiles array
SetTileDisappears:
    lda #$F0
    ora tiles + Tile::powers, X
    sta tiles + Tile::powers, X
    rts

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

; GetTilePosOnSlideAxis
; Retrieves the position coordinate of a given tile along the current sliding
; axis.
;
; Params:
; X - index into tiles array
; slideDir - determines the slide axis
;
; Returns:
; A - the tile's coordinate in board-space on the sliding axis
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

; GetTilePosOnNonSlideAxis
; Retrieves the position coordinate of a given tile along the opposite axis of
; the current sliding axis.
;
; Params:
; X - index into tiles array
; slideDir - determines the slide axis
;
; Returns:
; A - the tile's coordinate in board-space on the non-sliding axis
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
.export SetTileDisappears, SetTilePowerConstant, SetTilePowerIncrease
.export CalculateTileTransitions
.exportzp tileRow, tileIndex1, tileIndex2, tileIndex3, tileIndex4
.endif