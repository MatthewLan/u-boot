/*
 * (C) Copyright 2006 OpenMoko, Inc.
 * Author: Harald Welte <laforge@openmoko.org>
 *
 * SPDX-License-Identifier:	GPL-2.0+
 */

#include <common.h>

#include <nand.h>
#include <asm/arch/s3c24x0_cpu.h>
#include <asm/io.h>

#ifdef  CONFIG_NAND_S3C2410			/* -----  CONFIG_NAND_S3C2410  ----- */
#define S3C2410_NFCONF_EN          (1<<15)
#define S3C2410_NFCONF_512BYTE     (1<<14)
#define S3C2410_NFCONF_4STEP       (1<<13)
#define S3C2410_NFCONF_INITECC     (1<<12)
#define S3C2410_NFCONF_nFCE        (1<<11)
#define S3C2410_NFCONF_TACLS(x)    ((x)<<8)
#define S3C2410_NFCONF_TWRPH0(x)   ((x)<<4)
#define S3C2410_NFCONF_TWRPH1(x)   ((x)<<0)

#define S3C2410_ADDR_NALE 4
#define S3C2410_ADDR_NCLE 8
#endif								/* -----  CONFIG_NAND_S3C2410  ----- */

#ifdef  CONFIG_NAND_S3C2440			/* -----  CONFIG_NAND_S3C2440  ----- */
#define S3C2410_NFCONF_EN          (1<<15)
#define S3C2410_NFCONF_512BYTE     (1<<14)
#define S3C2410_NFCONF_4STEP       (1<<13)
#define S3C2410_NFCONF_INITECC     (1<<12)

#define S3C2440_NFCONF_TACLS(x)		((x)<<12)
#define S3C2440_NFCONF_TWRPH0(x)	((x)<<8)
#define S3C2440_NFCONF_TWRPH1(x)	((x)<<4)

#define S3C2440_NFCONT_INITECC		(1<<4)
#define S3C2440_NFCONT_nFCE			(1<<1)
#define S3C2440_NFCONT_EN			(1<<0)

/* struct s3c24x0_nand 结构体中，nfcmd 成员的相对位置 */
#define S3C2440_ADDR_CLE			8
/* struct s3c24x0_nand 结构体中，nfaddr 成员的相对位置 */
#define S3C2440_ADDR_ALE			12
#endif								/* -----  CONFIG_NAND_S3C2440  ----- */

#ifdef CONFIG_NAND_SPL

/* in the early stage of NAND flash booting, printf() is not available */
#define printf(fmt, args...)

static void nand_read_buf(struct mtd_info *mtd, u_char *buf, int len)
{
	int i;
	struct nand_chip *this = mtd_to_nand(mtd);

	for (i = 0; i < len; i++)
		buf[i] = readb(this->IO_ADDR_R);
}
#endif

/*
 * ===  FUNCTION  ======================================================================
 *         Name:  s3c24x0_hwcontrol
 *  Description:  NAND-Flash control
 * Paraamenters:  ctrl : select/deselect chip; send command or address;
 *                cmd  : command or address value
 * =====================================================================================
 */
static void s3c24x0_hwcontrol(struct mtd_info *mtd, int cmd, unsigned int ctrl)
{
	struct nand_chip *chip = mtd_to_nand(mtd);
	struct s3c24x0_nand *nand = s3c24x0_get_base_nand();

	debug("hwcontrol(): 0x%02x 0x%02x\n", cmd, ctrl);

#ifdef  CONFIG_NAND_S3C2410			/* -----  CONFIG_NAND_S3C2410  ----- */
	if (ctrl & NAND_CTRL_CHANGE) {
		ulong IO_ADDR_W = (ulong)nand;

		if (!(ctrl & NAND_CLE))
			IO_ADDR_W |= S3C2410_ADDR_NCLE;
		if (!(ctrl & NAND_ALE))
			IO_ADDR_W |= S3C2410_ADDR_NALE;

		chip->IO_ADDR_W = (void *)IO_ADDR_W;

		if (ctrl & NAND_NCE)
			writel(readl(&nand->nfconf) & ~S3C2410_NFCONF_nFCE,
			       &nand->nfconf);
		else
			writel(readl(&nand->nfconf) | S3C2410_NFCONF_nFCE,
			       &nand->nfconf);
	}

	if (cmd != NAND_CMD_NONE)
		writeb(cmd, chip->IO_ADDR_W);
#endif								/* -----  CONFIG_NAND_S3C2410  ----- */

#ifdef  CONFIG_NAND_S3C2440			/* -----  CONFIG_NAND_S3C2440  ----- */
	if (ctrl & NAND_CTRL_CHANGE) {
		ulong IO_ADDR_W = (ulong)nand;

		/*
		 * NAND_CLE : 表示发送命令
		 * IO_ADDR_W = nand_base_addr + nfcmd的相对位置
		 *
		 * S3C2440_ADDR_CLE 即：struct s3c24x0_nand 结构体中，nfcmd 成员的相对位置
		 */
		if (ctrl & NAND_CLE)
			IO_ADDR_W |= S3C2440_ADDR_CLE;
		/*
		 * NAND_ALE : 表示发送地址
		 * IO_ADDR_W = nand_base_addr + nfaddr的相对位置
		 *
		 * S3C2440_ADDR_ALE 即：struct s3c24x0_nand 结构体中，nfaddr 成员的相对位置
		 */
		if (ctrl & NAND_ALE)
			IO_ADDR_W |= S3C2440_ADDR_ALE;

		chip->IO_ADDR_W = (void *)IO_ADDR_W;

		/*
		 * s3c2440
		 * NFCONT : 0x4e000004
		 *
		 * Reg_nCE : [1]
		 * 0: enable chip select
		 * 1: disable chip select
		 */
		if (ctrl & NAND_NCE)		/* 使能选中 */
			writel(readl(&nand->nfcont) & ~S3C2440_NFCONT_nFCE, &nand->nfcont);
		else						/* 取消选中 */
			writel(readl(&nand->nfcont) | S3C2440_NFCONT_nFCE, &nand->nfcont);
	}

	/* 发送命令(nand->nfcmd)或地址(nand->nfaddr) */
	if (cmd != NAND_CMD_NONE)
		writeb(cmd, chip->IO_ADDR_W);
	/* reset IO_ADDR_W */
	else
		chip->IO_ADDR_W = (void*)&nand->nfdata;
#endif								/* -----  CONFIG_NAND_S3C2440  ----- */
}

static int s3c24x0_dev_ready(struct mtd_info *mtd)
{
	struct s3c24x0_nand *nand = s3c24x0_get_base_nand();
	debug("dev_ready\n");
	return readl(&nand->nfstat) & 0x01;
}

#ifdef CONFIG_S3C2410_NAND_HWECC
void s3c24x0_nand_enable_hwecc(struct mtd_info *mtd, int mode)
{
	struct s3c24x0_nand *nand = s3c24x0_get_base_nand();
	debug("s3c24x0_nand_enable_hwecc(%p, %d)\n", mtd, mode);
	writel(readl(&nand->nfconf) | S3C2410_NFCONF_INITECC, &nand->nfconf);
}

static int s3c24x0_nand_calculate_ecc(struct mtd_info *mtd, const u_char *dat,
				      u_char *ecc_code)
{
	struct s3c24x0_nand *nand = s3c24x0_get_base_nand();
	ecc_code[0] = readb(&nand->nfecc);
	ecc_code[1] = readb(&nand->nfecc + 1);
	ecc_code[2] = readb(&nand->nfecc + 2);
	debug("s3c24x0_nand_calculate_hwecc(%p,): 0x%02x 0x%02x 0x%02x\n",
	      mtd , ecc_code[0], ecc_code[1], ecc_code[2]);

	return 0;
}

static int s3c24x0_nand_correct_data(struct mtd_info *mtd, u_char *dat,
				     u_char *read_ecc, u_char *calc_ecc)
{
	if (read_ecc[0] == calc_ecc[0] &&
	    read_ecc[1] == calc_ecc[1] &&
	    read_ecc[2] == calc_ecc[2])
		return 0;

	printf("s3c24x0_nand_correct_data: not implemented\n");
	return -EBADMSG;
}
#endif

#ifdef  CONFIG_NAND_S3C2440			/* -----  CONFIG_NAND_S3C2440  ----- */
/*
 * ===  FUNCTION  ======================================================================
 *         Name:  s3c2440_nand_select
 *  Description:  select/deselect chip
 *
 * set this function pointer to nand->select_chip.
 * =====================================================================================
 */
static void s3c2440_nand_select(struct mtd_info *mtd, int chipnr)
{
	struct s3c24x0_nand *nand = s3c24x0_get_base_nand();

	switch (chipnr) {
	/* deselect chip */
	case -1: {
		writel(readl(&nand->nfcont) | S3C2440_NFCONT_nFCE, &nand->nfcont);
		break;
	}
	/* select chip */
	case 0: {
		writel(readl(&nand->nfcont) & ~S3C2440_NFCONT_nFCE, &nand->nfcont);
		break;
	}
	default:
		BUG();
	}
}
#endif								/* -----  CONFIG_NAND_S3C2440  ----- */

int board_nand_init(struct nand_chip *nand)
{
	u_int32_t cfg;
	u_int8_t tacls, twrph0, twrph1;
	struct s3c24x0_clock_power *clk_power = s3c24x0_get_base_clock_power();
	/*
	 * function   : s3c24x0_get_base_nand
	 * description: get NAND-Flash base address
	 * position   : arch/arm/include/asm/arch/s3c2440.h
	 */
	struct s3c24x0_nand *nand_reg = s3c24x0_get_base_nand();

	debug("board_nand_init()\n");

	/*
	 * s3c2440
	 * CLKCON : 0x4c00000c
	 *
	 * NAND Flash Controller : [4]
	 * 0 - disable
	 * 1 - enable
	 */
	writel(readl(&clk_power->clkcon) | (1 << 4), &clk_power->clkcon);

	/* initialize hardware */
#if defined(CONFIG_S3C24XX_CUSTOM_NAND_TIMING)
	tacls  = CONFIG_S3C24XX_TACLS;
	twrph0 = CONFIG_S3C24XX_TWRPH0;
	twrph1 =  CONFIG_S3C24XX_TWRPH1;
#else

#ifdef  CONFIG_NAND_S3C2410			/* -----  CONFIG_NAND_S3C2410  ----- */
	tacls  = 4;
	twrph0 = 8;
	twrph1 = 8;
#endif								/* -----  CONFIG_NAND_S3C2410  ----- */

#ifdef  CONFIG_NAND_S3C2440			/* -----  CONFIG_NAND_S3C2440  ----- */
	tacls  = 0;
	twrph0 = 1;
	twrph1 = 0;
#endif								/* -----  CONFIG_NAND_S3C2440  ----- */

#endif

#ifdef  CONFIG_NAND_S3C2410			/* -----  CONFIG_NAND_S3C2410  ----- */
	cfg = S3C2410_NFCONF_EN;
	cfg |= S3C2410_NFCONF_TACLS(tacls - 1);
	cfg |= S3C2410_NFCONF_TWRPH0(twrph0 - 1);
	cfg |= S3C2410_NFCONF_TWRPH1(twrph1 - 1);
	writel(cfg, &nand_reg->nfconf);
#endif								/* -----  CONFIG_NAND_S3C2410  ----- */

#ifdef  CONFIG_NAND_S3C2440			/* -----  CONFIG_NAND_S3C2440  ----- */
	cfg  = S3C2440_NFCONF_TACLS(tacls);
	cfg |= S3C2440_NFCONF_TWRPH0(twrph0);
	cfg |= S3C2440_NFCONF_TWRPH1(twrph1);
	writel(cfg, &nand_reg->nfconf);

	cfg = S3C2440_NFCONT_INITECC | S3C2440_NFCONT_nFCE | S3C2440_NFCONT_EN;
	writel(cfg, &nand_reg->nfcont);
#endif								/* -----  CONFIG_NAND_S3C2440  ----- */

	/* initialize nand_chip data structure */
	nand->IO_ADDR_R = (void *)&nand_reg->nfdata;
	nand->IO_ADDR_W = (void *)&nand_reg->nfdata;

#ifdef  CONFIG_NAND_S3C2440			/* -----  CONFIG_NAND_S3C2440  ----- */
	nand->select_chip = s3c2440_nand_select;
#else
	nand->select_chip = NULL;
#endif								/* -----  CONFIG_NAND_S3C2440  ----- */

	/* read_buf and write_buf are default */
	/* read_byte and write_byte are default */
#ifdef CONFIG_NAND_SPL
	nand->read_buf = nand_read_buf;
#endif

	/* hwcontrol always must be implemented */
	nand->cmd_ctrl = s3c24x0_hwcontrol;

	nand->dev_ready = s3c24x0_dev_ready;

#ifdef CONFIG_S3C2410_NAND_HWECC
/* #if (define CONFIG_S3C2410_NAND_HWECC) || (define CONFIG_S3C2440_NAND_HWECC) */
	nand->ecc.hwctl = s3c24x0_nand_enable_hwecc;
	nand->ecc.calculate = s3c24x0_nand_calculate_ecc;
	nand->ecc.correct = s3c24x0_nand_correct_data;
	nand->ecc.mode = NAND_ECC_HW;
	nand->ecc.size = CONFIG_SYS_NAND_ECCSIZE;
	nand->ecc.bytes = CONFIG_SYS_NAND_ECCBYTES;
	nand->ecc.strength = 1;
#else
	nand->ecc.mode = NAND_ECC_SOFT;
#endif

#ifdef CONFIG_S3C2410_NAND_BBT
	nand->bbt_options |= NAND_BBT_USE_FLASH;
#endif

	debug("end of nand_init\n");

	return 0;
}
