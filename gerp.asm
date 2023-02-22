			incdir "./include/"
			include "debug-macros.i"
			include	"hardware/custom-uppercase.i"
			include	"hardware/custom.i"
			include	"hardware/blitbits.i"
			include	"hardware/dmabits.i"
			include	"hardware/intbits.i"
			include "support/debug.i"

	xdef _start
	xdef metacube_animframe
_start:	
	move.l 4.w,a6			;Exec library base address in a6
	sub.l a4,a4
	btst #0,297(a6)			;68000 CPU?
	beq.s .yes68k
	lea .GetVBR(PC),a5		;else fetch vector base address to a4:
	jsr -30(a6)			;enter Supervisor mode

    *--- save view+coppers ---*

.yes68k:lea .GfxLib(PC),a1		;either way return to here and open
	jsr -408(a6)			;graphics library
	tst.l d0			;if not OK,
	beq.s .quit			;exit program.
	move.l d0,a5			;a5=gfxbase

	move.l a5,a6
	move.l 34(a6),-(sp)
	sub.l a1,a1			;blank screen to trigger screen switch
	jsr -222(a6)			;on Amigas with graphics cards

    *--- save int+dma ---*

	lea $dff000,a6
	bsr.s WaitEOF			;wait out the current frame
	move.l $1c(a6),-(sp)		;save intena+intreq
	move.w 2(a6),-(sp)		;and dma
	move.l $6c(a4),-(sp)		;and also the VB int vector for sport.
	bsr.s AllOff			;turn off all interrupts+DMA

    *--- call demo ---*

	movem.l a4-a6,-(sp)
	bsr demo			;call our demo \o/
	movem.l (sp)+,a4-a6

    *--- restore all ---*

	bsr.s WaitEOF			;wait out the demo's last frame
	bsr.s AllOff			;turn off all interrupts+DMA
	move.l (sp)+,$6c(a4)		;restore VB vector
	move.l 38(a5),$80(a6)		;and copper pointers
	move.l 50(a5),$84(a6)
	addq.w #1,d2			;$7fff->$8000 = master enable bit
	or.w d2,(sp)
	move.w (sp)+,$96(a6)		;restore DMA
	or.w d2,(sp)
	move.w (sp)+,$9a(a6)		;restore interrupt mask
	or.w (sp)+,d2
	bsr.s IntReqD2			;restore interrupt requests

	move.l a5,a6
	move.l (sp)+,a1
	jsr -222(a6)			;restore OS screen

    *--- close lib+exit ---*

	move.l a6,a1			;close graphics library
	move.l 4.w,a6
	jsr -414(a6)
.quit:	moveq #0,d0			;clear error return code to OS
	rts				;back to AmigaDOS/Workbench.

.GetVBR:dc.w $4e7a,$c801		;hex for "movec VBR,a4"
	rte				;return from Supervisor mode

.GfxLib:dc.b "graphics.library",0,0

WaitEOF:				;wait for end of frame
	bsr.s WaitBlitter
	move.w #$138,d0
WaitRaster:				;Wait for scanline d0. Trashes d1.
.l:	move.l 4(a6),d1
	lsr.l #1,d1
	lsr.w #7,d1
	cmp.w d0,d1
	bne.s .l			;wait until it matches (eq)
	rts

AllOff:	move.w #$7fff,d2		;clear all bits
	move.w d2,$96(a6)		;in DMACON,
	move.w d2,$9a(a6)		;INTENA,
IntReqD2:
	move.w d2,$9c(a6)		;and INTREQ
	move.w d2,$9c(a6)		;twice for A4000 compatibility
	rts

WaitBlitter:				;wait until blitter is finished
	tst.w (a6)			;for compatibility with A1000
.loop:	btst #6,2(a6)
	bne.s .loop
	rts

demo:
			; clear interrupt requests for level 3
			* install new copperlist and level 3 handler
			; lea		metacube_basecopper,a0
			; bsr		copperInstall
			; lea.l		$dff000,a6
			move.w	#INTF_INTEN|INTF_VERTB,INTENA(a6)
			move.w	#INTF_INTEN|INTF_VERTB,INTREQ(a6)
			move.w	#INTF_INTEN|INTF_VERTB,INTREQ(a6)
			lea.l	gerp_level3,a0
			move.l 	a0,$6c(a4)							* now we have new handler
			move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER|DMAF_BLITTER,DMACON(a6)	; BLT,COP,BPL
			move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER|DMAF_BLITTER,DMACON(a6)	; BLT,COP,BPL
			bsr		WaitBlitter
			bsr		pollVSync
			move.w	#INTF_SETCLR|INTF_INTEN|INTF_VERTB,INTENA(a6)	;interruption vbl and coper

			* register some resources

			* 		Introduce the demo with a logo
			bsr		gerp_logosegment
			bsr		metacube_init
			lea.l	metacube_copperptrs,a0
			move.l	VIEWSCR(a0),a0
			bsr		copperInstall

			lea.l	scores,a0
			lea.l	lsbank,a1
			sub.l	a2,a2					* no VBR testing... :-(
			moveq	#0,d0
			*bsr		LSP_MusicDriver_CIA_Start

			* 		Run the main effect, the metacube
.loopit		
			debug_start_idle
			bsr		pollVSync
			debug_stop_idle

			bsr		metacube_democube
			bsr		metacube_switchscreen
			btst	#6,$bfe001
			bne.s	.loopit

			* fade out et cetere
			*bsr		LSP_MusicDriver_CIA_Stop

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
			move.w	#($8200|(1<<7)),$dff096
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
METACUBE_BPLWIDTH = 512
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

CUBESCREEN_H = 288
CUBWSCREEN_W = 64*8

*** METACUBE CODE
metacube_framecount:	dc.w	0


gerp_logosegment:
			bsr 	gerp_fadeinlogo
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


			bsr		metacube_allocmem	
			bsr		metacube_generaternds
			bsr		metacube_makextab
			lea.l 	basecopsprites,a0
			bsr		clearsprites
			lea.l 	cop1sprites,a0
			bsr		clearsprites
			lea.l 	cop2sprites,a0
			bsr		clearsprites
			bsr 	metacube_preparecoppers

			* create background: 128pix maximum on 64byte lines
			* shrink logo image(s): from 160px to 128? px
			* shrink cubeframes from 64 to less
			* patch tables with pointers to actual graphics?
			rts

metacube_allocmem:
			* allocate memory for all the bitmaps to be shown
			* triangle: 8k	
			lea.l	chipbuffer,a0

			move.l	a0,d0
			move.l	d0,d1

			and.l	#$ffff0000,d1
			add.l	#$10000,d1
			move.l	d1,triangle_ptr

			move.w	#(8192/4)-5,d7
			lea.l   triangle,a1
			move.l	d1,a2
			moveq	#0,d3
			move.l	d3,(a2)+		* this is just to shift the triangle to the right
			move.l	d3,(a2)+
			move.l	d3,(a2)+
			move.l	d3,(a2)+
.movetriangle
			move.l 	(a1)+,(a2)+
			dbf		d7,.movetriangle
			rts
			; 			lea.l	chipmem_allocations(pc),a1
; 			move.l	a0,d0
; 			move.l	d0,d1		* save start of chipbuffer

; .perallocation
; 			move.l	(a1)+,d3	* size of req chunk
; 			tst.l	d3
; 			beq.s	.doneallocs
			
; 			move.l	#$10000,d2
; 			sub.w	d1,d2		* bytes remaining in this 64k

; 			cmp.w	d3,d2
; 			blt.s 	

; 			and.l	#$ffff,d0
; 			add.l	#$10000,d0
; .doneallocs:
; 			rts

; chipmem_allocations:
; 			dc.l	8*1024,0	* triangle
; 			dc.l	4*1024,0	* noisebuffer
; 			dc.l	0
COPLINE_LEN = 20  * copwait in bytes
metademo_clearcop:
			* clear copper for bplptrs
			lea.l		metacube_copperptrs,a0
			move.l		DRAWSCR(a0),a0
			lea.l		cop1cubelines-cop1start(a0),a1		* the copper cubelines
			move.w		#CUBESCREEN_H-1,d7
.clrline	clr.w		6(a1)
			lea.l		COPLINE_LEN(a1),a1	
			dbf			d7,.clrline
			rts

*** This cube has a Talent demo on each face. 
*** 4 bitplanes active: 
*** Talent logo rescaled (takes all 4 bitplanes)
*** Some sinewavy stuff or other cube as main effect (double sinewave with color mixing?)
*** Scroller (not very tall, so can be rescaled with blitter on the fly, right shifts and left shifts)
*** Flat shading--> each face has own palette, does not change on each face
metacube_democube:
			bsr 		metademo_clearcop					* clear the copperlist (change to blitter)
			* move cubes across z-axis and x-axis
			* identify rotation and animation state
			* prioritize playfields
			* render main cube contents here.
			move.w		metacube_cube1xpos,d0
			add.w		#8,d0
			and.w		#$3fe,d0
			move.w		d0,metacube_cube1xpos
			lea.l		xpostab,a1
			move.w		(a1,d0.w),d7

			move.w		#125,d7


			
			lea.l		metacube_copperptrs,a0
			move.l		DRAWSCR(a0),a0

			move.w		metacube_animframe,d0
			add.w		#32,d0
			move.w		d0,metacube_animframe

			move.w		d0,d1
			* where on the cube
			lea.l		cube1_data,a3
			adda.l		#2,a3
			move.w		d7,d3
			and.w		#$f,d3
			lea.l		cop1cubectrl-cop1start(a0),a1		* the copper cubelines
			move.w		#15,d6
			sub.w		d3,d6
			move.w		d6,26(a1)
			lea.l		cop1cubelines-cop1start(a0),a0		* the copper cubelines
			lsr.w		#4,d7
			add.w		d7,d7					* x byteoffset for bplptrs
			move.w		(a3)+,d6				* y offset for coplist
			and.l		#$f000,d1
			rol.w		#6,d1
			and.w		#%1100,d1					* which side are we looking at, *4 for .l
			lea.l		(a3,d1.w),a3
			
			* where in the precalc
			lea.l		cubeprecalc,a2
			and.w		#%111111100000,d0		* get 0-127 mult 32 for correct face data
			lea.l		(a2,d0.w),a2			* ptr to face data


			* check if anything to do
			move.l		(a3)+,a1
			tst.w		(a2)
			blt.s		.noface1
			jsr			(a1)
.noface1	
			move.l		(a3)+,a1
			lea.l		16(a2),a2
			tst.w		(a2)
			blt.s		.noface2
			jsr			(a1)
.noface2
			* per cube, plot bplptrs and cols for all lines
			rts
metacube_cube1xpos:		dc.w 0	
			* cube data
			* xpos, ypos, xspeed, yspeed
			* ptrs to render functions for all four faces + extra fifth face

cube1_data:
			dc.w	0,40
			dc.l 	renderface_green, renderface_pink,renderface_red, renderface_blue, renderface_green


renderface_blue:
			move.w #$f,d5
			bra renderface
renderface_red:
			move.w #$f00,d5
			bra renderface
renderface_pink:
			move.w #$f0f,d5
			bra renderface
renderface_green:
			move.w #$0f0,d5
renderface:
			move.w		(a2),d0			* signed 16b height of face
			move.w		2(a2),d1			* top y of face
			add.w		d6,d1

			mulu		#COPLINE_LEN,d1		* calc to correct position in coplist
			lea.l		(a0,d1.w),a4		* move

			* now we are ready to poke the lines for the face
			moveq		#0,d1
			move.w		4(a2),d1	* start width
			move.w		6(a2),d2	* width gradient * 64
			move.w		8(a2),d4	* texture "gradient" * 64
.nextline
			* poke bplptrs in this line
			move.w	d1,d3			* width of current line
			and.w	#$ffc0,d3		* align 64 for bplwidth 64
			or.w	d7,d3
			move.w  d3,6(a4)		* write low ptr to triangle to copperlist
			move.w	d5,18(a4)		* set color

			* change width to next line
			add.w	d2,d1	

			* move to next line
			lea.l	COPLINE_LEN(a4),a4

			dbf		d0,.nextline
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

			move.l	triangle_ptr,d0
			swap	d0
			lea.l	2+cop1cubectrl-cop1start(a1),a2
			move.w	d0,(a2)
			move.w	d0,4(a2)

; 			swap	d0
; 			lea.l	10+cop1cubelines-cop1start(a1),a2
; 			move.w	#CUBESCREEN_H-1,d6
; .nuline
; 			move.w	d0,(a2)
; 			move.w	d0,4(a2)
; 			lea.l  	44(a2),a2
; 			dbf		d6,.nuline

 			dbf 	d7,.nulist
			rts


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
			move.l VIEWSCR(a0),d0
			move.l DRAWSCR(a0),d1
			move.l d1,VIEWSCR(a0)
			move.l d0,DRAWSCR(a0)
		ENDM


metacube_switchscreen:

		lea.l metacube_screenptrs,a0
		SWITCHSCREEN
		lea.l metacube_copperptrs,a0
		SWITCHSCREEN

		bsr WaitBlitter
		lea.l metacube_copperptrs,a1
		move.l VIEWSCR(a1),a0				* move the new VIEWscreen-copperlist
		bsr copperInstall
		rts

metacube_makextab:
		lea.l	sintab,a0
		lea.l	xpostab,a1
		move.w	#2048-1,d7
.nextval
		move.w	(a0)+,d0
		add.w	#$4000,d0
		asr.w	#8,d0
		move.w	d0,(a1)+
		dbf	d7,.nextval
		rts

metacube_choosecolumns:
		rts

metacube_blitlogo	




		include "./include/LSPlayer.h"

		section "metacube_data",data

							cnop 0,4
metacube_animframe: dc.w 0
scores:						incbin "./assets/mod.lsmusic"
maincubetab:				blk.l	CUBESCREEN_H,0
exitflag:					dc.w 0
fw_spritetab:				dc.l	$00000000,$00000000,$00000000,$00000000
							dc.l	$00000000,$00000000,$00000000,$00000000
metacube_bplwtab:
y set 0
							rept METACUBE_BPLHEIGHT
							dc.l (METACUBE_BPLWIDTH_BTS*METACUBE_BPLDEPTH)*y
y set y + 1
							endr
metacube_demoframe: 		dc.l 0
metacube_palette: 			dc.w $0377,$0f46,$647,$faa,$fff,$fff,$fff,$fff
metacube_copperptrs:  		dc.l metacube_copperlist1, metacube_copperlist2
metacube_screenptrs:  		dc.l 0,0 * metacube_screen1, metacube_screen2
							cnop 0,4
triangle:					incbin "./assets/triangle.raw"
triangle_ptr				dc.l triangle
cubeprecalc:				incbin "./assets/cubeframes.dat"
testcube:					dc.w 1, 1, -64, 160, 64, 160,0		* one surface, flat
sintab:						incbin "./assets/sintab.dat"
xpostab:					blk.w		2048,0

			section "metacube_chipdata", data_c

metacube_emptysprite: dc.l 0


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
			dc.l  	$00920030,$009400d8	;bitplane start, bitplane stop
			dc.l	$01060000,$01fc0000						;fixes the aga modulo problem
			dc.w	$0100,$0200
			dc.w	$0108,$0000,$010a,$0000
			dc.w	$0104,$0000
cop\1sprites:
			dc.l	$01200000,$01220000
			dc.l	$01240000,$01260000
			dc.l	$01280000,$012a0000
			dc.l	$012c0000,$012e0000
			dc.l	$01300000,$01320000
			dc.l	$01340000,$01340000
			dc.l	$01380000,$01380000
			dc.l	$013c0000,$013c0000
cop\1cubectrl
			dc.w	$00e0,$0000,$00e4,$0000
			dc.w	$00e8,$0000,$00ec,$0000
			dc.w	$00f0,$0000,$00f4,$0000
			dc.w	$0102,$0000,$0100,$6600		; bplcon1 + 2
			dc.w	$0180,$0415
cop\1cubelines
y set $12
			rept  CUBESCREEN_H
				dc.b    (y)&$ff,$df,$ff,$fe			; +4
				dc.w	$00e2,$0000		; +4 bpl1ptl
				dc.w  	$00ea,$0000		; +4 bpl3ptl
				dc.w	$00f2,$0000		; +4 
				dc.w	$0182,$0f0f		; farge 0, pl1
y set y+1
				dc.b  	(y)&$ff,$05,$ff,$fe		;48
			endr
cop\1linesend
			dc.l	$fffffffe	; end coplist
			ENDM


metacube_copperlist1:		COPPERCONTENTS 1
metacube_copperlist2:		COPPERCONTENTS 2
metacube_logopalette:		incbin "./assets/logo.pal"
metacube_logo:				incbin "./assets/logo.raw"
metacube_smalllogo:			incbin "./assets/logo_160.raw"
metacube_tinylogo:			incbin "./assets/logo_80.raw"
metacube_tinylogopalette:	incbin "./assets/logo_80.pal"
metacube_bplcon0:			dc.w $CAFE
lsbank: 					incbin "./assets/mod.lsbank"

			section metacube_screens, bss_c

metacube_noise:			blk.b  4*1024,0
logo160_256:			blk.b	32*3*32*32,0		* 32 bytes a 3 planes a 32 lines a 32 shrinks
logo80_256:				blk.b	32*3*16*16,0		* 32 bytes a 3 planes a 16 lines a 16 shrinks

chipbuffer:				blk.b	64*1024*3,0

; cop\1cubepalette
; 			dc.w  $0180,$0325, $0182,$0000, $0184,$0fff, $0186,$0f0f
; 			dc.w  $0188,$0325, $018a,$0325, $018c,$0325, $018e,$0325
; 			dc.w  $0190,$0325, $0192,$0325, $0194,$0325, $0196,$0325
; 			dc.w  $0198,$0325, $019a,$0325, $019c,$0325, $019e,$0325
; 			dc.w  $01a0,$0325, $01a2,$0325, $01a4,$0325, $01a6,$0325
; 			dc.w  $01a8,$0325, $01aa,$0325, $01ac,$0325, $01ae,$0325
; 			dc.w  $01b0,$0325, $01b2,$0325, $01b4,$0325, $01b6,$0325
; 			dc.w  $01b8,$0325, $01ba,$0325, $01bc,$0325, $01be,$0325
