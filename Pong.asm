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
 
	 mov  ah,0
	 mov  al,03h
	 int  10h
 
	 POP  AX

ENDM         
ClearScreen MACRO    
	 PUSHALL
	 MOV AH, 0
	 MOV AL, 03h
	 int 10h
	 ; Code for Hiding the blinking Text cursor
	 ; Looks bad when drawing the game every cycle
	 MOV CH, 20H 
	 MOV AH, 01H
	 INT 10H
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
HideCursor MACRO 
	 mov ch, 32
 	 mov ah, 1
 	 int 10h 
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
.STACK 100

.DATA
	; Player variables
	; =============================================================================================
	 PLAYER_DATA_SIZE     	EQU 4 ; How many bytes does one player occupy in memory
	 PlayerInitialRow     	DB  08H
	 LeftPlayerIitialCol  	DB  2H
	 RightPlayerIitialCol 	DB  77D
	 PlayerSymbol         	EQU "#"
     PLAYER_WIDTH   		EQU 1
	 PLAYER_HEIGHT  		EQU 3
	 PlayerOneScore 		DB 30H ; Player Scores
	 PlayerTwoScore 		DB 30H

	 ; Player DB xPos, yPos, bullets, bulletsInArena
	 PlayerOne 				DB 02, 12, 3, 0
	 PlayerTwo 				DB 77, 12, 3, 0

	; Bullet data 
	; =============================================================================================
	 BulletDataSize 		EQU 5 ; How many bytes does a single bullet occupy
	 NumBullets 			EQU 3 ; Change when adding bounce bullets
	 BallInititLoc      	DB  3D, 11D
     BulletSymbol 			EQU "O"                 
	 
	 ; Bullet DB xPos, yPos, xVel, yVel, active
	 ; Player1 bullets
	 P1Bullet1 				DB 40, 12, 2, 0, 0
     
	 ; Player2 bullets
	 P2Bullet1 				DB 40, 12, -2, 0, 0
	 ;DB '$'				; we use it as indicator for the end of the bullets
		 
	 ;One of the following is used when a bullet hits a stonepile (xPos, yPos, xVel, yVel, active)
	 ExtraBullet1 			DB 40, 12, 2, 0, 0
	 ;ExtraBullet2			DB 40, 12, -2, 0, 0
	 DB '$'
	 ExtraNum 				EQU 1
	; Cactus data
	; =============================================================================================
	; xPos, yPos pairs
	 CactusNum    			EQU 2 
	 Cactus       			DB 32d,11d,11d,5d,'$'
	 CactusSymbol 			EQU 206
     
	; Barrel data
	; =============================================================================================
	; xPos, yPos pairs Will be changed later to -> xPos, yPos, Height
	 BarrelNum 				EQU 2
	 Barrel 				DB 40d,4d,50d,1d,'$'
	 ;Barrel 				DB 40d,4d,2d,50d,1d,3d,'$' ->(xPos, yPos, Height)
	 BarrelSymbol 			EQU 178

	; StonePile data
	; =============================================================================================
	; xPos, yPos pairs
	 StonePileNum 			EQU 2
	 StonePile 				DB 60d,8d,12d,10d,'$'
	 StonePileSymbol 		EQU 234
	 
	; Displayed messages
	; =============================================================================================
	 Welc          			DB 'Please Enter Your Name:', 13, 10, '$'
	 Hel 		   			DB 'Please Enter any key to continue','$'
	 Choices       			DB '* To start chatting press F1', 13,10,13,10, 09,09,09, '* To start game press F2', 13,10,13,10, 09,09,09,'* To end the program press ESC',13,10, '$'
	 Info          			DB 13,10,'- You send a chat invitaion to ','$'
	 userName      			DB 16,?, 16 DUP('$')
	 userNameScore 			DB "'s Score : ", '$'
	 userName2     			DB "Abdelrahman", '$' ; Fixed at Abdelrahman for now but should be whatever User types in chatting screen
	 p1Score 	   			DB "Tarek's Score : ", '$'
	 p2Score 	   			DB "Abdelrahman's Score :", '$'
	 endGame 	   			DB "- To end the game with Abdelrahman, Press F4", '$'
	 endGame1 	   			DB "- To end the game with ", '$'
	 endGame2 	   			DB ", Press F4", '$'
	 WinCondition  			DB " Wins with score: " , '$'
	 WinScore 	   			DB " To ", '$'
	 Test1         			DB "Test", '$'
	 RoundSystemTime		DB ?				   	; Storing only seconds to detect when 1 second has passed		
	 RoundTime 				DB 34H,35H
	 DefaultTime			DB 34H,35H

	; Other variables
	; ============================================================================================= 
	 authentication 		DB 0
	 exiting 				DB 0
	 GetInput				DB 1					; If it's 1 players can move and and shoot. If it's 0, they can't

	; Unused data
	; =============================================================================================
	; xPos, yPos, height
	 BlockSymbol   			EQU 178D
	 Block1					DB 20d, 12D, 8D
	 Block2					DB 60d, 10D, 4D
			
	;  DynamicBlock1 			DB 1
	;  DynamicBlock2 			DB -1

.CODE
MAIN PROC FAR
	; Initializing DS
	 MOV            AX, @DATA
	 MOV            DS, AX
 
	 LEA SI, exiting
	 MOV AH, 1
	 CMP [SI], AH
	 JZ OptionsWindow

	; Main Screen
	Home:
		 ClearScreen 												; Clearn the screen of DOSBox stuff
		 
		; Display welcome message in the middle of the main screen
		 MoveCursor 0AH, 0AH
		 DisplayMessage Welc
		 
		;Get user's name
		 MoveCursor 0CH, 0CH
 
		 MOV 			AH, 0Ah
		 MOV 			DX, OFFSET userName
		 INT 21h			; read username
; ============================================================================================
;									username Validations
; ============================================================================================

		 CMP userName+2, 41h 					;less than A
		 JB Home 
		 
		 CMP userName+2, 5Ah
		 JBE Welcome 							; if in range A:Z
		 		
	; If greater than A and not in range A:Z, check for a:z
	Check:
		 CMP userName+2,61h						; less than a
		 JB Home 
		 CMP userName+2, 7Ah
		 JA Home  								; If not a letter, clear

; ============================================================================================
;										Options Window
; ============================================================================================

	Welcome:
		 MoveCursor 0AH, 0DH
		 DisplayMessage Hel						; Display "press any key to continue" message
 
		;Get any key as an indicator to continue
		 MOV 			AH, 0
		 INT 16h

	OptionsWindow:

		 MOV DI, OFFSET exiting					; reset exiting flag to 0
		 MOV BH, 0
		 MOV [DI],BH 
		 ClearScreen
		 MoveCursor 18H, 0AH
		 
		 DisplayMessage Choices					; Display Options
				
	;------------------------------Get Input and validate it--------------------------------------;
	CHS:
		 MOV 			AH, 0
		 INT 16h
		
		 CMP AH, 1   		       	   ; Check for ESC
		 JNZ NotExit
		 JMP Exit

		 NotExit:
		 	CMP AH, 3Ch 		       ; Check for F2
		 	JNZ NotF2
		 	CALL ResetRound            ; Reset the player positions
		 	MOV PlayerOneScore, 30H    ; Reset both players' scores
		 	MOV PlayerTwoScore, 30H
		 	JMP GameLoop 

		 NotF2:
		 	CMP AH, 3Bh 		       ; Check for F1
		 	JNZ CHS 			       ; if the pressed key not an option, loop till it is

;=================================================================================================
;										 Chatting Module 
;=================================================================================================

	Chatting:		
		;To be Continued "D IS THAT AN EMOJI!?
		;Move cursor to the footer
		 MoveCursor 00H, 15H
		
	; Loadig the character, number of loops and preparing the interrupt 
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

		; Check if Any player Won
		 MOV AL, PlayerOneScore
		 MOV AH, PlayerTwoScore
		 CMP AL, 35H							; Check if PlayerOneScore is 5
		 JNZ CheckPlayer2Score					; If it is, Call WinScreen
		 CALL WinScreen
		 JMP OptionsWindow
		 JMP Procedures
		 CheckPlayer2Score:
		 CMP AH, 35H							; Check if PlayerTwoScore is 5
		 JNZ CheckRoundTime						; If it is, call Winscreen
		 CALL WinScreen
		 JMP OptionsWindow

	CheckRoundTIme:

		 ; Check if Round time is 0
		 LEA SI, RoundTime						; RoundTime is the time counter that changes on the screen
		 CMP BYTE PTR [SI], 30H					; stored in format [Tens], [Units]. If both Tens and Units are zero, counter is 00
		 JNZ CheckRound
		 CMP BYTE PTR [SI + 1], 30H
		 JNZ CheckRound							; If the current round timer isn't zero, don't Start a new round
		 MOV AL, GetInput						; GetInput is a flag to check if players can move and shoot or not
		 CMP AL, 0								; If round timer is zero and no inputs are allowed, This is the end of the countdown 
		 JZ DontResetRound						; That is before the start of a new round, and therefore, don't reset to a new round
		 CALL ResetRound						; Otherwise, if GetInput is 1 and round timer is zero, that means that the current round
		 JMP CheckRound							; just ended and ResetRound (i.e. Start a new Round)

		DontResetRound:
			LEA DI, DefaultTime					; Stores the default round time so that we can reset RoundTime
			MOV AL, BYTE PTR [DI]
			MOV BYTE PTR [SI], AL
			MOV AL, BYTE PTR[DI + 1]
			MOV BYTE PTR [SI + 1], AL			; Move the Default time in the current round timer
			MOV GetInput, 1						; Allow player inputs
			FlushKeyBuffer						; Flush the key buffer for any button presses when inputs weren't allowed
			JMP Procedures
		
		CheckRound:
			MOV AL, GetInput					
			CMP AL, 0
			JZ DontGetInput

	Procedures:

		 CALL GetPlayerInput      				 ;Get player input,  Currently only getting local player input

	DontGetInput:
		 CALL Logic

 		 CALL StaticLayout
 		 
		 CALL Draw								; Draw The Player at their proper position, derived from player input

	;-------------------------------------- Check if the player pressed F4 ---------------------------------------;
	
		 LEA SI, exiting
		 MOV BH, [SI]
		 CMP BH, 1 
		 JMP GameLoop		; if not continue the game
		 				
		 JMP OptionsWindow	; else return to options window

	Exit:
		; Exits the program
		 MOV            AH, 4CH
		 INT            21H

MAIN ENDP

CactusColls PROC
; =================================================================================================
;  Cactus Collisions Checks
; =================================================================================================

	 LEA DI, P1Bullet1			 							; Starting with bullet 1
	 LEA SI, Cactus 										; To Iterate on the cactus objects to check collisions ,  [SI] and [SI+1] are xPos and yPos of the cactus

CactusCollisions:
	forEachBullet:
		 MOV CH , 0 				  						; Will be used for jumping when checking x+1 and x
		 MOV AL, BYTE PTR [DI + 4] 							; Carries the current bullet's active flag
		 CMP AL, 1				  							; Checking if the bullet is active
		 JNZ InactiveBullet		  							; If not, skip the collision check
	 
		 MOV BL, BYTE PTR [DI]	  							; Otherwise, load xPos and yPos into BL and BH
		 MOV BH, BYTE PTR [DI + 1]
	 
		 MOV CL, BYTE PTR [SI]								; Stores the cactus's xPos
		 CMP BL, CL											; Check if the bullet xPos is the same as a cactus xPos
		 JZ ChecksStart										; If the bullet's xPos and the cactus's xPos match, got a hit, don't increment CH
 
		 INC CL												; x = x+1
		 CMP BL,CL											; If the bullet's xPos = cactus's xPos + 1, got a hit, don't increment CH
		 JZ ChecksStart
 
		 JNZ nextBullet										; If the bullet's xPos doesn't match neither the cactus's Xpos or Xpos + 1, check next bullet

ChecksStart:												; if a bullet hits a cactus	
		 MOV AL, [SI+1]										; get yPos of cactus
		 CMP BH, AL											; check yPos of cactus with yPos of bullet
		 JZ UpperPart										; if equal , the bullet hit the upper part , so reflect the bullet with angle 30
		 JL nextBullet										; if the bullet passed above the cactus, then no need to further ckecks
		 INC AL												; increase yPos of cactus to get the middle part
		 CMP BH, AL											; if the bullet hit the middle part
		 JZ MiddlePart										; reflect it with 0 angle
		 INC AL												; increase yPos to get the lower part
		 CMP BH, AL					
		 JZ LowerPart										; if equal , the bullet hit the lower part and should be reflected with 60 angle
		 JG nextBullet										; if not, the bullet didn't hit the cactus >> go check the next bullet

;       ---------------------------- Cactus Parts Logic when hit -----------------------------------    ;
UpperPart:
		 MOV BH, [DI+2]
		 CMP BH, 0 											; if the bullet was going from right to left => means -ve xVel
		 JL Increase
		 MOV BH, -2											; else if the bullet was going from left to right => means +ve xVel
		 JMP MOVE
	Increase:												; the bullet is going from right to left, we change its direction to be north-east
		 MOV BH, 2											
		 MOV [DI+2], BH										; xVel is +ve
		 MOV BH, -2											
		 MOV [DI +3], BH									; yVel is -ve
		 JMP nextBullet
	MOVE:													; the bullet is going from left to right, we change its direction to be north-west
		 MOV [DI+2], BH										; xVel is -ve
		 MOV [DI+3], BH										; yVel is -ve
		 JMP nextBullet

MiddlePart: 										
		MOV BH, 0
		SUB BH, BYTE PTR [DI+2]								; inverse the sign of xVel to make the bullet go in the opposite direction
		MOV [DI+2], BH
		JMP nextBullet

LowerPart:
		MOV BH, [DI+2]
		CMP BH, 0											; if the bullet was going from right to left => means -ve xVel
		JL Increase2
															; else if the bullet was going from left to right => means +ve xVel
		MOV BH, -2											; the bullet is going from left to right, we change its direction to be south-west
		MOV [DI+2], BH										; xVel is -ve
		MOV BH, 2
		MOV [DI+3], BH										; yVel is +ve
		JMP nextBullet
	Increase2:												; the bullet is going from right to left, we change its direction to be south-east
		MOV BH, 2
		MOV [DI+2], BH										; xVel is +ve
		MOV [DI+3], BH										; yVel is +ve
		JMP nextBullet

	InactiveBullet:											; If the current bullet is inactive, check the next one
		nextBullet:					
			ADD DI, BulletDataSize							; Loads the next bullet's data
			MOV BL, [DI]									
			CMP BL, '$'										
			JZ ResetBullet									; If we finished checking all bullets, reset the current bullet, check the next cactus
			JMP forEachBullet								; else, continue with the current cactus

	ResetBullet:					
		LEA DI, P1Bullet1									; reset the pointer to the first bullet

	NextCactus:
		ADD SI, 2
		MOV BL, [SI]
		CMP BL, '$'											; if we finish checking for all cactuses
		JZ FinishCactusColl										; stop iterating 
		JMP CactusCollisions								; else, continue with the next cactus
	
	FinishCactusColl: RET
	
CactusColls ENDP

; TODO: there's a bug where if a bullet moves just below or above a barrel, its speed still gets reduced
BarrelColls PROC
; =================================================================================================
;  Barrel Collisions Checks
; =================================================================================================

	 LEA SI, Barrel 										; To Iterate on the barrel objects to check collisions ,  [SI] and [SI+1] are xPos and yPos of the top of the barrel

StartFromBullet1:
	 LEA DI, P1Bullet1			 							; Starting with bullet 1
BarrelCollisions:
		 MOV BL, BYTE PTR [DI + 4] 							; Carries the current bullet's active flag
		 CMP BL, 1				  							; Checking if the bullet is active
		 JNZ GetBullet			  							; If not, skip the collision check

		 MOV BL, BYTE PTR [DI+2]							;If the xVelo = 1, then do nothing and get the next bullet
		 CMP BL, 1
		 JZ GetBullet
		 CMP BL, -1											;If the xVelo = -1, then do nothing and get the next bullet
		 JZ GetBullet

		 ;General Case: Collision occurs if xPos Bullet <= xPos Barrel <= xPos + xVel Bullet && yPos Bullet <= yPos Barrel <= yPos + yVel Bullet
		 ;For now implement the case where the bullet is straight
		 MOV BL, BYTE PTR [DI]								;Get the xPos of the bullet
		 MOV BH, BYTE PTR [SI]								;Get the xPos of the barrel
		 CMP BL,BH
		 JZ CheckYColli
		 INC BH
		 CMP BL,BH
		 JNZ GetBullet

	CheckYColli:
		 MOV BL, BYTE PTR [DI+1]
		 MOV BH, BYTE PTR [SI+1]
		 CMP BL,BH
		 JL GetBullet
		 ADD BH, 2											; 2 here is the height can be inputed as a variable in the barrel's data instead
		 ;MOV DL, BYTE PTR[SI+2]
		 ;ADD BH, DL 											;In case of length variable
		 CMP BL,BH
		 JG GetBullet
;       ----------------------------Barrel Parts Logic when hit -----------------------------------    ;
		 MOV AL,  BYTE PTR [DI+2]
		 CMP AL,0											;Check if the xVel is negative to be able to divide it properly
		 JL NegativeSpeedx
		 MOV AH,0											;Make AX a positive number
		 JMP CalcX
	NegativeSpeedx:
		 MOV AH,0FFh										;Make AX a negative number
	CalcX:
		 MOV BL,2											;Decreasing the velocity to half its value
		 IDIV BL											;Used IDIV instead of DIV since the xVel is signed
		 MOV [DI+2], AL										;Assigning the xVel its new value

		 MOV AL,  BYTE PTR [DI+3]
		 CMP AL,0											;Check if the xVel is negative to be able to divide it properly
		 JL NegativeSpeedy
		 MOV AH,0											;Make AX a positive number
		 JMP CalcY
	NegativeSpeedy:
		 MOV AH,0FFh										;Make AX a negative number
	CalcY:
		 MOV BL,2											;Decreasing the velocity to half its value
		 IDIV BL											;Used IDIV instead of DIV since the xVel is signed
		 MOV [DI+3], AL										;Assigning the xVel its new value
		 GetBullet:					
		 ADD DI, BulletDataSize								; Loads the next bullet's data
		 MOV BL, [DI]									
		 CMP BL, '$'										
		 JZ NextBarrel										; If we finished checking all bullets, reset the current bullet, check the next barrel
		 JMP BarrelCollisions								; else, continue with the current barrel

	NextBarrel:
		 ADD SI, 2
		 ;ADD SI, 3 										;In case of length variable
		 MOV BL, [SI]
		 CMP BL, '$'										; if we finish checking for all barrel
		 JNZ StartFromBullet1								; stop iterating else, continue with the next barrel

BarrelColls ENDP

StonepileColls PROC
; =================================================================================================
;  StonePile Collisions Checks
; =================================================================================================

	 LEA SI, StonePile 										; To Iterate on the stonepile objects to check collisions ,  [SI] and [SI+1] are xPos and yPos of the stonepile

SPStartFromBullet1:
	 LEA DI, P1Bullet1			 							; Starting with bullet 1
	 MOV DL,0
StonepileCollisions:
		 INC DL
		 MOV BL, BYTE PTR [DI + 4] 							; Carries the current bullet's active flag
		 CMP BL, 1				  							; Checking if the bullet is active
		 JNZ SPGetBullet			  						; If not, skip the collision check
		 
		 ;General Case: Collision occurs if xPos Bullet <= xPos Stonepile <= xPos + xVel Bullet && yPos Bullet <= yPos Stonepile <= yPos + yVel Bullet
		 ;For now implement the case where the bullet is straight
		 MOV BL, BYTE PTR [DI]								;Get the xPos of the bullet
		 MOV BH, BYTE PTR [SI]								;Get the xPos of the stonepile
		 CMP BL,BH
		 JZ SPCheckYColli
		 INC BH												;This is correct assuming the velocity is either +2 or -2
		 CMP BL,BH
		 JNZ SPGetBullet

	SPCheckYColli:
		 MOV BL, BYTE PTR [DI+1]							;Get the yPos of the bullet
		 MOV BH, BYTE PTR [SI+1]							;Get the yPos of the stonepile
		 CMP BL,BH
		 JNZ SPGetBullet
;       ----------------------------Stonepile Parts Logic when hit -----------------------------------    ;
		 PUSH SI
		 LEA SI, ExtraBullet1								;To check wherther there's an available extra bullet.
	SPGetExtraBullet:
		 MOV CL, BYTE PTR [SI + 4]							; Carries the current bullet's active flag
		 CMP CL, 0				  							; Checking if the bullet is active
		 JZ ExecuteSPLogic			  						; If not, Check the next extra bullet
		 ADD SI, BulletDataSize								; Loads the next bullet's data
		 MOV CL, BYTE PTR [SI]									
		 CMP CL, '$'										
		 JNZ SPGetExtraBullet
		 POP SI
		 RET												;If no extra bullet available, skip making any effect

ExecuteSPLogic:

		 MOV CL, BYTE PTR [SI + 4]							; Carries the current bullet's active flag
		 MOV CL, 1				  							; Makes the bullet active
		 MOV [SI + 4], CL
		 
		 MOV CL, [SI]										;Setting the extra bullet's xPos the same as the original bullet
		 MOV BL, [DI]
		 MOV CL, BL
		 MOV [SI], CL
		 MOV CL, [SI+1]										;Setting the extra bullet's yPos the same as the original bullet
		 MOV BL, [DI+1]
		 MOV CL, BL
		 MOV [SI+1], CL

		 MOV CL, [SI+2]										;Setting the extra bullet's xVel the same as the original bullet
		 MOV BL, [DI+2]
		 MOV CL, BL
		 MOV [DI+3], CL										;Setting the yVel of the bullet the same as its xVel
		 MOV [SI+2], CL
		 NOT CL
		 INC CL
		 MOV [SI+3], CL										;Setting the extra bullet's yVel in the opposite direction to the original bullet
		 POP SI

	SPGetBullet:					
		 ADD DI, BulletDataSize								; Loads the next bullet's data
		 ;MOV BL, [DI]									
		 ;CMP BL, '$'		
		 CMP DL, NumBullets
		 JZ NextStonepile									; If we finished checking all bullets, reset the current bullet, check the next stonepile
		 JMP StonepileCollisions							; else, continue with the current stonepile

	NextStonepile:
		 ADD SI, 2
		 MOV BL, [SI]
		 CMP BL, '$'										; if we finish checking for all stonepiles
		 JZ FinishStonepileColl
		 JMP SPStartFromBullet1								; stop iterating else, continue with the next stonepile

	FinishStonepileColl:RET

StonepileColls ENDP

PlayerColls PROC	
;       ----------------------------- Players Logic when got hit -----------------------------------    ;
stopIterate:
	 LEA SI, PlayerOne
	 MOV DL, BYTE PTR [SI]									; DL carries the X coordinate (Columns) for P1
	 MOV DH , BYTE PTR [SI + 1]  							; DH carries the Y coordinate (Rows) for P1
	 MOV AH , PLAYER_HEIGHT
	 MOV CL, NumBullets
	 ADD CL, ExtraNum
	 MOV CH, 0
	 LEA DI, P1Bullet1										; Starting with bullet 1

; =================================================================================================
; Player 1 collision checks 
; =================================================================================================

BulletPlayer1Col:
	 MOV AL, BYTE PTR [DI + 4] 								; Carries the current bullet's active flag
	 CMP AL, 1				 								; Checking if the bullet is active
	 JNZ InactiveBullet1		  							; If not, skip the collision check
	 MOV BL, BYTE PTR [DI]	  								; Otherwise, load xPos and yPos into BL and BH
	 MOV BH, BYTE PTR [DI + 1]
 
	 CMP BL, 2				  								; Checking if the bullet is near P1
	 JA NotNearP1 			  								; If the bullet's xPos ≠ 2 (not near P1), check the next bullet, EDIT THIS IF WE NEED TO CHECK PAST THE FACE
	CheckPlayer1CollisionsY:
		;Check First Player Row
		 CMP BH, DH									
		 JNZ NoP1Hit 										; If the y coordinate doesn't match, bail
															; If both the x and y coordiantes match, it's a hit!
		 ADD PlayerTwoScore, 1 								; Add one to the other player's score
		 MOV BYTE PTR [DI + 4], 00D       					; Deactivate this bullet's active flag
															; Move the bullet to the middle
		 MOV BYTE PTR [DI], 40D
		 MOV BYTE PTR [DI + 1], 12D
		
		; -------------------------------- Scoring ---------------------------------- ;
		 CMP CL, 2        									; If CL = 2, it's bullet one belonging to player one
		 JNZ P2
		 DEC BYTE PTR [SI + 3]     							; So, decrement player one's bullet count in the arena
		 JMP EndDecrement1

		P2:
			 LEA SI, PlayerTwo 								; Otherwise, load P2 in SI , decrement his bullet count then load P1 is SI again 
			 DEC BYTE PTR [SI + 3]
			 LEA SI, PlayerOne

		EndDecrement1:
			 CALL ResetRound
			 JMP EndPlayer1Checks

		NoP1Hit:
			 DEC DH											; Going 1 block up
			 DEC AH   										; Decrement the number of player blocks left to check
			 CMP AH, 0        								; If no blocks are left, on to the next bullet
			 JNZ CheckPlayer1CollisionsY


	InactiveBullet1:										; If the current bullet is inactive, check the next one
		NotNearP1:											; Jump here if the bullet's xPos > 2
		 ADD DI, BulletDataSize								; Loads the next bullet's data
		 LOOP BulletPlayer1Col		
		 EndPlayer1Checks:									; Jump here if the player was hit, TEMPORARY

;=================================================================================================
; Player 2 colissions checks
;=================================================================================================

	 LEA SI, PlayerTwo
	 MOV DL, BYTE PTR [SI]									; DL carries the X coordinate (Columns) for P2
	 MOV DH , BYTE PTR [SI + 1]  							; DH carries the Y coordinate (Rows) for P2
	 MOV AH , PLAYER_HEIGHT
	 MOV CL, NumBullets
	 ADD CL, ExtraNum
	 MOV CH, 0
	 LEA DI, P1Bullet1										; Starting with bullet 1

BulletPlayer2Col:
	 MOV AL, BYTE PTR [DI + 4] 								; Carries the current bullet's active flag
	 CMP AL, 1				  								; Checking if the bullet is active
	 JNZ InactiveBullet2		  								; If not, skip the collision check
	 MOV BL, BYTE PTR [DI]	  								; Otherwise, load xPos and yPos into BL and BH
	 MOV BH, BYTE PTR [DI + 1]
	 CMP BL, 77				  								; Checking if the bullet is near P2
	 JB NotNearP2			  								; If the bullet's xPos ≠ 77 (not near P2), check the next bullet, EDIT THIS IF WE NEED TO CHECK PAST THE FACE
	
	CheckPlayer2CollisionsY:
		 CMP BH,DH											; Comparing Y coordinates
		 JNZ NoP2Hit 										; If the y coordinate doesn't match, bail
		 													; If both the x and y coordiantes match, it's a hit!
		 ADD PlayerOneScore, 1
		 MOV BYTE PTR [DI + 4], 0D 							; Setting the bullet's active flag to false
		 MOV BYTE PTR [DI], 40D    							; Putting the inactive bullet in the middle
		 MOV BYTE PTR [DI + 1], 12D 

;-------------------------------- Scoring ---------------------------------- ;
		 CMP CL, 2        									; If CL = 2, it's bullet one belonging to player one
		 JZ P1           									; decrement player one's bullet count
		 DEC BYTE PTR [SI + 3]     							; Otherwise, decrement player two's bullet count
		 JMP EndDecrement2
		P1:
			 LEA SI, PlayerOne 								; Otherwise, load P1 in SI , decrement his bullet count then load P2 is SI again 
			 DEC BYTE PTR [SI + 3]
			 LEA SI, PlayerTwo
		EndDecrement2:
			 CALL ResetRound
			 ; I'll cause it to abort further checking for now until we get a proper score update procedure
			 JMP EndPlayer2Checks

		; Checks here
		NoP2Hit:
			 DEC DH											; Going 1 block up
			 DEC AH   										; Decrement the number of player blocks left to check
			 CMP AH, 0        								; If no blocks are left, on to the next bullet
			 JNZ CheckPlayer2CollisionsY

	InactiveBullet2:										; If the current bullet is inactive, check the next one
		NotNearP2:											; Jump here if the bullet's xPos > 2
		 ADD DI, BulletDataSize								; Loads the next bullet's data
		 LOOP BulletPlayer2Col								; Loops to check the rest of the bullets with P2
	EndPlayer2Checks:										; Jump here if the player was hit, TEMPORARY

	RET
PlayerColls ENDP

MoveDeactivateBullets PROC	
; =================================================================================================
; Moving bullets & deactivating
; =================================================================================================

	 MOV CH, 0
	 MOV CL, NumBullets
	 LEA SI, P1Bullet1										; start with P1
	 LEA DI, PlayerOne 										; Used to decrement the player's bulletsInArenaFlag
	; TODO : CHANGE NUMBULLETS OR MAKE IT DEPEND ON DATA SIZE
	 MOV AX, NumBullets										; Getting the number of bullets each player has, assuming that each player has 1/2 of the total bullets
	 MOV BL, 2
	 DIV BL
	 MOV AH,AL									
	 MOV BL, 0

MoveBullets:
	 MOV AL, BYTE PTR [SI + 4]								; Get the current bullet's active flag
	 CMP AL, 1
	 JNZ DontMove											; If the flag is not 1 (ie. inactive), skip the drawing
	 MOV DL, BYTE PTR [SI]									; Current bullet xPos
	 MOV DH, BYTE PTR [SI + 1]   							; Current bullet yPos

;								--------------Boundaries Checks----------------								;
	 CMP DL, 1												
	 JL DeactivateBullet										
	 CMP DL, 79
	 JG DeactivateBullet
 
 	 CMP DH, 1
 	 JL DeactivateBullet
	 CMP DH, 15
	 JG DeactivateBullet
 
	 JMP DontDeactivateBullet
;								--------------Deactivating-----------------								;
	DeactivateBullet:
		 MOV BYTE PTR [SI + 4], 0 							; Setting the bullet's active flag to false
		 MOV BYTE PTR [SI], 40   							; Putting the inactive bullet in the middle
		 MOV BYTE PTR [SI + 1], 12 
		 DEC BYTE PTR [DI + 3]   							; Decrementing the player's bullets in arena
		 JMP DontMove


	DontDeactivateBullet:
		 MOV BL, BYTE PTR [SI + 2]							; Current bullet xVel
		 MOV BH, BYTE PTR [SI + 3]							; Current bullet yVel
 
		 ADD DL, BL
		 ADD DH, BH
 
	     MOV BYTE PTR [SI], DL								; Moving the bullet on the x
	     MOV BYTE PTR [SI + 1], DH   						; Moving the bullet on the y

	DontMove:
		 DEC AH						
		 JNZ DontChangePlayer								; If the player has more bullets in the arena, continue checking
		 ADD DI, PLAYER_DATA_SIZE							; Otherwise, check the next player
		 MOV AX, NumBullets									; Reseting AL so it check for player2's bullets (the second half of the bullets)
		 MOV BL, 2
		 DIV BL
		 MOV AH,AL											; Cleanup
		 MOV AL,0
		 MOV BL,0

	DontChangePlayer:
		 ADD SI, BulletDataSize
		 LOOP MoveBullets

	 MOV BH,0 
		 
	; After all the logic is done, Check if all bullets are out of the screen and both players have run out of bullets
	 LEA SI, PlayerOne
	 LEA DI, PlayerTwo
	 CMP BYTE PTR [SI + 2], 0
	 JNZ NotOutOfBullets
	 CMP BYTE PTR [SI + 3], 0
	 JNZ NotOutOfBullets
	 CMP BYTE PTR [DI + 2], 0
	 JNZ NotOutOfBullets
	 CMP BYTE PTR [DI + 3], 0
	 JNZ NotOutOfBullets
	 CALL ResetRound
	
	NotOutOfBullets:

		 RET
MoveDeactivateBullets ENDP

; The main logic of the game
Logic PROC

	 CALL PlayerColls

     CALL CactusColls

	 CALL BarrelColls

	 CALL StonepileColls

	 CALL MoveDeactivateBullets
	 
	 RET
Logic ENDP

StaticLayout PROC 
	; Flicker solution found at: https://stackoverflow.com/questions/43794402/avoid-blinking-flickering-when-drawing-graphics-in-8086-real-mode
	; Comment this when using emu8086
	 CALL waitForNewVR
	 ClearScreen
; ---------------------------------------------------------------------------------------------------
; Chat Upper border
; ---------------------------------------------------------------------------------------------------

	 MoveCursor 00H, 16d
	; Loading the character, number of loops and preparing the interrupt 
		 MOV 			CX, 80
		 MOV 			AH, 2
		 MOV 			DL, '-'
	chatWindow:											    ; Draw the dashed line
		 INT 21h
		 LOOP chatWindow

; ---------------------------------------------------------------------------------------------------
; Player Score
; ---------------------------------------------------------------------------------------------------

	 MoveCursor 01H, 17d
	 LEA SI, userName
	 ADD SI, 2
	 DisplayMessage SI
	 DEC SI
	 MOV AL, 01D
	 ADD AL, [SI]
	 MoveCursor AL, 17D
	 DisplayMessage UserNameScore 							; Length of UserNameScore is 11D
	 Add Al, 11D
	 MoveCursor Al, 17D
	 DisplayChar PlayerOneScore
	 
	 MOV CH, 1D
	 ADD CH, AL												; Storing the end point of P1Score for user later

	 
	 MOV AH, 11D                                       		; AL is the length of the entire message of Player2 score
	 ADD AH, 11D											; lengths of userName2 + UserNameScore + PlayerTwo Score + 1(for spacing)
	 ADD AH, 1D												; 			11D		    +		11D	   +	 1D		     +  1D
	 ADD AH, 1D
	 MOV AL, 80D
	 SUB AL, AH												; Now AL contains the x from where we start displaying the player two score message
	 MOV CL, AL												; Storing the beginning of P2Score for use later

	 MoveCursor AL, 17d
	 DisplayMessage userName2 
	 ADD AL, 11D 											; This should be length of userName2 Which is fixed at Abdelrahman For Now
	 DisplayMessage UserNameScore
	 ADD AL, 11D
	 DisplayChar PlayerTwoScore

; ---------------------------------------------------------------------------------------------------
; Break dashed line
; ---------------------------------------------------------------------------------------------------
	PUSH CX
	MoveCursor 00H, 18d
		MOV 			CX, 80
		MOV 			AH, 2
		MOV 			DL, '-'
	chatWindow2:										 	;Draw the dashed line
		 INT 21h
		 LOOP chatWindow2
	POP CX

; ---------------------------------------------------------------------------------------------------
; Timer
; ---------------------------------------------------------------------------------------------------
	SUB CL, CH												; This bit is used to center the round timer in the space between the 
	MOV DH, 2D												; 2 players' names
	MOV AH, 00D												; CL contains the start of P2Score message and CH contains the end of P1Score message
	MOV AL, CL												; Subtracting them then dividing by 2 gives the length of half the space between them
	DIV DH													; The time message length is 6, subtract 6 so that 6 characters are in the first half
	ADD AL, CH												; And the 3 other characters are in the second half
	SUB AL, 3D

	MOV AH, 02H
	INT 1AH													; INT 1AH is used to get System time. It stores seconds in DH
	CMP DH, RoundSystemTime									; Round system time stores the tens and units of the seconds in format [Tens][Seconds] or 00 
	JZ DisplayTime											; If there is no change in system time (1 second has yet to pass) just display time and move on
	MOV RoundSystemTime, DH									
	LEA SI, RoundTime
	CMP BYTE PTR [SI + 1], 30H								; Check if the units are 0
	JZ Borrow												; If so, borrow 1 from the tens, otherwise, subtract 1 from the units
	DEC BYTE PTR [SI + 1]									
	JMP DisplayTime
	Borrow:
		DEC BYTE PTR [SI]
		MOV BYTE PTR [SI + 1], 39H
	
	DisplayTime:											; Display time displays the current time left in seconds that the time has left
		MoveCursor AL, 17D
		DisplayChar '|'
		DisplayChar '0'
		DisplayChar ':'
		LEA SI, RoundTime									; RoundTime stores the time in format tens, seconds
		Displaychar [SI]
		ADD SI, 1D
		DisplayChar [SI]
		DisplayChar '|'

; ---------------------------------------------------------------------------------------------------
; Chat Bottom border
; ---------------------------------------------------------------------------------------------------

	MoveCursor 00H, 23d
		 MOV 			CX, 80
		 MOV 			AH, 2
		 MOV 			DL, '-'
	dashline:												 ;Draw the dashed line
		 INT 21h
		 LOOP dashline

; ---------------------------------------------------------------------------------------------------
; Info message
; ---------------------------------------------------------------------------------------------------

	; Length of endGame1 Message is 23D, Length of userName2 is 11D
	; Length of engGame2 Message is 10D
	 MoveCursor 03H, 24d
	 DisplayMessage endGame1
														
	 MOV AL, 03H
	 ADD AL, 23D
	 MoveCursor AL, 24D
	 DisplayMessage userName2
	 ADD AL, 11D
	 MoveCursor AL, 24D
	 DisplayMessage endGame2

	 RET
StaticLayout ENDP

Draw PROC
	; Draw left Player first
	; Move the cursor to row 0AH, column 2, output "#"
	; Row 0BH, column 2, output
	; Row 0CH, column 2, output
	; Then the right Player
	; Same as the left Player but move to row 77D   
	; DL carries the X coordinate (Columns), DH carries the Y coordinate (Rows)

	; ---------------------------------------------------------------------------------------------------
	; Draw Left Player
	; ---------------------------------------------------------------------------------------------------

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

	; Drawing the bullet count behind the player
	 MOV CL, BYTE PTR [SI]									; Loading the player's xPos
	 DEC CL													; Going 1 block to the left
	 MOV CH, BYTE PTR [SI+1]								; Loading the player's yPos
	 DEC CH													; Going 1 block up
	 MOV DL, BYTE PTR [SI+2]								; Loading the player's bullet count
	 ADD DL, 30H											; Converting it to ASCII
	 MoveCursor CL, CH				
	 DisplayChar DL


; ---------------------------------------------------------------------------------------------------
; Right Player
; ---------------------------------------------------------------------------------------------------

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

	 ; Drawing the bullet count behind the player
	 MOV CL, BYTE PTR [SI]									; Loading the player's xPos
	 INC CL													; Going 1 block to the right
	 MOV CH, BYTE PTR [SI+1]								; Loading the player's yPos
	 DEC CH													; Going 1 block up
	 MOV DL, BYTE PTR [SI+2]								; Loading the player's bullet count
	 ADD DL, 30H											; Converting it to ASCII
	 MoveCursor CL, CH				
	 DisplayChar DL

; ---------------------------------------------------------------------------------------------------
; Bullets Drawing 
; ---------------------------------------------------------------------------------------------------

	 MOV CH, 0
	 MOV CL, NumBullets
	 ADD CL, ExtraNum
	 LEA SI, P1Bullet1

DrawBullets:
	 MOV AL, BYTE PTR [SI + 4]									; Get the current bullet's active flag
	 CMP AL, 1					 
	 JNZ DontDraw												; If the flag is not 1 (ie. inactive), skip the drawing
 
	 MOV DL, BYTE PTR [SI]										; DL = xPos of Bullet
	 MOV DH, BYTE PTR [SI + 1]									; DH = yPos of Bullet
	 MoveCursor DL, DH
	 DisplayChar BulletSymbol
	
	DontDraw:
		 ADD SI, BulletDataSize
		 LOOP DrawBullets
		
	
; ---------------------------------------------------------------------------------------------------
; Blocks Drawing 
; ---------------------------------------------------------------------------------------------------

; CALL DrawBlocks

; ---------------------------------------------------------------------------------------------------
; Cactus Drawing 
; ---------------------------------------------------------------------------------------------------

 	 MOV SI, OFFSET Cactus
 	 MOV CX, 0
 	 MOV CL, CactusNum

DrawCactus:
	 MOV DL, [SI] 												;xPos of the upper part of the cactus
	 MOV DH, [SI+1]												;yPos of the upper part of the cactus
 
	 PUSH CX 													; we save the value of the iterate of the outer loop to be able to use CX for the two loops 
	 MOV  CX, 3

	DrawCactusBlock:											; this loop draws the 3 parts of the cactus {Upper, Middle, Lower}
		 MoveCursor DL, DH
		 DisplayChar CactusSymbol
		 INC DH
		 LOOP DrawCactusBlock

	 POP CX														; pop the outer loop iterator
	 ADD SI, 2													; get the next cactus
	 LOOP DrawCactus

; ---------------------------------------------------------------------------------------------------
; Barrel Drawing 
; ---------------------------------------------------------------------------------------------------
	 MOV SI, OFFSET Barrel
	 MOV CX, 0
	 MOV CL, BarrelNum

DrawBarrel:
	 MOV DL, [SI] 												;xPos of the upper part of the barrel
	 MOV DH, [SI+1]												;yPos of the upper part of the barrel

	 ;MOV AL, [SI+2]
	 PUSH CX 													; we save the value of the iterate of the outer loop to be able to use CX for the two loops 
	 MOV CX, 2
	 ;MOV CH,0													;In case of length variable
	 ;ADD CL, AL 												;In case of length variable

	DrawBarrelBlock:											; The barrel is supposed to have a variable length but for now I'll put as 2
		 MoveCursor DL, DH
		 DisplayChar BarrelSymbol
		 INC DH
		 LOOP DrawBarrelBlock
	 POP CX														; pop the outer loop iterator
 	 ADD SI, 2													; get the next barrel
	 ;ADD SI, 3 												;In case of length variable
	 LOOP DrawBarrel

; ---------------------------------------------------------------------------------------------------
; StonePile Drawing 
; ---------------------------------------------------------------------------------------------------
	 MOV SI, OFFSET StonePile
	 MOV CX, 0
	 MOV CL, StonePileNum
DrawStonePile:													;Here we only need one loop since the stonepile consists of only one position (i.e its height is 1)
	 MOV DL, [SI] 												;xPos of the stonepile
	 MOV DH, [SI+1]												;yPos of the stonepile

	 MoveCursor DL, DH
	 DisplayChar StonePileSymbol
	 INC DH
	 ADD SI, 2													; get the next stonepile
	 LOOP DrawStonePile

	 RET

Draw ENDP

; VR stands for "Vertical Refresh"
; Temporary solution until we get paging figured out
waitForNewVR PROC

	;Wait for bit 3 to be zero (not in VR).
	;We want to detect a 0->1 transition.
 	 MOV DX, 3DAH

	;WAIT FOR BIT 3 TO BE ONE (IN VR)
	_WAITFOREND:
		 IN AL, DX
		 TEST AL, 08H
		 JNZ _WAITFOREND

	_WAITFORNEW:
		 IN AL, DX
		 TEST AL, 08H
		 JZ _WAITFORNEW
	 
 	 RET
waitForNewVR ENDP

GetPlayerInput PROC

	 
CheckBuffer:
	 ; Checking if the keyboard buffer contains any keypresses
	 ; INT 16H with AH = 01H returns ZF = 0 if there's something in the buffer and ZF = 1 if the buffer is empty
	 MOV AH,01H
	 INT 16h
	 JNZ CheckInput											; If the buffer is empty, no need to execute inputs
	 JMP exitGame											; AAAAAAAAAAAAAAAAAAAAAAAA
	 
CheckInput:
	 ; If there's a keypress, get it 
	 MOV AH, 00
	 INT 16H
	 
; ---------------------------------------------------------------------------------------------------
; Player 1 
; ---------------------------------------------------------------------------------------------------

	 LEA SI, PlayerOne
     MOV CL, BYTE PTR [SI + 1]
    ;  MOV AH,1
    ;  INT 16H 

	 CMP AH, 3Eh											; Checks if the user pressed F4
	 JNZ continue											; if not, continue searching for the pressed key
	 LEA SI, exiting										; if he pressed, set this flag to 1 so we can use it in the main program to direct the user to Options Window
	 MOV BYTE PTR [SI], 1
	 JMP exitGame											; exit this procedure
	continue:

	SKIP_JUMP:
     CMP AH, 17D											; Checks if player1 pressed W, move up
     JZ MoveUpP1
    
     CMP AH, 31D											;  Checks if player1 pressed S, move down
     JZ MoveDownP1	
     JMP EndMoveCheckP1
     
MoveUpP1:    												; Checks if PlayerOne is moving up & out of the game boundary
	 CMP CL, 2
	 JZ EndMoveCheckP1
     DEC CL
     JMP EndMoveCheckP1

MoveDownP1:     											; Checks if PlayerOne is moving down & out of the game boundary
	 CMP CL, 15D
	 JZ EndMoveCheckP1
     INC CL                  
     JMP EndMoveCheckP1

EndMoveCheckP1:
     MOV BYTE PTR [SI + 1], CL
	 CMP AH, 32D
	 JNZ EndShootCheckP1 									; If the player didn't press D, don't check for bullets

	 LEA SI, PlayerOne
	 MOV BL, BYTE PTR [SI + 3]
	 CMP BL, 0
	 JNZ EndShootCheckP1 									; If the player has any bullets in the arena, don't shoot any more bullets
	 MOV BL, BYTE PTR[SI + 2]
	 CMP BL, 0
	 JZ EndShootCheckP1  									; If the player has no bullets left to shoot, don't shoot
	 CALL Player1Shoot
	EndShootCheckP1:
; ---------------------------------------------------------------------------------------------------
; Player 2 
; ---------------------------------------------------------------------------------------------------
	
	 LEA SI, PlayerTwo
     MOV CL, BYTE PTR [SI + 1]

     CMP AH, 72D											; player pressed Up arrow
     JZ MoveUpP2
    
     CMP AH, 80D											; player pressed Down arrow
     JZ MoveDownP2
     JMP EndInputP2
     
MoveUpP2:     											 	; Checks if PlayerTwo is moving up & out of the game boundary
	 CMP CL, 2
	 JZ EndInputP2
     DEC CL
	 skip21:
     JMP EndInputP2

MoveDownP2:   											 	; Checks if PlayerTwo is moving up & out of the game boundary
	 CMP CL, 15D
	 JZ EndInputP2
     INC CL                  
     JMP EndInputP2

EndInputP2:
     MOV BYTE PTR [SI + 1], CL

	 CMP AH, 75D
	 JNZ EndShootCheckP2 									; If the player didn't press D, don't check for bullets
 
	 LEA SI, PlayerTwo
	 MOV BL, BYTE PTR [SI + 3]
	 CMP BL, 0
	 JNZ EndShootCheckP2 									; If the player has any bullets in the arena, don't shoot any more bullets
	 MOV BL, BYTE PTR[SI + 2]
	 CMP BL, 0
	 JZ EndShootCheckP2  									; If the player has no bullets left to shoot, don't shoot
	 CALL Player2Shoot
 
	EndShootCheckP2:
	 ; Jump to check if there are anymore keypresses
	 JMP CheckBuffer										; JUMP OUT OF RANGE AAAAAAAAAAA
	; FlushKeyBuffer
	exitGame:
	 RET

ENDP              
	
Player1Shoot PROC
	 LEA SI, PlayerOne
	 LEA DI, P1Bullet1										; Will be used to spawn the bullet in front of the player and set it as active
 
 
	 MOV AL, BYTE PTR [SI]									; AL = P1.xPos
	 MOV AH, BYTE PTR [SI + 1]								; AH = P1.yPos
	 DEC AH 												; Shifting the bullet 1 block up so it comes out from the middle of the player
	 DEC BYTE PTR[SI + 2]     					 			; Decrease the player's bullet stash by 1
	 INC AL													; Incrementing AL so that it's now in front of the player
	 
	 MOV BYTE PTR [DI],AL
	 MOV BYTE PTR [DI + 1], AH
	 MOV BYTE PTR [DI + 4], 1
	 MOV BYTE PTR [SI+3],1
 
	 MOV BYTE PTR [DI+2],2 
	 MOV BYTE PTR [DI+3],0

	 RET
Player1Shoot ENDP

Player2Shoot PROC
	 LEA SI, PlayerTwo
	 LEA DI, P2Bullet1										; Will be used to spawn the bullet in front of the player and set it as active
 
	 MOV AL, BYTE PTR [SI]									; AL = P2.xPos
	 MOV AH, BYTE PTR [SI + 1]								; AH = P2.yPos
	 DEC AH													; Shifting the bullet 1 block up so it comes out from the middle of the player
	 DEC BYTE PTR [SI + 2]     								; Decrease the player's bullet stash by 1
	 DEC AL													; Decrementing AL so that it's now in front of the player
 
	 MOV BYTE PTR [DI],AL									; Spawning the bullet in front of the player
	 MOV BYTE PTR [DI + 1], AH
	 MOV BYTE PTR [DI + 4], 1								; Setting the bullet's active flage
	 MOV BYTE PTR [SI+3],1									; Setting the player's bulletsInArenaFlag
	 MOV BYTE PTR [DI+2], -2								; reset the player xVel incase it was changed by an object
	 MOV BYTE PTR [DI+3],0									; reset the player yVel incase it was changed by an object
	 RET
Player2Shoot ENDP

ResetRound PROC
; ---------------------------------------------------------------------------------------------------
; Reset Player1 Variables
; ---------------------------------------------------------------------------------------------------

	 LEA SI, PlayerOne										; Reset xpos, ypos, bulletsCount, and bulletsInArena do 
	 MOV AL, LeftPlayerIitialCol							; Default values
	 MOV BYTE PTR [SI], AL
	 MOV AL, PlayerInitialRow
	 MOV BYTE PTR [SI + 1], AL
	 MOV BYTE PTR [SI + 2], 3
	 MOV BYTE PTR [SI + 3], 0

; ---------------------------------------------------------------------------------------------------
; Reset Player2 Variables
; ---------------------------------------------------------------------------------------------------

	 LEA SI, PlayerTwo										; Reset xpos, ypos, bulletsCount, and bulletsInArena do
	 MOV AL, RightPlayerIitialCol							; Default values
	 MOV BYTE PTR [SI], AL
	 MOV AL, PlayerInitialRow
	 MOV BYTE PTR [SI + 1], AL
	 MOV BYTE PTR [SI + 2], 3
	 MOV BYTE PTR [SI + 3], 0

; ---------------------------------------------------------------------------------------------------
; Deactivating Active Bullets
; ---------------------------------------------------------------------------------------------------

	 LEA DI, P1Bullet1 										; Set the active flag of any bullet to 0 and move them
	 MOV CL, NumBullets										; all to the center of the screen
	 MOV CH, 00D
	GetToWork:
	 	 MOV BYTE PTR [DI], 40D
	 	 MOV BYTE PTR [DI + 1], 12D
	 	 MOV BYTE PTR [DI + 4], 0
	 	 ADD DI, BulletDataSize
	 	 LOOP GetToWork
; ---------------------------------------------------------------------------------------------------
; Get Current system time and round wait timers
; ---------------------------------------------------------------------------------------------------
	 MOV AH, 02H
	 INT 1AH											; INT 1Ah gets system time and stores seconds in DH
	 MOV RoundSystemTime, DH							; Whenever we resetRound (i.e. starting a new round), we wait for
	 LEA SI, RoundTime									; 3 seconds before starting that new round
	 MOV AL, 30H										; We add 30 to the tens and units of the time so that they can be printed
	 MOV AH, 33H										; RoundSystemTime contains the current round Time which is counted 
	 MOV [SI], AL										; down every second
	 MOV [SI + 1], AH
	 MOV AL, 0										
	 MOV GetInput, AL									; GetInput is a flag used to determine whether we read input from the players or not
														; This is set to 0 (Players's can't move or shoot) during the 3 seconds wait time 
	 RET												; before round start
ResetRound ENDP

WinScreen PROC 
	 ClearScreen

	 MOV AL, 0
	 CMP PlayerOneScore, 35H         					; Check if the winner is P1
	 JZ SKIP1
	 JMP Player2

	SKIP1:
	 LEA SI, userName
	 ADD SI, 2 

	 ADD AL, [SI - 1]									; Here we are getting the total length of the win message
	 ADD AL, 18D
	 ADD AL, 1D
	 ADD AL, 4D

	 MOV AH, 80D										; This is used to center the entire length
	 SUB AH, AL											; We subtract the entire length of the win message from 80 (row length)
	 MOV AL, AH											; we then divide the result by 2 and use that as the beginning of the message
	 MOV AH, 00H
	 MOV DH, 2D
	 DIV DH
	 MoveCursor AL, 12D
	 DisplayMessage  SI  								
	 ADD AL, [SI - 1]
	 MoveCursor AL, 12D
	 DisplayMessage WinCondition						
	 ADD AL, 18D
	 MoveCursor AL, 12D
	 DisplayChar PlayerOnescore
	 ADD AL, 1D
	 MoveCursor AL, 12D
	 DisplayMessage WinScore
	 ADD AL, 4D
	 MoveCursor AL, 12D
	 DisplayChar PlayerTwoScore
	 JMP SKIP2

	Player2:											;userName2 is fixed for now but will be needed when it's variable     
	 LEA SI, userName2

	 ADD AL, 11D           								; This is fixed at 11D for now but should change when player2's name is inputed
	 ADD AL, 18D
	 ADD AL, 1D
	 ADD AL, 4D

	 MOV AH, 80D										; This is used to center the entire length
	 SUB AH, AL											; We subtract the entire length of the win message from 80 (row length)
	 MOV AL, AH											; we then divide the result by 2 and use that as the beginning of the message
	 MOV AH, 00H
	 MOV DH, 2D
	 DIV DH


	 MoveCursor AL, 12D
	 DisplayMessage userName2
	 ADD AL, 11D
	 MoveCursor AL, 12D
	 DisplayMessage WinCondition 
	 ADD AL, 18D
	 MoveCursor AL, 12D
	 DisplayChar PlayerOnescore
	 ADD AL, 1D
	 MoveCursor AL, 12D
	 DisplayMessage WinScore
	 ADD AL, 4D
	 MoveCursor AL, 12D
	 DisplayChar PlayerTwoScore

SKIP2:					
	 MOV AH, 02H
	 INT 1AH													; INT 1AH is used to get the system time, Seconds are stored in DH
	 MOV AL, DH													; If we want to wait for 5 seconds, all we need to do
	 MOV BL, 5D													; Is detect changes in the seconds of the system time 5 times
Time:															; We store the current system time then loop untill we detect a change in system time (seconds)
	 MOV AH, 02H												; If change is detected, decrement BL, if this happens 5 times, then 5 seconds have passed
	 INT 1AH
	 CMP AL, DH
	 JZ Time
	 DEC BL
	 JZ EndTime
	 MOV AL, DH
	 JMP Time
EndTime:
	 RET
WinScreen ENDP

; Disabled for now
DrawBlocks PROC
;											-----Block One-----											;
	 MOV SI, OFFSET Block1		  								; Points at the first byte
	 MOV CX,0													; Clearing CX
	 MOV CL, BYTE PTR [SI + 2]	    							; Putting the height inside CL
	 MOV DL, BYTE PTR [SI]										; Putting the xPos in DL
	 MOV DH, BYTE PTR [SI] + 1									; Putting the yPos in DH

DrawBlockOne:
	 MoveCursor DL,DH				
	 DisplayChar BlockSymbol
	 DEC DH
	 LOOP DrawBlockOne

;											-----Block Two-----											;

	 MOV SI, OFFSET Block2										; Points at the first byte
	 MOV CX,0													; Clearing CX
	 MOV CL, BYTE PTR [SI + 2]									; Putting the height inside CL
	 MOV DL, BYTE PTR [SI]										; Putting the xPos in DL
	 MOV DH, BYTE PTR [SI] + 1									; Putting the yPos in DH

DrawBlockTwo:
	 MoveCursor DL,DH
	 DisplayChar BlockSymbol
	 DEC DH
	 LOOP DrawBlockTwo

	RET
DrawBlocks ENDP

; End file and tell the assembler what the main subroutine is
    END MAIN 

