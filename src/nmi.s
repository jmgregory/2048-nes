.include "defs.s"

.import Blit16

.segment "ZEROPAGE"
blitStartPPU:   .res 2  ; Counter address used in blitting to PPU
blitMode:       .res 1  ; see BLIT_* enum in defs.s
blitCounter:    .res 1  ; Which row/col are we blitting?
.export blitMode

.import blitSource

.segment "CODE"

.export nmi
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
    cmp #BLIT_HORIZONTAL
    beq BlitHorizontal
    cmp #BLIT_VERTICAL
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
    tay     ; Y is index into BOARD_BUFFER

    lda #<BOARD_BUFFER
    sta blitSource
    lda #>BOARD_BUFFER
    sta blitSource+1

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

; Blit ATTR table
; Horizontal
    lda blitCounter
    and #$03
    asl A
    asl A
    clc
    adc #BOARD_TOP_Y
    asl A
    asl A
    asl A
    clc
    adc #BOARD_LEFT_X
    lsr A
    lsr A
    adc #$C0
    ldy #$23
    bit PPU_STATUS
    sty PPU_ADDR
    sta PPU_ADDR
    lda blitCounter
    and #$03
    asl A
    asl A
    tax
    lda ATTR_BUFFER, X
    inx
    sta PPU_DATA
    lda ATTR_BUFFER, X
    inx
    sta PPU_DATA
    lda ATTR_BUFFER, X
    inx
    sta PPU_DATA
    lda ATTR_BUFFER, X
    inx
    sta PPU_DATA
    jmp DoneBlitting

DoneBlitting:
    inc blitCounter

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

