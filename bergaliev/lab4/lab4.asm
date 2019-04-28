STACK SEGMENT STACK
 DW 10h DUP(?)
STACK ENDS

CODE SEGMENT
 ASSUME CS:CODE, DS:CODE, SS:STACK

ROUT PROC FAR
 mov KEEP_SS, SS
 mov KEEP_SP, SP
 mov AX, STACK
 mov SS, AX
 mov SP, 20h
 dec SP

 PUSH AX
 PUSH CX
 PUSH BX
 PUSH DS
 PUSH ES
 PUSH BP
 PUSH DI

 call getCurs
 push DX
 mov DH, 08h
 mov DL, 2Ch	
 call setCurs
 mov AX,seg ROUT
 mov DS,AX
 mov AX, COUNT
 inc AX
 mov COUNT,AX
 mov DI,offset CALL_COUNT_STR
 add DI,35
 call WRD_TO_HEX
 mov AX,seg ROUT
 mov ES,AX
 mov BP,offset CALL_COUNT_STR
 mov CX, 36
 call outputBP
 pop DX
 call setCurs

 POP DI
 POP BP
 POP ES
 POP DS
 POP BX
 POP CX 
 POP AX

 mov AX, KEEP_SS
 mov SS, AX
 mov SP, KEEP_SP
 MOV AL, 20H
 OUT 20H,AL
 IRET
 KEEP_CS dw 0
 KEEP_IP dw 0
 KEEP_SS dw 0
 KEEP_SP dw 0             
 COUNT dw 0
 CALL_COUNT_STR db 'Количество вызовов прерывания:     $'
ROUT ENDP     

TETR_TO_HEX PROC near       
 and AL,0Fh
 cmp AL,09
 jbe NEXT
 add AL,07
NEXT: add AL,30h
 ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near 
 push CX
 mov AH,AL
 call TETR_TO_HEX
 xchg AL,AH
 mov CL,4
 shr AL,CL
 call TETR_TO_HEX 
 pop CX 
 ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
 push BX
 mov BH,AH
 call BYTE_TO_HEX
 mov [DI],AH
 dec DI
 mov [DI],AL
 dec DI
 mov AL,BH
 call BYTE_TO_HEX
 mov [DI],AH
 dec DI
 mov [DI],AL
 pop BX
 ret
WRD_TO_HEX ENDP

outputBP proc
 mov AH,13h
 mov AL,0
 mov BH,0
 int 10h
 ret
outputBP endp
	
setCurs proc
 mov ah,02h
 mov bh,0
 int 10h
 ret
setCurs endp

getCurs PROC
 mov ah,03h
 mov bh,0
 int 10h
 ret 
getCurs endp

resident_end:

PRINT_STR PROC near
 push AX
 mov AH, 09h
 int 21h
 pop AX
 ret
PRINT_STR ENDP

IS_LOADED PROC near
 mov AH, 35h
 mov AL, 1Ch
 int 21h
 add BX, offset CALL_COUNT_STR
 mov SI, BX
 mov DI, offset CALL_COUNT_STR
 mov CX, 32
 call STR_COMPARE
 cmp CX, 0
 je loaded
 CLC
 jmp check_end
 loaded:
 STC
 check_end:
 ret
IS_LOADED ENDP
 
UNLOAD PROC near
 cli
 mov AH, 35h
 mov AL, 1Ch
 int 21h
 add BX, offset KEEP_CS
 mov AX, ES:[BX]
 mov DX, ES:[BX+2]
 push DS
 mov DS, AX
 mov AH, 25h
 mov AL, 1Ch
 int 21h
 pop DS
 mov BX, seg ROUT
 mov DX, STACK
 sub DX, BX
 mov AX, ES
 add AX, DX
 sub AX, 10h
 mov ES, AX
 mov AX, ES:[2Ch]
 push ES
 mov ES, AX
 mov AH, 49h
 int 21h
 pop ES
 mov AH, 49h
 int 21h
 sti
 ret
UNLOAD ENDP

IS_UNLOAD_TAIL PROC near
 mov AL, ES:[80h]
 cmp AL, 4
 jne loading
 mov DI, offset UNLOAD_TAIL
 mov SI, 81h
 mov CX, 4
 call STR_COMPARE
 jg loading
 STC
 ret
 loading:
  CLC
  ret
IS_UNLOAD_TAIL ENDP
 
STR_COMPARE PROC near
  mov AL, ES:[SI]
  mov AH, DS:[DI]
  inc DI
  inc SI
  cmp AL, AH
 loope STR_COMPARE
 cmp CX, 0
 ret
STR_COMPARE ENDP

LOAD PROC near
 push DS
 mov DX, offset ROUT
 mov AX, SEG ROUT
 mov DS, AX
 mov AH, 25h
 mov AL, 1Ch
 int 21h
 pop DS     
 mov DX, offset JUST_LOADED
 call PRINT_STR
 mov DX, offset resident_end
 mov CL, 4
 shr DX, CL
 add DX, 20h
 mov AH, 31h
 int 21h
LOAD ENDP

UNLOAD_TAIL db ' /un$'
JUST_LOADED db 'Прерывание загружено', 0DH, 0AH, '$'
ALREADY_LOADED db 'Прерывание уже загружено', 0DH, 0AH, '$'
UNLOADED db 'Прерывание выгружено', 0DH, 0AH, '$' 
NOTHING_TO_UNLOAD db 'Нечего выгружать', 0DH, 0AH, '$'

Main PROC far
 push ES
 mov AX, CS
 mov DS, AX

 mov AX, CODE
 mov DS, AX
 mov AH, 35h
 mov AL, 1Ch
 int 21h
 mov KEEP_IP, BX
 mov KEEP_CS, ES
 call IS_LOADED
 jnc not_loaded
 pop ES
 call IS_UNLOAD_TAIL
 jc unloading
 mov DX, offset ALREADY_LOADED
 call PRINT_STR
 jmp main_end

 unloading:
  call UNLOAD
  mov DX, offset UNLOADED
  call PRINT_STR
  jmp main_end

 not_loaded:
  pop ES
  call IS_UNLOAD_TAIL
  jc unload_not_loaded
  call LOAD

 unload_not_loaded:
 mov DX, offset NOTHING_TO_UNLOAD
 call PRINT_STR 

 main_end:
 xor AL,AL
 mov AH,4Ch
 int 21H
 ret
Main ENDP

CODE ENDS
END MAIN