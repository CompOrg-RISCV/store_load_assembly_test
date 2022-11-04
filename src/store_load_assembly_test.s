/*
 * store_load_assembly_test.s
 *
 *  Created on: April 1st, 2022
 *      Author: kgraham
 */

 // Section .crt0 is always placed from address 0
	.section .crt0, "ax"

/********************************
 * Basic store instruction tests
 ********************************/

_start:
	.global _start

	addi x2, x0, 0x87			// Create test value of 0x87654321 corresponding to their byte number
	slli x2, x2, 8
	addi x2, x2, 0x65
	slli x2, x2, 8
	addi x2, x2, 0x43
	slli x2, x2, 8
	addi x2, x2, 0x21			// x2 will have the value 0x87654321 when completed
	nop
	nop
	nop
	nop
	nop							// create base address for store operations in x3
	addi x3, x0, 0x20
	slli x3, x3, 8				// base address will be x3 = 0x2000
	nop
	nop
	nop
	nop
	nop
	sw	x2, 0(x3)				// word store of x2, 0x87654321, into memory address 0x2000
	sb	x2, 7(x3)				// store byte value 0x21 to 0x2007
	srli x4, x2, 8				// 0x43 shifted to the byte location to be stored
	sb  x4, 6(x3)				// store byte value 0x43 to 0x2006 //also test out data hazard/forwarding from EX stage
	nop					// memory location at 0x2000 will now equal 0x87654321
	srli x4, x4, 8		// 0x65 shifted to the byte location to be stored //address 0x2004 = 0x21000000
	nop
	sb  x4, 5(x3)		// store byte value 0x65 to 0x2005 //also test out data hazard/forwarding from MEM stage (address 0x2004 = 0x2143
	srli x4, x4, 8				// 0x87 shifted to the byte location to be stored
	sb  x4, 4(x3)				// store byte value 0x87 to 0x2004
	nop
	nop					// memory location at 0x2004 now 0x21436500
	nop
	sh  x2, 10(x3)		// store 0x4321 to location 0x2010 // memory location at 0x2004 now 0x21436587
	srli x10, x2, 16				// shift 0x8765 to half-word store location, lower 16-bits
	sh  x10, 8(x3)				// store 0x8765 to location 0x2008
	nop
	nop					// momory location at 0x2008 now 0x4321000
	nop
	nop					// memory location at 0x2008 now 0x43218765
	nop
	beq x0, x0, TEST	// Branch to validate that the branch cancels the write to 0x200c
	sw x2, 12(x3)
	nop
	nop
TEST:
	nop
	nop
	nop
	nop
	nop					// if memory location changes from 0 to 0x87654321. ERROR.
	nop					// The branch should have canceled the store operation that occure immediate after a branch taken
	nop
	halt

/***************************************************************
 * Basic load instruction test to validate lw, lb, lh, and lbu
 ***************************************************************/
	nop
	nop
	nop
	nop
	lw x4, 0(x3)			// load the value from memory which was written from x2.  x3 will equal x2
	lb x5, 7(x3)			// reassemble x2 from the bytes write at 0x2004. x4 will equal x2
	nop
	nop
	lb x10, 6(x3)
	nop					// check that x4 == x2  (confirms word loads)
	slli x10, x10, 8
	or x5, x5, x10
	lb x10, 5(x3)
	nop
	slli x10, x10, 16
	or x5, x5, x10
	lb x10, 4(x3)
	lh x6, 10(x3)
	slli x10, x10, 24
	or x5, x5, x10
	nop
	lh x10, 8(x3)
	nop
	slli x10, x10, 16
	or x6, x6, x10		// check that x5 == x2 (confirms byte loads)
	nop
	addi x10, x0, 0xff		// store byte of 0xff or -1
	nop
	sb x10, 12(x3)
	nop					// check that x6 == x2 (confirms half-word loads)
	lb x7, 12(x3)
	lbu x8, 12(x3)
	nop
	nop
	nop
	nop					// lb sign extends a byte load. does x7 = 0xffffffff?
	nop					// lbu does not sign extend byte load.  does x8 = 0xff?
	nop
	nop
	nop
	halt
/**************************************************************************
 * Load test to validate whether memory stall implemented successfully
 **************************************************************************/
	nop
	nop
	sw x2, 16(x3)
	lw x7, 16(x3)
	nop
	nop
	nop
	nop
	nop					// if memory stalled successfully, x7 == x2, else x7 is ?
	nop
	nop
	halt
/**************************************************************************
 * Extra-credit Load test to validate structural hazard detected and stall
 **************************************************************************/
 	addi x9, x0, 0			// initializing test register x9 to 0
 	nop
	nop
	nop
	nop
	nop
	lw x8, 16(x3)			// loading value of 0x87654321 int x8 registers
	addi x9, x8, 0			// Moving value from x8 which should be read from memory as x87654321
	addi x10, x9, 0
	nop
	nop					// x8 should now equal x87654321
	nop
	nop					// x9 == x8 if load structural hazard detected and IF, ID stall with IDEX clear (NOP bubble)
	nop					// x10 = x9
	jal x1, JUMP			// generate case of control hazard, clear pipeline regs IDEX & EXMEM and change address in IF stage w/simulataneous load structural hazard
JUMP:
	lw x11, 16(x3)			// setting x11 to 0x87654321
	sw x11, 20(x3)			// checking for structural hazard for store after load
	lw x12, 20(x3)
	nop
	nop
	nop					// x11 = 0x87654321
	nop
	nop					// x12 = x11
	nop
	nop
	nop
	halt
	nop
	nop
	nop
/**************************************************************************
 * End of store_load_assembly_test
 **************************************************************************/
	nop
	nop
	nop