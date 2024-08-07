	.extern main
	.global _start
	.type _start, "function"
	.section ".vectors", "ax"
	.align 3
_start:
	b		reset
	b		hang_undef_instr
	b		vPortYieldProcessor
	b		hang_fetch_abort
	b		hang_data_abort
	b		hang
	b		FreeRTOS_IRQ_Handler
	b		hang_FIQ

hang:
	b		hang
hang_undef_instr:
	b		hang_undef_instr
hang_fetch_abort:
	b		hang_fetch_abort
hang_data_abort:
	b		hang_data_abort
hang_FIQ:
	b		hang_FIQ

    .global reset
    .type reset, "function"
reset:
@    // Change EL2 exception base address
@        LDR r0, =EL2_Vectors
@        MCR p15, 4, r0, c12, c0, 0      // Write to HVBAR

    // Init HSCTLR
        LDR r0, =0x30C5180C             // See TRM for decoding
        MCR p15, 4, r0, c1, c0, 0       // Write to HSCTLR

    // Enable EL1 access to all IMP DEF registers
        LDR r0, =0x7F81
        MCR p15, 4, r0, c1, c0, 1       // Write to HACTLR

    // Change EL1 exception base address
        LDR r0, =EL1_Vectors
        MCR p15, 0, r0, c12, c0, 0      // Write to VBAR

    // Go to SVC mode
        MRS r0, cpsr
        MOV r1, #0x13
        BFI r0, r1, #0, #5
#ifdef __THUMB__
        ORR r0, r0, #(0x1 << 5)         // Set T bit
#endif
        MSR spsr_cxsf, r0
        LDR r0, =EL1_Reset_Handler
        MSR elr_hyp, r0
        DSB
        ISB
        ERET

    .align 5
EL1_Vectors:
	b		EL1_Reset_Handler
	b		hang_undef_instr
	b		vPortYieldProcessor
	b		hang_fetch_abort
	b		hang_data_abort
	b		hang
	b		FreeRTOS_IRQ_Handler
	b		hang_FIQ


    .global EL1_Reset_Handler
    .type EL1_Reset_Handler, "function"
EL1_Reset_Handler:

	# load stack base
	ldr		r0, =.Lstack
	bic		r0, r0, #7
	# set IRQ stack
	msr		cpsr_c, 0xd2
	mov		sp, r0
	sub		r0, r0, #256
	# set application stack
	msr		cpsr_c, 0xd3
	mov		sp, r0
	bl		main

	.global vPortYieldProcessor
	.global vPortIRQHandler
	.global vPortSwitchContext
FreeRTOS_IRQ_Handler:
	/* Return to the interrupted instruction. */
	SUB		lr, lr, #4

	/* Push the return address and SPSR. */
	PUSH	{lr}
	MRS		lr, SPSR
	PUSH	{lr}

	/* Change to supervisor mode to allow reentry. */
	CPS		#19

	/* Push used registers. */
	PUSH	{r0-r4, r12}

	/* Call the interrupt handler. */
	PUSH	{r0-r3, lr}
	LDR		r1, =vPortIRQHandler
	BLX		r1
	mov		r4, r0
	POP		{r0-r3, lr}

	/* Did the interrupt request a context switch?  r1 holds the address of
	ulPortYieldRequired and r0 the value of ulPortYieldRequired for future
	use. */
	mov		r4, #1
	CMP		r4, #0
	BNE		switch_before_exit

exit_without_switch:
	/* No context switch.  Restore used registers, LR_irq and SPSR before
	returning. */
	POP		{r0-r4, r12}
	CPS		#18
	POP		{LR}
	MSR		SPSR_cxsf, LR
	POP		{LR}
	MOVS	PC, LR

switch_before_exit:
	/* Restore used registers, LR-irq and SPSR before saving the context
	to the task stack. */
	POP		{r0-r4, r12}
	CPS		#18
	POP		{LR}
	MSR		SPSR_cxsf, LR
	POP		{LR}
	b		vPortSwitchContext


.bss
.balign 16
.space 4096
.Lstack:
