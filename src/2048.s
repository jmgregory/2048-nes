.include "defs.s"

.segment "CODE"

.importzp blitSource, blitMode

; Set blit mode
    lda #1
    sta blitMode

; Draw the main background
.import Blit256
    ; Set PPU address to 0x2000 (first nametable)
    bit PPU_STATUS  ; clear PPU address latch
    lda #$20
    sta PPU_ADDR
    lda #$00
    sta PPU_ADDR
    lda #<BackgroundPatternTable
    sta blitSource
    lda #>BackgroundPatternTable
    sta blitSource + 1
    ldy #0
    jsr Blit256
    inc blitSource + 1
    jsr Blit256
    inc blitSource + 1
    jsr Blit256
    inc blitSource + 1
    jsr Blit256

.import WipeBoardBuffer, PaintAttributeBuffer
    jsr WipeBoardBuffer
.import TestColorMix1, TestDrawTileShapes, TestDrawEdgeTiles
    jsr TestDrawTileShapes
    ; jsr TestDrawEdgeTiles
    ; jsr TestColorMix1
    jsr PaintAttributeBuffer

; Enable interrupts
    cli
    ; enable NMI, use second CHAR tile set for sprites
    lda #%10001000
    sta PPU_CTRL
    ; Enable sprites and background
    lda #%00011110
    sta PPU_MASK

Loop:
    jmp Loop

.segment "RODATA"

.export BackgroundPatternTable
BackgroundPatternTable:
.incbin "../data/board-background.nam"

.segment "CHARS"

.incbin "../data/2048.chr"

.segment "VECTORS"
.import nmi, start
.word nmi
.word start
