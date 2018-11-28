#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "xparameters.h"
#include "xil_printf.h"
#include "xil_cache.h"
#include "ff.h"
#include "xdevcfg.h"
#include "xil_io.h"
#include "xil_types.h"

#include "xbasic_types.h"
#include "xil_exception.h"
#include "xsdps.h"
#include "math.h"
#include "string.h"
/////////////////////////////////////////


#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

///////////////////////////////////////
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

/* default: SipHash-2-4 */
#define cROUNDS 2
#define dROUNDS 4
//////////////////////////////////////
#define ROTL(x, b) (uint64_t)(((x) << (b)) | ((x) >> (64 - (b))))


uint64_t siphash(uint64_t m,uint64_t k0,uint64_t k1,  const size_t outlen) {

    assert((outlen == 8) || (outlen == 16));
    uint64_t v0 = 0x736f6d6570736575ULL;
    uint64_t v1 = 0x646f72616e646f6dULL;
    uint64_t v2 = 0x6c7967656e657261ULL;
    uint64_t v3 = 0x7465646279746573ULL;
   uint64_t out;

    int i;

    v3 ^= k1;
    v2 ^= k0;
    v1 ^= k1;
    v0 ^= k0;

    v3 ^= m;


    for (i = 0; i < cROUNDS; ++i)
    {        v0 += v1;
    v1 = ROTL(v1, 13);
    v1 ^= v0;
    v0 = ROTL(v0, 32);
    v2 += v3;
    v3 = ROTL(v3, 16);
    v3 ^= v2;
    v0 += v3;
    v3 = ROTL(v3, 21);
    v3 ^= v0;
    v2 += v1;
    v1 = ROTL(v1, 17);
    v1 ^= v2;
    v2 = ROTL(v2, 32);
    }

    v0 ^= m;


    v2 ^= 0xff;


    for (i = 0; i < dROUNDS; ++i)
    { v0 += v1;
    v1 = ROTL(v1, 13);
    v1 ^= v0;
    v0 = ROTL(v0, 32);
    v2 += v3;
    v3 = ROTL(v3, 16);
    v3 ^= v2;
    v0 += v3;
    v3 = ROTL(v3, 21);
    v3 ^= v0;
    v2 += v1;
    v1 = ROTL(v1, 17);
    v1 ^= v2;
    v2 = ROTL(v2, 32);
    }


    m = v0 ^ v1 ^ v2 ^ v3;
    out=m;
return out;

}

//////////////////////////////////////
const int  image_size =  512;
static FIL file1;		// File instance
FRESULT result;			// FRESULT variable
u8 Buffer[521*512*10] __attribute__ ((aligned(32))); // Buffer should be word aligned (multiple of 4)
u32 Buffer_size = (512*512*8);
u32 image[512*512];
u32 image_H[512][512];
u32 image_V[512*512];
u32 image_VH[512][512];
u32 sum[512][512];
static char *image_File; // pointer to the image

// Parameters for Partial Reconfiguration
#define PARTIAL_SOBEL_ADDR   			0x4000000
#define PARTIAL_GAUSSIAN_ADDR   		0x8000000

#define PARTIAL_SOBEL_BITFILE_LEN       0x13D170 // in number of words
#define PARTIAL_GAUSSIAN_BITFILE_LEN    0x13D170 // in number of words

// SLCR registers
#define SLCR_LOCK				0xF8000004 // SLCR Write Protection Lock
#define SLCR_UNLOCK				0xF8000008 // SLCR Write Protection Unlock
#define SLCR_LVL_SHFTR_EN 		0xF8000900 // SLCR Level Shifters Enable
#define SLCR_PCAP_CLK_CTRL XPAR_PS7_SLCR_0_S_AXI_BASEADDR + 0x168 // SLCR PCAP clock control register address

#define SLCR_PCAP_CLK_CTRL_EN_MASK 	0x1
#define SLCR_LOCK_VAL				0x767B
#define SLCR_UNLOCK_VAL				0xDF0D

#define NUMOFCHARS 8


// Turn on/off Debug messages
#ifdef DEBUG_PRINT
#define  debug_printf  xil_printf
#else
#define  debug_printf(msg, args...) do {  } while (0)
#endif

// Read function for STDIN
extern char inbyte(void);

static int Reset = 1;
static FATFS fatfs;

// Driver Instantiations
static XDcfg_Config *XDcfg_0;
XDcfg DcfgInstance;
XDcfg *DcfgInstPtr;

int itoa(int n, char s[], int NumOfChars);// Parameter Definitions


int SD_Init()
{
	FRESULT rc;

	rc = f_mount(&fatfs, "", 0);
	if (rc) {
		xil_printf(" ERROR : f_mount returned %d\r\n", rc);
		return XST_FAILURE;
	}
	return XST_SUCCESS;
}

int SD_TransferPartial(char *FileName, u32 DestinationAddress, u32 ByteLength)
{
	FIL fil;
	FRESULT rc;
	UINT br;

	rc = f_open(&fil, FileName, FA_READ);
	if (rc) {
		xil_printf(" ERROR : f_open returned %d\r\n", rc);
		return XST_FAILURE;
	}

	rc = f_lseek(&fil, 0);
	if (rc) {
		xil_printf(" ERROR : f_lseek returned %d\r\n", rc);
		return XST_FAILURE;
	}

	rc = f_read(&fil, (void*) DestinationAddress, ByteLength, &br);
	if (rc) {
		xil_printf(" ERROR : f_read returned %d\r\n", rc);
		return XST_FAILURE;
	}

	rc = f_close(&fil);
	if (rc) {
		xil_printf(" ERROR : f_close returned %d\r\n", rc);
		return XST_FAILURE;
	}
	return XST_SUCCESS;
}

int get_imagefilesobel(char *FileName)
{
	int NumOfCharsToWrite = 0;
    Xuint32 *filter_addr = (Xuint32 *) XPAR_IP_LFSR_S00_AXI_BASEADDR;
	u32 i = 0;
	u32 j = 0;
	u32 k = 0;
	//unsigned int sum = 0;
	unsigned int  n=0;
	UINT BytesRW; // Bytes written

	// Creating new file with read/write permissions
	image_File = (char *)FileName;
	result = f_open(&file1, image_File, FA_OPEN_EXISTING | FA_READ);
   	if (result!= 0) {
   		return XST_FAILURE;
   	}
   	//seek start of file
   	f_lseek(&file1,0);
   	//read text file all data
	result = f_read(&file1,(void*)Buffer, Buffer_size, &BytesRW);
	//string to byte convert
	char  c;
	char  ptr[NUMOFCHARS];
	j=0; k=0;
	xil_printf("read bytes: %8d \n\r", BytesRW);
	for (i=0; i<BytesRW-1;++i)
		{
		c = Buffer[i];
		if ((Buffer[i] == 13)  && (Buffer[i+1] == 10))
		{
			for (n=j;n<6;n++)
				ptr[n] = 0;
				j=0;
				image[k] = atoll(ptr);
				k++;
		}
		else
		{
			if ((Buffer[i] != 10 ) || (Buffer[i] != 13))
			{
				ptr[j] = c;
				j++;
			}
		}
		}
	xil_printf("read bytes: %8d \n\r", k);
    result = f_close(&file1);
    image_File = (char *)FileName;
   	result = f_open(&file1, image_File, FA_CREATE_ALWAYS | FA_WRITE);
    if (result!= 0)
	{
       	xil_printf("error \n\r");
       	return XST_FAILURE;
    }
	//seek start of file
	f_lseek(&file1,0);
    xil_printf("processing start\n\r");
	// sobel filter and sd card file read/write
	for (i=1; i<=image_size-3; i++){
		for (j=1; j<=image_size-3; j++) {
			k=i*image_size + j;
			*(filter_addr+8) = image[k-(image_size+1)]; //p0
			*(filter_addr+9) = image[k-1];	 			//p1
			*(filter_addr+10) = image[k+(image_size-1)]; //p2
			*(filter_addr+11) = image[k-image_size]; 	//p3
			*(filter_addr+12) = image[k+image_size]; 	//p5
			*(filter_addr+13) = image[k-(image_size-1)]; //p6
			*(filter_addr+14) = image[k+1];	 			//p7
			*(filter_addr+15) = image[k+(image_size+1)]; //p8
			sum[i][j] = *(filter_addr+16);
			if ( sum[i][j] > 200) sum[i][j] = 255;
			else sum[i][j] = 0;
			}
		}
	// Initialize edges:
	for (i=0; i<1; i++) {
		for (j=1; j<=image_size-3; j++) {
		    k=i*image_size + j;
			sum[i][j] = 0;
		}
	}
	for (i=image_size-2; i<=image_size-1; i++) {
		for (j=1; j<=image_size-3; j++) {
			k=i*image_size + j;
			sum[i][j] = 0;
		}
	}
	for (j=0; j<1; j++) {
		for (i=1; i<=image_size-3; i++) {
		    k=i*image_size + j;
			sum[i][j] = 0;
		}
	}
	for (j=image_size-2; j<=image_size-1; j++) {
		for (i=1; i<=image_size-3; i++) {
			k=i*image_size + j;
			sum[i][j] = 0;
		}
	}

	// processing end
	for (i=0; i<=image_size-1; i++){
		for (j=0; j<=image_size-1; j++) {
			NumOfCharsToWrite = itoa(sum[i][j], ptr, NUMOFCHARS);
			// write sobel filter result to text file
			f_write(&file1,(const void*)ptr, NumOfCharsToWrite,&BytesRW);
		}
	}
	f_close(&file1);
	xil_printf("End Sobel Filter\n\r");
    return 0;
}

int get_imagefilegaussian(char *FileName)
{
	xil_printf("Start gaussian filter processing");

    Xuint32 *filter_addr = (Xuint32 *) XPAR_IP_LFSR_S00_AXI_BASEADDR;
	int NumOfCharsToWrite = 0;

	u32 i = 0;
	u32 j = 0;
	u32 k = 0;
	unsigned int  n=0;
	UINT BytesRW; // Bytes written

     // Creating new file with read/write permissions
  	image_File = (char *)FileName;
   	result = f_open(&file1, image_File, FA_OPEN_EXISTING | FA_READ);
   	if (result!= 0)
	{
   		return XST_FAILURE;
   	}
   	//seek start of file
   	f_lseek(&file1,0);
   	//read text file all data
	result = f_read(&file1,(void*)Buffer, Buffer_size, &BytesRW);
	//string to byte convert
	char  c;
	char  ptr[NUMOFCHARS];
	j=0; k=0;
	xil_printf("read bytes: %8d \n\r", BytesRW);
	for (i=0; i<BytesRW-1;++i)
	{
		c = Buffer[i];
		if ((Buffer[i] == 13)  && (Buffer[i+1] == 10))
		{
			for (n=j;n<6;n++)
				ptr[n] = 0;
				j=0;
				image[k] = atoll(ptr);
				k++;
		}
		else
		{
			if ((Buffer[i] != 10 ) || (Buffer[i] != 13))
			{
				ptr[j] = c;
				j++;
			}
		}
	}
	xil_printf("read bytes: %8d \n\r", k);
    result = f_close(&file1);
    image_File = (char *)FileName;
    result = f_open(&file1, image_File, FA_CREATE_ALWAYS | FA_WRITE);
    if (result!= 0)
	{
       	xil_printf("error \n\r");
       	return XST_FAILURE;
    }
	//seek start of file
	f_lseek(&file1,0);
    xil_printf("processing start\n\r");
	// Gaussian filter and sd card file read/write
	//Horizontal filter
	for (i=4;i<=image_size-8;i++){       // Skip first 2 and last 2 rows.
		for (j=4; j<=image_size-8;j++) { // Skip first and last column.
			k=i*image_size + j;          // Central value
			*(filter_addr+8) = image[k-3]; 	//p0
			*(filter_addr+9) = image[k-2]; 	//p1
			*(filter_addr+10) = image[k-1]; 	//p2
			*(filter_addr+11) = image[k];   	//p3 : center value
			*(filter_addr+12) = image[k+1]; 	//p5
			*(filter_addr+13) = image[k+2]; 	//p6
			*(filter_addr+14) = image[k+3]; 	//p7
			*(filter_addr+15) = 0; 			//p8
			image_H[i][j] = *(filter_addr+16);
		}
	}
	// Initialize edges:
	for (i=0; i<=3; i++) {
		for (j=4; j<=image_size-8;j++) {
			image_H[i][j] = 0;
		}
	}
	for (i=image_size-7; i<=image_size-1; i++) {
		for (j=4; j<=image_size-8;j++) {
			image_H[i][j] = 0;
		}
	}
	for (j=0; j<=3; j++) {
		for (i=4; i<=image_size-8;i++) {
			image_H[i][j] = 0;
		}
	}
	for (j=image_size-7; j<=image_size-1; j++) {
		for (i=4; i<=image_size-8;i++) {
			image_H[i][j] = 0;
		}
	}

	for (i=0; i<=image_size-1;i++){
		for (j=0;j<=image_size-1;j++){
			k = i*image_size+j;
			image_V[k] = image_H[i][j];
		}
	}
	//Vertical filter
	for (i=4;i<=image_size-8;i++){       // Skip first 2 and last 2 rows.
		for (j=4; j<=image_size-8;j++) { // Skip first and last column.
			k=i*image_size + j;          // Central value
			*(filter_addr+8) = image_V[k-3*image_size]; //p0
			*(filter_addr+9) = image_V[k-2*image_size]; //p1
			*(filter_addr+10) = image_V[k-image_size]; 	//p2
			*(filter_addr+11) = image_V[k]; 				//p3 : Central value
			*(filter_addr+12) = image_V[k+image_size]; 	//p5
			*(filter_addr+13) = image_V[k+2*image_size]; //p6
			*(filter_addr+14) = image_V[k+3*image_size]; //p7
			*(filter_addr+15) = 0; 						//p8
			image_VH[i][j] = *(filter_addr+16);
		}
	}
	// Initialize edges:
	for (i=0; i<=3; i++) {
		for (j=4; j<=image_size-8;j++) {
			image_VH[i][j] = 0;
		}
	}
	for (i=image_size-7; i<=image_size-1; i++) {
		for (j=4; j<=image_size-8;j++) {
			image_VH[i][j] = 0;
		}
	}
	for (j=0; j<=3; j++) {
		for (i=4; i<=image_size-5;i++) {
			image_VH[i][j] = 0;
		}
	}
	for (j=image_size-7; j<=image_size-1; j++) {
		for (i=4; i<=image_size-8;i++) {
			image_VH[i][j] = 0;
		}
	}
	// processing end
	for (i=0;i<=image_size-1;i++){
		for (j=0 ; j <=image_size-1;j++) {
			NumOfCharsToWrite = itoa(image_VH[i][j], ptr, NUMOFCHARS);
			// write gaussian filter result to text file
			f_write(&file1,(const void*)ptr, NumOfCharsToWrite,&BytesRW);
		}
	}
	f_close(&file1);
	xil_printf("End Gaussian Filter\n\r");
    return 0;
}

int itoa(int n, char s[], int NumOfChars)
{
    int j, sign;
    for(j=0; j<=NumOfChars-4; j++)
    	s[j] = '0';

    s[NumOfChars-3] = '\0';
    s[NumOfChars-2] = 13;
    s[NumOfChars-1] = 10;

    if ((sign = n) < 0)  /* record sign */
        n = -n;          /* make n positive */

    j = NumOfChars-4;
    if (n != 0) {
    	do {       /* generate digits in reverse order */
    	  s[j--] = n % 10 + '0';   /* get next digit */
    	} while ((n /= 10) > 0);//while ((n /= 10) != 0);      /* delete it */
    	if (sign < 0)
    	    s[j--] = '-';

       return(NumOfChars);  // Always fixed to a multiple of 4 (not checked)
    }

    return(NumOfChars);
}

int XDcfg_TransferBitfile(XDcfg *DcfgInstPtr, int PartialCfg, u32 PartialAddress, u32 bitfile_length_words, int att, int class)
{
	//simulate attack launched by rootkit kernel
	if (att==1 && class==0)
	{
		PartialAddress=PARTIAL_SOBEL_ADDR;
	    bitfile_length_words=PARTIAL_SOBEL_BITFILE_LEN;
	}
	else if (att==1 && class==1)
	{
		PartialAddress=PARTIAL_GAUSSIAN_ADDR;
		bitfile_length_words=PARTIAL_GAUSSIAN_BITFILE_LEN;
	}

	u32 IntrStsReg = 0;

	XDcfg_Transfer(DcfgInstPtr, (u8 *)PartialAddress, bitfile_length_words,
		(u8 *)XDCFG_DMA_INVALID_ADDRESS,
		0, XDCFG_NON_SECURE_PCAP_WRITE);

	// Poll IXR_DMA_DONE
	IntrStsReg = XDcfg_IntrGetStatus(DcfgInstPtr);
	while ((IntrStsReg & XDCFG_IXR_DMA_DONE_MASK) !=
			XDCFG_IXR_DMA_DONE_MASK) {
		IntrStsReg = XDcfg_IntrGetStatus(DcfgInstPtr);
	}

	if (PartialCfg) {
		/* Poll IXR_D_P_DONE */
		while ((IntrStsReg & XDCFG_IXR_D_P_DONE_MASK) !=
				XDCFG_IXR_D_P_DONE_MASK) {
			IntrStsReg = XDcfg_IntrGetStatus(DcfgInstPtr);
		}
	} else {
		/* Poll IXR_PCFG_DONE */
		while ((IntrStsReg & XDCFG_IXR_PCFG_DONE_MASK) !=
				XDCFG_IXR_PCFG_DONE_MASK) {
			IntrStsReg = XDcfg_IntrGetStatus(DcfgInstPtr);
		}
		// Enable the level-shifters from PS to PL.
		Xil_Out32(SLCR_UNLOCK, SLCR_UNLOCK_VAL);
		Xil_Out32(SLCR_LVL_SHFTR_EN, 0xF);
		Xil_Out32(SLCR_LOCK, SLCR_LOCK_VAL);
	}
	return XST_SUCCESS;
}

int main()
{
	u32 PartialAddress;
	int Status;
	u32 IntrStsReg = 0;
	u32 StatusReg;
	u32 PartialCfg = 0;
    Xuint32 *filter_addr = (Xuint32 *) XPAR_IP_LFSR_S00_AXI_BASEADDR;

	// Flush and disable Data Cache
	Xil_DCacheDisable();

    // Initialize SD controller and transfer partials to DDR
	SD_Init();
    SD_TransferPartial("sobel.bin", PARTIAL_SOBEL_ADDR, (PARTIAL_SOBEL_BITFILE_LEN << 2));
	SD_TransferPartial("gaussian.bin", PARTIAL_GAUSSIAN_ADDR, (PARTIAL_GAUSSIAN_BITFILE_LEN << 2));
	xil_printf("Partial Binaries transferred successfully!\r\n");

	// Invalidate and enable Data Cache
	Xil_DCacheEnable();

	// Initialize Device Configuration Interface
	DcfgInstPtr = &DcfgInstance;
	XDcfg_0 = XDcfg_LookupConfig(XPAR_XDCFG_0_DEVICE_ID) ;
	Status =  XDcfg_CfgInitialize(DcfgInstPtr, XDcfg_0, XDcfg_0->BaseAddr);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// Check first time configuration or partial reconfiguration
	IntrStsReg = XDcfg_IntrGetStatus(DcfgInstPtr);
	if (IntrStsReg & XDCFG_IXR_DMA_DONE_MASK) {
		PartialCfg = 1;
	}

	// Enable the pcap clock.
	StatusReg = Xil_In32(SLCR_PCAP_CLK_CTRL);
	if (!(StatusReg & SLCR_PCAP_CLK_CTRL_EN_MASK)) {
		Xil_Out32(SLCR_UNLOCK, SLCR_UNLOCK_VAL);
		Xil_Out32(SLCR_PCAP_CLK_CTRL,
				(StatusReg | SLCR_PCAP_CLK_CTRL_EN_MASK));
		Xil_Out32(SLCR_UNLOCK, SLCR_LOCK_VAL);
	}

	// Disable the level-shifters from PS to PL.
	if (!PartialCfg) {
		Xil_Out32(SLCR_UNLOCK, SLCR_UNLOCK_VAL);
		Xil_Out32(SLCR_LVL_SHFTR_EN, 0xA);
		Xil_Out32(SLCR_LOCK, SLCR_LOCK_VAL);
	}

	// Select PCAP interface for partial reconfiguration
	if (PartialCfg) {
		XDcfg_EnablePCAP(DcfgInstPtr);
		XDcfg_SetControlRegister(DcfgInstPtr, XDCFG_CTRL_PCAP_PR_MASK);
	}

	// Clear the interrupt status bits
	XDcfg_IntrClear(DcfgInstPtr, (XDCFG_IXR_PCFG_DONE_MASK |
					XDCFG_IXR_D_P_DONE_MASK |
					XDCFG_IXR_DMA_DONE_MASK));

	// Check if DMA command queue is full
	StatusReg = XDcfg_ReadReg(DcfgInstPtr->Config.BaseAddr,
				XDCFG_STATUS_OFFSET);
	if ((StatusReg & XDCFG_STATUS_DMA_CMD_Q_F_MASK) ==
			XDCFG_STATUS_DMA_CMD_Q_F_MASK) {
		return XST_FAILURE;
	}
    // Display Menu
    int Exit = 0;
    int OptionNext = 1; // start-up default


		print("Select the Filter Operation modified version demo\n\r");
			print("    1: Sobel filter (legal operation) \n\r");
			print("    2: Gaussian filter (legal operation) \n\r");
			print("    3: Sobel filter (secure operation under attack) \n\r");
			print("    4: Gaussian filter (secure operation under attack) \n\r");
			print("    5: Sobel filter (unsecure operation under attack) \n\r");
			print("    6: Gaussian filter (unsecure operation under attack) \n\r");
			print("    0: Exit\n\r");
			print("> ");

			OptionNext = inbyte();

			if (isalpha(OptionNext)) {
			OptionNext = toupper(OptionNext);
		}

			xil_printf("%c\n\r", OptionNext);


		switch (OptionNext) {
			case '0':
				Exit = 1;
				break;
		case '1':
				Reset = 1;
				PartialAddress = PARTIAL_SOBEL_ADDR;
				xil_printf("Starting Sobel Reconfiguration\n\r");
				Status = XDcfg_TransferBitfile(DcfgInstPtr, PartialCfg, PartialAddress, PARTIAL_SOBEL_BITFILE_LEN,0,0);
					*(filter_addr+3)=1;//update: start reconfiguration
			if (Status == XST_SUCCESS)
			{
					*(filter_addr+5)=1; //reconf_done
					*(filter_addr+3)=0;

					while (*(filter_addr+19)==0) //initialize signal used by SipHash core
					{
					xil_printf("wait for init \n");
					}
					if (*(filter_addr+19)==1)
					{
						*(filter_addr+7)=1; //software ready to receive challenge

					xil_printf("challenge received \n");
					*(filter_addr+5)=0;
					}
					xil_printf("Start response evaluation \n");
					/////////////////////Hash Evaluation in Software////////////
				    uint64_t in, out, k0,k1;
				   in = ( uint64_t) *(filter_addr+18) << 32 | *(filter_addr+17);
					//secret key
					k0=0xf0e0d0c0b0b09080;
					k1=0x97060504030201000;
				out=siphash(in, k0,k1,8);
					////////////////Send response///////////////////////
					*(filter_addr+0)= (uint32_t)( out & 0xFFFFFFFFLL);
					*(filter_addr+1) = (uint32_t)((out & 0xFFFFFFFF00000000LL) >> 32);
					*(filter_addr+6)=1;

					while (*(filter_addr+28)==0){
						xil_printf("comparison not done yet \n");

                  	}

					if (*(filter_addr+28)==1){
						xil_printf("Hash comparison done\n");
						xil_printf("value of activate SW= %d \n\r",*(filter_addr+26));
					}

					if (*(filter_addr+26)==0){
						xil_printf("MAC Mismatches!\n\r");

											xil_printf("Hardware MAC lower 32 bits = %x\n\r",*(filter_addr+51));

											xil_printf("Hardware MAC upper 32 bits = %x\n\r",*(filter_addr+52));

											xil_printf("Software MAC lower 32 bits = %x\n\r",*(filter_addr+0));

											xil_printf("Software MAC upper 32 bits = %x\n\r",*(filter_addr+1));
							exit(EXIT_FAILURE);
										}
					else {

						xil_printf("MAC Matches!\n\r");

											xil_printf("Hardware MAC lower 32 bits = %x\n\r",*(filter_addr+51));

											xil_printf("Hardware MAC upper 32 bits = %x\n\r",*(filter_addr+52));

											xil_printf("Software MAC lower 32 bits = %x\n\r",*(filter_addr+0));

											xil_printf("Software MAC upper 32 bits = %x\n\r",*(filter_addr+1));
						xil_printf("start processing!\n\r");

						get_imagefilesobel("sobel.txt");
						//exit(EXIT_FAILURE);

						xil_printf("Sobel Reconfiguration Completed!\n\r");

				}
			}
				else if (Status != XST_SUCCESS) {
					xil_printf("Error : FPGA configuration failed!\n\r");
					exit(EXIT_FAILURE);
				}
				break;

		case '2':
				Reset = 1;
				PartialAddress = PARTIAL_GAUSSIAN_ADDR;
				xil_printf("Starting gaussian Reconfiguration\n\r");
				Status = XDcfg_TransferBitfile(DcfgInstPtr, PartialCfg, PartialAddress, PARTIAL_GAUSSIAN_BITFILE_LEN,0,0);
					*(filter_addr+3)=1;
					*(filter_addr+4)=0;
				//	xil_printf("status value=%d\n\r",XST_SUCCESS);

			if (Status == XST_SUCCESS)
			{
					*(filter_addr+5)=1; //
					*(filter_addr+3)=0;

					while (*(filter_addr+19)==0)
					{
					xil_printf("wait for init \n");
					}
					if (*(filter_addr+19)==1)
					{
					//	xil_printf("value of %d is %d \n",33,*(filter_addr+33));
						*(filter_addr+7)=1;

					xil_printf("challenge received \n");
					*(filter_addr+5)=0; //
					}
				  //  xil_printf("value of %d is %d \n",33,*(filter_addr+33));
					xil_printf("Start response evaluation \n");



					/////////////////////Hash Evaluation in Software////////////
				    uint64_t in, out, k0,k1;
				//    int i;
				 //   int fails = 0;
				   in = ( uint64_t) *(filter_addr+18) << 32 | *(filter_addr+17);

					xil_printf("value of challenge is %llx \n",in);
					//secret key
				k0=0x9006050403020100;
				k1=0xf0e0d0c0b0b09080;

				out=siphash(in, k0,k1,8);

					///////////////////////////////////////
					*(filter_addr+0)= (uint32_t)( out & 0xFFFFFFFFLL);
					*(filter_addr+1) = (uint32_t)((out & 0xFFFFFFFF00000000LL) >> 32);
					*(filter_addr+6)=1;

					while (*(filter_addr+28)==0){
						xil_printf("comparison not done yet \n\r");

						int i;
	}

					if (*(filter_addr+28)==1){
						xil_printf("value of activate SW= %d \n\r",*(filter_addr+26));
					}

					if (*(filter_addr+26)==0){
						xil_printf("MAC Mismatches!\n\r");

											xil_printf("Hardware MAC lower 32 bits = %x\n\r",*(filter_addr+51));

											xil_printf("Hardware MAC upper 32 bits = %x\n\r",*(filter_addr+52));

											xil_printf("Software MAC lower 32 bits = %x\n\r",*(filter_addr+0));

											xil_printf("Software MAC upper 32 bits = %x\n\r",*(filter_addr+1));

							exit(EXIT_FAILURE);
										}
					else {
						xil_printf("MAC Matches!\n\r");

											xil_printf("Hardware MAC lower 32 bits = %x\n\r",*(filter_addr+51));

											xil_printf("Hardware MAC upper 32 bits = %x\n\r",*(filter_addr+52));

											xil_printf("Software MAC lower 32 bits = %x\n\r",*(filter_addr+0));

											xil_printf("Software MAC upper 32 bits = %x\n\r",*(filter_addr+1));
						xil_printf("start processing!\n\r");

						get_imagefilesobel("gaussian.txt");
						//exit(EXIT_FAILURE);

						xil_printf("Gaussian Reconfiguration Completed!\n\r");

				}
			}
				else if (Status != XST_SUCCESS) {
					xil_printf("Error : FPGA configuration failed!\n\r");
					exit(EXIT_FAILURE);
				}
				break;
		case '3':
				Reset = 1;
				PartialAddress = PARTIAL_SOBEL_ADDR;
				xil_printf("Starting Sobel Reconfiguration\n\r");
				Status = XDcfg_TransferBitfile(DcfgInstPtr, PartialCfg, PartialAddress, PARTIAL_SOBEL_BITFILE_LEN,1,1);
					*(filter_addr+3)=1;
					*(filter_addr+4)=0;
					//xil_printf("status value=%d\n\r",XST_SUCCESS);

			if (Status == XST_SUCCESS)
			{
					*(filter_addr+5)=1; //
					*(filter_addr+3)=0;

					while (*(filter_addr+19)==0)
					{
					xil_printf("wait for init \n");
					}
					if (*(filter_addr+19)==1)
					{
						//xil_printf("value of %d is %d \n",33,*(filter_addr+33));
						*(filter_addr+7)=1;

					xil_printf("challenge received \n");
					}
				    //xil_printf("value of %d is %d \n",33,*(filter_addr+33));
					xil_printf("Start hash evaluation \n");
					//xil_printf("value of %d is %d \n",33,*(filter_addr+33));
					//xil_printf("value of %d is %d \n",33,*(filter_addr+33));

					//xil_printf("here \n");
					/////////////////////Hash Evaluation in Software////////////
				    uint64_t in, out, k0,k1;
				//    int i;
				 //   int fails = 0;
				   in = ( uint64_t) *(filter_addr+18) << 32 | *(filter_addr+17);

					//xil_printf("value of challenge is %llx \n",in);
					//secret key
					k0=0xf0e0d0c0b0b09080;
					k1=0x97060504030201000;
				out=siphash(in, k0,k1,8);

				*(filter_addr+0)= (uint32_t)( out & 0xFFFFFFFFLL);
				*(filter_addr+1) = (uint32_t)((out & 0xFFFFFFFF00000000LL) >> 32);
					*(filter_addr+6)=1;
					///////////////////////////////////////

					while (*(filter_addr+28)==0){
						xil_printf("comparison not done yet \n");

						int i;
	}

					if (*(filter_addr+28)==1){
											xil_printf("value of activate SW= %d \n\r",*(filter_addr+26));
										}

										if (*(filter_addr+26)==0){
											xil_printf("MAC Mismatches!\n\r");

																xil_printf("Hardware MAC lower 32 bits = %x\n\r",*(filter_addr+51));

																xil_printf("Hardware MAC upper 32 bits = %x\n\r",*(filter_addr+52));

																xil_printf("Software MAC lower 32 bits = %x\n\r",*(filter_addr+0));

																xil_printf("Software MAC upper 32 bits = %x\n\r",*(filter_addr+1));

												exit(EXIT_FAILURE);
															}
					else {
						xil_printf("MAC Matches!\n\r");

						xil_printf("Hardware MAC lower 32 bits = %x\n\r",*(filter_addr+51));

						xil_printf("Hardware MAC upper 32 bits = %x\n\r",*(filter_addr+52));

						xil_printf("Software MAC lower 32 bits = %x\n\r",*(filter_addr+0));

						xil_printf("Software MAC upper 32 bits = %x\n\r",*(filter_addr+1));
						xil_printf("start processing!\n\r");

						get_imagefilesobel("sobel.txt");
						//exit(EXIT_FAILURE);

						xil_printf("Sobel Reconfiguration Completed!\n\r");

				}
			}
				else if (Status != XST_SUCCESS) {
					xil_printf("Error : FPGA configuration failed!\n\r");
					exit(EXIT_FAILURE);
				}
				break;
		case '4':
				Reset = 1;
				PartialAddress = PARTIAL_GAUSSIAN_ADDR;
								xil_printf("Starting Gaussian Reconfiguration\n\r");
								Status = XDcfg_TransferBitfile(DcfgInstPtr, PartialCfg, PartialAddress, PARTIAL_GAUSSIAN_BITFILE_LEN,1,0);

					*(filter_addr+3)=1;
					*(filter_addr+4)=0;
					//xil_printf("status value=%d\n\r",XST_SUCCESS);

			if (Status == XST_SUCCESS)
			{
					*(filter_addr+5)=1; //
					*(filter_addr+3)=0;

					while (*(filter_addr+19)==0)
					{
					xil_printf("wait for init \n");
					}
					if (*(filter_addr+19)==1)
					{
						//xil_printf("value of %d is %d \n",33,*(filter_addr+33));
						*(filter_addr+7)=1;

					xil_printf("challenge received \n");
					}
				    //xil_printf("value of %d is %d \n",33,*(filter_addr+33));
					xil_printf("Start hash evaluation\n");
					//xil_printf("value of %d is %d \n",33,*(filter_addr+33));
					//xil_printf("value of %d is %d \n",33,*(filter_addr+33));

					//xil_printf("here \n");
					/////////////////////Hash Evaluation in Software////////////
				    uint64_t in, out, k0,k1;
				//    int i;
				 //   int fails = 0;
				   in = ( uint64_t) *(filter_addr+18) << 32 | *(filter_addr+17);

					//xil_printf("value of challenge is %lx \n",in);
					//secret key
					k0=0x9006050403020100;
					k1=0xf0e0d0c0b0b09080;
				out=siphash(in, k0,k1,8);

				*(filter_addr+0)= (uint32_t)( out & 0xFFFFFFFFLL);
				*(filter_addr+1) = (uint32_t)((out & 0xFFFFFFFF00000000LL) >> 32);
					*(filter_addr+6)=1;
					///////////////////////////////////////

					while (*(filter_addr+28)==0){
						xil_printf("comparison not done yet \n");

						int i;
	}

					if (*(filter_addr+28)==1){
											xil_printf("value of activate SW= %d \n\r",*(filter_addr+26));
										}

										if (*(filter_addr+26)==0){
											xil_printf("MAC misatches!\n\r");

																xil_printf("Hardware MAC lower 32 bits = %x\n\r",*(filter_addr+51));

																xil_printf("Hardware MAC upper 32 bits = %x\n\r",*(filter_addr+52));

																xil_printf("Software MAC lower 32 bits = %x\n\r",*(filter_addr+0));

																xil_printf("Software MAC upper 32 bits = %x\n\r",*(filter_addr+1));
												exit(EXIT_FAILURE);
															}
					else {
						xil_printf("MAC Matches!\n\r");

											xil_printf("Hardware MAC lower 32 bits = %x\n\r",*(filter_addr+51));

											xil_printf("Hardware MAC upper 32 bits = %x\n\r",*(filter_addr+52));

											xil_printf("Software MAC lower 32 bits = %x\n\r",*(filter_addr+0));

											xil_printf("Software MAC upper 32 bits = %x\n\r",*(filter_addr+1));
						xil_printf("start processing!\n\r");

						get_imagefilegaussian("gaussian.txt");
						get_imagefilegaussian("gaussian.txt");
						//exit(EXIT_FAILURE);

						xil_printf("Gaussian Reconfiguration Completed!\n\r");

				}
			}
				else if (Status != XST_SUCCESS) {
					xil_printf("Error : FPGA configuration failed!\n\r");
					exit(EXIT_FAILURE);
				}
				break;
		case '5':
				Reset = 1;
				PartialAddress = PARTIAL_SOBEL_ADDR;
				xil_printf("Starting Sobel Reconfiguration\n\r");
				Status = XDcfg_TransferBitfile(DcfgInstPtr, PartialCfg, PartialAddress, PARTIAL_SOBEL_BITFILE_LEN,1,1);

					//xil_printf("status value=%d\n\r",XST_SUCCESS);

			if (Status == XST_SUCCESS)
			{
								xil_printf("start processing!\n\r");

						get_imagefilesobel("sobel.txt");
						//exit(EXIT_FAILURE);

						xil_printf("Sobel Reconfiguration Completed!\n\r");


			}
				else if (Status != XST_SUCCESS) {
					xil_printf("Error : FPGA configuration failed!\n\r");
					exit(EXIT_FAILURE);
				}
				break;
		case '6':
				Reset = 1;
				PartialAddress = PARTIAL_GAUSSIAN_ADDR;
												xil_printf("Starting Gaussian Reconfiguration\n\r");
												Status = XDcfg_TransferBitfile(DcfgInstPtr, PartialCfg, PartialAddress, PARTIAL_GAUSSIAN_BITFILE_LEN,1,0);

					//xil_printf("status value=%d\n\r",XST_SUCCESS);

			if (Status == XST_SUCCESS)
			{

						xil_printf("start processing!\n\r");

						get_imagefilegaussian("gaussian.txt");
						//exit(EXIT_FAILURE);

						xil_printf("Gaussian Reconfiguration Completed!\n\r");


			}
				else if (Status != XST_SUCCESS) {
					xil_printf("Error : FPGA configuration failed!\n\r");
					exit(EXIT_FAILURE);
				}
				break;
		default:
			break;
	//}
}

return 0;
}

