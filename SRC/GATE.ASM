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

extrn _proc:near
extrn setscr30:near

;_setscr30=setscr30

public _SetScr30

rkfont=0
rkfont8=0

public rkfont
public rkfont8

.code
.startup
call _proc
xor ah,ah
int 16h
int 20h

_SetScr30 proc
jmp SetScr30
_SetScr30 endp

end
