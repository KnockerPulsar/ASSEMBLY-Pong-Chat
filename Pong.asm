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
DisplayBuffer MACRO Buffer
	 MOV 			AH, 9h
	 MOV 			DX, OFFSET Buffer + 2
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
	 P1Bullet1 				DB 40, 12, 1, 0, 0
     
	 ; Player2 bullets
	 P2Bullet1 				DB 40, 12, -1, 0, 0
	 ;DB '$'				; we use it as indicator for the end of the bullets
		 
	 ;One of the following is used when a bullet hits a stonepile (xPos, yPos, xVel, yVel, active)
	 ExtraBullet1 			DB 40, 12, 2, 0, 0
	 ;ExtraBullet2			DB 40, 12, -2, 0, 0
	 DB '~'
	 ExtraNum 				EQU 1
	 P2Fired				DB 0 ; If 0 then P2 didn't shoot this turn and 1 means he shot
	
	; Cactus data
	; =============================================================================================
	; xPos, yPos pairs
	 CactusNum    			EQU 2 
	 Cactus       			DB 32d,11d,11d,5d,'~'
	 CactusLevel2   		DB 62d,5d,20d,12d,'~'
	 CactusSymbol 			EQU 206
     
	; Barrel data
	; =============================================================================================
	; xPos, yPos pairs Will be changed later to -> xPos, yPos, Height
	 BarrelNum 				EQU 2
	 Barrel 				DB 40d,4d,50d,1d,'~'
	 BarrelLevel2			DB 9d,5d,69d,10d,'~'
	 ;Barrel 				DB 40d,4d,2d,50d,1d,3d,'$' ->(xPos, yPos, Height)
	 BarrelSymbol 			EQU 178

	; StonePile data
	; =============================================================================================
	; xPos, yPos pairs
	 StonePileNum 			EQU 2
	 StonePile 				DB 60d,8d,12d,10d,'~'
	 StonePileLevel2		DB 50d,3d,13d,9d,'~'
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
	 ChooseDiff				DB "Please Choose a difficulty",'$'
	 Difficulties			DB '  * For easy, press 1', 13,10,13,10, 09,09,09, '  * For medium press, 2', '$'
	 ChooseLevel			DB "Please Choose a level",'$'
	 Levels					DB '  * For level 1, press 1', 13,10,13,10, 09,09,09, '  * For level 2, press 2', '$'

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

	; Difficulty & Levels
	; ============================================================================================= 
	; Speed multipliers
	ChosenDiff 			    DB ?
	MaxBullets			    DB ?
	CurrLevel			 	DB ?

	; Chatting Variables
	; ============================================================================================
	; 	
	UPPER_COLOR    DB 00FH                     	; 0 For black BG and F for white FG (text)
	LOWER_COLOR    DB 0F0H                     	; Reverse the above
	MyCursorPos    DB 0,0                      	; x,y for the current side's cursor (Local messages will be displayed at the top)
	OtherCursorPos DB 0,12                     	; x,y for the other end's cursor (Away messages will be displayed at the bottom)
	Recieved       DB 0                        	; The recieved character
	Sent           DB 0                        	; The sent character
	MyName         DB 16,3,"SLAVE", 12 DUP('$')
	OtherName      DB 17 DUP('$')
	Master         DB 0
	SendBuffer     DB 80 DUP('$'),0FEH
	localCharIndex DB 0
	ReadyToSend	   DB 0							;1 means that enter has been clicked and the stored text should be sent
	ReceiveBuffer  DB 80 DUP('$'),0FEH
	otherCharIndex DB 0
	ReadtToSendS   DB 0							;1 means that enter has been clicked and the stored text should be sent

	; Serial Communication Variables
	; ============================================================================================
	; 	
	; First Transmission:
	; Start Bit: 05h, Chosen Difficulty (1 byte), Max Bullets (1 byte), Current Level (1 byte), Name Size (1 byte), Name, Stop Bit (0FFh)
	FirstTransmissionBuffer		DB	30 DUP(?)			;A little Long in case of a long name
	; MasterGameBuffer:
	; Start Bit: 01h, Player1 Parameters (4 bytes), P1Score (1 byte), P2Score (1 byte), TimeCount (2 byteS), Exit Check (1 Byte), Bullets Count (1 byte), Bullets' data (5 bytes each), Chat length, Chat ,Stop Bit (0FFh)
	FromMasterGameBuffer 			DB	200 DUP(?);Used to temporarily store the data slave receives form master
	FromMasterChatLength			DB ?		;Used to store the chat length slave receives form master
	; FromSlaveGameBuffer:
	; Start Bit: 02h, Player2 Parameters (4 bytes), Exit Check (1 Byte), [Bullets Count (1 byte)][PROBABLY NOTa], Bullets' data (5 bytes each), Chat length, Chat ,Stop Bit (0FFh)
	FromSlaveGameBuffer	 		DB 100 DUP(?)
	FromSlaveChatLength			DB ?		;Used to temporarily store the chat length slave receives form master
	; MasterGIndex				DB
	SlaveGIndex				DB 0
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
		 MOV 			DX, OFFSET MyName
		 INT 21h			; read username
; ============================================================================================
;									username Validations
; ============================================================================================

		 CMP MyName+2, 41h 					;less than A
		 JB Home 
		 
		 CMP MyName+2, 5Ah
		 JBE Welcome 							; if in range A:Z
		 		
	; If greater than A and not in range A:Z, check for a:z
	Check:
		 CMP MyName+2,61h						; less than a
		 JB Home 
		 CMP MyName+2, 7Ah
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
			CALL DifficultySelect
			CALL LevelSelect
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
		 JNZ GameLoop		; if not continue the game
		 				
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
	 
	 CMP CurrLevel,1
	 JE Level1Cactus
	 CMP CurrLevel,2
	 JE Level2Cactus

	 Level1Cactus:
	 	LEA SI, Cactus 										; To Iterate on the cactus objects to check collisions ,  [SI] and [SI+1] are xPos and yPos of the cactus
		JMP CactusCollisions
	 Level2Cactus:
	 	LEA SI, CactusLevel2
		JMP CactusCollisions

CactusCollisions:
	forEachBullet:
		 MOV CH , 0 				  						; Will be used for jumping when checking x+1 and x
		 MOV AL, BYTE PTR [DI + 4] 							; Carries the current bullet's active flag
		 CMP AL, 0				  							; Checking if the bullet is active
		 JNZ ActiveBulletCactus	  							; If not, skip the collision check
	 	 JMP InactiveBullet
		  
		 ActiveBulletCactus:
		 MOV BL, BYTE PTR [DI]	  							; Otherwise, load xPos and yPos into BL and BH
		 MOV BH, BYTE PTR [DI + 1]
	 
		 MOV CL, BYTE PTR [SI]								; Stores the cactus's xPos
		 MOV AH, BYTE PTR [DI + 2]							; Stores the bullet's xVel

		 CMP BL,CL											; If the bullet exactly hit on the x, check the y
		 JZ ChecksStart
		 ADD BL,AH											; If the bullet WILL hit after moving, check the Y
		 CMP BL,CL
		 JZ ChecksStart
		 SUB BL,AH

		 CMP AH,0											; Since each bullet direction requires a different check
		 JG LTRBulletCactus
		 JL RTLBulletCactus


		 LTRBulletCactus:
		 ; Check if B.x < obj.x < B.x + xVel
		 ; if B.x > obj.x, no hit
		 CMP BL, CL
		 JG nextBullet
		 ; if obj.x > B.x + xVel, no hit
		 ADD BL, AH
		 CMP BL, CL
		 JL nextBullet
		 ; if B.x < obj.x < B.x + xVel, check yPos for a hit.
		 JMP ChecksStart

		 RTLBulletCactus:
		 ; Check if B.x + xVel < obj.x < B.x
		 ; if obj.x > B.x, no hit
		 CMP BL,CL
		 JL nextBullet 
		 ; if obj.x < B.x + xVel, no hit
		 ADD BL,AH
		 CMP BL,CL
		 JG nextBullet
		 ; if B.x + xVel < obj.x < B.x, check yPos for a hit
		 JMP ChecksStart

		;  CMP BL, CL											; Check if the bullet xPos is the same as a cactus xPos
		;  JZ ChecksStart										; If the bullet's xPos and the cactus's xPos match, got a hit, don't increment CH
 
		;  INC CL												; x = x+1
		;  CMP BL,CL											; If the bullet's xPos = cactus's xPos + 1, got a hit, don't increment CH
		;  JZ ChecksStart
 
		;  JNZ nextBullet										; If the bullet's xPos doesn't match neither the cactus's Xpos or Xpos + 1, check next bullet

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
			CMP BL, '~'										
			JZ ResetBullet									; If we finished checking all bullets, reset the current bullet, check the next cactus
			JMP forEachBullet								; else, continue with the current cactus

	ResetBullet:					
		LEA DI, P1Bullet1									; reset the pointer to the first bullet

	NextCactus:
		ADD SI, 2
		MOV BL, [SI]
		CMP BL, '~'											; if we finish checking for all cactuses
		JZ FinishCactusColl										; stop iterating 
		JMP CactusCollisions								; else, continue with the next cactus
	
	FinishCactusColl: RET
	
CactusColls ENDP

; TODO: there's a bug where if a bullet moves just below or above a barrel, its speed still gets reduced
BarrelColls PROC
; =================================================================================================
;  Barrel Collisions Checks
; =================================================================================================

	 CMP CurrLevel,1
	 JE Level1Barrels
	 CMP CurrLevel,2
	 JE Level2Barrels

	 Level1Barrels:
	 	LEA SI, Barrel 										; To Iterate on the barrel objects to check collisions ,  [SI] and [SI+1] are xPos and yPos of the top of the barrel
		JMP StartFromBullet1
	 Level2Barrels:
	 	LEA SI, BarrelLevel2
		JMP StartFromBullet1

StartFromBullet1:
	 LEA DI, P1Bullet1			 							; Starting with bullet 1
BarrelCollisions:
		 MOV BL, BYTE PTR [DI + 4] 							; Carries the current bullet's active flag
		 CMP BL, 0				  							; Checking if the bullet is active
		 JNZ ActiveBulletBarrel	  							; If not, skip the collision check
		 JMP GetBullet
ActiveBulletBarrel:

		 MOV AH,0
		 MOV AL, ChosenDiff
		 MOV DL, 3
		 IDIV DL
		 ;General Case: Collision occurs if xPos Bullet <= xPos Barrel <= xPos + xVel Bullet && yPos Bullet <= yPos Barrel <= yPos + yVel Bullet
		 ;For now implement the case where the bullet is straight
		 MOV BL, BYTE PTR [DI]								;Get the xPos of the bullet
		 MOV BH, BYTE PTR [SI]								;Get the xPos of the barrel
		 MOV DH, BYTE PTR [DI + 2]
		 MOV CL, BYTE PTR [DI+2]							;If the xVelo =< 1/3 normal xVelo for this difficulty, then do nothing and get the next bullet
		 
		 CMP DH,0
		 JG GoingRight
		 JL GoingLeft

GoingRight:
		 CMP DH, AL 
		 JLE GetBullet										; 1 <= 1, 1/3 = 0 So we want to skip this
		 JMP canSlowDown
GoingLeft:
		 MOV DL,-1
		 IMUL DL
		 CMP DH, AL											;If the xVelo => -1/3 normal xVelo for this difficulty, then do nothing and get the next bullet
		 JGE GetBullet										; -1 <= -1, -1/3 = 0 So we want to skip this
		 JMP canSlowDown

canSlowDown:

		 CMP BL,BH											; If the bullet exactly hit on the x, check the y
		 JZ CheckYColli
		 ADD BL,DH											; If the bullet WILL hit after moving, check the Y
		 CMP BL,BH
		 JZ CheckYColli
		 SUB BL,DH

		 CMP DH,0											; Since each bullet direction requires a different check
		 JG LTRBulletBarrel
		 JL RTLBulletBarrel

		 LTRBulletBarrel:
		 ; Check if B.x < obj.x < B.x + xVel
		 ; if B.x > obj.x, no hit
		 CMP BL, BH
		 JG GetBullet
		 ; if obj.x > B.x + xVel, no hit
		 ADD BL, DH
		 CMP BL, BH
		 JL GetBullet
		 ; if B.x < obj.x < B.x + xVel, check yPos for a hit.
		 JMP CheckYColli

		 RTLBulletBarrel:
		 ; Check if B.x + xVel < obj.x < B.x
		 ; if obj.x > B.x, no hit
		 CMP BL,BH
		 JL GetBullet 
		 ; if obj.x < B.x + xVel, no hit
		 ADD BL,DH
		 CMP BL,BH
		 JG GetBullet
		 ; if B.x + xVel < obj.x < B.x, check yPos for a hit
		 JMP CheckYColli


	CheckYColli:
		 MOV BL, BYTE PTR [DI+1]
		 MOV BH, BYTE PTR [SI+1]
		 CMP BL,BH
		 JL GetBullet
		 ; We already checked the top block, only need to check 1 block down
		 ADD BH, 1											 ; 2 here is the height can be inputed as a variable in the barrel's data instead
		 ;MOV DL, BYTE PTR[SI+2]
		 ;ADD BH, DL 										In case of length variable
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
		 MOV BL,3											;Decreasing the velocity to half its value
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
		 CMP BL, '~'										
		 JZ NextBarrel										; If we finished checking all bullets, reset the current bullet, check the next barrel
		 JMP BarrelCollisions								; else, continue with the current barrel

	NextBarrel:
		 ADD SI, 2
		 ;ADD SI, 3 										;In case of length variable
		 MOV BL, [SI]
		 CMP BL, '~'										; if we finish checking for all barrel
		 JZ NoMoreBarrels								; stop iterating else, continue with the next barrel
		 JMP StartFromBullet1
NoMoreBarrels:

BarrelColls ENDP

StonepileColls PROC
; =================================================================================================
;  StonePile Collisions Checks
; =================================================================================================
	 
	 CMP CurrLevel,1
	 JE Level1StonePile
	 CMP CurrLevel,2
	 JE Level2StonePile

	 Level1StonePile:
	 	LEA SI, StonePile 										; To Iterate on the StonePile objects to check collisions ,  [SI] and [SI+1] are xPos and yPos of the StonePile
		JMP SPStartFromBullet1
	 Level2StonePile:
	 	LEA SI, StonePileLevel2
		JMP SPStartFromBullet1

SPStartFromBullet1:
	 LEA DI, P1Bullet1			 							; Starting with bullet 1
	 MOV DL,0
StonepileCollisions:
		 INC DL
		 MOV BL, BYTE PTR [DI + 4] 							; Carries the current bullet's active flag
		 CMP BL, 1				  							; Checking if the bullet is active
		 JZ CheckBullet			  						    ; If not, skip the collision check
		 JMP SPGetBullet

CheckBullet:
		 ;General Case: Collision occurs if xPos Bullet <= xPos Stonepile <= xPos + xVel Bullet && yPos Bullet <= yPos Stonepile <= yPos + yVel Bullet
		 ;For now implement the case where the bullet is straight
		 MOV BL, BYTE PTR [DI]								;Get the xPos of the bullet
		 MOV BH, BYTE PTR [SI]								;Get the xPos of the stonepile
		 MOV AH, BYTE PTR [DI + 2]
		 CMP BL,BH											; If the bullet exactly hit on the x, check the y
		 JZ SPCheckYColli
		 ADD BL,AH											; If the bullet WILL hit after moving, check the Y
		 CMP BL,BH
		 JZ SPCheckYColli
		 SUB BL,AH

		 CMP AH,0											; Since each bullet direction requires a different check
		 JG LTRBulletSP
		 JL RTLBulletSP


		 LTRBulletSP:
		 ; Check if B.x < obj.x < B.x + xVel
		 ; if B.x > obj.x, no hit
		 CMP BL, BH
		 JG SPGetBullet
		 ; if obj.x > B.x + xVel, no hit
		 ADD BL, AH
		 CMP BL, BH
		 JL SPGetBullet
		 ; if B.x < obj.x < B.x + xVel, check yPos for a hit.
		 JMP SPCheckYColli

		 RTLBulletSP:
		 ; Check if B.x + xVel < obj.x < B.x
		 ; if obj.x > B.x, no hit
		 CMP BL,BH
		 JL SPGetBullet 
		 ; if obj.x < B.x + xVel, no hit
		 ADD BL,AH
		 CMP BL,BH
		 JG SPGetBullet
		 ; if B.x + xVel < obj.x < B.x, check yPos for a hit
		 JMP SPCheckYColli


		;  CMP BL,BH
		;  JZ SPCheckYColli
		;  INC BH												;This is correct assuming the velocity is either +2 or -2
		;  CMP BL,BH
		;  JNZ SPGetBullet

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
		 CMP CL, '~'										
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
		 CMP BL, '~'										; if we finish checking for all stonepiles
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
	 MOV CL, NumBullets
	 ADD CL, ExtraNum
	 MOV CH, 0
	 LEA DI, P1Bullet1										; Starting with bullet 1

; =================================================================================================
; Player 1 collision checks 
; =================================================================================================

BulletPlayer1Col:
	 MOV AH , PLAYER_HEIGHT
	 MOV AL, BYTE PTR [DI + 4] 								; Carries the current bullet's active flag
	 CMP AL, 1				 								; Checking if the bullet is active
	 JNZ InactiveBullet1		  							; If not, skip the collision check
	 MOV BL, BYTE PTR [DI]	  								; Otherwise, load xPos and yPos into BL and BH
	 MOV BH, BYTE PTR [DI + 1]
	; Bullet velocity offset is 2
	; Check the bullet's direction
	; if velocity is +ve (LTR), check if B.x < obj.x < B.x + velx
	; if velocity is -ve (RTL), check if B.x > obj.x > B.x + velx
	; if any of the conditions fail, jump to NotNearP1

	CMP BYTE PTR [DI + 2], 0
	JG NotNearP1											; If the bullet is going to the right, it can't hit P1 ever
	CMP BL, 2D												; If the bullet hit exactly on the x, check the y
	JE CheckPlayer1CollisionsY
	ADD BL, BYTE PTR [DI+2]									; If the bull WILL hit after moving, check the Y
	CMP BL, 2D
	JE CheckPlayer1CollisionsY
	SUB BL, BYTE PTR [DI+2]

	; If B.x < 2, no hit
	CMP BL, 2D
	JL NotNearP1				
	; If B.x + xVel > 2 , no hit
	ADD BL, BYTE PTR [DI + 2]
	CMP BL, 2D
	JG NotNearP1
	; Otherwise, check the y position
	

	;  JA NotNearP1 			  								; If the bullet's xPos ≠ 2 (not near P1), check the next bullet, EDIT THIS IF WE NEED TO CHECK PAST THE FACE
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
	 MOV CL, NumBullets
	 ADD CL, ExtraNum
	 MOV CH, 0
	 LEA DI, P1Bullet1										; Starting with bullet 1

BulletPlayer2Col:
	 MOV AH , PLAYER_HEIGHT
	 MOV AL, BYTE PTR [DI + 4] 								; Carries the current bullet's active flag
	 CMP AL, 1				  								; Checking if the bullet is active
	 JNZ InactiveBullet2		  							; If not, skip the collision check
	 MOV BL, BYTE PTR [DI]	  								; Otherwise, load xPos and yPos into BL and BH
	 MOV BH, BYTE PTR [DI + 1]
	; Bullet velocity offset is 2
	; Check the bullet's direction
	; if velocity is +ve (LTR), check if B.x < obj.x < B.x + velx
	; if velocity is -ve (RTL), check if B.x > obj.x > B.x + velx
	; if any of the conditions fail, jump to NotNearP2

	CMP BYTE PTR [DI + 2], 0
	JL NotNearP2											; If the bullet is going to the left, it can't hit P2 ever
	CMP BL, 77D
	JE CheckPlayer2CollisionsY
	ADD BL, BYTE PTR [DI +2 ]
	CMP BL, 77D
	JE CheckPlayer2CollisionsY

	; If B.x > 77, no hit
	CMP BL, 77D
	JG NotNearP2			
	; If B.x + xVel < 77 , no hit
	ADD BL, BYTE PTR [DI + 2]
	CMP BL, 77D
	JL NotNearP2
	; Otherwise, check the y position

	 
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
	 CMP DL, 2												
	 JL DeactivateBullet										
	 CMP DL, 77
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
	 DisplayBuffer userName
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

	
 	 MOV CX, 0
 	 MOV CL, CactusNum
 	 	 
	 CMP CurrLevel,1
	 JE Level1CactusDraw
	 CMP CurrLevel,2
	 JE Level2CactusDraw

	 Level1CactusDraw:
	 	LEA SI, Cactus 										; To Iterate on the cactus objects to check collisions ,  [SI] and [SI+1] are xPos and yPos of the cactus
		JMP DrawCactus
	 Level2CactusDraw:
	 	LEA SI, CactusLevel2
		JMP DrawCactus

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
	 MOV CX, 0
	 MOV CL, BarrelNum

	 CMP CurrLevel,1
	 JE Level1BarrelDraw
	 CMP CurrLevel,2
	 JE Level2BarrelDraw

	 Level1BarrelDraw:
	 	LEA SI, Barrel 										; To Iterate on the Barrel objects to check collisions ,  [SI] and [SI+1] are xPos and yPos of the Barrel
		JMP DrawBarrel
	 Level2BarrelDraw:
	 	LEA SI, BarrelLevel2
		JMP DrawBarrel

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
	 MOV CX, 0
	 MOV CL, StonePileNum

	 CMP CurrLevel,1
	 JE Level1StonePileDraw
	 CMP CurrLevel,2
	 JE Level2StonePileDraw

	 Level1StonePileDraw:
	 	LEA SI, StonePile 										; To Iterate on the StonePile objects to check collisions ,  [SI] and [SI+1] are xPos and yPos of the StonePile
		JMP DrawStonePile
	 Level2StonePileDraw:
	 	LEA SI, StonePileLevel2
		JMP DrawStonePile


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

GetPlayerInput ENDP              
	
Player1Shoot PROC
	 LEA SI, PlayerOne
	 LEA DI, P1Bullet1										; Will be used to spawn the bullet in front of the player and set it as active
 
 
	 MOV AL, BYTE PTR [SI]									; AL = P1.xPos
	 MOV AH, BYTE PTR [SI + 1]								; AH = P1.yPos
	 DEC AH 												; Shifting the bullet 1 block up so it comes out from the middle of the player
	 DEC BYTE PTR[SI + 2]     					 			; Decrease the player's bullet stash by 1
	 INC AL													; Incrementing AL so that it's now in front of the player
	 
	 MOV BYTE PTR [DI],AL									; Setting the bullet's x coordinate 
	 MOV BYTE PTR [DI + 1], AH								; Setting the bullet's x coordinate 
	 MOV BYTE PTR [DI + 4], 1								; Setting the bullet's active flag
	 MOV BYTE PTR [SI+3],1								    ; Setting the player's bullets in the arena
 
	 MOV BL, ChosenDiff
	 MOV BYTE PTR [DI+2],BL							; Setting the bullet's horizontal speed (Done in difficulty setup now)
	 MOV BYTE PTR [DI+3],0									; Resetting the bullet's vertical speed (just in case)

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
	 ; AL = -1 * ChosenDiff
	 MOV BL,ChosenDiff
	 MOV AL, -1
	 MUL BL
	 MOV BYTE PTR [DI+2], AL								; reset the player xVel incase it was changed by an object
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
	 MOV AH, MaxBullets
	 MOV BYTE PTR [SI + 1], AL
	 MOV BYTE PTR [SI + 2], AH
	 MOV BYTE PTR [SI + 3], 0

; ---------------------------------------------------------------------------------------------------
; Reset Player2 Variables
; ---------------------------------------------------------------------------------------------------

	 LEA SI, PlayerTwo										; Reset xpos, ypos, bulletsCount, and bulletsInArena do
	 MOV AL, RightPlayerIitialCol							; Default values
	 MOV BYTE PTR [SI], AL
	 MOV AL, PlayerInitialRow
	 MOV AH, MaxBullets
	 MOV BYTE PTR [SI + 1], AL
	 MOV BYTE PTR [SI + 2], AH
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
	 DisplayBuffer userName  								
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

DifficultySelect PROC
	ClearScreen
	MoveCursor 18H, 0AH
	DisplayMessage ChooseDiff

	MoveCursor 18H, 0CH
	DisplayMessage Difficulties 

DiffMenu:
	MOV AH,0
	INT 16H

	CMP AH, 02
	JE ChoseEasy
	CMP AH, 03
	JE ChoseMedium
	JMP DiffMenu

; Change bullet speed depending on the chosen difficulty

ChoseEasy:	
	MOV ChosenDiff, 3
	MOV MaxBullets, 5
	JMP DiffChosen 			
ChoseMedium:
	MOV ChosenDiff, 6
	MOV MaxBullets, 3
	JMP DiffChosen

DiffChosen:
	RET
DifficultySelect ENDP

LevelSelect PROC
	ClearScreen
	MoveCursor 18H, 0AH
	DisplayMessage ChooseLevel

	MoveCursor 18H, 0CH
	DisplayMessage Levels 

LevelMenu:
	MOV AH,0
	INT 16H

	CMP AH, 02
	JE Level1
	CMP AH, 03
	JE Level2
	JMP LevelMenu

Level1:
	MOV CurrLevel,1
	JMP LevelChosen
Level2:
	MOV CurrLevel,2
	JMP LevelChosen

LevelChosen:
	RET
LevelSelect ENDP


MasterSendsData PROC
						 LEA           SI , FromMasterGameBuffer ;First bit contains the whole length
						 MOV			AL, 26D
						 MOV			BYTE PTR [SI],AL
						 INC			SI
						 LEA		   DI, PlayerOne
						 MOV			CX,4
			PrepareP1Data:
						 MOV			AL, BYTE PTR [DI]
						 MOV			BYTE PTR [SI],AL
						 INC			DI
						 INC			SI
						 LOOP			PrepareP1Data
						 MOV			AL, PlayerOneScore
						 MOV			BYTE PTR [SI],AL
						 INC			SI
						 MOV			AL, PlayerTwoScore
						 MOV			BYTE PTR [SI],AL
						 INC			SI
						 LEA		   	DI, RoundTime
						 MOV			AL, BYTE PTR [DI]
						 MOV			BYTE PTR [SI],AL
						 INC			SI
						 INC			DI
						 MOV			AL, BYTE PTR [DI]
						 MOV			BYTE PTR [SI],AL
						 INC			SI
						 MOV			AL, exiting
						 MOV			BYTE PTR [SI],AL
						 INC			SI

						 LEA		    DI, P1Bullet1
						 MOV			CX,15
			PrepareP1BulletData:
						 MOV			AL, BYTE PTR [DI]
						 MOV			BYTE PTR [SI+1],AL
						 INC			DI
						 INC			SI
						 LOOP			PrepareP1BulletData

						 MOV			AL, ReadyToSend
						 CMP			AL,0			;I.e Not ready to send the text only
						 JZ				SENDFLAGMSD
						 MOV			AL, localCharIndex
						 LEA           	DI , FromMasterGameBuffer ;First bit contains the whole size of the data sent
						 ADD			BYTE PTR [DI],AL

						 LEA			DI, SendBuffer
			PrepareP1Chat: 
						 MOV			AL, BYTE PTR [DI]
						 CMP            AL , '$'
						 JZ				SENDFLAGMSD
						 MOV			BYTE PTR [SI],AL
						 MOV			BYTE PTR [DI],'$'
						 INC			SI
						 INC			DI
						 JMP			PrepareP1Chat

	; Send FFH to tell the other side that something's coming
	SENDFLAGMSD:            
	                     mov           dx , 3FDH                          	; Line Status Register address
	AGAINFLAGMSD:           In            al , dx                            	; Read Line Status
	                     test          al , 00100000b                     	; Bit 6: transmit shift register empty
	                     JZ            AGAINFLAGMSD                          	; Not empty, skip this cycle

	; If the transmit data register is empty, sends the character to it
	                     mov           dx , 3F8H                          	; Transmit data register address
	                     mov           al , 0FFH
	                     out           dx , al
						 LEA           SI , FromMasterGameBuffer
	SENDCHARMSD:            
	; https://stanislavs.org/helppc/int_14.html
	; Check that Transmitter Holding Register is Empty
	                     mov           dx , 3FDH                          	; Line Status Register address
	AGAINMSD:               In            al , dx                            	; Read Line Status
	                     test          al , 00100000b                     	; Bit 6: transmit shift register empty
	                     JZ            AGAINMSD                              	; Not empty, skip this cycle


	; If the transmit data register is empty, sends the character to it
	                     mov           dx , 3F8H                          	; Transmit data register address
	                     mov           al , BYTE PTR [SI]
	                     out           dx , al
	                     MOV           AH, BYTE PTR [SI]
	                     MOV           BYTE PTR [SI], '$'                 	; CLEARING THE BUFFER FOR THE NEXT MASSEGES
	                     INC           SI
	                     CMP           AH , '$'
	                     JNE           SENDCHARMSD    

	                     RET

MasterSendsData	ENDP

SlaveRecievesMasterData PROC
	; https://stanislavs.org/helppc/int_14.html
	; Check that data recieve register is Ready             
	                     LEA           SI , FromMasterGameBuffer
						 MOV		   CX , 0				;Counts the number of bits
	                     mov           dx , 3FDH           	; Line Status Register address
	CHKSGM:              in            al , dx
	                     test          al , 1              	; Bit 1: data ready
	                     JZ            CHKSGM	         	; Not Ready, skip this cycle
	; If Ready read the VALUE in Receive data register
	                     mov           dx , 03F8H          	; Data recieving register address
	                     in            al , dx

	; CHECK FOR THE STOP BIT FLAG
	                     CMP           AL , 0FFH
	                     JE           StartSRM
						 JMP			ABORTSGM

StartSRM:
	                     LEA           SI , FromMasterGameBuffer		
	RECEIVECHARSBM:
	                     mov           dx , 3FDH           	; Line Status Register address
	CHK_RECEIVESGM:      in            al , dx
	                     test          al , 1              	; Bit 1: data ready
	                     JZ            CHK_RECEIVESGM         	; Not Ready, skip this cycle
						 
	                     mov           dx , 03F8H          	; Data recieving register address
	                     in            al , dx
	                     MOV           BYTE PTR [SI] , AL
	                     INC           SI
						 INC CL
						 CMP		   CL, 26D
						 JGE		   StartReadingChatData	
						 JMP 		   RECEIVECHARSBM

StartReadingChatData:
						LEA             SI , FromMasterGameBuffer
						LEA				DI, PlayerOne
						MOV				BH,0
						MOV				BL, BYTE PTR [SI]			;Contains All Buffer Length
						SUB				BX, CX						;BX	now contains chat length
						PUSH			BX
						MOV				BX,0
						MOV				CX, 4						
			AddP1Data:	MOV				AL, BYTE PTR [SI+BX+1]
						MOV				BYTE PTR [DI+BX],AL
						INC				BX
						LOOP			AddP1Data
						POP				BX
						MOV				AL, BYTE PTR [SI+5]
						MOV				PlayerOneScore, AL
						MOV				AL, BYTE PTR [SI+6]
						MOV				PlayerTwoScore, AL
						MOV				AL, BYTE PTR [SI+7]
						MOV				RoundTime, AL
						MOV				AL, BYTE PTR [SI+8]
						MOV				RoundTime+1, AL
						MOV				AL, BYTE PTR [SI+9]
						MOV				exiting, AL
						PUSH			BX
						MOV				CX, 15
						MOV				BX, 0
						LEA				DI, P1Bullet1
		BulletsDataSBM:	MOV				AL, BYTE PTR [SI+BX+10]
						MOV				BYTE PTR [DI+BX],AL
						INC				BX
						LOOP			BulletsDataSBM
						POP 			BX
						 MOV           CX, 30
	                     LEA           DI, FromMasterGameBuffer
	CLEAR_FromMasterGameBuffer:
	                     MOV           BYTE PTR [DI], '$'
	                     INC           DI
	                     LOOP          CLEAR_FromMasterGameBuffer
						
						MOV				CX, BX				;Chat char count + 1 stop Bit
	                     LEA            DI,ReceiveBuffer	
						PUSH			CX
						MOV				FromMasterChatLength, CL
	RECEIVECHARSBM2:
	                     mov           dx , 3FDH           	; Line Status Register address
	CHK_RECEIVESGM2:     in            al , dx
	                     test          al , 1              	; Bit 1: data ready
	                     JZ            CHK_RECEIVESGM2      ; Not Ready, skip this cycle
	                     mov           dx , 03F8H          	; Data recieving register address
	                     in            al , dx
					     MOV           BYTE PTR [DI] , AL
	                     INC           DI
						 CMP		   CL, 0FFH				;Check if it's the Stop bit
						 JZ		   	   FinishedReadingChatDataGMS	
						 JMP 		   RECEIVECHARSBM2

FinishedReadingChatDataGMS:
	                     POP		   CX
	                     LEA           DI,ReceiveBuffer
	CLEAR_RECEIVE_BUFFER_FORG:
	                     MOV           BYTE PTR [DI], '$'
	                     INC           DI
	                     LOOP          CLEAR_RECEIVE_BUFFER_FORG
	ABORTSGM:               
	                     RET
SlaveRecievesMasterData ENDP

SlaveSendData PROC
						 LEA           SI , FromSlaveGameBuffer ;First bit contains the whole length
						 MOV			AL, 8D
						 MOV			BYTE PTR [SI],AL
						 INC			SI
						 LEA		   DI, PlayerTwo
						 MOV			CX,4
			PrepareP2Data:
						 MOV			AL, BYTE PTR [DI]
						 MOV			BYTE PTR [SI],AL
						 INC			DI
						 INC			SI
						 LOOP			PrepareP2Data
						 MOV			AL, P2Fired
						 MOV			BYTE PTR [SI],AL
						 INC			SI
						 MOV			AL, exiting
						 MOV			BYTE PTR [SI],AL
						 INC			SI

						 MOV			AL, ReadtToSendS
						 CMP			AL,0			;I.e Not ready to send the text only
						 JZ				SENDFLAGSSD
						 MOV			AL, localCharIndex
						 LEA           	DI , FromSlaveGameBuffer ;First bit contains the whole size of the data sent
						 ADD			BYTE PTR [DI],AL

						 LEA			DI, SendBuffer
			PrepareP2Chat: 
						 MOV			AL, BYTE PTR [DI]
						 CMP            AL , '$'
						 JZ				SENDFLAGSSD
						 MOV			BYTE PTR [SI],AL
						 MOV			BYTE PTR [DI],'$'
						 INC			SI
						 INC			DI
						 JMP			PrepareP2Chat

	; Send FFH to tell the other side that something's coming
	SENDFLAGSSD:            
	                     mov           dx , 3FDH                          	; Line Status Register address
	AGAINFLAGSSD:           In            al , dx                            	; Read Line Status
	                     test          al , 00100000b                     	; Bit 6: transmit shift register empty
	                     JZ            AGAINFLAGSSD                          	; Not empty, skip this cycle

	; If the transmit data register is empty, sends the character to it
	                     mov           dx , 3F8H                          	; Transmit data register address
	                     mov           al , 0FFH
	                     out           dx , al
						 LEA           SI , FromSlaveGameBuffer
	SENDCHARSSD:            
	; https://stanislavs.org/helppc/int_14.html
	; Check that Transmitter Holding Register is Empty
	                     mov           dx , 3FDH                          	; Line Status Register address
	AGAINSSD:               In            al , dx                            	; Read Line Status
	                     test          al , 00100000b                     	; Bit 6: transmit shift register empty
	                     JZ            AGAINSSD                              	; Not empty, skip this cycle


	; If the transmit data register is empty, sends the character to it
	                     mov           dx , 3F8H                          	; Transmit data register address
	                     mov           al , BYTE PTR [SI]
	                     out           dx , al
	                     MOV           AH, BYTE PTR [SI]
	                     MOV           BYTE PTR [SI], '$'                 	; CLEARING THE BUFFER FOR THE NEXT MASSEGES
	                     INC           SI
	                     CMP           AH , '$'
	                     JNE           SENDCHARSSD    

	                     RET


SlaveSendData ENDP
	

MasterReceiveData PROC

	; https://stanislavs.org/helppc/int_14.html
	; Check that data recieve register is Ready             
	                     LEA           SI , FromSlaveGameBuffer
						 MOV		   CX , 0				;Counts the number of bits
	                     mov           dx , 3FDH           	; Line Status Register address
	CHKMRD:              in            al , dx
	                     test          al , 1              	; Bit 1: data ready
	                     JZ            CHKMRD	         	; Not Ready, skip this cycle
	; If Ready read the VALUE in Receive data register
	                     mov           dx , 03F8H          	; Data recieving register address
	                     in            al , dx

	; CHECK FOR THE STOP BIT FLAG
	                     CMP           AL , 0FFH
	                     JE           StartMRD
						 JMP			ABORTMRD
StartMRD:
	                     LEA           SI , FromMasterGameBuffer		
	RECEIVECHARMRD:
	                     mov           dx , 3FDH           	; Line Status Register address
	CHK_RECEIVEMRD:      in            al , dx
	                     test          al , 1              	; Bit 1: data ready
	                     JZ            CHK_RECEIVEMRD         	; Not Ready, skip this cycle
						 
	                     mov           dx , 03F8H          	; Data recieving register address
	                     in            al , dx
	                     MOV           BYTE PTR [SI] , AL
	                     INC           SI
						 INC CL
						 CMP		   CL, 8D
						 JGE		   StartReadingChatData2	
						 JMP 		   RECEIVECHARMRD
StartReadingChatData2:
						LEA             SI , FromSlaveGameBuffer
						LEA				DI, PlayerTwo
						MOV				BH,0
						MOV				BL, BYTE PTR [SI]			;Contains All Buffer Length
						SUB				BX, CX						;BX	now contains chat length
						PUSH			BX
						MOV				BX,0
						MOV				CX, 4						
			AddP2Data:	MOV				AL, BYTE PTR [SI+BX+1]
						MOV				BYTE PTR [DI+BX],AL
						INC				BX
						LOOP			AddP2Data
						POP				BX
						MOV				AL, BYTE PTR [SI+5]
						MOV				P2Fired, AL
						MOV				AL, BYTE PTR [SI+6]
						MOV				exiting, AL
						 MOV           CX, 10
	                     LEA           DI, FromSlaveGameBuffer
	CLEAR_FromSlaveGameBuffer:
	                     MOV           BYTE PTR [DI], '$'
	                     INC           DI
	                     LOOP          CLEAR_FromSlaveGameBuffer
						
						MOV				CX, BX				;Chat char count + 1 stop Bit
	                     LEA            DI,ReceiveBuffer	
						PUSH			CX
						MOV				FromSlaveChatLength, CL
	RECEIVECHARMRD2:
	                     mov           dx , 3FDH           	; Line Status Register address
	CHK_RECEIVEMRD2:     in            al , dx
	                     test          al , 1              	; Bit 1: data ready
	                     JZ            CHK_RECEIVEMRD2      ; Not Ready, skip this cycle
	                     mov           dx , 03F8H          	; Data recieving register address
	                     in            al , dx
					     MOV           BYTE PTR [DI] , AL
	                     INC           DI
						 CMP		   CL, 0FFH				;Check if it's the Stop bit
						 JZ		   	   FinishedReadingChatDataMRD	
						 JMP 		   RECEIVECHARMRD2

FinishedReadingChatDataMRD:
	                     POP		   CX
	                     LEA           DI,ReceiveBuffer
	CLEAR_RECEIVE_BUFFER_FORG2:
	                     MOV           BYTE PTR [DI], '$'
	                     INC           DI
	                     LOOP          CLEAR_RECEIVE_BUFFER_FORG2
	ABORTMRD:               
	                     RET
MasterReceiveData ENDP
; End file and tell the assembler what the main subroutine is
    END MAIN 

