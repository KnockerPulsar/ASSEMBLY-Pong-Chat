DisplayChar MACRO Char
	            MOV AH,2
	            MOV DL,Char
	            INT 21H
ENDM
MoveCursor MACRO X,Y
	           mov ah,2
	           MOV DL, X
	           MOV DH, Y
	           int 10h
ENDM
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

ClearBuffer MACRO
	PUSH AX
	MOV AH, 0CH
	MOV AL, 02H
	INT 21H
	POP AX
ENDM

.Model SMALL
.STACK 100

.DATA

	UPPER_COLOR    DB 00FH	; 0 For black BG and F for white FG (text)
	LOWER_COLOR    DB 0F0H	; Reverse the above
	MyCursorPos    DB 0,0 	; x,y for the current side's cursor (Local messages will be displayed at the top)
	OtherCursorPos DB 0,13	; x,y for the other end's cursor (Away messages will be displayed at the bottom)
	Recieved       DB 0   	; The recieved character
	Sent           DB 0     ; The sent character
	RecieveBuffer  DB 30,30 dup('$') ;First byte is the size, second byte is the number of characters from the keyboard
	SendBuffer     DB 30,30 dup('$') ;First byte is the size ///NOT USED
	SendIndex	   DB 1					;///NOT USED
    ReceivedSize   DB 0
    sentflag       DB 0
    recieveflag    DB 0

.CODE

MAIN PROC  FAR

MOV AX, @DATA
MOV DS, AX

CALL INIT

mainloop:

    checkSending:
        MOV AH, 1
        INT 16H
        JZ checkRecieving           ; if not go check recieve
		
		ClearBuffer

        cmp ah, 3Bh     			; Check if F1 was pressed
        JNZ NotF1
		JMP sendchat
		NotF1:
        cmp ah, 3ch					; Check if F2 was pressed
		JNZ NotF2
        JMP sendgame
		NotF2:
        cmp ah, 1					; Check if ESC was pressed
        JNZ NotESC
		JMP sendexit
		NotESC:

    checkRecieving:
        CALL Recieve
        LEA DI, recieveflag
        cmp BYTE PTR [DI], 1
        jnz mainloop

        lea si,  Recieved
        checkrecievedchat:
            cmp BYTE PTR [si], "Y"
            jz chatting
        chechrecievedgame:
            cmp byte ptr [si], "R"
            jz Game
        checkrecievedexit:
            cmp byte ptr [si], "I"
            jz Exit


        checkchat:
            cmp byte ptr [si], "C"
            jnz checkgame
            lea di,  Sent
            mov byte ptr [di], "Y"
            call Send
            jmp chatting

        checkgame:
            cmp byte ptr [si], "G"
            jnz checkexiting
            lea di, Sent
            mov byte ptr [di], "R"
            call Send
            jmp Game

        checkexiting:
            cmp byte ptr [si], "E"
            jnz mainloop
            lea di, Sent
            mov byte ptr [di], "I"
            call Send
            jmp Exit

        
    sendchat:
		
        lea di, Sent
        MOV byte ptr [DI], "C"
        call Send
        mov si, offset sentflag
        cmp byte ptr [si],1
        jnz sendchat
        jmp mainloop
    sendgame:
        lea di, Sent
        mov byte ptr [DI], "G"
        call Send
        mov si, offset sentflag
        cmp byte ptr [si],1
        jnz sendgame
        jmp mainloop
        
    sendexit:
        lea di, Sent
        mov byte ptr [DI], "E"
        call Send
        mov si, offset sentflag
        cmp byte ptr [si],1
        jnz sendexit
        jmp mainloop

chatting:
Game:
Exit:
DisplayChar Recieved

MOV AH, 0
INT 16H

; Exits the program
		 MOV            AH, 4CH
		 INT            21H

MAIN ENDP


INIT PROC
	; The below block was copied straight out of the lab
	;  Set Divisor Latch Access Bit
	        mov         dx,3fbh           	; Line Control Register
	        mov         al,10000000b      	;Set Divisor Latch Access Bit
	        out         dx,al             	;Out it
	;  Set LSB byte of the Baud Rate Divisor Latch register.
	        mov         dx,3f8h
	        mov         al,0ch
	        out         dx,al
	;  Set MSB byte of the Baud Rate Divisor Latch register.
	        mov         dx,3f9h
	        mov         al,00h
	        out         dx,al
	;  Set port configuration
	        mov         dx,3fbh
	        mov         al,00011011b
	;  0:Access to Receiver buffer, Transmitter buffer
	;  0:Set Break disabled
	;  011:Even Parity
	;  0:One Stop Bit
	;  11:8bits
	        out         dx,al

	; This was also copied but modified a bit
	; Clear screen
	        MOV         AH,0
	        INT         10H

	; Might be useful to convert to a macro/proc later as it'll be used to scroll
	; Colors the top half
	        mov         ah,6              	; function 6
	        mov         al,0              	; How many lines to scroll
	        mov         bh,UPPER_COLOR    	; Black FG and white BG
	        mov         ch,0              	; upper left Y
	        mov         cl,0              	; upper left X
	        mov         dh,12             	; lower right Y
	        mov         dl,79             	; lower right X
	        int         10h

	; Colors the bottom half
	        mov         ah,6
	        mov         al,0
	        mov         bh,LOWER_COLOR    	; White BG and black FG
	        mov         ch,13
	        mov         cl,0
	        mov         dh,24
	        mov         dl,79
	        int         10h

	        RET
INIT ENDP


Send PROC
	; https://stanislavs.org/helppc/int_14.html
	; Check that Transmitter Holding Register is Empty
	        mov         dx , 3FDH         	; Line Status Register address
	AGAIN:  In          al , dx           	; Read Line Status
	        test        al , 00100000b    	; Bit 6: transmit shift register empty
	        JZ          Skip              	; Not empty, skip this cycle
            
	; https://vitaly_filatov.tripod.com/ng/asm/asm_027.2.html
	; Check if a key is pressed
	;         MOV         AH,1
	;         INT         16H               	; Sets the ZF = 0 if a key is available, ZF = 1 if not
	;         JZ          NoInput           	; Skips sending any character if ZF = 1 to avoid repeating characters
            
	; ; If it was, get it, display it then send it
	;         MOV         AH,0
	;         INT         16H
	;         MOV         Sent,AL           	; Stores it, probably not needed though since AL is not used later

	; Display the character
	       
			; CMP BL,79
			; JNZ continue

	        ; MoveCursor  BL,BH             	; Moves the cursor to the top half
	        ; INC         BL     	; Moves the x coordinate by 1 to the right to avoid overwriting

	; If the transmit data register is empty, sends the character to it
	        mov         dx , 3F8H         	; Transmit data register address
	        mov         al, Sent
	        out         dx , al
            mov si, offset sentflag
            mov byte ptr [si], 1
	NoInput:
	Skip:   
	        RET
Send ENDP

Recieve PROC
	; https://stanislavs.org/helppc/int_14.html
	; Check that data recieve register is Ready
	        mov         dx , 3FDH         	; Line Status Register address
	CHK:    in          al , dx
	        test        al , 1            	; Bit 1: data ready
	        JZ          ABORT             	; Not Ready, skip this cycle

	; If Ready read the VALUE (WHY ARE YOU SCREAMING, ENG. SANDRA?!?) in Receive data register
	        mov         dx , 03F8H        	; Data recieving register address
	        in          al , dx
	        mov         Recieved , al     	; Stores the recieved character
            LEA SI, recieveflag
            mov byte ptr [si], 1
	; Displays the recieved character
	       
	        ; MoveCursor  CL,CH
	        ; INC        	CL     	; Moves the away cursor 1 character to the right
	ABORT:  
	        RET
Recieve ENDP

END MAIN







