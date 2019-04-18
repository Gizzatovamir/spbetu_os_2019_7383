TESTMEM SEGMENT
 ASSUME CS:TESTPSP, DS:TESTPSP, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN
HEADERS db ' Адрес Владелец Размер  Имя',0DH,0AH,'$'
AVAILABLE_MEMORY db 'Количество доступной памяти: $'
EXTENDED_MEMORY db 'Размер расширенной памяти: $'
MCB_CHAIN db '  Блоки управления памятью', 0DH, 0AH, '$'
ENDLINE db 0DH, 0AH, '$'
NUM db '     h  $'
DEC_NUM db '        $'                    
MCB_NAME db '        $'
ERROR_STR db 'Произошла ошибка при выделении памяти. Номер ошибки:$'
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

WRD_TO_DEC PROC near
 push CX
 push DX
 mov CX,10
loop_bd: div CX
 or DL,30h
 mov [SI],DL
 dec SI
 xor DX,DX
 cmp AX,10
 jae loop_bd
 cmp AL,00h
 je end_l
 or AL,30h
 mov [SI],AL
end_l: pop DX
 pop CX
 ret
WRD_TO_DEC ENDP

PRINT_STR PROC near
 push AX
 mov AH, 09h
 int 21h
 pop AX
 ret
PRINT_STR ENDP

MCB_PRINT PROC near
 mov DX, offset MCB_CHAIN
 call PRINT_STR
 mov AH, 52h
 int 21h
 mov ES, ES:[BX-2]
 mov DX, offset HEADERS
 call PRINT_STR
 mov DI, offset NUM
 add DI, 4
 next_mcb:
 mov AX, ES
 mov DX, offset NUM
 call WRD_TO_HEX
 call PRINT_STR
 mov AX, ES:[1]
 add DI, 3
 call WRD_TO_HEX
 call PRINT_STR
 add DI, 3
 mov AX, ES:[3]
 mov BX, 16
 mul BX
 mov SI, offset DEC_NUM
 add SI, 5
 call WRD_TO_DEC
 mov DX, offset DEC_NUM
 call PRINT_STR
 mov CX, 6
 mov SI, offset DEC_NUM
 mov BL, ' '
 mcb_clean:
  mov [SI], BL
  inc SI
  loop mcb_clean
 mov BX, 8
 mov CX, 8
 mov SI, offset MCB_NAME
 copy_name:
  mov AL, ES:[BX]
  mov [SI], AL
  inc SI
  inc BX
  loop copy_name
 mov DX, offset MCB_NAME
 call PRINT_STR
 mov DX, offset ENDLINE
 call PRINT_STR
 mov CL, ES:[0]
 mov AX, ES
 inc AX
 add AX, ES:[3]
 mov ES, AX
 cmp CL, 5Ah
 jne next_mcb
 ret
MCB_PRINT ENDP

AV_MEM_PRINT PROC near
 mov DX, offset AVAILABLE_MEMORY
 call PRINT_STR
 mov AH, 4Ah
 mov BX, 0FFFFh
 int 21h
 mov AX, BX
 mov BX, 16
 mul BX
 mov SI, offset DEC_NUM
 add SI, 7
 mov BL, 'B'
 mov [SI], BL
 sub SI, 2
 call WRD_TO_DEC
 mov DX, offset DEC_NUM
 call PRINT_STR
 mov DX, offset ENDLINE
 call PRINT_STR
 mov SI, offset DEC_NUM
 mov CX, 8
 mov BL, ' '
 av_clean:
  mov [SI], BL
  inc SI
  loop av_clean
 ret
AV_MEM_PRINT ENDP

EXT_MEM_PRINT PROC near
 mov DX, offset EXTENDED_MEMORY
 call PRINT_STR
 mov AL,30h
 out 70h,AL
 in AL,71h
 mov BL,AL
 mov AL,31h
 out 70h,AL
 in AL,71h
 mov BH, AL
 mov AX, BX
 mov SI, offset DEC_NUM
 add SI, 7
 mov BL, 'B'
 mov [SI], BL
 dec SI
 mov BL, 'K'
 mov [SI], BL
 sub SI, 2
 mov DX, 0
 call WRD_TO_DEC
 mov DX, offset DEC_NUM
 call PRINT_STR
 mov DX, offset ENDLINE
 call PRINT_STR
 mov SI, offset DEC_NUM
 mov CX, 8
 mov BL, ' '
 ext_clean:          
  mov [SI], BL
  inc SI
  loop ext_clean
 ret
EXT_MEM_PRINT ENDP
  
BEGIN:
 call AV_MEM_PRINT
 call EXT_MEM_PRINT
 mov AH, 48H
 mov BX, 4096
 int 21h
 jnc no_error
 mov DX, offset ERROR_STR
 call PRINT_STR
 mov DI, offset NUM
 add DI, 4
 call WRD_TO_HEX
 mov DX, offset NUM
 call PRINT_STR
 mov DX, offset ENDLINE
 call PRINT_STR
 no_error:
 mov AH, 4AH
 mov BX, offset PR_END
 int 21h
 call MCB_PRINT
 xor AL,AL
 mov AH,4Ch
 int 21H
 PR_END:
TESTMEM ENDS
 END START
