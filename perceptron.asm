.386
.model flat, stdcall

includelib msvcrt.lib
extern exit: proc
extern fopen:proc
extern fscanf:proc
extern scanf:proc
extern fclose:proc
extern printf:proc

public start

.data
n equ 1000    ;;;;;;;; no. points

w dword 0,0,0 ;;;;;;;; weights
pred dword 0  ;;;;;;;; prediction
err dword 0   ;;;;;;;; error

x1 dword n dup(0) ;;;; x axis
x2 dword n dup(0) ;;;; y axis
lb dword n dup(0) ;;;; above (1) or below (-1) (label)

aux1 dword 0
aux2 dword 0
aux3 dword 0


sourcefile byte "data.txt", 0
rmode byte "r", 0
wmode byte "w", 0

integer1 byte "%d ", 0dh, 0ah, 0
integer3 byte "%d %d %d", 0dh, 0ah, 0
integer1_read byte "%d", 0
msg1 byte "x: ", 0
msg2 byte "y: ", 0 
above byte "above the line", 0dh, 0ah, 0
below byte "below the line", 0dh, 0ah, 0

.code
start:
	
	;;;; File Open ;;;;
    push offset rmode
    push offset sourcefile
    call fopen
    add esp, 8
  
    mov esi, eax
    
	;;;; Read data ;;;;
	
	mov ecx, n
  	xor ebx, ebx
reading:
	push ecx
	push offset aux3 	
	push offset aux2
	push offset aux1
	push offset integer3
 	push esi
    call fscanf
    add esp, 20
	
	mov eax, aux3
	mov lb[ebx*4], eax
	mov eax, aux2
	mov x2[ebx*4], eax
	mov eax, aux1
	mov x1[ebx*4], eax
	
	inc ebx
	pop ecx
loop reading
	
	;;;; For epochs
	mov ecx, 20000
for1:
	push ecx
	
	;;;; For points
	xor ebx, ebx
	mov ecx, n  
for2:
	push ecx
	
	;;;;; PREDICTION ;;;;; (w1*x1+w2*x2+bias)
	mov pred, 0
	mov eax, x1[ebx*4]
  	mul w[0]
  	mov pred, eax
  
  	mov eax, x2[ebx*4]
  	mul w[4]
  	add pred, eax
	
  	mov eax, w[8]
  	add pred, eax 
	
	;;;;; ERROR ;;;;;
	
	;;; max(0, 1-prediction*label) ;;;
	
	mov eax, pred
	mul lb[ebx*4]
	
	neg eax  	;  -prediction*label
	inc eax		; 1-prediction*label	
	
	mov err, 0
	
	cmp eax, 0
	jle continuare1 ;error <=0 means we do not need to update the weights
	mov err, eax
	
	;;; WEIGHT UPDATE ;;; 	w(j) += learning_rate * xj * label(i)
	
	mov eax, lb[ebx*4]
	mul x1[ebx*4]
	sar eax, 5			;;learning rate = 2^(-5)
	add w[0], eax
	
	mov eax, lb[ebx*4]
	mul x2[ebx*4]
	sar eax, 5
	add w[4], eax
	
	mov eax, lb[ebx*4]
	sar eax, 5
	add w[8], eax
	
	continuare1:
	
	cmp err, 0
	jne continuare2
	continuare2:
	
	
	inc ebx
	pop ecx
	;;; FOR2 ;;;
	dec ecx
	jne for2
	
	;;; FOR1 ;;;
	pop ecx
	
	dec ecx
	jne for1
	;;;;;;;;;;;;
	
	;;; Weight ;;;
	push w[8]
	push w[4]
	push w[0]
	push offset integer3
	call printf
	add esp, 16
	
	;;;;; Point Test ;;;;;
    
	push offset msg1
	call printf
	add esp, 4
	
	push offset aux1
	push offset integer1_read
	call scanf
	add esp, 8
	
	push offset msg2
	call printf
	add esp, 4
	
	push offset aux2
	push offset integer1_read
	call scanf
	add esp, 8
	
	mov pred, 0
	mov eax, aux1
  	mul w[0]
  	mov pred, eax
  
  	mov eax, aux2
  	mul w[4]
  	add pred, eax
	
  	mov eax, w[8]
  	add pred, eax
	
	cmp pred, 0
	jl below1
above1:
	push offset above
	call printf
	add esp, 4
	jmp final1
	
below1:
	push offset below
	call printf
	add esp, 4
final1: 

	;;;; File Close ;;;;
	push esi
	call fclose
	add esp, 4
	
	push 0
	call exit
end start