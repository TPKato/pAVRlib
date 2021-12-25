#ifndef __CCS811_H__
#define __CCS811_H__

/* CCS811 registers (bytes direction) */
#define STATUS			0x00 /* 1 Read */
#define MEAS_MODE		0x01 /* 1 Read / Write */
#define ALG_RESULT_DATA		0x02 /* 8 Read */
#define RAW_DATA		0x03 /* 2 Read */
#define ENV_DATA		0x05 /* 4 Write */
#define THRESHOLDS		0x10 /* 5 Write */
#define BASELINE		0x11 /* 2 Read / Write */
#define HW_ID			0x20 /* 1 Read */
#define HW_VERSION		0x21 /* 1 Read */
#define FW_Boot_Version		0x23 /* 2 Read */
#define FW_App_Version		0x24 /* 2 Read */
#define ERROR_ID		0xe0 /* 1 Read */
#define APP_ERASE		0xf1 /* 4 Write */
#define APP_DATA		0xf2 /* 9 Write	*/
#define APP_VERIFY		0xf3 /* 0 Write	*/
#define APP_START		0xf4 /* 0 Write	*/
#define SW_RESET		0xff /* 4 Write	*/

/* STATUS (0x00) */
#define sFW_MODE		7
#define sAPP_ERASE		6
#define sAPP_VERIFY		5
#define sAPP_VALID		4
#define sDATA_READY		3
#define sERROR			0

/* MEAS_MODE (0x01) */
#define DRIVE_MODE_0		(0<<4)
#define DRIVE_MODE_1		(1<<4)
#define DRIVE_MODE_2		(2<<4)
#define DRIVE_MODE_3		(3<<4)
#define DRIVE_MODE_4		(4<<4)
#define INT_DATARDY		(1<<3)
#define INT_THRESH		(1<<2)
/* aliases of DRIVE_MODE */
#define DRIVE_MODE_IDLE		(0<<4)
#define DRIVE_MODE_1s		(1<<4)
#define DRIVE_MODE_10s		(2<<4)
#define DRIVE_MODE_60s		(3<<4)
#define DRIVE_MODE_250ms	(4<<4)

/* ERROR_ID (0xe0) */
#define MSG_INVALID		(1<<5)
#define READ_REG_INVALID	(1<<4)
#define MEASMODE_INVALID	(1<<3)
#define MAX_RESISTANCE		(1<<2)
#define HEATER_FAULT		(1<<1)
#define HEATER_SUPPLY		(1<<0)

#ifndef __ASSEMBLER__
void CCS811_RESET();
char CCS811_SEARCH();
char CCS811_INITIALIZE(char CCS811_address);
unsigned int CCS811_WRITE(char CCS811_address, char CCS811_register, char bytes, char *data);
unsigned int CCS811_READ(char CCS811_address, char CCS811_register, char bytes, char *data);
#endif

#endif
