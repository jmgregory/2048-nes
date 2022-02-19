.import _printf, exit
.importzp sp

.segment "DATA"
tempA: .res 1
tempX: .res 1
tempY: .res 1
testName: .res 128, 0
testFileName: .res 80, 0

.segment "CODE"

PushStack: 
    ; pha
    ; txa
    ; pha
    ; tya
    ; pha
    sta tempA
    stx tempX
    sty tempY
    rts

PopStack:
    ; pla
    ; tay
    ; pla
    ; tax
    ; pla
    lda tempA
    ldx tempX
    ldy tempY
    rts

.macro printf0 string
    .local str, SkipData
    jsr PushStack
    jmp SkipData
str:
    .byte string
    .byte $0A
    .byte $00
SkipData:
    ldy #0
    dec sp
    lda #>str
    sta (sp), y
    dec sp
    lda #<str
    sta (sp), y
    ldy #2
    jsr _printf
    jsr PopStack
.endmacro

.macro printfb1 format, arg
    .local str, SkipData
    jsr PushStack
    jmp SkipData
str:
    .byte format
    .byte $0A
    .byte $00
SkipData:
    ldy #0
    dec sp
    lda #>str
    sta (sp), y
    dec sp
    lda #<str
    sta (sp), y
    dec sp
    lda #0
    sta (sp), y
    dec sp
    lda arg
    sta (sp), y
    ldy #4
    jsr _printf
    jsr PopStack
.endmacro

.macro printfb2 format, arg1, arg2
    .local str, SkipData
    jsr PushStack
    jmp SkipData
str:
    .byte format
    .byte $0A
    .byte $00
SkipData:
    ldy #0
    dec sp
    lda #>str
    sta (sp), y
    dec sp
    lda #<str
    sta (sp), y
    dec sp
    lda #0
    sta (sp), y
    dec sp
    lda arg1
    sta (sp), y
    dec sp
    lda #0
    sta (sp), y
    dec sp
    lda arg2
    sta (sp), y
    ldy #6
    jsr _printf
    jsr PopStack
.endmacro

.macro printfw1 format, addr
    .local str, SkipData
    jsr PushStack
    jmp SkipData
str:
    .byte format
    .byte $0A
    .byte $00
SkipData:
    ldy #0
    dec sp
    lda #>str
    sta (sp), y
    dec sp
    lda #<str
    sta (sp), y
    dec sp
    lda #>addr
    sta (sp), y
    dec sp
    lda #<addr
    sta (sp), y
    ldy #4
    jsr _printf
    jsr PopStack
.endmacro

.macro printfw2 format, addr1, addr2
    .local str, SkipData
    jsr PushStack
    jmp SkipData
str:
    .byte format
    .byte $0A
    .byte $00
SkipData:
    ldy #0
    dec sp
    lda #>str
    sta (sp), y
    dec sp
    lda #<str
    sta (sp), y
    dec sp
    lda #>addr1
    sta (sp), y
    dec sp
    lda #<addr1
    sta (sp), y
    dec sp
    lda #>addr2
    sta (sp), y
    dec sp
    lda #<addr2
    sta (sp), y
    ldy #6
    jsr _printf
    jsr PopStack
.endmacro

.macro setTestFileName name
    .local str, Done, NextChar
    jsr PushStack
    ldx #0
    jmp NextChar
str: .asciiz name
NextChar:
    lda str, x
    sta testFileName, x
    beq Done
    inx
    jmp NextChar
Done:
    jsr PopStack
.endmacro

.macro setTestName name
    .local str, Done, NextChar
    jsr PushStack
    ldx #0
    jmp NextChar
str: .asciiz .string(name)
NextChar:
    lda str, x
    sta testName, x
    beq Done
    inx
    jmp NextChar
Done:
    jsr PopStack
.endmacro

.macro expectA value, string
    .local ExpectSucceeded, ExpectFailed
    cmp value
    bne ExpectFailed
    jmp ExpectSucceeded
ExpectFailed:
    sta tempA
    printfw2 "Test '%s' in file '%s' failed!", testName, testFileName
    printfb2 .concat("Expected ", string, " to be $%02x, but got $%02x"), value, tempA
    lda #1
    jmp exit
ExpectSucceeded:
.endmacro
