; FLAPPY BIRD - PIC16F877A + Nokia 5110 (PCD8544)

    PROCESSOR   16F877A
    #include    <xc.inc>

    CONFIG  FOSC = HS, WDTE = OFF, PWRTE = ON, BOREN = OFF, LVP = OFF

#define LCD_DC      PORTD,0
#define LCD_CE      PORTD,1
#define LCD_RST     PORTD,2
#define LCD_SDIN    PORTC,5
#define LCD_SCLK    PORTC,3
#define BTN         PORTB,0

#define w 0
#define f 1

GROUND_Y    EQU     42
CEILING_Y   EQU     8       
BIRD_X      EQU     15
BIRD_W      EQU     6
PIPE_W      EQU     8

    PSECT   gvars,class=RAM,space=1,delta=1,noexec,reloc=2
bird_y:         DS  1
bird_vel:       DS  1
bird_dead:      DS  1
score_tens:     DS  1       
score_ones:     DS  1
hi_tens:        DS  1       
hi_ones:        DS  1       
rand_val:       DS  1

temp1:          DS  1       
temp2:          DS  1       
temp3:          DS  1
temp4:          DS  1       
temp5:          DS  1
temp6:          DS  1
spi_data:       DS  1
spi_loop:       DS  1
str_idx:        DS  1
loop_page:      DS  1
loop_col:       DS  1
col_byte:       DS  1
btn_prev:       DS  1
pipeA_x:        DS  1
pipeA_y:        DS  1
pipeA_gap:      DS  1
pipeB_x:        DS  1
pipeB_y:        DS  1
pipeB_gap:      DS  1
col_px:         DS  1
col_py:         DS  1
col_pgap:       DS  1
render_py:      DS  1
render_pgap:    DS  1

;==============================================================================
    PSECT   resetVec,class=CODE,delta=2,reloc=2,abs,ovrld
    ORG     0x0000
    GOTO    MAIN

    PSECT   mainCode,class=CODE,delta=2,reloc=2
MAIN:
    BSF     STATUS, 5       
    CLRF    TRISC           
    CLRF    TRISD           
    MOVLW   0xFF
    MOVWF   TRISB           
    MOVLW   0x06
    MOVWF   ADCON1          
    BCF     STATUS, 5       

    CALL    LCD_INIT
    
    MOVLW   0x00
    CALL    EEPROM_READ
    MOVWF   hi_tens
    MOVLW   0x01
    CALL    EEPROM_READ
    MOVWF   hi_ones
    
    MOVLW   10
    SUBWF   hi_tens, w
    BTFSS   STATUS, 0       
    GOTO    HI_SCORE_OK
    CLRF    hi_tens
    CLRF    hi_ones
HI_SCORE_OK:

    MOVLW   0x88
    MOVWF   rand_val        

SHOW_SPLASH:
    CALL    CLEAR_SCREEN
    
    MOVLW   36
    MOVWF   temp1
    MOVLW   0
    MOVWF   temp2
    CALL    LCD_GOTO
    CLRF    str_idx
SPL_DTU:
    MOVF    str_idx, w
    CALL    STR_DTU
    CLRF    PCLATH          
    IORLW   0
    BTFSC   STATUS, 2
    GOTO    SPL_FLAPPY
    CALL    DRAW_CHAR
    INCF    str_idx, f
    GOTO    SPL_DTU
    
SPL_FLAPPY:
    MOVLW   18
    MOVWF   temp1       
    MOVLW   1
    MOVWF   temp2       
    CALL    LCD_GOTO
    CLRF    str_idx
SPL_FLAP_L:
    MOVF    str_idx, w
    CALL    STR_FLAPPY
    CLRF    PCLATH          
    IORLW   0
    BTFSC   STATUS, 2
    GOTO    SPL_BIRD
    CALL    DRAW_BIG_CHAR
    INCF    str_idx, f
    GOTO    SPL_FLAP_L

SPL_BIRD:
    MOVLW   18
    MOVWF   temp1       
    MOVLW   2
    MOVWF   temp2       
    CALL    LCD_GOTO
    CLRF    str_idx
SPL_BIRD_L:
    MOVF    str_idx, w
    CALL    STR_BIRD
    CLRF    PCLATH          
    IORLW   0
    BTFSC   STATUS, 2
    GOTO    SPL_N1
    CALL    DRAW_BIG_CHAR
    INCF    str_idx, f
    GOTO    SPL_BIRD_L

SPL_N1:
    MOVLW   10
    MOVWF   temp1
    MOVLW   3               
    MOVWF   temp2
    CALL    LCD_GOTO
    CLRF    str_idx
SPL_N1_L:
    MOVF    str_idx, w
    CALL    STR_NAMES_1
    CLRF    PCLATH          
    IORLW   0
    BTFSC   STATUS, 2
    GOTO    SPL_N2
    CALL    DRAW_CHAR
    INCF    str_idx, f
    GOTO    SPL_N1_L

SPL_N2:
    MOVLW   20
    MOVWF   temp1
    MOVLW   4               
    MOVWF   temp2
    CALL    LCD_GOTO
    CLRF    str_idx
SPL_N2_L:
    MOVF    str_idx, w
    CALL    STR_NAMES_2
    CLRF    PCLATH          
    IORLW   0
    BTFSC   STATUS, 2
    GOTO    WAIT_START_BTN
    CALL    DRAW_CHAR
    INCF    str_idx, f
    GOTO    SPL_N2_L

WAIT_START_BTN:
    CALL    DELAY_50MS
    CALL    DELAY_50MS
    INCF    temp5, f
    MOVLW   20              
    MOVWF   temp1
    MOVLW   5               
    MOVWF   temp2
    CALL    LCD_GOTO
    BTFSC   temp5, 2        
    GOTO    CLEAR_PROMPT
    
DRAW_PROMPT:
    CLRF    str_idx
DP_LOOP:
    MOVF    str_idx, w
    CALL    STR_PROMPT
    CLRF    PCLATH          
    IORLW   0
    BTFSC   STATUS, 2
    GOTO    CHK_BTN
    CALL    DRAW_CHAR
    INCF    str_idx, f
    GOTO    DP_LOOP

CLEAR_PROMPT:
    MOVLW   44              
    MOVWF   temp1
CP_LOOP:
    MOVLW   0
    CALL    LCD_DATA
    DECFSZ  temp1, f
    GOTO    CP_LOOP

CHK_BTN:
    BTFSC   BTN             
    GOTO    WAIT_START_BTN  
    CALL    DELAY_50MS

WAIT_START_REL:
    BTFSS   BTN             
    GOTO    WAIT_START_REL

GAME_RESTART:
    CALL    GAME_INIT
    
PLAY_LOOP:
    CALL    UPDATE_PHYSICS
    CALL    DRAW_FRAME
    CALL    FRAME_DELAY
    MOVF    bird_dead, w
    BTFSC   STATUS, 2
    GOTO    PLAY_LOOP
    
    ; --- GAME OVER SEQUENCE ---
    CALL    DRAW_FRAME      
    MOVLW   10              
    MOVWF   temp3
DELAY_05S:
    CALL    DELAY_50MS
    DECFSZ  temp3, f
    GOTO    DELAY_05S
    
CHECK_HIGH_SCORE:
    MOVF    hi_tens, w
    SUBWF   score_tens, w
    BTFSS   STATUS, 0       
    GOTO    SKIP_SAVE
    BTFSS   STATUS, 2       
    GOTO    DO_SAVE         
    
    MOVF    hi_ones, w
    SUBWF   score_ones, w
    BTFSS   STATUS, 0       
    GOTO    SKIP_SAVE

DO_SAVE:
    MOVLW   0x00
    MOVWF   temp1
    MOVF    score_tens, w
    CALL    EEPROM_WRITE    
    MOVLW   0x01
    MOVWF   temp1
    MOVF    score_ones, w
    CALL    EEPROM_WRITE    
    MOVF    score_tens, w
    MOVWF   hi_tens
    MOVF    score_ones, w
    MOVWF   hi_ones
SKIP_SAVE:
    
    CALL    CLEAR_SCREEN
    
    ; CENTERED "GAME"
    MOVLW   26
    MOVWF   temp1
    MOVLW   1
    MOVWF   temp2
    CALL    LCD_GOTO
    CLRF    str_idx
GO_GAME_LOOP:
    MOVF    str_idx, w
    CALL    STR_GAME
    CLRF    PCLATH          
    IORLW   0
    BTFSC   STATUS, 2
    GOTO    GO_OVER_INIT
    CALL    DRAW_BIG_CHAR   
    INCF    str_idx, f
    GOTO    GO_GAME_LOOP
    
GO_OVER_INIT:
    ; CENTERED "OVER"
    MOVLW   26
    MOVWF   temp1
    MOVLW   2
    MOVWF   temp2
    CALL    LCD_GOTO
    CLRF    str_idx
GO_OVER_LOOP:
    MOVF    str_idx, w
    CALL    STR_OVER
    CLRF    PCLATH          
    IORLW   0
    BTFSC   STATUS, 2
    GOTO    SHOW_HI_SCORE
    CALL    DRAW_BIG_CHAR   
    INCF    str_idx, f
    GOTO    GO_OVER_LOOP

SHOW_HI_SCORE:
    MOVLW   12
    MOVWF   temp1
    MOVLW   4
    MOVWF   temp2
    CALL    LCD_GOTO
    CLRF    str_idx
GO_HI_LOOP:
    MOVF    str_idx, w
    CALL    STR_HI
    CLRF    PCLATH          
    IORLW   0
    BTFSC   STATUS, 2
    GOTO    DRAW_HI_DIGITS
    CALL    DRAW_CHAR       
    INCF    str_idx, f
    GOTO    GO_HI_LOOP

DRAW_HI_DIGITS:
    MOVF    hi_tens, w
    CALL    DRAW_DIGIT      
    MOVF    hi_ones, w
    CALL    DRAW_DIGIT
    
WAIT_RST_BTN:
    BTFSC   BTN             
    GOTO    WAIT_RST_BTN
    CALL    DELAY_50MS
WAIT_RST_REL:
    BTFSS   BTN             
    GOTO    WAIT_RST_REL
    GOTO    GAME_RESTART

;---- Game Logic --------------------------------------------------------------
GAME_INIT:
    MOVLW   22
    MOVWF   bird_y
    CLRF    bird_vel
    CLRF    bird_dead
    CLRF    score_tens
    CLRF    score_ones
    CLRF    btn_prev
    MOVLW   60              
    MOVWF   pipeA_x
    CALL    GENERATE_PIPE_Y
    MOVWF   pipeA_y
    MOVLW   15
    MOVWF   pipeA_gap
    MOVLW   105             
    MOVWF   pipeB_x
    CALL    GENERATE_PIPE_Y
    MOVWF   pipeB_y
    MOVLW   15
    MOVWF   pipeB_gap
    RETURN

UPDATE_PHYSICS:
    MOVLW   1
    ADDWF   bird_vel, f
    MOVF    bird_vel, w
    ADDWF   bird_y, f
    MOVLW   GROUND_Y ; =42
    SUBWF   bird_y, w
    BTFSC   STATUS, 0
    BSF     bird_dead, 0
    MOVLW   CEILING_Y ; =8
    SUBWF   bird_y, w
    BTFSS   STATUS, 0
    BSF     bird_dead, 0
    BTFSC   BTN
    GOTO    BTN_RELEASED
    MOVF    btn_prev, w
    BTFSS   STATUS, 2
    GOTO    MOVE_PIPES
    MOVLW   253             
    MOVWF   bird_vel
    MOVLW   1
    MOVWF   btn_prev
    GOTO    MOVE_PIPES
BTN_RELEASED:
    CLRF    btn_prev

MOVE_PIPES:
    DECF    pipeA_x, f
    MOVF    pipeA_x, w
    XORLW   BIRD_X
    BTFSC   STATUS, 2
    CALL    ADD_SCORE       
    BTFSS   pipeA_x, 7      
    GOTO    MOVE_PIPE_B
    MOVLW   84              
    MOVWF   pipeA_x
    CALL    GENERATE_PIPE_Y
    MOVWF   pipeA_y

MOVE_PIPE_B:
    DECF    pipeB_x, f
    MOVF    pipeB_x, w
    XORLW   BIRD_X
    BTFSC   STATUS, 2
    CALL    ADD_SCORE       
    BTFSS   pipeB_x, 7      
    GOTO    CHECK_COLLISIONS
    MOVLW   84              
    MOVWF   pipeB_x
    CALL    GENERATE_PIPE_Y
    MOVWF   pipeB_y
    
CHECK_COLLISIONS:
    MOVF    pipeA_x, w
    MOVWF   col_px
    MOVF    pipeA_y, w
    MOVWF   col_py
    MOVF    pipeA_gap, w
    MOVWF   col_pgap
    CALL    DO_COLLISION_CHECK
    MOVF    pipeB_x, w
    MOVWF   col_px
    MOVF    pipeB_y, w
    MOVWF   col_py
    MOVF    pipeB_gap, w
    MOVWF   col_pgap
    CALL    DO_COLLISION_CHECK
    RETURN

DO_COLLISION_CHECK:
    MOVLW   BIRD_X + BIRD_W
    SUBWF   col_px, w
    BTFSC   STATUS, 0      ; bird is left of pipe = no collision
    RETURN
    MOVF    col_px, w
    ADDLW   PIPE_W
    MOVWF   temp1
    MOVLW   BIRD_X
    SUBWF   temp1, w
    BTFSS   STATUS, 0       
    RETURN
    MOVF    bird_y, w
    SUBWF   col_py, w
    BTFSS   STATUS, 0       
    GOTO    HIT_LOWER
    BSF     bird_dead, 0     ; hit top pipe
    RETURN
HIT_LOWER:
    MOVF    col_pgap, w
    ADDWF   col_py, w       
    SUBWF   bird_y, w
    BTFSC   STATUS, 0       
    BSF     bird_dead, 0     ; hit bottom pipe
    RETURN

ADD_SCORE:
    MOVLW   5
    ADDWF   score_ones, f
    MOVLW   10
    SUBWF   score_ones, w
    BTFSS   STATUS, 0       
    RETURN
    MOVWF   score_ones      
    INCF    score_tens, f
    MOVLW   10
    SUBWF   score_tens, w
    BTFSC   STATUS, 0
    CLRF    score_tens      
    RETURN

GENERATE_PIPE_Y:
    CALL    RANDOM
    MOVF    rand_val, w
    ANDLW   0x1F            
    ADDLW   12               
    MOVWF   temp1
    RETURN

;---- Rendering ---------------------------------------------------------------
DRAW_FRAME:
    MOVLW   0x80            
    CALL    LCD_CMD
    MOVLW   0x40            
    CALL    LCD_CMD
    CLRF    loop_page
PAGE_LOOP:
    CLRF    loop_col
COL_LOOP:
    CLRF    col_byte
    MOVF    loop_page, w
    BTFSS   STATUS, 2
    GOTO    CHK_GROUND
    BSF     col_byte, 7     
    MOVLW   70
    SUBWF   loop_col, w
    BTFSS   STATUS, 0
    GOTO    SEND_PIXEL      
    MOVLW   73
    SUBWF   loop_col, w
    BTFSS   STATUS, 0
    GOTO    DO_TENS
    MOVLW   77
    SUBWF   loop_col, w
    BTFSS   STATUS, 0
    GOTO    SEND_PIXEL
    MOVLW   80
    SUBWF   loop_col, w
    BTFSS   STATUS, 0
    GOTO    DO_ONES
    GOTO    SEND_PIXEL

DO_TENS:
    MOVF    loop_col, w
    ADDLW   256-70
    MOVWF   temp1           
    MOVF    score_tens, w
    CALL    GET_FONT
    CLRF    PCLATH          
    IORWF   col_byte, f
    GOTO    SEND_PIXEL

DO_ONES:
    MOVF    loop_col, w
    ADDLW   256-77
    MOVWF   temp1           
    MOVF    score_ones, w
    CALL    GET_FONT
    CLRF    PCLATH          
    IORWF   col_byte, f
    GOTO    SEND_PIXEL

CHK_GROUND:
    MOVLW   5               
    SUBWF   loop_page, w
    BTFSS   STATUS, 2
    GOTO    CHK_PIPE_A
    MOVLW   0xC0            
    MOVWF   col_byte

CHK_PIPE_A:
    MOVF    pipeA_x, w
    SUBWF   loop_col, w
    BTFSS   STATUS, 0       
    GOTO    CHK_PIPE_B
    MOVWF   temp1           
    MOVLW   PIPE_W
    SUBWF   temp1, w
    BTFSC   STATUS, 0       
    GOTO    CHK_PIPE_B
    MOVF    pipeA_y, w
    MOVWF   render_py
    MOVF    pipeA_gap, w
    MOVWF   render_pgap
    GOTO    RENDER_PIPE

CHK_PIPE_B:
    MOVF    pipeB_x, w
    SUBWF   loop_col, w
    BTFSS   STATUS, 0
    GOTO    CHK_BIRD
    MOVWF   temp1
    MOVLW   PIPE_W
    SUBWF   temp1, w
    BTFSC   STATUS, 0
    GOTO    CHK_BIRD
    MOVF    pipeB_y, w
    MOVWF   render_py
    MOVF    pipeB_gap, w
    MOVWF   render_pgap

RENDER_PIPE:
    MOVF    temp1, w         
    MOVWF   col_px
    CALL    CALC_PIPE_PIXELS
    MOVF    temp1, w
    IORWF   col_byte, f

CHK_BIRD:
    MOVLW   BIRD_X
    SUBWF   loop_col, w
    BTFSS   STATUS, 0
    GOTO    SEND_PIXEL
    MOVWF   temp1
    MOVLW   BIRD_W
    SUBWF   temp1, w
    BTFSC   STATUS, 0
    GOTO    SEND_PIXEL
    MOVF    temp1, w         
    MOVWF   col_px
    CALL    CALC_BIRD_PIXELS
    MOVF    temp1, w
    IORWF   col_byte, f

SEND_PIXEL:
    MOVF    col_byte, w
    CALL    LCD_DATA
    INCF    loop_col, f
    MOVLW   84
    SUBWF   loop_col, w
    BTFSS   STATUS, 0
    GOTO    COL_LOOP
    INCF    loop_page, f
    MOVLW   6
    SUBWF   loop_page, w
    BTFSS   STATUS, 0
    GOTO    PAGE_LOOP
    RETURN

CLEAR_SCREEN:
    MOVLW   0x80
    CALL    LCD_CMD
    MOVLW   0x40
    CALL    LCD_CMD
    MOVLW   6
    MOVWF   loop_page
CS_P:
    MOVLW   84
    MOVWF   loop_col
CS_C:
    MOVLW   0
    CALL    LCD_DATA
    DECFSZ  loop_col, f
    GOTO    CS_C
    DECFSZ  loop_page, f
    GOTO    CS_P
    RETURN

LCD_GOTO:
    MOVF    temp1, w
    IORLW   0x80
    CALL    LCD_CMD
    MOVF    temp2, w
    IORLW   0x40
    CALL    LCD_CMD
    RETURN

DRAW_CHAR:
    MOVWF   temp4           
    CLRF    col_py          
DC_LOOP:
    MOVF    col_py, w
    MOVWF   temp1           
    MOVF    temp4, w
    CALL    GET_FONT
    CLRF    PCLATH          
    CALL    LCD_DATA
    INCF    col_py, f
    MOVLW   3
    SUBWF   col_py, w
    BTFSS   STATUS, 0
    GOTO    DC_LOOP
    MOVLW   0
    CALL    LCD_DATA        
    RETURN

DRAW_BIG_CHAR:
    MOVWF   temp4           
    CLRF    col_py          
DBC_LOOP:
    MOVF    col_py, w
    MOVWF   temp1           
    MOVF    temp4, w
    CALL    GET_FONT        
    CLRF    PCLATH          
    MOVWF   temp5           
    MOVF    temp5, w        
    CALL    LCD_DATA        
    MOVF    temp5, w        
    CALL    LCD_DATA        
    INCF    col_py, f
    MOVLW   3               
    SUBWF   col_py, w
    BTFSS   STATUS, 0
    GOTO    DBC_LOOP
    MOVLW   0
    CALL    LCD_DATA        
    MOVLW   0
    CALL    LCD_DATA        
    RETURN

DRAW_DIGIT:
    MOVWF   temp4           
    CLRF    col_py          
DD_LOOP:
    MOVF    col_py, w
    MOVWF   temp1           
    MOVF    temp4, w
    CALL    GET_FONT
    CLRF    PCLATH          
    CALL    LCD_DATA
    INCF    col_py, f
    MOVLW   3
    SUBWF   col_py, w
    BTFSS   STATUS, 0
    GOTO    DD_LOOP
    MOVLW   0
    CALL    LCD_DATA        
    RETURN

STR_DTU:
    MOVWF temp6
    MOVLW high(T_DTU)
    MOVWF PCLATH
    MOVLW low(T_DTU)
    ADDWF temp6, w
    BTFSC STATUS, 0
    INCF PCLATH, f
    MOVWF PCL
T_DTU: RETLW 13 
 RETLW 29 
 RETLW 30 
 RETLW 0   

STR_FLAPPY:
    MOVWF temp6
    MOVLW high(T_FLP)
    MOVWF PCLATH
    MOVLW low(T_FLP)
    ADDWF temp6, w
    BTFSC STATUS, 0
    INCF PCLATH, f
    MOVWF PCL
T_FLP: RETLW 15 
 RETLW 21 
 RETLW 10 
 RETLW 25 
 RETLW 25 
 RETLW 34 
 RETLW 0   

STR_BIRD:
    MOVWF temp6
    MOVLW high(T_BRD)
    MOVWF PCLATH
    MOVLW low(T_BRD)
    ADDWF temp6, w
    BTFSC STATUS, 0
    INCF PCLATH, f
    MOVWF PCL
T_BRD: RETLW 11 
 RETLW 18 
 RETLW 27 
 RETLW 13 
 RETLW 36 
 RETLW 37 
 RETLW 0   

STR_NAMES_1:
    MOVWF temp6
    MOVLW high(T_NM1)
    MOVWF PCLATH
    MOVLW low(T_NM1)
    ADDWF temp6, w
    BTFSC STATUS, 0
    INCF PCLATH, f
    MOVWF PCL
T_NM1: RETLW 10 
 RETLW 11 
 RETLW 14 
 RETLW 14 
 RETLW 29 
 RETLW 36 
 RETLW 25 
 RETLW 10 
 RETLW 30 
 RETLW 21 
 RETLW 36 
 RETLW 28 
 RETLW 18 
 RETLW 23 
 RETLW 16 
 RETLW 17 
 RETLW 0   

STR_NAMES_2:
    MOVWF temp6
    MOVLW high(T_NM2)
    MOVWF PCLATH
    MOVLW low(T_NM2)
    ADDWF temp6, w
    BTFSC STATUS, 0
    INCF PCLATH, f
    MOVWF PCL
T_NM2: RETLW 31 
 RETLW 18 
 RETLW 31 
 RETLW 10 
 RETLW 10 
 RETLW 23 
 RETLW 36 
 RETLW 16 
 RETLW 24 
 RETLW 14 
 RETLW 21 
 RETLW 0   

STR_PROMPT:
    MOVWF temp6
    MOVLW high(T_PRM)
    MOVWF PCLATH
    MOVLW low(T_PRM)
    ADDWF temp6, w
    BTFSC STATUS, 0
    INCF PCLATH, f
    MOVWF PCL
T_PRM: RETLW 25 
 RETLW 27 
 RETLW 14 
 RETLW 28 
 RETLW 28 
 RETLW 36 
 RETLW 28 
 RETLW 29 
 RETLW 10 
 RETLW 27 
 RETLW 29 
 RETLW 0

STR_GAME:
    MOVWF temp6
    MOVLW high(T_GAM)
    MOVWF PCLATH
    MOVLW low(T_GAM)
    ADDWF temp6, w
    BTFSC STATUS, 0
    INCF PCLATH, f
    MOVWF PCL
T_GAM: RETLW 16 
 RETLW 10 
 RETLW 22 
 RETLW 14 
 RETLW 0   

STR_OVER:
    MOVWF temp6
    MOVLW high(T_OVR)
    MOVWF PCLATH
    MOVLW low(T_OVR)
    ADDWF temp6, w
    BTFSC STATUS, 0
    INCF PCLATH, f
    MOVWF PCL
T_OVR: RETLW 24 
 RETLW 31 
 RETLW 14 
 RETLW 27 
 RETLW 0   

STR_HI:
    MOVWF temp6
    MOVLW high(T_HI)
    MOVWF PCLATH
    MOVLW low(T_HI)
    ADDWF temp6, w
    BTFSC STATUS, 0
    INCF PCLATH, f
    MOVWF PCL
T_HI: RETLW 17 
 RETLW 18 
 RETLW 16 
 RETLW 17 
 RETLW 36 
 RETLW 28 
 RETLW 12 
 RETLW 24 
 RETLW 27 
 RETLW 14 
 RETLW 36 
 RETLW 38 
 RETLW 36 
 RETLW 0

    ALIGN 2
GET_FONT:
    MOVWF   temp2
    BCF     STATUS, 0
    RLF     temp2, w         
    ADDWF   temp2, w         
    ADDWF   temp1, w         
    MOVWF   temp3           
    MOVLW   high(FONT_DATA)
    MOVWF   PCLATH
    MOVLW   low(FONT_DATA)
    ADDWF   temp3, w
    BTFSC   STATUS, 0
    INCF    PCLATH, f
    MOVWF   PCL

FONT_DATA:
 RETLW 0x3E 
 RETLW 0x22 
 RETLW 0x3E   
 RETLW 0x00 
 RETLW 0x3E 
 RETLW 0x00   
 RETLW 0x3A 
 RETLW 0x2A 
 RETLW 0x2E 
 RETLW 0x2A 
 RETLW 0x2A 
 RETLW 0x3E 
 RETLW 0x0E 
 RETLW 0x08 
 RETLW 0x3E 
 RETLW 0x2E 
 RETLW 0x2A 
 RETLW 0x3A 
 RETLW 0x3E 
 RETLW 0x2A 
 RETLW 0x3A 
 RETLW 0x02 
 RETLW 0x02 
 RETLW 0x3E 
 RETLW 0x3E 
 RETLW 0x2A 
 RETLW 0x3E 
 RETLW 0x2E 
 RETLW 0x2A 
 RETLW 0x3E 
 RETLW 0x3E 
 RETLW 0x0A 
 RETLW 0x3E 
 RETLW 0x3E 
 RETLW 0x2A 
 RETLW 0x14 
 RETLW 0x1C 
 RETLW 0x22 
 RETLW 0x22 
 RETLW 0x3E 
 RETLW 0x22 
 RETLW 0x1C 
 RETLW 0x3E 
 RETLW 0x2A 
 RETLW 0x22 
 RETLW 0x3E 
 RETLW 0x0A 
 RETLW 0x02 
 RETLW 0x1C 
 RETLW 0x22 
 RETLW 0x2C 
 RETLW 0x3E 
 RETLW 0x08 
 RETLW 0x3E 
 RETLW 0x22 
 RETLW 0x3E 
 RETLW 0x22 
 RETLW 0x10 
 RETLW 0x20 
 RETLW 0x1E 
 RETLW 0x3E 
 RETLW 0x08 
 RETLW 0x36 
 RETLW 0x3E 
 RETLW 0x20 
 RETLW 0x20 
 RETLW 0x3E 
 RETLW 0x04 
 RETLW 0x3E 
 RETLW 0x3E 
 RETLW 0x04 
 RETLW 0x38 
 RETLW 0x1C 
 RETLW 0x22 
 RETLW 0x1C 
 RETLW 0x3E 
 RETLW 0x12 
 RETLW 0x0C 
 RETLW 0x1C 
 RETLW 0x2A 
 RETLW 0x3C 
 RETLW 0x3E 
 RETLW 0x12 
 RETLW 0x2C 
 RETLW 0x24 
 RETLW 0x2A 
 RETLW 0x12 
 RETLW 0x02 
 RETLW 0x3E 
 RETLW 0x02 
 RETLW 0x1E 
 RETLW 0x20 
 RETLW 0x1E 
 RETLW 0x0E 
 RETLW 0x30 
 RETLW 0x0E 
 RETLW 0x3E 
 RETLW 0x10 
 RETLW 0x3E 
 RETLW 0x36 
 RETLW 0x08 
 RETLW 0x36 
 RETLW 0x06 
 RETLW 0x38 
 RETLW 0x06 
 RETLW 0x32 
 RETLW 0x2A 
 RETLW 0x26 
 RETLW 0x00 
 RETLW 0x00 
 RETLW 0x00 
 RETLW 0x08 
 RETLW 0x1C 
 RETLW 0x08 
 RETLW 0x08 
 RETLW 0x08 
 RETLW 0x08

GET_BIRD_SPRITE:
    MOVWF temp2
    MOVLW high(BIRD_DATA)
    MOVWF PCLATH
    MOVLW low(BIRD_DATA)
    ADDWF temp2, w
    BTFSC STATUS, 0
    INCF PCLATH, f
    MOVWF PCL
BIRD_DATA:
 RETLW 0x0E 
 RETLW 0x11 
 RETLW 0x15 
 RETLW 0x11 
 RETLW 0x0A 
 RETLW 0x04 
 RETLW 0x0E 
 RETLW 0x11 
 RETLW 0x11 
 RETLW 0x15 
 RETLW 0x0A 
 RETLW 0x04 

CALC_PIPE_PIXELS:
    CLRF temp1
    MOVF loop_page, w
    BTFSC STATUS, 2          
    RETURN
    MOVLW 8
    MOVWF temp2             
    MOVF loop_page, w
    MOVWF temp3
    BCF STATUS, 0
    RLF temp3, f
    BCF STATUS, 0
    RLF temp3, f
    BCF STATUS, 0
    RLF temp3, f
    MOVLW 0x01
    MOVWF temp4             
CPP_LOOP:
    MOVF render_py, w
    SUBWF temp3, w
    BTFSS STATUS, 0         
    GOTO CPP_PATTERN_CHK 
    MOVF render_pgap, w
    ADDWF render_py, w      
    SUBWF temp3, w
    BTFSC STATUS, 0         
    GOTO CPP_PATTERN_CHK 
    GOTO CPP_NEXT
CPP_PATTERN_CHK:
    MOVF col_px, w
    XORLW 1                 
    BTFSC STATUS, 2
    GOTO CPP_NEXT
    MOVF temp4, w
    IORWF temp1, f          
CPP_NEXT:
    INCF temp3, f          
    BCF STATUS, 0
    RLF temp4, f          
    DECFSZ temp2, f
    GOTO CPP_LOOP
    RETURN

CALC_BIRD_PIXELS:
    MOVF col_px, w
    BTFSC bird_dead, 0
    ADDLW 6                
    CALL GET_BIRD_SPRITE
    CLRF PCLATH          
    MOVWF temp4             
    MOVF bird_y, w
    MOVWF temp2
    BCF STATUS, 0
    RRF temp2, f
    BCF STATUS, 0
    RRF temp2, f
    BCF STATUS, 0
    RRF temp2, w
    ANDLW 0x07
    MOVWF temp3             
    MOVF loop_page, w
    SUBWF temp3, w
    BTFSC STATUS, 2
    GOTO BIRD_SAME_PAGE
    INCF temp3, w
    SUBWF loop_page, w
    BTFSC STATUS, 2
    GOTO BIRD_NEXT_PAGE
    CLRF temp1             
    RETURN

BIRD_SAME_PAGE:
    MOVF bird_y, w
    ANDLW 0x07
    MOVWF temp2
    MOVF temp4, w
    MOVWF temp1
    MOVF temp2, f
    BTFSC STATUS, 2
    RETURN
BSP_LOOP:
    BCF STATUS, 0
    RLF temp1, f
    DECFSZ temp2, f
    GOTO BSP_LOOP
    RETURN

BIRD_NEXT_PAGE:
    MOVF bird_y, w
    ANDLW 0x07
    SUBLW 8                
    MOVWF temp2
    MOVF temp4, w
    MOVWF temp1
    MOVF temp2, f
    BTFSC STATUS, 2
    RETURN
BNP_LOOP:
    BCF STATUS, 0
    RRF temp1, f
    BCF temp1, 7          
    DECFSZ temp2, f
    GOTO BNP_LOOP
    RETURN

LCD_INIT:
    BCF LCD_RST
    CALL DELAY_50MS
    BSF LCD_RST
    BCF LCD_CE
    MOVLW 0x21
    CALL LCD_CMD
    MOVLW 0xBF
    CALL LCD_CMD
    MOVLW 0x06
    CALL LCD_CMD
    MOVLW 0x13
    CALL LCD_CMD
    MOVLW 0x20
    CALL LCD_CMD
    MOVLW 0x0C
    CALL LCD_CMD
    RETURN

LCD_CMD:
    BCF LCD_DC
    GOTO SPI_SEND
LCD_DATA:
    BSF LCD_DC
SPI_SEND:
    BCF LCD_CE
    MOVWF spi_data
    MOVLW 8
    MOVWF spi_loop
SPI_LOOP:
    NOP
    BTFSC spi_data, 7
    BSF LCD_SDIN
    BTFSS spi_data, 7
    BCF LCD_SDIN
    BSF LCD_SCLK
    NOP
    BCF LCD_SCLK
    RLF spi_data, f
    DECFSZ spi_loop, f
    GOTO SPI_LOOP
    BSF LCD_CE
    RETURN

RANDOM:
    RLF rand_val, w
    XORWF rand_val, w
    RLF rand_val, f
    RETURN

FRAME_DELAY:
    MOVLW 0x05             
    MOVWF temp1
D_L1: MOVLW 0xFF
    MOVWF temp2
D_L2: DECFSZ temp2, f
    GOTO D_L2
    DECFSZ temp1, f
    GOTO D_L1
    RETURN

DELAY_50MS:
    MOVLW 0x80
    MOVWF temp1
D50_L1: MOVLW 0xFF
    MOVWF temp2
D50_L2: DECFSZ temp2, f
    GOTO D50_L2
    DECFSZ temp1, f
    GOTO D50_L1
    RETURN

EEPROM_READ:
    BANKSEL EEADR
    MOVWF EEADR
    BANKSEL EECON1
    BCF EECON1, 7        
    BSF EECON1, 0        
    BANKSEL EEDATA
    MOVF EEDATA, w
    BANKSEL PORTA            
    RETURN

EEPROM_WRITE:
    BANKSEL temp2
    MOVWF temp2            
    MOVF temp1, w
    BANKSEL EEADR
    MOVWF EEADR            
    BANKSEL temp2
    MOVF temp2, w
    BANKSEL EEDATA
    MOVWF EEDATA          
    BANKSEL EECON1
    BCF EECON1, 7        
    BSF EECON1, 2        
    
    BCF INTCON, 7
    
    MOVLW 0x55            
    MOVWF EECON2
    MOVLW 0xAA
    MOVWF EECON2
    BSF EECON1, 1        
    
   
    MOVLW 0xFF
    BANKSEL temp3
    MOVWF temp3
EE_WAIT:
    BANKSEL EECON1
    BTFSS EECON1, 1      
    GOTO EE_DONE         
    BANKSEL temp3
    DECFSZ temp3, f
    GOTO EE_WAIT         
EE_DONE:
    BANKSEL EECON1
    BCF EECON1, 2        
    BANKSEL PORTA            
    RETURN

    END 
