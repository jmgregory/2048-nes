.importzp tileDrawX, tileDrawY, tilePower
.import DrawTile, PaintAttributeBuffer

.segment "CODE"

.export TestDrawTileShapes
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

.export TestDrawEdgeTiles
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

.export TestColorMix1
TestColorMix1:
    lda #0
    sta tilePower
    sta tileDrawX
    sta tileDrawY
    jsr DrawTile
    inc tilePower
    inc tileDrawX
    jsr DrawTile
    inc tilePower
    inc tileDrawX
    jsr DrawTile
    inc tilePower
    inc tileDrawX
    jsr DrawTile

    lda #0
    sta tileDrawX
    lda #4
    sta tileDrawY
    inc tilePower
    jsr DrawTile
    inc tilePower
    inc tileDrawX
    jsr DrawTile
    inc tilePower
    inc tileDrawX
    jsr DrawTile
    inc tilePower
    inc tileDrawX
    jsr DrawTile

    lda #0
    sta tileDrawX
    lda #8
    sta tileDrawY
    inc tilePower
    jsr DrawTile
    inc tilePower
    inc tileDrawX
    jsr DrawTile
    inc tilePower
    inc tileDrawX
    jsr DrawTile
    inc tilePower
    inc tileDrawX
    jsr DrawTile

    lda #0
    sta tileDrawX
    lda #12
    sta tileDrawY
    inc tilePower
    jsr DrawTile
    inc tilePower
    inc tileDrawX
    jsr DrawTile

    rts
