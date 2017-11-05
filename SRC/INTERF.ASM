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

;File: INTERF.ASM

; Содержит процедуры для интерфейса с пользователем

.model tiny

public f_speed
public f_vid
public f_f809
public f_scr
public f_reset
public f_font
public filename
public setup
public getfilename
public disable_vga
public set_fontoem
public enable_hookf809
public set_cga_mode
public filename
public f_choose_file
public f_synb
;public outtextxy2

extrn quit:near
extrn choose_file_name:near
extrn save_scr:near
extrn rest_scr:near

.code

h=8
w=47
t=8
l=17

f_reset db 0

; Отменяет пункт меню 78x30
disable_vga proc
        mov byte ptr cs:[i_scrhigh+11],1
;       mov word ptr cs:[i_scrlow+3],offset i_scrlow
;       mov word ptr cs:[i_scrlow+5],offset i_scrlow
        ret
disable_vga endp

; Устанавливает пункт меню 80x25 и запрещает остальные
set_cga_mode proc
        mov byte ptr cs:[i_scrhigh+11],1
        mov byte ptr cs:[i_scrauto+11],1
;       mov word ptr cs:[i_scrlow+3],offset i_scrlow
;       mov word ptr cs:[i_scrlow+5],offset i_scrlow
        mov word ptr cs:[l_scr+5], offset i_scrlow
        mov byte ptr cs:[f_scr],0
        mov word ptr cs:[l_font+5],offset i_fontoem
        mov byte ptr cs:[f_font],0
        mov byte ptr cs:[i_fontrk+11],1
        ret
set_cga_mode endp

; Устанавливает знакогенератор cp866
set_fontoem proc
        mov word ptr cs:[l_font+5],offset i_fontoem
        mov byte ptr cs:[f_font],0
        ret
set_fontoem endp

; Устанавливает перехват 0F809H
enable_hookf809 proc
        mov word ptr cs:[l_f809+5],offset i_f809yes
        mov byte ptr cs:[f_f809],1
        ret
enable_hookf809 endp

; Отображает меню настроек
setup proc
        pushf
        push ax
        push bx
        push cx
        push dx
        push si
        push di
        push bp
        push ds
        mov ax,es
        mov ds,ax
        push es
        call save_scr
        push ax
        call prframe
        call printall
        call input
        pop ax
        call rest_scr
        pop es
        pop ds
        pop bp
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        popf
        ret
setup endp

; Запрос имени файла
getfilename proc
        pushf
        push ax
        push bx
        push cx
        push dx
        push si
        push di
        push bp
        push ds
        mov ax,es
        mov ds,ax
        push es
        call save_scr
        push ax
        call query
        call readstr
        pop ax
        call rest_scr
        pop es
        pop ds
        pop bp
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        popf
        ret
getfilename endp

i_spnorm:
        db 2
        db 1
        db 24
        dw i_spmed
        dw i_spmax
        dw l_vid
        dw l_font
        db 0
        db 'Норм.',0
i_spmed:
        db 1
        db 1
        db 31
        dw i_spmax
        dw i_spnorm
        dw l_vid
        dw l_font
        db 0
        db 'Без ПДП',0
i_spmax:
        db 0
        db 1
        db 40
        dw i_spnorm
        dw i_spmed
        dw l_vid
        dw l_font
        db 0
        db 'Макс.',0
l_speed:
f_speed:db 2
        dw l_vid
        dw l_font
        dw i_spnorm
        db 1
        db 3
        db 'Скорость:',0

i_vidno:
        db 0
        db 2
        db 24
        dw i_vidyes
        dw i_vidfull
        dw l_f809
        dw l_speed
        db 0
        db 'Нет',0
i_vidyes:
        db 1
        db 2
        db 29
        dw i_vidfull
        dw i_vidno
        dw l_f809
        dw l_speed
        db 0
        db 'Зап.',0
i_vidfull:
        db 2
        db 2
        db 35
        dw i_vidno
        dw i_vidyes
        dw l_f809
        dw l_speed
        db 0
        db 'Чт/Зап',0
l_vid:
f_vid:  db 1
        dw l_f809
        dw l_speed
        dw i_vidyes
        db 2
        db 3
        db 'Эмул.в/пам.и порт.:',0

i_f809yes:
        db 1
        db 3
        db 24
        dw i_f809no
        dw i_f809no
        dw l_scr
        dw l_vid
        db 0
        db 'Да',0
i_f809no:
        db 0
        db 3
        db 28
        dw i_f809yes
        dw i_f809yes
        dw l_scr
        dw l_vid
        db 0
        db 'Нет',0
l_f809:
f_f809: db 0
        dw l_scr
        dw l_vid
        dw i_f809no
        db 3
        db 3
        db 'Перехват 0F809H:',0

i_scrauto:
        db 2
        db 4
        db 24
        dw i_scrlow
        dw i_scrhigh
        dw l_font
        dw l_f809
        db 0
        db 'Авто',0
i_scrlow:
        db 0
        db 4
        db 31
        dw i_scrhigh
        dw i_scrauto
        dw l_font
        dw l_f809
        db 0
        db '64x25',0
i_scrhigh:
        db 1
        db 4
        db 38
        dw i_scrauto
        dw i_scrlow
        dw l_font
        dw l_f809
        db 0
        db '78x30',0
l_scr:
f_scr:  db 2
        dw l_font
        dw l_f809
        dw i_scrauto
        db 4
        db 3
        db 'Разрешение экрана:',0

i_fontoem:
        db 0
        db 5
        db 24
        dw i_fontrk
        dw i_fontrk
        dw l_speed
        dw l_scr
        db 0
        db 'cp866',0
i_fontrk:
        db 1
        db 5
        db 31
        dw i_fontoem
        dw i_fontoem
        dw l_speed
        dw l_scr
        db 0
        db 'РК',0
l_font:
f_font:  db 1
        dw l_speed
        dw l_f809
        dw i_fontrk
        db 5
        db 3
        db 'Знакогенератор:',0

stline  dw l_speed

outtextxy proc
        push ax
        mov al,dh
        add al,t
        add dl,l
        xor ah,ah
        mov cl,80
        mul cl
        xor dh,dh
        add ax,dx
        shl ax,1
        mov di,ax
        mov ax,0b800h
        mov es,ax
        pop ax
        cld
otxy1:  lodsb
        test al,al
        jz otxyex
        stosw
        jmp otxy1
otxyex: ret
outtextxy endp

outtextxy2 proc
        push ax
        mov al,dh
        xor ah,ah
        mov cl,80
        mul cl
        xor dh,dh
        add ax,dx
        shl ax,1
        mov di,ax
        mov ax,0b800h
        mov es,ax
        pop ax
        cld
otxy2_1:  lodsb
        test al,al
        jz otxy2_ex
        stosw
        jmp otxy2_1
otxy2_ex: ret
outtextxy2 endp

printitem proc
        push es
        push dx
        push cx
        push ax
        mov dl,byte ptr [bx+2]
        mov dh,byte ptr [bx+1]
        lea si,[bx+12]
        call outtextxy
        pop ax
        pop cx
        pop dx
        pop es
        ret
printitem endp

printline proc
        push si
        push cx
        push bx
        push es
        push dx
        push cx
        push ax
        mov dl,byte ptr [bx+8]
        mov dh,byte ptr [bx+7]
        lea si,[bx+9]
        mov ah,1bh
        call outtextxy
        pop ax
        pop cx
        pop dx
        pop es
        mov bx,word ptr [bx+5]
        mov cx,bx
;        mov ah,1eh
        call printitem
pl1:    mov bx,word ptr [bx+3]
        cmp cx,bx
        je plex
        mov ah,17h
        cmp byte ptr [bx+11],0
        jz pl2
        mov ah,18h
pl2:    call printitem
        jmp pl1
plex:   pop bx
        pop cx
        pop si
        ret
printline endp

printall proc
        push bx
        push cx
        mov bx,[stline]
        mov cx,bx
pa1:    mov ah,1eh
        call printline
        mov bx,word ptr [bx+1]
        cmp bx,cx
        jne pa1
        pop cx
        pop bx
        ret
printall endp

prframe proc
;        push ds
;        mov ax,0b800h
;        mov ds,ax
;        mov si,160*t+(l*2)
;        lea di,winbuf
;        mov cx,h
;        cld
;gw0:    push cx
;        push si
;        mov cx,w
;        rep movsw
;        pop si
;        pop cx
;        add si,160
;        loop gw0
;        pop ds
        push es
        mov ax,0b800h
        mov es,ax
        mov di,160*t+(l*2)
        mov cx,h
        cld
        mov ax,1e00h
gw1:    push cx
        push di
        mov cx,w
        rep stosw
        pop di
        pop cx
        add di,160
        loop gw1
        mov di,160*t+(l*2)+2
        mov ax,1ecdh
        mov cx,w-2
        rep stosw
        mov di,160*t+160*(h-1)+(l*2)+2
        mov ax,1ecdh
        mov cx,w-2
        rep stosw
        mov di,160*t+(l*2)
        mov byte ptr [es:di],'╔'
        mov byte ptr [es:di+(w*2-2)],'╗'
        mov byte ptr [es:di+(h-1)*160],'╚'
        mov byte ptr [es:di+(h-1)*160+(w*2-2)],'╝'
        mov cx,h-2
gw2:    add di,160
        mov byte ptr [es:di],'║'
        loop gw2
        mov cx,h-2
        mov di,160*(t+1)+(l*2)+(w*2-2)
gw3:    mov byte ptr [es:di],'║'
        add di,160
        loop gw3
        mov ah,1ah
        mov dh,h-2
        mov dl,8
        lea si,lastline
        call outtextxy
        pop es
        ret
prframe endp

;restwin proc
;        push es
;        mov ax,0b800h
;        mov es,ax
;        mov di,160*t+(l*2)
;        lea si,winbuf
;        mov cx,h
;        cld
;pw0:    push cx
;        push di
;        mov cx,w
;        rep movsw
;        pop di
;        pop cx
;        add di,160
;        loop pw0
;        pop es
;        ret
;restwin endp

query   proc
        push es
        push ax
        push di
        push si
        push cx
        mov ax,0b800h
        mov es,ax
        mov di,160*10+44
        lea si,frame
        cld
        mov dx,5
em0:    push di
        mov cx,35
        mov ah,1eh
em1:    lodsb
        stosw
        loop em1
        pop di
        add di,160
        dec dx
        jnz em0
        pop cx
        pop si
        pop di
        pop ax
        pop es
        ret
query   endp

prsymb proc
        mov ah,0eh
        push bx
        xor bh,bh
        mov cx,1
        int 10h
        pop bx
        ret
prsymb endp

; 1, если нужно выбирать файл
f_choose_file db ?

; 1, если нужно писать синхробайт
f_synb db 0

readstr proc
        mov ah,3
        xor bh,bh
        int 10h
        push dx
        mov ah,2
        xor bh,bh
        mov dx,0b23h
        int 10h
        lea bx,filename
rstr1:  mov byte ptr [bx],0
rstr2:  call show_hint
        xor ah,ah
        int 16h
        cmp al,0dh
        je rstr3
        cmp al,1bh
        je rstr9
        cmp ax,3d00h ; F3
        je rstrc
        cmp al,8
        je rstr5
        cmp bx,(offset filename)+20
        je rstr2
        test al,al
        jz rstr4
        cmp al,20h
        jl rstr2
        cmp al,7fh
        jg rstr2
        mov byte ptr [bx],al
        inc bx
        call prsymb
        jmp rstr1
rstr4:  cmp ax,4b00h
        jne rstr2
rstr5:  cmp bx,offset filename
        je rstr2
        mov al,8
        call prsymb
        mov al,' '
        call prsymb
        mov al,8
        call prsymb
        dec bx
        jmp rstr1
rstr9:  mov byte ptr cs:[filename],0
        jmp rstr6
rstr3:  
        cmp byte ptr cs:[filename],0
        jne rstr6
        push bx
        call choose_file_name
        pop bx
        cmp byte ptr cs:[filename],0
        jz rstr2
rstr6:  mov ah,2
        xor bh,bh
        pop dx
        int 10h
        ret
rstrc:  xor byte ptr [f_synb],1
        mov al,byte ptr [f_synb]
        xor al,1
        shl al,1
        add al,'+'
        mov byte ptr [wr_hint+18h],al
        jmp rstr2
show_hint:
        cmp byte ptr [f_choose_file],0
        jnz rstra
        lea si,wr_hint
        mov dx,0d1ah
        jmp rstrb
rstra:  cmp byte ptr [filename],0
        jz rstr7
        lea si,emp_hint
        jmp rstr8
rstr7:  lea si,nemp_hint
rstr8:  mov dx,0d1ch
rstrb:  mov ah,1ah
        call outtextxy2
        ret
emp_hint db  '      Esc-отмена       ',0
nemp_hint db 'Enter-выбор  Esc-отмена',0
wr_hint db   ' Esc-отмена  F3:С/байт-[-] ',0
readstr endp

input proc
        mov bx,word ptr [stline]
inpaa:  mov si,bx
        mov bx,word ptr [bx+5]
inpl:   mov ah,3eh
        push bx
        mov bx,si
        call printline
        pop bx
        mov al,byte ptr [bx]
        mov byte ptr [si],al
inpr:   xor ah,ah
        int 16h
        cmp ax,4b00h ; <-
        jne inp1
inpb:   mov bx,word ptr [bx+5]
        mov word ptr [si+5],bx
        cmp byte ptr [bx+11],0
        jnz inpb
        jmp inpl
inp1:   cmp ax,4d00h ; ->
        jne inp2
inpc:   mov bx,word ptr [bx+3]
        mov word ptr [si+5],bx
        cmp byte ptr [bx+11],0
        jnz inpc
        jmp inpl
inp2:   cmp ax,4800h ; ^
        jne inp3
        mov bx,word ptr [bx+9]
        jmp inpa
inp3:   cmp ax,5000h ; \/
        jne inp4
inp5:   mov bx,word ptr [bx+7]
        jmp inpa
inp4:   cmp al,0dh
        je inp5
        cmp al,1bh
        je inpex
        and al,0dfh
        cmp al,51h
        je inp6
        cmp al,52h
        je inp7
        jmp inpr
inpa:   push bx
        mov bx,si
        mov ah,1eh
        call printline
        pop bx
        jmp inpaa
inp6:   call rest_scr
        jmp quit
inp7:   mov byte ptr [f_reset],1
inpex:  ret
input endp

frame db '╔═════════════════════════════════╗'
      db '║ Имя файла:                      ║'
      db '╟─────────────────────────────────╢'                                                                   
      db '║                                 ║'
      db '╚═════════════════════════════════╝'


;winbuf db h*w*2 dup ( ? )
filename db 21 dup ( ? )
lastline db 'ESC-Возврат  R-Reset  Q-Выход',0

end
