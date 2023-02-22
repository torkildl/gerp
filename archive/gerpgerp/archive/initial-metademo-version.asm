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
			lea.l	$dff000,a6
			move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITHOG|DMAF_COPPER|DMAF_RASTER|DMAF_BLITTER,DMACON(a6)	; BLT,COP,BPL
			lea		metacube_basecopper,a0
			bsr		copperInstall
			lea.l	metacube_level3, a0
			move.l a0,$6c(a4)												* now we have new handler
			* unmark COPER level 3 interrupt
			bsr		WaitBlitter
      bsr		pollVSync


			lea.l 	CUSTOM,a6
			move.w	#INTF_SETCLR|INTF_INTEN|INTF_VERTB|INTF_COPER,$dff09a		;interruption vbl and coper

			bsr 		metacube_init
			lea.l   Samples,a1
			lea.l   Scores,a0
			sub.l   a2,a2         * VBR...
			moveq   #0,d0
			jsr			LSP_MusicDriver_CIA_Start
			lea.l 	metacube_copperptrs,a0
			move.l 	VIEWSCR(a0), a0				* move the new VIEWscreen-copperlist to d0
			bsr 		copperInstall

.mainloop
			bsr    pollVSync
			; tst.w		metademo_sync
			; beq.s 	.mainloop
			; clr.w		metademo_sync
			bsr			metacube_updateframe

			tst.w		exitflag
			bne.s		.leave
			bra			.mainloop
.leave
			jsr     LSP_MusicDriver_CIA_Stop

			moveq		#0,d0
			rts


metacube_level3:
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
	move.w #1,metacube_sync
	*clr.w metademo_debug
	add.w #1,metacube_lvl3cnt
*	bsr metademo_switchscreen
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
metacube_sync:					dc.w	0
metacube_lvl3cnt				dc.w 	0
metacube_endframe:			dc.w	0



metacube_init:
			rts

metacube_updateframe:
			rts



; ;--------------------------------------------------------------------
; ; normal display data fetch start/stop (without scrolling)
; METADEMO_BPLWIDTH = 320 + 64 + 64
; METADEMO_BPLWIDTH_BTS = METADEMO_BPLWIDTH/8
; METADEMO_BPLHEIGHT = 256+64
; METADEMO_BPLSIZE = (METADEMO_BPLWIDTH*METADEMO_BPLHEIGHT)/8
; METADEMO_BPLDEPTH = 2
; METADEMO_SCREEN_SIZE= METADEMO_BPLSIZE*METADEMO_BPLDEPTH
; METADEMO_SCREEN_MODULO = (1*METADEMO_BPLWIDTH_BTS) + 8 + 8
; METADEMO_MIRROR_MODULO = -(2*METADEMO_BPLWIDTH_BTS) - METADEMO_BPLWIDTH_BTS*2
; VIEWSCR = 0
; DRAWSCR = 4
; CLEARSCR = 8
; METADEMO_BACKCOL = $377
; METADEMO_FRONTCOL = $323
; METADEMO_COP_BPLPTRS = 8*7
; METADEMO_CANVAS_WIDTH = 80
; METADEMO_CANVAS_HEIGHT = 64
; METADEMO_CANVAS_SIZE = METADEMO_CANVAS_WIDTH*METADEMO_CANVAS_HEIGHT/8
; METADEMO_CANVAS_DEPTH = 2
; METADEMO_FRAME_SIZE = METADEMO_CANVAS_SIZE*METADEMO_CANVAS_DEPTH
; SCROLLMAP_WIDTH = 1024
; SCROLLMAP_WIDTH_BTS = SCROLLMAP_WIDTH/8
; SCROLLMAP_HEIGHT = 8
; SCROLLMAP_DEPTH = 1
; METADEMO_BOUNCE_SPEED = 1
;
; metademo_init:
; 			lea.l basecopsprites,a0
; 			bsr		clearsprites
; 			lea.l cop1sprites,a0
; 			bsr		clearsprites
; 			lea.l cop2sprites,a0
; 			bsr		clearsprites
; 			bsr 	metademo_preparecoppers
; 			bsr 	createlogomask
; 			bsr 	metademo_patchypatterns
; 			bsr 	metademo_pokeletters
;       rts
;
;
; metademo_pokeletters:
; 			lea.l	scrolltab,a0
; 			* i
; 			move.w	#'i',d0
; 			add.w		d0,d0
; 			lea.l		(a0,d0.w),a1
; 			move.w	#4,(a1)
;
; 			move.w	#'I',d0
; 			add.w		d0,d0
; 			lea.l		(a0,d0.w),a1
; 			move.w	#4,(a1)
;
; 			* i
; 			move.w	#'l',d0
; 			add.w		d0,d0
; 			lea.l		(a0,d0.w),a1
; 			move.w	#4,(a1)
;
; 			* i
; 			move.w	#'T',d0
; 			add.w		d0,d0
; 			lea.l		(a0,d0.w),a1
; 			move.w	#6,(a1)
;
; 			* i
; 			move.w	#"'",d0
; 			add.w		d0,d0
; 			lea.l		(a0,d0.w),a1
; 			move.w	#3,(a1)
;
; 			* i
; 			move.w	#"",d0
; 			add.w		d0,d0
; 			lea.l		(a0,d0.w),a1
; 			move.w	#3,(a1)
; 			rts
;
; metademo_patchypatterns:
; 			lea.l metademo_ypatterns,a0
; 			lea.l metademo_ypatterns_end,a1
; 			move.w #188,d0
; .loop
; 			move.w d0,d1
; 			sub.w (a0),d1
; 			lsl.w	#2,d1					* for pixel precision
; 			move.w d1,(a0)+
; 			cmp.l a0,a1
; 			bne.s .loop
; 			rts
;
; createlogomask:
; 			lea.l		metademo_vertlogoraw,a2
; 			lea.l 	metademo_vertlogo,a0
; 			lea.l 	metademo_vertlogomask,a1
; 			move.w 	#METADEMO_CANVAS_HEIGHT-1,d7
; 			moveq		#0,d1
; .line
; 			move.w 	(a2)+,d0
;
; 			move.w d1,(a0)+
; 			move.w d0,(a0)+
; 			move.w d0,(a1)+
; 			move.w d0,(a1)+
;
; 			dbf 	d7,.line
;       rts
;
;
; metademo_preparecoppers:
; 			lea.l metademo_copperptrs,a0
; 			lea.l metademo_screenptrs,a3
; 			lea.l scroller_screenptrs,a5
;
; 			move.w #2-1,d7								* # of copperlists
; .nulist
;
; 			move.l #METADEMO_BPLWIDTH_BTS,d0
; 			move.l (a0)+,a1								* copperptr of this round
; 			lea.l cop1bplptrs-cop1start(a1),a2 * skip other instrutions
; 			move.l (a3)+,d1								* screenptr
; 			add.l #8,d1										* move beyond the left border area
; 			move.w #METADEMO_BPLDEPTH-1,d6
; .nuplane
; 			move.w d1,6(a2)
; 			swap 	d1
; 			move.w d1,2(a2)
; 			swap 	d1
; 			add.l d0,d1
; 			lea.l 8(a2),a2
; 			dbf d6,.nuplane
;
; 			* scroll bplptrs
; 			lea.l cop1scroll-cop1start(a1),a2
; 			move.l (a5)+,d1
; 			move.l #42,d0
; 			move.w #METADEMO_BPLDEPTH-1,d6
; .scrplane
; 			move.w d1,6(a2)
; 			swap 	d1
; 			move.w d1,2(a2)
; 			swap 	d1
; 			add.l d0,d1
; 			lea.l 8(a2),a2
; 			dbf d6,.scrplane
;
;
; 			lea.l cop1palette-cop1start+2(a1),a2
; 			move.w #4-1,d6
; 			lea.l metademo_palette,a4
; .nucol
; 			move.w (a4)+,(a2)
; 			adda.l #4,a2
;
; 			dbf d6,.nucol
; 			dbf d7,.nulist
; 			rts
;
; metademo_updateframe:
; 			* Update the canvas with new demo frame
; 			bsr metademo_producecube			* fill the canvas with a cubeanim frame
; 			bsr metademo_addscroller			* add the scroller part to the frame
; 			bsr metademo_placelogo				* add vertical logo to current frame
;
; 			* Move to moving and rendering main screen
; 			bsr metademo_updateademo			* routine to clear screen at prev position and draw new cube
;
; 			bsr metademo_doscroll
; 			bsr metademo_switchscreen			* change pointers to newly drawn screen
; 			rts
;
; metademo_doscroll:
; 			lea.l	scroller_screenptrs,a0
; 			lea.l	CUSTOM,a6
; 			move.l VIEWSCR(a0),d0
; 			move.l DRAWSCR(a0),d1
; 			move.l	#(42*16*2)-2,d2
; 			add.l		d2,d0
; 			add.l		d2,d1
;
; 			bsr			WaitBlitter
; 			move.l	#$19f00002, BLTCON0(a6)
; 			move.l	d0,BLTAPTH(a6)
; 			move.l	d1,BLTDPTH(a6)
; 			move.l	#$ffffffff,BLTAFWM(a6)
; 			move.l	#0,BLTAMOD(a6)
; 			move.l	#0,BLTDMOD(a6)
; 			move.w	#(2*16*64)+21,BLTSIZE(a6)
; 			bsr 		WaitBlitter
;
; 			move.w	main_scrollcounter, d0
; 			tst.w		d0
; 			bne.s		.nonewchar
;
;
; 			move.w		textcounter, d1
; 			lea.l			scrolltext,a3
; 			moveq			#0,d3
; 			move.b 		(a3,d1.w),d3			* d3 is ascii
; 			move.w		d3,d1
; 			lsl.w			#6,d1
; 			lea.l			metademo_font,a3
; 			lea.l			(a3,d1.w),a4
;
; 			move.l		DRAWSCR(a0),a1
; 			lea.l			40(a1),a1			* bpl1
; 			lea.l			42(a1),a2			*bpl2
; 			move.w		#15,d7
;
; 			bsr			WaitBlitter
; 			move.l	#$09f00000, BLTCON0(a6)
; 			move.l	a4,BLTAPTH(a6)
; 			move.l	a1,BLTDPTH(a6)
; 			move.l	#$ffffffff,BLTAFWM(a6)
; 			move.w	#0,BLTAMOD(a6)
; 			move.w	#40,BLTDMOD(a6)
; 			move.w	#(2*16*64)+1,BLTSIZE(a6)
; 			bsr 		WaitBlitter
;
; 			lea.l		scrolltab,a1
; 			add.w		d3,d3
; 			move.w	(a1,d3.w),d0
; 			move.w	d0,main_scrollcounter
; 			add.w		#1,textcounter
; 			cmp.w		#6017, textcounter
; 			bne.s		.noreset
; 			move.w	#1,exitflag
; .noreset
; 			rts
; .nonewchar
; 			sub.w		#1,d0
; 			move.w	d0,main_scrollcounter
; 			rts
;
;
; ;--------------------------------------------------------------------
; 			;sets all sprites in the given copperlist
; 			;a0 - pointer to a setspriteblock for 8 sprites inside a copperlist (dc.l $01200000,...,$013e0000)
; 			;a1 - pointer to pointerlist of 8 sprites
; 			;destroys: d0-d7/a0-a1
; 			; setsprites:
; clearsprites:
; 		lea		fw_spritetab,a1
; 		addq.l	#2,a0
; 		movem.l	(a1),d0-d7
; 		move.w	d0,$04(a0)
; 		swap	d0
; 		move.w	d0,(a0)
; 		move.w	d1,$0c(a0)
; 		swap	d1
; 		move.w	d1,$08(a0)
; 		move.w	d2,$14(a0)
; 		swap	d2
; 		move.w	d2,$10(a0)
; 		move.w	d3,$1c(a0)
; 		swap	d3
; 		move.w	d3,$18(a0)
; 		move.w	d4,$24(a0)
; 		swap	d4
; 		move.w	d4,$20(a0)
; 		move.w	d5,$2c(a0)
; 		swap	d5
; 		move.w	d5,$28(a0)
; 		move.w	d6,$34(a0)
; 		swap	d6
; 		move.w	d6,$30(a0)
; 		move.w	d7,$3c(a0)
; 		swap	d7
; 		move.w	d7,$38(a0)
; 		rts
;
;
; metademo_producecube:
; 			* this far not rubber, and no room for shifting
; 			* add shifting space for blitter?
; 			* rubber by using sinewave on which frame
; 			lea.l metademo_cubeframes,a0
; 			move.l metademo_cubecount,d0
; 			add.l #$400,d0
; 			and.l #$1fc00,d0 *128*2*512,d0
; 			moveq #0,d1
; 			move.l d0,d2
; .noreset
; 			move.l d0,metademo_cubecount
; 			lea.l metademo_canvas,a2
; 			rept METADEMO_CANVAS_HEIGHT
; 				move.l a0,a1
; 				adda.l d0,a1
; 				move.l (a1)+,(a2)+				* 2 lws = one line of 64 pix
; 				move.l (a1)+,(a2)+				*
; 				clr.w (a2)+								* clear and skip the shift space
; 				move.l (a1)+,(a2)+				* 2 lws = one line of 64 pix
; 				move.l (a1)+,(a2)+				*
; 				clr.w (a2)+								* clear and skip the shift space
; 				lea.l 16(a0),a0						* the next line of the cube
; 				add.l #$170,d2
; 				move.l d2,d0
; 				and.l #$1fc00,d0 *128*2*512,d0
; 			endr
; 			rts
;
; metademo_addscroller:
; 			* scrollcounter hold how many pixels we have moved on the scrollmap.
; 			* blitter copy with shift from scrollmap to destination canvas.
; 			* ex:  scrollcounter = 0 copy with 0 shift to destination.
; 			* scrollcounter = 13:
; 			move.w metademo_scrollcounter,d0
; 			add.w #1,d0
; 			and.w	#SCROLLMAP_WIDTH-1,d0
; 			move.w d0,metademo_scrollcounter
;
; 			moveq #0,d1
; 			move.w d0,d1
; 			lsr.w #4,d1
; 			add.w d1,d1									* bytes to move ahead on scrollmap
; 			and.w	#$f,d0								* which line of shift should we choose
; 			mulu.w	#2048,d0
; 			add.w	d0,d1
;
; 			move.l #$0fca0000,d3                        * cookie cut
;
; 			lea.l metademo_scrollmap,a0
; 			adda.l d1,a0
;
; 			lea.l metademo_canvas,a2
;       move.l #METADEMO_FRAME_SIZE,d1
; 			sub.l #(SCROLLMAP_HEIGHT*METADEMO_CANVAS_DEPTH*(METADEMO_CANVAS_WIDTH/8)),d1
; 			adda.l	d1,a2
; 			move.w #SCROLLMAP_WIDTH_BTS,d1
; 			sub.w #METADEMO_CANVAS_WIDTH/8,d1			* modulo for logo and mask
; 			move.w #SCROLLMAP_HEIGHT*64,d4	* #lines
; 			or.w #METADEMO_CANVAS_WIDTH/16,d4			* combine words and lines
; 			lea $dff000,a6												* set up
; 			bsr WaitBlitter
; 			move.l d3,BLTCON0(a6)	           ;A->D copy, no shifts, ascending mode
; 			move.l a0,BLTAPTH(a6)				* this is the scrollmap mask (decides shape)
; 			move.l #emptychip,BLTBPTH(a6)				* this is the actual scroller (decided color)
;       move.l a2,BLTCPTH(a6)				* this is the canvas
;       move.l a2,BLTDPTH(a6)				* this is the canvas
; 			move.l #$ffffffff,BLTAFWM(a6)	   ;no masking of first/last word
; 			move.w d1,BLTAMOD(a6)				* no modulo for logo mask
; 			move.w d1,BLTBMOD(a6)				* no modulo for logo source
; 			move.w #METADEMO_CANVAS_WIDTH/8,BLTCMOD(a6)				* same modulo for canvas when C
;       move.w #METADEMO_CANVAS_WIDTH/8,BLTDMOD(a6)				* canvas modulo
; 			move.w d4,BLTSIZE(a6)	           ;rectangle size, starts blit
; 			bsr		WaitBlitter
; 			add.l	#METADEMO_CANVAS_WIDTH/8,a2
; 			move.l d3,BLTCON0(a6)	           ;A->D copy, no shifts, ascending mode
; 			move.l a0,BLTAPTH(a6)				* this is the scrollmap mask (decides shape)
; 			move.l a0,BLTBPTH(a6)				* this is the actual scroller (decided color)
;       move.l a2,BLTCPTH(a6)				* this is the canvas
;       move.l a2,BLTDPTH(a6)				* this is the canvas
; 			move.l #$ffffffff,BLTAFWM(a6)	   ;no masking of first/last word
; 			move.w d1,BLTAMOD(a6)				* no modulo for logo mask
; 			move.w d1,BLTBMOD(a6)				* no modulo for logo source
; 			move.w #METADEMO_CANVAS_WIDTH/8,BLTCMOD(a6)				* same modulo for canvas when C
;       move.w #METADEMO_CANVAS_WIDTH/8,BLTDMOD(a6)				* canvas modulo
; 			move.w d4,BLTSIZE(a6)	           ;rectangle size, starts blit
; 			rts
;
; metademo_placelogo:
; 			lea.l metademo_vertlogo,a0
; 			lea.l metademo_vertlogomask,a1			* mask 1 bpl
; 			lea.l metademo_canvas,a2
; 			move.w #2,d1											* width of source in bytes
; 			move.w #METADEMO_CANVAS_WIDTH/8,d2		* width of dest in bytes (interleaved + remainder)
; 			sub.w d1,d2																* modulo for dest
; 			lsr.w #1,d1																* words to blit
; 			move.w #METADEMO_CANVAS_HEIGHT*METADEMO_CANVAS_DEPTH*64,d3	* #lines
; 			or.w d1,d3																* combine words and lines
; 			lea $dff000,a6														* set up
; 			bsr WaitBlitter
; 			move.l a2,BLTDPTH(a6)				* this is the canvas
; 			move.l a1,BLTAPTH(a6)				* this is the logo mask
; 			move.l a0,BLTBPTH(a6)				* this is the actual logo
; 			move.l a2,BLTCPTH(a6)				* this is the canvas
; 			move.w d2,BLTDMOD(a6)				* canvas modulo
; 			move.w #0,BLTAMOD(a6)				* no modulo for logo mask
; 			move.w #0,BLTBMOD(a6)				* no modulo for logo source
; 			move.w d2,BLTCMOD(a6)				* same modulo for canvas when C
; 			move.l #$ffffffff,BLTAFWM(a6)	;no masking of first/last word
; 			move.l #$0fca0000,BLTCON0(a6)	;cookie cut
; 			move.w d3,BLTSIZE(a6)	;rectangle size, starts blit
; 			rts
;
; 			MACRO SWITCHSCREEN
; 			move.l VIEWSCR(a0), d0
; 			move.l DRAWSCR(a0), d1
; 			move.l d1,VIEWSCR(a0)
; 			move.l d0,DRAWSCR(a0)
; 			ENDM
;
;
; metademo_switchscreen:
; *				clr.w metademo_debug
; 				lea.l metademo_screenptrs, a0
; 				SWITCHSCREEN
; 				lea.l metademo_copperptrs, a0
; 				SWITCHSCREEN
; 				lea.l	scroller_screenptrs,a0
; 				SWITCHSCREEN
;
; 				bsr WaitBlitter
; 				lea.l metademo_copperptrs,a0
; 				move.l VIEWSCR(a0), a0				* move the new VIEWscreen-copperlist
; 				bsr copperInstall
; 				rts
;
;
;
; 											rsreset
; data_startframe				rs.w 1
; data_prev_bitmap 			rs.l 1
; data_bitmap 					rs.l 1
; data_xpos							rs.w 1
; data_ypos 						rs.w 1
; data_xdelta 					rs.w 1
; data_ypattern					rs.w 1
; demodata_size					rs.w 0
; 											rsreset
;
; metademo_updateademo:
; 					* static registers
; 						* for moving
; 						*  pointer to demodata previous screen (CLEAR) for clearing
; 						*  pointer to demodata current screen (VIEW) for current data
; 						*  pointer to going-to-be screen (DRAW) for updating/rendering
; 						* for clearing:
; 						*  screenptrs base address			all ptrs in a5
; 						*  screen modulo
; 						*  bltsize
; 						*  bltcon0/1
; 						* for rendering:
; 						*   canvas
; 						*   canvas mask
; 						*		screen modulo
; 						*		bltcon0/1
;
; 					* a6-a2 : taken
; 					* d7-d6 taken
; 					clr.w 	metademo_debug
; 					lea.l 	metademo_data,a4
; 					lea.l		CUSTOM,a6				; a6 - custom base
;
; 					move.w 	#METADEMO_CANVAS_HEIGHT*METADEMO_CANVAS_DEPTH*64,d7
; 					or.w 		#METADEMO_CANVAS_WIDTH/16,d7			* BLTSIZE to d7
; 					move.w 	#METADEMO_BPLWIDTH_BTS-(METADEMO_CANVAS_WIDTH/8), d6	* screen modulo to d6
;
; 					; tst.w		data_prevprev_visible(a4)				* test if was visible
; 					; beq.s 	.skipclear
;
; .newclear
; 					move.l data_prev_bitmap(a4),d0	* get  byteoffset from table
; 					tst.l d0
; 					beq.s .skipclear										* dont clear if no drawing
;
;           bsr     WaitBlitter
; 					move.l	#$01000000,BLTCON0(a6)
; 					move.l	d0,BLTDPTH(a6)							* dest ptr
; 					move.w	d6,BLTDMOD(a6)							* set screen modulo
; 					move.w	d7,BLTSIZE(a6)							* set prespec bltsize
;
; .skipclear
; 					bsr WaitBlitter
; 					* We are done clearing the screen for two-frames-ago-demos
; 					lea.l 	metademo_canvas,a2
; 					lea.l 	metademo_canvasmask,a3		* may swap these for others
; 					lea.l 	metademo_screenptrs,a5
; 					lea.l 	metademo_ypatterns,a1
; 					lea.l  	metademo_bplwtab,a0
; 					move.l  DRAWSCR(a5),a5
;
; 					move.l data_bitmap(a4),data_prev_bitmap(a4)
;
; 					lea.l demodata_size(a4),a4					* next demodata
; 					cmp.w #-1,(a4)
; 					bne.s .newclear
;
; 					* MOVE DEMO AROUND
; 					* should be heavily optimized
; 					add.l 	#1,metademo_demoframe
; ; 					cmp.w 	#METADEMO_WALLFRAME,metademo_demoframe
; ; 					blt.s 	.noopenwall
; ; 					move.w	#1,metademo_openwall
; ; .noopenwall
;
; 					lea.l metademo_data,a4
; 					* now we can write info for current frame, into previous
; .newdemo
; 					moveq	#0,d0
; 					move.w data_startframe(a4),d0
; 					cmp.l  metademo_demoframe,d0
; 					bgt.s 	.notvisible
;
; 					* XPOS JUST FOLLOWS STEADY FLOW
; 					move.w data_xpos(a4),d0
;  					add.w data_xdelta(a4),d0
; 					cmp.w #0,d0
; 					bpl.s .nominx
;  					move.w #0,d0
; 					tst.w metademo_openwall
; 					beq.s .nowall
; 					move.w #0,data_xdelta(a4)
; 					bra .nominx
; .nowall
; 					move.w #1*4,data_xdelta(a4)
; .nominx		cmpi.w #4*(METADEMO_BPLWIDTH-64),d0
; 					blt.s .nomaxx
;
; 					move.w #4*(METADEMO_BPLWIDTH-64),d0
; 					tst.w metademo_openwall
; 					beq.s .closedwall
; 					move.w #0,data_xdelta(a4)
; 					bra.s .nomaxx
; .closedwall
; 					move.w #-1*4,data_xdelta(a4)
;
; .nomaxx		move.w d0, data_xpos(a4)
;
; 					* YPOS IS A BOUNCE PATTERN
; 					move.w data_ypattern(a4),d1					* offset for this demos pattern
; 					move.w data_ypos(a4),d2							* position in pattern
; 					add.w  #METADEMO_BOUNCE_SPEED*2,d2	* move position
; 					and.w #$fe,d2												* reset if needed
; 					move.w d2,data_ypos(a4)							* save new position
; 					add.w d2,d1													* add position to byteoffset
; 					move.w (a1,d1.w),d1									* get ypos from table
;
; 					* check if the thing is visible here!
; 					clr.l data_bitmap(a4)								* if we decie not to try, not
;
; ;  					add.w data_ydelta(a4),d1
; ; 					cmp.w #0,d1
; ; 					bpl.s .nominy
; ;  					move.w #0,d1
; ; 					neg.w data_ydelta(a4)
; ; .nominy		cmp.w #(METADEMO_BPLHEIGHT-METADEMO_CANVAS_HEIGHT)*4,d1
; ; 					bmi.s .nomaxy
; ; 					move.w #(METADEMO_BPLHEIGHT*4),d1
; ; 					neg.w data_ydelta(a4)
; ; .nomaxy
; ; 				move.w d1,data_ydelta(a4)
; ; ;
; 					* to screen pixel coords
; 					asr.w 	#2,d0
;
; 					moveq 	#0,d2
; 					move.w 	d0,d2			* save x
; 					lsr.w 	#4,d2																						* x-pos byteoffset
; 					add.w 	d2,d2
;
; 					and.l #$fffc,d1
; 					add.l (a0,d1.w),d2
; 					add.l 	a5,d2									* add bitmap base address
;
; 					move.l 	d2,data_bitmap(a4)			* save byteoffset for next 2 frames
;
; 					and.w 	#$f,d0
; 					ror.w 	#4,d0
; 					move.l 	#$0fca,d1
; 					or.w 		d0,d1
; 					swap		d1
; 					or.w		d0,d1													* bplcon01
;
; 					bsr 		WaitBlitter																* wait
; 					move.l a3,BLTAPTH(a6)		* canvas mask
; 					move.l a2,BLTBPTH(a6)		* canvas
; 					move.l d2,BLTCPTH(a6)		* backgruond (i.e. destination)
; 					move.l d2,BLTDPTH(a6)		; destination top left corner
; 					move.l d1,BLTCON0(a6)	;A->D copy, no shifts, ascending mode
; 					move.l #$ffff0000,BLTAFWM(a6)
; 					move.w #0,BLTAMOD(a6)		* canvas modulo
; 					move.w #0,BLTBMOD(a6)		* canvas modulo
; 					move.w d6,BLTCMOD(a6)		* bitplane modulo
; 					move.w d6,BLTDMOD(a6)		; bitplane modulo
; 					move.w d7,BLTSIZE(a6)		; rectangle size, starts blit
;
; .notvisible
; 				lea.l demodata_size(a4),a4					* next demodata
; 				cmp.w #-1,(a4)
; 				bne.s .newdemo
; 				bsr WaitBlitter
; 				rts

			section replayer, code

		    include "includes/LSP/LightSpeedPlayer_cia.asm"
		    include "includes/LSP/LightSpeedPlayer.asm"

			section "metacube_data",data

											cnop 0,4
exitflag:			dc.w 0
fw_spritetab:	dc.l	$00000000,$00000000,$00000000,$00000000
							dc.l	$00000000,$00000000,$00000000,$00000000

metacube_copperptrs:  dc.l metacube_copperlist1
										  dc.l metacube_copperlist2
metacube_screenptrs:  dc.l metacube_screen1
											dc.l metacube_screen2

; scrolltab: 						blk.w  256,7
; metademo_bplwtab:
; y set 0
; 											rept METADEMO_BPLHEIGHT
; 											dc.l (METADEMO_BPLWIDTH_BTS*METADEMO_BPLDEPTH)*y
; y set y + 1
; 											endr
; metademo_demoframe: 	dc.l 0
; metademo_openwall: 		dc.w 0
; metademo_palette: 		dc.w $0377,$0f46,$647,$faa,$fff,$fff,$fff,$fff
; 											dc.b "CPTR"
; 				* startfrme, prevoff,prefvis, off,vis, xpos,ypos, xdelta,ypattern
; metademo_data:				dc.w 0				*startframe
; 											dc.l 0				*prev bitmap calc previous frame
; 											dc.l 0				*bitmap calculatad this frame
; 											dc.w 100*4, $7e, 1*4, 0*256
; 											dc.w 150				*startframe
; 											dc.l 0				*prev bitmap calc previous frame
; 											dc.l 0				*bitmap calculatad this frame
; 											dc.w 0*4, 128, 3*4, 1*256
; 											dc.w 250				*startframe
; 											dc.l 0				*prev bitmap calc previous frame
; 											dc.l 0				*bitmap calculatad this frame
; 											dc.w 0*4, 72, 2*4, 2*256
; 											dc.w 320				*startframe
; 											dc.l 0				*prev bitmap calc previous frame
; 											dc.l 0				*bitmap calculatad this frame
; 											dc.w 0*4, 15, 11, 1*256
; 											dc.w 410				*startframe
; 											dc.l 0				*prev bitmap calc previous frame
; 											dc.l 0				*bitmap calculatad this frame
; 											dc.w 0*4, 30, 7, 2*256
; 											dc.w 420				*startframe
; 											dc.l 0				*prev bitmap calc previous frame
; 											dc.l 0				*bitmap calculatad this frame
; 											dc.w 0*4, 50, 5, 3*256
; 											dc.w 430				*startframe
; 											dc.l 0				*prev bitmap calc previous frame
; 											dc.l 0				*bitmap calculatad this frame
; 											dc.w 0*4, 170, 3, 0*256
; 											dc.w 530				*startframe
; 											dc.l 0				*prev bitmap calc previous frame
; 											dc.l 0				*bitmap calculatad this frame
; 											dc.w 2*4, 170, 3, 3*256
; 											dc.w 570				*startframe
; 											dc.l 0				*prev bitmap calc previous frame
; 											dc.l 0				*bitmap calculatad this frame
; 											dc.w 3*4, 120, 3, 2*256
; 											dc.w 630				*startframe
; 											dc.l 0				*prev bitmap calc previous frame
; 											dc.l 0				*bitmap calculatad this frame
; 											dc.w 1*4, 120, 7, 1*256
; 											dc.w 680				*startframe
; 											dc.l 0				*prev bitmap calc previous frame
; 											dc.l 0				*bitmap calculatad this frame
; 											dc.w 1*4, 120, 7, 1*256
; metademo_enddata:			dc.w -1
;
; metademo_ypatterns:		incbin "./data/bounce-pattern-1.raw"
; ypattern2:						incbin "./data/bounce-pattern-2.raw"
; 											incbin "./data/bounce-pattern-3.raw"
; 											incbin "./data/bounce-pattern-2.raw"
; metademo_ypatterns_end:
; metademo_cubeframes:	incbin "./data/cubeframes.raw"
; metademo_cubecount: 	dc.l 0
; metademo_waveptr:			dc.l 0
; 											dc.b "DBUG"
; metademo_debug:				dc.w 0
; metademo_debugcolor:  dc.w $f0f
; metademo_vertlogoraw:	incbin "./data/vert-logo.raw"

; thewave:							incbin "./gfx/backband.raw"
; textcounter:					dc.w 0
; metademo_scrollcounter: dc.w 0
; main_scrollcounter:		dc.w 0
; scroller_screenptrs:	dc.l scroller_screen1,scroller_screen2
; scrolltext:						incbin "./data/scrolltext.txt"

Scores:       				incbin "./assets/mod.lsmusic"
											cnop 0,4

			section "metademo_chipdata", data_c

metacube_background:
							* fills the first bpl with bgr: 128px --> 96px
							dc.w 	-1,-1,-1,-1,-1,-1,-1,-1		* full line
							dc.w	$7fff,-1,-1,-1,-1,$fffe * one pix in
							dc.w 	$3fff,-1,-1,-1,-1,$fffc	* two pix
							dc.w 	$1fff,-1,-1,-1,-1,$fff8	* three pix
							dc.w 	$0fff,-1,-1,-1,-1,$fff0	* four pix
							dc.w	$07ff,-1,-1,-1,-1,$ffe0 * one pix in
							dc.w 	$03ff,-1,-1,-1,-1,$ffc0	* two pix
							dc.w 	$01ff,-1,-1,-1,-1,$ff80	* three pix
							dc.w 	$00ff,-1,-1,-1,-1,$ff00	* four pix

Samples:      incbin "./assets/mod.lsbank"

; metademo_emptysprite: dc.l 0

metacube_basecopper:
			dc.l	$008e1b51,$009037d1  ;window start, window stop,
			dc.l  $00920030,$009400d0	;bitplane start, bitplane stop
			dc.l	$01060c00,$01fc0000						;fixes the aga modulo problem
			dc.l	$01000200,$01020000						;bplcon mode, scroll values
basecopsprites:
			dc.l	$01200000,$01220000
			dc.l	$01240000,$01260000
			dc.l	$01280000,$012a0000
			dc.l	$012c0000,$012e0000
			dc.l	$01300000,$01320000
			dc.l	$01340000,$01340000
			dc.l	$01380000,$01380000
			dc.l	$013c0000,$013c0000
			dc.l	$01800000+METADEMO_BACKCOL
			dc.l	$fffffffe	; end coplist

			MACRO COPPERCONTENTS
cop\1start
			dc.l	$008e2c81,$00902cc1  ;window start, window stop,
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
			dc.l	$01002200,$01020000						;bplcon mode, scroll
			dc.l	$01040000
cop\1modulo
      dc.l  $01080000+METADEMO_SCREEN_MODULO
			dc.w  $010a,METADEMO_SCREEN_MODULO
cop\1palette
      dc.l	$01800000,$01820000
			dc.l	$01840000,$01860000
			dc.l	$01880000,$018a0000
			dc.l	$018c0000,$018e0000
cop\1bplptrs
			dc.l  $00e00000,$00e20000
			dc.l  $00e40000,$00e60000
cop\1waits
y set $2b
			rept  235
				dc.b	(y&$ff),$df,$ff,$fe
				dc.w	$0180,METADEMO_BACKCOL
y set y+1
			endr
			dc.l  $17dffffe,$01000200
			dc.w	$0180,$0373, $0182,$fff,$184,$0bde,$186,$0070
			dc.w	$0102,$0000,$0108,42+2,$010a,42+2
cop\1scroll
			dc.w	$00e0,$0000,$00e2,$0000,$00e4,$0000,$00e6,$0000
cop\1postscroll
			dc.w	$1cdf,$fffe,$0100,$2200 			* end it
			dc.l  $30c1fffe	* wait until end of screen
			dc.l  $009c8010	* turn on copper interrupt
      dc.l	$fffffffe	; end coplist
			ENDM

metacube_copperlist1:			COPPERCONTENTS 1
metacube_copperlist2:			COPPERCONTENTS 2
; metademo_canvas:					blk.b METADEMO_CANVAS_SIZE*METADEMO_CANVAS_DEPTH,$aa
; 													dc.w 0
; metademo_canvasmask:			rept METADEMO_CANVAS_HEIGHT*METADEMO_CANVAS_DEPTH
; 														dc.w	-1,-1,-1,-1,0
; 													endr
; metademo_nter: 						dc.w 100
; metademo_scrollmap:				incbin "./data/readymade-scrollmap-16.raw"
; metademo_vertlogo:				blk.w METADEMO_CANVAS_HEIGHT*METADEMO_CANVAS_DEPTH,$aaaa
; metademo_vertlogomask:		blk.w METADEMO_CANVAS_HEIGHT*METADEMO_CANVAS_DEPTH,$f0ff
; 													dc.b "HORE"
metacube_font:						incbin "./data/font.raw"

					section metademo_screens, bss_c

emptychip:						ds.b  2048
metademo_screen1:			ds.b	METADEMO_SCREEN_SIZE
metademo_screen2:			ds.b	METADEMO_SCREEN_SIZE
; scroller_screen1:			ds.b	2048
; scroller_screen2:			ds.b	2048
