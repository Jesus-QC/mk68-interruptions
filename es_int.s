* ARQUITECTURA DE COMPUTADORES
* 2025-2026
* PROYECTO E/S
* JESUS QUIROGA CAMPOS

* Constantes para programa principal
        ORG     $0
        DC.L    $8000           * Pila
        DC.L    INICIO          * PC

* Registros de DUART
MR1A    EQU     $EFFC01
MR2A    EQU     $EFFC01
SRA     EQU     $EFFC03
CSRA    EQU     $EFFC03
CRA     EQU     $EFFC05
RBA     EQU     $EFFC07
TBA     EQU     $EFFC07

MR1B    EQU     $EFFC11
MR2B    EQU     $EFFC11
SRB     EQU     $EFFC13
CSRB    EQU     $EFFC13
CRB     EQU     $EFFC15
RBB     EQU     $EFFC17
TBB     EQU     $EFFC17

ACR     EQU     $EFFC09
ISR     EQU     $EFFC0B
IMR     EQU     $EFFC0B
IVR     EQU     $EFFC19

* Offset para código
        ORG     $400

* El IMR no se puede leer, por lo tanto guardamos una copia
* 2200 = 22 máscara de interrupciones, 00 relleno para alinear a palabra 
IMR_COPY:   DC.W  $2200

* Configura DUART
INIT:
        * Guardamos registro por si acaso
        MOVE.L  A0,-(A7)

        * Reiniciamos punteros
        MOVE.B  #%00010000,CRA
        MOVE.B  #%00010000,CRB
        
        * 8 bits por carácter
        MOVE.B  #%00000011,MR1A
        MOVE.B  #%00000011,MR1B

        * Modo normal con eco automático desactivado
        MOVE.B  #%00000000,MR2A
        MOVE.B  #%00000000,MR2B
        
        * Velocidades de conjunto 2
        MOVE.B  #%10000000,ACR

        * 38400 baudios para recepción y para transmisión
        MOVE.B  #%11001100,CSRA
        MOVE.B  #%11001100,CSRB
        
        * Interrupciones de nivel 4
        MOVE.B  #64,IVR

        * Activamos interrupciones de recepción
        MOVE.B  #%00100010,IMR

        * Habilitamos transmisión y recepción
        MOVE.B  #%00000101,CRA
        MOVE.B  #%00000101,CRB

        * Guardamos RTI para rutina de interrupciones
        MOVE.L  #RTI,$0100

        BSR     INI_BUFS

        * Recuperamos registro
        MOVE.L  (A7)+,A0
        RTS

PRINT:
        * Guardamos pila
        LINK    A6,#0
        MOVE.L  D2,-(A7)
        MOVE.L  D3,-(A7)
        MOVE.L  D4,-(A7)
        MOVE.L  A0,-(A7)
        
        * Buffer
        MOVE.L  8(A6),A0
        * Descriptor
        MOVE.W  12(A6),D3
        * Tamaño
        MOVE.W  14(A6),D2
        
        CMP.W   #0,D3
        BEQ     PRINT_A
        CMP.W   #1,D3
        BEQ     PRINT_B
        
        * Error, descriptor no es 0 o 1
        MOVE.L  #$FFFFFFFF,D0
        BRA     P_END

PRINT_A:
PRINT_B:
        * Traducimos a cola
        ADD.W   #2,D3
        * Contador carácteres escritos
        MOVE.L  #0,D4

P_LOOP:
        * Buffer vacio
        CMP.W   #0,D2
        BEQ     P_TRANS

        * Cola 
        MOVE.L  D3,D0
        
        * Metemos carácter en cola
        MOVE.L  #0,D1
        MOVE.B  (A0)+,D1
        BSR     ESCCAR
        
        * Cola llena
        CMP.L   #$FFFFFFFF,D0
        BEQ     P_TRANS

        * Incremento contador y restamos 1 a restantes
        ADD.L   #1,D4
        SUB.W   #1,D2

        BRA     P_LOOP

P_TRANS:
        * Si esta vacio salimos
        CMP.L   #0,D4
        BEQ     P_RESUL

        * Inhibimos interrupciones
        MOVE.W  SR,-(A7)
        MOVE.W  #$2700,SR

        MOVE.B  IMR_COPY,D1
        
        CMP.W   #2,D3
        * Linea A = Bit 0
        BNE     P_L_B
P_L_A:
        OR.B    #$01,D1
        BRA     P_REST
P_L_B:
        * Linea B = Bit 4
        OR.B    #$10,D1
P_REST:
        MOVE.B  D1,IMR_COPY
        MOVE.B  D1,IMR
        MOVE.W  (A7)+,SR

P_RESUL:
        * Metemos en D0 el contador
        MOVE.L  D4,D0

P_END:
        MOVE.L  (A7)+,A0
        MOVE.L  (A7)+,D4
        MOVE.L  (A7)+,D3
        MOVE.L  (A7)+,D2
        UNLK    A6
        RTS

SCAN:
        * Guardamos pila
        LINK    A6,#0
        MOVE.L  D2,-(A7)
        MOVE.L  D3,-(A7)
        MOVE.L  D4,-(A7)
        MOVE.L  A0,-(A7)

        * Buffer
        MOVE.L  8(A6),A0
        * Descriptor
        MOVE.W  12(A6),D3
        * Tamaño
        MOVE.W  14(A6),D2
        
        CMP.W   #0,D3
        BEQ     SCAN_A
        CMP.W   #1,D3
        BEQ     SCAN_B
        
        * Error, descriptor no es 0 o 1
        MOVE.L  #$FFFFFFFF,D0
        BRA     S_END

SCAN_A:
SCAN_B:
        * Contador de caracteres leidos
        MOVE.L  #0,D4

S_BUCLE:
        * Buffer vacio
        CMP.W   #0,D2
        BEQ     S_RESUL
        
        * Descriptor
        MOVE.L  D3,D0

        * Sacamos carácter de la cola
        BSR     LEECAR

        * Cola vacía
        CMP.L   #$FFFFFFFF,D0
        BEQ     S_RESUL

        * Guardamos carácter en buffer
        MOVE.B  D0,(A0)+

        * Incremento contador y restamos 1 a restantes
        ADD.L   #1,D4
        SUB.W   #1,D2

        BRA     S_BUCLE

S_RESUL:
        MOVE.L  D4,D0

S_END:
        MOVE.L  (A7)+,A0
        MOVE.L  (A7)+,D4
        MOVE.L  (A7)+,D3
        MOVE.L  (A7)+,D2
        UNLK    A6
        RTS

* Rutina de interrupción
RTI:
        * Guardamos pila
        MOVE.L  D0,-(A7)
        MOVE.L  D1,-(A7)
        MOVE.L  D2,-(A7)
        MOVE.L  A0,-(A7)
        * Leemos ISR en D2
        MOVE.B  ISR,D2

R_RXA:
        * No ha llegado caracter RxA
        BTST    #1,D2
        BEQ     R_TXA

        * Metemos en cola el caracter RxA
        MOVE.L  #0,D1
        MOVE.B  RBA,D1
        MOVE.L  #0,D0
        BSR     ESCCAR

R_TXA:
        * No ha llegado caracter TxA
        BTST    #0,D2
        BEQ     R_RXB

        * Leemos carácter de la cola
        MOVE.L  #2,D0
        BSR     LEECAR

        * No hay caracter
        CMP.L   #$FFFFFFFF,D0
        BEQ     R_TXA_E

        * Escribimos carácter
        MOVE.B  D0,TBA
        BRA     R_RXB

R_TXA_E:
        MOVE.B  IMR_COPY,D0
        * Apagamos TxA
        AND.B   #$FE,D0
        MOVE.B  D0,IMR_COPY
        MOVE.B  D0,IMR

R_RXB:
        * No ha llegado caracter RxB
        BTST    #5,D2
        BEQ     R_TXB

        * Metemos en cola el caracter RxB
        MOVE.L  #0,D1
        MOVE.B  RBB,D1
        MOVE.L  #1,D0
        BSR     ESCCAR

R_TXB:
        * No ha llegado caracter TxB
        BTST    #4,D2
        BEQ     R_END

        * Leemos carácter de la cola
        MOVE.L  #3,D0
        BSR     LEECAR

        * No hay caracter
        CMP.L   #$FFFFFFFF,D0
        BEQ     R_TXB_E

        * Escribimos carácter
        MOVE.B  D0,TBB
        BRA     R_END

R_TXB_E:
        MOVE.B  IMR_COPY,D0
        * Apagamos TxB
        AND.B   #$EF,D0
        MOVE.B  D0,IMR_COPY
        MOVE.B  D0,IMR

R_END:
        MOVE.L  (A7)+,A0
        MOVE.L  (A7)+,D2
        MOVE.L  (A7)+,D1
        MOVE.L  (A7)+,D0
        RTE

* Programa de prueba
INICIO:
        BSR     INIT
        * Pasa a Supervisor=1 con Máscara=000
        MOVE.W  #$2000,SR       

BUCLE_PR:
        * Leemos
        MOVE.W  #30,-(A7)       * Tamaño máximo
        MOVE.W  #0,-(A7)        * Línea A
        MOVE.L  #DATOS_PR,-(A7)
        BSR     SCAN
        ADD.L   #8,A7

        * Esperamos
        CMP.L   #0,D0
        BLE     BUCLE_PR

        * Escribimos
        MOVE.W  D0,-(A7)        * Tamaño leido por SCAN
        MOVE.W  #1,-(A7)        * Línea B
        MOVE.L  #DATOS_PR,-(A7)
        BSR     PRINT
        ADD.L   #8,A7

        BRA     BUCLE_PR

DATOS_PR:  
        DS.B    2100

* Importamos librería
        INCLUDE bib_aux.s
