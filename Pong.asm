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
    
	; TODO: BOUND CHECKING SO THAT THE SLIDERS DON'T GO OFF SCREEN
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
	 
	 Block_Nums DB 6,4,1,9,6,7,3,7,7,8,8,7,9,4,1,5,3,8,5,5,6,7,7,5,1
	 Chars DB '0','1','2','3','4','5','6','7','8','9',"10"


	BlockSymbol EQU 178D

	; xPos, yPos, height
	 Block1 DB 20d, 12D, 8D
	 Block2 DB 60d, 24D, 4D

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

	
	; Flicker solution found at: https://stackoverflow.com/questions/43794402/avoid-blinking-flickering-when-drawing-graphics-in-8086-real-mode
	CALL waitForNewVR
	
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


; Preparing to draw the characters/points
; First, must point at the start or end of Block_Nums
	 MOV SI, OFFSET Block_Nums	
	 MOV DI,3D            ; Going to draw 3 columns, so DI = 3
	 MOV DL, 38D          ; Starting at column 38

DrawColumns:
	 MOV CX,0             ; Just making sure that CH doesn't have any leftover bits from other operations
	 MOV CL, 24D          ; Starting from the very bottom, will draw from the bottom up
	 MOV BX, OFFSET chars ; Setting up BX for XLAT
	
	DrawColumn:
		 MoveCursor DL ,CL    ; START FROM COL 38, ROW 25 DRAW ASCII 178 TILL THE TOP OF THE ROW
 
		 MOV AL,BYTE PTR [SI] ; Moving the the current byte/number SI is pointing at into AL
		 XLAT				 ; Converting the number into its respective character
		 DisplayChar AL		 
 
		 INC SI               ; Going forward one byte
 
		 CMP SI, OFFSET Chars   	  ; Checking if SI has reached the end of the numbers array
		 JNZ NOT_ZERO			  ; If not, continue as usual
 
		 MOV SI, OFFSET Block_Nums ; If so, reset SI to the start of the array, now it points at the first number
 
		 NOT_ZERO:				  
		 DEC CL					  ; Going up one row
		 CMP CL, 0FFH			  ; Checking if the The full column has been drawn (24 -> 0 and then an underflow)
		 JNZ DrawColumn				
 
	 INC DL						  ; Next clumn
	 DEC DI						  ; Just loop stuff
	 CMP DI, 0					  ; Just loop stuff 2: electric boogalo
	 JNZ DrawColumns  			  ; Looping on the 


; Preparing to draw the first obstacle
; Remember, The first byte is the xPos, the second byte is yPos, and the third byte is the height of the obstacle
	 MOV SI, OFFSET Block1		  	; Points at the first byte
	 MOV CX,0						; Clearing CX
	 MOV CL, BYTE PTR [SI + 2]	    ; Putting the height inside CL
 
	 MOV DL, BYTE PTR [SI]			; Putting the xPos in DL
	 MOV DH, BYTE PTR [SI] + 1		; Putting the yPos in DH

; Drawing the first block (Bottom up)
DrawBlockOne:
	 MoveCursor DL,DH				
	 DisplayChar BlockSymbol
	 DEC DH
	 LOOP DrawBlockOne

; Preparing to draw the second obstacle
; Remember, The first byte is the xPos, the second byte is yPos, and the third byte is the height of the obstacle
	 MOV SI, OFFSET Block2			; Points at the first byte
	 MOV CX,0						; Clearing CX
	 MOV CL, BYTE PTR [SI + 2]		; Putting the height inside CL
 
	 MOV DL, BYTE PTR [SI]			; Putting the xPos in DL
	 MOV DH, BYTE PTR [SI] + 1		; Putting the yPos in DH

; Drawing the second block (Bottom up)
DrawBlockTwo:
	 MoveCursor DL,DH
	 DisplayChar BlockSymbol
	 DEC DH
	 LOOP DrawBlockTwo

	RET
Draw ENDP

; VR stands for "Vertical Refresh"
waitForNewVR PROC
 	 MOV DX, 3DAH
 
	;Wait for bit 3 to be zero (not in VR).
	;We want to detect a 0->1 transition.
	_WAITFOREND:
		IN AL, DX
		TEST AL, 08H
		JNZ _WAITFOREND

	;WAIT FOR BIT 3 TO BE ONE (IN VR)
	_WAITFORNEW:
		IN AL, DX
		TEST AL, 08H
		JZ _WAITFORNEW
	 

 	 RET
 	 waitForNewVR ENDP

; End file and tell the assembler what the main subroutine is
    END MAIN 

