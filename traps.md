Notes on trap handling

// First-pass pseudocode
handle_trap(trap):
	//Check the IE bit IN THE MSTATUS CSR
	
	find this trap's privilege level
	go to the corresponding entry MIE/HIE/SIE/UIE
	if the bit is high, proceed,
	else, fail (What does fail mean in this context?)

	// Store the cause
	Get the trap exception code from the input trap


	// Store old privilege level

	// Store old IE bit

	// Store old PC

	// Set PC to trap handler code address
