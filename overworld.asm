; accumulator=8bit, index=8bit
overworld_load:
        LDA !save_powerup
        STA !Powerup
        STA !SavedPlayerPowerup
        LDA !save_itembox
        STA !PlayerItembox
        STA !SavedPlayerItembox
        RTL

; accumulator=8bit, index=8bit
overworld_tick:
        PHB
        PHK
        PLB

        JSR test_for_powerup
        JSR test_for_swap
        JSR test_for_start_point
        JSR test_for_rng_toggle
        JSR test_for_rng
        JSR update_rng

        REP #$30                        ; accumulator=16bit, index=16bit
        JSL overworld_draw_room_name
        JSR overworld_draw_predictions
        JSR overworld_draw_rng
        SEP #$30                        ; accumulator=8bit, index=8bit

        PLB
        JML $048241                     ; GameMode_0E_Prim

; if R is pressed, cycle through powerup
; accumulator=8bit, index=8bit
test_for_powerup:
        LDA !axlr0000Frame
        BIT #$10
        BEQ .return

        LDA !Powerup
        INC A
        AND #$03
        STA !Powerup
        STA !SavedPlayerPowerup
        STA !save_powerup
        EOR #$FF
        STA !backup_powerup

    .return
        RTS

; if select is pressed, swap powerup and item box powerup (if applicable)
; accumulator=8bit, index=8bit
test_for_swap:
        LDA !byetudlrFrame
        BIT #$20
        BEQ .return

        LDX !Powerup
        CPX #$04
        BCS .return

        LDY !PlayerItembox
        CPY #$03
        BEQ .return
        CPY #$05
        BCS .return

        LDA itembox_table, x
        STA !PlayerItembox
        STA !SavedPlayerItembox
        STA !save_itembox
        EOR #$FF
        STA !backup_itembox

        LDA powerup_table, y
        STA !Powerup
        STA !SavedPlayerPowerup
        STA !save_powerup
        EOR #$FF
        STA !backup_powerup

    .return
        RTS

; if right is pressed, increment start point
; if left is pressed, decrement start point
; accumulator=8bit, index=8bit
test_for_start_point:
        LDA !save_start_point
        TAX
        LDA !byetudlrFrame
        BIT #$01
        BEQ +
        INX
    +   BIT #$02
        BEQ +
        DEX
    +   TXA
        AND #$03
        STA !save_start_point
        EOR #$FF
        STA !backup_start_point
        RTS

; if L is pressed, cycle through RNG
test_for_rng_toggle:
        LDA !axlr0000Frame
        BIT #$20
        BEQ .return

        LDA !save_start_point
        CMP #$03
        BEQ .lemmy
        CMP #$02
        BNE .return

    .room3
        REP #$20                        ; accumulator=16bit
        LDX #$00
        LDA !save_rng_index
        CMP #$0127
        BCS +
        LDA #$0127                      ; if (A < 127) A = 295
        BRA .store
    +   CMP #$023C
        BCS +
        LDA #$023C                      ; else if (A < 572) A = 572
        BRA .store
    +   LDA #$0000                      ; else A = 0
        BRA .store

    .lemmy
        REP #$20                        ; accumulator=16bit
        LDX #$02
        LDA !save_rng_index+2
        CMP #$01FD
        BCS +
        LDA #$01FD                      ; if (A < 509) A = 509
        BRA .store
    +   CMP #$0312
        BCS +
        LDA #$0312                      ; else if (A < 786) A = 786
        BRA .store
    +   LDA #$00D6                      ; else A = 214
        BRA .store

    .store
        STA !save_rng_index,x
        EOR #$FFFF
        STA !backup_rng_index,x
        SEP #$20                        ; accumulator=8bit

    .return
        RTS

; accumulator=8bit, index=8bit
test_for_rng:
        REP #$10                        ; index=16bit
        LDY #$0000
        LDA #$00
        XBA

        LDA !save_start_point
        SEC
        SBC #$02
        BCC .return
        ASL A
        TAX

        LDA !byetudlrHold
        AND #$4C

        CMP #$04                        ; DOWN
        BNE +
        LDY.W #-1
        BRA .check_timer

    +   CMP #$08                        ; UP
        BNE +
        LDY.W #1
        BRA .check_timer

    +   CMP #$44                        ; (X or Y) and DOWN
        BNE +
        LDY.W #-100
        BRA .check_timer

    +   CMP #$48                        ; (X or Y) and UP
        BNE .return
        LDY.W #100

    .check_timer
        LDA !repeat_timer
        CMP #$20
        BCS +
        INC !repeat_timer
        CMP #$00
        BNE .return

    +   REP #$20                        ; accumulator=16bit
        TYA
        CLC
        ADC !save_rng_index,x
        BPL +
        CLC
        ADC #$6C81                      ; if (A < 0) A += 217*128+1
    +   CMP #$6C81
        BCC +
        SBC #$6C81                      ; if (A >= 217*128+1) A -= 217*128+1
    +   STA !save_rng_index,x
        EOR #$FFFF
        STA !backup_rng_index,x

    .return
        SEP #$30                        ; accumulator=8bit, index=8bit
        CPY #$00
        BNE +
        STZ !repeat_timer
    +   RTS

; accumulator=8bit, index=8bit
update_rng:
        REP #$20                        ; accumulator=16bit
        STZ !rng_index
        STZ !rng_index+2
        STZ !RNGCalc
        STZ !RandomNumber

        ; if (save_start_point < 2) return
        LDA !save_start_point
        AND #$00FF
        SEC
        SBC #$0002
        BCS +
        BRL .return

        ; if (save_rng_index[save_start_point - 2] == 0) return
    +   ASL A
        TAX
        LDA !save_rng_index,x
        BNE +
        BRL .return

        ; convert index to BCD
    +   DEC A
        PHA
        LDX #10
        STA !HW_DVIDEND
        STX !HW_DIVISOR
        NOP #8
        LDY !HW_REMAINDER
        STY !rng_index
        LDA !HW_QUOTIENT
        STA !HW_DVIDEND
        STX !HW_DIVISOR
        NOP #8
        LDA !HW_REMAINDER
        ASL #4
        TSB !rng_index
        LDA !HW_QUOTIENT
        STA !HW_DVIDEND
        STX !HW_DIVISOR
        NOP #8
        LDY !HW_REMAINDER
        STY !rng_index+1
        LDA !HW_QUOTIENT
        STA !HW_DVIDEND
        STX !HW_DIVISOR
        NOP #8
        LDA !HW_REMAINDER
        ASL #4
        TSB !rng_index+1
        LDY !HW_QUOTIENT
        STY !rng_index+2

        ; determine seed value
        PLA
        LDX #217
        STA !HW_DVIDEND
        STX !HW_DIVISOR
        SEP #$20            ; 3 cycles  ; accumulator=8bit
        AND #$7F            ; 2 cycles
        TAY                 ; 2 cycles
        LDA seed1,Y         ; 4 cycles
        STA !RNGCalc        ; 4 cycles  ; RNGCalc[0] = seed1[index % 128]
        NOP                 ; 2 cycles
        LDY !HW_REMAINDER
        LDA seed2,Y
        STA !RNGCalc+1                  ; RNGCalc[1] = seed2[index % 217]

        ; get random number
        JSL JorU($01ACFC, $01ACF9)      ; GetRand

    .return
        SEP #$20                        ; accumulator=8bit
        RTS

; accumulator=16bit, index=16bit
overworld_draw_bg:
        LDA !DynStripeImgSize
        TAX
        LDY #$0080
        LDA #$1C3F

    -   STA !DynamicStripeImage,x
        INX #2
        DEY
        BNE -

        LDA #StripeHeader(2,0,17)
        STA !DynamicStripeImage-$0100,x
        LDA #StripeHeader(2,0,18)
        STA !DynamicStripeImage-$00C0,x
        LDA #StripeHeader(2,0,19)
        STA !DynamicStripeImage-$0080,x
        LDA #StripeHeader(2,0,20)
        STA !DynamicStripeImage-$0040,x
        LDA #$3B00
        STA !DynamicStripeImage-$00FE,x
        STA !DynamicStripeImage-$00BE,x
        STA !DynamicStripeImage-$007E,x
        STA !DynamicStripeImage-$003E,x
        LDA #$FFFF
        STA !DynamicStripeImage,x
        TXA
        STA !DynStripeImgSize
        RTL

; accumulator=16bit, index=16bit
overworld_draw_room_name:
        LDA !save_start_point
        AND #$00FF
        ASL #4
        ADC.W #room_names
        STA $00
        LDA.W #room_names>>16
        STA $02
        LDA #$0010
        JSR append_stripe_image
        RTL

; accumulator=16bit, index=16bit
overworld_draw_predictions:
        LDA.W #predictions_image
        STA $00
        LDA.W #predictions_image>>16
        STA $02
        LDA.W #14
        JSR append_stripe_image

        LDA !save_start_point
        AND #$00FF
        CMP #$0003
        BNE .return

        LDA !RNGCalc
        STA $00
        LDA #$0000                      ; clear high byte
        SEP #$20                        ; accumulator=8bit
        JSR .predict
        JSR .predict
        JSR .predict
        JSR .predict
        JSR .predict
        REP #$20                        ; accumulator=16bit

    .return
        RTS

    .predict:
        ; pipe number
        JSR get_next_random_number
        AND #$0F
        TAY
        LDA pipe_table,y
        STA !DynamicStripeImage+4,x
        INX

        ; indicate in red when facing sideways and yellow otherwise
        JSR get_next_random_number
        LSR #2
        AND #$07
        TAY
        LDA pose_table,y
        STA !DynamicStripeImage+4,x
        INX
        RTS

; accumulator=16bit, index=16bit
overworld_draw_rng:
        LDA.W #rng_image
        STA $00
        LDA.W #rng_image>>16
        STA $02
        LDA.W #28
        JSR append_stripe_image

        LDA !save_start_point
        AND #$00FF
        CMP #$0002
        BCC .return

        TXA
        CLC
        ADC.W #!DynamicStripeImage+4
        STA $00
        LDA.W #!DynamicStripeImage>>16
        STA $02
        SEP #$30                        ; accumulator=8bit, index=8bit

        LDY #$02
        LDA !rng_index+2
        STA [$00]
        LDA !rng_index+1
        JSR .hex
        LDA !rng_index
        JSR .hex

        ; replace 0's with spaces cause it looks better for a 5 digit number
        LDY #$00
    -   LDA [$00],y
        BNE +
        LDA #$FC
        STA [$00],y
        INY #2
        CPY #$08
        BNE -

    +   LDY #$10
        LDA !RandomNumber
        JSR .hex
        LDA !RandomNumber+1
        JSR .hex
        REP #$30                        ; accumulator=16bit, index=16bit

    .return
        RTS

    .hex
        PHA
        LSR #4
        STA [$00],y
        INY #2
        PLA
        AND #$0F
        STA [$00],y
        INY #2
        RTS
