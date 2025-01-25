; uzduotis:
; suskaiciuoti y =  /   3*b+x*x                   , kai 3*b>x
;                   \   (|x|-4*a)/(c*c*c-b)     , kai 3*b=x
; skaiciai be zenklo
; Duomenys a - w, b - b, c - w, x - b, y - w

stekas  SEGMENT STACK	; steko segmentas
DB 256 DUP(0)
stekas  ENDS

duom    SEGMENT		; duomenu segmentas
a    DW 250  		; konstantos		
b    DB 10
c    DW 100
x    DB 30	; kintamojo X masyvas
kiek    = ($-x)		; elementu skaicius masyve X
y    DW kiek dup(0AAh)		; rezervuojama vieta masyvui Y
isvb    DB 'x=',6 dup (?), ' y=',6 dup (?), 0Dh, 0Ah, '$'
perp    DB 'Perpildymas', 0Dh, 0Ah, '$'
daln    DB 'Dalyba is nulio', 0Dh, 0Ah, '$'
netb    DB 'Netelpa i baita', 0Dh, 0Ah, '$'
maz     DB 'Netenkina salyga', 0Dh, 0Ah, '$'
neig     DB 'Neigiamas skaicius', 0Dh, 0Ah, '$'
spausk  DB 'Skaiciavimas baigtas, spausk bet kuri klavisa,', 0Dh, 0Ah, '$'
duom    ENDS

prog    SEGMENT		; programos kodo segmentas
assume ss:stekas, ds:duom, cs:prog
pr:    	MOV ax, duom
	MOV ds, ax	; nustatoma DS registro reiksme
	XOR si, si      ; (suma mod 2) si = 0
	XOR di, di      ; di = 0
c_pr:   MOV cx, kiek	; ciklu skaicius
	JCXZ pab	; jei 0, neskaiciuoti
cikl:
			; issisakojimas - pagal kuria formule skaiciuosime 
	MOV al, 3	; ikrauname ax - 3 (baitas)
	MUL b        ; daugyba 3*b
	JC kl1       ; tikrina ar nera pernasos
	MOV bx, ax  ; apkeiciame bx<->ax reiksmes
	MOV al, x[si]; al priskiriame x
	XOR ah, ah   ; ispleciame
	CMP ax, bx   ; lyginame su x[i] 3*b
	JNBE kl4       ; tikriname ar x nera maziau	
	JE f2		 ; jei lygu - 2-a formule

f1:  			; 3*b+x*x, kai 3*b>x  
	MOV al, x[si]	; ax = x[i]
	MUL x[si]		; ax = x*x
	ADD ax, bx 	; ax = x*x+3*b
	JC kl1		; jei suma netilpo i ax
	JMP re		; --> rezultato patikrinimas

f2:    			; |(|x|-4*a)/(c*c*c-b)|, kai 3*b=x
	MOV bx, ax  ; bx = x[i]
	MOV ax, 4	; ax = 4
	MUL a		; ax = 4*a
	JC kl1  	; jei sandauga netilpo i ax
	CMP bx, ax  
	JB kl5
	SUB bx, ax  ; bx = x-4*a
	JC kl1      ; jei atimtis netilpo i ax
	MOV ax, c   ; ax = c
	MUL c       ; ax = c*c
	JC kl1      ; jei sandauga netilpo i ax
	MUL c       ; ax = c*c*c
	JC kl1      ; jei sandauga netilpo i ax
	XCHG ax, dx ; ax--> dx )atlaisviname ax)	
	MOV al, b   ; al = b
	MOV ah, 0   ; ah = 0
	XOR ah, ah  ; ispleciame iki zodzio
	SUB dx, ax  ; dx = c*c*c - b
	JC kl1      ; jei atimtinis netilpo i ax
	CMP dx, 0   ; ar gautas vardiklis nera lygu 0
	JE kl2      ; jei lygu - dalyba is 0
	MOV ax, bx  ; vardiklis ax = x-4*a
	MOV bx, dx  ; bx = c*c*c - b
	XOR dx, dx  ; ispleciame iki dvigubio zodzio
	DIV bx      ; ax rezultatas	
	JMP re      ; rezultato patikrinimas    
re:			; rezultato patikrinimas
	CMP ah, 0     	; ar telpa rezultatas i baita
	JMP ger		; jei taip, --> gerai
	JMP kl3		; jei ne, --> klaida
ger:   
    MOV y[di], ax	; y[i] = rezultatas
	INC si		; padidiname indeksu reiksmes
	INC di
	INC di
	LOOP cikl	; kartoti skaiciavimo cikla
;=========================================================
pab:			; rezultatu isvedimas i ekrana
	XOR si, si
	XOR di, di
	MOV cx, kiek
	JCXZ is_pab
isv_cikl:
	MOV al, x[si]  	; ax = isvedama kintamojo x[i] reiksme (zodis)
	XOR ah, ah      ; ispleciama iki zodzio
	PUSH ax
	MOV bx, offset isvb+2
	PUSH bx
	CALL binasc	; suformuoti isvedimui ax turini
	MOV ax, y[di]	; ax = isvedamas rezultatas - baitas y[i]
	PUSH ax
	MOV bx, offset isvb+11
	PUSH bx
	CALL binasc	; suformuoti isvedimui ax turini
	MOV dx, offset isvb
	MOV ah, 9h
	INT 21h		; isvesti suformuota eilute
;============================
	INC si		; padidiname indeksu reiksmes
	INC di
	INC di
	LOOP isv_cikl	; kartoti isvedimo cikla
is_pab:
;===== PAUZE ===================
;===== paspausti bet kuri klavisa ===
	LEA dx, spausk
	MOV ah, 9
	INT 21h
	MOV ah, 0
	INT 16h
;============================
	MOV ah, 4Ch   	; programos pabaiga, grizti i OS
	INT 21h
;============================
			; klaidu apdorojimas
kl1:    LEA dx, perp
	MOV ah, 9
	INT 21h
	XOR ax, ax
	JMP ger
kl2:    LEA dx, daln
	MOV ah, 9
	INT 21h
	XOR ax, ax
	JMP ger
kl3:    LEA dx, netb
	MOV ah, 9
	INT 21h
	XOR ax, ax
	JMP ger
kl4:    LEA dx, maz
	MOV ah, 9
	INT 21h
	XOR ax, ax
	JMP ger
kl5:    LEA dx, neig
	MOV ah, 9
	INT 21h
	XOR ax, ax
	JMP ger
; skaiciu vercia i desimtaine sist. ir issaugo
; ASCII kode. Parametrai perduodami per steka
; Pirmasis parametras ([bp+6])- verciamas skaicius
; Antrasis parametras ([bp+4])- vieta rezultatui

binasc  PROC NEAR
	PUSH bp
	MOV bp, sp
; naudojamu registru issaugojimas
	PUSHA
; rezultato eilute uzpildome tarpais
	MOV cx, 6
	MOV bx, [bp+4]
tarp:   MOV byte ptr[bx], ' '
	INC bx
	LOOP tarp
; skaicius paruosiamas dalybai is 10
	MOV ax, [bp+6]
	MOV si, 10
val:    XOR dx, dx
	DIV si
;  gauta liekana verciame i ASCII koda
	ADD dx, '0'   ; galima--> ADD dx, 30h
;  irasome skaitmeni i eilutes pabaiga
	DEC bx
	MOV [bx], dl
; skaiciuojame pervestu simboliu kieki
	INC cx
; ar dar reikia kartoti dalyba?
	CMP ax, 0
	JNZ val

	POPA
	POP bp
	RET
binasc  ENDP

prog    ENDS
END pr
