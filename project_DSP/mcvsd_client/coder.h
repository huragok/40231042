/***************************************************************
  File Name      : coder.h
  Module Name    : CODER

  ----------------------------------------------------------------------------
  Description    : 
***********************************************************************/

#include "mds_def.h"

#ifndef _CODER_H
#define _CODER_H

/* Structures */

/********************************************************************
  Struct name :  fir_state_fr16

 *******************************************************************
  Purpose     :  Filter structure for FIR filter functions.
  Description :  This FIR filter structure contains information 
                 regarding the state of the FIR filter.

 *******************************************************************/

typedef struct 
{
    fract16 *h;    /*  filter coefficients            */
	fract16 *d;    /*  start of delay line            */
	int k;         /*  number of coefficients         */
} fir_state_fr16;

/* Macros */

#define fir_init(state, coef, delay, samples) \
    (state).h = (coef); \
    (state).d = (delay); \
    (state).k = (samples); \

#define iir_init(state, coef, delay, stages) \
    (state).c = (coef); \
    (state).d = (delay); \
    (state).k = (stages)

void _code_mcvsd(const fract16 x[],fract16 y[],int n, const fract16 delta0, const fract16 delta_min, const fract16 alpha, const fract16 beta, fir_state_fr16 *s1, fir_state_fr16 *s2, const fract16 *sr, const fract16 *delta, const fract32 *d, const int step);
void _decode_mcvsd(const fract16 y[],fract16 x[],int n, const fract16 delta0, const fract16 delta_min, const fract16 alpha, const fract16 beta, fir_state_fr16 *s1, fir_state_fr16 *s2, const fract16 *sr, const fract16 *delta, const fract32 *d, const int step, fir_state_fr16 *s3);
#endif

