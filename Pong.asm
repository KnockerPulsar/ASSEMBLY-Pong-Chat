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
            PUSHALL
            mov ax,0600h
            mov bh,07
            mov cx,0
            mov dx,184FH
            int 10h
            POPALL
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

; An alternative to POPA which doesn't work in MASM/TASM
; Can be changed to include other registers if necessary.
POPALL MACRO 
	POP DX
	POP CX
	POP BX
	POP AX
ENDM

PUSHALL MACRO 
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
ENDM

.Model SMALL
.STACK 64

.DATA
	 ; Variables here
	 PlayerInitialRow     DB  0CH
	 LeftPlayerIitialCol  DB  2H
	 RightPlayerIitialCol DB  77D
	 PlayerSymbol         EQU "#"
	 BallInititLoc        DB  3D, 11D
     BulletSymbol EQU "O"                 
     PLAYER_WIDTH EQU 3
	 PLAYER_HEIGHT EQU 2

	 ; Player DB xPos, yPos, bullets, bulletsInArena
	 PlayerOne DB 02, 12, 3, 0
	 PlayerTwo DB 77, 12, 3, 0
     
	 NumBullets EQU 2 ; Change when adding bounce bullets
	 BulletDataSize EQU 5 ; How many bytes does a single bullet occupy
	 Bullets LABEL BYTE
	 ; Bullet DB xPos, yPos, xVel, yVel, active
	 ; Can split the velocity of each bullet into a seperate "object", having it embedded is cleaner though
	 ; Player1 bullets
	 P1Bullet1 DB 40,12, 2,0, 0
	 ; Bounce bullets here

	 ; Player2 bullets
	 P2Bullet1 DB 40,12, -2,0, 0
	 ; Bounce bullets here
     
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
		 CALL GetPlayerInput      

		; Game logic 
		 CALL Logic
		 
		; Draw The Player at their proper position, derived from player input
		 CALL Draw
		 
	     ; TODO: Move ball
	     ; Might get changed depending on the game
 
		 Loop GameLoop

	Exit:
		; Exits the program
		 MOV            AH, 4CH
		 INT            21H

MAIN ENDP

; The main logic of the game
Logic PROC
	; Checking for bullet collisions with players
	; First, check all bullets over player 1
	; A similar loop to the drawing one
	; If the bullet hit player one
	; Call a procedure to incement score and reset level
	; Then do the same for player 2

	; DL carries the X coordinate (Columns), DH carries the Y coordinate (Rows)
	LEA SI, PlayerOne
	MOV DL, BYTE PTR [SI]                    
	MOV CL , PLAYER_WIDTH

; Need to loop every bullet over all of the player's blocks
; Must check of course that the bullet is active
; We'll store the bullet's x and y in BL and BH respectively
	MOV CH, 0
	MOV CL, NumBullets
	LEA SI, PlayerOne
	LEA DI, P1Bullet1
BulletPlayer1Col:
	MOV AL, BYTE PTR [DI + 4]
	CMP AL, 1
	JNZ InactiveBullet1
	MOV BL, BYTE PTR [DI]
	MOV BH, BYTE PTR [DI + 1]
	; The outer loop loops over the x axis of the player
	CheckPlayer1CollisionsX:   
		MOV CH , PLAYER_HEIGHT
		MOV DH , BYTE PTR [SI + 1]
		; The inner loop loops over the y axis of the player (bottom up)
		CheckPlayer1CollisionsY:
			; The player's xPos and yPos are stored in DL,DH respectively
			CMP BL,DL
			JNZ NoP1Hit ; If the x coordinate doesn't match, bail
			CMP BH,DH
			JNZ NoP1Hit ; If the y coordinate doesn't match, bail

			; If both the x and y coordiantes match, it's a hit!
			; I'll cause it to abort further checking for now until we get a proper score update procedure
			JMP EndPlayer1Checks

			; Checks here
			NoP1Hit:
			DEC DH    
			DEC CH
			CMP CH, 0        
			JNZ CheckPlayer1CollisionsY
		DEC DL
		DEC CL
		CMP CL, 0     
		JNZ CheckPlayer1CollisionsX

		ADD SI, BulletDataSize
		LOOP BulletPlayer1Col
		InactiveBullet1:
		EndPlayer1Checks:

; Prepare to check the right Player		
	LEA SI, PlayerTwo
	MOV DL, BYTE PTR [SI]                     
	MOV CL , PLAYER_WIDTH

	MOV CH, 0
	MOV CL, NumBullets
	LEA SI, PlayerOne
	LEA DI, P1Bullet1
BulletPlayer2Col:
	MOV AL, BYTE PTR [DI + 4]
	CMP AL, 1
	JNZ InactiveBullet2
	MOV BL, BYTE PTR [DI]
	MOV BH, BYTE PTR [DI + 1]
	; The outer loop loops over the x axis of the player
	CheckPlayer2CollisionsX:   
		MOV CH , PLAYER_HEIGHT
		MOV DH , BYTE PTR [SI + 1]
		; The inner loop loops over the y axis of the player (bottom up)
		CheckPlayer2CollisionsY:
			; The player's xPos and yPos are stored in DL,DH respectively
			CMP BL,DL
			JNZ NoP2Hit ; If the x coordinate doesn't match, bail
			CMP BH,DH
			JNZ NoP2Hit ; If the y coordinate doesn't match, bail

			; If both the x and y coordiantes match, it's a hit!
			; I'll cause it to abort further checking for now until we get a proper score update procedure
			JMP EndPlayer2Checks

			; Checks here
			NoP2Hit:
			DEC DH    
			DEC CH
			CMP CH, 0        
			JNZ CheckPlayer2CollisionsY
		DEC DL
		DEC CL
		CMP CL, 0     
		JNZ CheckPlayer2CollisionsX

		ADD SI, BulletDataSize
		LOOP BulletPlayer2Col
		InactiveBullet2:
		EndPlayer2Checks:


; Now to move the bullets
	MOV CH, 0
	MOV CL, NumBullets
	LEA SI, P1Bullet1
MoveBullets:
	MOV AL, BYTE PTR [SI + 4]	; Get the current bullet's active flag
	CMP AL, 1					; Compare it to 1
	JNZ DontMove				; If the flag is not 1 (ie. inactive), skip the drawing
	MOV DL, BYTE PTR [SI]		; Current bullet xPos
	MOV DH, BYTE PTR [SI + 1]   ; Current bullet yPos

	CMP DL, 0
	JL DeactivateBullet
	CMP DL, 80
	JG DeactivateBullet

	CMP DH, 0
	JL DeactivateBullet
	CMP DH, 25
	JG DeactivateBullet

	JMP DontDeactivateBullet

	DeactivateBullet:
	MOV BYTE PTR [SI + 4],0 ; Setting the active flag to false
	MOV BYTE PTR [SI], 40   ; Putting the inactive bullet in the middle
	MOV BYTE PTR [SI + 1], 12 
	JMP DontMove

	DontDeactivateBullet:
	MOV BL, BYTE PTR [SI + 2]	; Current bullet xVel
	MOV BH, BYTE PTR [SI + 3]	; Current bullet yVel

	ADD DL, BL
	ADD DH, BH

	; Might need some way to add a delay/ do this ever x*100 cycles
	MOV BYTE PTR [SI], DL		; Moving the bullet on the x
	MOV BYTE PTR [SI + 1], DH   ; Moving the bullet on the y
	

	DontMove:
		ADD SI, BulletDataSize
		LOOP MoveBullets

	MOV BH,0 ; For some reason, without this line, the drawing goes haywire

	RET
Logic ENDP

Draw PROC
	; Draw left Player first
	; Move the cursor to row 0AH, column 2, output "#"
	; Row 0BH, column 2, output
	; Row 0CH, column 2, output
	; Then the right Player
	; Same as the left Player but move to row 77D   

	
	; Flicker solution found at: https://stackoverflow.com/questions/43794402/avoid-blinking-flickering-when-drawing-graphics-in-8086-real-mode
	; Comment this when using emu8086
	CALL waitForNewVR
	ClearScreen
	
	; DL carries the X coordinate (Columns), DH carries the Y coordinate (Rows)
	LEA SI, PlayerOne
	MOV DL, BYTE PTR [SI]                    
	MOV CL , PLAYER_WIDTH
DrawLeftPlayerX:   
	MOV CH , PLAYER_HEIGHT
	MOV DH , BYTE PTR [SI + 1]
	DrawLeftPlayerY:
		MoveCursor     DL,DH
		DisplayChar    PlayerSymbol
		DEC DH    
		DEC CH
		CMP CH, 0        
		JNZ DrawLeftPlayerY
	DEC DL
	DEC CL
	CMP CL, 0     
	JNZ DrawLeftPlayerX

; Prepare to draw the right Player		
	LEA SI, PlayerTwo
	MOV DL, BYTE PTR [SI]                     
	MOV CL , PLAYER_WIDTH

DrawRightPlayerX:   
	MOV CH , PLAYER_HEIGHT
	MOV DH , BYTE PTR [SI + 1]
	DrawRightPlayerY:
		MoveCursor     DL,DH
		DisplayChar    PlayerSymbol
		DEC DH    
		DEC CH
		CMP CH, 0        
		JNZ DrawRightPlayerY
	INC DL
	DEC CL
	CMP CL, 0     
	JNZ DrawRightPlayerX

	; Looping over all bullets
	MOV CH, 0
	MOV CL, NumBullets
	LEA SI, P1Bullet1
DrawBullets:
	MOV AL, BYTE PTR [SI + 4]	; Get the current bullet's active flag
	CMP AL, 1					; Compare it to 1 
	JNZ DontDraw				; If the flag is not 1 (ie. inactive), skip the drawing
	; If the bullet is to be drawn, we need to move the cursor to its x and y positions
	; I'll store them in DL,DH 
	MOV DL, BYTE PTR [SI]
	MOV DH, BYTE PTR [SI + 1]
	MoveCursor DL, DH
	DisplayChar BulletSymbol
	
	DontDraw:
		ADD SI, BulletDataSize
		LOOP DrawBullets
		
	
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
; Temporary solution until we get paging figured out
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

; Gets input for both players locally
GetPlayerInput PROC
    
	; TODO: BOUND CHECKING SO THAT THE SLIDERS DON'T GO OFF SCREEN
	; Checking input for P1
     PUSH CX
	 LEA SI, PlayerOne
     MOV CL, BYTE PTR [SI + 1]
     MOV AH,1
     INT 16H    

	; Checks if the user pressed F4
	; If so, goes back to the main menu
	; TODO: SHOW THE SCORE FOR 5 SECONDS THEN GO TO THE MAIN MENU/OPTIONS MENU
	; Note that choosing to play a game again after leaving the first one picks up exactly where the first left off
	; Might need to keep an array of initial values to re-initialize the game again.
	 CMP AH, 62D
	; So, you might wonder, why did I do this peculiar jump
	; Well, it seems that conditional jumps (JNZ, JG, etc...) have less range than unconditional jumps (JMP)
	; Since I converted the macro to a procedure and made it longer, the distance between the below jump and the label has grown
	; Check this for more information: https://stackoverflow.com/questions/39427980/relative-jump-out-of-range-by
	 JNZ SKIP_JUMP
	 JMP OptionsScreen
	SKIP_JUMP:
	; Checks if player1 pressed W
	; If so, decrements the y position of the Player (since the y axis points down)
     CMP AH, 17D
     JZ MoveUpP1
    
	; Same as the up check but increments the y position
     CMP AH, 31D
     JZ MoveDownP1
     JMP EndMoveCheckP1
     
MoveUpP1:          
       DEC CL
       JMP EndMoveCheckP1
MoveDownP1:            
       INC CL                  
       JMP EndMoveCheckP1

EndMoveCheckP1:
       MOV BYTE PTR [SI + 1], CL

	; If P1 pressed D, check if they have any bullets in the arena
	; If so, ignore the input
	; Otherwise, CALL Player1Shoot
	CMP AH, 32D
	JNZ EndShootCheckP1 ; If the player didn't press D, don't check for bullets

	LEA SI, PlayerOne
	MOV AL, BYTE PTR [SI + 3]
	CMP AL, 0
	JNZ EndShootCheckP1 ; If the player has any bullets in the arena, don't shoot any more bullets
	CALL Player1Shoot
	EndShootCheckP1:
; ============================================================================================================================================;
	
	; Checking input for P2
	 LEA SI, PlayerTwo
     MOV CL, BYTE PTR [SI + 1]
     MOV AH,1
     INT 16H    

	; TODO: Check for player2 shooting, check if the player has any bullets in the arena
	; TODO: CHECK IF THE OTHER USER PRESSED F4

	; Checks if player2 pressed up arrow
	; If so, decrements the y position of the Player (since the y axis points down)
     CMP AH, 72D
     JZ MoveUpP2
    
	; Same as the up check but increments the y position
     CMP AH, 80D
     JZ MoveDownP2

     JMP EndInputP2
     
MoveUpP2:          
       DEC CL
       JMP EndInputP2
MoveDownP2:            
       INC CL                  
       JMP EndInputP2

EndInputP2:
       MOV BYTE PTR [SI + 1], CL
       POP CX  


	; If P2 pressed the left arrow, check if they have any bullets in the arena
	; If so, ignore the input
	; Otherwise, CALL Player2Shoot
	CMP AH, 75D
	JNZ EndShootCheckP2 ; If the player didn't press D, don't check for bullets

	LEA SI, PlayerTwo
	MOV AL, BYTE PTR [SI + 3]
	CMP AL, 0
	JNZ EndShootCheckP2 ; If the player has any bullets in the arena, don't shoot any more bullets
	CALL Player2Shoot

	EndShootCheckP2:
	       
       FlushKeyBuffer
	   RET
ENDP              

; If so, sets the bullet's active flag to 1, changes the location so it's right in front of the player
; Otherwise, ignore the user's input
Player1Shoot PROC
	; Will be used to get the xPos and yPos of P1
	LEA SI, PlayerOne
	; Will be used to spawn the bullet in front of the player and set it as active
	LEA DI, P1Bullet1

	; AL = P1.xPos, AH = P1.yPos
	MOV AL, BYTE PTR [SI]
	MOV AH, BYTE PTR [SI + 1]
	; Incrementing AL so that it's now in front of the player
	INC AL

	MOV BYTE PTR [DI],AL
	MOV BYTE PTR [DI + 1], AH
	MOV BYTE PTR [DI + 4], 1

	RET
Player1Shoot ENDP
Player2Shoot PROC
	; Will be used to get the xPos and yPos of P1
	LEA SI, PlayerTwo
	; Will be used to spawn the bullet in front of the player and set it as active
	LEA DI, P2Bullet1

	; AL = P1.xPos, AH = P1.yPos
	MOV AL, BYTE PTR [SI]
	MOV AH, BYTE PTR [SI + 1]
	; Decrementing AL so that it's now in front of the player
	DEC AL

	MOV BYTE PTR [DI],AL
	MOV BYTE PTR [DI + 1], AH
	MOV BYTE PTR [DI + 4], 1

	RET
Player2Shoot ENDP

; End file and tell the assembler what the main subroutine is
    END MAIN 

