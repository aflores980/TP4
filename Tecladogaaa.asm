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
    
    #DEFINE	    KEYPAD_ROW1	    PORTC, 0
    #DEFINE	    KEYPAD_ROW2	    PORTC, 1
    #DEFINE	    KEYPAD_ROW3	    PORTC, 2
    #DEFINE	    KEYPAD_ROW4	    PORTC, 3
    #DEFINE	    KEYPAD_COL1	    PORTC, 4
    #DEFINE	    KEYPAD_COL2	    PORTC, 5
    #DEFINE	    KEYPAD_COL3	    PORTC, 6
    #DEFINE	    KEYPAD_COL4	    PORTC, 7
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
	CLRF ANSEL
	CLRF ANSELH

	BANKSEL TRISD
	CLRF TRISD

	BANKSEL PORTD
	CLRF PORTD
ENDM

CFG_KEYPAD MACRO
	BANKSEL TRISB
	SETF TRISB

	BANKSEL PORTB
	SETF PORTB
ENDM

LEDS_OFF MACRO
	BANKSEL PORTD
	CLRF PORTD
ENDM

CFG_ISR
	
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
    BTFSC INTCON,RBIF
	GOTO ISR_IOC
	GOTO ISR_FIN
    ;------------------------------------	
		
;===============================================================================
; FINALIZACIÓN DE RUTINAS DE SERVICIO DE INTERRUPCIÓN
;===============================================================================		    
ISR_FIN			    
    ;--------Restauración de Contexto--------        
    SWAPF   STATUS_TEMP, 0
    MOVWF   STATUS
    MOVWF   W_TEMP
	GOTO MAIN_LOOP
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

ISR_IOC
	CALL KEY_READ
	CALL TEST_KEYPAD
	BCF INTCON,RBIF
	GOTO ISR_FIN

KEY_READ
	CLRF KEYPAD_NUMBER
	INCF KEYPAD_NUMBER
	GOTO ACTIVE_ROW1

TEST_KEYPAD
	MOVFW KEYPAD_NUMBER
	CALL TABLE_DECO_LEDS
	MOVWF PORTD
	RETURN
;===============================================================================		
    END
;===============================================================================
;asdakfajksd