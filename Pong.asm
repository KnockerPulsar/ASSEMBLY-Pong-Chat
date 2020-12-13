DisplayChar MACRO Char
	            PUSH AX
	            PUSH DX

	            mov  ah,2
	            mov  dl, Char
	            int  21h

	            POP  DX
	            POP  AX
ENDM
MoveCursor MACRO X,Y 
               PUSH AX
	           PUSH DX

	           mov  ah,2
	           mov  dl,X
	           mov  dh,Y
	           int  10h

	           POP  DX   
	           POP  AX
ENDM
GoIntoTextMode MACRO
	               PUSH AX

	               mov  ah,6
	               mov  al,13h
	               int  10h

	               POP  AX

ENDM         

ClearScreen MACRO    
            PUSHA ; Will cause erros in VSCode
            mov ax,0600h
            mov bh,07
            mov cx,0
            mov dx,184FH
            int 10h
            POPA ; Will cause erros in VSCode 
ENDM              

GetPlayerInput MACRO 
             
     PUSH CX
     MOV CL, LocalY
     mov ah,1
     int 16h    
               
     CMP AH, 72D
     JZ MoveUp
     
     CMP AH, 80D
     JZ MoveDown
     
     JMP EndInput
     
MoveUp:          
       DEC CL
       JMP EndInput
MoveDown:            
       INC CL                  
       JMP EndInput
EndInput:
       MOV LocalY, CL
          
       POP CX  
       
       FlushKeyBuffer
ENDM
                  
FlushKeyBuffer MACRO 
                PUSH AX
	            mov ah,0ch
	            mov al,0
	            int 21h   
	            POP AX
ENDM FlushKeyBuffer     

.Model SMALL
.STACK 64

.DATA
	; Variables here
	PaddleInitialRow     DB  0CH
	LeftPaddleIitialCol  DB  2H
	RightPaddleIitialCol DB  77D
	Paddle               EQU "|"
	BallInititLoc        DB  3D, 11D
    Ball EQU "O"                 
    
    
    LocalX DB 2D
    LocalY DB 12D
    
    OtherX DB 77D
    OtherY DB 12D
    
    BallCurrX DB 3D
    BallCurrY DB 11D
    
    BallPrevX DB ?
    BallPrevY DB ?
    
.CODE
MAIN PROC FAR
	; Code here
	; Initializing DS
	     MOV            AX, @DATA
	     MOV            DS, AX

	; Chaning video mode
	     GoIntoTextMode
 
	
GameLoop:     
	; Get player input    
	; Currently only getting local player input
	GetPlayerInput      
	
	; Draw The paddle at their proper position, derived from player input
	CALL Draw
	
	; Move ball
	
	Loop GameLoop

	; Exits the program
	     MOV            AH, 4CH
	     INT            21H

MAIN ENDP

Draw PROC
	; Draw left paddle first
	; Move the cursor to row 0AH, column 2, output "|"
	; Row 0BH, column 2, output
	; Row 0CH, column 2, output
	; Then the right paddle
	; Same as the left paddle but move to row 77D   
	
	; DL carries the X coordinate (Columns), DH carries the Y coordinate (Rows)
         MOV CX, 3D
	     MOV            DL , LocalX
	     MOV            DH, LocalY
         
	ClearScreen
                            
LeftPaddleInit:                            
	     MoveCursor     DL,DH
	     DisplayChar    Paddle
	     DEC DH            
	     LOOP LeftPaddleInit
	                         
	     MOV CX, 3D                        
	     MOV            DL , OtherX
	     MOV            DH, OtherY                           
RightPaddleInit:                            
	     MoveCursor     DL,DH
	     DisplayChar    Paddle
	     DEC DH
	     LOOP RightPaddleInit
	                            
	                            
	     MOV DL, BallCurrX
	     MOV DH, BallCurrY
	     	     
	     MoveCursor DL,DH
	     DisplayChar Ball
	     


	     RET
Draw ENDP
; End file and tell the assembler what the main subroutine is
    END MAIN 

