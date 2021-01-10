DisplayChar MACRO Char
	            MOV AH,2
	            MOV DL,Char
	            INT 21H
ENDM
MoveCursor MACRO X,Y
	           MOV BH,0
	           mov ah,2
	           MOV DL, X
	           MOV DH, Y
	           int 10h
ENDM
DisplayString MACRO String
	              MOV AH, 9
	              MOV DX, OFFSET String
	              INT 21H
ENDM
DisplayBuffer MACRO Buffer
	              MOV AH, 9
	              MOV DX, OFFSET Buffer + 2
	              INT 21H
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

; How to use
; ============================================================================================================
; First, download the virtual port driver and install it from: https://www.eltima.com/products/vspdxp/
; Select "download", then "STANDARD"
; Then, follow the instructions in the lab: https://drive.google.com/file/d/18Y-l5dkBYDNZbU-aDfM1E6Nw9gUD4neV/view?usp=sharing
;
;
;
; If you're using the VSCode extension exclusively, 
; you can find its DOSBox config file at : C:\Users\YOUR USERNAME\.vscode\extensions\xsro.masm-tasm-0.7.0\resources\VSC-ExtUse.conf (Yes, it does use its own seperate DOSBox)
; 
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
	;    ORG 100
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
	ReceiveBuffer  DB 80 DUP('$'),0FEH
	otherCharIndex DB 0
.CODE
MAIN PROC FAR
	                     MOV           AX,@DATA
	                     MOV           DS,AX

	; Clears the screen, splits the top half and the bottom half
	                     CALL          INIT
	; Do master/slave name initialization
	                     CALL          ExchangeNames
	; Display the name of each side
	                     CALL          DisplayNames

	lewp:                
	                     CALL          Send
	                     CALL          Recieve
	                     JMP           lewp

	                     MOV           AH,4CH
	                     INT           21H
MAIN ENDP

INIT PROC

	; Clear screen
	                     MOV           AH,0
	                     INT           10H

	; Might be useful to convert to a macro/proc later as it'll be used to scroll
	; Colors the top half
	                     mov           ah,6                	; function 6
	                     mov           al,0                	; How many lines to scroll
	                     mov           bh,UPPER_COLOR      	; Black FG and white BG
	                     mov           ch,0                	; upper left Y
	                     mov           cl,0                	; upper left X
	                     mov           dh,11               	; lower right Y
	                     mov           dl,79               	; lower right X
	                     int           10h

	; Colors the bottom half
	                     mov           ah,6
	                     mov           al,0
	                     mov           bh,LOWER_COLOR      	; White BG and black FG
	                     mov           ch,12
	                     mov           cl,0
	                     mov           dh,24
	                     mov           dl,79
	                     int           10h

	                     RET


	; The below block was copied straight out of the lab
	;  Set Divisor Latch Access Bit
	                     mov           dx,3fbh             	; Line Control Register
	                     mov           al,10000000b        	;Set Divisor Latch Access Bit
	                     out           dx,al               	;Out it
	;  Set LSB byte of the Baud Rate Divisor Latch register.
	                     mov           dx,3f8h
	                     mov           al,0ch
	                     out           dx,al
	;  Set MSB byte of the Baud Rate Divisor Latch register.
	                     mov           dx,3f9h
	                     mov           al,00h
	                     out           dx,al
	;  Set port configuration
	                     mov           dx,3fbh
	                     mov           al,00011011b
	;  0:Access to Receiver buffer, Transmitter buffer
	;  0:Set Break disabled
	;  011:Even Parity
	;  0:One Stop Bit
	;  11:8bits
	                     out           dx,al

	
	                     RET
INIT ENDP

Send PROC
	; https://vitaly_filatov.tripod.com/ng/asm/asm_027.2.html
	; Check if a key is pressed
	                     MOV           AH,1
	                     INT           16H                 	; Sets the ZF = 0 if a key is available, ZF = 1 if not
	                     JNZ           Input               	; Skips sending any character if ZF = 1 to avoid repeating characters
	                     JMP           NoInput
            
	Input:               
	; If it was, get it, display it then send it
	                     MOV           AH,0
	                     INT           16H

	                     LEA           SI , SendBuffer
	                     MOV           CH , 0
	                     MOV           CL , localCharIndex
	                     ADD           SI , CX
	                     LEA           DI , MyCursorPos

	                     CMP           AL, 08H             	; Check if the user pressed backspace
	                     JE            Backspace
	                     CMP           AL , 0DH            	; Check if the user pressed enter
	                     JE            SendBufferLBL

	; Put the character in the send buffer AND DISPLAY IT
	                     CMP           BYTE PTR [SI+1],0FEH	; Check if the next character is 0FEH (BUFFER END)
	                     JE            NoInput             	; DON'T ADD ANY MORE IF SO
	                     MOV           BYTE PTR [SI], AL   	; MOVE THE CHAR IN THE BUFFER
	                     INC           localCharIndex      	; INCR THE BUFFER INDEX
	                     MOV           CL,BYTE PTR [DI]    	; Loads the local cursor's x
	                     MOV           CH,BYTE PTR [DI+1]  	; Same but for the y
	                     MoveCursor    CL,CH               	; Moves the cursor to the top half
	                     DisplayChar   AL
	                     INC           BYTE PTR [DI]       	; Moves the x coordinate by 1 to the right to avoid overwriting
	                     JMP           CharWritten

	Backspace:           
	                     CMP           localCharIndex,1    	; CAN'T BACKSPACE PAST THE FIRST CHARACTER
	                     JL            NoInput
	                     DEC           BYTE PTR [DI]       	; DEC X
	                     MOV           CL , BYTE PTR [DI]  	; Loads the local cursor's x
	                     MOV           CH , BYTE PTR [DI+1]	; Same but for the y
	                     MoveCursor    CL , CH
	                     DisplayChar   ' '                 	; HIDES THE PREVIOUS CHAR
	                     MoveCursor    CL , CH
	                     DEC           SI
	                     MOV           BYTE PTR [SI], '$'
	                     DEC           localCharIndex
	                     JMP           CharWritten
	SendBufferLBL:       
	                     MOV           localCharIndex , 0
	                     MOV           BYTE PTR [DI] , 0
	                     INC           BYTE PTR [DI+1]     	; MOVE THE CURSOR TO THE LINE BELOW
	                     MOV           CL, BYTE PTR [DI]
	                     MOV           CH, BYTE PTR [DI+1]
	                     MoveCursor    CL,CH
	                     CMP           BYTE PTR [DI+1],11D
	                     JL            DontScrollMasterUp
	                     CALL          ScrollMasterUp
	DontScrollMasterUp:  
	                     CALL          SENDBUFFERPROC
	
	NoInput:             
	CharWritten:         
	                     RET
Send ENDP

Recieve PROC
	; https://stanislavs.org/helppc/int_14.html
	; Check that data recieve register is Ready
	START:               
	                     LEA           SI , ReceiveBuffer
	                     mov           dx , 3FDH           	; Line Status Register address
	CHK:                 in            al , dx
	                     test          al , 1              	; Bit 1: data ready
	                     JZ            ABORT               	; Not Ready, skip this cycle
	; If Ready read the VALUE (WHY ARE YOU SCREAMING, ENG. SANDRA?!?) in Receive data register
	                     mov           dx , 03F8H          	; Data recieving register address
	                     in            al , dx

	; CHECK FOR THE FLAG
	                     CMP           AL , 0FFH
	                     JNE           ABORT

	                     LEA           SI , ReceiveBuffer
						 
	
	RECEIVECHAR:         
	                     mov           dx , 3FDH           	; Line Status Register address
	CHK_RECEIVE:         in            al , dx
	                     test          al , 1              	; Bit 1: data ready
	                     JZ            CHK_RECEIVE         	; Not Ready, skip this cycle
						 
	                     mov           dx , 03F8H          	; Data recieving register address
	                     in            al , dx
	                     MOV           BYTE PTR [SI] , AL
	                     INC           SI
	;  DisplayChar   AL
	                     CMP           AL , '$'
	                     JE            DISPLAYRECEIVED
	                     JMP           RECEIVECHAR
	DISPLAYRECEIVED:     
	                     LEA           SI, OtherCursorPos
	                     MOV           BYTE PTR [SI], 0
	                     MOV           CL, BYTE PTR [SI]
	                     MOV           CH, BYTE PTR [SI+1]
	                     MoveCursor    CL,CH
	                     DisplayString ReceiveBuffer
	                     INC           BYTE PTR [SI+1]

	                     MOV           CX, 30
	                     LEA           DI,ReceiveBuffer
	                     CMP           BYTE PTR [SI+1], 24
	                     JL            DontScrollSlaveUp
	                     CALL          ScrollSlaveUp
	DontScrollSlaveUp:   
	CLEAR_RECEIVE_BUFFER:
	                     MOV           BYTE PTR [DI], '$'
	                     INC           DI
	                     LOOP          CLEAR_RECEIVE_BUFFER
	ABORT:               
	                     RET
Recieve ENDP

	
ReceiveOtherName PROC
	
	; Receiving the name from the other side
	                     LEA           DI, OtherName
	                     LEA           SI, OtherCursorPos
	
	; Check that data recieve register is Ready
	RecieveNextCharacter:
	                     mov           dx , 3FDH           	; Line Status Register address
	CHKEXG:              in            al , dx
	                     test          al , 1              	; Bit 1: data ready
	                     JZ            CHKEXG              	; Not Ready, skip this cycle

	; If Ready read the VALUE (WHY ARE YOU SCREAMING, ENG. SANDRA?!?) in Receive data register
	                     mov           dx , 03F8H          	; Data recieving register address
	                     in            al , dx
	                     mov           BYTE PTR [DI] , al  	; Stores the recieved character
	                     CMP           BYTE PTR [DI],'$'
	                     JE            EndNameReceiving

	                     INC           DI
	                     JMP           RecieveNextCharacter
	EndNameReceiving:    
	                     RET
ReceiveOtherName ENDP

SendMyName PROC
	
	; Sending out my own name
	; This can send up to 16 characters or until it encounters a '$'
	; Check that Transmitter Holding Register is Empty
	; Load how many characters are in the name
	                     LEA           DI, MyName
	; Points DI at the first character
	                     ADD           DI,2
	                     LEA           SI,MyCursorPos
	 					 
	SendNextCharacter:   
	                     mov           dx , 3FDH           	; Line Status Register address
	AGAINEXG:            In            al , dx             	; Read Line Status
	                     test          al , 00100000b      	; Bit 6: transmit shift register empty
	                     JZ            AGAINEXG            	; Not empty, skip this cycle
	 
	; Then sends out the characters byte by byte
	; If the transmit data register is empty, sends the character to it
	                     mov           dx , 3F8H           	; Transmit data register address
	                     mov           al, BYTE PTR [DI]
	                     out           dx , al
 
	; Next character
	                     CMP           BYTE PTR[DI], '$'
	                     JE            EndNameSending
 
	                     INC           DI
	                     JMP           SendNextCharacter
	EndNameSending:      
	                     RET
SendMyName ENDP

ExchangeNames PROC
	                     CMP           Master,1
	                     JE            MasterLBL
	                     JNE           SlaveLBL

	MasterLBL:           
	CHKEsadsadsdXG:      mov           dx , 3FDH           	; Line Status Register address
	                     in            al , dx
	                     test          al , 1              	; Bit 1: data ready
	                     JZ            CHKEsadsadsdXG      	; Not Ready, skip this cycle

	; Loop until you receive FFH from the slave
	                     mov           dx , 03F8H          	; Data recieving register address
	                     in            al , dx
	                     CMP           al,0FFH
	                     jne           CHKEsadsadsdXG

	; Once FFH is received, exchange names
	                     CALL          SendMyName
	                     CALL          ReceiveOtherName
	                     JMP           FinishNameInit

	SlaveLBL:            
	                     mov           dx , 3FDH           	; Line Status Register address
	sadsadsa:            
	                     In            al , dx             	; Read Line Status
	                     test          al , 00100000b      	; Bit 6: transmit shift register empty
	                     JZ            sadsadsa            	; Not empty, skip this cycle

	; Once the slave program runs, sends FFH to the master to inform it that it is ready
	                     mov           dx , 3F8H           	; Transmit data register address
	                     mov           al , 0FFH
	                     out           dx , al

	                     CALL          ReceiveOtherName
	                     CALL          SendMyName
	                     JMP           FinishNameInit

	FinishNameInit:      
	                     RET
ExchangeNames ENDP

DisplayNames PROC
	                     LEA           SI, MyCursorPos
	                     MOV           CL, BYTE PTR [SI]
	                     MOV           CH, BYTE PTR [SI+1]
	                     MoveCursor    CL,CH
	                     DisplayBuffer MyName
	                     INC           BYTE PTR [SI+1]
	                     MOV           BYTE PTR [SI], 0

	                     LEA           DI, OtherCursorPos
	                     MOV           CL, BYTE PTR [DI]
	                     MOV           CH, BYTE PTR [DI+1]
	                     MoveCursor    CL,CH
	                     DisplayString OtherName
	                     INC           BYTE PTR [DI+1]
	                     MOV           BYTE PTR [DI], 0
	                     RET
DisplayNames ENDP

SENDBUFFERPROC PROC
		
	                     LEA           SI , SendBuffer
	; Send FFH to tell the other side that something's coming
	SENDFLAG:            
	                     mov           dx , 3FDH           	; Line Status Register address
	AGAINFLAG:           In            al , dx             	; Read Line Status
	                     test          al , 00100000b      	; Bit 6: transmit shift register empty
	                     JZ            AGAINFLAG           	; Not empty, skip this cycle

	; If the transmit data register is empty, sends the character to it
	                     mov           dx , 3F8H           	; Transmit data register address
	                     mov           al , 0FFH
	                     out           dx , al

	SENDCHAR:            
	; https://stanislavs.org/helppc/int_14.html
	; Check that Transmitter Holding Register is Empty
	                     mov           dx , 3FDH           	; Line Status Register address
	AGAIN:               In            al , dx             	; Read Line Status
	                     test          al , 00100000b      	; Bit 6: transmit shift register empty
	                     JZ            AGAIN               	; Not empty, skip this cycle


	; If the transmit data register is empty, sends the character to it
	                     mov           dx , 3F8H           	; Transmit data register address
	                     mov           al , BYTE PTR [SI]
	                     out           dx , al
	                     MOV           AH, BYTE PTR [SI]
	                     MOV           BYTE PTR [SI], '$'  	; CLEARING THE BUFFER FOR THE NEXT MASSEGES
	                     INC           SI
	                     CMP           AH , '$'
	                     JNE           SENDCHAR
	NothingReceived:     

	                     RET

SENDBUFFERPROC ENDP

	; Master is the upper half, from (0,0) to (79,11)
ScrollMasterUp PROC
	; AL = lines to scroll (0 = clear, CH, CL, DH, DL are used),
	; BH = Background Color and Foreground color. BH = 43h, means that background color is red and foreground color is cyan. Refer the BIOS color attributes
	; CH = Upper row number, CL = Left column number, DH = Lower row number, DL = Right column number
	                     MOV           AL , 1
	                     MOV           BH , UPPER_COLOR
	                     MOV           CH , 0
	                     MOV           CL , 0
	                     MOV           DH , 11D
	                     MOV           DL , 79D
	                     MOV           AH , 6D
	                     INT           10H

	                     LEA           SI, MyCursorPos
	                     SUB           BYTE PTR [SI+1],1

	                     MoveCursor    0,0
	                     DisplayBuffer MyName
	                     MOV           CL, BYTE PTR [SI]
	                     MOV           CH, BYTE PTR [SI+1]
	                     MoveCursor    CL,CH

	                     RET

ScrollMasterUp ENDP

	; Slave is the lower half, from (0,11) to (79,24)
ScrollSlaveUp PROC
	                     MOV           AL , 1
	                     MOV           BH , LOWER_COLOR
	                     MOV           CH , 12D
	                     MOV           CL , 0
	                     MOV           DH , 24D
	                     MOV           DL , 79D
	                     MOV           AH , 6D
	                     INT           10H

	                     LEA           SI, OtherCursorPos
	                     SUB           BYTE PTR [SI+1],1

	                     MoveCursor    0,12
	                     DisplayString OtherName

	                     MOV           CL, BYTE PTR [SI]
	                     MOV           CH, BYTE PTR [SI+1]
	                     MoveCursor    CL,CH

	                     RET
ScrollSlaveUp ENDP
END MAIN
