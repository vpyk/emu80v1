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

;File: LOADER.ASM

; Содержит загрузочную часть и собственно интерпретатор инструкций 8080

.model tiny

public fin
public setparms
public quit
public set_video_auto
public set_delay_w_dma
public set_delay_wo_dma

extrn last:byte
extrn emF809:near
extrn emF803:near
extrn emF81B:near
extrn emF812:near
extrn emF80C:near
extrn emF806:near
extrn code_tbl:word
extrn code_tbl_m:word
extrn code_tbl_m2:word
extrn inittimer:near
extrn getcount:near
extrn f_speed:byte
extrn f_vid:byte
extrn f_f809:byte
extrn f_scr:byte
extrn f_font:byte
extrn setup:near
extrn f_reset:byte
extrn get_key:near
extrn test_key:near
extrn prep_key:near
extrn f_f10:byte
extrn flash_key:near
extrn setscr25:near
extrn setscr30:near
extrn setscr43:near
extrn refresh_scr:near
extrn load_8x16:near
extrn load_8x16rk:near
extrn load_8x8:near
extrn load_8x8rk:near
extrn setw8:near
extrn set_vga400:near
extrn set_vga350:near
extrn symtable_ptr:word
extrn test_vga:near
extrn test_win:near
extrn test_nt:near
extrn disable_vga:near
extrn set_fontoem:near
extrn enable_hookf809:near
extrn init_sound:near
extrn sh_height:byte
extrn get_09_vect:near
extrn set_new_09_vect:near
extrn restore_09_vect:near
extrn close_file:near
extrn set_cga_mode:near
extrn test_ega:near
extrn find_path:near
extrn com_path:byte
extrn com_path_len:word
;extrn light_led:near
;extrn process_port_c:near
extrn process_int:near
extrn disable_ints:near

; такты на 100 мкс
IF TYPE_P
delay_norm=100 ; нормальная работа процессора 8080
delay_dma=69 ; при включенном ПДП
ELSE
delay_norm=89 ; нормальная работа процессора 8080
delay_dma=58 ; при включенном ПДП
ENDIF

.code
.startup
; COM-программа захватывает всю память,
; поэтому лишнюю нужно освободить
        mov bx, offset last
        mov cl,4
        shr bx,cl
        add bx,17
        mov ah,4ah
        int 21h
        mov ax,bx
        shl ax,cl
        dec ax
        mov sp,ax

        mov ah,48h
        mov bx,4096
        int 21h
        jnc l4
        jmp error

l4:     push ax

; Создаем полный путь к файлу с ПЗУ
        call find_path
        lea di,com_path
        add di,word ptr [com_path_len]
        lea si,romname
        mov cx,9 ; длина имени файла с ПЗУ + 1 нулевой байт
        rep movsb

; Открываем файл с ПЗУ
        lea dx,com_path; romname
        mov ax,3d00h
        xor cx,cx
        int 21h         ; откраваем файл с ПЗУ
        jnc l5
        jmp error

l5:     mov bx,ax

        pop ax
        
; Очистка памяти сегмента 8080
        push ax
        push es
        mov es,ax
        mov cx,8000h
        xor ax,ax
        xor di,di
        rep stosw
        pop es
        pop ax
        
        mov ds,ax

        mov ah,3fh
IF TYPE_P OR TYPE_A
        mov cx,1000h
        mov dx,0f000h
ELSEIF TYPE_R OR TYPE_M
        mov cx,0800h
        mov dx,0f800h
ENDIF
        int 21h         ; читаем ПЗУ
        jc error

        mov ah,3eh
        int 21h         ; закрываем файл
        jc error

; Нужно, чтобы программы, ожидающие vertical refresh путем опроса порта
; ВГ75 не зависали - подставим им этот бит
; А также пусть не будут нажаты клавиши УС, НР и РУС/ЛАТ.
IF TYPE_P
        mov byte ptr ds:[0d801h],20h
        mov byte ptr ds:[0d902h],0f0h
ELSEIF TYPE_R
        mov byte ptr ds:[0c001h],20h
        mov byte ptr ds:[08002h],0f0h
ELSEIF TYPE_A
        mov byte ptr ds:[0ef01h],20h
        mov byte ptr ds:[0ee02h],0f0h
ELSEIF TYPE_M
        mov byte ptr ds:[0d001h],20h
        mov byte ptr ds:[0c002h],0f0h
ENDIF

        call get_09_vect        ; запоминаем вектор прерывания int 09 клав.

        call test_vga
        jz l1
        mov es:f_vgapres,0
        call disable_vga        ; отсутствует VGA - запретить режим 78x30
        call test_ega
        jnz l1
        call set_cga_mode       ; отсутствует EGA - запретить режим Auto
l1:     call test_win
        jz l2
        call set_fontoem        ; работает Windows - не загр. фонта по умолч.

l2:     call test_nt
        test al,al
        jz l3
        call enable_hookf809    ; работает под NT - включить перехват 0F809H
        call set_fontoem        ; а также запретить загрузку фонта

l3:     call inittimer
        call init_sound
        call cls
        call anal_params        ; Разбираем параметры из модуля интерфейса

;#########################################################################

; Поехали !

call getcount   ; Получаем текущее значение счетчика таймера 8254
mov word ptr es:[init_mtick],ax
mov word ptr es:[tick_count],0
mov word ptr es:[count2],200

; Загрузка начальных значений в регистры 8080
mov cx,0
mov dx,0
mov bx,0
mov di,76cfh
mov si,0f800h

jmp interpret

error:  mov ah,9
        lea dx,errmes
        int 21h
        mov ax,es
        mov ds,ax
        int 20h
errmes  db 'Error',10,10,13,'$'

; Текущая задержка. Используется при нормальной скорости
cur_speed dw delay_dma

; Устанавливает скорость с DMA, если установлена норм. скорость
set_delay_w_dma proc
        mov word ptr cs:[cur_speed],delay_dma
        cmp byte ptr cs:[f_speed],2
        jne sdn1
        mov word ptr cs:[delay],delay_dma
sdn1:   ret
set_delay_w_dma endp

; Устанавливает скорость без DMA, если установлена норм. скорость
set_delay_wo_dma proc
        mov word ptr cs:[cur_speed],delay_norm
        cmp byte ptr cs:[f_speed],2
        jne sdd1
        mov word ptr cs:[delay],delay_norm
sdd1:   ret
set_delay_wo_dma endp

f_chscr db 1    ; 1, если нужно перенастраивать экран
f_vgapres db 1  ; 1, если присутствует VGA

; Перенастройка режима экрана в соответствии с переменными в модуле инт-са
set_video proc
        cmp es:[f_scr],0
        jnz sv1
        jmp set_video_25
sv1:    cmp es:[f_scr],1
        jne sv2
        jmp set_video_30
sv2:    call set_video_auto
        ret
set_video endp

load_font8x16 proc
;       cmp es:[f_vgapres],0
;       jz lf16_2
        cmp es:[f_font],0
        jz lf16_2
        call load_8x16rk
        call setw8
        jmp lf16_3
lf16_2: ;call load_8x16
lf16_3: ret
load_font8x16 endp

load_font8x8 proc
        cmp es:[f_font],0
        jz lf8_2
        call load_8x8rk
        call setw8
        jmp lf8_3
lf8_2:  ;call load_8x8
lf8_3:  ret
load_font8x8 endp

set_video_25 proc
        cmp es:[f_vgapres],0
        jz sv25_1
        call set_vga400
sv25_1: call setscr25
        call load_font8x16
        ret
set_video_25 endp

set_video_30 proc
        call set_vga400
        call setscr25
        call setscr30
        call load_font8x16
        ret
set_video_30 endp

set_video_43 proc
        cmp es:[f_vgapres],0
        jz sv43_1
        call set_vga350
sv43_1: call setscr43
        call load_font8x8
        ret
set_video_43 endp

set_video_auto proc
        cmp es:[f_vgapres],0
        jz sva1
        cmp byte ptr es:[sh_height],30
        jbe set_video_30
sva1:   jmp set_video_43
set_video_auto endp

; Разбор параметров из модуля интерфейса
anal_params proc
        cmp es:[f_speed],0
        jnz ap1
        mov word ptr es:[delay],0fffh
        jmp ap2
ap1:    cmp es:[f_speed],1
        jnz ap5
        mov word ptr es:[delay],delay_norm
        jmp ap2
ap5:    push ax
        mov ax,word ptr es:[cur_speed]
        mov word ptr es:[delay],ax
        pop ax
ap2:    cmp es:[f_vid],2
        je ap3
        call restore_09_vect
        cmp es:[f_vid],0
        jz ap8
        mov word ptr es:[c_table],offset code_tbl_m
        jmp ap4
ap8:    mov word ptr es:[c_table],offset code_tbl
        mov word ptr es:[cur_speed],delay_dma  ; поск-ку в этом режиме не отсл
        jmp ap4                                ; зап. в контр. DMA
ap3:    call set_new_09_vect
        mov word ptr es:[c_table],offset code_tbl_m2
;       call process_port_c
ap4:    cmp byte ptr es:[f_chscr],0
        jz ap7
        call set_video
        call refresh_scr
ap7:    mov byte ptr es:[f_chscr],1 ; зачем ???
        ret
anal_params endp

; Вызывается при нажатии F10
setparms proc
        pushf
        push ax
        mov al,byte ptr es:[f_scr]
        mov ah,byte ptr es:[f_font]
        call restore_09_vect            ; восстановить для диалога
        call setup
        xor al,byte ptr es:[f_scr]
        xor ah,byte ptr es:[f_font]
        or al,ah
        mov byte ptr es:[f_chscr],al
        cmp byte ptr es:[f_vid],0
        jne sp1
        call enable_hookf809
sp1:    cmp byte ptr es:[f_vgapres],1
        je sp2
        cmp byte ptr es:[f_scr],0
        jne sp2
        call set_fontoem
sp2:    pop ax
        call anal_params
        popf
        ret
setparms endp

; Выход из программы
fin:
exit:        
        mov ax,es
        mov ds,ax
quit:
        call restore_09_vect
        call init_sound
        cmp cs:[f_vgapres],0
        jz q1
        call set_vga400
        call load_8x16
q1:     mov ax,3
        int 10h
        lea dx,copyrmes
        mov ah,9
        int 21h
        int 20h

IF TYPE_P
copyrmes db '# Эмулятор ПК "Партнер"  Version 1.81p #',10,13
ELSEIF TYPE_R
copyrmes db '# Эмулятор ПК "Радио-86РК"  Version 1.81r #',10,13
ELSEIF TYPE_A
copyrmes db '# Эмулятор ПК "Апогей"  Version 1.81a #',10,13
ELSEIF TYPE_M
copyrmes db '# Эмулятор ПК "Микроша"  Version 1.81m #',10,13
ENDIF
         db 'Автор: В.А.Пыхонин',10,13
         db 'Нижний Новгород 1998 г.',10,13,24h

; Очистка экрана
cls proc
        mov ax,0600h
        mov cx,0
        mov dx,184fh
        mov bh,7
        int 10h
        ret
cls endp

; Имя файла с ПЗУ
IF TYPE_P
romname db 'romp.bin',0
ELSEIF TYPE_R
romname db 'romr.bin',0
ELSEIF TYPE_A
romname db 'roma.bin',0
ELSEIF TYPE_M
romname db 'romm.bin',0
ENDIF

; Текущая средняя длительность команды 8080 или 0
delay dw 0ffffh

; Текущая таблица инструкций 8080
c_table dw code_tbl_m

; сюда управление попадает 50 раз в секунду
inter7:
        mov word ptr es:[count2],200
        push ax
IF TYPE_P
       call process_int
ENDIF
;       cmp byte ptr es:[f_vid],2
;       jne inter11
;       call light_led
;inter11:
        call prep_key
        cmp byte ptr es:[f_f10],0
        jz inter8
        mov byte ptr es:[f_f10],0
        call flash_key
        call setparms
inter8:
        pop ax
        cmp byte ptr es:[f_reset],1
        jne inter5
;        jmp inter9
inter9: ; Reset
        mov byte ptr es:[f_reset],0
        mov cx,0
        mov dx,0
        mov bx,0
        mov di,76cfh
        mov si,0f800h
IF TYPE_P
        call disable_ints
ENDIF
        jmp inter5

inter2:        
; Берем адрес процедуры из таблицы ...
        mov bp,word ptr es:[c_table]
        push bx
        xor bh,bh
        mov bl,byte ptr [si]
        add bp,bx
        add bp,bx
        pop bx
        popf
        mov bp,word ptr es:[bp]
; вызываем ее ...
        call bp
        pushf
;       cmp word ptr es:[delay],0
;       jz inter5 ; нулевая задержка
        add bp,word ptr es:[tick_count]
        mov word ptr es:[tick_count],bp
        sub bp,word ptr es:[delay]
        jae inter3
inter5: popf
        jmp interpret ; к следующей команде

; сюда управление попадает каждые 100 мкс
inter3: mov word ptr es:[tick_count],bp
        mov bp,word ptr es:[init_mtick]
        push ax
inter4: call getcount
        sub ax,bp
        cmp ax,-119
        ja inter4
        add ax,bp
        mov word ptr es:[init_mtick],ax
        pop ax
        dec word ptr es:[count2]
        jnz inter10
        jmp inter7
inter10:popf
        jmp interpret

interpret:
        pushf

inter1:
IF TYPE_P OR TYPE_A
        cmp si,0f000h
ELSEIF TYPE_R OR TYPE_M
        cmp si,0f800h
ENDIF
        jb inter2

; Находимся в ПЗУ - проверяем перехватываемые адреса    
IF TYPE_P
        cmp si,0fd7bh
        jz _f803
        cmp si,0fce9h
        jz _f81b
        cmp si,0fda5h
        jz _f809
        cmp si,0fc81h
        jz _f812
        cmp si,0fc55h
        jz _f80c
        cmp si,0fba2h
        jz _f806
ELSEIF TYPE_R
        cmp si,0fe63h
        jz _f803
        cmp si,0fe72h
        jz _f81b
        cmp si,0fcbah
        jz _f809
        cmp si,0fe01h
        jz _f812
        cmp si,0fc46h
        jz _f80c
        cmp si,0fb98h
        jz _f806
ELSEIF TYPE_A
        cmp si,0fe61h
        jz _f803
        cmp si,0fe70h
        jz _f81b
        cmp si,0fcbah
        jz _f809
        cmp si,0fdffh
        jz _f812
        cmp si,0fc46h
        jz _f80c
        cmp si,0fb98h
        jz _f806
ELSEIF TYPE_M ; ###
        cmp si,0fed0h
        jz _f803
        cmp si,0feeah
        jz _f81b
        cmp si,0fd25h
        jz _f809
        cmp si,0fe7fh
        jz _f812
        cmp si,0fcabh
        jz _f80c
        cmp si,0fc0dh
        jz _f806
ENDIF
inter6: jmp inter2

tick_count dw ? ; счетчик тактов 8080
init_mtick dw ? ; значение счетчика 8254 PC
count2 dw ?     ; счетчик до 20 мс

; По адресу FFFF специально стоит C3 - ret

_f80c:  call emf80c
        mov si,0ffffh
        jmp inter1

_f806:  call emf806
        mov si,0ffffh
        jmp inter1

_f803:  call close_file ; Если работали с файлом, то его закрыть
        cmp byte ptr es:[f_vid],2
        je inter6
        call emf803
        cmp byte ptr es:[f_reset],1     ; пров. на Reset, поскольку
        je res_rom                      ; окно настроек м.б. вызвано и
        cmp byte ptr es:[f_vid],2
        je inter6
        mov si,0ffffh
        jmp inter1                      ; из этого обработчика

_f81b:  cmp byte ptr es:[f_vid],2
        je inter6
        call emf81b
        cmp byte ptr es:[f_reset],1
        je res_rom
        cmp byte ptr es:[f_vid],2
        je inter6
        mov si,0ffffh
        jmp inter1

_f809:  cmp byte ptr es:[f_f809],0
        jz inter6
        call emf809
        mov si,0ffffh
        jmp inter1

_f812:  popf
        call emf812
        pushf
        cmp byte ptr es:[f_vid],2
        je inter6
        mov si,0ffffh
        jmp inter1

res_rom:
        mov byte ptr es:[f_reset],0
        mov cx,0
        mov dx,0
        mov bx,0
        mov di,76cfh
        mov si,0f800h
;       call disable_ints
        jmp inter1

end
