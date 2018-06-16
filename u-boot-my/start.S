
.text
.global _start
_start:

/* close Watchdog */
	ldr	r0, =0x53000000		/* WTCON	*/
	mov	r1, #0
	str	r1, [r0]

/* init clock */
	ldr	r0, =0x4c000014		/* CLKDIVN					*/
	/* mov	r1, #0x03 */		/* 200MHz 					*/
					/* FCLK:HCLK:PCLK = 1:2:4, HDIVN=01, PDIVN=1	*/
	/* improvement 1 */
	mov	r1, #0x05		/* 400MHz					*/
					/* FCLK:HCLK:PCLK = 1:4:8, HDIVN=10, PDIVN=1	*/
	str	r1, [r0]

	/* FCKL != HCLK	*/
	/* if HDIVN is not 0, set asynchoronous bus mode */
	mrc	p15, 0, r1, c1, c0, 0	/* read control register	*/
	orr	r1, r1, #0xc0000000	/* set asynchoronous bus mode	*/
	mcr	p15, 0, r1, c1, c0, 0	/* write control register	*/

	ldr	r0, =0x4c000004		/* MPLLCON				*/
	/* ldr	r1, =0x5c012 */		/* 200MHz : (0x5c<<12)|(0x01<<4)|0x02)	*/
					/* FCLK=200MHz, HCLK=100MHz, PCLK=50MHz	*/
	/* improvement 1 */
	ldr	r1, =0x5c011		/* 400MHz : (0x5c<<12)|(0x01<<4)|0x01)	*/
					/* FCLK=400MHz, HCLK=100MHz, PCLK=50MHz	*/
	str	r1, [r0]

	/* improvement 2 */
	/* setup ICACHE -> command */
	mrc	p15, 0, r0, c1, c0, 0	/* read controller register		*/
	orr	r0, r0, #(1<<12)
	mcr	p15, 0, r0, c1, c0, 0	/* write back				*/

/* init SDRAM */
	ldr	r0, =0x48000000		/* SDRAM CONTROL REGISTER BASE ADDRESS	*/
	adr	r1, sdram_config	/* get sdram_config current address	*/
	add	r3, r0, #52		/* 13 control register *4		*/
1:
	ldr	r2, [r1], #4
	str	r2, [r0], #4
	cmp	r0, r3
	bne	1b

/* copy u-boot codes from flash to sdram (link address) */
	ldr	sp, =0x34000000		/* stack address 	*/
	bl	init_nand

	mov	r0, #0			/* src address		*/
	ldr	r1, =_start		/* dest link address	*/
	ldr	r2, =__bss_start	/* .bss link address	*/
	sub	r2, r2, r1		/* .text size		*/
	bl	copy_codes_to_sdram
	
	bl	clean_bss

/* exec main */
	ldr	lr, =loop		/* return address : if main has return */
	ldr	pc, =start_boot
loop:
	b loop


sdram_config:
	.long	0x22011110		/* BWSCON	*/
	.long	0x00000700		/* BANKCON0	*/
	.long	0x00000700		/* BANKCON1	*/
	.long	0x00000700		/* BANKCON2	*/
	.long	0x00000700		/* BANKCON3	*/
	.long	0x00000700		/* BANKCON4	*/
	.long	0x00000700		/* BANKCON5	*/
	.long	0x00018005		/* BANKCON6	*/
	.long	0x00018005		/* BANKCON7	*/
	.long	0x008c04f4		/* REFRESH	*/
	.long	0x000000b1		/* BANKSIZE	*/
	.long	0x00000030		/* MRSRB6	*/
	.long	0x00000030		/* MRSRB7	*/

