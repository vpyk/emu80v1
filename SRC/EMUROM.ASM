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

;File: EMUROM.ASM

; Содержит процедуры, заменяющие некоторые стандартные из ПЗУ

.model tiny

public emf809
public emf803
public emf81b
public emf812
public emf80c
public emf806
public symtable_ptr
public cur_offs
public refresh_scr
public sh_height
public sh_width
public sh_scrbeg
public sh_scrlen
public close_file

extrn fin:near
extrn setparms:near
extrn f_reset:byte
extrn f_vid:byte
extrn getfilename:near
extrn filename:byte
extrn test_key:near
extrn get_key:near
extrn prep_key:near
extrn scr_beg:word
extrn scr_end:word
extrn f_scr:byte
extrn f_font:byte
extrn set_new_09_vect:near
extrn restore_09_vect:near
extrn cur_xy:word
extrn f_choose_file:byte
extrn f_synb:byte

.code

; Начало средней части экранной области 64x25
IF TYPE_P
begin_scr=77bdh
ELSEIF TYPE_R OR TYPE_M
begin_scr=77c2h
ELSEIF TYPE_A
begin_scr=0e2c2h
ENDIF

;Переменные, определяющие режим дисплея в режиме Авто
sh_scrbeg dw 5f69h  ; начало экранной области
sh_height dw 35     ; количество строк
sh_width db 78      ; количество символов в строке
sh_scrlen dw 78*35  ; длина экранной области (обычно sh_width*sh_height)

s_startline db 0    ; отступ сверху при отображении на PC

;####===-- Эмуляция 0F809H --===####
; Вывод символа на экран
; Вход:
; C - выводимый символ

emf809: pushf
        push ax
        push bx
        push cx
        push dx

        and cl,7fh
        
        cmp es:curstate,0
        je em09_g
        jmp em09stt

em09_g: cmp cl,20h      
        jl em09_b
        jmp em09norm

em09_b: cmp cl,8        ; стрелка влево
        jne em09_1
        mov dx,word ptr ds:curpos
IF TYPE_R OR TYPE_A OR TYPE_M
        sub dx,0308h
ENDIF
        dec dl
        cmp dl,-1
        je em09_c
        jmp em09spos
em09_c: mov dl,63
        dec dh
        cmp dh,-1
        je em09_d
        jmp em09spos
em09_d: mov dh,24
        jmp em09spos

em09_1:
        cmp cl,18h      ; стрелка вправо
        jne em09_2
        mov dx,word ptr ds:curpos
IF TYPE_R OR TYPE_A OR TYPE_M
        sub dx,0308h
ENDIF
        inc dl
        cmp dl,64
        je em09_e
        jmp em09spos
em09_e: mov dl,0
        inc dh
        cmp dh,25
        je em09_f
        jmp em09spos
em09_f: mov dh,0
        jmp em09spos

em09_2:
        cmp cl,19h      ; стрелка вверх
        jne em09_3
        mov dx,word ptr ds:curpos
IF TYPE_R OR TYPE_A OR TYPE_M
        sub dx,0308h
ENDIF
        dec dh
        cmp dh,-1
        jne em09spos
        mov dh,24
        jmp em09spos

em09_3:
        cmp cl,1ah      ; стрелка вниз
        jne em09_4
        mov dx,word ptr ds:curpos
IF TYPE_R OR TYPE_A OR TYPE_M
        sub dx,0308h
ENDIF
        inc dh
        cmp dh,25
        jne em09spos
        mov dh,0
        jmp em09spos

em09_4:
        cmp cl,7h       ; звуковой сигнал
        jne em09_5
        mov ax,0e07h
        mov bx,0
        int 10h
        jmp em09exit

em09_5:
        cmp cl,0ch      ; HOME
        jne em09_6
        mov dx,0
        jmp em09spos

em09_6:
        cmp cl,0dh      ; ВК
        jne em09_7
        mov dx,word ptr ds:curpos
IF TYPE_R OR TYPE_A OR TYPE_M
        sub dx,0308h
ENDIF
        mov dl,0
        jmp em09spos

em09_7:
        cmp cl,0ah      ; ПС
        jne em09_8
        mov dx,word ptr ds:curpos
IF TYPE_R OR TYPE_A OR TYPE_M
        sub dx,0308h
ENDIF
        jmp em09_a

em09spos:
        mov word ptr ds:curpos,dx
IF TYPE_R OR TYPE_A OR TYPE_M
        add word ptr ds:curpos,0308h
ENDIF
        jmp em09exit

em09_8:
        cmp cl,1fh      ; очистка экрана - СТР
        jne em09_9
        mov ax,0600h
        mov cx,0
        mov dx,word ptr es:[scr_dim]
        mov bh,7
        int 10h
        push es
        push di
        mov dx,ds
        mov es,dx
IF TYPE_P
        mov di,76d1h
        mov cx,78*30-1
ELSEIF TYPE_R OR TYPE_M
        mov di,76d0h
        mov cx,78*30
ELSEIF TYPE_A
        mov di,0e1d0h
        mov cx,78*30
ENDIF
        xor al,al
        cld
        rep stosb
        pop di
        pop es
        mov dx,0
        jmp em09spos

em09_9:
        cmp cl,1bh      ; АР2 (ESC)
        jne em09norm
        mov es:curstate,1
        jmp em09quit


em09norm: 
        mov dx,word ptr ds:curpos
IF TYPE_R OR TYPE_A OR TYPE_M
        sub dx,0308h
ENDIF
        mov bh,78
        mov al,dh
        mul bh
        xor dh,dh
        add ax,dx
        mov bx,ax
        mov ds:[bx+begin_scr],cl

        mov bx,cs:[symtable_ptr]
        mov al,cl
        xlat byte ptr es:symtable_ptr
        call pos_cursor_mon

        mov ah,0ah
        mov cx,1
        mov bx,0
        int 10h
        mov dx,word ptr ds:[curpos]
IF TYPE_R OR TYPE_A OR TYPE_M
        sub dx,0308h
ENDIF
        inc dl
        mov word ptr ds:curpos,dx
IF TYPE_R OR TYPE_A OR TYPE_M
        add word ptr ds:curpos,0308h
ENDIF
        cmp dl,64
        jne em09exit
        mov byte ptr ds:[curx],0
IF TYPE_R OR TYPE_A OR TYPE_M
        add byte ptr ds:curx,08h
ENDIF
em09_a: inc dh
        mov ds:cury,dh
IF TYPE_R OR TYPE_A OR TYPE_M
        add byte ptr ds:cury,03h
ENDIF
        cmp dh,25
        jne em09exit
        mov byte ptr ds:[cury],24
IF TYPE_R OR TYPE_A OR TYPE_M
        add byte ptr ds:cury,03h
ENDIF
        mov ax,0601h
        mov bh,07h
        mov cx,word ptr es:[cur_offs]
        xor cl,cl
        mov dx,word ptr es:[scr_dim]
        int 10h
        push es
        push si
        push di
        mov dx,ds
        mov es,dx
        mov si,begin_scr+78
        mov di,begin_scr
        mov cx,78*25
        cld
        rep movsb
        pop di
        pop si
        pop es
em09exit:        
        call pos_cursor_mon
        mov dx,word ptr ds:curpos
IF TYPE_R OR TYPE_A OR TYPE_M
        sub dx,0308h
ENDIF
        mov cl,78
        mov al,dh
        mul cl
        xor dh,dh
        add ax,dx
        add ax,begin_scr
IF TYPE_P
        mov word ptr ds:[7600h],ax
ELSEIF TYPE_R OR TYPE_M
        mov word ptr ds:[7600h],ax
ELSEIF TYPE_A
        mov word ptr ds:[0e100h],ax
ENDIF
em09quit:        
        pop dx
        pop cx
        pop bx
        pop ax
        popf
        ret

em09stt:
        cmp es:[curstate],1
        jne em09_10
        cmp cl,59h
        jne em09stterr
        mov es:[curstate],2
        jmp em09quit
em09_10:
        cmp es:[curstate],2
        jne em09_11
        sub cl,20h
        mov ds:cury,cl
IF TYPE_R OR TYPE_A OR TYPE_M
        add byte ptr ds:cury,03h
ENDIF
        mov es:[curstate],3
        jmp em09quit
em09_11:
        sub cl,20h
        mov ds:curx,cl
IF TYPE_R OR TYPE_A OR TYPE_M
        add byte ptr ds:curx,08h
ENDIF
        mov es:[curstate],0
        jmp em09exit
em09stterr:
        mov es:[curstate],0
        jmp em09quit

pos_cursor proc
        push ax
        push bx
        push dx
        mov dx,word ptr es:[cur_xy]
IF TYPE_R OR TYPE_A OR TYPE_M
        sub dx,0308h
ELSEIF TYPE_P
        sub dx,0304h
ENDIF
        add dx,word ptr es:[cur_offs]
        mov ah,2
        mov bh,0
        int 10h
        pop dx
        pop bx
        pop ax
        ret
pos_cursor endp

pos_cursor_mon proc
        push ax
        push bx
        push dx
        mov dx,word ptr ds:[curpos]
        mov word ptr es:[cur_xy],dx
IF TYPE_R OR TYPE_A OR TYPE_M
        sub dx,0308h
ENDIF
        add dx,word ptr es:[cur_offs]
        mov ah,2
        mov bh,0
        int 10h
        pop dx
        pop bx
        pop ax
        ret
pos_cursor_mon endp

; Переменные положения курсора в сегменте памяти 8080
; (обычно устанавливаются Монитором).
;curpos:
;curx    db 0
;cury    db 0
IF TYPE_P
curpos=7602h
curx=7602h
cury=7603h
ELSEIF TYPE_R OR TYPE_M
curpos=7602h
curx=7602h
cury=7603h
ELSEIF TYPE_A
curpos=0e102h
curx=0e102h
cury=0e103h
ENDIF
curstate db 0

; Текущая символьная таблица
symtable_ptr dw symtable

; Таблица перекодировки для CP866
symtable:
 db 0,'■■▀■■▐█ ',15,' ',24,'  ',26,25
 db '■▌■█▄███   │─',27,9,' '
 db ' !"#$%&',27h,'()*+,-./'
 db '0123456789:;<=>?'
 db '@ABCDEFGHIJKLMNO'
 db 'PQRSTUVWXYZ[\]^_'
 db 'ЮАБЦДЕФГХИЙКЛМНО'
 db 'ПЯРСТУЖВЬЫЗШЭЩЧ▒'

; Таблица перекодировки для загружаемого знакогенератора РК
symtablerk:
 db 00h,01h,02h,03h,04h,05h,06h,07h,08h,09h,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh
 db 10h,11h,12h,13h,14h,15h,16h,17h,18h,19h,1Ah,1Bh,1Ch,1Dh,1Eh,1Fh
 db 20h,21h,22h,23h,24h,25h,26h,27h,28h,29h,2Ah,2Bh,2Ch,2Dh,2Eh,2Fh
 db 30h,31h,32h,33h,34h,35h,36h,37h,38h,39h,3Ah,3Bh,3Ch,3Dh,3Eh,3Fh
 db 40h,41h,42h,43h,44h,45h,46h,47h,48h,49h,4Ah,4Bh,4Ch,4Dh,4Eh,4Fh
 db 50h,51h,52h,53h,54h,55h,56h,57h,58h,59h,5Ah,5Bh,5Ch,5Dh,5Eh,5Fh
 db 0D0h,0D1h,0D2h,0D3h,0D4h,0D5h,0D6h,0D7h
 db 0D8H,0D9h,0DAh,0DBh,0DCh,0DDh,0DEh,0DFh
 db 0F0h,0F1h,0F2h,0F3h,0F4h,0F5h,0F6h,0F7h
 db 0F8H,0F9h,0FAh,0FBh,0FCh,0FDh,0FEh,0FFh


;####===-- Эмуляция 0F803H --===####
; Ввод символа с клавиатуры с ожиданием нажатия
; Выход:
; A - считанный символ

emf803: push bx
        push cx
        push dx

em03_1:
;       mov ax,0
;       int 16h
        call get_key
        
        cmp ax,4400h ;F10
        jne em03_2
        call setparms
        cmp byte ptr es:[f_reset],1
        je em03exit
        cmp byte ptr es:[f_vid],2
        je em03exit
        jmp em03_1
em03_2:
        call scan2rk
        cmp al,'А'
        je em03_1

em03exit:        
        pop dx
        pop cx
        pop bx
        ret

; Таблица перекодировки для клавиатуры
keytable:
 db '@ABCDEFGHIJKLMNO'
 db 'PQRSTUVWXYZ[\]^_'
 db 'abwgdevzijklmnop'
 db 'rstufhc~{}',27h,'yx|`q'
 db 'abwgdevzijklmnop'
 db 'АААААААААААААААА'
 db 'АААААААААААААААА'
 db 'АААААААААААААААА'
 db 'rstufhc~{}',27h,'yx|`q'
 db 'АААААААААААААААА'

; Таблица перекодировки клавиатуры для расширенных клавиш
; Конец таблицы - db 0
keytbl2:
 db 4bh,8h
 db 4dh,18h
 db 48h,19h
 db 50h,1ah
 db 47h,0ch
 db 3bh,0h
 db 3ch,1h
 db 3dh,2h
 db 3eh,3h
 db 3fh,4h
 db 53h,1h
 db 52h,3h
 db 49h,1fh
 db 0

; Преобразует скан-код клавиши в код клавиши РК, используя keytbl2
scan2rk proc
        cmp al,0
        je srk_ext
        
        cmp al,60h
        jb srk_tstbsp
        sub al,60h
        lea bx,keytable
        xlat byte ptr es:keytable
        ret
srk_tstbsp:
        cmp ax,0e08h
        je srk_4
        ret
srk_4:        
        mov al,7fh
        ret
srk_ext:
        lea bx,keytbl2
srk_2:  
        cmp ah,byte ptr es:[bx]
        je srk_3
        inc bx
        inc bx
        cmp byte ptr es:[bx],0
        jne srk_2
        mov al,'А'
        ret
srk_3:
        mov al,byte ptr es:[bx+1]
        ret
scan2rk endp

;####===-- Эмуляция 0F81BH --===####
; Ввод символа с клавиатуры без ожидания нажатия
; Выход:
; A - считанный символ (FF - клавиша не нажата, FE - клавиша РУС/ЛАТ)
emf81b: push bx
        push cx
        push dx
        
em1b_4: ;mov ah,01h
;        int 16h
        call test_key
        
        jz em1b_3
        
;        mov ah,0
;        int 16h
        call get_key

        cmp ax,4400h ;F10
        jne em1b_2
        call setparms
        cmp byte ptr es:[f_reset],1
        je em1bexit
        cmp byte ptr es:[f_vid],2
        je em1bexit
        jmp em1b_4
em1b_3:
        push es
        mov ax,40h
        mov es,ax
        mov al,es:[17h]
        pop es
        and al,08h
        mov al,0ffh
        jz em1bexit
        mov al,0feh
        jmp em1bexit

em1b_2:
        call scan2rk
        cmp al,'А'
        jne em1bexit
        mov al,0ffh

em1bexit:        
        pop dx
        pop cx
        pop bx
        ret



;####===-- Эмуляция 0F812H --===####
; Проверка нажатия клавиши

emf812: push bx
        push cx
        push dx

;       mov ah,01h
;       int 16h
        call test_key

        mov al,0
        jz em12_1
        mov al,0ffh
em12_1: test al,al
        pop dx
        pop cx
        pop bx
        ret

; Флаг - 1, если происходит чтение из файла
f_file_open db 0

; Дескриптор файла или 0 при ошибке
file_id dw 0

; Запрашивает имя и открывает файл на запись
; Если установлен признак записи синхробайта,
; то записывает его (0E6H)
open_file_write proc
        call restore_09_vect
        mov byte ptr cs:[f_choose_file],0
        call getfilename
        call set_appropr_09_vect
        lea dx,filename
        mov cx,20h
        mov ah,3ch
of0:    int 21h
        mov word ptr [file_id],0
        jc of1
        mov word ptr [file_id],ax
of1:    mov byte ptr [f_file_open],1
        cmp byte ptr [f_synb],0
        jz of2
        cmp word ptr [file_id],0
        jz of2

        ; Пишем синхробайт
        mov bx,ax
        mov cx,1
        lea dx,syn_byte
        mov ah,40h
        int 21h

of2:    ret
syn_byte db 0e6h
open_file_write endp

; Запрашивает имя и открывает файл на чтение
; Если формат с синхробайтом, то пропускает первый байт (0E6H)
open_file_read proc
        call restore_09_vect
        mov byte ptr cs:[f_choose_file],1
        call getfilename
        call set_appropr_09_vect
        lea dx,filename
        xor cl,cl
        mov ax,3d00h
        int 21h
        mov word ptr [file_id],0
        jc ofr3
        mov word ptr [file_id],ax
ofr3:   mov byte ptr [f_file_open],1
; Проверяем формат
        ; Читаем первые 5 байт
        mov bx,word ptr [file_id]
        test bx,bx
        jz ofr1
        mov cx,5
        lea dx,first_5_bytes
        mov ah,3fh
        int 21h
        test ax,ax
        jz ofr1
        ; Восстанавливаем позицию в файле
        push ax
        mov ax,4200h
        mov bx,word ptr [file_id]
        xor cx,cx
        xor dx,dx
        int 21h
        ; Анализируем формат
        pop ax
        cmp byte ptr [first_5_bytes],0e6h
        jne ofr1
        cmp ax,5
        jne ofr2
        cmp word ptr [first_5_bytes+1],0e6e6h
        jne ofr2
        cmp word ptr [first_5_bytes+3],0e6e6h
        je ofr2
        cmp byte ptr [first_5_bytes+4],0e6h
        jne ofr1
ofr2:   mov bx,word ptr [file_id] ; Пропускаем первый байт E6
        mov cx,1
        lea dx,first_5_bytes
        mov ah,3fh
        int 21h
ofr1:   ret        
first_5_bytes db 5 dup (0)
open_file_read endp

; Закрывает открытый файл
close_file proc
        pushf
        push ax
        push bx
        mov byte ptr es:[f_sync_found],0
        cmp byte ptr es:[f_file_open],0
        jz cf1
        mov byte ptr es:[f_file_open],0
        mov bx,word ptr es:[file_id]
        test bx,bx
        jz cf1
        mov ah,3eh
        int 21h
cf1:    pop bx
        pop ax
        popf
        ret
close_file endp

; Текущий читаемый из файла байт
cur_byte db ?

; Флаг - 1, если найден первый синхробайт (также при записи)
f_sync_found db 0

; Пишет байт в файл (только если уже был синхробайт)
write_file proc
        cmp byte ptr [f_file_open],1
        je wf2
        call open_file_write
wf2:    mov bx,word ptr [file_id]
        test bx,bx
        jz wf1
        cmp byte ptr [f_sync_found],0
        jnz wf3
        cmp al,0e6h     ; синхробайт
        jne wf1
        mov byte ptr [f_sync_found],1
        jmp wf1
wf3:    mov byte ptr [cur_byte],al
        mov cx,1
        lea dx,cur_byte
        mov ah,40h
        int 21h
wf1:    ret
write_file endp

; Читает байт из файла
read_file proc
        cmp byte ptr [f_file_open],0
        je rf1
        mov bx,word ptr [file_id]
        test bx,bx
        jz rf1
        mov cx,1
        lea dx,cur_byte
        mov ah,3fh
        int 21h
         test ax,ax
         jz rf1
;        jc rf1
        mov al,byte ptr [cur_byte]
        clc
        ret
rf1:    stc
;        xor al,al
        mov al,0dah
        ret
read_file endp

; Ищет синхробайт в файле
read_file_sync proc
        cmp byte ptr [f_file_open],1
        je rfs1
        call open_file_read
        jmp read_file
rfs1:   call read_file
        jc rfs2
        cmp al,0e6h
        jne rfs1
rfs2:   jmp read_file
read_file_sync endp

;####===-- Эмуляция 0F80CH --===####
; Вывод байта на магнитофон
; C - выводимый байт

emf80c: push ax
        push bx
        push cx
        push dx
        push ds
        mov ax,es
        mov ds,ax

        mov al,cl
        call write_file

        pop ds
        pop dx
        pop cx
        pop bx
        pop ax
        ret

;####===-- Эмуляция 0F806H --===####
; Чтение байта с магнитофона
; Вход:
; A=8 - без ожидания синхробайта (E6)
; A=FF - с ожиданием синхробайта

emf806: push bx
        push cx
        push dx
        push ds
        mov bx,es
        mov ds,bx

        cmp al,08h
        jne em06_1
        call read_file
        jmp em06_2
em06_1: call read_file_sync

em06_2: pop ds
        pop dx
        pop cx
        pop bx
        ret

;##################################################################
;### Установка экранных настроек и отображение экранной области ###
;##################################################################
refresh_scr proc
        cmp byte ptr es:[f_scr],1
        jnz rs1
; 30x78
        mov word ptr es:[scr_dim],1d3fh
IF TYPE_P
        mov word ptr es:[scr_beg],76d0h
        mov word ptr es:[scr_end],7ff3h
        mov word ptr es:[cur_offs],0303h
ELSEIF TYPE_R OR TYPE_M
        mov word ptr es:[scr_beg],76d0h
        mov word ptr es:[scr_end],7ff3h
        mov word ptr es:[cur_offs],0308h
ELSEIF TYPE_A
        mov word ptr es:[scr_beg],0e1d0h
        mov word ptr es:[scr_end],0eaf3h
        mov word ptr es:[cur_offs],0308h
ENDIF
        jmp rs22
rs1:    cmp byte ptr es:[f_scr],0
        jnz rs2
; 25x64
        mov word ptr es:[cur_offs],0
        mov word ptr es:[scr_dim],183fh
IF TYPE_P
        mov word ptr es:[scr_beg],77bdh
        mov word ptr es:[scr_end],7f0dh+74
ELSEIF TYPE_R OR TYPE_M
        mov word ptr es:[scr_beg],77c2h
        mov word ptr es:[scr_end],7f12h+74
ELSEIF TYPE_A
        mov word ptr es:[scr_beg],0e2c2h
        mov word ptr es:[scr_end],0ea12h+74
ENDIF
        jmp rs22
rs2:
; Auto
        push ax
        mov ah,byte ptr es:[sh_height]
        mov al,byte ptr es:[sh_width]
        sub ax,0101h
        mov word ptr es:[scr_dim],ax
        mov ax,word ptr es:[sh_scrbeg]
        mov word ptr es:[scr_beg],ax
        add ax,word ptr es:[sh_scrlen]
        dec ax
        mov word ptr es:[scr_end],ax
IF TYPE_P
        mov word ptr es:[cur_offs],0303h
ELSE
        mov word ptr es:[cur_offs],0308h
ENDIF
        pop ax

rs22:   push di
        cmp byte ptr es:[f_font],0
        jz rs7
        lea di,symtablerk
        jmp rs6
rs7:    lea di,symtable
rs6:    mov word ptr es:[symtable_ptr],di
        call pos_cursor
        push si
        push cx
        push bx
        xor di,di
        mov si,word ptr es:[scr_beg]
        mov cl,byte ptr es:[scr_dim+1]
        inc cl
        xor ch,ch
        push ax
        mov ax,0b800h
        push es
        mov es,ax
        mov ah,7
        cld
rs3:    push cx
        push di
        mov bx,word ptr cs:[symtable_ptr]
        mov cx,78
rs4:    lodsb
        test al,al
        jns rs5
        xor al,al
rs5:
        xlat byte ptr cs:symtable_ptr
        stosw
        loop rs4
        pop di
        pop cx
        add di,160
        loop rs3
        pop es
        pop ax
        pop bx
        pop cx
        pop si
        pop di
        ret
refresh_scr endp

; Разница между физ. и логич. координатами курсора
cur_offs dw 0

; Размерность экрана - 64x25 или 78x30
scr_dim dw 183fh

set_appropr_09_vect proc
        cmp byte ptr es:[f_vid],2
        jne sav1
        call set_new_09_vect
sav1:   ret
set_appropr_09_vect endp

end
