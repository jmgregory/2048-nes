; definitions
PPU_CTRL      = $2000
PPU_MASK      = $2001
PPU_STATUS    = $2002
PPU_SCROLL    = $2005
PPU_ADDR      = $2006
PPU_DATA      = $2007
OAM_ADDRESS   = $2003
OAM_DMA       = $4014
APU_DMC       = $4010
APU_STATUS    = $4015
APU_FRAME_CTR = $4017

SPRITE_BUFFER = $0200   ; Staging area for sprite data
BOARD_BUFFER  = $0300   ; Staging area for main board nametable
COLOR_BUFFER  = $0400   ; Staging area for tile colors, for attribute table calc
ATTR_BUFFER   = $0500   ; Staging area for board attribute table

BOARD_LEFT_X  = 4       ; X coordinate of board left edge in nametable space (must multiple of 4 for attributes to map properly)
BOARD_TOP_Y   = 8       ; Y coordinate of board top edge in nametable space (must multiple of 4 for attributes to map properly)

.enum
    BLIT_NONE
    BLIT_HORIZONTAL
    BLIT_VERTICAL
.endenum

.enum
    DIR_UP
    DIR_DOWN
    DIR_LEFT
    DIR_RIGHT
.endenum

.struct Tile
    power       .byte
    xpos        .byte
    ypos        .byte
    velocity    .byte   ; High nibble = x velocity, low nibble = y velocity (2's complement)
.endstruct