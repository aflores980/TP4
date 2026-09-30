;===============================================================================
; @file       Gx_TPL4_ED2.asm
;
; @author URZAGASTI_SANTIAGO
;	      Apellido_Nombre
;	      Apellido_Nombre
;
; @date       dia/mes/año
;
; @version    1.0
;===============================================================================

;===============================================================================
; DIRECTIVAS DE INCLUSIÓN
;===============================================================================
LIST P=16F887			
#include "p16f887.inc"	
	
;===============================================================================
; CONFIGURACIÓN GENERAL DEL MCU
;=============================================================================== 	
__CONFIG _CONFIG1, _XT_OSC & _WDTE_OFF & _MCLRE_ON & _LVP_OFF

;===============================================================================
; DEFINICIÓN DE CONSTANTES
;===============================================================================     
    #DEFINE	    LED0    PORTD, 0
    #DEFINE	    LED1    PORTD, 1
    #DEFINE	    LED2    PORTD, 2
    #DEFINE	    LED3    PORTD, 3
    #DEFINE	    LED4    PORTD, 4
    #DEFINE	    LED5    PORTD, 5
    #DEFINE	    LED6    PORTD, 6
    #DEFINE	    LED7    PORTD, 7
    
    #DEFINE	    KEYPAD_ROW1	    PORTB, 0
    #DEFINE	    KEYPAD_ROW2	    PORTB, 1
    #DEFINE	    KEYPAD_ROW3	    PORTB, 2
    #DEFINE	    KEYPAD_ROW4	    PORTB, 3
    #DEFINE	    KEYPAD_COL1	    PORTB, 4
    #DEFINE	    KEYPAD_COL2	    PORTB, 5
    #DEFINE	    KEYPAD_COL3	    PORTB, 6
    #DEFINE	    KEYPAD_COL4	    PORTB, 7
;===============================================================================
; DEFINICIÓN DE VARIABLES
;=============================================================================== 
    
    ;Direcciones del banco 1
    CBLOCK  0X20
	KEYPAD_NUMBER
    ENDC
    
    ;Direcciones en memoria compartida
    CBLOCK  0X70
	W_TEMP
	STATUS_TEMP
    ENDC
    
;===============================================================================
; DECLARACIÓN DE MACROS PARA CONFIGURACIÓN DE REGISTROS
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
    BANKSEL TRISB
    MOVLW   0XFF
    MOVWF   TRISB

    BANKSEL PORTB
    MOVLW   0XFF
    MOVWF   PORTB
ENDM

LEDS_OFF MACRO
    BANKSEL PORTD
    CLRF    PORTD
ENDM

CFG_ISR MACRO
    BANKSEL IOCB
    MOVLW   0xFF
    MOVWF   IOCB
    
    BANKSEL INTCON
    BCF	    INTCON,RBIF
    BSF	    INTCON,RBIE
    BSF	    INTCON,GIE
ENDM
	
;===============================================================================
; INICIALIZACIÓN DEL MCU (CÓDIGO ABSOLUTO)
;===============================================================================    
    
    ORG     0x00	    ;Vector de Reset
    GOTO    INICIO	    ;Salto al inicio del programa principal
    ORG     0x04	    ;Vector de Interrupción
    GOTO    ISR_INICIO	    ;Salto al Rutina de Servicio de Interrupción
    ORG     0x05	    ;Ubicación Programa Principal en la memoria 
			    ;de programa
		
;===============================================================================
; INICIALIZACIÓN DE MACROS PARA CONFIGURACIÓN DE REGISTROS
;===============================================================================    	    
INICIO	    ;-----Inicialización de Macros-------
    CFG_LEDS
    CFG_KEYPAD
    CFG_ISR
		
;===============================================================================
; INICIO PROGRAMA PRINCIPAL
;===============================================================================						
MAIN_LOOP
    ;...
    GOTO    MAIN_LOOP	

;===============================================================================
; INICIALIZACIÓN DE RUTINAS DE SERVICIO DE INTERRUPCIÓN
;===============================================================================		    
ISR_INICIO		
    ;--------Guardado de Contexto--------
    MOVWF   W_TEMP
    SWAPF   STATUS, 0
    MOVWF   STATUS_TEMP
    ;------------------------------------
    ;---Identificación de Interrupción---
    BTFSC   INTCON,RBIF
    GOTO    ISR_IOC
    GOTO    ISR_FIN
    ;------------------------------------	
		
;===============================================================================
; FINALIZACIÓN DE RUTINAS DE SERVICIO DE INTERRUPCIÓN
;===============================================================================		    
ISR_FIN			    
    ;--------Restauración de Contexto--------        
    SWAPF   STATUS_TEMP, 0
    MOVWF   STATUS
    SWAPF   W_TEMP, 1
    SWAPF   W_TEMP, 0
    RETFIE
    ;---------------------------------------- 	  
	
;===============================================================================
; SUBRUTINAS
;===============================================================================
;*******************************************************************************
; @brief    Descripción general de la subrutina.
;           
; @details  Descripción específica de la subrutina.
;******************************************************************************* 
SUBROUTINE
ACTIVE_ROW1
    BCF     KEYPAD_ROW1
    BSF	    KEYPAD_ROW2
    BSF	    KEYPAD_ROW3
    BSF	    KEYPAD_ROW4
    GOTO    SCANN_COLS
    
ACTIVE_ROW2
    BSF     KEYPAD_ROW1
    BCF	    KEYPAD_ROW2
    BSF	    KEYPAD_ROW3
    BSF	    KEYPAD_ROW4
    GOTO    SCANN_COLS
    
ACTIVE_ROW3
    BSF     KEYPAD_ROW1
    BSF	    KEYPAD_ROW2
    BCF	    KEYPAD_ROW3
    BSF	    KEYPAD_ROW4
    GOTO    SCANN_COLS
    
ACTIVE_ROW4
    BSF     KEYPAD_ROW1
    BSF	    KEYPAD_ROW2
    BSF	    KEYPAD_ROW3
    BCF	    KEYPAD_ROW4
    GOTO    SCANN_COLS
    
ISR_IOC
    CALL    KEY_READ
    CALL    TEST_KEYPAD
    BCF	    INTCON,RBIF
    GOTO    ISR_FIN

KEY_READ
    CLRF    KEYPAD_NUMBER
    INCF    KEYPAD_NUMBER
    GOTO    ACTIVE_ROW1

TEST_KEYPAD
    LEDS_OFF
    MOVF    KEYPAD_NUMBER, 0
    CALL    TABLE_DECO_LEDS
    MOVWF   PORTD
RETURN

SCANN_COLS
    BTFSS   KEYPAD_COL1	    ;ESCANEO COLUMNA 1
    CALL    WAIT_RELEASE
    INCF    KEYPAD_NUMBER, 1
    BTFSS   KEYPAD_COL2	    ;ESCANEO COLUMNA 2
    CALL    WAIT_RELEASE
    INCF    KEYPAD_NUMBER, 1
    BTFSS   KEYPAD_COL3	    ;ESCANEO COLUMNA 3
    CALL    WAIT_RELEASE
    INCF    KEYPAD_NUMBER, 1
    BTFSS   KEYPAD_COL4	    ;ESCANEO COLUMNA 4
    CALL    WAIT_RELEASE
    INCF    KEYPAD_NUMBER, 1
    CALL    SCANN_ROWS	    ;PASA A ESCANEAR FILAS CUANDO TERMINA
RETURN

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
    BCF	    KEYPAD_ROW1
    BCF	    KEYPAD_ROW2
    BCF	    KEYPAD_ROW3
    BCF	    KEYPAD_ROW4
RETURN
    
SCANN_ROWS
    ;SCANN_ROW1
    BTFSS   KEYPAD_ROW1
    GOTO    ACTIVE_ROW2
    ;SCANN_ROW2
    BTFSS   KEYPAD_ROW2
    GOTO    ACTIVE_ROW3
    ;SCANN_ROW3
    BTFSS   KEYPAD_ROW3
    GOTO    ACTIVE_ROW4
    GOTO    RST_KEYPAD
RETURN
    
RST_KEYPAD
    CLRF    KEYPAD_NUMBER
    BCF	    KEYPAD_ROW1
    BCF	    KEYPAD_ROW2
    BCF	    KEYPAD_ROW3
    BCF	    KEYPAD_ROW4
RETURN

;===============================================================================		
;	    TABLAS
;===============================================================================
TABLE_DECO_LEDS
    ADDWF   PCL, 1
    RETLW   b'00000000' ;caso base
    RETLW   b'00000001' ;LED0
    RETLW   b'00000010'	;LED1
    RETLW   b'00000100'	;LED2
    RETLW   b'00001000'	;LED3
    RETLW   b'00010000'	;LED4
    RETLW   b'00100000'	;LED5
    RETLW   b'01000000'	;LED6
    RETLW   b'10000000'	;LED7

;===============================================================================		
END
;===============================================================================