	define SNA_FILENAME "test-2s-attr-keyframe.sna"

	device zxspectrum128

	org #6000
start	di : ld sp, $-2

	xor a : out (#fe), a	; бордюр

	// чистим экраны
	call swap_screen
	ld hl, #c000 : ld de, #c001 : ld bc, #1800 : ld (hl), l : ldir
	ld bc, #02ff : ld (hl), #42 : ldir	

	call swap_screen
	ld hl, #c000 : ld de, #c001 : ld bc, #1800 : ld (hl), l : ldir
	ld bc, #02ff : ld (hl), #43 : ldir

	; keyframe initalization
	ld a, %11000000		; screen in #c000 / animation bright = 0
	ld hl, KEYFRAME_START	; animation start
	ld de, KEYFRAME_END		; animation end
	call keyframe.INIT

	; player initalization
	ld a, %11000000		; screen in #c000 / animation bright = 0
	ld hl, CHNK_START	; animation start
	ld de, CHNK_END		; animation end
	call chnk_main.INIT	

	ld a,#5c, i,a, hl,interr, (#5cff),hl : im 2 : ei

main	
	call player_start

	// fade in	
	ld b, #10		; количество итераций
fin_outer	push bc
	call keyframe.INC_BRGHT
	call chnk_main.INC_BRGHT
	ld b, #04		; внутри каждой интерации прокручиваем N раз анимацию для замедления эффекта
	push bc : halt : pop bc : djnz $-3
	pop bc : djnz fin_outer

	// main cycle
	ld b, #20
	push bc : halt : pop bc : djnz $-3

	; change color
	ld a, #47 : ld (COLOR1), a
	ld a, #47 : ld (COLOR2), a

	halt : halt : halt : halt : halt : halt

	; restore color
	ld a, #42 : ld (COLOR1), a
	ld a, #03 : ld (COLOR2), a

	// fade out	
	ld b, #18		
fout_outer	push bc
	call keyframe.DEC_BRGHT
	call chnk_main.DEC_BRGHT
	ld b, #04
	push bc : halt : pop bc : djnz $-3
	pop bc : djnz fout_outer

	; stop playing befor flipping!!!
	call player_stop

	; just pause
	ld b, #20 : halt : djnz $-1

	; flip horizontal or vertical on every iteration
flp_flag	ld a, #01 : inc a : and #01 : ld (flp_flag + 1), a
	or a : jr z, 1f
	call keyframe.FLIP_HORIZ	
	call chnk_main.FLIP_HORIZ
	jr 2f
1	call keyframe.FLIP_VERT
	call chnk_main.FLIP_VERT
2
	; restart main cycle
	jr main

player_start	ld a, #01 : ld (_player_state + 1), a
	ret

player_stop	xor a : ld (_player_state + 1), a
	ret

swap_screen	ld a, %00001101 : xor %00001010 : ld (swap_screen + 1), a
	ld bc, #7ffd : out (c), a
	ret

interr	di
	push af,bc,de,hl,ix,iy
	exx : ex af, af'
	push af,bc,de,hl,ix,iy

	ld a, #01 : out (#fe), a
_player_state	ld a, #00 : or a : jr z, _player_stopped

	; выбираем цвет, которым отображать фрейм (в зависимости от текущего экрана)
	ld a, (swap_screen + 1) : cp %00001101 : jr z, 1f
	ld a, (COLOR1) : jr 2f
1	ld a, (COLOR2) 
2	ld (chnk_main.CUR_ATTR), a
	call chnk_main.PLAY
	call keyframe.PLAY
	call swap_screen
_player_stopped	xor a : out (#fe), a

	pop iy,ix,hl,de,bc,af
	exx : ex af, af'
	pop iy,ix,hl,de,bc,af
	ei
	ret

	; два цвета, раздельные для каждого экрана
COLOR1	db #42
COLOR2	db #03

	; таблица яркостей
BRIGHT_TABLE	include "../lib/chunks.bright.table.asm"
		
	; таблица чанков
	align #100
CHUNK_SRC	include "../lib/chunks.src.table.asm"

	module keyframe
CHE_TABLES	equ #bc00	; адрес, с которого начинаются таблицы плеера (1к)
	include "../lib/chunks.player.asm"
	endmodule

	module chnk_main
CHE_TABLES equ #b800	; адрес, с которого начинаются таблицы плеера (1к)
	include "../lib/chunks.player-attr.asm"
	endmodule

KEYFRAME_START	
	include "res/parsed-2s-attr-keyframe.asm"
KEYFRAME_END

CHNK_START	include "res/parsed-2s-attr.asm"
CHNK_END	display /d, 'Chunks data len: ', CHNK_END - CHNK_START

	display 'Free space from: ', $

	; build
	if (_ERRORS == 0 && _WARNINGS == 0)
	; LABELSLIST "user.l"
	savesna SNA_FILENAME, start
	endif