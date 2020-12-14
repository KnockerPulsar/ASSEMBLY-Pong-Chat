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
            POPA ; Will cause errors in VSCode 
ENDM              
GetPlayerInput MACRO 
             
     PUSH CX
     MOV CL, LocalY
     MOV AH,1
     INT 16H    

	; Checks if the user pressed F4
	; If so, goes back to the main menu
	; TODO: SHOW THE SCORE FOR 5 SECONDS THEN GO TO THE MAIN MENU/OPTIONS MENU
	; Note that choosing to play a game again after leaving the first one picks up exactly where the first left off
	; Might need to keep an array of initial values to re-initialize the game again.
	 CMP AH, 62D
	 JZ OptionsScreen
	
	; Checks if the player pressed the up arrow
	; If so, decrements the y position of the paddle (since the y axis points down)
     CMP AH, 72D
     JZ MoveUp
    
	; Same as the up check but increments the y position
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
DisplayMessage MACRO Message
		 MOV 			AH, 9h
		 MOV 			DX, OFFSET Message
		 INT 21h	
ENDM

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
		 MoveCursor 0AH, 0AH

		;Display welcome message
		 DisplayMessage Welc
	
	;Get user's name
		;Move Cursor 
  		 MoveCursor 0CH, 0CH

		; This part isn't repeated that much, probably doesn't need a macro
		; Take the username as an input
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
		 MoveCursor 0AH, 0DH

		;Display "press any key to continue" message
		 DisplayMessage Hel

		;Get any key as an indicatr to continue
		 MOV 			AH, 0
		 INT 16h

	OptionsScreen:
		 ClearScreen
		;Move Cursor
		 MoveCursor 18H, 0AH

		;Display Options
		 DisplayMessage Choices
			
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
		 MoveCursor 00H, 15H
		
		
	; Loading the character, number of loops and preparing the interrupt 
		 MOV 			CX, 79
		 MOV 			AH, 2
		 MOV 			DL, '-'
 	;Draw the dashed line
	Footer:
		 INT 21h
		 LOOP Footer
		 
		; Show info message
		 DisplayMessage Info
		
	 	; Just to hold the program to see the above changes till we decide what to do next
		 MOV 			AH, 0
		 INT 16h
		 JMP Exit
		
	GameLoop:     
		; Get player input    
		; Currently only getting local player input
		 GetPlayerInput      
		 
		; Draw The paddle at their proper position, derived from player input
		 CALL Draw
		 
	     ; TODO: Move ball
	     ; Might get changed depending on the game
 
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
	MOV            DL, LocalX
	MOV            DH, LocalY
	
	ClearScreen
                            
DrawLeftPaddle:                            
	MoveCursor     DL,DH
	DisplayChar    Paddle
	DEC DH            
	LOOP DrawLeftPaddle

; Prepare to draw the right paddle		
	MOV CX, 3D                        
	MOV            DL, OtherX
	MOV            DH, OtherY 

DrawRightPaddle:                            
	MoveCursor     DL,DH
	DisplayChar    Paddle
	DEC DH
	LOOP DrawRightPaddle             
						
; Draw the ball at its current position
	MOV DL, BallCurrX
	MOV DH, BallCurrY			
	MoveCursor DL,DH
	DisplayChar Ball

	RET
Draw ENDP

; End file and tell the assembler what the main subroutine is
    END MAIN 

