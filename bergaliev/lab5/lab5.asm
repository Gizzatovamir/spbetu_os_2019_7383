STACK SEGMENT STACK
 DW 10h DUP(?)
STACK ENDS

CODE SEGMENT
 ASSUME CS:CODE, DS:CODE, SS:STACK

ROUT PROC FAR
 mov KEEP_AX, AX
 mov KEEP_SS, SS
 mov KEEP_SP, SP
 mov AX, STACK
 mov SS, AX
 mov SP, 20h
 mov AX, KEEP_AX
 push AX
 push BX
 push CX
 in AL, 60h
 cmp AL, 3Bh
 je process_sym
 mov BX, offset KEEP_IP
 pushf
 call dword ptr CS:[BX]
 jmp int_end

 process_sym:
 push AX
 in AL, 61h
 mov AH, AL
 or AL, 80h
 out 61h, AL
 mov AL, AH
 out 61h, AL
 mov AL, 20H
 out 20H,AL
 pop AX

 mov CL, 'H'
 call ADD_SYM
 mov CL, 'e'
 call ADD_SYM
 mov CL, 'l'
 call ADD_SYM
 mov CL, 'l'
 call ADD_SYM
 mov CL, 'o'
 call ADD_SYM
 int_end:
 pop CX
 pop BX
 pop AX
 mov AX, KEEP_SS
 mov SS, AX
 mov SP, KEEP_SP
 mov AL, 20H
 out 20H,AL
 mov AX, KEEP_AX
 IRET
 KEEP_IP dw 0
 KEEP_CS dw 0
 KEEP_SS dw 0
 KEEP_SP dw 0
 KEEP_AX dw 0
 ID db 'BONJOUR!$'             
ROUT ENDP

ADD_SYM PROC near
 mov AH, 05h
 mov CH, 00h
 int 16h
 or AL, AL
 jz add_sym_end
 mov AX, ES:[1Ah]
 mov ES:[1Ch], AX
 jmp add_sym
 add_sym_end:
  ret
ADD_SYM ENDP     

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
 mov AL, 09h
 int 21h
 add BX, offset ID
 mov SI, BX
 mov DI, offset ID
 mov CX, 9
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
 mov AL, 09h
 int 21h
 add BX, offset KEEP_IP
 mov DX, ES:[BX]
 mov AX, ES:[BX+2]
 push DS
 mov DS, AX
 mov AH, 25h
 mov AL, 09h
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
 mov AL, 09h
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
 mov AL, 09h
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