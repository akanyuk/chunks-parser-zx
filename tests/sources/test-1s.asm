	define SNA_FILENAME "test-1s.sna"

	device zxspectrum128

	define CHE_TABLES #bb00	; адрес, с которого начинаются таблицы плеера (1к)

	org #6000
start	di : ld sp, $-2

	xor a : out (#fe), a	; бордюр

	// чистим экран
	ld hl, #4000 : ld de, #4001 : ld bc, #1800 : ld (hl), l : ldir
	ld bc, #02ff : ld (hl), #42 : ldir	

	ld a, %01000000		; экран #4000 / нулевая стартовая яркость
	ld hl, CHNK_START	; начало данных анитации
	ld de, CHNK_END		; конец данных анитации
	call chnk_main.INIT		

	ld a,#5c, i,a, hl,interr, (#5cff),hl : im 2 : ei

main	call player_start

	// fade in	
	ld b, #10		; количество итераций
fin_outer	push bc
	call chnk_main.INC_BRGHT
	ld b, #04		; внутри каждой интерации прокручиваем N раз анимацию для замедления эффекта
	push bc : halt : pop bc : djnz $-3
	pop bc : djnz fin_outer

	// main cycle
	ld b, #20
	push bc : halt : pop bc : djnz $-3

	// fade out	
	ld b, #18		
fout_outer	push bc
	call chnk_main.DEC_BRGHT
	ld b, #04
	push bc : halt : pop bc : djnz $-3
	pop bc : djnz fout_outer

	; just pause
	ld b, #20 : halt : djnz $-1

	; stop playing befor flipping!!!
	call player_stop

	; flip horizontal or vertical on every iteration
flp_flag	ld a, #00 : inc a : and #01 : ld (flp_flag + 1), a
	or a : jr z, $+7
	call chnk_main.FLIP_HORIZ
	jr $+5
	call chnk_main.FLIP_VERT

	; restart main cycle
	jr main

player_start	ld hl, chnk_main.PLAY
	ld (_player_state + 1), hl
	ret

player_stop	ld hl, _player_dummy
	ld (_player_state + 1), hl
	ret

interr	di
	push af,bc,de,hl,ix,iy
	exx : ex af, af'
	push af,bc,de,hl,ix,iy

	ld a, #01 : out (#fe), a
_player_state	call _player_dummy
	xor a : out (#fe), a

	pop iy,ix,hl,de,bc,af
	exx : ex af, af'
	pop iy,ix,hl,de,bc,af
	ei
_player_dummy	ret

PLAYERS_START
	; таблица яркостей
BRIGHT_TABLE	include "../lib/chunks.bright.table.asm"
		
	; таблица чанков
	align #100
CHUNK_SRC	include "../lib/chunks.src.table.asm"

	module chnk_main
	include "../lib/chunks.player.asm"
	display /d, 'Chunks players full length: ', $ - PLAYERS_START
	endmodule

CHNK_START	include "res/a2-1s.asm"
CHNK_END	display /d, 'Chunks data len: ', CHNK_END - CHNK_START


	; build
	if (_ERRORS == 0 && _WARNINGS == 0)
	; LABELSLIST "user.l"
	savesna SNA_FILENAME, start
	endif