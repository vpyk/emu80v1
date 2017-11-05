;
;  Emu80 v. 1.81
;  (c) Viktor Pykhonin <pyk@mail.ru>, 1997-1998
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
;

; File: EMUIO.ASM

; Содержит процедуры, эмулирующие внешние устройства ПК

.model tiny

public scr_beg
public scr_end
public save_byte
public load_byte
public enable_ints
public disable_ints
public cur_xy
public process_port_c
public port_c
public process_int

extrn symtable_ptr:word
extrn cur_offs:word
extrn sh_scrbeg:word
extrn sh_scrlen:word
extrn sh_width:byte
extrn sh_height:byte
extrn f_scr:byte
extrn f_vid:byte
extrn refresh_scr:near
extrn set_video_auto:near
extrn key_bytes:byte
extrn ctrl_keys:byte
;extrn light_led:near
extrn led_state:byte
extrn rst6:near
extrn set_delay_w_dma:near
extrn set_delay_wo_dma:near

.code

; Разрешение прерываний (EI)
enable_ints proc
IF TYPE_P 
	mov byte ptr cs:[int_flag],1
	pushf
	cmp byte ptr cs:[int_req],0
	jz ei1
	call process_int
;	mov byte ptr cs:[int_flag],1
ei1:	popf
	ret
ELSEIF TYPE_A OR TYPE_M
        ret
ELSEIF TYPE_R
; в РК-86 - включение динамика
        pushf
        push ax
        in al,61h
        and al,0fch
        or al,2
        out 61h,al
        pop ax
        popf
        ret
ENDIF
enable_ints endp

; Запрещение прерываний (DI)
disable_ints proc
IF TYPE_P
       mov byte ptr cs:[int_flag],0
       ret
ELSEIF TYPE_A OR TYPE_M
        ret
ELSEIF TYPE_R
; в РК-86 - выключение динамика
        pushf
        push ax
        in al,61h
        and al,0fch
        out 61h,al
        pop ax
        popf
        ret
cFB:;ei ; в РК-86 - включение динамика
ENDIF
disable_ints endp

process_int proc
       cmp byte ptr cs:[int_flag],0
       jnz pi2
       mov byte ptr cs:[int_req],1
       jmp pi1
pi2:   mov byte ptr cs:[int_flag],0
       mov byte ptr cs:[int_req],0
       push bp
       cmp byte ptr ds:[si],76h ; HLT
       je pi3
       dec si
pi3:   call rst6
       pop bp
pi1:   ret
process_int endp

int_flag db 0 ; 1, если разрешены прерывания
int_req db 0 ; 1, если есть отложеный запрос на прерывание

cursor_state db 0       ; 1, если координата X положения курсора принята,
                        ; а Y - еще нет
cursor_x db ?           ; координата X положения курсора

IF TYPE_P
scr_beg dw 77bdh        ; начало области видеопамяти 64x25
scr_end dw 7f0dh+74     ; ее конец
ELSEIF TYPE_R OR TYPE_M
scr_beg dw 77c2h
scr_end dw 7f12h+74
ELSEIF TYPE_A
scr_beg dw 0e2c2h
scr_end dw 0ea12h+74
ENDIF

; Вызывается при попытке записи в память
; BP-адрес, AH-значение

save_byte proc
        cmp bp,word ptr es:[scr_beg]
        jae sb1
sb0:    mov byte ptr ds:[bp],ah         ; пишем
sb00:   ret
sb1:    cmp bp,word ptr es:[scr_end]
        ja sb2
; Попали в видеопамять
        mov byte ptr ds:[bp],ah
        sub bp,word ptr es:[scr_beg]
        push bx
        push ax
        mov ax,bp
        mov bl,78
        div bl
        mov bh,160
        mov bl,ah
        mul bh
        xor bh,bh
        add ax,bx
        add ax,bx
        mov bp,ax
        pop ax
        push ax
        mov bx,word ptr es:[symtable_ptr]
        mov al,ah
        test al,al
        jns sb55
        xor al,al
sb55:
        xlat es:[bx]
        push es
        mov bx,0b800h
        mov es,bx
        mov byte ptr es:[bp],al
        pop es
        pop ax
        pop bx
        ret

sb2:
IF TYPE_P
        cmp bp,0d800h
        jb sb0
        cmp bp,0d900h
        jae sb3
        jmp crt_out
sb3:    cmp bp,0da00h
        jae sb4
        jmp ppi1_out
sb4:    cmp bp,0db00h
        jae sb5
        ret
sb5:    cmp bp,0dc00h
        jae sb6
        jmp dma_out
sb6:    ret
ELSEIF TYPE_R
        cmp bp,8000h
        jb sb0
        cmp bp,0a000h
        jae sb3
        jmp ppi1_out
sb3:    cmp bp,0c000h
        jae sb4
        jmp ppi2_out
sb4:    cmp bp,0e000h
        jae sb5
        jmp crt_out
sb5:    jmp dma_out
ELSEIF TYPE_M
        cmp bp,8000h
        jb sb0
        cmp bp,0c000h
        jae sb3
        ret
sb3:    cmp bp,0c800h
        jae sb4
        jmp ppi1_out
sb4:    cmp bp,0d000h
        jae sb5
        jmp ppi2_out
sb5:    cmp bp,0d800h
        jae sb6
        jmp crt_out
sb6:    cmp bp,0e000h
        jae sb7
        jmp pit_out
sb7:    cmp bp,0f800h
        jae sb8
        ret
sb8:    jmp dma_out
ELSEIF TYPE_A
        cmp bp,0ec00h
        jb sb0
        cmp bp,0ed00h
        jae sb3
        jmp pit_out
sb3:    cmp bp,0ee00h
        jae sb4
        jmp ppi1_out
sb4:    cmp bp,0ef00h
        jae sb5
        jmp ppi2_out
sb5:    cmp bp,0f000h
        jae sb6
        jmp crt_out
sb6:    cmp bp,0f100h
        jae sb7
        jmp dma_out
sb7:    ret
ENDIF
save_byte endp

; Эмуляция ВГ75
crt_out proc
        test bp,1h
        jz cp1
        cmp ah,0
        jz cp3
        mov byte ptr es:[crt_mode],0     ; режим управления курсором
        mov byte ptr es:[cursor_state],0 ; запись в управляющий регистр
        ret
cp1:    cmp byte ptr es:[crt_mode],0
        jnz cp4                          ; управляющая команда
        cmp byte ptr es:[cursor_state],0 ; запись в регистр данных
        jne cp2
        mov byte ptr es:[cur_x],ah       ; запоминаем X и факт его записи
        inc byte ptr es:[cursor_state]
        ret
cp2:    dec byte ptr es:[cursor_state]   ; устанавливаем курсор
        mov byte ptr es:[cur_y],ah
        push ax
        push bx
        push dx
        mov dl,byte ptr es:[cur_x]
        mov dh,ah
        mov ah,2
        xor bh,bh
IF TYPE_P
        sub dx,0304h    ; коррекция положения курсора
ELSEIF TYPE_R OR TYPE_A OR TYPE_M
        sub dx,0308h
ENDIF
        add dx,word ptr es:[cur_offs]
        int 10h
        pop dx
        pop bx
        pop ax
        ret
cp3:    mov byte ptr es:[crt_mode],1     ; управляющий режим
        mov byte ptr es:[crt_param_n],0
        ret
cp4:    inc byte ptr es:[crt_param_n]
        cmp byte ptr es:[crt_param_n],1
        jnz cp5
        and ah,7fh
        mov byte ptr es:[crt_cols],ah
        ret
cp5:    cmp byte ptr es:[crt_param_n],2
        jnz cp6
        and ah,3fh
        mov byte ptr es:[crt_lines],ah
cp6:    ret
crt_out endp

cur_xy:
cur_x:
db 0
cur_y:
db 0


; Эмуляция PPI
ppi1_out proc
IF TYPE_P
        cmp bp,0d902h
        je ppi1_c
        cmp bp,0d903h
        je ppi1_r
        cmp bp,0d900h
        je ppi1_a
        ret
ELSEIF TYPE_M
        cmp bp,0c002h
        je ppi1_c
;       cmp bp,0c003h
;       je ppi1_r
        cmp bp,0c001h
        je ppi1_a
        ret
ELSEIF TYPE_R
        cmp bp,8002h
        je ppi1_c
        cmp bp,8000h
        je ppi1_a
        ret
ELSEIF TYPE_A
        cmp bp,0ed02h
        je ppi1_c
        cmp bp,0ed00h
        je ppi1_a
        ret
ENDIF

; Обрабатывает состояние порта C ППА
process_port_c proc
        push ax
        mov ah, byte ptr es:[port_c]
        jmp kpc4
process_port_c endp


; запись в порт C ППА ВВ55
; бит 1 - управление динамиком (0-писк)
ppi1_c:
        mov byte ptr es:[port_c],ah
        push ax
kpc4:
IF TYPE_P
        in al,61h
        test ah,2
        jnz kpc1
        or al,03h
        jmp kpc2
kpc1:   and al,0fch
kpc2:   out 61h,al
ELSEIF TYPE_M
        in al,61h
        test ah,2
        jz kpc1
        or al,03h
        jmp kpc2
kpc1:   and al,0fch
kpc2:   out 61h,al
ENDIF
;        cmp byte ptr es:[f_vid],2
;        jne kpc3

        and ah,08h
        ror ah,1
        and byte ptr es:[led_state],0fbh
        or byte ptr es:[led_state],ah
;       call light_led

kpc3:   pop ax
kpc5:   ret

; запись в регистр управляющего слова (РУС) ППА
; отслеживаем только звук (см. выше)
IF TYPE_P
ppi1_r:
        cmp ah,80h
        jae kpc5
        push ax
        push cx
        mov cl,ah
        ror cl,1
        and cl,03h
        mov al,0feh
        rol al,cl
        and byte ptr es:[port_c],al
        and ah,1
        rol ah,cl
        or byte ptr es:[port_c],ah
        mov ah, byte ptr es:[port_c]
        pop cx
        jmp kpc4
ENDIF

ppi1_a:
        mov byte ptr es:[port_a_val],ah
        ret
ppi1_out endp

port_c db 0
port_a_val db 0ffh ; значение, записанное в порт A ППА (B для Микроши)

; Эмуляция PIT
pit_out proc
IF TYPE_M
        cmp bp,0d803h
        jne pp1
        push ax
        mov al,0b6h
        out 43h,al
        pop ax
        ret
pp1:    push ax
        mov al,ah
        out 42h,al
        pop ax
ENDIF
        ret
pit_out endp

ppi2_out:
        ret

dma_out proc
        and bp,000fh
        cmp bp,4
        jne do1
        push cx
        mov cl,8
        ror word ptr es:[dma_begadr],cl
        pop cx
        mov byte ptr es:[dma_begadr+1],ah
        ret
do1:    cmp bp,5
        jne do2
        push cx
        mov cl,8
        ror word ptr es:[dma_len],cl
        pop cx
        mov byte ptr es:[dma_len+1],ah
        ret
do2:    cmp bp,8
        jne do3
        cmp ah,80h
        je do5
        call set_delay_w_dma
        jmp do6
do5:    call set_delay_wo_dma
do6:    test ah,4
        jz do3
        and word ptr es:[dma_len],3fffh
        push ax
        mov ax,word ptr es:[dma_begadr]
        mov word ptr es:[sh_scrbeg],ax
        mov ax,word ptr es:[dma_len]
        inc ax
        mov word ptr es:[sh_scrlen],ax
        mov al,byte ptr es:[crt_lines]
        inc al
        mov byte ptr es:[sh_height],al
        mov al,byte ptr es:[crt_cols]
        inc al
        mov byte ptr es:[sh_width],al
; Делим длину экрана на количество столбцов
        push cx
        mov cl,al
        mov ax,word ptr es:[sh_scrlen]
        div cl
        pop cx
; Сравниваем результат с числом строк и берем меньшее
        cmp al,byte ptr es:[sh_height]
        jae do4
        mov byte ptr es:[sh_height],al
do4:    pop ax
; refresh screen
        cmp byte ptr es:[f_scr],2
        jne do3
        push ax
        push bx
        push cx
        push dx
        push si
        push di
        call set_video_auto
        call refresh_scr
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
do3:    ret
dma_out endp

crt_param_n db 0
crt_mode db 0 ; 0-курсор, 1-управл.
crt_lines db ?
crt_cols db ?
dma_begadr dw ?
dma_len dw ?

; Вызывается при попытке чтения из памяти
; BP-адрес Возврат : AH-значение

load_byte proc
IF TYPE_P
        cmp bp,0d800h
        jb lb0
        cmp bp,0d900h
        jae lb3
        jmp crt_in
lb3:    cmp bp,0da00h
        jae lb4
        jmp ppi1_in
lb4:    cmp bp,0db00h
        jae lb5
        ret
lb5:    cmp bp,0dc00h
        jae lb6
        jmp dma_in
lb6:    cmp bp,0f000h
        jae lb0
        mov ah,0ffh
        ret
ELSEIF TYPE_R
        cmp bp,8000h
        jb lb0
        cmp bp,0a000h
        jae lb3
        jmp ppi1_in
lb3:    cmp bp,0c000h
        jae lb4
        jmp ppi2_in
lb4:    cmp bp,0e000h
        jae lb0
        jmp crt_in
ELSEIF TYPE_M
        cmp bp,8000h
        jb lb0
        cmp bp,0c000h
        jae lb3
        ret
lb3:    cmp bp,0c800h
        jae lb4
        jmp ppi1_in
lb4:    cmp bp,0d000h
        jae lb5
        jmp ppi2_in
lb5:    cmp bp,0d800h
        jae lb6
        jmp crt_in
lb6:    cmp bp,0e000h
        jae lb7
        jmp pit_in
lb7:    cmp bp,0f800h
        jae lb0
lb8:    jmp dma_in
ELSEIF TYPE_A
        cmp bp,0ec00h
        jb lb0
        cmp bp,0ed00h
        jae lb3
        jmp pit_in
lb3:    cmp bp,0ee00h
        jae lb4
        jmp ppi1_in
lb4:    cmp bp,0ef00h
        jae lb5
        jmp ppi2_in
lb5:    cmp bp,0f000h
        jae lb0
        jmp crt_in
ENDIF
lb0:    mov byte ptr ah,ds:[bp];                ; читаем
lb00:   ret
load_byte endp

crt_in:
        mov ah,20h
        ret
dma_in:
ppi2_in:
pit_in:
        mov ah,0ffh
        ret

ppi1_in proc
        push cx
        push ax
        mov ax,bp
        and al,03h
IF TYPE_M
        cmp al,0
ELSE
        cmp al,1
ENDIF
        jne ppi1_1
        push bx
        mov bx, offset key_bytes
        mov cx,8
        mov ah,0ffh
        mov al,byte ptr es:[port_a_val]
ppi1_2: rcr al,1
        jc ppi1_3
        and ah, byte ptr es:[bx]
ppi1_3: inc bx
        loop ppi1_2
        pop bx
ppi1_5: mov cl,ah
        pop ax
        mov ah,cl
        pop cx
        ret
ppi1_1: cmp al,2
        je ppi1_4
        mov ah,byte ptr es:[port_a_val]
        jmp ppi1_5
ppi1_4: mov ah,byte ptr es:[ctrl_keys]
        mov al,byte ptr es:[port_c]
        and al,0fh
        or ah,al
        jmp ppi1_5
ppi1_in endp

end
