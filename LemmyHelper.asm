function JorU(j, u) = select(defined("VER_U"), u, j)

function StripeHeader(layer, x, y) = \
    select(equal(layer,1),$20,select(equal(layer,2),$30,$50))|\
    ((y&$20)>>2)|\
    ((x&$20)>>3)|\
    ((y&$18)>>3)|\
    ((y&$07)<<13)|\
    ((x&$1F)<<8)

; hardware register
!HW_DVIDEND = $4204
!HW_DIVISOR = $4206
!HW_QUOTIENT = $4214
!HW_REMAINDER = $4216

; variables originally held by SMW
!byetudlrHold = $15
!byetudlrFrame = $16
!axlr0000Frame = $18
!Powerup = $19
!SavedPlayerPowerup = $0DB8
!SavedPlayerItembox = $0DBC
!PlayerLives = $0DBE
!PlayerItembox = $0DC2
!MusicBackup = $0DDA
!StatusBar = $0EF9
!SkipMidwayCastleIntro = $13CF
!RNGCalc = $148B
!RandomNumber = $148D
!LoadingLevelNumber = $17BB
!OWLevelTileSettings = $1EA2
!DynStripeImgSize = $7F837B
!DynamicStripeImage = $7F837D

; added variables
!repeat_timer = $FF
!rng_index = $1487
!save_data = $700380
!save_powerup = $700380
!save_itembox = $700381
!save_start_point = $700382
!save_rng_index = $700383
!backup_data = $7003C0
!backup_powerup = $7003C0
!backup_itembox = $7003C1
!backup_start_point = $7003C2
!backup_rng_index = $7003C3

; hijacks ---------------------------------------------------------------------

ORG JorU($008EEA, $008F55)
        JSL level_draw_rng
        NOP #2

ORG JorU($009A30, $009A9B)
        JSR title_screen_load

; disable routine that gets the number of exits and shows it on the screen
ORG JorU($009C4C, $009CB8)
        NOP #3

ORG JorU($009C6B, $009CD1)              ; GameMode08
        JSL check_save_data
        JMP JorU($9DAE, $9E10)          ; skip all file and player menuing

; remove intro cutscene
ORG JorU($009C42, $009CB0)
        LDA #$00

; initial position
ORG JorU($009E8E, $009EF0)
        db $02, $02
ORG JorU($009E94, $009EF6)
        dw $00C8, $0128, $00C8, $0128
        dw $000C, $0012, $000C, $0012

ORG JorU($00A02B, $00A08D)
        NOP #2
        JSL overworld_load

ORG JorU($00A165, $00A1C7)
        JSL overworld_tick

ORG JorU($00A182, $00A1E4)
        JSL level_tick
        LDA #$00
        BRA $14

ORG JorU($00AD3E, $00ADA0)
        JSR overworld_load_hud_colors

; palette
ORG JorU($00B456, $00B4B6)
        dw $573B

; remove castle cutscene
ORG JorU($00C949, $00C9A9)
        db $00

; don't decrease amount of lifes
ORG JorU($00D078, $00D0D8)
        LDA !PlayerLives

; header
ORG $00FFC0
        db "SMW LEMMY HELPER     "

; increment RNG index when GetRand is called
ORG JorU($01ACFF, $01ACFC)
        JSL count_rng_index

; remove save prompt
ORG JorU($048FB7, $048FE9)
        NOP #3
ORG JorU($048FC9, $048FFB)
        NOP #3

; don't enter level when X or Y is pressed
ORG JorU($049113, $049154)
        AND #$80

; enter destroyed castle
ORG JorU($04915A, $04919B)
        NOP #4

ORG JorU($049BFB, $049D07)
        JSL overworld_draw_bg
        JSL overworld_draw_room_name
        RTS

; skip castle crush
ORG JorU($04E61A, $04E618)
        NOP #2

; override copyright by title
ORG JorU($05B288,$05B6D3)
        dw StripeHeader(3,10,17),$1700
        dw $3815,$380E,$3816,$3816,$3822,$38FC,$3811,$380E,$3815,$3819,$380E,$381B ; "LEMMY HELPER"
        dw $FFFF

; skip castle intro
ORG $05D79B
        STA !SkipMidwayCastleIntro

ORG $05D8A9
        JSR set_level_number

; bank $00 --------------------------------------------------------------------

ORG $00FF93

; accumulator=8bit, index=8bit
title_screen_load:
        JSR JorU($8567, $85D2)          ; LoadScrnImage
        JSL title_screen_draw
        JSR JorU($8567, $85D2)          ; LoadScrnImage
        RTS

; accumulator=16bit, index=16bit
overworld_load_hud_colors:
        JSR JorU($AC9D, $ACFF)          ; LoadColors
        LDA #JorU($B110, $B170)         ;StatusBarColors
        STA $00
        STZ $04
        LDA #$0007
        STA $06
        LDA #$0001
        STA $08
        JSR JorU($AC9D, $ACFF)          ; LoadColors
        RTS

print pc, " / 010000"
warnpc $010000

; bank $05 --------------------------------------------------------------------

ORG $05DC46

; accumulator=8bit, index=16bit or 8bit
set_level_number:
        CMP #$1C
        BNE +
        SEP #$10                        ; index=8bit
        LDA !save_start_point
        TAX
        LDA tile_settings,x
        STA !OWLevelTileSettings+$40
        LDA level_numbers,x
    +   STA !LoadingLevelNumber
        RTS

tile_settings:
        db $80,$C0,$80,$80

level_numbers:
        db $1C,$1C,$F3,$F2

print pc, " / 05E000"
warnpc $05E000

; bank $0F --------------------------------------------------------------------

ORG $0FEF90

; accumulator=8bit, index=8bit
title_screen_draw:
        REP #$30
        LDA.W #title_screen_image
        STA $00
        LDA.W #title_screen_image>>16
        STA $02
        LDA.W #22
        JSR append_stripe_image
        SEP #$30
        RTL

; [$00]=source, A=size
; accumulator=16bit, index=16bit
append_stripe_image:
        TAY
        CLC
        ADC !DynStripeImgSize
        STA !DynStripeImgSize
        TAX
        LDA #$FFFF
        STA !DynamicStripeImage,x
    -   DEX #2
        DEY #2
        LDA [$00],y
        STA !DynamicStripeImage,x
        CPY #$0000
        BNE -
        RTS

; accumulator=8bit, index=8bit
check_save_data:
        LDX #$06
    -   LDA !save_data,x
        EOR !backup_data,x
        EOR #$FF
        BNE .invalid
        DEX
        BPL -

        LDA !save_start_point
        CMP #$04
        BCS .invalid

        REP #$20                        ; accumulator=16bit
        LDA !save_rng_index
        CMP #$6C81
        BCS .invalid
        LDA !save_rng_index+2
        CMP #$6C81
        BCS .invalid

    .valid
        SEP #$20                        ; accumulator=8bit
        RTL

    .invalid
        SEP #$20                        ; accumulator=8bit
        LDX #$06
    -   LDA #$00
        STA !save_data,x
        LDA #$FF
        STA !backup_data,x
        DEX
        BPL -
        RTL

; [$00]=seed
; accumulator=8bit, index=16bit
; high byte of accumulator must be 0
get_next_random_number:
        LDA $00
        TAY
        LDA seed1_next,y
        STA $00
        LDA $01
        TAY
        LDA seed2_next,y
        STA $01
        EOR $00
        RTS

incsrc "overworld.asm"
incsrc "level.asm"
incsrc "tables.asm"

print pc, " / 100000"
warnpc $100000

; -----------------------------------------------------------------------------
