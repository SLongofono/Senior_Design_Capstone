Exceptions in general:
	Need a CSR that is readable by the user mode that indicates the current mode, page table pointer, and TLB
	Only the supervisor (OS) can write these, by special instructions

	Provide a system call which the user can invoke to elevate to supervisor mode(ecall).  This instruction
	should save the PC in the SEPC CSR, and after handling whatever it needs to do, uses the SRET instruction
	to jump back to the address in SEPC and set mode to user again.

	While handling an exception, we should always 

VMM Exceptions

	TLB misses occur when we have no mapping in the TLB for the given address

	Page faults occur when we expect a page to be in memory, but it is not in fact there.

	In either case we need to invoke an exception, and restart the instruction.  This signalling needs to be
	asynchronous, because the core needs to identify that the exception occurs before doing anything else.
	In our case, this is handled by checking for interrupts/exceptions at the start of each clock cycle,
	before doing anything else.

	We also need to save the minimum amount of state to perform the instruction again, that is, the control
	bits and the instruction itself.
