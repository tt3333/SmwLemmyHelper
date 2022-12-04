; accumulator=8bit, index=8bit
level_draw_rng:
        LDX #$01
        LDA !rng_index+2
        AND #$0F
        STA !StatusBar
        LDA !rng_index+1
        JSR .hex
        LDA !rng_index
        JSR .hex

        ; replace 0's with spaces cause it looks better for a 5 digit number
        LDX #$00
    -   LDA !StatusBar,x
        BNE +
        LDA #$FC
        STA !StatusBar,x
        INX
        CPX #$04
        BNE -

    +   LDX #$1C
        LDA !RandomNumber
        JSR .hex
        LDA !RandomNumber+1
        JSR .hex
        RTL

    .hex:
        PHA
        LSR #4
        STA !StatusBar,x
        INX
        PLA
        AND #$0F
        STA !StatusBar,x
        INX
        RTS

; accumulator=8bit, index=8bit
level_tick:
        LDA !MusicBackup
        CMP #$05                        ; boss fight
        BNE .return

        REP #$30                        ; accumulator=16bit, index=16bit
        PHB
        PHK
        PLB

        LDA !DynStripeImgSize
        TAX
        LDA #StripeHeader(3,2,1)
        STA !DynamicStripeImage,x
        INX #2
        LDA #$0900
        STA !DynamicStripeImage,x
        INX #2
        LDA !RNGCalc
        STA $00
        LDA #$0000                      ; clear high byte
        SEP #$20                        ; accumulator=8bit
        JSR .predict
        JSR .predict
        JSR .predict
        JSR .predict
        JSR .predict
        LDA #$FF
        STA !DynamicStripeImage,x
        REP #$20                        ; accumulator=16bit
        TXA
        STA !DynStripeImgSize

        SEP #$30                        ; accumulator=8bit, index=8bit
        PLB

    .return
        RTL

    .predict:
        JSR get_next_random_number
        AND #$0F
        TAY
        LDA pipe_table,y
        STA !DynamicStripeImage,x
        INX

        JSR get_next_random_number
        LSR #2
        AND #$07
        TAY
        LDA pose_table,y
        ORA #$08
        STA !DynamicStripeImage,x
        INX
        RTS

; increment RNG index when GetRand is called
; accumulator=8bit, index=8bit
count_rng_index:
        REP #$21                        ; accumulator=16bit, C=0
        LDA !RNGCalc
        BNE +
        STZ !rng_index                  ; if seed is zero, reset index
        STZ !rng_index+1
    +   SED
        LDA !rng_index
        ADC #$0001
        STA !rng_index
        SEP #$20                        ; accumulator=8bit
        LDA !rng_index+2
        ADC #$00
        STA !rng_index+2
        CLD
        JML JorU($01AD0A, $01AD07)
