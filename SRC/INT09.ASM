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

.model tiny

extrn f_f10:byte
extrn port_c:byte

public get_09_vect
public set_new_09_vect
public restore_09_vect
public key_bytes
public ctrl_keys
public led_state
;public light_led

.code

old_09 dd ?

get_09_vect proc
	push es
	push bx
	mov ax,3509h
	int 21h
	mov word ptr cs:[old_09],bx
	mov word ptr cs:[old_09+2],es
	pop bx
	pop es
	ret
get_09_vect endp

set_new_09_vect proc
	push ax
	push dx
	mov ax,2509h
	push ds
	push cs
	pop ds
	lea dx,int_09
	int 21h
	call light_led
	pop ds
	pop dx
	pop ax
	ret
set_new_09_vect endp

restore_09_vect proc
	push ax
	push dx
	mov ax,2509h
	push ds
	lds dx,dword ptr cs:[old_09]
	int 21h
	call restore_led
	pop ds
	pop dx
	pop ax
	ret
restore_09_vect endp

int_09 proc
	push es
	push ax
;i9_1:in al,61h
;test al,80h
;jnz i9_1
	in al,60h
	cmp al,44h ;F10
	jne i3
	mov byte ptr cs:[f_f10],1
	jmp i1
i3:	cmp al,46h; ScrollLock
	jne i2
	xor byte ptr cs:[keyb_type],1
	xor byte ptr cs:[led_state],1
	call light_led
	jmp i1
i2:	mov ah,al
	and al,7fh
	cmp al,53h
	ja i1
	call anal_key
i1:	cli
	in al,61h
	or al,80h
	out 61h,al
	and al,7fh
	out 61h,al
	mov al,20h
	out 20h,al
;call light_led
	pop ax
	pop es
;jmp dword ptr cs:[old_09]
	iret
int_09 endp

; �������� ᢥ⮤���� ���������� � ᮮ⢥��⢨� � ���⮬ ���ﭨ�
light_led proc
	push ax
ll1:	in al,64h
	test al,2
	jnz ll1
	mov al,0edh
	out 60h,al
	mov al,byte ptr cs:[port_c]
	and al,08h
	ror al,1
	or byte ptr cs:[led_state],al
	mov al, byte ptr cs:[led_state]
	push ax
ll2:	in al,64h
	test al,2
	jnz ll2
	pop ax
	out 60h,al
	pop ax
	ret
light_led endp

; �������� ᢥ⮤���� ���������� � ᮮ⢥��⢨� � BIOS
restore_led proc
	push ax
rl1:	in al,64h
	test al,2
	jnz ll1
	mov al,0edh
	out 60h,al
	push es
	mov ax,40h
	mov es,ax
	mov al,byte ptr [es:17h]
	pop es
	pushf
	ror al,1
	ror al,1
	ror al,1
	ror al,1
	and al,07h
	push ax
rl2:	in al,64h
	test al,2
	jnz rl2
	pop ax
	popf
	out 60h,al
	pop ax
	ret
restore_led endp

; ���������� ᪠�-��� � AL (AH<0, �᫨ �⦠⨥)
anal_key proc
; mov byte ptr cs:[key_bytes],al
; ret
	push bx
	xor bh,bh
	mov bl,al
	add bx,bx
	cmp byte ptr cs:[keyb_type],0
	jz ak3
	mov al, byte ptr cs:[bx+offset key_tbl_r+1] ; ��᪠
	mov bl, byte ptr cs:[bx+offset key_tbl_r]   ; ����� ����
	jmp ak4
ak3:	mov al, byte ptr cs:[bx+offset key_tbl_l+1] ; ��᪠
	mov bl, byte ptr cs:[bx+offset key_tbl_l]   ; ����� ����
ak4:	xor bh,bh
	test ah,ah
	jns ak1
	or byte ptr cs:[bx+offset key_bytes],al
	jmp ak2
ak1:	not al
	and byte ptr cs:[bx+offset key_bytes],al
ak2:	pop bx
	ret
anal_key endp

key_bytes db 8 dup (0ffh)
ctrl_keys db 0f0h

keyb_type db 0 ; 0-lat, 1-rus �४�. �� ScrollLock

led_state db 0 ; ����ﭨ� ᢥ⮤����� ����������

key_tbl_l:
IF TYPE_M
db 0,0
db 1,1; 01-ESC
db 1,4; 02-1
db 2,4; 03-2
db 3,4; 04-3
db 4,4; 05-4
db 5,4; 06-5
db 6,4; 07-6
db 7,4; 08-7
db 0,8; 09-8
db 1,8; 0a-9
db 0,4; 0b-0
db 5,8; 0c--
db 3,8; 0d
db 7,128; 0e-BSP
db 2,1; 0f-TAB

db 1,64; Q
db 7,64; W
db 5,16; E
db 2,64; R
db 4,64; T
db 1,128; Y
db 5,64; U
db 1,32; I
db 7,32; O
db 0,64; P
db 3,128; [
db 5,128; ]
db 4,1; Enter
db 8,64; Ctrl ;####
db 1,16; A
db 3,64; S

db 4,16; D
db 6,16; F
db 7,16; G
db 0,32; H
db 2,32; J
db 3,32; K
db 4,32; L
db 2,8; :
db 0,0
db 0,16; @(~)
db 8,128; Shift
db 4,128; \
db 2,128; Z
db 0,128; X
db 3,16; C
db 6,64; V

db 2,16; B
db 6,32; N
db 5,32; M
db 4,8; ,
db 6,8; .
db 7,8; /
db 8,128; Shift ;####
db 0,0; Prs
db 0,0; Alt
db 0,1; Space
db 8,32; Caps Lock ;####
db 3,2; F1
db 4,2; F2
db 5,2; F3
db 6,2; F4
db 7,2; F5

db 0,0
db 0,0
db 0,0
db 0,0
db 0,0
db 0,0; Num Lock
db 0,0; Scroll Lock
db 2,2; Home
db 0,2; Up
db 5,1; PgUp-���
db 5,8; -
db 6,1; Left
db 0,0
db 7,1; Right
db 3,8; +
db 0,0; End

db 1,2
db 0,0; PqDn
db 0,0; Ins
db 4,2; Del-F2
ELSE
db 0,0
db 0,4; 01-ESC
db 2,2; 02-1
db 2,4; 03-2
db 2,8; 04-3
db 2,16; 05-4
db 2,32; 06-5
db 2,64; 07-6
db 2,128; 08-7
db 3,1; 09-8
db 3,2; 0a-9
db 2,1; 0b-0
db 3,32; 0c--
db 3,8; 0d
db 1,8; 0e-BSP
db 1,1; 0f-TAB

db 6,2; Q
db 6,128; W
db 4,32; E
db 6,4; R
db 6,16; T
db 7,2; Y
db 6,32; U
db 5,2; I
db 5,128; O
db 6,1; P
db 7,8; [
db 7,32; ]
db 1,4; Enter
db 8,64; Ctrl ;####
db 4,2; A
db 6,8; S

db 4,16; D
db 4,64; F
db 4,128; G
db 5,1; H
db 5,4; J
db 5,8; K
db 5,16; L
db 3,4; :
db 0,0
db 4,1; @(~)
db 8,32 ;Shift
db 7,16; \
db 7,4; Z
db 7,1; X
db 4,8; C
db 6,64; V

db 4,4; B
db 5,64; N
db 5,32; M
db 3,16; ,
db 3,64; .
db 3,128; /
db 8,32; Shift
db 0,0; Prs
db 0,0; Alt
db 7,128; Space
IF TYPE_P
db 8,16 ;Caps Lock
ELSE
db 8,128
ENDIF
db 0,8; F1
db 0,16; F2
db 0,32; F3
db 0,64; F4
db 0,128; F5

db 0,0
db 0,0
db 0,0
db 0,0
db 0,0
db 0,0; Num Lock
db 0,0; Scroll Lock
db 0,1; Home
db 1,32; Up
db 0,2; PgUp-���
db 3,32; -
db 1,16; Left
db 0,0
db 1,64; Right
db 3,8; +
db 0,0; End

db 1,128
db 0,0; PqDn
db 0,0; Ins
db 0,16; Del-F2
ENDIF


key_tbl_r:
IF TYPE_M
db 0,0
db 1,1; 01-ESC
db 1,4; 02-1
db 2,4; 03-2
db 3,4; 04-3
db 4,4; 05-4
db 5,4; 06-5
db 6,4; 07-6
db 7,4; 08-7
db 0,8; 09-8
db 1,8; 0a-9
db 0,4; 0b-0
db 5,8; 0c--
db 3,8; 0d
db 7,128; 0e-BSP
db 2,1; 0f-TAB

db 2,32; �
db 3,16; �
db 5,64; �
db 3,32; �
db 5,16; �
db 6,32; �
db 7,16; �
db 3,128; �
db 5,128; �
db 2,128; �
db 0,32; �
db 0,0
db 4,1; Enter
db 8,64; Ctrl ;####
db 6,16; �
db 1,128; �

db 7,64; �
db 1,16; �
db 0,64; �
db 2,64; �
db 7,32; �
db 4,32; �
db 4,16; �
db 6,64; �
db 4,128; �
db 0,16; @(~)
db 8,32;
db 4,128; \
db 1,64; �
db 6,128; �
db 3,64; C
db 5,32; �

db 1,32; �
db 4,64; �
db 0,128; �
db 2,16; �
db 0,16; �
db 7,8; /
db 8,128; Shift ;####
db 0,0; Prs
db 0,0; Alt
db 0,1; Space
db 8,32; Caps Lock ;####
db 3,2; F1
db 4,2; F2
db 5,2; F3
db 6,2; F4
db 7,2; F5

db 0,0
db 0,0
db 0,0
db 0,0
db 0,0
db 0,0; Num Lock
db 0,0; Scroll Lock
db 2,2; Home
db 0,2; Up
db 5,1; PgUp-���
db 5,8; -
db 6,1; Left
db 0,0
db 7,1; Right
db 3,8; +
db 0,0; End

db 1,2
db 0,0; PqDn
db 0,0; Ins
db 4,2; Del-F2
ELSE
db 0,0
db 0,4; 01-ESC
db 2,2; 02-1
db 2,4; 03-2
db 2,8; 04-3
db 2,16; 05-4
db 2,32; 06-5
db 2,64; 07-6
db 2,128; 08-7
db 3,1; 09-8
db 3,2; 0a-9
db 2,1; 0b-0
db 3,32; 0c--
db 3,8; 0d
db 1,8; 0e-BSP
db 1,1; 0f-TAB

db 5,4; �
db 4,8; �
db 6,32; �
db 5,8; �
db 4,32; �
db 5,64; �
db 4,128; �
db 7,8; �
db 7,32; �
db 7,4; �
db 5,1; �
db 0,0
db 1,4; Enter
db 8,64; Ctrl ;####
db 4,64; �
db 7,2; �

db 6,128; �
db 4,2; �
db 6,1; �
db 6,4; �
db 5,128; �
db 5,16; �
db 4,16; �
db 6,64; �
db 7,16; �
db 4,1; @(~)-�
IF TYPE_M
db 8,128; Shift ;####
ELSE
db 8,32
ENDIF
db 7,16; \
db 6,2; �
db 7,64; �
db 6,8; �
db 5,32; �

db 5,2; �
db 6,16; �
db 7,1; �
db 4,4; �
db 4,1; �
db 3,128; /
IF TYPE_M
db 8,128; Shift ;####
ELSE
db 8,32
ENDIF
db 0,0; Prs
db 0,0; Alt
db 7,128; Space
IF TYPE_M
db 8,32; Caps Lock ;####
ELSEIF TYPE_P
db 8,16
ELSE
db 8,128
ENDIF
db 0,8; F1
db 0,16; F2
db 0,32; F3
db 0,64; F4
db 0,128; F5

db 0,0
db 0,0
db 0,0
db 0,0
db 0,0
db 0,0; Num Lock
db 0,0; Scroll Lock
db 0,1; Home
db 1,32; Up
db 0,2; PgUp-���
db 3,32; -
db 1,16; Left
db 0,0
db 1,64; Right
db 3,8; +
db 0,0; End

db 1,128
db 0,0; PqDn
db 0,0; Ins
db 0,16; Del-F2
ENDIF

end
