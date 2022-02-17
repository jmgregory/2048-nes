.include "defs.s"

.segment "ZEROPAGE"
blitSource:     .res 2  ; Pointer to memory location to blit from
.export blitSource

.segment "CODE"

.export Blit256, Blit224
Blit256:
    jsr Blit32
Blit224:
    jsr Blit32
    jsr Blit32
    jsr Blit32
    jsr Blit32
    jsr Blit32
    jsr Blit32
    jsr Blit32
    rts

.export Blit32
Blit32:
    jsr Blit16
    jsr Blit16
    rts

.export Blit16
Blit16:
    lda (blitSource), Y
    sta PPU_DATA
    iny
    lda (blitSource), Y
    sta PPU_DATA
    iny
    lda (blitSource), Y
    sta PPU_DATA
    iny
    lda (blitSource), Y
    sta PPU_DATA
    iny
    lda (blitSource), Y
    sta PPU_DATA
    iny
    lda (blitSource), Y
    sta PPU_DATA
    iny
    lda (blitSource), Y
    sta PPU_DATA
    iny
    lda (blitSource), Y
    sta PPU_DATA
    iny
    lda (blitSource), Y
    sta PPU_DATA
    iny
    lda (blitSource), Y
    sta PPU_DATA
    iny
    lda (blitSource), Y
    sta PPU_DATA
    iny
    lda (blitSource), Y
    sta PPU_DATA
    iny
    lda (blitSource), Y
    sta PPU_DATA
    iny
    lda (blitSource), Y
    sta PPU_DATA
    iny
    lda (blitSource), Y
    sta PPU_DATA
    iny
    lda (blitSource), Y
    sta PPU_DATA
    iny
    rts
