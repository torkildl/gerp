			include "./includes/debug-macros.i"
			include	"./includes/hardware/custom-uppercase.i"
			include	"./includes/hardware/custom.i"
			include	"./includes/hardware/blitbits.i"
			include	"./includes/hardware/dmabits.i"
			include	"./includes/hardware/intbits.i"
			include "./includes/miniwrapper.asm"

Demo:
			; clear interrupt requests for level 3
			* install new copperlist and level 3 handler
			; lea		metacube_basecopper,a0
			; bsr		copperInstall
			; lea.l		$dff000,a6
			move.w	#INTF_INTEN|INTF_VERTB,INTENA(a6)
			lea.l		gerp_level3, a0
			move.l 	a0,$6c(a4)							* now we have new handler
			move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITHOG|DMAF_COPPER|DMAF_RASTER|DMAF_BLITTER,DMACON(a6)	; BLT,COP,BPL
			*			bsr		WaitBlitter
			*		     bsr		pollVSync
			move.w	#INTF_SETCLR|INTF_INTEN|INTF_VERTB,INTENA(a6)	;interruption vbl and coper

			* 		Music starts, demo starts
			lea.l   	Samples,a1
			lea.l   	Scores,a0
			sub.l   	a2,a2         * VBR...
			moveq   	#0,d0
			jsr		LSP_MusicDriver_CIA_Start
			* 		Introduce the demo with a logo
			bsr		gerp_logosegment
			bsr		metacube_init
			* 		Run the main effect, the metacube
.loopit
			bsr		pollVSync
			bsr		metacube_updateframe
			btst	#6,$bfe001
			bne.s	.loopit

			* 	Exit the demo
			jsr    	LSP_MusicDriver_CIA_Stop
			moveq		#0,d0
			rts


gerp_level3:
	movem.l	d0-d7/a0-a6,-(a7)
	lea	CUSTOM,a5
	move.w	INTREQR(a5),d0
	btst	#INTB_BLIT,d0
	bne.s	.blitter
	btst	#INTB_VERTB,d0
	bne.s	.vertb
	btst	#INTB_COPER,d0
	bne.s	.copper
	bra	.exit

.blitter:
; Do stuff here when Blit done
	move.w	#(INTF_INTEN!INTF_BLIT),INTREQ(a5)
	move.w	#(INTF_INTEN!INTF_BLIT),INTREQ(a5)
	bra.s	.exit

.vertb:
; Do stuff here in VBL
	move.w	#(INTF_INTEN!INTF_VERTB),INTREQ(a5)
	move.w	#(INTF_INTEN!INTF_VERTB),INTREQ(a5)
	bra.s	.exit

.copper:
; Do stuff here on Copper Int.
	move.w 	#1,gerp_sync
	add.w 	#1,gerp_lvl3cnt
	move.w	#(INTF_INTEN!INTF_COPER),INTREQ(a5)
	move.w	#(INTF_INTEN!INTF_COPER),INTREQ(a5)

.exit:
	movem.l	(a7)+,d0-d7/a0-a6
therte:
.rmb
			btst #2,$dff016
			beq.s .rmb
	rte


pollVSync:	btst	#0,$dff005
			beq.s	pollVSync
.wdown:
		  	btst	#0,$dff005
			bne.s	.wdown
			rts

copperInstall:
			move.w	#(1<<7),$dff096		; swith OFF copper DMA
			move.l	a0,$dff080
			move.w	#($8000|(1<<7)),$dff096
			rts



; WaitBlitter:
; blitterWait:
; arosWaitBlitter:
; 		* Blitter nasty set? Also simultaneous original DIP Agnus bug workaround. */
;     btst #2,$dff002
;     bne.s .w1
;
;     * Already finished? Exit immediately. */
;     btst #6,$dff002
;     beq.s .w0
;
;     * Set blitter nasty temporarily. */
;     move.w #$8400,$dff096
; .w2: * Keep CPU out of the chipbus for few cycles. */
;     tst.b $bfe001
;     btst #6,$dff002
;     bne.s .w2
;     * Clear blitter nasty. */
;     move.w #$0400,$dff096
;
; .w0:
; 		rts
;
;     * Blitter nasty was already set, normal wait loop. */
; .w1: btst #6,$dff002
;     beq.s .w0
;     * Keep CPU out of the chipbus for few cycles. */
;     tst.b $bfe001
;     bra.s .w1


					cnop	0,4
					dc.b "INTS"
gerp_sync:				dc.w	0
gerp_lvl3cnt			dc.w 	0
gerp_endframe:			dc.w	0

****
****
****
METACUBE_BPLWIDTH = 320 + 64 + 64
METACUBE_BPLWIDTH_BTS = METACUBE_BPLWIDTH/8
METACUBE_BPLHEIGHT = 256+64
METACUBE_BPLSIZE = (METACUBE_BPLWIDTH*METACUBE_BPLHEIGHT)/8
METACUBE_BPLDEPTH = 2
METACUBE_SCREEN_SIZE= METACUBE_BPLSIZE*METACUBE_BPLDEPTH
METACUBE_SCREEN_MODULO = (1*METACUBE_BPLWIDTH_BTS) + 8 + 8
METACUBE_MIRROR_MODULO = -(2*METACUBE_BPLWIDTH_BTS) - METACUBE_BPLWIDTH_BTS*2
VIEWSCR = 0
DRAWSCR = 4
CLEARSCR = 8
METACUBE_BACKCOL = $377
METACUBE_FRONTCOL = $323
SCROLLMAP_WIDTH = 8192
SCROLLMAP_HEIGHT = 16
SCROLLMAP_MODULO = (SCROLLMAP_WIDTH/8)-(320/8)

CUBESCREEN_H = 160
CUBWSCREEN_W = 176

*** METACUBE CODE
metacube_framecount:	dc.w	0


gerp_logosegment:
			bsr 		gerp_fadeinlogo
			move.w	#50,d0
			bsr		gerp_waitframes
			bsr		gerp_fadeoutlogo
			rts

gerp_waitframes:
gerp_fadeinlogo:
gerp_fadeoutlogo:
			rts


* the metacube

metacube_init:
			bsr	metacube_generaternds
			lea.l basecopsprites,a0
			bsr		clearsprites
			lea.l cop1sprites,a0
			bsr		clearsprites
			lea.l cop2sprites,a0
			bsr		clearsprites

			lea.l		metacube_font,a0
			move.w 	#"'",d0
			lsl.w		#6,d0
			lea.l		(a0,d0.w),a1
			move.l	#%0110000000000000000000000000,(a1)+
			move.l	#%0110000000000000000000000000,(a1)+
			move.l	#%0010000000000000000000000000,(a1)+
			move.l	#$0000,(a0)+

			move.w 	#'"',d0
			lsl.w		#6,d0
			lea.l		(a0,d0.w),a1
			move.l	#%1101100000000000000000000000,(a1)+
			move.l	#%1101100000000000000000000000,(a1)+
			move.l	#%11011000000000000000000000000,(a1)+
			move.l	#$0000,(a0)+

*			THLTEST
			move.w	#'W',d0
			lsl.w		#6,d0
			lea.l		(a0,d0.w),a1
			move.l	a1,a3

			move.w	#'V',d1
			lsl.w		#6,d1
			lea.l		(a0,d1.w),a2
			rept 16
				move.l	(a1)+,(a2)+
			endr

			* New capital W
			move.l	#%0000000000000000000000000000,(a3)+
			move.l	#%1101101100000000000000000000,(a3)+
			move.l	#%1101101100000000000000000000,(a3)+
			move.l	#%1101101100000000000000000000,(a3)+
			move.l	#%1101101100000000000000000000,(a3)+
			move.l	#%1101101100000000000000000000,(a3)+
			move.l	#%1101101100000000000000000000,(a3)+
			move.l	#%1101101100000000000000000000,(a3)+
			move.l	#%1101011100000000000000000000,(a3)+
			move.l	#%0111011000000000000000000000,(a3)+
			move.l	#%0000000000000000000000000000,(a3)+
			move.l	#%0000000000000000000000000000,(a3)+
			move.l	#%0000000000000000000000000000,(a3)+
			move.l	#%0000000000000000000000000000,(a3)+
			move.l	#%0000000000000000000000000000,(a3)+
			move.l	#%0000000000000000000000000000,(a3)+

			bsr 	metacube_preparecoppers
			*THLTEST
			bsr	metacube_makescroller

			* create background: 128pix maximum on 64byte lines
			* shrink logo image(s): from 160px to 128? px
			* shrink cubeframes from 64 to less
			* patch tables with pointers to actual graphics?
			rts

metacube_updateframe:


			* render main cube contents here.
			lea.l		cubeprecalc,a0
			lea.l		metacube_copperptrs,a1
			move.l	DRAWSCR(a1),a1
			lea.l		cop1cubelines-cop1start(a1),a1		* the copper cubelines
			lea.l		triangle,a2									* the triangle

			* check if anything to do
			cmp.b		#$ff,(a0)
			beq.s		.quitthis
			* CLEAR THE PRECEEDING LINES
			moveq		#0,d7
			move.b	(a0)+,d7				* number of lines to draw on this face (facelines)
			subq		#1,d7
			moveq	#0,d0
			move.b	(a0)+,d0
			subq		#1,d0
			move.w	#$0200,d1
.clearline
			move.w	d1,6(a1)
			lea.l		52(a1),a1
			dbf			d0,.clearline

.nextline
			moveq		#0,d1
			move.b	(a0)+, d1				* width
			move.b	(a0)+, d2				* texture line
			and.w		#$00fe,d1
			lsl.w		#4,d1
			add.l		a2,d1
			move.w	d1,14(a1)
			swap		d1
			move.w	d1,10(a1)

			cmp.b		#31,d2
			bgt.s		.notlogo
			move.w	#$1200,6(a1)
			bra			.checkend
.notlogo
			cmp.b		#95,d2
			bgt.s		.notcube
			move.w	#$1200,6(a1)
			bra			.checkend
.notcube
			* blah blah scroller
			move.w	#$1200,6(a1)
			bra			.checkend
.checkend
			lea.l		52(a1),a1
.quitthis
			dbf		d7,.nextline

			THLTEST
			move.w	#CUBESCREEN_H+$70,d3
			move.w	#$0200,d5
.skipmore
			move.b	(a1),d4
			cmp.b		d3,d4
			beq.s		.nomoreskip
			move.w	d5,6(a1)
			lea.l		52(a1),a1
			move.b	(a1),d4
			cmp.b		d3,d4
			beq.s		.nomoreskip
			bra.s		.skipmore
.nomoreskip

			* move cubes across z-axis and x-axis
			* identify rotation and animation state
			* prioritize playfields
			* per cube, plot bplptrs and cols for all lines

			* Move to moving and rendering main screen
			bsr		metacube_scrollscroller
			bsr		metacube_switchscreen			* change pointers to newly drawn screen
			rts


metacube_generaternds:
					lea.l	metacube_noise,a0
					move.w #1023,d7
.nextrnd
					bsr		cubism_rnd
					move.l	d0,(a0)+  * save rnd
					dbf 		d7,.nextrnd
					rts

cubism_rnd:
				moveq	#4,d2		* do this 5 times
				move.l	.prng32,d0	* get current
.ninc0	moveq	#0,d1		* clear bit count
				ror.l	#2,d0		* bit 31 -> carry
				bcc	.ninc1		* skip increment if =0
				addq.b	#1,d1		* else increment bit count
.ninc1	ror.l	#3,d0		* bit 28 -> carry
				bcc	.ninc2		* skip increment if =0
				addq.b	#1,d1		* else increment bit count
.ninc2	rol.l	#5,d0		* restore prng longword
				roxr.b	#1,d1		* eor bit into xb
				roxr.l	#1,d0		* shift bit to most significant
				dbf	d2,.ninc0	* loop 5 times

				move.l	d0,.prng32	* save back to seed word
				rts
.prng32				dc.l	$3490834f


metacube_preparecoppers:
			lea.l 	metacube_copperptrs,a0
			move.w 	#2-1,d7					* # of copperlists

.nulist
			move.l 	(a0)+,a1					* copperptr of this round

			lea.l 	metacube_logo,a3
			lea.l 	cop1logobplptrs-cop1start(a1),a2 	* skip other instrutions
			move.l 	a3,d1		* get logo base
			move.l	#40,d2	* linewidth for logo
			move.w 	#4-1,d6	* four bplptrs in logo
.logoplane
			move.w 	d1,6(a2)
			swap 		d1
			move.w 	d1,2(a2)
			swap 		d1
			add.l 	d2,d1
			lea.l 	8(a2),a2
			dbf 		d6,.logoplane

			lea.l 	metacube_logopalette,a4
			lea.l		2+cop1logopalette-cop1start(a1),a2
			move.w	#16-1,d6
.nucol		move.w	(a4)+, (a2)
			lea.l		4(a2),a2
			dbf		d6,.nucol

			move.l	cubelines_ptr,d0
			swap		d0
			lea.l		2+cop1cubectrl-cop1start(a1),a2
			move.w	d0,(a2)
			move.w	d0,4(a2)

			swap		d0
			lea.l		10+cop1cubelines-cop1start(a1),a2
			move.w	#CUBESCREEN_H-1,d6
.nuline
			move.w	d0,(a2)
			move.w	d0,4(a2)
			lea.l  	44(a2),a2
			dbf			d6,.nuline

			dbf 		d7,.nulist
			rts


* Write the 1024 characters to the scroll map
* For each character, place it on the scroller bitmap
* The bitmap has room for 8px per character (but will take far less).
* Modulo for the

metacube_makescroller:
			lea.l		scrollerbitmaps,a0	* destination bitmap
			add.l		#SCROLLMAP_WIDTH/8,a0
			lea.l       scrolltext,a1		* scrolltext
			lea.l		scrolltab,a2		* table of widths
			lea.l		metacube_font,a3		* font, vertical, 8x16 (16pix wide bmap)
			lea.l		CUSTOM,a6

			lea.l		scrolltext_end,a5

			move.w	#SCROLLMAP_WIDTH/8,d5	* width of scrollmap in bytes
			sub.w		#4,d5				* subtract width of blit to get C/D modulo

			move.l	#$00000fca, d7
			move.l		#350,d0				* counter for xposition in dest bitmap


.newchar

			moveq		#0,d1
			move.b	(a1)+,d1			* the character
			move.w	d1,d2
			lsl.w		#6,d2				* mul bitmap size
			lea.l		(a3,d2.w),a4		* the character bitmap

			moveq		#0,d2
			move.w	d0,d2				* xpos in px
			move.w	d2,d3				* save
			lsr.w		#4,d2				* in words
			add.w		d2,d2				* address offset for destination
			add.l		a0,d2				* add base address

			and.w		#$f,d3			* remaining 0-15 of the destination xpos
			ror.w		#4,d3
			move.l 	d7,d6
			or.w		d3,d6				* bltcon1 shift
			swap		d6
			or.w		d3,d6				* bltcon0 shift

			bsr		WaitBlitter
			move.l	d6, BLTCON0(a6)
			move.l	a4, BLTAPTH(a6)
			move.l	a4, BLTBPTH(a6)
			move.l	d2, BLTCPTH(a6)
			move.l	d2, BLTDPTH(a6)
			move.l	#$ffffffff,BLTAFWM(a6)
			move.w	#0, BLTAMOD(a6)
			move.w	#0, BLTBMOD(a6)
			move.w	d5, BLTCMOD(a6)
			move.w	d5, BLTDMOD(a6)
			move.w	#(16*64)+2, BLTSIZE(a6)

*			THLTEST
			moveq		#0,d6
			move.b 	(a2,d1.w),d6
			add.l		d6,d0

			cmp.l		a5, a1
			blt.s		.newchar

			rts

metacube_scrollscroller:
			lea.l		metacube_copperptrs,a0
			move.l	DRAWSCR(a0),a0
			lea.l		2+cop1scroll-cop1start(a0),a1
			lea.l 	scrollpos(pc),a2
			move.l	#scrollerbitmaps,d0

			moveq		#0,d1
			move.w	(a2),d1
			add.w		2(a2),d1
			move.w	d1,(a2)
			and.w		#$7fff,d1

			move.l	d1,d4			* save for other bitplanes
			addq		#1,d4			* the other bpl pos

			move.l	d1,d2
			and.w		#$f,d1
			move.w	#15,d3
			sub.w		d1,d3
			move.w	d3,d5			* scrollreg for even

			lsr.l		#4,d2
			add.w		d2,d2
			add.l		d0,d2			* bitplane ptr for even
			add.l	#SCROLLMAP_WIDTH/8,d2


*			move.l	d4,d1
*			and.w		#$f,d1
*			move.w	#15,d3
*			sub.w		d1,d3
*			rol.w		#4,d3
*			or.w		d3,d5

*			lsr.l		#4,d4
*			add.w		d4,d4
*			add.l		d0,d4

			* save scrollreg
			move.w	d5,(a1)

			* first bitplane
			lea.l		4(a1),a1
			move.w	d2,4(a1)
			swap		d2
			move.w	d2,(a1)

			* noise
			lea.l		8(a1),a1
			move.l	#metacube_noise,d4
			and.w		#$ffe,d1
			add.l		d1,d4

			move.w	d4,4(a1)
			swap		d4
			move.w	d4,(a1)

			rts

scrollpos:		dc.w  	0
scrollspeed:	dc.w		1
;--------------------------------------------------------------------
			;sets all sprites in the given copperlist
			;a0 - pointer to a setspriteblock for 8 sprites inside a copperlist (dc.l $01200000,...,$013e0000)
			;a1 - pointer to pointerlist of 8 sprites
			;destroys: d0-d7/a0-a1
			; setsprites:
clearsprites:
		lea		fw_spritetab,a1
		addq.l	#2,a0
		movem.l	(a1),d0-d7
		move.w	d0,$04(a0)
		swap	d0
		move.w	d0,(a0)
		move.w	d1,$0c(a0)
		swap	d1
		move.w	d1,$08(a0)
		move.w	d2,$14(a0)
		swap	d2
		move.w	d2,$10(a0)
		move.w	d3,$1c(a0)
		swap	d3
		move.w	d3,$18(a0)
		move.w	d4,$24(a0)
		swap	d4
		move.w	d4,$20(a0)
		move.w	d5,$2c(a0)
		swap	d5
		move.w	d5,$28(a0)
		move.w	d6,$34(a0)
		swap	d6
		move.w	d6,$30(a0)
		move.w	d7,$3c(a0)
		swap	d7
		move.w	d7,$38(a0)
		rts



		MACRO SWITCHSCREEN
		move.l VIEWSCR(a0), d0
		move.l DRAWSCR(a0), d1
		move.l d1,VIEWSCR(a0)
		move.l d0,DRAWSCR(a0)
		ENDM


metacube_switchscreen:

		lea.l metacube_screenptrs, a0
		SWITCHSCREEN
		lea.l metacube_copperptrs, a0
		SWITCHSCREEN

		bsr WaitBlitter
		lea.l metacube_copperptrs,a0
		move.l VIEWSCR(a0), a0				* move the new VIEWscreen-copperlist
		bsr copperInstall
		rts

			section replayer, code

	    include "includes/LSP/LightSpeedPlayer_cia.asm"
	    include "includes/LSP/LightSpeedPlayer.asm"

			section "metacube_data",data

												cnop 0,4
maincubetab:						blk.l	CUBESCREEN_H,0

exitflag:								dc.w 0
fw_spritetab:						dc.l	$00000000,$00000000,$00000000,$00000000
												dc.l	$00000000,$00000000,$00000000,$00000000
metacube_bplwtab:
y set 0
												rept METACUBE_BPLHEIGHT
													dc.l (METACUBE_BPLWIDTH_BTS*METACUBE_BPLDEPTH)*y
y set y + 1
												endr
metacube_demoframe: 		dc.l 0
metacube_palette: 			dc.w $0377,$0f46,$647,$faa,$fff,$fff,$fff,$fff
metacube_copperptrs:  	dc.l metacube_copperlist1, metacube_copperlist2
metacube_screenptrs:  	dc.l 0,0 * metacube_screen1, metacube_screen2
Scores:  			     			incbin "./assets/mod.lsmusic"
												cnop 0,4
textcounter:						dc.w 0
scrolltab: 							incbin "./assets/fontspec.dat"    *blk.w  256,7
metacube_scrollcounter: dc.w 0
main_scrollcounter:			dc.w 0
scrolltext:							incbin "./assets/scrolltext.txt"
												even
scrolltext_end:
cubelines_ptr						dc.l 0
cubeprecalc:						incbin "./assets/rotlist.dat"
testcube:								dc.w 1, 1, -64, 160, 64, 160,0		* one surface, flat

			section "metacube_chipdata", data_c

Samples:      incbin "./assets/mod.lsbank"
metacube_emptysprite: dc.l 0


* BPL 1: Small cube
* BPL 2: Tiny cube
* BPL 3-5: Logos


metacube_basecopper:
			dc.l	$008e1b51,$009037d1  ;window start, window stop,
			dc.l	$01000200,$01020000						;bplcon mode, scroll values
			dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem
basecopsprites:
			dc.l	$01200000,$01220000
			dc.l	$01240000,$01260000
			dc.l	$01280000,$012a0000
			dc.l	$012c0000,$012e0000
			dc.l	$01300000,$01320000
			dc.l	$01340000,$01340000
			dc.l	$01380000,$01380000
			dc.l	$013c0000,$013c0000
			dc.l	$01800000+METACUBE_BACKCOL
			dc.l	$fffffffe	; end coplist

			MACRO COPPERCONTENTS
cop\1start
			dc.l	$008e1181,$009033c1  ;window start, window stop,
			dc.l  $00920038,$009400d0	;bitplane start, bitplane stop
			dc.l	$01060000,$01fc0000						;fixes the aga modulo problem
cop\1sprites:
			dc.l	$01200000,$01220000
			dc.l	$01240000,$01260000
			dc.l	$01280000,$012a0000
			dc.l	$012c0000,$012e0000
			dc.l	$01300000,$01320000
			dc.l	$01340000,$01340000
			dc.l	$01380000,$01380000
			dc.l	$013c0000,$013c0000
cop\1bplcon
			dc.l	$01000200,$01020000						;bplcon mode, scroll
			dc.l	$01040000
cop\1modulo
    	dc.w  $0108,$0000+(40*3)
			dc.w  $010a,$0000+(40*3)
cop\1logopalette:
			dc.w  $0180,$0325
			dc.w  $0182,$0325
			dc.w  $0184,$0325
			dc.w  $0186,$0325
			dc.w  $0188,$0325
			dc.w  $018a,$0325
			dc.w  $018c,$0325
			dc.w  $018e,$0325
			dc.w  $0190,$0325
			dc.w  $0192,$0325
			dc.w  $0194,$0325
			dc.w  $0196,$0325
			dc.w  $0198,$0325
			dc.w  $019a,$0325
			dc.w  $019c,$0325
			dc.w  $019e,$0325
cop\1logobplptrs:
			dc.l  $00e00000,$00e20000
			dc.l  $00e40000,$00e60000
			dc.l  $00e80000,$00ea0000
			dc.l  $00ec0000,$00ee0000
			dc.w	$28df,$fffe,$0100,$4200
			dc.w  $68df,$fffe,$0100,$0200,$0108,$0000,$010a,$0000
			dc.w	$0092,$0048,$0094,$00c0
			* cube lines part
cop\1cubectrl
			dc.w	$00e0,$0000,$00e4,$0000
cop\1cubepalette
			dc.w  $0180,$0325, $0182,$0000, $0184,$0fff, $0186,$0f0f
			dc.w  $0188,$0325, $018a,$0325, $018c,$0325, $018e,$0325
			dc.w  $0190,$0325, $0192,$0325, $0194,$0325, $0196,$0325
			dc.w  $0198,$0325, $019a,$0325, $019c,$0325, $019e,$0325
			dc.w  $01a0,$0325, $01a2,$0325, $01a4,$0325, $01a6,$0325
			dc.w  $01a8,$0325, $01aa,$0325, $01ac,$0325, $01ae,$0325
			dc.w  $01b0,$0325, $01b2,$0325, $01b4,$0325, $01b6,$0325
			dc.w  $01b8,$0325, $01ba,$0325, $01bc,$0325, $01be,$0325
cop\1cubelines
y set 0
			rept  CUBESCREEN_H
				dc.b  ($70+y)&$ff,$df,$ff,$fe
				dc.w 	$0100,$1200								;8
				dc.w  $00e0,$0000,$00e2,$0000		; 16
				dc.w	$00e4,$0000,$00e6,$0000		;24
				dc.w  $00e8,$0000,$00ea,$0000		; 32
				dc.w	$00ec,$0000,$00ee,$0000		;40
				dc.w	$00f0,$0000,$00f2,$0000		;48
y set y+1
				dc.b  ($70+y)&$ff,$05,$ff,$fe		;52
			endr
			* scroller part
			dc.b  ($72+y+1)&$ff,$df,$ff,$fe
			dc.l  $01000200
			dc.w 	$0182,$0ccf,$0184,$0325,$0186,$077c
			dc.w 	$0092,$0030,$0094,$00d8
			dc.w  $0108,SCROLLMAP_MODULO-4,$010a,0
cop\1scroll		dc.w  $0102,$0000
			dc.w	$00e0,$0000,$00e2,$0000,$00e4,$0000,$00e6,$0000
			dc.w  $2305,$fffe,$0100,$2200
cop\1postscroll
			dc.w  $3305,$fffe,$0100,$0200
			dc.l	$fffffffe	; end coplist
			ENDM

metacube_copperlist1:		COPPERCONTENTS 1
metacube_copperlist2:		COPPERCONTENTS 2
metacube_logopalette:		incbin "./assets/logo.pal"
metacube_font:					incbin "./assets/font.raw"
metacube_logo:					incbin "./assets/logo.raw"
metacube_smalllogo:			incbin "./assets/logo_160.raw"
metacube_tinylogo:			incbin "./assets/logo_80.raw"
metacube_tinylogopalette:	incbin "./assets/logo_80.pal"
metacube_bplcon0:				dc.w $CAFE
triangle:								incbin "./assets/triangle.raw"

					section metacube_screens, bss_c

scrollerbitmaps:			ds.b  16*SCROLLMAP_WIDTH/8	* bitmap for scroller
smallscrollerbitmap:		ds.b  8*SCROLLMAP_WIDTH/8
tinyscrollerbitmap:		ds.b  4*SCROLLMAP_WIDTH/8
*cubelines:				ds.b  160*(160/8)
metacube_noise:			ds.b  4*1024
logo160_256:				ds.b	32*3*32*32		* 32 bytes a 3 planes a 32 lines a 32 shrinks
logo80_256:					ds.b	32*3*16*16		* 32 bytes a 3 planes a 16 lines a 16 shrinks
