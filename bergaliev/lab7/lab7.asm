STACK SEGMENT STACK
 dw 10h DUP(?)
STACK ENDS

DATA SEGMENT
ERROR_1 db 'Номер функции неверен', 0DH, 0AH, '$'
ERROR_2 db 'Файл не найден', 0DH, 0AH, '$'
ERROR_3 db 'Маршрут не найден', 0DH, 0AH, '$'
ERROR_4 db 'Слишком много открытых файлов', 0DH, 0AH, '$'
ERROR_5 db 'Нет доступа', 0DH, 0AH, '$'                     
ERROR_8 db 'Недостаточный объем памяти', 0DH, 0AH, '$'
ERROR_9 db 'Неверный адрес блока памяти', 0DH, 0AH, '$'
ERROR_10 db 'Неправильная строка среды', 0DH, 0AH, '$'

DTA db 2Bh DUP(?)
OVERLAY_MODULE1 db 'OVERLAY1.OVL', 0
OVERLAY_MODULE2 db 'OVERLAY2.OVL', 0
PATH db '                   ', 0
OVERLAY_ADDR dw 2h DUP(0)
DATA ENDS

CODE SEGMENT 
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK

PRINT_STR PROC near
 push AX
 mov AH, 09h
 int 21h
 pop AX
 ret
PRINT_STR ENDP

COPY_STR PROC near
 mov AL, ES:[SI]
 mov DS:[DI], AL
 inc SI
 inc DI
 cmp AL, 0
 jne COPY_STR
 ret
COPY_STR ENDP

CHECK_ERROR PROC near
 jnc check_error_end
 cmp AX, 1
 jne error2
 mov DX, offset ERROR_1
 jmp print_error
 error2:
 cmp AX, 2
 jne error3
 mov DX, offset ERROR_2
 jmp print_error
 error3:
 cmp AX, 3
 jne error4
 mov DX, offset ERROR_3
 jmp print_error
 error4:
 cmp AX, 4
 jne error5
 mov DX, offset ERROR_4
 jmp print_error
 error5:
 cmp AX, 5
 jne error8
 mov DX, offset ERROR_5
 jmp print_error
 error8:
 cmp AX, 8
 jne error10
 mov DX, offset ERROR_8
 jmp print_error
 error10:
 cmp AX, 10
 jne error18
 mov DX, offset ERROR_10
 jmp print_error
 error18:
 mov DX, offset ERROR_2
 print_error:
 mov AX, DATA
 mov DS, AX
 call PRINT_STR
 xor AL, AL
 mov AH, 4Ch
 int 21h
 check_error_end:
 ret
CHECK_ERROR ENDP

PREP PROC near
 mov AH, 4AH
 mov BX, offset PR_END
 add BX, 10h
 int 21h
 
 call CHECK_ERROR

 set_DTA_addr:
 mov AH, 1Ah
 mov DX, offset DTA
 int 21h
 
 call CHECK_ERROR

 mov AX, ES:[2Ch]
 mov ES, AX
 mov SI, 0 
 find_path:
  mov AL, ES:[SI]
  inc SI
  cmp AL, 0
  jne find_path
  mov AL, ES:[SI]
  inc SI
  cmp AL, 0
  jne find_path
 add SI, 2
 mov DI, offset PATH
 call COPY_STR
 ret
PREP ENDP

SET_FILENAME PROC near
 mov DI, offset PATH
 find_zero:
  mov AL, DS:[DI]
  inc DI
  cmp AL, 0
 jne find_zero
 dec DI
 find_slash:
  dec DI
  mov AL, DS:[DI]
  cmp AL, '\'
 jne find_slash
 inc DI 
 call COPY_STR
 ret
SET_FILENAME ENDP

ALLOC_MEM PROC near
 mov DX, offset PATH
 mov AH, 4Eh
 mov CX, 0
 int 21h
 call CHECK_ERROR
 
 mov BX, offset DTA
 mov AX, DS:[BX+1Ah]
 mov DX, DS:[BX+1Ch]
 mov BX, 16
 div BX
 inc AX

 mov BX, AX
 mov AH, 48h
 int 21h
 call CHECK_ERROR
 mov OVERLAY_ADDR+2, AX  
 ret
ALLOC_MEM ENDP

LOAD_AND_RUN PROC near
 push DS
 push ES
 mov AX, SEG OVERLAY_ADDR+2
 mov ES, AX
 mov BX, offset OVERLAY_ADDR+2
 mov AX, SEG PATH
 mov DS, AX
 mov DX, offset PATH
 mov AX, 4B03h
 int 21h
 call CHECK_ERROR
 call dword ptr OVERLAY_ADDR
 pop ES
 pop DS
 ret
LOAD_AND_RUN ENDP

SET_AND_EXEC PROC near
 mov AX, DATA
 mov ES, AX
 call SET_FILENAME
 
 call ALLOC_MEM
 call LOAD_AND_RUN
 mov AX, OVERLAY_ADDR+2
 mov ES, AX
 mov AH, 49h
 int 21h
 call CHECK_ERROR
 ret
SET_AND_EXEC ENDP
  
MAIN PROC near
 mov AX, DATA
 mov DS, AX

 call PREP

 mov SI, offset OVERLAY_MODULE1
 call SET_AND_EXEC
 mov SI, offset OVERLAY_MODULE2
 call SET_AND_EXEC

 xor AL,AL
 mov AH,4Ch
 int 21H
MAIN ENDP
PR_END:
CODE ENDS
END MAIN