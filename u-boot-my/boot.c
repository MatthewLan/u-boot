/****************************************************************/
/* Header File							*/
/****************************************************************/
#include "setup.h"

/****************************************************************/
/* Reference							*/
/****************************************************************/
extern void read_from_nand(unsigned int addr, unsigned char *dest, unsigned int len);
extern void init_uart0(void);
extern void puts_uart(char *str);


/****************************************************************/
/* Macro Definition						*/
/****************************************************************/
#define kernel_addr		(0x60000 + 64)		/* uImage: kernel_header + kernel */
#define kernel_link_addr	(0x30008000)		/* kernel lds setting 		  */
#define kernel_size		(0x200000)		/* 2MB 				  */

#define params_base_addr	(0x30000100)		/* kernel setting 		  */

/* SDRAM */
#define mem_base_addr		(0x30000000)
#define mem_size		(0x4000000)

#define S3C2440_ARCH_ID		(362)


/****************************************************************/
/* Variable Definition						*/
/****************************************************************/
static struct tag *params;
char params_str[] = "noinitrd root=/dev/mtdblock3 init=/linuxrc console=ttySAC0";


/****************************************************************/
/* Function Definition						*/
/****************************************************************/
/*************************************
 * Author     : Matthew
 *
 * Description: get the length of string
 *
 * Parameter  : a string data
 *
 * Return     : the length
 ************************************/
int mystrlen(char *str)
{
	int i = 0;
	while (*str++ != '\0') {
		++i;
	}
	return i;
}

/*************************************
 * Author     : Matthew
 *
 * Description: copy to dest from src
 *
 * Parameter  : 
 *
 * Return     : 
 ************************************/
void mystrcpy(char *dest, char *src)
{
	while ((*dest++ = *src++) != '\0');
}

/*************************************
 * Author     : Matthew
 *
 * Description: set start_tag param
 *
 * Parameter  : 
 *
 * Return     : 
 ************************************/
void setup_start_tag(void)
{
	params = (struct tag *)params_base_addr;

	params->hdr.tag  = ATAG_CORE;
	params->hdr.size = tag_size(tag_core);		/* 4Byte unit */

	params->u.core.flags    = 0;
	params->u.core.pagesize = 0;
	params->u.core.rootdev  = 0;
	
	params = tag_next(params);
}

/*************************************
 * Author     : Matthew
 *
 * Description: set memory param
 *
 * Parameter  : 
 *
 * Return     : 
 ************************************/
void setup_memory_tags(void)
{
	params->hdr.tag  = ATAG_MEM;
	params->hdr.size = tag_size(tag_mem32);
	
	params->u.mem.start = mem_base_addr;
	params->u.mem.size  = mem_size;
	
	params = tag_next(params);
}

/*************************************
 * Author     : Matthew
 *
 * Description: set commandline param
 *
 * Parameter  : cmdline : boot params
 *
 * Return     : 
 ************************************/
void setup_cmdline_tag(char *cmdline)
{
	puts_uart("[setup_cmdline_tag] ");
	puts_uart(cmdline);
	puts_uart("\n\r");

	int cmdline_size     = mystrlen(cmdline) + 1;
	int tag_cmdline_size = sizeof(struct tag_header) + cmdline_size + 3;

	params->hdr.tag  = ATAG_CMDLINE;
	params->hdr.size = tag_cmdline_size>>2;
	
	mystrcpy(params->u.cmdline.cmdline, cmdline);
	
	params = tag_next(params);
}

/*************************************
 * Author     : Matthew
 *
 * Description: set end_tag param
 *
 * Parameter  : 
 *
 * Return     : 
 ************************************/
void setup_end_tag(void)
{
	params->hdr.tag  = ATAG_NONE;
	params->hdr.size = 0;
}

/*************************************
 * Author     : Matthew
 *
 * Description: boot the kernel
 *
 * Parameter  : 
 *
 * Return     : 
 ************************************/
void start_boot(void)
{
	typedef void (*theKernel)(int zero, int arch, unsigned int params);
	theKernel start_kernel = 0;
	
	/* init serial port */
	init_uart0();
	
	/* copy linux kernel from NAND Flash */
	puts_uart("[start_boot] copy kernel from nand\n\r");
	read_from_nand((unsigned int)kernel_addr, 
			(unsigned char)kernel_link_addr, 
			(unsigned int)kernel_size);
	
	/* params setting */
	puts_uart("[start_boot] set boot params\n\r");
	setup_start_tag();
	setup_memory_tags();
	setup_cmdline_tag(params_str);
	setup_end_tag();

	/* start linux kernel */
	puts_uart("[start_boot] start kernel...\n\r");
	start_kernel = (theKernel)kernel_link_addr;
	start_kernel(0, S3C2440_ARCH_ID, params_base_addr);
	
	/* No Error, No run here */
	puts_uart("[start_boot] start kernel ERROR\n\r");
}

