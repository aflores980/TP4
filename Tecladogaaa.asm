;===============================================================================
; DIRECTIVAS DE INCLUSIÓN Y CONFIGURACIÓN
;===============================================================================
LIST P=16F887			
#include "p16f887.inc"	
	
__CONFIG _CONFIG1, _XT_OSC & _WDTE_OFF & _MCLRE_ON & _LVP_OFF

;===============================================================================
; DEFINICIÓN DE CONSTANTES
;===============================================================================     
    #DEFINE    LED0        PORTD, 0
    #DEFINE    LED1        PORTD, 1
    #DEFINE    LED2        PORTD, 2
    #DEFINE    LED3        PORTD, 3
    #DEFINE    LED4        PORTD, 4
    #DEFINE    LED5        PORTD, 5
    #DEFINE    LED6        PORTD, 6
    #DEFINE    LED7        PORTD, 7
    
    #DEFINE    KEYPAD_ROW1 PORTB, 0
    #DEFINE    KEYPAD_ROW2 PORTB, 1
    #DEFINE    KEYPAD_ROW3 PORTB, 2
    #DEFINE    KEYPAD_ROW4 PORTB, 3
    #DEFINE    KEYPAD_COL1 PORTB, 4
    #DEFINE    KEYPAD_COL2 PORTB, 5
    #DEFINE    KEYPAD_COL3 PORTB, 6
    #DEFINE    KEYPAD_COL4 PORTB, 7

;===============================================================================
; DEFINICIÓN DE VARIABLES
;=============================================================================== 
    CBLOCK  0x20
        KEYPAD_NUMBER
    ENDC
    
    CBLOCK  0x70
        W_TEMP
        STATUS_TEMP
    ENDC

;===============================================================================
; DECLARACIÓN DE MACROS
;===============================================================================
CFG_LEDS MACRO
    BANKSEL ANSEL
    CLRF    ANSEL
    CLRF    ANSELH

    BANKSEL TRISD
    CLRF    TRISD

    BANKSEL PORTD
    CLRF    PORTD
ENDM

CFG_KEYPAD MACRO
    BANKSEL OPTION_REG
    BCF     OPTION_REG, NOT_RBPU ; <--- AGREGADO: Activa las resistencias pull-up globales del PORTB

    BANKSEL WPUB
    MOVLW   b'11110000'         ; <--- AGREGADO: Activa pull-ups internas en las columnas (RB4..RB7)
    MOVWF   WPUB

    BANKSEL TRISB
    MOVLW   b'11110000'         ; <--- MODIFICADO: (Antes 0xFF). RB0..RB3 Salidas (Filas), RB4..RB7 Entradas (Cols)
    MOVWF   TRISB

    BANKSEL PORTB
    MOVLW   b'11110000'         ; <--- MODIFICADO: Mantiene las filas en reposo alto (1) por defecto
    MOVWF   PORTB
ENDM

LEDS_OFF MACRO
    BANKSEL PORTD
    CLRF    PORTD
ENDM

CFG_ISR MACRO
    BANKSEL IOCB
    MOVLW   b'11110000'         ; <--- MODIFICADO: (Antes 0xFF). Interrupción por cambio SOLO en Columnas (RB4..RB7)
    MOVWF   IOCB
    
    BANKSEL PORTB
    MOVF    PORTB, W            ; <--- AGREGADO: Lectura requerida de PORTB para limpiar la condición 'Mismatch'

    BANKSEL INTCON
    BCF     INTCON, RBIF
    BSF     INTCON, RBIE
    BSF     INTCON, GIE
ENDM

;===============================================================================
; VECTORES DE INICIO E INTERRUPCIÓN
;=============================================================================== 
    ORG     0x00
    GOTO    INICIO

    ORG     0x04
    GOTO    ISR_INICIO

;===============================================================================
; PROGRAMA PRINCIPAL
;=============================================================================== 
INICIO
    CFG_LEDS
    CFG_KEYPAD
    CFG_ISR

MAIN_LOOP
    NOP
    GOTO    MAIN_LOOP

;===============================================================================
; RUTINA DE SERVICIO DE INTERRUPCIÓN (ISR)
;=============================================================================== 
ISR_INICIO
    MOVWF   W_TEMP
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP

    BTFSC   INTCON, RBIF
    GOTO    ISR_IOC
    GOTO    ISR_FIN

ISR_IOC
    CALL    KEY_READ
    CALL    TEST_KEYPAD
    BANKSEL PORTB
    MOVF    PORTB, W            ; <--- AGREGADO: Lectura previa requerida antes de limpiar el flag RBIF
    BCF     INTCON, RBIF
    GOTO    ISR_FIN

ISR_FIN
    SWAPF   STATUS_TEMP, W
    MOVWF   STATUS
    SWAPF   W_TEMP, F
    SWAPF   W_TEMP, W
    RETFIE

;===============================================================================
; SUBRUTINAS DE ESCANEO
;===============================================================================
KEY_READ
    CLRF    KEYPAD_NUMBER
    INCF    KEYPAD_NUMBER, F    ; KEYPAD_NUMBER = 1
    GOTO    ACTIVE_ROW1

ACTIVE_ROW1
    BANKSEL PORTB               ; <--- AGREGADO: Garantiza la seleccion de banco correcta
    BCF     KEYPAD_ROW1
    BSF     KEYPAD_ROW2
    BSF     KEYPAD_ROW3
    BSF     KEYPAD_ROW4
    GOTO    SCANN_COLS

ACTIVE_ROW2
    BANKSEL PORTB               ; <--- AGREGADO: Garantiza la seleccion de banco correcta
    BSF     KEYPAD_ROW1
    BCF     KEYPAD_ROW2
    BSF     KEYPAD_ROW3
    BSF     KEYPAD_ROW4
    GOTO    SCANN_COLS

ACTIVE_ROW3
    BANKSEL PORTB               ; <--- AGREGADO: Garantiza la seleccion de banco correcta
    BSF     KEYPAD_ROW1
    BSF     KEYPAD_ROW2
    BCF     KEYPAD_ROW3
    BSF     KEYPAD_ROW4
    GOTO    SCANN_COLS

ACTIVE_ROW4
    BANKSEL PORTB               ; <--- AGREGADO: Garantiza la seleccion de banco correcta
    BSF     KEYPAD_ROW1
    BSF     KEYPAD_ROW2
    BSF     KEYPAD_ROW3
    BCF     KEYPAD_ROW4
    GOTO    SCANN_COLS

SCANN_COLS
    BANKSEL PORTB               ; <--- AGREGADO: Garantiza la seleccion de banco correcta
    BTFSS   KEYPAD_COL1         ; Columna 1 presionada (0)?
    GOTO    KEY_FOUND           ; <--- MODIFICADO: Salta inmediatamente a detener el escaneo
    INCF    KEYPAD_NUMBER, F    ; <--- MODIFICADO: Solo incrementa si la columna NO estaba presionada

    BTFSS   KEYPAD_COL2         ; Columna 2 presionada (0)?
    GOTO    KEY_FOUND           ; <--- MODIFICADO: Salta inmediatamente a detener el escaneo
    INCF    KEYPAD_NUMBER, F    ; <--- MODIFICADO: Solo incrementa si la columna NO estaba presionada

    BTFSS   KEYPAD_COL3         ;Columna  3 presionada (0)?
    GOTO    KEY_FOUND           ; <--- MODIFICADO: Salta inmediatamente a detener el escaneo
    INCF    KEYPAD_NUMBER, F    ; <--- MODIFICADO: Solo incrementa si la columna NO estaba presionada

    BTFSS   KEYPAD_COL4         ; Columna  4 presionada (0)?
    GOTO    KEY_FOUND           ; <--- MODIFICADO: Salta inmediatamente a detener el escaneo
    INCF    KEYPAD_NUMBER, F    ; <--- MODIFICADO: Solo incrementa si la columna NO estaba presionada

    GOTO    SCANN_ROWS          ; Si no hubo pulsacion en esta fila, pasa a activar la siguiente fila

WAIT_RELEASE
LOOP_COL1
    BTFSS   KEYPAD_COL1
    GOTO    LOOP_COL1
LOOP_COL2
    BTFSS   KEYPAD_COL2
    GOTO    LOOP_COL2
LOOP_COL3
    BTFSS   KEYPAD_COL3
    GOTO    LOOP_COL3
LOOP_COL4
    BTFSS   KEYPAD_COL4
    GOTO    LOOP_COL4

    ; Restablece filas tras soltar la tecla
    BANKSEL PORTB
    BCF     KEYPAD_ROW1
    BCF     KEYPAD_ROW2
    BCF     KEYPAD_ROW3
    BCF     KEYPAD_ROW4
    RETURN

SCANN_ROWS
    BANKSEL PORTB               ; <--- AGREGADO: Garantiza la selección de banco correcta
    BTFSS   KEYPAD_ROW1         ; Si la Fila 1 era la activa (0)
    GOTO    ACTIVE_ROW2
    BTFSS   KEYPAD_ROW2         ; Si la Fila 2 era la activa (0)
    GOTO    ACTIVE_ROW3
    BTFSS   KEYPAD_ROW3         ; Si la Fila 3 era la activa (0)
    GOTO    ACTIVE_ROW4
    GOTO    RST_KEYPAD

RST_KEYPAD
    CLRF    KEYPAD_NUMBER
    BANKSEL PORTB
    BCF     KEYPAD_ROW1
    BCF     KEYPAD_ROW2
    BCF     KEYPAD_ROW3
    BCF     KEYPAD_ROW4
    RETURN

TEST_KEYPAD
    LEDS_OFF
    ; --- BLOQUE AGREGADO PARA EVITAR DESBORDAMIENTO EN LA TABLA ---
    MOVF    KEYPAD_NUMBER, W    ; <--- AGREGADO: Carga la tecla leída a W
    SUBLW   d'8'                ; <--- AGREGADO: Resta (8 - KEYPAD_NUMBER)
    BTFSS   STATUS, C           ; <--- AGREGADO: Si C=0, KEYPAD_NUMBER es mayor a 8 (filas 3 y 4)
    RETURN                      ; <--- AGREGADO: Sale sin consultar la tabla para no corromper la memoria

    MOVF    KEYPAD_NUMBER, W
    CALL    TABLE_DECO_LEDS
    BANKSEL PORTD
    MOVWF   PORTD
    RETURN

;===============================================================================
; TABLA DE DECODIFICACIÓN
;===============================================================================
TABLE_DECO_LEDS
    ADDWF   PCL, F              ; <--- MODIFICADO: Especifica destino F explícito (PCL)
    RETLW   b'00000000'         ; Caso 0: Sin tecla
    RETLW   b'00000001'         ; Tecla 1  (1,1) -> LED0
    RETLW   b'00000010'         ; Tecla 2  (1,2) -> LED1
    RETLW   b'00000100'         ; Tecla 3  (1,3) -> LED2
    RETLW   b'00001000'         ; Tecla 4  (1,4) -> LED3
    RETLW   b'00010000'         ; Tecla 5  (2,1) -> LED4
    RETLW   b'00100000'         ; Tecla 6  (2,2) -> LED5
    RETLW   b'01000000'         ; Tecla 7  (2,3) -> LED6
    RETLW   b'10000000'         ; Tecla 8  (2,4) -> LED7

END
