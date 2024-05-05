

.plugin "se.booze.kickass.CruncherPlugins"


#import "helpers.asm"






.const  text_start = 11
.const  scroller_start = 17
.const  raster_start = 56+scroller_start*8-8
.const  raster_end = raster_start+67
.const  raster_mid = (raster_start + raster_end)/2
.const  raster_first = 56

.const  barSize = 10
.const  nBars = 4

.label border = $d020
.label background = $d021
                        // zero page register

.const  scrhelp             =  $fd // 02
.const  cpos             =  $fc // 03
.const  REG_ZERO_FD             =  $40
.const  REG_ZERO_FE             =  $42
.const  REG_ZERO_FC             =  $44

                        // common register definitions

.const  REG_INTSERVICE_LOW      =  $0314              // interrupt service routine low byte
.const  REG_INTSERVICE_HIGH     =  $0315              // interrupt service routine high byte
.const  REG_SCREENCTL_1         =  $d011              // screen control register #1
.const  REG_RASTERLINE          =  $d012              // raster line position 
.const  REG_SCREENCTL_2         =  $d016              // screen control register #2
.const  REG_MEMSETUP            =  $d018              // memory setup register
.const  REG_INTFLAG             =  $d019              // interrupt flag register
.const  REG_INTCONTROL          =  $d01a              // interrupt control register
.const  REG_BORCOLOUR           =  $d020              // border colour register
.const  REG_BGCOLOUR            =  $d021              // background colour register
.const  REG_INTSTATUS_1         =  $dc0d              // interrupt control and status register #1
.const  REG_INTSTATUS_2         =  $dd0d              // interrupt control and status register #2


                        // constants

.const  C_SCREEN_RAM            =  $0400
.const  C_CHARSET               =  $3800
.const  C_CHARSET_HIGH          =  $3900
.const  C_COLOUR_RAM            =  $d800



                
.var        music = LoadSid("./Scrollex.sid")
.print      "SID at "+toHexString(music.location)
.print      "init=$"+toHexString(music.init)
.print      "play=$"+toHexString(music.play)
.print      "songs="+music.songs
.print      "startSong="+music.startSong
.print      "size=$"+toHexString(music.size)
.print      "name="+music.name
.print      "author="+music.author
.print      "copyright="+music.copyright



                        BasicUpstart2(start)
                        *= $5000    // Assemble to $2000

// -------------------- start

start:                  sei

                        jsr music.init
                        lda #$7f
                        sta REG_INTSTATUS_1             // turn off the CIA interrupts
                        sta REG_INTSTATUS_2
                        lda REG_INTSTATUS_1             // turn off the CIA interrupts
                        lda REG_INTSTATUS_2
                        and REG_SCREENCTL_1             // clear high bit of raster line
                        sta REG_SCREENCTL_1

                        ldy #000
                        sty REG_RASTERLINE
                        lda #<init_routine
                        ldx #>init_routine
                        sta REG_INTSERVICE_LOW
                        stx REG_INTSERVICE_HIGH

                        lda #$01                        // enable raster interrupts
                        sta REG_INTCONTROL
                        cli

forever:                jmp forever




// -------------------- init koala 

initkoala:
                        // lda #$18
                        // sta $d018
                        lda #$d8
                        sta $d016
                        lda #$3b
                        sta $d011
                        lda #$4710
                        sta $d020
                        lda $4710
                        sta $d021
                        ldx #0

!loop:
                        .for (var i=0; i<2; i++) {
                           lda $4328+i*$100,x
                           sta $d800+i*$100,x
                           lda $3f40+i*$100,x
                           sta $0400+i*$100,x
                        }
                        inx
                        bne !loop-
                        rts

 

// -------------------- apply interrupt function 

apply_interrupt:        sta REG_RASTERLINE
                        stx REG_INTSERVICE_LOW
                        sty REG_INTSERVICE_HIGH
apply_interrupt_repeat: inc REG_INTFLAG
                        jmp $ea81



// -------------------- clear screen ram

clear_screen_ramroutine:lda #032
                        ldx #040 
clear_screen_ram_loop:  sta C_SCREEN_RAM, x
                        sta C_SCREEN_RAM + $100, x
                        sta C_SCREEN_RAM + $200, x
                        sta C_SCREEN_RAM + $2e8, x
                        inx
                        bne clear_screen_ram_loop
                        rts



// -------------------- clear color ram

clear_colour_ramroutine:lda #010
                        ldx #000 
clear_colour_ram_loop:  sta C_COLOUR_RAM, x
                        sta C_COLOUR_RAM + $100, x
                        sta C_COLOUR_RAM + $200, x
                        sta C_COLOUR_RAM + $300, x
                        inx
                        bne clear_colour_ram_loop
                        rts


// -------------------- init small scroller

initsmallscroller:      lda #$07
                        sta scrhelp 
                        lda #$00
                        sta cpos

                        lda #$0f
                        sta $0286   // cursor color


// -------------------- init message

                        ldx #100
init_short_message:     lda #$0e
                        sta C_COLOUR_RAM + text_start*40, x
                        dex
                        bpl init_short_message

                        ldx #040
init_short_message2:    lda #$01
                        sta C_COLOUR_RAM + text_start*40 + 3*40, x
                        dex
                        bpl init_short_message2

                        ldx #040
init_short_message3:    lda text2, x
                        sta C_SCREEN_RAM + text_start*40 + 3*40, x
                        dex
                        bpl init_short_message3

                        rts



// -------------------- init scroller

initscroller:           ldx #000                        // relocate character set data
relocate_font_data:     lda font_data, x
                        sta C_CHARSET, x
                        lda font_data + $100, x
                        sta C_CHARSET + $100, x
                        lda font_data + $200, x
                        sta C_CHARSET + $200, x
                        lda font_data + $300, x
                        sta C_CHARSET + $300, x
                        // lda font_data + $400, x
                        // sta C_CHARSET + $400, x
                        inx
                        bne relocate_font_data
                                          
                        ldx #4*40                        // init colour ram for scroller
                        lda #001
set_scroller_colour:    sta C_COLOUR_RAM + scroller_start*40-1, x
                        dex
                        bne set_scroller_colour

                        ldx #40
set_scroller_colour_r:  lda waterColor
                        sta C_COLOUR_RAM + scroller_start*40+4*40-1, x
                        lda waterColor+1
                        sta C_COLOUR_RAM + scroller_start*40+5*40-1, x
                        lda waterColor+2
                        sta C_COLOUR_RAM + scroller_start*40+6*40-1, x
                        lda waterColor+3
                        sta C_COLOUR_RAM + scroller_start*40+7*40-1, x
                        dex
                        bne set_scroller_colour_r
                        rts


initwatersinus:         ldx #$00
w2:                     clc
                        lda waterSinus,x
                        adc #%11010000
                        sta waterSinus,x
                        lda waterSinus+$100,x
                        adc #%11010000
                        sta waterSinus+$100,x
                        inx
                        bne w2
                        rts 


// -------------------- init routines 

init_routine:           jsr clear_screen_ramroutine     // initialise screen
                        jsr clear_colour_ramroutine
                        jsr $e544
                        jsr initkoala
                        jsr initscroller
                        // jsr initmessage
                        jsr initsmallscroller
                        jsr initwatersinus
                
                        lda #$1e                        // switch to character set
                        sta REG_MEMSETUP

                        lda #000                        // init screen and border colours
                        sta REG_BORCOLOUR
                        sta REG_BGCOLOUR

                        jmp mainLoop



// -------------------- main loop 

mainLoop:               lda #$d8
                        sta $d016
                        lda #$3b
                        sta $d011


// -------------------- scroller 

update_scroller:        ldx scroller_amount + 1
                        dex                             // advance hardware scroll
                        dex
                        dex
                        bmi shift_scroller_data         // detect if time to shift screen ram on the scroller
                        stx scroller_amount + 1         // not time to advance scroller, so just update the hardware scroll value
                        jmp update_scroller_done_cycle        // we're done for now

shift_scroller_data:    stx REG_ZERO_FE                 // cache scroll amount for later use



                        ldy #000                        // shift screen ram to the left
scroller_shift_loop:    lda C_SCREEN_RAM + scroller_start*40 + 1, y      // shift all 4 rows
                        sta C_SCREEN_RAM + scroller_start*40 , y
                        lda C_SCREEN_RAM + scroller_start*40 +41, y
                        sta C_SCREEN_RAM + scroller_start*40 +40, y
                        lda C_SCREEN_RAM + scroller_start*40 +81, y
                        sta C_SCREEN_RAM + scroller_start*40 +80, y
                        lda C_SCREEN_RAM + scroller_start*40 +121, y
                        sta C_SCREEN_RAM + scroller_start*40 +120, y

                        lda C_SCREEN_RAM + scroller_start*40 +161, y      // shift all 4 rows
                        sta C_SCREEN_RAM + scroller_start*40 +160, y
                        lda C_SCREEN_RAM + scroller_start*40 +201, y
                        sta C_SCREEN_RAM + scroller_start*40 +200, y
                        lda C_SCREEN_RAM + scroller_start*40 +241, y
                        sta C_SCREEN_RAM + scroller_start*40 +240, y
                        lda C_SCREEN_RAM + scroller_start*40 +281, y
                        sta C_SCREEN_RAM + scroller_start*40 +280, y

                        iny
                        cpy #020
                        bne scr_cnt
                        lda #$00
                        sta $d020
                        sta $d021

scr_cnt:                cpy #039
                        bne scroller_shift_loop

                        ldx scroller_char_step + 1      // grab step into rendering current scroller character
                        bpl render_next_scroll_colm     // detect if we need to render a new character, or are still rendering current character (each letter is 4 chars wide)
                                                
scroller_message_index: ldx #000                        // time to render a new character, so set up some which character to render and the bit mask
read_next_scroller_char:lda scroller_message, x         // grab next character to render
                        bpl advance_scroller_index      // detect end of message control character
                        lda scroller_message
                        ldx #001                        // reset index - set to 1 since this update will use first char in message
                        ldy #>scroller_message          // reset scroller message read source
                        sty read_next_scroller_char + 2 
                        jmp save_scroller_index

advance_scroller_index: inx                             // advance scroller message index
                        bne save_scroller_index         // detect if reached 256 offset
                        inc read_next_scroller_char + 2 // advance high byte for reading message
save_scroller_index:    stx scroller_message_index + 1
                        
                        ldy #>C_CHARSET                 // determine if character is in the low/high section of the charset
                        cmp #031
                        bcc calc_scrollchar_src_low
                        ldy #>C_CHARSET_HIGH

calc_scrollchar_src_low:and #031                        // calculate offset into char set for character bytes
                        asl
                        asl
                        asl

                        sty render_scroller_column + 2  // store character high/low pointers for rendering
                        sty render_scroller_column2 + 2
                        sta render_scroller_column + 1
                        sta render_scroller_column2 + 1

                        lda #192                        // reset the scroller character mask
                        sta scroller_character_mask + 1
                        lda #003                        // reset step into new character mask
                        sta scroller_char_step + 1

render_next_scroll_colm:clc
                        lda REG_ZERO_FE                 // reset the hardware scroll value
                        adc #008
                        tax
                        stx scroller_amount + 1         // save hardware scroll index


                        ldx #000                        // init character byte loop counter
                        stx REG_ZERO_FD                 // reset screen rendering offset and cache on zero page
render_scroller_column: lda C_CHARSET, x                // load byte from character ram
scroller_character_mask:and #192                        // apply current mask
scroller_char_step:     ldy #255                        
                        beq skip_shift_1                // dont shift if we are already masking bits 0 and 1
shift_scroll_mask_loop1:lsr                             // shift down until bits 0 and 1 are occupied
                        lsr
                        dey
                        bne shift_scroll_mask_loop1
skip_shift_1:           asl                             // multiply by 4 as a look up into our character matrix
                        asl
                        sta REG_ZERO_FE                 // cache on zero page to recall shortly

                        inx                             // advance to next byte in character ram
render_scroller_column2:lda C_CHARSET, x
                        and scroller_character_mask + 1 // apply current mask
                        ldy scroller_char_step + 1
                        beq skip_shift_2                // dont shift if we are already masking bits 0 and 1
shift_scroll_mask_loop2:lsr                             // shift down until bits 0 and 1 are occupied
                        lsr
                        dey
                        bne shift_scroll_mask_loop2
                        
skip_shift_2:           clc                             // calculate characater code to use for this 2x2 block
                        adc REG_ZERO_FE                 // grab offset calculated earlier
                        adc #064                        // add offset to the character matrix


scroller_render_offset: ldy REG_ZERO_FD
                        sta C_SCREEN_RAM + scroller_start*40 +39, y      // render character to screen
                        tya
                        adc #040                        // advance rendering offset for next pass of the loop
                        sta REG_ZERO_FD

                        inx                             // advance to next byte in character ram
                        cpx #008                        // detect if entire column now rendered
                        bne render_scroller_column


                        // read the written bytes and reverse them using LUT
                        ldx C_SCREEN_RAM + scroller_start*40 +39
                        lda font_swap_4,x 
                        sta C_SCREEN_RAM + scroller_start*40 +39 + 7*40

                        ldx C_SCREEN_RAM + scroller_start*40 +39 + 1*40
                        lda font_swap_3,x 
                        sta C_SCREEN_RAM + scroller_start*40 +39 + 6*40

                        ldx C_SCREEN_RAM + scroller_start*40 +39 + 2*40
                        lda font_swap_2,x 
                        sta C_SCREEN_RAM + scroller_start*40 +39 + 5*40

                        ldx C_SCREEN_RAM + scroller_start*40 +39 + 3*40
                        lda font_swap_1,x 
                        sta C_SCREEN_RAM + scroller_start*40 +39 + 4*40

                        dec scroller_char_step + 1      // advance scroller character step
                        lda scroller_character_mask + 1 // advance scroller character mask for next update
                        lsr
                        lsr
                        sta scroller_character_mask + 1
                        jmp update_scroller_done
update_scroller_done_cycle:
                        ldx #$ff
lp2:                    nop     
                        nop 
                        dex 
                        bne lp2
                        lda #$00
                        sta $d020 
                        sta $d021

update_scroller_done:
                        dec scrhelp
                        dec scrhelp
                        bmi hardscroll 
                        lda #$00
                        sta REG_ZERO_FC
                        jmp sscr_done

hardscroll:             lda #$07
                        sta scrhelp
                
                        lda #$01
                        sta REG_ZERO_FC

                        ldx cpos    
                        lda text1,x


hardcont:               sta $0427+text_start*40

                        inx
                        cpx #text2-text1
                        bne cont 
                        ldx #$00
cont:                   stx cpos 

sscr_done: 
                        jsr music.play


                        :wait_raster(48)
                        cycles(15)



                        ldx logoRasterPos
                        .var c = 0
                        .var i = 0
                        .for (var u=0; u<$06; u++) {
                            .for (var v=0; v<$0b; v++) {
                                .eval i = i+1
                                lda logoRaster+v+u+1*u,x  // 4*
                                sta border      // 4
                                sta background  // 4
                                .if (mod(i, 8) != 3) {
                                        ldy REG_ZERO_FC // 3
fakecopy:                               lda $0400+text_start*40+c,y // 4
                                        sta $0400+text_start*40+c  // 4
                                        .eval c = c + 1
wasted:                                 cycles(63-4-4-4-3-4-4+0)
                                } else {
                                    cycles(20-4-4-4) // 2-3 cycles for badline
                                }
                            }
                        }
                        cycles(2)
                        lda #$0
                        sta border 
                        sta background
                        inc logoRasterPos
                        lda logoRasterPos
                        cmp #$60
                        bmi allok
                        sbc #$60
allok:                  sta logoRasterPos       
                        lda #$1b    
                        sta $d011     //  force new color DMA

                        ldx scrhelp
                        stx $d016



 

// -------------------- update rasterbars 
                        :wait_raster(123)

                        ldx #$40
                        lda #$00
            del_rb:     sta raster_data,x 
                        dex
                        bne del_rb


                        // bar for bar
                        .for (var i = 0; i < nBars; i++) {
                            ldx barPos+i
                            ldy sinTable,x 
                            ldx #barSize-1
            copy_bar1:      lda barTable+barSize*i,x 
                            sta raster_data,y
                            iny
                            dex 
                            bpl copy_bar1
                            // correct pos1 if needed 
                            inc barPos+i
                        }


    

// -------------------- wait rasterbars 
                        :wait_raster(150)





                        // apply_hardware_scroll
                        lda #$1b    
                        sta $d011     //  force new color DMA

                        
                        //cycles(-3+63) // RL15
                        cycles(0)




                        // apply_hardware_scroll
                        lda #$c0                        // 38 column
                        ora #000                        // add hardware scroll - ready to apply
                        sta $d016             // apply hardware scroll value

                        
                        .for (var i=0; i<30; i++) {
                            lda raster_data, x  // 4*
                            sta border      // 4
                            sta background  // 4
                            inx  //2
                            .if (mod(i, 8) != 4) {
                                .if (i != 29) {
                                    cycles(63-4-4-4-2)
                                }
                            } else {
                                cycles(21-4-4-4-2) // 2-3 cycles for badline
                            }
                        }

                        cycles(63-4-4-4-2-4-4-2)
                        lda #$c0                        // 38 column
scroller_amount:        ora #007                        // add hardware scroll - ready to apply
                        sta $d016             // apply hardware scroll value


                        .for (var i=30; i<67; i++) {
                            lda raster_data, x  // 4*
                            sta border      // 4
                            sta background  // 4
                            inx  //2
                            .if (mod(i, 8) != 4) {
                                .if (i != 66) {
                                    cycles(63-4-4-4-2)
                                }
                            } else {
                                cycles(21-4-4-4-2) // 2-3 cycles for badline
                            }
                        }

                        cycles(28+10-6-4-6)
                        inc waterSinusPos //6
                        ldx waterSinusPos //4
                        ldy waterSinusPos, x // 6

                        .for (var i=0; i<54; i++) {
                            .var ncyc = 63
                            ldx copyTable+i           // 4
                            lda raster_data, x      // 4
                            sta border      // 4
                            sta background  // 4
                            sty $d016 //4
                            .eval ncyc = ncyc - 4-4-4-4-4
                            .if ((i != 1) && (i != 1+8) && (i != 1+2*8) && (i != 1+3*8)) {
                                cycles(ncyc)
                            } else {
                                //cycles(2) // 2-3 cycles for badline
                            }
                        }                        

                        // .for (var i=0; i<54; i++) {
                        //     .var ncyc = 63
                        //     ldx copyTable+i           // 4
                        //     ldy raster_data, x      // 4
                        //     lda raster_color_swap, y     // 4
                        //     sta border      // 4
                        //     sta background  // 4
                        //     .eval ncyc = ncyc - 4-4-4-4-4
                        //     .if ((i != 1) && (i != 1+8) && (i != 1+2*8) && (i != 1+3*8)) {
                        //         cycles(ncyc)
                        //     } else {
                        //         //cycles(2) // 2-3 cycles for badline
                        //     }
                        // }
                        jmp mainLoop


// data & variables ------------------------------------------------------------------------------------------------]
// -----------------------------------------------------------------------------------------------------------------]




        // linking
            *=music.location "Music"
            .fill music.size, music.getData(i)



        // retropixels 
        // retropixels -o noryx_1.prg -m bitmap -f prg -r 0 noryx\ \(1\).png -s none --overwrite
        // tail -c +6002 noryx_koala.prg > noryx_koala.kla
        // to edit with ditheridoo: $ tail +143c munia2w.kla >  munia2w_90.kla

            // *=$2000
            // .import binary "./munia_rgb_final.koa", 2//, $8f

//                           lda $3f40+i*$100,x
//                           lda $4328+i*$100,x

            *=$2000
            .import binary "./munia_rgb_final.koa", 2+$2000-$2000, $a00 //, $8f
            *=$3f40
            .import binary "./munia_rgb_final.koa", 2+$3f40-$2000, $1d0 //, $8f
            *=$4328
            .import binary "./munia_rgb_final.koa", 2+$4328-$2000, $1d0 //, $8f


*=$4600

text1:          .text "     63+ nops intro...   released at decrunch 2023 in wroclaw...   " 
                .text "code & gfx by drunkeneye. scroller by jesder/0xc64.  "
                .text "music scrollex by flex/artline design...  "
text2:          .text "         -=* 63+ nops intro *=-            "
logoRasterPos:  .byte 0

waterColor:         .byte $0e, $0e, $0e, $0e, $00, $00, $00, $00
scroller_message:   .text "    hiyya, drunkeneye on the keys, this is our very first intro," 
                    .text " nearly 33 years too late, but better late than never... "
                    .text "this code has more nops than real instructions to get "
                    .text " the damn raster bars stable... this is why its called 63+ nops..."
                    .text "  the intro should have contained interlaced rasterbars, "
                    .text " sinus-scroller and what not... but well, that didnt happen... "
                    .text " maybe next year...        hi here is togu669 from the stronghold "
                    .text "breslau, the lacking element of the ongoing agi evolution. first "
                    .text "greetings go to the mysterious wizard drunkeneye, without him this "
                    .text "perfect intro would never win anything. and the last greetings go "
                    .text "to the frontline team microsol from legnicka street. this scroll text "
                    .text "was only possible thanks to your mental resilience and iron patience, "
                    .text "brothers and sisters!              "
                    .byte 255


                        // 16*32 = 512
font_data:              
                        .byte 0,0,0,0,0,0,0,0
                        .import c64 "./parallax.64c", $8, $200-8

                        //scroller characters (16 chars)
                        .byte $00, $00, $00, $00, $00, $00, $00, $00
                        .byte $00, $00, $00, $00, $0e, $0e, $0e, $00
                        .byte $00, $00, $00, $00, $e0, $e0, $e0, $00
                        .byte $00, $00, $00, $00, $ee, $ee, $ee, $00 //43

                        .byte $0e, $0e, $0e, $00, $00, $00, $00, $00 //44
                        .byte $0e, $0e, $0e, $00, $0e, $0e, $0e, $00
                        .byte $0e, $0e, $0e, $00, $e0, $e0, $e0, $00
                        .byte $0e, $0e, $0e, $00, $ee, $ee, $ee, $00

                        .byte $e0, $e0, $e0, $00, $00, $00, $00, $00 //48
                        .byte $e0, $e0, $e0, $00, $0e, $0e, $0e, $00
                        .byte $e0, $e0, $e0, $00, $e0, $e0, $e0, $00
                        .byte $e0, $e0, $e0, $00, $ee, $ee, $ee, $00 //4b

                        .byte $ee, $ee, $ee, $00, $00, $00, $00, $00 //4c
                        .byte $ee, $ee, $ee, $00, $0e, $0e, $0e, $00 //4d
                        .byte $ee, $ee, $ee, $00, $e0, $e0, $e0, $00 //4e
                        .byte $ee, $ee, $ee, $00, $ee, $ee, $ee, $00 //4f


                        .byte $00, $00, $00, $00, $00, $00, $00, $00
                        .byte $00, $00, $00, $00, $00, $00, $0e, $0e
                        .byte $00, $00, $00, $00, $00, $00, $e0, $e0
                        .byte $00, $00, $00, $00, $00, $00, $ee, $ee

                        .byte $00, $0e, $0e, $0e, $00, $00, $00, $00
                        .byte $00, $0e, $0e, $0e, $00, $00, $0e, $0e
                        .byte $00, $0e, $0e, $0e, $00, $00, $e0, $e0
                        .byte $00, $0e, $0e, $0e, $00, $00, $ee, $ee

                        .byte $00, $e0, $e0, $e0, $00, $00, $00, $00
                        .byte $00, $e0, $e0, $e0, $00, $00, $0e, $0e
                        .byte $00, $e0, $e0, $e0, $00, $00, $e0, $e0
                        .byte $00, $e0, $e0, $e0, $00, $00, $ee, $ee

                        .byte $00, $ee, $ee, $ee, $00, $00, $00, $00
                        .byte $00, $ee, $ee, $ee, $00, $00, $0e, $0e
                        .byte $00, $ee, $ee, $ee, $00, $00, $e0, $e0
                        .byte $00, $ee, $ee, $ee, $00, $00, $ee, $ee



                        .byte $00, $00, $00, $00, $00, $00, $00, $00
                        .byte $00, $00, $00, $00, $00, $00, $00, $0e
                        .byte $00, $00, $00, $00, $00, $00, $00, $e0
                        .byte $00, $00, $00, $00, $00, $00, $00, $ee

                        .byte $00, $00, $0e, $0e, $00, $00, $00, $00
                        .byte $00, $00, $0e, $0e, $00, $00, $00, $0e
                        .byte $00, $00, $0e, $0e, $00, $00, $00, $e0
                        .byte $00, $00, $0e, $0e, $00, $00, $00, $ee

                        .byte $00, $00, $e0, $e0, $00, $00, $00, $00
                        .byte $00, $00, $e0, $e0, $00, $00, $00, $0e
                        .byte $00, $00, $e0, $e0, $00, $00, $00, $e0
                        .byte $00, $00, $e0, $e0, $00, $00, $00, $ee

                        .byte $00, $00, $ee, $ee, $00, $00, $00, $00
                        .byte $00, $00, $ee, $ee, $00, $00, $00, $0e
                        .byte $00, $00, $ee, $ee, $00, $00, $00, $e0
                        .byte $00, $00, $ee, $ee, $00, $00, $00, $ee


                        .byte $00, $00, $00, $00, $00, $00, $00, $00
                        .byte $00, $00, $00, $00, $00, $00, $00, $04
                        .byte $00, $00, $00, $00, $00, $00, $00, $40
                        .byte $00, $00, $00, $00, $00, $00, $00, $44

                        .byte $00, $00, $00, $00, $0e, $00, $00, $00
                        .byte $00, $00, $00, $00, $0e, $00, $00, $04
                        .byte $00, $00, $00, $00, $0e, $00, $00, $40
                        .byte $00, $00, $00, $00, $0e, $00, $00, $44

                        .byte $00, $00, $00, $00, $e0, $00, $00, $00
                        .byte $00, $00, $00, $00, $e0, $00, $00, $04
                        .byte $00, $00, $00, $00, $e0, $00, $00, $40
                        .byte $00, $00, $00, $00, $e0, $00, $00, $44

                        .byte $00, $00, $00, $00, $ee, $00, $00, $00
                        .byte $00, $00, $00, $00, $ee, $00, $00, $04
                        .byte $00, $00, $00, $00, $ee, $00, $00, $40
                        .byte $00, $00, $00, $00, $ee, $00, $00, $44


  
font_swap_1:  
    .fill $40, i
    .byte $40, $44, $48, $4c,   $41, $45, $49, $4d
    .byte $42, $46, $4a, $4e,   $43, $47, $4b, $4f

font_swap_2:  
    .fill $40, i
    .byte $50, $54, $58, $5c,   $51, $55, $59, $5d
    .byte $52, $56, $5a, $5e,   $53, $57, $5b, $5f

font_swap_3:  
    .fill $40, i
    .byte $60, $64, $68, $6c,   $61, $65, $69, $6d
    .byte $62, $66, $6a, $6e,   $63, $67, $6b, $6f

font_swap_4:  
    .fill $40, i
    .byte $70, $74, $78, $7c,   $71, $75, $79, $7d
    .byte $72, $76, $7a, $7e,   $73, $77, $7b, $7f


*=$0900

.align $100
raster_data:
    .fill 256, 0

barPos: 
    .fill nBars, 12*i

.align $100
sinTable: 
    .fill 256, 26.0 + 15.0*sin(toRadians(i*360/128)) // Generates a sine curve

raster_color_swap:
col_raster_color_swap:
    .byte 6, 1, 2, 3, 4, 5
    .byte 6, 7, 8, 9, 10, 11
    .byte 12, 13, 14, 15
// grey_raster_color_swap:
//     .byte 6, 11, 11, 15, 12, 12
//     .byte 11, 15, 12, 11, 12, 11
//     .byte 12, 15, 12, 15


.align $100
copyTable:
   .fill 64, 48-4*log(1+i)/log(2)


.align $100
barTable:

    .byte $B, $C, $F, $F, $1, $1, $F, $F, $C, $B
    .byte $2, $8, $A, $7, $1, $1, $7, $A, $8, $2
    .byte $6, $E, $3, $D, $1, $1, $D, $3, $E, $6
    .byte $B, $5, $7, $D, $1, $1, $D, $7, $5, $B


.align $100 
logoRaster:
    .byte $2, $A, $7, $7, $1, $1, $1, $7, $7, $A, $2, 0, 0, 0, 0, 0
    .byte $B, $C, $F, $F, $1, $1, $1, $F, $F, $C, $B, 0, 0, 0, 0, 0
    .byte $6, $E, $3, $3, $1, $1, $1, $3, $3, $E, $6, 0, 0, 0, 0, 0
    .byte $9, $8, $7, $7, $1 ,$1, $1, $7, $7, $8, $9, 0, 0, 0, 0, 0
    .byte $B, $5, $7, $D, $1 ,$1, $1, $D, $7, $5, $B, 0, 0, 0, 0, 0
    
    .byte $2, $A, $7, $7, $1, $1, $1, $7, $7, $A, $2, 0, 0, 0, 0, 0
    .byte $B, $C, $F, $F, $1, $1, $1, $F, $F, $C, $B, 0, 0, 0, 0, 0


* = $1b00 

.align $100
waterSinus:
   .byte 3,3,2,2,1,1,1,1,1,1,1,2,2,3,3,3
   .byte 4,4,4,4,4,4,3,3,3,2,2,1,1,1,0,0
   .byte 0,0,0,0,1,1,1,2,2,3,3,3,3,3,3,3
   .byte 3,2,2,1,1,0,0,0,0,0,0,0,0,0,1,1
   .byte 1,2,2,3,3,3,3,3,3,3,2,2,2,1,1,0
   .byte 0,0,0,0,0,0,0,1,1,1,2,2,3,3,3,3
   .byte 4,3,3,3,3,2,2,2,1,1,1,1,0,1,1,1
   .byte 1,2,2,3,3,3,4,4,4,4,4,4,4,4,4,3
   .byte 3,2,2,2,2,2,2,2,2,2,3,3,3,4,4,5
   .byte 5,5,5,6,5,5,5,5,4,4,4,3,3,3,3,2
   .byte 3,3,3,3,4,4,5,5,5,6,6,6,6,6,6,6
   .byte 6,5,5,4,4,4,3,3,3,3,3,3,3,4,4,5
   .byte 5,5,6,6,6,6,6,6,6,6,6,5,5,4,4,3
   .byte 3,3,3,3,3,3,3,4,4,5,5,5,6,6,6,6
   .byte 6,6,5,5,5,4,4,3,3,3,2,2,2,2,2,2
   .byte 3,3,3,4,4,5,5,5,5,5,5,5,4,4,3,3
   .byte 3,3,2,2,1,1,1,1,1,1,1,2,2,3,3,3
   .byte 4,4,4,4,4,4,3,3,3,2,2,1,1,1,0,0
   .byte 0,0,0,0,1,1,1,2,2,3,3,3,3,3,3,3
   .byte 3,2,2,1,1,0,0,0,0,0,0,0,0,0,1,1
   .byte 1,2,2,3,3,3,3,3,3,3,2,2,2,1,1,0
   .byte 0,0,0,0,0,0,0,1,1,1,2,2,3,3,3,3
   .byte 4,3,3,3,3,2,2,2,1,1,1,1,0,1,1,1
   .byte 1,2,2,3,3,3,4,4,4,4,4,4,4,4,4,3
   .byte 3,2,2,2,2,2,2,2,2,2,3,3,3,4,4,5
   .byte 5,5,5,6,5,5,5,5,4,4,4,3,3,3,3,2
   .byte 3,3,3,3,4,4,5,5,5,6,6,6,6,6,6,6
   .byte 6,5,5,4,4,4,3,3,3,3,3,3,3,4,4,5
   .byte 5,5,6,6,6,6,6,6,6,6,6,5,5,4,4,3
   .byte 3,3,3,3,3,3,3,4,4,5,5,5,6,6,6,6
   .byte 6,6,5,5,5,4,4,3,3,3,2,2,2,2,2,2
   .byte 3,3,3,4,4,5,5,5,5,5,5,5,4,4,3,3
waterSinusPos:
   .byte 0

// 
