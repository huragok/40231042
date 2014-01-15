
/****************************************************************************
 Copyright (c) 2000 Analog Devices Inc. All rights reserved.
 ***************************************************************************
  File Name      : fir_test.c
  Description    : This module tests the fir function.

***************************************************************************/

/* Includes */
#include "mds_def.h"
#include "coder.h"
#include "fir_coeff.h"
#include "voice_input.h"

/* Constants */
#define DELAY_SIZE_MCVSD1	LEN_LPF_MCVSD1
#define DELAY_SIZE_MCVSD2	LEN_LPF_MCVSD2
#define DELAY_SIZE_CVSD		LEN_LPF_CVSD

fract16 delay_MCVSD1_tx[DELAY_SIZE_MCVSD1];
fract16 delay_MCVSD2_tx[DELAY_SIZE_MCVSD2];

fract16 delay_MCVSD1_rx[DELAY_SIZE_MCVSD1];
fract16 delay_MCVSD2_rx[DELAY_SIZE_MCVSD2];
fract16 delay_CVSD_rx[DELAY_SIZE_CVSD];

fract16 sr_tx;
fract16 delta_tx=3277;
fract32 d_tx;

fract16 sr_rx;
fract16 delta_rx=3277;
fract32 d_rx;

fract16 code_MCVSD[BIT_OUTPUT_SIZE];
fract16 decode_MCVSD[BUFFER_SIZE];

void main()
{
	int	i,
		nsamples,
		step;
		
	fract16 delta0=115,
			delta_min=33,
			alpha=32604,
			beta=24576; 

    fir_state_fr16 s1,s2;
    fir_state_fr16 s3,s4,s5;

    nsamples = BUFFER_SIZE;
    step = 1;
	
	fir_init(s1, lpf_mcvsd1, delay_MCVSD1_tx, DELAY_SIZE_MCVSD1);
	fir_init(s2, lpf_mcvsd2, delay_MCVSD2_tx, DELAY_SIZE_MCVSD2);
	
	fir_init(s3, lpf_mcvsd1, delay_MCVSD1_rx, DELAY_SIZE_MCVSD1);
	fir_init(s4, lpf_mcvsd2, delay_MCVSD2_rx, DELAY_SIZE_MCVSD2);
	fir_init(s5, lpf_cvsd, delay_CVSD_rx, DELAY_SIZE_CVSD);
	
	_code_mcvsd(IN, code_MCVSD, nsamples, delta0, delta_min, alpha, beta, &s1, &s2, &sr_tx, &delta_tx, &d_tx,step);
	_decode_mcvsd(code_MCVSD,decode_MCVSD,nsamples, delta0, delta_min, alpha, beta, &s3, &s4, &sr_rx, &delta_rx, &d_rx, step, &s5);
}

