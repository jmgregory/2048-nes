.include "defs.s"

.segment "ZEROPAGE"
frameCounter: .res 1

.segment "CODE"

.import PaintAttributeBufferRow
.import WipeBoardRow, WipeSpriteBuffer, WipeSpriteRow
.import WipeTiles, IterateTileRowSlide, CalculateTileTransitions, ResetTileVelocities, FindTileRow, UpdateTilePowers
.import DrawBoardRow
.import ReadJoy
.importzp blitSource, blitMode, nmiDone
.importzp blitCounter, slideDir, tileRow
.importzp newButtons1

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

    ; Add some tiles for testing
    .importzp tiles
    jsr WipeTiles
    lda #0
    sta tiles + 0 + Tile::powers
    lda #4
    sta tiles + 0 + Tile::xpos
    lda #12
    sta tiles + 0 + Tile::ypos
    lda #0
    sta tiles + 0 + Tile::velocity
    lda #0
    sta tiles + 4 + Tile::powers
    lda #0
    sta tiles + 4 + Tile::xpos
    lda #12
    sta tiles + 4 + Tile::ypos
    lda #0
    sta tiles + 4 + Tile::velocity
    lda #2
    sta tiles + 8 + Tile::powers
    lda #0
    sta tiles + 8 + Tile::xpos
    lda #0
    sta tiles + 8 + Tile::ypos
    lda #0
    sta tiles + 8 + Tile::velocity

    lda #$FF
    sta frameCounter

    lda #DIR_LEFT
    sta slideDir

; Enable interrupts
    cli
    ; enable NMI, use second CHAR tile set for sprites
    lda #%10001000
    sta PPU_CTRL
    ; Enable sprites and background
    lda #%00011110
    sta PPU_MASK

MainLoop:
    lda frameCounter
    cmp #$FF
    bne :+
    ; Only check button presses if we're not currently animating
    jsr CheckForButtonPresses
:

    ; Set tileRow
    lda blitCounter
    and #$03
    sta tileRow

    ; For first four frames only, calculate this row's tile velocities
    lda frameCounter
    cmp #4
    bcs :+
    jsr FindTileRow
    jsr CalculateTileTransitions
:

    jsr IterateTileRowSlide
    jsr WipeSpriteRow
    jsr WipeBoardRow
    jsr DrawBoardRow
    jsr PaintAttributeBufferRow

    lda frameCounter
    cmp #$FF
    beq WaitLoop
    inc frameCounter
    lda frameCounter
    cmp #16 ; End animation after 16 frames
    bne :+
    lda #$FF
    sta frameCounter
    jsr ResetTileVelocities
    jsr UpdateTilePowers
:

WaitLoop:
    lda nmiDone
    cmp #1
    bne WaitLoop
    lda #0
    sta nmiDone
    jmp MainLoop

CheckForButtonPresses:
    jsr ReadJoy
    lda newButtons1
    cmp #BUTTON_LEFT
    bne :+
    lda #DIR_LEFT
    sta slideDir
    lda #BLIT_HORIZONTAL
    sta blitMode
    jmp BeginSlideAnimation
:
    cmp #BUTTON_RIGHT
    bne :+
    lda #DIR_RIGHT
    sta slideDir
    lda #BLIT_HORIZONTAL
    sta blitMode
    jmp BeginSlideAnimation
:
    cmp #BUTTON_DOWN
    bne :+
    lda #DIR_DOWN
    sta slideDir
    lda #BLIT_VERTICAL
    sta blitMode
    jmp BeginSlideAnimation
:
    cmp #BUTTON_UP
    bne :+
    lda #DIR_UP
    sta slideDir
    lda #BLIT_VERTICAL
    sta blitMode
    jmp BeginSlideAnimation
:
    rts
BeginSlideAnimation:
    lda #0
    sta frameCounter
    sta blitCounter
    rts

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
