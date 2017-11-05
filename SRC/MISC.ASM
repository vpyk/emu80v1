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

;File: MISC.ASM

; Содержит разнообразные служебные процедуры

.model tiny

public get_key
public test_key
public prep_key
public f_f10
public flash_key

public inittimer
public getcount

public init_sound

public setscr25
public setscr30
public setscr43
public setw8
public test_vga
public test_ega
public test_nt
public test_win
public load_8x16
public load_8x16rk
public load_8x8
public load_8x8rk
public set_vga400
public set_vga350

public find_path
public com_path
public com_path_len

extrn rkfont:near
extrn rkfont8:near

.code

;### Процедуры для работы с клавиатурой ###

; Эти процедуры всегда работают с последним символом,
; игнорируя очередь (точнее, эмулируется буфер из одного симфола)

; Буфер из одного символа
key dw 0

; Флаг - устанавливается при нажатии F10
f_f10 db 0

tst proc
        mov ah,1
        int 16h
        ret
tst endp

; Подготовка символа и анализ F10
prep_key proc
;        call tst
;        jnz pk2
;        mov es:[key],0
;        jmp pk1
pk3:    call tst
        jz pk1
pk2:    xor ah,ah
        int 16h
        cmp ax,4400h
        jne pk4
        mov byte ptr es:[f_f10],1
        jmp pk3
pk4:    mov es:[key],ax
        jmp pk3
pk1:    ret
prep_key endp

; Чтение символа
get_key proc
        call prep_key
        mov ax,es:[key]
        mov es:[key],0
        test ax,ax
        jnz gk1
        xor ah,ah
        int 16h
gk1:    ret
get_key endp

; Проверка нажатия (наличия в буфере)
test_key proc
        push ax
        call prep_key
        mov ax,es:[key]
        test ax,ax
        pop ax
        ret
test_key endp

; Очистка буфера
flash_key proc
        mov es:[key],0
        ret
flash_key endp

;### Процедуры для работы с таймером ###

; Инициализация таймера
inittimer proc
        mov al,36h
        out 43h,al
        xor al,al
        out 40h,al
        out 40h,al
        ret
inittimer endp

; Получение текущего значения счетчика в AX
getcount proc
        push cx
        mov al,06h
        out 43h,al
        in al,40h
        mov cl,al
        in al,40h
        mov ah,al
        mov al,cl
        pop cx
        ret
getcount endp

;### Процедуры для работы с экраном ###

;Устанавливает режим 80x30
setscr30 proc
        push ax
        push dx
        mov ax,83h
        int 10h
        cli
        mov dx,3d4h
        mov al,11h
        out dx,al
        inc dx
        in al,dx
        and al,7fh
        out dx,al
        dec dx
        mov al,06h
        out dx,al
        mov al,0bh
        inc dx
        out dx,al
        dec dx
        mov al,07h
        out dx,al
        mov al,3eh
        inc dx
        out dx,al
        dec dx
        mov al,10h
        out dx,al
        mov al,0eah
        inc dx
        out dx,al
        dec dx
        mov al,12h
        out dx,al
        mov al,0dfh
        inc dx
        out dx,al
        dec dx
        mov al,15h
        out dx,al
        mov al,0e7h
        inc dx  
        out dx,al
        dec dx
        mov al,16h
        out dx,al
        mov al,04h
        inc dx
        out dx,al
        dec dx
        sti
        mov ax,40h
        push es
        mov es,ax
        mov byte ptr es:[0084h],1dh ; установка переменной BIOS числа строк
;       mov byte ptr es:[0049h],07fh
        pop es
        pop dx
        pop ax
        ret
setscr30 endp

; Устанавливает режим 80x25 (без очистки экрана)
setscr25 proc
        mov ax,83h
        int 10h
        ret
setscr25 endp

; Устанавливает режим 80x43
setscr43 proc
        push bx
        mov ax,83h
        int 10h
        mov ax,1112h
        xor bl,bl
        int 10h
        pop bx
        ret
setscr43 endp

;Z=1, если присутствует VGA
test_vga proc
        mov ax,1a00h
        int 10h
        cmp al,1ah
;       cmp al,1h
        ret
test_vga endp

;Z=0, если присутствует EGA
test_ega proc
        mov ax,1200h
        mov bx,0010h
        int 10h
        cmp bl,10h
;       cmp bl,3h
        ret
test_ega endp

;Устанавливает режим 400 строк для VGA
set_vga400 proc
        push bx
        mov ax,1202h
        mov bl,30h
        int 10h
        pop bx
        ret
set_vga400 endp

;Устанавливает режим 350 строк для VGA
set_vga350 proc
        push bx
        mov ax,1201h
        mov bl,30h
        int 10h
        pop bx
        ret
set_vga350 endp

;Загружает стандартный шрифт 8x16
load_8x16 proc
        push bx
        mov ax,1104h
        xor bl,bl
        int 10h
;       mov ax,1103h
;       xor bl,bl
;       int 10h
        pop bx
        ret
load_8x16 endp

;Загружает стандартный шрифт 8x8
load_8x8 proc
        push bx
        mov ax,1102h
        xor bl,bl
        int 10h
;       mov ax,1103h
;       xor bl,bl
;       int 10h
        pop bx
        ret
load_8x8 endp

; Загружает шрифт 8x16 знакогенератора РК-86
; в символы 00-5F, D0-DF, F0-FF
load_8x16rk proc
        push bx
        push cx
        push dx
        push es
        mov ax,1100h
        mov bx,1000h
        mov cx,60h
        xor dx,dx
        push cs
        pop es
        mov bp,offset rkfont
        int 10h
        mov ax,1100h
        mov bx,1000h
        mov cx,10h
        mov dx,0d0h
        push cs
        pop es
        mov bp,(offset rkfont)+600h
        int 10h
        mov ax,1100h
        mov bx,1000h
        mov cx,10h
        mov dx,0f0h
        push cs
        pop es
        mov bp,(offset rkfont)+700h
        int 10h
        pop es
        pop dx
        pop cx
        pop bx
        ret
load_8x16rk endp

; Загружает шрифт 8x8 знакогенератора РК-86
; в символы 00-5F, D0-DF, F0-FF
load_8x8rk proc
        push bx
        push cx
        push dx
        push es
        mov ax,1100h
        mov bx,0800h
        mov cx,60h
        xor dx,dx
        push cs
        pop es
        mov bp,offset rkfont8
        int 10h
        mov ax,1100h
        mov bx,0800h
        mov cx,10h
        mov dx,0d0h
        push cs
        pop es
        mov bp,(offset rkfont8)+300h
        int 10h
        mov ax,1100h
        mov bx,0800h
        mov cx,10h
        mov dx,0f0h
        push cs
        pop es
        mov bp,(offset rkfont8)+380h
        int 10h
        pop es
        pop dx
        pop cx
        pop bx
        ret
load_8x8rk endp

; Устанавливает для VGA режим ширины символов 8 (по умолчанию 9)
setw8 proc
        push dx
        mov dx,03C4h
        mov al,01h
        out dx,al
        inc dx
        in al,dx
        dec dx
        test al,01h
        jne fin
        cli
        mov ax,0100h
        out dx,ax
        inc ax
        out dx,al
        inc dx
        in al,dx
        dec dx
        or al,01h
        mov ah,al
        mov al,01h
        out dx,ax
        mov dl,0CCh
        in al,dx
        and al,0F3h
        mov dl,0C2h
        out dx,al
        mov dl,0DAh
        in al,dx
        mov dl,0C0h
        mov al,13h
        out dx,al
        mov al,00h
        out dx,al
        mov dl,0DAh
        in al,dx
        mov dl,0C0h
        mov al,20h
        out dx,al
        mov dl,0C4h
        mov ax,0300h
        out dx,ax
        sti
fin:    pop dx
        ret
setw8 endp

;### Процедуры для работы со звуком ###

init_sound proc
        push ax
        push dx
        mov dx,1491
        in al,61h
        and al,0fch
        out 61h,al
        mov al,0b6h
        out 43h,al
        mov al,dl
        out 42h,al
        mov al,dh
        out 42h,al
        pop dx
        pop ax
        ret
init_sound endp

;### Прочие процедуры ###

; Z=0, если работает Windows в расширенном режиме
test_win proc
        mov ax,1600h
        int 2fh
        cmp al,0h
        jz tw1
        cmp al,80h
tw1:    ret
test_win endp

; AL=1, если запущена под Windows NT и 0 в противном случае
test_nt proc
        push es
        push ds
        push cs
        pop es
        push si
        mov si,word ptr cs:[2ch]
        mov ds,si
        xor si,si
tnt1:   cmp byte ptr ds:[si],0
        jz tnt2
        push si
        lea di,nt_var
        mov cx,14
        rep cmpsb
        je tnt3
        pop si
tnt4:   lodsb
        test al,al
        jnz tnt4
        jmp tnt1
tnt3:   pop si
        mov al,1
        jmp tnt5
tnt2:   xor al,al
tnt5:   pop si
        pop ds
        pop es
        ret
nt_var db 'OS=Windows_NT',0
test_nt endp

; заносит путь к com-файлу в сторку com_path
find_path proc
        push es
        push ds
        push cs
        pop es
        push si
        mov si,word ptr cs:[2ch]
        mov ds,si
        xor si,si
fp1:    cmp byte ptr ds:[si],0
        jz fp2
fp4:    lodsb
        test al,al
        jnz fp4
        jmp fp1
fp2:    inc si
        cmp word ptr ds:[si],1
        jne fp5
        inc si
        inc si
        mov di,offset com_path
fp6:    lodsb 
        test al,al
        je fp7
        stosb
        inc word ptr es:[com_path_len]
        jmp fp6
fp7:    dec si
        dec word ptr es:[com_path_len]
        cmp byte ptr ds:[si],'\'
        jne fp7
        inc word ptr es:[com_path_len]
        inc word ptr es:[com_path_len]
fp5:    pop si
        pop ds
        pop es
        ret
com_path db 128 dup (0)
com_path_len dw 0
find_path endp

end
