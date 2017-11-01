Notes on interrupt process

When an interrupt is encountered, the processor needs to follow this
procedure:

Given the pending interrupts CSR mpi:

	// determine enabled interrupts
	let mie be the MIE bit of the mstatus register
	
	/* machine mode interrupts are enabled if the current privilege is less
	 * than machine mode, or if we are in machine mode and the mie bit is
	 * high.  Why do it this way?
	 */
	
	let enabled interrupts be the input pending interrupts mpi, masked by
	the inverse of those interrupts that are delegated to supervisor mode,
	masked with the negative of the machine mode enabled boolean.
	
	/* The last part is
	 * a bitwise trick that just sets the whole vector to itself if m_enabled
	 * is true or all zeros otherwise.
	 */

	/* supervisor mode interrupts follow the same pattern, they are
	 * always enabled if invoked from user mode, and otherwise enabled if in
	 * supervisor mode and the SIE bit is high.  The interrupts to be
	 * handled by supervisor mode are only evaluated if the enabled bits
	 * above are all zero, indicating that some interrupts have been
	 * delegated to supervisor mode.
         */

	if(enabled interrupts = 0):
		// update what will be handled, using the same bit trick
		 with the supervisor interrupt enable bit (SIE)
		enabled interrupts = mpi & delegated interrupts mask & -SIE

	// Trigger the trap handler only if the cause is zero, and there are
	// enabled interrupts

	if(cause == 0 && enabled interrupts){
		handle_trap( 1 << (instruction bitlength-1) | count(enabled interrupts)); 
	}

	/* count finds the number of contiguous zero bits, starting at the
	 * LSB.  So 00000000000000000000000010000000 would see 7 returned.
	 * Why is this done?
	 *
end procedure
