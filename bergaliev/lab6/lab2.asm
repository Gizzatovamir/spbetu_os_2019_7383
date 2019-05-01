TESTPSP SEGMENT
 ASSUME CS:TESTPSP, DS:TESTPSP, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN
INACCESSIBLE db 'Сегментный адрес недоступной памяти: $'
ENV_ADDR db 'Сегментный адрес среды: $'
COMLINE_TAIL db 'Хвост командной строки: "$'
ENDLINE db 0DH, 0AH, '$'
NUM db '    ',0DH,0AH,'$'
ENV_CONTAIN db 'Содержимое области среды:',0DH,0AH,'$'
MODULE_PATH db 'Путь загруженного модуля: $'

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

PRINT_STR PROC near
 push AX
 mov AH, 09h
 int 21h
 pop AX
 ret
PRINT_STR ENDP

COMLINE_TAIL_PRINT PROC near
 xor CX, CX
 mov CL, ES:[80h]
 cmp CL, 0
 je empty_tail
 mov AH, 02h
 mov DI, 81h
 print_tail:
  mov DL, ES:[DI]
  inc DI
  int 21h
  loop print_tail
 empty_tail:
 mov DL, '"'
 mov AH, 02h
 int 21h
 mov DX, offset ENDLINE
 call PRINT_STR
 ret
COMLINE_TAIL_PRINT ENDP

ENV_PRINT PROC near
 push ES
 mov ES, DS:[2Ch]
 mov DI, 0
 mov AH, 02h
 print_env:
 mov DL, ES:[DI]
 cmp DL, 0
 je env_print_end
 print_entry:
  int 21h
  inc DI
  mov DL, ES:[DI]
  cmp DL, 0
  loopne print_entry
 inc DI
 mov DX, offset ENDLINE
 call PRINT_STR
 jmp print_env
 env_print_end:
 mov DX, offset MODULE_PATH
 call PRINT_STR
 add DI, 3
 print_path:
  mov DL, ES:[DI]
  int 21h
  inc DI
  cmp DL, 0
  loopne print_path
 mov DX, offset ENDLINE
 call PRINT_STR
 pop ES
 ret
ENV_PRINT ENDP
 
BEGIN:
 mov DX, offset INACCESSIBLE
 call PRINT_STR
 mov AX, DS:[02h]
 mov DI, offset NUM
 add DI, 3
 call WRD_TO_HEX
 mov DX, offset NUM
 call PRINT_STR
 
 mov DX, offset ENV_ADDR
 call PRINT_STR
 mov AX, DS:[2Ch]
 mov DI, offset NUM
 add DI, 3
 call WRD_TO_HEX
 mov DX, offset NUM
 call PRINT_STR
 
 mov DX, offset COMLINE_TAIL
 call PRINT_STR
 call COMLINE_TAIL_PRINT 

 mov DX, offset ENV_CONTAIN
 call PRINT_STR 
 call ENV_PRINT

 mov AH, 01h
 int 21h
 
 mov DX, offset ENDLINE
 call PRINT_STR
 
 mov AH,4Ch
 int 21H
TESTPSP ENDS
 END START