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

; TODOS
; ============================================================================================================
;    1- Require the user to press enter before displaying the typed characters at the other side
;       this might require having a buffer that stores characters. Then after the user presses enter, the buffer
;       will be sent byte by byte along its size to the other user, after the buffer is sent, the other side can
;       display the whole string at once (will require a large string pre-allocated)
;    2- After a massege is sent, drop the your cursor on the other size by 1 row (INC OtherCursorPos.y)
;    3- Scroll down automatically on reachin the bottom border
;    4- Add scrolling up and down with the arrow keys (check Lab 2 for more info)
;    5- Display the names of each side
;    6- Add the footer
;    7- https://music.youtube.com/watch?v=QkFJau6aK3w&list=OLAK5uy_kqBgrX1-hKk1i0zb3MWS6R4tu5SmRjYdk (not a rickroll I swear)

; How to use
; ============================================================================================================
; First, download the virtual port driver and install it from: https://www.eltima.com/products/vspdxp/
; Select "download", then "STANDARD"
; Then, follow the instructions in the lab: https://drive.google.com/file/d/18Y-l5dkBYDNZbU-aDfM1E6Nw9gUD4neV/view?usp=sharing
;
;
;
; If you're using the VSCode extension exclusively, you can find its DOSBox config file at : C:\Users\YOUR USERNAME\.vscode\extensions\xsro.masm-tasm-0.7.0\resources\VSC-ExtUse.conf (Yes, it does use its own seperate DOSBox)
; Add the following lines:
;         [serial]
;         serial1=directserial realport:COM1
; Then you use "Run ASM code" to fire up 2 DOSBox instances and test
;
;
;
; If you use vanilla DOSBox or for debugging, you can find DOSBox's config at : C:\Users\YOUR USERNAME\AppData\Local\DOSBox\dosbox-0.74-3.conf
; It already has the serial section, so no need to add that 
; For ease of use, you can make DOSBox masm and link the object automatically at launch (this is what the extension does too!)
; Add the following lines to the end of the config file: 
;         MOUNT C PATH (Will show you how to get that later on)
;         C:
;         MASM FILENAME.ASM;
;         LINK FILENAME.OBJ;
;         FILENAME 
; Then you can run 1 instance with COM1, change the config to COM2 (don't forget to save), run the other instance
; To get the DOS compatible path (since it can handle names 8 characters long at most), you can open a command window,
; run the following commands: 
;         cd "FILE PATH FROM WINDOWS EXPLORER" 
;         for %I in (.) do echo %~sI
; cd: current directory, sets the current command window's directory to the specified path
; Copy the output path, should be similar to "C:\Users\tarek\Desktop\College\YEAR2~1\MICROP~1\Project\ASSEMB~1"
; put it in place of "PATH"
; Source: https://stackoverflow.com/questions/36684753/invalid-dos-path-in-dosbox
.MODEL SMALL
.STACK 64
.DATA
	UPPER_COLOR    DB 00FH	; 0 For black BG and F for white FG (text)
	LOWER_COLOR    DB 0F0H	; Reverse the above
	MyCursorPos    DB 0,0 	; x,y for the current side's cursor (Local messages will be displayed at the top)
	OtherCursorPos DB 0,13	; x,y for the other end's cursor (Away messages will be displayed at the bottom)
	Recieved       DB 0   	; The recieved character
	Sent           DB 0     ; The sent character
.CODE
MAIN PROC FAR
	        MOV         AX,@DATA
	        MOV         DS,AX

	; Used later to update the info for the x & y of each side's cursor
	        LEA         SI, MyCursorPos
	        LEA         DI, OtherCursorPos

	; Clears the screen, colors the top half and the bottom half
	        CALL        INIT

	lewp:   
	        CALL        Send
	        CALL        Recieve
	        JMP         lewp

	        DisplayChar 'A'
	        DisplayChar 'A'
	        DisplayChar 'A'
	        MOV         AH,4CH
	        INT         21H
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
	        mov         ah,6              	; function 6 (How descriptive, Eng.Sandra...)
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
	        MOV         AH,1
	        INT         16H               	; Sets the ZF = 0 if a key is available, ZF = 1 if not
	        JZ          NoInput           	; Skips sending any character if ZF = 1 to avoid repeating characters
            
	; If it was, get it, display it then send it
	        MOV         AH,0
	        INT         16H
	        MOV         Sent,AL           	; Stores it, probably not needed though since AL is not used later

	; Display the character
	        MOV         BL,BYTE PTR [SI]  	; Loads the local cursor's x
	        MOV         BH,BYTE PTR [SI+1]	; Same but for the y
	        MoveCursor  BL,BH             	; Moves the cursor to the top half
	        DisplayChar Sent
	        INC         BYTE PTR [SI]     	; Moves the x coordinate by 1 to the right to avoid overwriting

	; If the transmit data register is empty, sends the character to it
	        mov         dx , 3F8H         	; Transmit data register address
	        mov         al, Sent
	        out         dx , al
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

	; Displays the recieved character
	        MOV         CL,BYTE PTR [DI]  	; x
	        MOV         CH,BYTE PTR [DI+1]	; y
	        MoveCursor  CL,CH
	        DisplayChar Recieved
	        INC         BYTE PTR [DI]     	; Moves the away cursor 1 character to the right
	ABORT:  
	        RET
Recieve ENDP
END MAIN
