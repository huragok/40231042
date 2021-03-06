//--------------------------------------------------------------------------//
//																			//
//	 Name: 	Talkthrough with FIR for the ADSP-BF561 EZ-KIT Lite						//
//																			//
//--------------------------------------------------------------------------//
//																			//
//	(C) Copyright 2003 - Analog Devices, Inc.  All rights reserved.			//
//																			//
//	Project Name:	BF561 C Talkthrough TDM									//
//																			//
//	Date Modified:	16/10/03		HD		Rev 0.2							//
//																			//
//	Software:		VisualDSP++3.5											//
//																			//
//	Hardware:		ADSP-BF561 EZ-KIT Board									//
//																			//
//	Connections:	Dipswitch SW4 : set #6 to "on"							//
//					Dipswitch SW4 : set #5 to "off"							//
//					Connect an input source (such as a radio) to the Audio	//
//					input jack and an output source (such as headphones) to //
//					the Audio output jack									//
//																			//
//	Purpose:		This program sets up the SPI port on the ADSP-BF561 to  //
//					configure the AD1836 codec.  The SPI port is disabled 	//
//					after initialization.  The data to/from the codec are 	//
//					transfered over SPORT0 in TDM mode						//
//																			//
//--------------------------------------------------------------------------//


#include "Talkthrough.h"

// FIR stuffs 
#include "mds_def.h"
#include "coder.h"
#include "fir_coeff.h"
#include "EthFunc.h"

// AD1836 Control Register Values
volatile short sCodec1836TxRegs[CODEC_1836_REGS_LENGTH] =
{									
					DAC_CONTROL_1	| 0x010,
					DAC_CONTROL_2	| 0x000,
					DAC_VOLUME_0	| 0x3ff,
					DAC_VOLUME_1	| 0x3ff,
					DAC_VOLUME_2	| 0x3ff,
					DAC_VOLUME_3	| 0x3ff,
					DAC_VOLUME_4	| 0x3ff,
					DAC_VOLUME_5	| 0x3ff,
					ADC_CONTROL_1	| 0x012,
					ADC_CONTROL_2	| 0x020,
					ADC_CONTROL_3	| 0x000	
};


/**************************************************
    DMA RX and TX Ping-Pong Buffer Definitions  
***************************************************/
// SPORT0 DMA Receive Double Buffer, ping + pong
short RxBuffer[2*FRAMESIZE + 2*FRAMESIZE];

// SPORT0 DMA Transmit Double Buffer, ping + pong
short TxBuffer[2*FRAMESIZE + 2*FRAMESIZE];


//short RxBUF[80*FRAMESIZE];
//short TxBUF[80*FRAMESIZE];

// Ping Pong Buffer Pointers
short* RxPing = RxBuffer;
short* RxPong = RxBuffer + 2*FRAMESIZE;

short* TxPing = TxBuffer;
short* TxPong = TxBuffer + 2*FRAMESIZE;

/*************************************************
    FIR  Definitions
**************************************************/
/* Constants */
#define DELAY_SIZE_MCVSD1	LEN_LPF_MCVSD1
#define DELAY_SIZE_MCVSD2	LEN_LPF_MCVSD2
#define DELAY_SIZE_CVSD		LEN_LPF_CVSD

fract16 delta0=115,
		delta_min=33,
		alpha=32604,
		beta=24576; 

#if IS_SERVER
fract16 delay_MCVSD1_tx_L[DELAY_SIZE_MCVSD1];
fract16 delay_MCVSD2_tx_L[DELAY_SIZE_MCVSD2];
fract16 delay_MCVSD1_tx_R[DELAY_SIZE_MCVSD1];
fract16 delay_MCVSD2_tx_R[DELAY_SIZE_MCVSD2];

fract16 sr_tx_L;
fract16 delta_tx_L=3277;
fract32 d_tx_L;
fract16 sr_tx_R;
fract16 delta_tx_R=3277;
fract32 d_tx_R;

fir_state_fr16 s1_tx_L,s2_tx_L;
fir_state_fr16 s1_tx_R,s2_tx_R;

ETH_DATA send;
#endif

#if IS_CLIENT
fract16 delay_MCVSD1_rx_L[DELAY_SIZE_MCVSD1];
fract16 delay_MCVSD2_rx_L[DELAY_SIZE_MCVSD2];
fract16 delay_CVSD_rx_L[DELAY_SIZE_CVSD];
fract16 delay_MCVSD1_rx_R[DELAY_SIZE_MCVSD1];
fract16 delay_MCVSD2_rx_R[DELAY_SIZE_MCVSD2];
fract16 delay_CVSD_rx_R[DELAY_SIZE_CVSD];

fract16 sr_rx_L;
fract16 delta_rx_L=3277;
fract32 d_rx_L;
fract16 sr_rx_R;
fract16 delta_rx_R=3277;
fract32 d_rx_R;

fir_state_fr16 s1_rx_L,s2_rx_L,s3_rx_L;
fir_state_fr16 s1_rx_R,s2_rx_R,s3_rx_R;

ETH_DATA receive;
#endif

//�������ֵ�����

fract16 code_MCVSD_L[BIT_OUTPUT_SIZE];
fract16 code_MCVSD_R[BIT_OUTPUT_SIZE];

//--------------------------------------------------------------------------//
// Function:	main														//
//																			//
// Description:	After calling a few initalization routines, main() just 	//
//				waits in a loop forever.  The code to process the incoming  //
//				data can be placed in the function Process_Data() in the 	//
//				file "Process_Data.c".										//
//--------------------------------------------------------------------------//
void main(void)
{

	// unblock Core B if dual core operation is desired	
#ifndef RUN_ON_SINGLE_CORE	// see talkthrough.h
	*pSICA_SYSCR &= 0xFFDF; // clear bit 5 to unlock  
#endif

	Init1836();
	Init_Sport0();
	Init_DMA();
	Init_Sport_Interrupts();
	Enable_DMA_Sport0();

	#if IS_SERVER
	InitPacketHead(send);
	fir_init(s1_tx_L, lpf_mcvsd1, delay_MCVSD1_tx_L, DELAY_SIZE_MCVSD1);
	fir_init(s2_tx_L, lpf_mcvsd2, delay_MCVSD2_tx_L, DELAY_SIZE_MCVSD2);

	fir_init(s1_tx_R, lpf_mcvsd1, delay_MCVSD1_tx_R, DELAY_SIZE_MCVSD1);
	fir_init(s2_tx_R, lpf_mcvsd2, delay_MCVSD2_tx_R, DELAY_SIZE_MCVSD2);
	#endif

	#if IS_CLIENT
	fir_init(s1_rx_L, lpf_mcvsd1, delay_MCVSD1_rx_L, DELAY_SIZE_MCVSD1);
	fir_init(s2_rx_L, lpf_mcvsd2, delay_MCVSD2_rx_L, DELAY_SIZE_MCVSD2);
	fir_init(s3_rx_L, lpf_cvsd, delay_CVSD_rx_L, DELAY_SIZE_CVSD);
	
	fir_init(s1_rx_R, lpf_mcvsd1, delay_MCVSD1_rx_R, DELAY_SIZE_MCVSD1);
	fir_init(s2_rx_R, lpf_mcvsd2, delay_MCVSD2_rx_R, DELAY_SIZE_MCVSD2);
	fir_init(s3_rx_R, lpf_cvsd, delay_CVSD_rx_R, DELAY_SIZE_CVSD);
	#endif
	    	
	while(1);
}
