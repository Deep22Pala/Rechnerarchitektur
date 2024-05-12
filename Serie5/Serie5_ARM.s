/*
-----------------------------------------------------------
 Series 4 - Raspberry Pi Programming Part 1 - Running Light
 
 Group members:
 Mikael Ruben 23-108-434, Andrin Müller 20-745-469, Deepak Palapurackal 19-746-833
 
 Individualised code by:
 Deepak Palapurackal 19-746-833
 
 
 Exercise Version:
 Version 1


 
-----------------------------------------------------------
*/

.global main
.func main

main:
	// This will setup the wiringPi library.
	// In case something goes wrong, we exit the program
	BL	wiringPiSetupGpio		
	CMP	R0, #-1			
	BEQ	exit


configurePins:
	// Set the data pin to 'output' mode
	LDR	R0, .DATA_PIN
	LDR	R1, .OUTPUT
	BL	pinMode

	// Set the latch pin to 'output' mode
	/* to be implemented by student */
	LDR R0, .LATCH_PIN
	LDR R1, .OUTPUT
	BL pinMode

	// Set the clock pin to 'output' mode
	/* to be implemented by student */
	LDR R0, .CLOCK_PIN
	LDR R1, .OUTPUT
	BL pinMode

	// Set the pins of BUTTON 1 and BUTTON 2 to 'input' mode 
	/* to be implemented by student */
	LDR R0, .BUTTON1_PIN
	LDR R1, .INPUT
	BL pinMode

	LDR R0, .BUTTON2_PIN
	LDR R1, .INPUT
	BL pinMode


	LDR	R0, .BUTTON1_PIN
	LDR	R1, .PUD_UP
	BL	pullUpDnControl

	LDR	R0, .BUTTON2_PIN
	LDR	R1, .PUD_UP
	BL	pullUpDnControl

	// Set the buzzer pin to 'output' mode
	LDR R0, .BUZZER_PIN
	LDR R1, .OUTPUT
	BL pinMode


startCondition:
	// Check if button 2 is pressed to start/ restart the Game
	LDR R0, .BUTTON2_PIN // Load the button 2 pin to R0
	MOV R1, #500 // Every 0.5s we check if button 2 is pressed
	MOV R2, #1 // We set the previous state of button 2 to 1 because we take action only on falling edge
	BL waitForButton // Calls the waitForButton subroutine
	CMP R0, #1 // Check if ouptut in R0 is 1
	BEQ start // If R0==1, start the game
	B startCondition // Otherwise we will loop infinitely to check if button 2 is pressed
	

start:
	/* 
	Implement the main logic for the running light here and in the loop below.
	Depending on your implementation, you will probably need to initialise
	- a register to hold the state of the LED bar
	- a register to save the time delay for the LED
	- registers to save the state of the two buttons
	- a register for a counter variable
	- and/or other (temporary) registers as you wish.
	*/
	Mov R4, #0b10000000		// R4: state of the LED bar(0-7)
	Mov R5, #500		// R5: time delay for the LED in ms
	Mov R6, #1		// R6: button 1 state. 1: high, 0: low. We take only action on falling edge.
	Mov R7, #1		// R7: button 2 state. 1: high, 0: low. We take only action on falling edge.
	Mov R8, #7		// R8: counter variable for the Led bar(0-7)
	Mov R9, #0		// If the value in R9==0 left shift otherwise if R9==1 right shift
	Mov R10, #0		// R10: saves the score.




knightRiderLoop:
	/* 
	Implement this loop to make the light move.
	As described in the appendix of the exercise sheet, 
	you can use the shiftOut subroutine to send serial data.
	To do so
	1. Set the latch pin to low
	2. Send the data with shiftOut
	3. Set the latch pin to high
	*/

	// Set latch pin low (read serial data)
	/* to be implemented by student */
	LDR R0, .LATCH_PIN
	LDR R1, .LOW
	BL digitalWrite

	CMP R9, #1 // Check if R9==1
	MOVEQ R4, R4, LSL #1 // If R9==1, left shift for one bit
	MOVNE R4, R4, LSR #1 // If R9==0, right shift for one bit

	
	// Send serial data (shiftOut)
	/* to be implemented by student */
	LDR R0, .DATA_PIN
	LDR R1, .CLOCK_PIN
	LDR R2, .MSBFIRST // We are sending the most significant bit first
	MOV R3, R4 // Copies the LED bar state from R4 to R3
	BL shiftOut // Calls the shiftOut subroutine


	// Set latch pin high (write serial data to parallel output)
	/* to be implemented by student */
	LDR R0, .LATCH_PIN
	LDR R1, .HIGH
	BL digitalWrite
	
	
	// Detect if button1 is pressed 

	LDR R0, .BUTTON1_PIN // Load the button 1 pin to R0
	MOV R1, R5 // Load the delay in R5 to R1
	MOV R2, R6 // Copie the previous state of button 1 to R2
	BL waitForButton // Calls the waitForButton subroutine
	CMP R0, #1 // Check if ouptut in R0 is 1
	BEQ buttonCheck
	CMP R4,  #0b10000000 // Check if the LED 0 is on
	BEQ  alert
	CMP R4, #0b00000001 // Check if the LED 7 is on
	BEQ alert
	B continue // else branch to continue

	buttonCheck:
		CMP R4,  #0b10000000 // check if the button was pressed in the given time window
		BEQ addScore // If button was pressed in the given time window, branch to addScore
		CMP R4, #0b00000001 // check if the button was pressed in the given time window
		BEQ addScore // If button was pressed in the given time window, branch to addScore
		BNE alert // If button was not pressed in the given time window, branch to alert

	alert: 
		LDR R0, .BUZZER_PIN // Load the buzzer pin to R0
		LDR R1, .HIGH // Set the buzzer pin to high
		BL digitalWrite // Calls the digitalWrite subroutine
		B continue // If we alert we do not add score, so we branch to continue
	addScore:
		ADD R10, R10, #1 // If the button was pressed in the given time window, we add 1 to the score
	
	continue:
		Mov R6, R1  // Update the button 1 state after the subroutine call
	
	
		SUBS R8, R8, #1 // Decrease counter variable by 1 and store it in R8 again!
		BNE knightRiderLoop // If counter variable is not 0, branch to knightRiderLoop

		// Change direction of the LED bar if the counter variable is 0
		EOR R9, R9, #1 // If the counter Variable is 0, toggle the value in R9 to shift in other direction.
		Mov R8, #7 // Reset the counter variable to 7
		CMP R5, #100 // Check if the delay is 100ms. If yes the Game is over and we branch to gameOver!
		BEQ gameOver // If the delay is 100ms, branch to gameOver
		SUB R5, R5, #50 // If the delay is not 100ms, decrease the delay by 50ms
		B knightRiderLoop // Start the knightRiderLoop again

	gameOver:
		// Display the score on the LED bar
		LDR R0, LATCH_PIN // Load the latch pin to R0
		LDR R1, LOW // Set the latch pin to low
		BL digitalWrite // Calls the digitalWrite subroutine
		
		// Send serial data (shiftOut)
		LDR R0, DATA_PIN // Load the data pin to R0
		LDR R1, CLOCK_PIN // Load the clock pin to R1
		LDR R2, MSBFIRST // We are sending the most significant bit first
		MOV R3, R10 // Copies the score from R10 to R3
		BL shiftOut // Calls the shiftOut subroutine to display the score in binary on the LED bar

		LDR R0, LATCH_PIN // Load the latch pin to R0
		LDR R1, HIGH // Set the latch pin to high
		BL digitalWrite // Calls the digitalWrite subroutine to set the latch pin to high
		B startCondition // Branch to startCondition after Game is over


	
exit:
	MOV 	R7, #1				// System call 1, exit
	SWI 	0				// Perform system call


/*
-------------------------------------------------------------------------
 SUBROUTINES
-------------------------------------------------------------------------

If you wish, you can define your own subroutines here.
Make sure you save the registers on the stack to avoid conflicts.
Here is an example: 

foo: 
	STMDB SP!, {R3, R4, LR}
	// ... do something here with registers R3 and R4 ...
	LDMIA SP!, {R3, R4, PC} // end of foo subroutine, restore registers and jump


*/ 

waitForButton:
	/* 
	-----------------------------------------------------------------
	 Input arguments:
	 R0:	buttonPin
	 R1: 	timeout (millis)
	 R2: 	previous button state

	 Output:
	 R0:	1 if button pressed (falling edge), 0 otherwise
	 R1:	state of button (High/Low)
	-----------------------------------------------------------------
	*/
	STMDB SP!, {R2-R10, LR}

	MOV	R5, R0 		// R5: buttonPin
	MOV	R6, R1		// R6: timeout 
	MOV	R9, R2		// R9: (previous) button state
	MOV	R10, #0		// R10: button pressed or not

	@ get start time
	BL	millis
	MOV	R7, R0 		// R7: start time
	
	waitingLoopForButton:
	
		// read button pin state
		MOV	R0, R5
		BL	digitalRead
	
		// Check if edge is falling (1 -> 0)
		SUB	R1, R9, R0
		MOV	R9, R0			// previous = current
		CMP	R1, #1
		MOVEQ	R10, #1
	
		// compute elapsed time
		BL	millis
		SUB	R0, R0, R7
		
		// check if elapsed time < time out
		CMP	R0, R6
		BMI	waitingLoopForButton
		B	returnButtonPress

	returnButtonPress:
	LDR R0, .Buzzer // Load the buzzer pin to R0
	LDR R1, .LOW // Set the buzzer pin to low
	BL digitalWrite // Calls the digitalWrite subroutine
	MOV	R0, R10				// return 1 if button pressed within time window
	MOV	R1, R9
	LDMIA SP!, {R2-R10, PC}




// Constants for high- and low signals on the pins
.HIGH:			.word	1
.LOW:			.word	0

// The mode of the pin can be set to input or output.
.OUTPUT:		.word	1
.INPUT:			.word 	0

// For buttons (pull up / pull down)
.PUD_OFF:		.word	0
.PUD_DOWN:		.word	1
.PUD_UP:		.word	2

// For serial to parallel converter (74HC595 chip)
.LSBFIRST:		.word	0		// Least significant bit first
.MSBFIRST:		.word 	1		// Most significant bit first

.DATA_PIN:		.word	17 		// DS Pin of 74HC595 (Pin14)
.LATCH_PIN:		.word	27		// ST_CP Pin of 74HC595 (Pin12)	
.CLOCK_PIN:		.word	22		// CH_CP Pin of 74HC595 (Pin11)

// Button pins
.BUTTON1_PIN:		.word	18
.BUTTON2_PIN:		.word	25

// Buzzer pin
.BUZZER_PIN:		.word	24
