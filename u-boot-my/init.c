
/****************************************************************/
/* Macro Definition						*/
/****************************************************************/
/*******************************************
 * NAND Flash Register
 ******************************************/
#define nfconf		(*((volatile unsigned long *)0x4e000000))
#define nfcont		(*((volatile unsigned long *)0x4e000004))
#define nfcmmd		(*((volatile unsigned char *)0x4e000008))
#define nfaddr		(*((volatile unsigned char *)0x4e00000c))
#define nfdata		(*((volatile unsigned char *)0x4e000010))
#define nfstat		(*((volatile unsigned char *)0x4e000020))

/*******************************************
 * HCKL=100MHz -> 10ns
 * 15ns (NAND Flash's tcls)
 *
 * HCLK*TACLS >= (tcls-twp = 0ns) 
 * TACLS = 0
 *
 * NFCONF[13:12]
 ******************************************/
#define TACLS		0

/*******************************************
 * HCLK*(TWRPH0+1) >= 15ns (NAND Flash's twp)
 * TWRPH0 = 0.5
 *
 * NFCONF[10:8]
 ******************************************/
#define TWRPH0		1

/*******************************************
 * HCLK*(TWRPH1+1) >= 5ns (NAND Flash's tclh)
 * TWRPH1 = 0
 *
 * NFCONF[6:4]
 ******************************************/
#define TWRPH1		0

/*******************************************
 * ECC		NFCONT[4]
 * 
 * nCE_DIS	NFCONT[1]
 *
 * ENABLE	NFCONT[0]
 ******************************************/
#define ECC		1
#define nCE_DIS		1
#define ENABLE		1


/*******************************************
 * GPIO Register -> UART
 ******************************************/
#define gphcon		(*((volatile unsigned long *)0x56000070))
#define gphup		(*((volatile unsigned long *)0x56000078))

/*******************************************
 * UART Register 
 ******************************************/
#define ulcon0		(*((volatile unsigned long *)0x50000000))
#define ucon0		(*((volatile unsigned long *)0x50000004))
#define ufcon0		(*((volatile unsigned long *)0x50000008))
#define umcon0		(*((volatile unsigned long *)0x5000000c))
#define ubrdiv0		(*((volatile unsigned long *)0x50000028))
#define utrstat0	(*((volatile unsigned long *)0x50000010))
#define utxh0		(*((volatile unsigned char *)0x50000020))
#define urxh0		(*((volatile unsigned char *)0x50000024))

/*******************************************
 * uart baudrate: 
 *
 * PCLK=50MHz
 *
 * UBRDIVn = ((UART_CLK / (UART_BAUDRATE * 16)) -1)
 ******************************************/
#define UART_CLK	50000000
#define UART_BAUDRATE	115200
#define UART_BRD	((UART_CLK / (UART_BAUDRATE * 16)) -1)

#define ready_rxd0	1
#define ready_txd0	(1<<2)

/*******************************************
 * Macro Funtion
 ******************************************/
#define address_bit8(x)		((x) & 0xff)	/* bit[7:0] */


/****************************************************************/
/* Function Definition						*/
/****************************************************************/ 

/*************************************
 * Author     : Matthew
 *
 * Description: init the NAND Flash
 *
 * Parameter  : 
 *
 * Return     : 
 ************************************/
void init_nand(void)
{
	/* */
	nfconf = (TACLS<<12) | (TWRPH0<<8) | (TWRPH1<<4);
	/* Enable NAND Flash Controller
	 * init ECC
	 * disable chip
	 */
	nfcont = (ECC<<4) | (nCE_DIS<<1) | (ENABLE<<0);
}

/*************************************
 * Author     : Matthew
 *
 * Description: enable/disable NAND Flash chip
 *
 * Parameter  : chip :
 *			1 = enable
 *			0 = disable
 *
 * Return     : 
 ************************************/
void set_chip_nand(unsigned char chip)
{
	if (chip) {
		nfcont &= ~(1<<1);	/* select chip */
	} else {
		nfcont |= (1<<1);
	}
}

/*************************************
 * Author     : Matthew
 *
 * Description: sleep for some time
 *
 * Parameter  : time counts
 *
 * Return     : 
 ************************************/
void sleep(unsigned int interval)
{
	while (interval--);
}

/*************************************
 * Author     : Matthew
 *
 * Description: send command to NAND Flash
 *
 * Parameter  : cmd: NAND Flash's command 
 *
 * Return     : 
 ************************************/
void send_cmd_nand(unsigned char cmd)
{
	nfcmmd = cmd;
	sleep(10);
}

/*************************************
 * Author     : Matthew
 *
 * Description: send address to NAND Flash
 *
 * Parameter  : addr: NAND Flash's legal address
 *
 * Return     : 
 ************************************/
void send_addr_nand(unsigned int addr)
{
	unsigned int column_addr = addr / 2048;
	unsigned int row_addr = addr % 2048;
	
	nfaddr = address_bit8(column_addr);
	sleep(10);
	nfaddr = address_bit8(column_addr>>8);
	sleep(10);
	nfaddr = address_bit8(row_addr);
	sleep(10);
	nfaddr = address_bit8(row_addr>>8);
	sleep(10);
	nfaddr = address_bit8(row_addr>>16);
	sleep(10);
}

/*************************************
 * Author     : Matthew
 *
 * Description: wait for NADN Flash to be operated
 *
 * Parameter  : 
 *
 * Return     : 
 ************************************/
void wait_ready_nand(void)
{
	/*
	 * NFSTAT
	 * RnB [0]
	 *	0 = busy
	 *	1 = ready to operate
	 */
	while (!(nfstat & 0x1));
}

/*************************************
 * Author     : Matthew
 *
 * Description: read data from NADN Flash
 *
 * Parameter  : 
 *
 * Return     : a char
 ************************************/
unsigned char read_data_nand(void)
{
	return nfdata;
}

/*************************************
 * Author     : Matthew
 *
 * Description: copy data to dest from NAND Flash
 *
 * Parameter  : addr : NAND Flash address
 *		dest : buffer to receive
 *		len  : data size
 *
 * Return     : 
 ************************************/
void read_from_nand(unsigned int addr, 
				unsigned char *dest, 
				unsigned int len)
{
	unsigned int column_addr = addr % 2048;
	unsigned int index = 0;
	
	set_chip_nand(1);
	while (index < len) {
		send_cmd_nand(0x00);
		send_addr_nand(addr);
		send_cmd_nand(0x30);
		wait_ready_nand();
		
		for (; (column_addr < 2048) && (index < len); column_addr++) {
			dest[index] = read_data_nand();
			++index;
			++addr;
		}
		column_addr = 0;	/* Important */
	}
	set_chip_nand(0);
}

/*************************************
 * Author     : Matthew
 *
 * Description: jude whether boot from NOR Flash
 *
 * Parameter  : void
 *
 * Return     : 1 = from NOR Flash
 *		0 = from NADN Flash
 *
 * NOR Flash 不能简单地写操作
 ************************************/
int is_boot_from_norflash(void)
{
	volatile int *p = (volatile int *)0;

	*p = 0x12345678;
	return ((*p == 0x12345678)? 0 : 1);
}

/*************************************
 * Author     : Matthew
 *
 * Description: copy to SDRAM from Flash(NOR or NAND)
 *
 * Parameter  : src  : Flash address
 *		dest : SDRAM address
 *		len  : data size
 *
 * Return     : 
 ************************************/
void copy_codes_to_sdram(unsigned char *src, 
			unsigned char *dest, 
			unsigned int len)
{
	unsigned int i = 0;

	/* from NOR FLASH */
	if (is_boot_from_norflash()) {
		while (i++ < len) {
			*dest++ = *src++;
		}
	} else {
		read_from_nand((unsigned int)src, dest, len);
	}
}

/*************************************
 * Author     : Matthew
 *
 * Description: clear the bss section
 *
 * Parameter  : 
 *
 * Return     : 
 ************************************/
void clean_bss(void)
{
	extern int __bss_start, __bss_end;	/* from the u-boot.lds */
	int *p_start = &__bss_start;
	
	for (; p_start < &__bss_end; p_start++)	{
		*p_start = 0;
	}
}

/*************************************
 * Author     : Matthew
 *
 * Description: init the serial port 0
 *
 * Parameter  : 
 *
 * Return     : 
 ************************************/
void init_uart0(void)
{
	gphcon |= 0xa0;		/* GPH2, GPH3 -> TXD0, RXD0	*/
	gphup   =  0x0c;	/* GPH2, GPH3 pull-up		*/

	ulcon0  = 0x03;		/* 8N1: 8bits, no parity, 1stopbit */
	ucon0   = 0x05;		/* polling mode，->PCLK		*/
	ufcon0  = 0x00;		/* disable FIFO mode		*/
	umcon0  = 0x00;		/* disable flow control		*/
	ubrdiv0 = UART_BRD;	/* baudrate: 115200		*/
}

/*************************************
 * Author     : Matthew
 *
 * Description: send a char data to serial port
 *
 * Parameter  : a char data
 *
 * Return     : 
 ************************************/
void putc_uart(unsigned char c)
{
	/* transmitter empty */
	while (!(utrstat0 & ready_txd0));
	/* write data */
	utxh0 = c;
}

/*************************************
 * Author     : Matthew
 *
 * Description: send a string data to serial port
 *
 * Parameter  : a string data
 *
 * Return     : 
 ************************************/
void puts_uart(char *str)
{
	while (*str != '\0') {
		putc_uart(*str);
		str++;
	}
}

