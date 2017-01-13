/*
 * Memory Setup stuff - taken from blob memsetup.S
 *
 * Modified for the Samsung SMDK2440
 *
 */


#include <config.h>

/* some parameters for the board */

/*
 *
 * Taken from linux/arch/arm/boot/compressed/head-s3c2440.S
 *
 */

/********************************************
 * S3C2440
 *
 * FCLK, HCLK, PCLK
 *
 * FCLK: ARM920T
 * HCLK: AHB Bus (ARM920T, Memory Controller, Interrupt Controller, LCD Controller, DMA and USB Host Block)
 * PCLK: APB Bus (WDT<WatchDog>, I2S, I2C, PWM Timer, MMC Interface, ADC, UART, GPIO, RTC, SPI)-peripherals
 *
 * HDIVN	PDIVN	HCLK3_HALF/HCLK4_HALF	FCLK	HCLK	PCLK	Divide Ratio
 *	0		0				-				FCLK	FCLK	FCLK		1:1:1 (Default)
 *	0		1				-				FCLK	FCLK	FCLK/2		1:1:2
 *	1		0				-				FCLK	FCLK/2	FCLK/2		1:2:2
 *	1		1				-				FCLK	FCLK/2	FCLK/4		1:2:4
 *	3		0				0/0				FCLK	FCLK/3	FCLK/3		1:3:3
 *	3		1				0/0				FCLK	FCLK/3	FCLK/6		1:3:6
 *	3		0				1/0				FCLK	FCLK/6	FCLK/6		1:6:6
 *	3		1				1/0				FCLK	FCLK/6	FCLK/12		1:6:12
 *	2		0				0/0				FCLK	FCLK/4	FCLK/4		1:4:4
 *	2		1				0/0				FCLK	FCLK/4	FCLK/8		1:4:8
 *	2		0				0/1				FCLK	FCLK/8	FCLK/8		1:8:8
 *	2		1				0/1				FCLK	FCLK/8	FCLK/16		1:8:16
 *
 *
 * Register   : LOCKTIME
 * Description: Lock time count Register
 * Address    : 0x4c00,0000
 *    U_LTIME [31:16]		UPLL lock time count value for UCLK
 *    M_LTIME [15:0]			MPLL lock time count value for FCLK,HCLK,PCLK
 *
 *
 * Register   : MPLLCON			UPLLCON
 * Description: PLL control Register
 * Address    : 0x4c00,0004		0x4c00,0008
 *    MDIV [19:12]		Main divider control
 *    PDIV [9:4]		Pre-divider control
 *    SDIV [1:0]		Post divider control
 *
 * MPLL(FCLK) = (2 *m *Fin)/(p *2^s)
 * UPLL = (m *Fin)/(p *2^s)
 *    m = MDIV + 8
 *    p = PDIV + 2
 *    s = SDIV
 *
 *
 * Register   : CLKCON
 * Description: Clock control Register
 * Address    : 0x4c00,000c
 *    AC97 [20]			Control PCLK into AC97 block
 *      0 = disable
 *      1 = enable
 *    Camera [19]		PCLK -> Camera
 *    SPI    [18]		PCLK -> SPI
 *    IIS    [17]		PCLK -> IIS
 *    IIC    [16]     	PCLK -> IIC
 *    ADC    [15]		PCLK -> ADC		&Touch Screen
 *    RTC    [14]		PCLK -> RTC
 *    GPIO   [13]       PCLK -> GPIO
 *    UART2  [12]		PCLK -> UART2
 *    UART1  [11]		PCLK -> UART1
 *    UART0  [10]		PCLK -> UART0
 *    SDI    [9]		PCLK -> SDI
 *    PWMTIMER   [8]	PCLK -> PWMTIMER
 *    USB_Device [7]	PCLK -> USB Device
 *
 *    USB_Host   [6]	HCLK -> USB Host
 *    LCDC       [5]	HCLK -> LCDC
 *    NAND_Flash [4]	HCLK -> NAND Flsh Controller
 *
 *    SLEEP      [3]	Control SLEEP mode of S3C2440A
 *    IDLE_BIT   [2]	Enter IDLE mode. This bit is not cleared automatically.
 *    Reserved   [1:0]
 *
 *
 * Register   : CLKSLOW
 * Description: Clock slow control Register
 * Address    : 0x4c00,0010
 *    UCLK_ON [7]
 *      0 = UCLK ON (UPLL is also turned on and the UPLL lock time is inserted automatically.)
 *      1 = UCLK OFF (UPLL is also turned off.)
 *
 *    Reserved [6]
 *
 *    MPLL_OFF [5]
 *      0 = turn on PLL  (After PLL stabilization time (minimum 300us), SLOW_BIT can be cleared to 0.)
 *      1 = turn off PLL (PLL is turned off only when SLOW_BIT is 1.)
 *
 *    SLOW_BIT [4]
 *      0: FCLK = MPLL
 *      1: SLOW mode
 *        FCLK = input_clock/(2*SLOW_VAL), when SLOW_VAL>0
 *        FCLK = input_clock, when SLOW_VAL=0
 *
 *    Reserved [3]
 *    SLOW_VAL [2:0]	The divider value for the slow clock when SLOW_BIT is on.
 *
 *
 * Register   : CLKDIVN
 * Description: Clock divider control Register
 * Address    : 0x4c00,0014
 *    DIVN_UPLL [3]			UCLK select register (UCLK must be 48MHZ for USB)
 *      0: UCLK = UPLL_clock
 *      1: UCLK = UPLL_clock/2
 *
 *    HDIVN     [2:1]
 *      00: HCLK = FCLK
 *      01: HCLK = FCLK/2
 *      10: HCLK = FCLK/4 (CAMDIVN[9]=0)
 *          HCLK = FCLK/8 (CAMDIVN[9]=1)
 *      11: HCLK = FCLK/3 (CAMDIVN[8]=0)
 *          HCLK = FCLK/6 (CAMDIVN[8]=1)
 *
 *    PDVIN     [0]
 *      0: PCLK = HCLK
 *      1: PCLK = HCLK/2
 *
 *
 * Register   : CAMDIVN
 * Description: Camera clock divider Register
 * Address    : 0x4c00,0018
 *    DVS_EN [12]
 *      0 = DVS OFF (ARM core will run normally with FCLK (MPLLout))
 *      1 = DVS ON  (ARM core will run at the same clock as system clock (HCLK))
 *
 *    Reserved [11]
 *    Reserved [10]
 *
 *    HCLK_HALF [9]		HDVIN division rate change bit, when CLKDIVN[2:1]=10b
 *      0: HCLK = FCLK/4
 *      1: HCLK = FCLK/8
 *
 *    HCLK_HALF [8]		HDVIN division rate change bit, when CLKDIVN[2:1]=11b
 *      0: HCLK = FCLK/3
 *      1: HCLK = FCLK/6
 *
 *    CAMCLK_SEL [4]
 *      0 = use CAMCLK with UPLL output (CAMCLK=UPLL_out)
 *      1 = CAMCLK is divded by CAMCLK_DIV value
 *
 *    CAMCLK_DIV [3:0]
 *      CAMCLK divide factor setting register (0~15)
 *      Camera_clock = UPLL/((CAMCLK +1) *2)
 *
 *
 * If HDIVN is not 0 (HCLK != FCLK), the CPU bus mode has to be changed
 * from the fast bus mode to the asynchronous bus mode.
 * Using following instruction (S3C2440 does not support synchronous bus mode).
 *   MMU_SetAsyncBusMode
 *     mrc p15, 0, r0, c1, c0, 0
 *     orr r0, r0, #R1_nF:OR:R1_iA
 *     mcr p15, 0, r0, c1, c0, 0
 *
 *
 * 1. S3C2440 CPU核的工作电压为1.2V时，主频可达到200MHZ；
 *					工作电压为1.3V时，主频可达到400MHZ；
 * 2. JZ2440V3的晶振为12MHZ，需要通过始终控制逻辑的PLL提高系统；
 * 3. S3C2440有两个PLL：MPLL 和 UPLL；
 *				UPLL -> USB设备
 *				MPLL -> 设置FCLK,HCLK,PLCK
 * 4. 上电时，PLL没被启动时，FCKL即等于外部输入的时钟，称Fin；
 *    若要提高系统时钟，需要软件来启用PLL；
 * 5. 程序开头启动 MPLL，设置MPLL后，需等待一段时间(Lock Time)，MPLL的输出才稳定；
 *******************************************/

/********************************************
 * S3C2440
 *
 * 8_BANK Address Space
 *
 * BANK0 - nGCS0
 * 0x0000,0000 ~ 0x0800,0000-1 (128M)
 *
 * BANK1 - nGCS1
 * 0x0800,0000 ~ 0x1000,0000-1
 *
 * BANK2 - nGCS2
 * 0x1000,0000 ~ 0x1800,0000-1
 *
 * BANK3 - nGCS3
 * 0x1800,0000 ~ 0x2000,0000-1
 *
 * BANK4 - nGCS4
 * 0x2000,0000 ~ 0x2800,0000-1
 *
 * BANK5 - nGCS5
 * 0x2800,0000 ~ 0x3000,0000-1
 *
 * BANK6 - nGCS6
 * 0x3000,0000 ~ 0x3800,0000-1
 *
 * BANK7 - nGCS7
 * 0x3800,0000 ~ 0x4000,0000-1
 *
 *
 * BANK0~BANK5 -> SRAM
 * BANK6~BANK7 -> SRAM,SDRAM
 *
 * BANK6 and BANK7 must have the same memory size.
 * BANK0 data bus width: 16-bit or 32 bit
 *
 *******************************************/

/********************************************
 * S3C2440
 *
 * SRAM
 * size: 4KB
 *
 * NOR Flash mode
 * address: 0x4000,0000 ~
 *
 * NAND Flash mode
 * address: 0x0000,0000 ~
 *
 *******************************************/

/********************************************
 * S3C2440
 *
 * Register Space
 *
 * address: 0x4800,0000 ~ 0x5FFF,FFFF
 *
 *******************************************/

/********************************************
 * S3C2440
 *
 * BANK_SIZE <-> BANK_ADDRESS
 *
 * 64M <-> A[25:24]
 * BA0 - LADDR24
 * BA1 - LADDR25
 *
 *******************************************/

/********************************************
 * BWSCON <- S3C2440
 *
 * Description: Bus width & Wait control Register
 *
 * Address: 0x4800,0000
 *
 * ST7 [31]					Determines SRAM for using UB/LB for bank7 (数据掩码引脚的使能)
 *   0 = not using UB/LB	-> SDRAM
 *   1 = using UB/LB		-> SRAM
 *
 * WS7 [30]					Determines Wait status for bank7
 *   0 = Wait disable
 *   1 = Wait enable
 *
 * DW7 [29:28]				Determines data bus width for bank7
 *   00 = 8-bit
 *   01 = 16-bit
 *   10 = 32-bit
 *
 * ST6,WS6,DW6 : [27],[26],[25:24]
 * ST5,WS5,DW5 : [23],[22],[21:20]
 * ST4,WS4,DW4 : [19],[18],[17:16]
 * ST3,WS3,DW3 : [15],[14],[13:12]
 * ST2,WS2,DW2 : [11],[10],[9:8]
 * ST1,WS1,DW1 : [7],[6],[5:4]
 *
 * DW0 [2:1]
 *    01 = 16-bit
 *    10 = 32-bit
 *
 * Reserved [0]
 *
 *******************************************/

/********************************************
 * BANKCONn <- S3C2440
 *
 * Description: Bank control Register
 *
 *************************
 * BANKCON0: 0x4800,0004
 * BANKCON1: 0x4800,0008
 * BANKCON2: 0x4800,000c
 * BANKCON3: 0x4800,0010
 * BANKCON4: 0x4800,0014
 * BANKCON5: 0x4800,0018
 * < SRAM >
 *
 * tacs [14:13]		address set-up time before nGCSn
 *    00 = 0 clock
 *    01 = 1 clock
 *    10 = 2 clocks
 *    11 = 4 clocks
 *
 * tcos [12:11]		chip selection set-up time before nOE
 *    00 = 0 clock
 *    01 = 1 clock
 *    10 = 2 clocks
 *    11 = 4 clocks
 *
 * tacc [10:8]		access cycle
 *    000 = 1 clock
 *    001 = 2 clocks
 *    010 = 3 clocks
 *    011 = 4 clocks
 *    100 = 6 clocks
 *    101 = 8 clocks
 *    110 = 10 clocks
 *    111 = 14 clocks
 *
 * tcoh [7:6]		chip selection hold time after nOE
 *    00 = 0 clock
 *    01 = 1 clock
 *    10 = 2 clocks
 *    11 = 4 clocks
 *
 * tcah [5:4]		address hold time after nGCSn
 *    00 = 0 clock
 *    01 = 1 clock
 *    10 = 2 clocks
 *    11 = 4 clocks
 *
 * tacp [3:2]		page mode access cycle @ Page mode
 *    00 = 2 clocks
 *    01 = 3 clocks
 *    10 = 4 clocks
 *    11 = 6 clocks
 * PMC  [1:0]		Page mode configuration
 *    00 = normal(1 data)
 *    01 = 4 data
 *    10 = 8 data
 *    11 = 16 data
 *
 *************************
 * BANKCON6: 0x4800,001c
 * BANKCON7: 0x4800,0020
 * < SRAM or SDRAM >
 *
 * MT  [16:15]		determine the memory type for bank6 and bank7
 *    00 = ROM or SRAM
 *    01 = Reserved
 *    10 = Reserved
 *    11 = Sync. DRAM (SDRAM)
 *
 * @1 -> MT=00 -> SRAM
 *  All the options is same to bank0 ~ bank5
 *
 * @2 -> MT=11 -> SDRAM
 * trcd [3:2]		RAS to CAS delay
 *    00 = 2 clocks
 *    01 = 3 clocks (recommended)
 *    10 = 4 clocks
 *
 * SCAN [1:0]
 *    00 = 8-bit
 *    01 = 9-bit
 *    10 = 10-bit
 *  The other options is same to bank0 ~ bank5
 *
 *******************************************/

/********************************************
 * REFRESH <- S3C2440
 *
 * Description: Refresh control Register
 *
 * Address: 0x4800,0024
 *
 * REFEN [23]		SDRAM Refresh enable
 *    0 = disable
 *    1 = enable (Self or CBR/Auto refresh)
 *
 * TREFMD [22]		SDRAM Refresh mode
 *    0 = CBR/Auto refresh
 *    1 = Self refresh (一般在系统休眠时使用)
 *
 * trp  [21:20]		SDRAM RAS pre-charge time
 *    00 = 2 clocks
 *    01 = 3 clocks
 *    10 = 4 clocks
 *    11 = not support
 *
 * tsrc [19:18]		SDRAM semi row cycle time
 *    00 = 4 clocks
 *    01 = 5 clocks
 *    10 = 6 clocks
 *    11 = 7 clocks
 *
 ** SDRAM row cycle time: trc = tsrc+trp
 *
 * Reserved [17:16]
 * Reserved [15:11]
 *
 *
 *************
 * Description: SDRAM refresh count value.
 *              Refer to chapter 6 SDRAM refresh controller bus priority section.
 *
 * refresh_count [10:0]
 *
 * refresh_period = (2^11 - refresh_count + 1)/HCLK
 *
 * Example:
 * 	If refresh period is 7.8us and HCLK is 100MHZ, the refresh count is as follows:
 *  refresh_count = 2^11 + 1 + 100*7.8 = 1269
 *
 *******************************************/

/********************************************
 * BANKSIZE <- S3C2440
 *
 * Description: BANKSIZE Register
 *
 * Address: 0x4800,0028
 *
 * BURST_EN [7]		ARM core burst operation enable
 *    0 = disable
 *    1 = enable
 *
 * Reserved [6]
 *
 * SCKE_EN  [5]		SDRAM power down mode enable control by SCKE
 *    0 = disable
 *    1 = enable
 *
 * SCLK_EN  [4]		SCLK is enable only during SDRAM access cycle for reducing power consumption.
 *                  When SDRAM is not accessed, SCLK become 'L' level.
 *    0 = always active
 *    1 = active only during the access (recommended)
 *
 * Reserved [3]
 *
 * BK76MAP  [2:0]	BANK6/7 memory map
 *    000 = 32M/32M
 *    001 = 64M/64M
 *    010 = 128M/128M
 *    011 = Reserved
 *    100 = 2M/2M
 *    101 = 4M/4M
 *    110 = 8M/8M
 *    111 = 16M/16M
 *
 *******************************************/

/********************************************
 * BANKSIZE <- S3C2440
 *
 * Description: SDRAM mode register set Register (MRSR)
 *
 * MRSRB6: 0x4800,002c
 * MRSRB7: 0x4800,0030
 *
 * Reserved [11:10]
 *
 * WBL [9]		Write burst length
 *    0 = burst (fixed)
 *    1 = Reserved
 *
 * TM  [8:7]	Test mode
 *    00 = mode register set (fixed)
 *    other = Reserved
 *
 * CL  [6:4]	CAS latency
 *    000 = 1 clock
 *    010 = 2 clocks
 *    011 = 3 clocks
 *    other = Reserved
 *
 * BT  [3]		Burst type
 *    0 = sequential (fixed)
 *    1 = Reserved
 *
 * BL  [2:0]	Burst length
 *    000 = 1 (fixed)
 *    other = Reserved
 *
 *******************************************/

/********************************************
 * JZ2440V3 Board
 *
 * BANK -> External Devices
 *
 * BANK0 - NOR Flash
 *
 * BANK1 - IDE Interfac command_block Register
 * BANK2 - IDE Interfac control_block Register
 *
 * BANK3 - Network card: CS8900A (10M)
 *
 * BANK4 - Network card: DM9000 (100M)
 *
 * BANK5 - Expand SerialPort Chip: 16C2550
 *
 * BANK6 - SDRAM: EM63A165TS-6G
 *
 *******************************************/

/********************************************
 * SDRAM
 * PartNumer: EM63A165TS-6G
 * Frequency: 166MHZ
 *
 * Chip: nGCS6 -> BANK6			-> BANKCON6.MT=11
 *
 * 16bit_width *2 = 32-bit		-> B6_BWSCON: DW32 -> BWSCON.DW7=10
 * Size_per: 4M *8bank = 32M
 * Size_tal: 32M *2 = 64M		-> BANKSIZE.BK76MAP=000
 *
 * row address   : A0~A12
 * column address: A0-A8 		-> B6_SCAN: 9bit -> BANKCON6.SCAN=01
 * auto precharge: A10
 *
 * 8192 refresh cycles/64ms
 * Refresh cycles: 64ms/8192	-> 7.8125us -> REFRESH.refresh_count = 2^11 + 1 + HCLK*7.8125
 *                              -> REFRESH.REFEN=1
 *                              -> REFRESH.TREFMD=0 (CBR/Auto refresh)
 *
 *******************************************/

#define BWSCON	0x48000000	/* S3C2440 Store Controller Address: 0x4800,0000~0x4800,0030 */

/* BWSCON */
#define DW8				(0x0)
#define DW16			(0x1)
#define DW32			(0x2)
#define WAIT			(0x1<<2)
#define UBLB			(0x1<<3)

#define B1_BWSCON		(DW32)
#define B2_BWSCON		(DW16)
#define B3_BWSCON		(DW16 + WAIT + UBLB)
#define B4_BWSCON		(DW16)
#define B5_BWSCON		(DW16)
#define B6_BWSCON		(DW32)
#define B7_BWSCON		(DW32)

/* BANK0CON */
#define B0_Tacs			0x0	/*  0clk */
#define B0_Tcos			0x0	/*  0clk */
#define B0_Tacc			0x7	/* 14clk */
#define B0_Tcoh			0x0	/*  0clk */
#define B0_Tah			0x0	/*  0clk */
#define B0_Tacp			0x0
#define B0_PMC			0x0	/* normal */

/* BANK1CON */
#define B1_Tacs			0x0	/*  0clk */
#define B1_Tcos			0x0	/*  0clk */
#define B1_Tacc			0x7	/* 14clk */
#define B1_Tcoh			0x0	/*  0clk */
#define B1_Tah			0x0	/*  0clk */
#define B1_Tacp			0x0
#define B1_PMC			0x0

#define B2_Tacs			0x0
#define B2_Tcos			0x0
#define B2_Tacc			0x7
#define B2_Tcoh			0x0
#define B2_Tah			0x0
#define B2_Tacp			0x0
#define B2_PMC			0x0

#define B3_Tacs			0x0	/*  0clk */
#define B3_Tcos			0x3	/*  4clk */
#define B3_Tacc			0x7	/* 14clk */
#define B3_Tcoh			0x1	/*  1clk */
#define B3_Tah			0x0	/*  0clk */
#define B3_Tacp			0x3	/*  6clk */
#define B3_PMC			0x0	/* normal */

#define B4_Tacs			0x0	/*  0clk */
#define B4_Tcos			0x0	/*  0clk */
#define B4_Tacc			0x7	/* 14clk */
#define B4_Tcoh			0x0	/*  0clk */
#define B4_Tah			0x0	/*  0clk */
#define B4_Tacp			0x0
#define B4_PMC			0x0	/* normal */

#define B5_Tacs			0x0	/*  0clk */
#define B5_Tcos			0x0	/*  0clk */
#define B5_Tacc			0x7	/* 14clk */
#define B5_Tcoh			0x0	/*  0clk */
#define B5_Tah			0x0	/*  0clk */
#define B5_Tacp			0x0
#define B5_PMC			0x0	/* normal */

#define B6_MT			0x3	/* SDRAM */
#define B6_Trcd			0x1
#define B6_SCAN			0x1	/* 9bit */

#define B7_MT			0x3	/* SDRAM */
#define B7_Trcd			0x1	/* 3clk */
#define B7_SCAN			0x1	/* 9bit */

/* REFRESH parameter */
#define REFEN			0x1	  /* Refresh enable */
#define TREFMD			0x0	  /* CBR(CAS before RAS)/Auto refresh */
#define Trp				0x0   /* 2clk */
#define Trc				0x3	  /* 7clk */  /* -> tsrc */
#define Tchr			0x2	  /* 3clk */  /* -> [16] Reserved */
#define REFCNT			0x4f4 /* period=7.8125us, HCLK=100Mhz, (2048+1-7.8125us*100)=1267.75 */

/**************************************/

.globl lowlevel_init
lowlevel_init:
	/* memory control configuration */
	/* make r0 relative the current location so that it */
	/* reads SMRDATA out of FLASH rather than memory ! */
	ldr     r0, =SMRDATA			/* SMRDATA Link Address */
	ldr	r1, =CONFIG_SYS_TEXT_BASE	/* text_start_addr: 0x0; define in /include/configs/jz2440v3.h */
	sub	r0, r0, r1					/* r0: SMRDATA_start_addr in NOR Flash */
	ldr	r1, =BWSCON					/* Bus Width Status Controller */
	add     r2, r0, #13*4			/* r2: SMRDATA_end_addr in NOR Flash */
0:
	ldr     r3, [r0], #4
	str     r3, [r1], #4			/* r1: BWSCON addr */
	cmp     r2, r0					/* write over or not */
	bne     0b

	/* everything is fine now */
	mov	pc, lr

	.ltorg
/* the literal pools origin */

SMRDATA:
    .word (0+(B1_BWSCON<<4)+(B2_BWSCON<<8)+(B3_BWSCON<<12)+(B4_BWSCON<<16)+(B5_BWSCON<<20)+(B6_BWSCON<<24)+(B7_BWSCON<<28))
    .word ((B0_Tacs<<13)+(B0_Tcos<<11)+(B0_Tacc<<8)+(B0_Tcoh<<6)+(B0_Tah<<4)+(B0_Tacp<<2)+(B0_PMC))
    .word ((B1_Tacs<<13)+(B1_Tcos<<11)+(B1_Tacc<<8)+(B1_Tcoh<<6)+(B1_Tah<<4)+(B1_Tacp<<2)+(B1_PMC))
    .word ((B2_Tacs<<13)+(B2_Tcos<<11)+(B2_Tacc<<8)+(B2_Tcoh<<6)+(B2_Tah<<4)+(B2_Tacp<<2)+(B2_PMC))
    .word ((B3_Tacs<<13)+(B3_Tcos<<11)+(B3_Tacc<<8)+(B3_Tcoh<<6)+(B3_Tah<<4)+(B3_Tacp<<2)+(B3_PMC))
    .word ((B4_Tacs<<13)+(B4_Tcos<<11)+(B4_Tacc<<8)+(B4_Tcoh<<6)+(B4_Tah<<4)+(B4_Tacp<<2)+(B4_PMC))
    .word ((B5_Tacs<<13)+(B5_Tcos<<11)+(B5_Tacc<<8)+(B5_Tcoh<<6)+(B5_Tah<<4)+(B5_Tacp<<2)+(B5_PMC))
    .word ((B6_MT<<15)+(B6_Trcd<<2)+(B6_SCAN))
    .word ((B7_MT<<15)+(B7_Trcd<<2)+(B7_SCAN))
    .word ((REFEN<<23)+(TREFMD<<22)+(Trp<<20)+(Trc<<18)+(Tchr<<16)+REFCNT)
    .word 0x32
    .word 0x30
    .word 0x30
