.286
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
    
	;Displayed messages
	Welc DB 'Please Enter Your Name:', 13, 10, '$'
	Hel DB 'Please Enter any key to continue','$'
	Choices DB '* To start chatting press F1', 13,10,13,10, 09,09,09, '* To start game press F2', 13,10,13,10, 09,09,09,'* To end the program press ESC',13,10, '$'
	Info DB 13,10,'- You send a chat invitaion to ','$'
	userName DB 16,?, 16 DUP('$')

.CODE
MAIN PROC FAR
	; Code here
	; Initializing DS
	     MOV            AX, @DATA
	     MOV            DS, AX

	; Chaning video mode
	     GoIntoTextMode

	; Main Screen
	Home:
		ClearScreen
				;Display the Message in the middle of the main screen
		;Move Cursor
		 MOV 			AH, 2
		 MOV 			DX, 0A0Ah
		 INT 10h
			
		;Display Message
		 MOV 			AH, 9h
		 MOV 			DX, OFFSET Welc
		 INT 21h

	;Get user's name
		;Move Cursor 
		 MOV 			AH, 2
		 MOV 			DX, 0C0Ch
		 INT 10h

		 MOV 			AH, 0Ah
		 MOV 			DX, OFFSET userName
		 INT 21h

		;Validate the name
		 CMP userName+2, 41h 
		 JB Home 
		 
		 CMP userName+2, 5Ah
		 JBE Welcome 		; if in range A:Z
		 JA Check 			; If greater than A and not in range A:Z, check for a:z
			
	Check:
		CMP userName+2,61h
		JB Home 
		CMP userName+2, 7Ah
		JA Home  			; If not a letter, clear

	
	Welcome:				;Welcome the user
		;Move Cursor
		 MOV 			AH, 2
		 MOV 			DX, 0D0Ah
		 INT 10h
		;Display message
		 MOV 			AH, 9h
		 MOV 			DX, OFFSET Hel
		 INT 21h
		;Get any key as an indicatr to continue
		 MOV 			AH, 0
		 INT 16h

	OptionsScreen:
		ClearScreen
		;Move Cursor
		 MOV 			AH, 2
		 MOV 			DX, 0A18h
		 INT 10h
		
		;Display Options
		 MOV			AH, 9h
		 MOV 			DX, OFFSET Choices
		 INT 21h

		;Get User's choice
	CHS:
		 MOV 			AH, 0
		 INT 16h
		
		;Check user's input
		 CMP AH, 1   		; Check for ESC
		 JZ Exit
		 CMP AH, 3Ch 		; Check for F2
		 JZ GameLoop
		 CMP AH, 3Bh 		; Check for F1
		 JNZ CHS 			; if the pressed key not an option, loop till it is

	Chatting:		
	;To be Continued "D
		;Move cursor to the footer
		 MOV 			AH, 2
		 MOV 			DX, 1500h
		 INT 10h

		 MOV 			CX, 79
	Footer: ;Draw the dashed line
		 MOV 			AH, 2
		 MOV 			DL, '-'
		 INT 21h
		LOOP Footer
		; Show info message
		 MOV			AH, 9h
		 MOV 			DX, OFFSET Info
		 INT 21h
		;Just to hold the program to see the above changes till we decide what to do next
		 MOV 			AH, 0
		 INT 16h
		 JMP Exit
	
GameLoop:     
	; Get player input    
	; Currently only getting local player input
	GetPlayerInput      
	
	; Draw The paddle at their proper position, derived from player input
	CALL Draw
	
	; Move ball
	
	Loop GameLoop

Exit:
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

