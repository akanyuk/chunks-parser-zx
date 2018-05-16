CHNK_DATA	equ CHE_TABLES		; 16 декранченых процедуры вывода чанков - 256 байт. Выход - ret
CHNK_DATA2	equ CHE_TABLES + #100	; 16 декранченых процедуры вывода чанков - 256 байт. Выход - jp CHMN13_CYCLE
FLPVT_CHNK_TBL	equ CHE_TABLES + #200 	; Таблица зеркалирования по вертикали (чанки) - 256 байт
FLPHZ_TABLE	equ CHE_TABLES + #300 	; Таблица зеркалирования по горизонтали (чанки) - 256 байт

CUR_FRAME	db #00	; текущий фрейм
CUR_BRGT_INDEX	db #00	; текущая яркость

CHNK_START	dw #0000	; Адрес начала данных
CHNK_END	dw #0000	; Адрес конца данных

CUR_BRIGHT	db 0, 0, 0, 0

	; зеркальный разворот анимации по вертикали
FLIP_VERT
	; меняем местами первую и третью 1/3 экрана
	ld a, (SCR_ADDR1 + 1) : xor #10 : ld (SCR_ADDR1 + 1), a
	ld a, (SCR_ADDR3 + 1) : xor #10 : ld (SCR_ADDR3 + 1), a

	ld hl, (CHNK_START)
	ld bc, (CHNK_END)

_flpvrt1	; проверяем на конец данных
	ld a, h : cp b : jr nz, _flpvrt2
	ld a, l : cp c : ret z

_flpvrt2	; проверка на сигнатуру #ffff - конец 1/3 экрана или фрейма - пропускаем
	ld a, (hl) : inc hl : cp #ff : jr nz, _flpvrt3
	cp (hl) : jr nz, _flpvrt3
	inc hl
	jr _flpvrt1

_flpvrt3	; "зеракалим адрес"
	xor #e0 : dec hl : ld (hl), a : inc hl

	; "зеркалим данные"
	ld e, (hl)
	ld d, high FLPVT_CHNK_TBL
	ld a, (de) : ld (hl), a

	inc hl
	jr _flpvrt1

	; зеркальный разворот анимации по горизонтали
FLIP_HORIZ	ld hl, (CHNK_START)
	ld bc, (CHNK_END)

_flphrz1	; проверяем на конец данных
	ld a, h : cp b : jr nz, _flphrz2
	ld a, l : cp c : ret z

_flphrz2	; проверка на сигнатуру #ffff - конец 1/3 экрана или фрейма - пропускаем
	ld a, (hl) : inc hl : cp #ff : jr nz, _flphrz3
	cp (hl) : jr nz, _flphrz3
	inc hl
	jr _flphrz1

_flphrz3	; "зеракалим адрес"
	xor #1f : dec hl : ld (hl), a : inc hl

	; "зеркалим данные"
	ld e, (hl)
	ld d, high FLPHZ_TABLE
	ld a, (de) : ld (hl), a
	
	inc hl
	jr _flphrz1


INC_BRGHT	ld a, (CUR_BRGT_INDEX) : cp #1f : jr nc, $+3 : inc a : ld (CUR_BRGT_INDEX), a
	jp INIT_PALETTE

DEC_BRGHT	ld a, (CUR_BRGT_INDEX) : or a : jr z, $+3 : dec a : ld (CUR_BRGT_INDEX), a
	jp INIT_PALETTE

	; main cycle
PLAY	
CUR_CHNK_START	ld hl, #0000

SCR_ADDR1	ld a, #c0 : ld (CHMAIN13_DE + 1), a : call CHMAIN13
SCR_ADDR2	ld a, #c8 : ld (CHMAIN13_DE + 1), a : call CHMAIN13
SCR_ADDR3	ld a, #d0 : ld (CHMAIN13_DE + 1), a : call CHMAIN13

	ld a, h 
CHNK_END_HI1	cp #00
	jr nz, 1f
	ld a, l 
CHNK_END_LO1	cp #00
	jr nz, 1f

	; reset to first frame
	ld hl, (CHNK_START)
	ld (CUR_CHNK_START + 1), hl
	xor a : ld (CUR_FRAME), a
	ret
1	; next frame
	ld (CUR_CHNK_START + 1), hl
	ld hl, CUR_FRAME : inc (HL)
	ret
	
CHMAIN13	push hl
CHMN13_CYCLE	pop hl
	ld e, (hl) : inc hl
	ld a, (hl) : inc hl

	// проверяем на сигнатуру #ffff - конец трети экрана / фрейма
	cp #ff : jr nz, 2f
	cp e : ret z
2	push hl
	ld c, a
	; Нижняя половину знакоместа
	rrca : rrca : rrca : rrca
	and %11110000 : ld l, a 
	ld h, high CHNK_DATA2 : push hl
	ld a, c
	; Верхняя половину знакоместа
	and %11110000 : ld l, a 
	ld h, high CHNK_DATA : push hl

CHMAIN13_DE	ld d, #40 	; теперь в de адрес экрана
	ex de, hl
	ret	; переход на процедуру вывода на экран

INIT	; a - начальная яркость / выбор экрана #4000 / #c000
	; hl - начало данных анитации
	; de - конец данных анитации
	push af
	and #1f : ld (CUR_BRGT_INDEX), a	; первичная инициация яркости

	; инициация вывода на экран: #4000 / #c000
	pop af : and #c0 
	ld (SCR_ADDR1 + 1), a
	add #08 : ld (SCR_ADDR2 + 1), a
	add #08 : ld (SCR_ADDR3 + 1), a

	; Заносим адреса
	ld (CHNK_START), hl
	ld (CUR_CHNK_START + 1), hl
	ld (CHNK_END), de

	ld a, d : ld (CHNK_END_HI1 + 1), a
	ld a, e : ld (CHNK_END_LO1 + 1), a

	; заполняем таблицу вертикального зеркалирования (чанки)
	ld hl, FLPVT_CHNK_TBL
1	ld a, l
	rrca : rrca : rrca : rrca
	ld (hl), a
	inc hl : ld a, l : or a : jr nz, 1b

	; заполняем таблицу горизонтального зеркалирования
	ld hl, FLPHZ_TABLE
1	ld a, l
	rrca : rrca : and %00110011 : ld e, a
	ld a, l
	rlca : rlca : and %11001100 : or e
	ld (hl), a
	inc hl : ld a, l : or a : jr nz, 1b

	; Начальная инициация процедур декранчинга
	ld hl, CHNK_DATA + 12
	ld de, #0010
	ld a, 16
	ld (hl), #c9	; ret
	add hl, de
	dec a : jr nz, $-4

	; инициация палитры обязательно должна идти последней, т.к. вызывается при смене яркости
INIT_PALETTE	; копируем нужный набор цветов согласно выбранной яркости
	ld a, (CUR_BRGT_INDEX) : ld l, a
	ld h, 0 : add hl, hl : add hl, hl : ld de, BRIGHT_TABLE : add hl, de
	ld de, CUR_BRIGHT
	ldi : ldi : ldi : ldi

	ld ix, CHNK_DATA
	ld iy, CHNK_DATA2	
	ld bc, CUR_BRIGHT
2	ld a, (bc) : add a, a : add a, a : ld (_IC_DE + 1) , a
	ld a, (CUR_BRIGHT) : add a, a : add a, a : ld (_IC_HL + 1) , a : call _INIT_COLOR
	ld a, (CUR_BRIGHT + 1) : add a, a : add a, a : ld (_IC_HL + 1) , a : call _INIT_COLOR
	ld a, (CUR_BRIGHT + 2) : add a, a : add a, a : ld (_IC_HL + 1) , a : call _INIT_COLOR
	ld a, (CUR_BRIGHT + 3) : add a, a : add a, a : ld (_IC_HL + 1) , a : call _INIT_COLOR
	inc bc
	ld a, c : cp low CUR_BRIGHT + 4 : jr nz, 2b

	ret

_INIT_COLOR	push bc
_IC_HL	ld hl, CHUNK_SRC
_IC_DE	ld de, CHUNK_SRC
	ld b, #04
1	ld a, (hl) : inc hl : and %11110000 : ld c, a
	ld a, (de) : inc de : and %00001111 : or c

	ld (ix + 0), #36 ; ld (hl), nn
	ld (ix + 1), a
	ld (ix + 2), #24 ; inc h
	inc ix : inc ix : inc ix

	ld (iy + 0), #36 ; ld (hl), nn
	ld (iy + 1), a
	ld (iy + 2), #24 ; inc h
	inc iy : inc iy : inc iy

	djnz 1b

	ld (ix + 0), #c9	; ret	

	ld (iy - 1), #c3	; jp
	ld (iy + 0), low CHMN13_CYCLE
	ld (iy + 1), high CHMN13_CYCLE

	dup 4 : inc ix : inc iy : edup
	pop bc
	ret