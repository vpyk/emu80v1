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

; File: EMUCPU.ASM

; Содержит процедуры, эмулирующие инструкции МП 8080

.model tiny

public code_tbl
public code_tbl_m
public code_tbl_m2
public rst6

extrn emF809:near
extrn emF818:near
extrn emF803:near
extrn emF812:near
;extrn fin:near
extrn save_byte:near
extrn load_byte:near
extrn enable_ints:near
extrn disable_ints:near

.code

; Таблица входов в подпрограммы обработки инструкций 8080
code_tbl:
  dw c00,c01,c02,c03,c04,c05,c06,c07
  dw c08,c09,c0a,c0b,c0c,c0d,c0e,c0f
  dw c10,c11,c12,c13,c14,c15,c16,c17
  dw c18,c19,c1a,c1b,c1c,c1d,c1e,c1f
  dw c20,c21,c22,c23,c24,c25,c26,c27
  dw c28,c29,c2a,c2b,c2c,c2d,c2e,c2f
  dw c30,c31,c32,c33,c34,c35,c36,c37
  dw c38,c39,c3a,c3b,c3c,c3d,c3e,c3f
  dw c40,c41,c42,c43,c44,c45,c46,c47
  dw c48,c49,c4a,c4b,c4c,c4d,c4e,c4f
  dw c50,c51,c52,c53,c54,c55,c56,c57
  dw c58,c59,c5a,c5b,c5c,c5d,c5e,c5f
  dw c60,c61,c62,c63,c64,c65,c66,c67
  dw c68,c69,c6a,c6b,c6c,c6d,c6e,c6f
  dw c70,c71,c72,c73,c74,c75,c76,c77
  dw c78,c79,c7a,c7b,c7c,c7d,c7e,c7f
  dw c80,c81,c82,c83,c84,c85,c86,c87
  dw c88,c89,c8a,c8b,c8c,c8d,c8e,c8f
  dw c90,c91,c92,c93,c94,c95,c96,c97
  dw c98,c99,c9a,c9b,c9c,c9d,c9e,c9f
  dw cA0,cA1,cA2,cA3,cA4,cA5,cA6,cA7
  dw cA8,cA9,cAa,cAb,cAc,cAd,cAe,cAf
  dw cB0,cB1,cB2,cB3,cB4,cB5,cB6,cB7
  dw cB8,cB9,cBa,cBb,cBc,cBd,cBe,cBf
  dw cC0,cC1,cC2,cC3,cC4,cC5,cC6,cC7
  dw cC8,cC9,cCa,cCb,cCc,cCd,cCe,cCf
  dw cD0,cD1,cD2,cD3,cD4,cD5,cD6,cD7
  dw cD8,cD9,cDa,cDb,cDc,cDd,cDe,cDf
  dw cE0,cE1,cE2,cE3,cE4,cE5,cE6,cE7
  dw cE8,cE9,cEa,cEb,cEc,cEd,cEe,cEf
  dw cF0,cF1,cF2,cF3,cF4,cF5,cF6,cF7
  dw cF8,cF9,cFa,cFb,cFc,cFd,cFe,cFf

; Таблица входов в подпрограммы обработки инструкций 8080 в
; режиме эмуляции видео-ОЗУ
code_tbl_m:
  dw c00,c01,d02,c03,c04,c05,c06,c07
  dw c08,c09,c0a,c0b,c0c,c0d,c0e,c0f
  dw c10,c11,d12,c13,c14,c15,c16,c17
  dw c18,c19,c1a,c1b,c1c,c1d,c1e,c1f
  dw c20,c21,d22,c23,c24,c25,c26,c27
  dw c28,c29,c2a,c2b,c2c,c2d,c2e,c2f
  dw c30,c31,d32,c33,d34,d35,d36,c37
  dw c38,c39,c3a,c3b,c3c,c3d,c3e,c3f
  dw c40,c41,c42,c43,c44,c45,c46,c47
  dw c48,c49,c4a,c4b,c4c,c4d,c4e,c4f
  dw c50,c51,c52,c53,c54,c55,c56,c57
  dw c58,c59,c5a,c5b,c5c,c5d,c5e,c5f
  dw c60,c61,c62,c63,c64,c65,c66,c67
  dw c68,c69,c6a,c6b,c6c,c6d,c6e,c6f
  dw d70,d71,d72,d73,d74,d75,c76,d77
  dw c78,c79,c7a,c7b,c7c,c7d,c7e,c7f
  dw c80,c81,c82,c83,c84,c85,c86,c87
  dw c88,c89,c8a,c8b,c8c,c8d,c8e,c8f
  dw c90,c91,c92,c93,c94,c95,c96,c97
  dw c98,c99,c9a,c9b,c9c,c9d,c9e,c9f
  dw cA0,cA1,cA2,cA3,cA4,cA5,cA6,cA7
  dw cA8,cA9,cAa,cAb,cAc,cAd,cAe,cAf
  dw cB0,cB1,cB2,cB3,cB4,cB5,cB6,cB7
  dw cB8,cB9,cBa,cBb,cBc,cBd,cBe,cBf
  dw cC0,cC1,cC2,cC3,cC4,cC5,cC6,cC7
  dw cC8,cC9,cCa,cCb,cCc,cCd,cCe,cCf
  dw cD0,cD1,cD2,cD3,cD4,cD5,cD6,cD7
  dw cD8,cD9,cDa,cDb,cDc,cDd,cDe,cDf
  dw cE0,cE1,cE2,cE3,cE4,cE5,cE6,cE7
  dw cE8,cE9,cEa,cEb,cEc,cEd,cEe,cEf
  dw cF0,cF1,cF2,cF3,cF4,cF5,cF6,cF7
  dw cF8,cF9,cFa,cFb,cFc,cFd,cFe,cFf

; Таблица входов в подпрограммы обработки инструкций 8080 в
; режиме эмуляции видео-ОЗУ и портов клавиатуры
code_tbl_m2:
  dw c00,c01,d02,c03,c04,c05,c06,c07
  dw c08,c09,e0a,c0b,c0c,c0d,c0e,c0f
  dw c10,c11,d12,c13,c14,c15,c16,c17
  dw c18,c19,e1a,c1b,c1c,c1d,c1e,c1f
  dw c20,c21,d22,c23,c24,c25,c26,c27
  dw c28,c29,c2a,c2b,c2c,c2d,c2e,c2f
  dw c30,c31,d32,c33,d34,d35,d36,c37
  dw c38,c39,e3a,c3b,c3c,c3d,c3e,c3f
  dw c40,c41,c42,c43,c44,c45,e46,c47
  dw c48,c49,c4a,c4b,c4c,c4d,e4e,c4f
  dw c50,c51,c52,c53,c54,c55,e56,c57
  dw c58,c59,c5a,c5b,c5c,c5d,e5e,c5f
  dw c60,c61,c62,c63,c64,c65,e66,c67
  dw c68,c69,c6a,c6b,c6c,c6d,e6e,c6f
  dw d70,d71,d72,d73,d74,d75,c76,d77
  dw c78,c79,c7a,c7b,c7c,c7d,e7e,c7f
  dw c80,c81,c82,c83,c84,c85,e86,c87
  dw c88,c89,c8a,c8b,c8c,c8d,e8e,c8f
  dw c90,c91,c92,c93,c94,c95,e96,c97
  dw c98,c99,c9a,c9b,c9c,c9d,e9e,c9f
  dw cA0,cA1,cA2,cA3,cA4,cA5,eA6,cA7
  dw cA8,cA9,cAa,cAb,cAc,cAd,eAe,cAf
  dw cB0,cB1,cB2,cB3,cB4,cB5,eB6,cB7
  dw cB8,cB9,cBa,cBb,cBc,cBd,eBe,cBf
  dw cC0,cC1,cC2,cC3,cC4,cC5,cC6,cC7
  dw cC8,cC9,cCa,cCb,cCc,cCd,cCe,cCf
  dw cD0,cD1,cD2,cD3,cD4,cD5,cD6,cD7
  dw cD8,cD9,cDa,eDb,cDc,cDd,cDe,cDf
  dw cE0,cE1,cE2,cE3,cE4,cE5,cE6,cE7
  dw cE8,cE9,cEa,cEb,cEc,cEd,cEe,cEf
  dw cF0,cF1,cF2,cF3,cF4,cF5,cF6,cF7
  dw cF8,cF9,cFa,cFb,cFc,cFd,cFe,cFf

; Реализация подпрограмм, соответствующих инструкциям 8080
; Соответствие регистров:
; 
;  A - AL
; BC - CX
; DE - DX
; HL - BX
; SP - DI
; PC - SI
; flags - flags

c10:
c20:
c30:
c08:
c18:
c28:
c38:

c00:;nop
	pushf
	inc si
	popf
	mov bp,4
	ret

c01:;lxi b,imm16
	mov cx,word ptr [si+1]
	pushf
	add si,3
	popf
	mov bp,10
	ret

c11:;lxi d,imm16
	mov dx,word ptr [si+1]
	pushf
	add si,3
	popf
	mov bp,10
	ret

c21:;lxi h,imm16
	mov bx,word ptr [si+1]
	pushf
	add si,3
	popf
	mov bp,10
	ret

c31:;lxi sp,imm16
	mov di,word ptr [si+1]
	pushf
	add si,3
	popf
	mov bp,10
	ret

c03:;inx b
	pushf
	inc cx
	inc si
	popf
	mov bp,5
	ret

c13:;inx d
	pushf
	inc dx
	inc si
	popf
	mov bp,5
	ret

c23:;inx h
	pushf
	inc bx
	inc si
	popf
	mov bp,5
	ret

c33:;inx sp
	pushf
	inc di
	inc si
	popf
	mov bp,5
	ret

c0B:;dcx b
	pushf
	dec cx
	inc si
	popf
	mov bp,5
	ret

c1B:;dcx d
	pushf
	dec dx
	inc si
	popf
	mov bp,5
	ret

c2B:;dcx h
	pushf
	dec bx
	inc si
	popf
	mov bp,5
	ret

c3B:;dcx sp
	pushf
	dec di
	inc si
	popf
	mov bp,5
	ret

c04:;inr b
	inc ch
	pushf
	inc si
	popf
	mov bp,5
	ret

c14:;inr d
	inc dh
	pushf
	inc si
	popf
	mov bp,5
	ret

c24:;inr h
	inc bh
	pushf
	inc si
	popf
	mov bp,5
	ret

c34:;inr m
	inc byte ptr [bx]
	pushf
	inc si
	popf
	mov bp,10
	ret

c0C:;inr c
	inc cl
	pushf
	inc si
	popf
	mov bp,5
	ret

c1C:;inr e
	inc dl
	pushf
	inc si
	popf
	mov bp,5
	ret

c2C:;inr l
	inc bl
	pushf
	inc si
	popf
	mov bp,5
	ret

c3C:;inr a
	inc al
	pushf
	inc si
	popf
	mov bp,5
	ret

c05:;dcr b
	dec ch
	pushf
	inc si
	popf
	mov bp,5
	ret

c15:;dcr d
	dec dh
	pushf
	inc si
	popf
	mov bp,5
	ret

c25:;dcr h
	dec bh
	pushf
	inc si
	popf
	mov bp,5
	ret

c35:;dcr m
	dec byte ptr [bx]
	pushf
	inc si
	popf
	mov bp,10
	ret

c0D:;dcr c
	dec cl
	pushf
	inc si
	popf
	mov bp,5
	ret

c1D:;dcr e
	dec dl
	pushf
	inc si
	popf
	mov bp,5
	ret

c2D:;dcr l
	dec bl
	pushf
	inc si
	popf
	mov bp,5
	ret

c3D:;dcr a
	dec al
	pushf
	inc si
	popf
	mov bp,5
	ret

c06:;mvi b,imm8
	mov ch,byte ptr [si+1]
	pushf
	inc si
	inc si
	popf
	mov bp,7
	ret

c16:;mvi d,imm8
	mov dh,byte ptr [si+1]
	pushf
	inc si
	inc si
	popf
	mov bp,7
	ret

c26:;mvi h,imm8
	mov bh,byte ptr [si+1]
	pushf
	inc si
	inc si
	popf
	mov bp,7
	ret

c36:;mvi m,imm8
	mov ah,byte ptr [si+1]
	mov byte ptr [bx],ah
	pushf
	inc si
	inc si
	popf
	mov bp,10
	ret

c0E:;mvi c,imm8
	mov cl,byte ptr [si+1]
	pushf
	inc si
	inc si
	popf
	mov bp,7
	ret

c1E:;mvi e,imm8
	mov dl,byte ptr [si+1]
	pushf
	inc si
	inc si
	popf
	mov bp,7
	ret

c2E:;mvi l,imm8
	mov bl,byte ptr [si+1]
	pushf
	inc si
	inc si
	popf
	mov bp,7
	ret

c3E:;mvi a,imm8
	mov al,byte ptr [si+1]
	pushf
	inc si
	inc si
	popf
	mov bp,7
	ret

c09:;dad b
	lahf
	mov bp,0e000h
	pushf
        and bp,ax
        popf
        add bx,cx
	lahf
        and ax,01ffh
	or ax,bp
        inc si
	sahf
	mov bp,10
	ret

c19:;dad d
	lahf
	mov bp,0e000h
	pushf
        and bp,ax
        popf
        add bx,dx
	lahf
        and ax,01ffh
	or ax,bp
        inc si
	sahf
	mov bp,10
	ret

c29:;dad h
	lahf
	mov bp,0e000h
	pushf
        and bp,ax
        popf
        add bx,bx
	lahf
        and ax,01ffh
	or ax,bp
        inc si
	sahf
	mov bp,10
	ret

c39:;dad sp
	lahf
	mov bp,0e000h
	pushf
        and bp,ax
        popf
        add bx,di
	lahf
        and ax,01ffh
	or ax,bp
        inc si
	sahf
	mov bp,10
	ret

c02:;stax b
	mov bp,cx
	mov byte ptr ds:[bp],al
	pushf
	inc si
	popf
	mov bp,7
	ret

c12:;stax d
	mov bp,dx
	mov byte ptr ds:[bp],al
	pushf
	inc si
	popf
	mov bp,7
	ret

c0A:;ldax b
	mov bp,cx
	mov al,byte ptr ds:[bp]
	pushf
	inc si
	popf
	mov bp,7
	ret

c1A:;ldax d
	mov bp,dx
	mov al,byte ptr ds:[bp]
	pushf
	inc si
	popf
	mov bp,7
	ret

c22:;shld addr
	mov bp,word ptr [si+1]
	mov word ptr ds:[bp],bx
	pushf
	add si,3
	popf
	mov bp,16
	ret

c2A:;lhld addr
	mov bp,word ptr [si+1]
	mov bx,word ptr ds:[bp]
	pushf
	add si,3
	popf
	mov bp,16
	ret

c32:;sta addr
	mov bp,word ptr [si+1]
	mov byte ptr ds:[bp],al
	pushf
	add si,3
	popf
	mov bp,13
	ret

c3A:;lda addr
	mov bp,word ptr [si+1]
	mov al,byte ptr ds:[bp]
	pushf
	add si,3
	popf
	mov bp,13
	ret

c07:;rlc
	rol al,1
	pushf
	inc si
	popf
	mov bp,4
	ret

c0F:;rrc
	ror al,1
	pushf
	inc si
	popf
	mov bp,4
	ret

c17:;ral
	rcl al,1
	pushf
	inc si
	popf
	mov bp,4
	ret

c1F:;rar
	rcr al,1
	pushf
	inc si
	popf
	mov bp,4
	ret

c27:;daa
	daa
	pushf
	inc si
	popf
	mov bp,4
	ret

c37:;stc
	stc
	pushf
	inc si
	popf
	mov bp,4
	ret

c2F:;cma
	pushf
	xor al,0ffh
	inc si
	popf
	mov bp,4
	ret

c3F:;cmc
	cmc
	pushf
	inc si
	popf
	mov bp,4
	ret

c40:;mov b,b
c49:;mov c,c
c52:;mov d,d
c5B:;mov e,e
c64:;mov h,h
c6D:;mov l,l
c7f:;mov a,a
	pushf
	inc si
	popf
	mov bp,5
	ret

c41:;mov b,c
	mov ch,cl
	pushf
	inc si
	popf
	mov bp,5
	ret

c42:;mov b,d
	mov ch,dh
	pushf
	inc si
	popf
	mov bp,5
	ret

c43:;mov b,e
	mov ch,dl
	pushf
	inc si
	popf
	mov bp,5
	ret

c44:;mov b,h
	mov ch,bh
	pushf
	inc si
	popf
	mov bp,5
	ret

c45:;mov b,l
	mov ch,bl
	pushf
	inc si
	popf
	mov bp,5
	ret

c46:;mov b,m
	mov ch,byte ptr [bx]
	pushf
	inc si
	popf
	mov bp,7
	ret

c47:;mov b,a
	mov ch,al
	pushf
	inc si
	popf
	mov bp,5
	ret

c48:;mov c,b
	mov cl,ch
	pushf
	inc si
	popf
	mov bp,5
	ret

c4A:;mov c,d
	mov cl,dh
	pushf
	inc si
	popf
	mov bp,5
	ret

c4B:;mov c,e
	mov cl,dl
	pushf
	inc si
	popf
	mov bp,5
	ret

c4C:;mov c,h
	mov cl,bh
	pushf
	inc si
	popf
	mov bp,5
	ret

c4D:;mov c,l
	mov cl,bl
	pushf
	inc si
	popf
	mov bp,5
	ret

c4E:;mov c,m
	mov cl,byte ptr [bx]
	pushf
	inc si
	popf
	mov bp,7
	ret

c4F:;mov c,a
	mov cl,al
	pushf
	inc si
	popf
	mov bp,5
	ret

c50:;mov d,b
	mov dh,ch
	pushf
	inc si
	popf
	mov bp,5
	ret

c51:;mov d,c
	mov dh,cl
	pushf
	inc si
	popf
	mov bp,5
	ret

c53:;mov d,e
	mov dh,dl
	pushf
	inc si
	popf
	mov bp,5
	ret

c54:;mov d,h
	mov dh,bh
	pushf
	inc si
	popf
	mov bp,5
	ret

c55:;mov d,l
	mov dh,bl
	pushf
	inc si
	popf
	mov bp,5
	ret

c56:;mov d,m
	mov dh,byte ptr [bx]
	pushf
	inc si
	popf
	mov bp,7
	ret

c57:;mov d,a
	mov dh,al
	pushf
	inc si
	popf
	mov bp,5
	ret

c58:;mov e,b
	mov dl,ch
	pushf
	inc si
	popf
	mov bp,5
	ret

c59:;mov e,c
	mov dl,cl
	pushf
	inc si
	popf
	mov bp,5
	ret

c5A:;mov e,d
	mov dl,dh
	pushf
	inc si
	popf
	mov bp,5
	ret

c5C:;mov e,h
	mov dl,bh
	pushf
	inc si
	popf
	mov bp,5
	ret

c5D:;mov e,l
	mov dl,bl
	pushf
	inc si
	popf
	mov bp,5
	ret

c5E:;mov e,m
	mov dl,byte ptr [bx]
	pushf
	inc si
	popf
	mov bp,7
	ret

c5F:;mov e,a
	mov dl,al
	pushf
	inc si
	popf
	mov bp,5
	ret

c60:;mov h,b
	mov bh,ch
	pushf
	inc si
	popf
	mov bp,5
	ret

c61:;mov h,c
	mov bh,cl
	pushf
	inc si
	popf
	mov bp,5
	ret

c62:;mov h,d
	mov bh,dh
	pushf
	inc si
	popf
	mov bp,5
	ret

c63:;mov h,e
	mov bh,dl
	pushf
	inc si
	popf
	mov bp,5
	ret

c65:;mov h,l
	mov bh,bl
	pushf
	inc si
	popf
	mov bp,5
	ret

c66:;mov h,m
	mov bh,byte ptr [bx]
	pushf
	inc si
	popf
	mov bp,7
	ret

c67:;mov h,a
	mov bh,al
	pushf
	inc si
	popf
	mov bp,5
	ret

c68:;mov l,b
	mov bl,ch
	pushf
	inc si
	popf
	mov bp,5
	ret

c69:;mov l,c
	mov bl,cl
	pushf
	inc si
	popf
	mov bp,5
	ret

c6A:;mov l,d
	mov bl,dh
	pushf
	inc si
	popf
	mov bp,5
	ret

c6B:;mov l,e
	mov bl,dl
	pushf
	inc si
	popf
	mov bp,5
	ret

c6C:;mov l,h
	mov bl,bh
	pushf
	inc si
	popf
	mov bp,5
	ret

c6E:;mov l,m
	mov bl,byte ptr [bx]
	pushf
	inc si
	popf
	mov bp,7
	ret

c6F:;mov l,a
	mov bl,al
	pushf
	inc si
	popf
	mov bp,5
	ret

c70:;mov m,b
	mov byte ptr [bx],ch
	pushf
	inc si
	popf
	mov bp,7
	ret

c71:;mov m,c
	mov byte ptr [bx],cl
	pushf
	inc si
	popf
	mov bp,7
	ret

c72:;mov m,d
	mov byte ptr [bx],dh
	pushf
	inc si
	popf
	mov bp,7
	ret

c73:;mov m,e
	mov byte ptr [bx],dl
	pushf
	inc si
	popf
	mov bp,7
	ret

c74:;mov m,h
	mov byte ptr [bx],bh
	pushf
	inc si
	popf
	mov bp,7
	ret

c75:;mov m,l
	mov byte ptr [bx],bl
	pushf
	inc si
	popf
	mov bp,7
	ret

c77:;mov m,a
	mov byte ptr [bx],al
	pushf
	inc si
	popf
	mov bp,7
	ret

c78:;mov a,b
	mov al,ch
	pushf
	inc si
	popf
	mov bp,5
	ret

c79:;mov a,c
	mov al,cl
	pushf
	inc si
	popf
	mov bp,5
	ret

c7A:;mov a,d
	mov al,dh
	pushf
	inc si
	popf
	mov bp,5
	ret

c7B:;mov a,e
	mov al,dl
	pushf
	inc si
	popf
	mov bp,5
	ret

c7C:;mov a,h
	mov al,bh
	pushf
	inc si
	popf
	mov bp,5
	ret

c7D:;mov a,l
	mov al,bl
	pushf
	inc si
	popf
	mov bp,5
	ret

c7E:;mov a,m
	mov al,byte ptr [bx]
	pushf
	inc si
	popf
	mov bp,7
	ret

c76:;hlt
;	jmp fin
	mov bp,7
	ret

c80:;add b
	add al,ch
	pushf
	inc si
	popf
	mov bp,4
	ret

c81:;add c
	add al,cl
	pushf
	inc si
	popf
	mov bp,4
	ret

c82:;add d
	add al,dh
	pushf
	inc si
	popf
	mov bp,4
	ret

c83:;add e
	add al,dl
	pushf
	inc si
	popf
	mov bp,4
	ret

c84:;add h
	add al,bh
	pushf
	inc si
	popf
	mov bp,4
	ret

c85:;add l
	add al,bl
	pushf
	inc si
	popf
	mov bp,4
	ret

c86:;add m
	add al,byte ptr [bx]
	pushf
	inc si
	popf
	mov bp,7
	ret

c87:;add a
	add al,al
	pushf
	inc si
	popf
	mov bp,4
	ret

c88:;adc b
	adc al,ch
	pushf
	inc si
	popf
	mov bp,4
	ret

c89:;adc c
	adc al,cl
	pushf
	inc si
	popf
	mov bp,4
	ret

c8A:;adc d
	adc al,dh
	pushf
	inc si
	popf
	mov bp,4
	ret

c8B:;adc e
	adc al,dl
	pushf
	inc si
	popf
	mov bp,4
	ret

c8C:;adc h
	adc al,bh
	pushf
	inc si
	popf
	mov bp,4
	ret

c8D:;adc l
	adc al,bl
	pushf
	inc si
	popf
	mov bp,4
	ret

c8E:;adc m
	adc al,byte ptr [bx]
	pushf
	inc si
	popf
	mov bp,7
	ret

c8F:;adc a
	adc al,al
	pushf
	inc si
	popf
	mov bp,4
	ret

c90:;sub b
	sub al,ch
	pushf
	inc si
	popf
	mov bp,4
	ret

c91:;sub c
	sub al,cl
	pushf
	inc si
	popf
	mov bp,4
	ret

c92:;sub d
	sub al,dh
	pushf
	inc si
	popf
	mov bp,4
	ret

c93:;sub e
	sub al,dl
	pushf
	inc si
	popf
	mov bp,4
	ret

c94:;sub h
	sub al,bh
	pushf
	inc si
	popf
	mov bp,4
	ret

c95:;sub l
	sub al,bl
	pushf
	inc si
	popf
	mov bp,4
	ret

c96:;sub m
	sub al,byte ptr [bx]
	pushf
	inc si
	popf
	mov bp,7
	ret

c97:;sub a
	sub al,al
	pushf
	inc si
	popf
	mov bp,4
	ret

c98:;sbb b
	sbb al,ch
	pushf
	inc si
	popf
	mov bp,4
	ret

c99:;sbb c
	sbb al,cl
	pushf
	inc si
	popf
	mov bp,4
	ret

c9A:;sbb d
	sbb al,dh
	pushf
	inc si
	popf
	mov bp,4
	ret

c9B:;sbb e
	sbb al,dl
	pushf
	inc si
	popf
	mov bp,4
	ret

c9C:;sbb h
	sbb al,bh
	pushf
	inc si
	popf
	mov bp,4
	ret

c9D:;sbb l
	sbb al,bl
	pushf
	inc si
	popf
	mov bp,4
	ret

c9E:;sbb m
	sbb al,byte ptr [bx]
	pushf
	inc si
	popf
	mov bp,7
	ret

c9F:;sbb a
	sbb al,al
	pushf
	inc si
	popf
	mov bp,4
	ret

cA0:;ana b
	and al,ch
	pushf
	inc si
	popf
	mov bp,4
	ret

cA1:;ana c
	and al,cl
	pushf
	inc si
	popf
	mov bp,4
	ret

cA2:;ana d
	and al,dh
	pushf
	inc si
	popf
	mov bp,4
	ret

cA3:;ana e
	and al,dl
	pushf
	inc si
	popf
	mov bp,4
	ret

cA4:;ana h
	and al,bh
	pushf
	inc si
	popf
	mov bp,4
	ret

cA5:;ana l
	and al,bl
	pushf
	inc si
	popf
	mov bp,4
	ret

cA6:;ana m
	and al,byte ptr [bx]
	pushf
	inc si
	popf
	mov bp,7
	ret

cA7:;ana a
	and al,al
	pushf
	inc si
	popf
	mov bp,4
	ret

cA8:;xra b
	xor al,ch
	pushf
	inc si
	popf
	mov bp,4
	ret

cA9:;xra c
	xor al,cl
	pushf
	inc si
	popf
	mov bp,4
	ret

cAA:;xra d
	xor al,dh
	pushf
	inc si
	popf
	mov bp,4
	ret

cAB:;xra e
	xor al,dl
	pushf
	inc si
	popf
	mov bp,4
	ret

cAC:;xra h
	xor al,bh
	pushf
	inc si
	popf
	mov bp,4
	ret

cAD:;xra l
	xor al,bl
	pushf
	inc si
	popf
	mov bp,4
	ret

cAE:;xra m
	xor al,byte ptr [bx]
	pushf
	inc si
	popf
	mov bp,7
	ret

cAF:;xra a
	xor al,al
	pushf
	inc si
	popf
	mov bp,4
	ret

cB0:;ora b
	or al,ch
	pushf
	inc si
	popf
	mov bp,4
	ret

cB1:;ora c
	or al,cl
	pushf
	inc si
	popf
	mov bp,4
	ret

cB2:;ora d
	or al,dh
	pushf
	inc si
	popf
	mov bp,4
	ret

cB3:;ora e
	or al,dl
	pushf
	inc si
	popf
	mov bp,4
	ret

cB4:;ora h
	or al,bh
	pushf
	inc si
	popf
	mov bp,4
	ret

cB5:;ora l
	or al,bl
	pushf
	inc si
	popf
	mov bp,4
	ret

cB6:;ora m
	or al,byte ptr [bx]
	pushf
	inc si
	popf
	mov bp,7
	ret

cB7:;ora a
	or al,al
	pushf
	inc si
	popf
	mov bp,4
	ret

cB8:;cmp b
	cmp al,ch
	pushf
	inc si
	popf
	mov bp,4
	ret

cB9:;cmp c
	cmp al,cl
	pushf
	inc si
	popf
	mov bp,4
	ret

cBA:;cmp d
	cmp al,dh
	pushf
	inc si
	popf
	mov bp,4
	ret

cBB:;cmp e
	cmp al,dl
	pushf
	inc si
	popf
	mov bp,4
	ret

cBC:;cmp h
	cmp al,bh
	pushf
	inc si
	popf
	mov bp,4
	ret

cBD:;cmp l
	cmp al,bl
	pushf
	inc si
	popf
	mov bp,4
	ret

cBE:;cmp m
	cmp al,byte ptr [bx]
	pushf
	inc si
	popf
	mov bp,7
	ret

cBF:;cmp a
	cmp al,al
	pushf
	inc si
	popf
	mov bp,4
	ret

cC6:;adi imm8
	add al,byte ptr [si+1]
	pushf
	inc si
	inc si
	popf
	mov bp,7
	ret

cD6:;sui imm8
	sub al,byte ptr [si+1]
	pushf
	inc si
	inc si
	popf
	mov bp,7
	ret

cE6:;ani imm8
	and al,byte ptr [si+1]
	pushf
	inc si
	inc si
	popf
	mov bp,7
	ret

cF6:;ori imm8
	or al,byte ptr [si+1]
	pushf
	inc si
	inc si
	popf
	mov bp,7
	ret

cCE:;aci imm8
	adc al,byte ptr [si+1]
	pushf
	inc si
	inc si
	popf
	mov bp,7
	ret

cDE:;sbi imm8
	sbb al,byte ptr [si+1]
	pushf
	inc si
	inc si
	popf
	mov bp,7
	ret

cEE:;xri imm8
	xor al,byte ptr [si+1]
	pushf
	inc si
	inc si
	popf
	mov bp,7
	ret

cFE:;cpi imm8
	cmp al,byte ptr [si+1]
	pushf
	inc si
	inc si
	popf
	mov bp,7
	ret

cC3:;jmp addr
	mov si,word ptr [si+1]
	mov bp,10
	ret

cCA:;jz addr
	jz cC3
	pushf
	add si,3
	popf
	mov bp,7
	ret

cDA:;jc addr
	jc cC3
	pushf
	add si,3
	popf
	mov bp,7
	ret

cEA:;jpe addr
	jpe cC3
	pushf
	add si,3
	popf
	mov bp,7
	ret

cFA:;jm addr
	js cC3
	pushf
	add si,3
	popf
	mov bp,7
	ret

cC2:;jnz addr
	jnz cC3
	pushf
	add si,3
	popf
	mov bp,7
	ret

cD2:;jnc addr
	jnc cC3
	pushf
	add si,3
	popf
	mov bp,7
	ret

cE2:;jpo addr
	jpo cC3
	pushf
	add si,3
	popf
	mov bp,7
	ret

cF2:;jp addr
	jns cC3
	pushf
	add si,3
	popf
	mov bp,7
	ret

cCB:
cDD:
cED:
cFD:
cCD:;call addr
	pushf
	dec di
	dec di
	add si,3
	popf
	mov word ptr [di],si
	mov si,word ptr [si-2]
	mov bp,17
	ret

cCC:;сz addr
	jz cCD
	pushf
	add si,3
	popf
	mov bp,11
	ret

cDC:;сc addr
	jc cCD
	pushf
	add si,3
	popf
	mov bp,11
	ret

cEC:;сpe addr
	jpe cCD
	pushf
	add si,3
	popf
	mov bp,11
	ret

cFC:;сm addr
	js cCD
	pushf
	add si,3
	popf
	mov bp,11
	ret

cC4:;сnz addr
	jnz cCD
	pushf
	add si,3
	popf
	mov bp,11
	ret

cD4:;сnc addr
	jnc cCD
	pushf
	add si,3
	popf
	mov bp,11
	ret

cE4:;сpo addr
	jpo cCD
	pushf
	add si,3
	popf
	mov bp,11
	ret

cF4:;сp addr
	jns cCD
	pushf
	add si,3
	popf
	mov bp,11
	ret

cD9:
cC9:;ret
	mov si,word ptr [di]
	pushf
	inc di
	inc di
	popf
	mov bp,11
	ret

cC8:;rz
	jz cC9
	pushf
	inc si
	popf
	mov bp,5
	ret

cD8:;rc
	jc cC9
	pushf
	inc si
	popf
	mov bp,5
	ret

cE8:;rpe
	jpe cC9
	pushf
	inc si
	popf
	mov bp,5
	ret

cF8:;rm
	js cC9
	pushf
	inc si
	popf
	mov bp,5
	ret

cC0:;rnz
	jnz cC9
	pushf
	inc si
	popf
	mov bp,5
	ret

cD0:;rnc
	jnc cC9
	pushf
	inc si
	popf
	mov bp,5
	ret

cE0:;rpo
	jpo cC9
	pushf
	inc si
	popf
	mov bp,5
	ret

cF0:;rp
	jns cC9
	pushf
	inc si
	popf
	mov bp,5
	ret

cC7:;rst 0
	pushf
	dec di
	dec di
	inc si
	popf
	mov word ptr [di],si
	mov si,00h
	mov bp,11
	ret

cD7:;rst 2
	pushf
	dec di
	dec di
	inc si
	popf
	mov word ptr [di],si
	mov si,10h
	mov bp,11
	ret

cE7:;rst 4
	pushf
	dec di
	dec di
	inc si
	popf
	mov word ptr [di],si
	mov si,20h
	mov bp,11
	ret

rst6:
cF7:;rst 6
	pushf
	dec di
	dec di
	inc si
	popf
	mov word ptr [di],si
	mov si,30h
	mov bp,11
	ret

cCF:;rst 1
	pushf
	dec di
	dec di
	inc si
	popf
	mov word ptr [di],si
	mov si,08h
	mov bp,11
	ret

cDF:;rst 3
	pushf
	dec di
	dec di
	inc si
	popf
	mov word ptr [di],si
	mov si,18h
	mov bp,11
	ret

cEF:;rst 5
	pushf
	dec di
	dec di
	inc si
	popf
	mov word ptr [di],si
	mov si,28h
	mov bp,11
	ret

cFF:;rst 7
	pushf
	dec di
	dec di
	inc si
	popf
	mov word ptr [di],si
	mov si,38h
	mov bp,11
	ret

cC5:;push b
	pushf
	dec di
	dec di
	mov word ptr [di],cx
	inc si
	popf
	mov bp,11
	ret

cD5:;push d
	pushf
	dec di
	dec di
	mov word ptr [di],dx
	inc si
	popf
	mov bp,11
	ret

cE5:;push h
	pushf
	dec di
	dec di
	mov word ptr [di],bx
	inc si
	popf
	mov bp,11
	ret

cF5:;push psw
	pushf
	dec di
	dec di
	popf
	lahf
	xchg ah,al
	mov word ptr [di],ax
	xchg ah,al
	pushf
	inc si
	popf
	mov bp,11
	ret

cC1:;pop b
	mov cx,word ptr [di]
	pushf
	inc di
	inc di
	inc si
	popf
	mov bp,10
	ret

cD1:;pop d
	mov dx,word ptr [di]
	pushf
	inc di
	inc di
	inc si
	popf
	mov bp,10
	ret

cE1:;pop h
	mov bx,word ptr [di]
	pushf
	inc di
	inc di
	inc si
	popf
	mov bp,10
	ret

cF1:;pop psw
	mov ax,word ptr [di]
	xchg ah,al
	sahf
	pushf
	inc di
	inc di
	inc si
	popf
	mov bp,10
	ret

cF3:;di
	pushf
	inc si
	call disable_ints
	popf
	mov bp,4
	ret
cFB:;ei    
	pushf
	inc si
	call enable_ints
	popf
	mov bp,4
	ret

cD3:;out port8
	push bx
	mov bh,byte ptr [si+1]
	mov bl,bh
	mov byte ptr [bx],al
	pop bx
	pushf
	inc si
	inc si
	popf
	mov bp,10
	ret

cDB:;in port8
	push bx
	mov bh,byte ptr [si+1]
	mov bl,bh
	mov al,byte ptr [bx]
	pop bx
	pushf
	inc si
	inc si
	popf
	mov bp,10
	ret

cE3:;xthl
	xchg word ptr [di],bx
	pushf
	inc si
	popf
	mov bp,18
	ret

cEB:;xchg
	xchg dx,bx
	pushf
	inc si
	popf
	mov bp,4
	ret

cF9:;sphl
	mov di,bx
	pushf
	inc si
	popf
	mov bp,5
	ret

cE9:;pchl
	mov si,bx
	mov bp,5
	ret

;#### С эмуляцией видеопамяти ####

d02:;stax b
	pushf
	mov bp,cx
	mov ah,al
	call save_byte
	inc si
	popf
	mov bp,7
	ret

d12:;stax d
	pushf
	mov bp,dx
	mov ah,al
	call save_byte
	inc si
	popf
	mov bp,7
	ret

d36:;mvi m,imm8
	mov ah,byte ptr [si+1]
	mov bp,bx
	pushf
	call save_byte
	inc si
	inc si
	popf
	mov bp,10
	ret

d32:;sta addr
	mov bp,word ptr [si+1]
	mov ah,al
	pushf
	call save_byte
	add si,3
	popf
	mov bp,13
	ret

d34:;inr m
	mov ah,byte ptr [bx]
	inc ah
	mov bp,bx
	pushf
	call save_byte
	inc si
	popf
	mov bp,10
	ret

d35:;dcr m
	mov ah,byte ptr [bx]
	dec ah
	mov bp,bx
	pushf
	call save_byte
	inc si
	popf
	mov bp,10
	ret

d22:;shld addr
	mov bp,word ptr [si+1]
	mov ah,bl
	pushf
	push bp
	call save_byte
	pop bp
	inc bp
	mov ah,bh
	call save_byte
	add si,3
	popf
	mov bp,16
	ret

d70:;mov m,b
	pushf
	mov bp,bx
	mov ah,ch
	call save_byte
	inc si
	popf
	mov bp,7
	ret

d71:;mov m,c
	pushf
	mov bp,bx
	mov ah,cl
	call save_byte
	inc si
	popf
	mov bp,7
	ret

d72:;mov m,d
	pushf
	mov bp,bx
	mov ah,dh
	call save_byte
	inc si
	popf
	mov bp,7
	ret

d73:;mov m,e
	pushf
	mov bp,bx
	mov ah,dl
	call save_byte
	inc si
	popf
	mov bp,7
	ret

d74:;mov m,h
	pushf
	mov bp,bx
	mov ah,bh
	call save_byte
	inc si
	popf
	mov bp,7
	ret

d75:;mov m,l
	pushf
	mov bp,bx
	mov ah,bl
	call save_byte
	inc si
	popf
	mov bp,7
	ret

d77:;mov m,a
	pushf
	mov bp,bx
	mov ah,al
	call save_byte
	inc si
	popf
	mov bp,7
	ret

e0A:;ldax b
	mov bp,cx
	call load_byte
	mov al,ah
	pushf
	inc si
	popf
	mov bp,7
	ret

e1A:;ldax d
	pushf
	mov bp,dx
	call load_byte
	mov al,ah
	inc si
	popf
	mov bp,7
	ret

e3A:;lda addr
	pushf
	mov bp,word ptr [si+1]
	call load_byte
	mov al,ah
	add si,3
	popf
	mov bp,13
	ret

e46:;mov b,m
	pushf
	mov bp,bx
	call load_byte
	mov ch,ah
	inc si
	popf
	mov bp,7
	ret

e4e:;mov c,m
	pushf
	mov bp,bx
	call load_byte
	mov cl,ah
	inc si
	popf
	mov bp,7
	ret

e56:;mov d,m
	pushf
	mov bp,bx
	call load_byte
	mov dh,ah
	inc si
	popf
	mov bp,7
	ret

e5e:;mov e,m
	pushf
	mov bp,bx
	call load_byte
	mov dl,ah
	inc si
	popf
	mov bp,7
	ret

e66:;mov h,m
	pushf
	mov bp,bx
	call load_byte
	mov bh,ah
	inc si
	popf
	mov bp,7
	ret

e6e:;mov l,m
	pushf
	mov bp,bx
	call load_byte
	mov bl,ah
	inc si
	popf
	mov bp,7
	ret

e7e:;mov a,m
	pushf
	mov bp,bx
	call load_byte
	mov al,ah
	inc si
	popf
	mov bp,7
	ret

e86:;add m
	pushf
	inc si
	mov bp,bx
	call load_byte
	popf
	add al,ah
	mov bp,7
	ret

e8e:;adc m
	pushf
	inc si
	mov bp,bx
	call load_byte
	popf
	adc al,ah
	mov bp,7
	ret

e96:;sub m
	pushf
	inc si
	mov bp,bx
	call load_byte
	popf
	sub al,ah
	mov bp,7
	ret

e9e:;sbb m
	pushf
	inc si
	mov bp,bx
	call load_byte
	popf
	sbb al,ah
	mov bp,7
	ret

ea6:;ana m
	pushf
	inc si
	mov bp,bx
	call load_byte
	popf
	and al,ah
	mov bp,7
	ret

eae:;xra m
	pushf
	inc si
	mov bp,bx
	call load_byte
	popf
	xor al,ah
	mov bp,7
	ret

eb6:;ora m
	pushf
	inc si
	mov bp,bx
	call load_byte
	popf
	or al,ah
	mov bp,7
	ret

ebe:;cmp m
	pushf
	inc si
	mov bp,bx
	call load_byte
	popf
	cmp al,ah
	mov bp,7
	ret

eDB:;in port8
	pushf
	mov ah,byte ptr [si+1]
	mov al,ah
	mov bp,ax
	call load_byte
	mov al,ah
	inc si
	inc si
	popf
	mov bp,10
	ret

end
