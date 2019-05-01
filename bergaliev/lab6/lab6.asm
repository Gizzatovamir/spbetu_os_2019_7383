STACK SEGMENT STACK
 dw 10h DUP(?)
STACK ENDS

DATA SEGMENT
ERROR_1 db 'Номер функции неверен', 0DH, 0AH, '$'
ERROR_2 db 'Файл не найден', 0DH, 0AH, '$'
ERROR_5 db 'Ошибка диска', 0DH, 0AH, '$'
ERROR_7 db 'Разрушен управляющий блок памяти', 0DH, 0AH, '$'
ERROR_8 db 'Недостаточный объем памяти', 0DH, 0AH, '$'
ERROR_9 db 'Неверный адрес блока памяти', 0DH, 0AH, '$'
ERROR_10 db 'Неправильная строка среды', 0DH, 0AH, '$'
ERROR_11 db 'Неверный формат', 0DH, 0AH, '$'
END_0 db 'Программа завершилась нормально', 0DH, 0AH, '$'
END_1 db 'Программа завершилась по Ctrl-Break', 0DH, 0AH, '$'
END_2 db 'Программа завершилась по ошибке устройства', 0DH, 0AH, '$'
END_3 db 'Программа завершилась по функции 31h, оставляющей программу резидентной', 0DH, 0AH, '$'
END_CODE db 'Код завершения:   $'

KEEP_SS dw ?
KEEP_SP dw ?
MODULE_NAME db 'LAB2.COM', 0
PATH db '                   $'
ENV_ADDR dw 0
COMM_LINE dd ?
FIRST_FCB dd ?
SECOND_FCB dd ?
DATA ENDS

CODE SEGMENT 
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
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
 mov [DI],AH
 dec DI
 mov [DI],AL 
 pop CX 
 ret
BYTE_TO_HEX ENDP

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

PRINT_ERROR PROC near
 cmp AX, 1
 jne error2
 mov DX, offset ERROR_1
 jmp end_print_error
 error2:
 cmp AX, 2
 jne error5
 mov DX, offset ERROR_2
 jmp end_print_error
 error5:
 cmp AX, 5
 jne error7
 mov DX, offset ERROR_5
 jmp end_print_error
 error7:
 cmp AX, 7
 jne error8
 mov DX, offset ERROR_7
 jmp end_print_error
 error8:
 cmp AX, 8
 jne error9
 mov DX, offset ERROR_8
 jmp end_print_error
 error9:
 cmp AX, 9
 jne error10
 mov DX, offset ERROR_9
 jmp end_print_error
 error10:
 cmp AX, 10
 jne error11
 mov DX, offset ERROR_10
 jmp end_print_error
 error11:
 mov DX, offset ERROR_11
 end_print_error:
 call PRINT_STR
 ret
PRINT_ERROR ENDP

PREP_PARAMS PROC near
 mov AH, 4AH
 mov BX, offset PR_END
 add BX, 100h
 int 21h
 
 jnc param_block
 call PRINT_ERROR
 mov AH, 4Ch
 int 21h

 param_block:
 mov AX, ES
 mov ENV_ADDR+2, AX
 mov ENV_ADDR+4, 80h
 mov ENV_ADDR+6, AX
 mov ENV_ADDR+8, 5Ch
 mov ENV_ADDR+10, AX
 mov ENV_ADDR+12, 6Ch
 
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
 find_slash:
  dec DI
  mov AL, DS:[DI]
  cmp AL, '\'
 jne find_slash
 inc DI 
 mov AX, DS
 mov ES, AX
 mov SI, offset MODULE_NAME
 call COPY_STR
 mov DX, offset PATH
 mov BX, offset ENV_ADDR
 mov AX, SS
 mov KEEP_SS, AX  
 ret
PREP_PARAMS ENDP
  
MAIN PROC near
 mov AX, DATA
 mov DS, AX

 call PREP_PARAMS
 push DS
 push ES
 mov AX, SP
 mov KEEP_SP, AX
 mov AX, 4B00h
 int 21h
 mov BX, KEEP_SS
 mov SS, BX
 mov BX, KEEP_SP
 mov SP, BX
 pop ES
 pop DS

 jnc without_errors
 call PRINT_ERROR
 jmp end_main
 without_errors:
  mov AH, 4Dh
  int 21h
  cmp AH, 0
  jne end1
  mov DX, offset END_0
  call PRINT_STR
  mov DI, offset END_CODE
  add DI, 17
  call BYTE_TO_HEX
  mov DX, offset END_CODE
  call PRINT_STR
  jmp end_main
  end1:
  cmp AH, 1
  jne end2
  mov DX, offset END_1
  call PRINT_STR
  jmp end_main
  end2:
  cmp AH, 2
  jne end3
  mov DX, offset END_2
  call PRINT_STR
  jmp end_main
  end3:
  mov DX, offset END_3
  call PRINT_STR  
 end_main:
 xor AL,AL
 mov AH,4Ch
 int 21H
MAIN ENDP
PR_END:
CODE ENDS
END MAIN