#include "Talkthrough.h"
#include "coder.h"
#include <string.h>

extern fract16 delta0;
extern fract16 delta_min;
extern fract16 alpha;
extern fract16 beta; 

#if IS_SERVER
extern fir_state_fr16 s1_tx_L;
extern fir_state_fr16 s2_tx_L;

extern fir_state_fr16 s1_tx_R;
extern fir_state_fr16 s2_tx_R;

extern fract16 sr_tx_L;
extern fract16 delta_tx_L;
extern fract32 d_tx_L;
extern fract16 sr_tx_R;
extern fract16 delta_tx_R;
extern fract32 d_tx_R;
#endif

#if IS_CLIENT
extern fir_state_fr16 s1_rx_L;
extern fir_state_fr16 s2_rx_L;
extern fir_state_fr16 s3_rx_L;

extern fir_state_fr16 s1_rx_R;
extern fir_state_fr16 s2_rx_R;
extern fir_state_fr16 s3_rx_R;

extern fract16 sr_rx_L;
extern fract16 delta_rx_L;
extern fract32 d_rx_L;
extern fract16 sr_rx_R;
extern fract16 delta_rx_R;
extern fract32 d_rx_R;
#endif

//用舸胖的变量
extern fract16 *code_MCVSD_L;
extern fract16 *code_MCVSD_R;

//--------------------------------------------------------------------------//
// Function:	Process_Data()												//
//																			//
// Description: This function is called for each DMA RX Complete Interrupt, //
//				or 2*FRAMESIZE samples for a stereo signal. Then left and   //
//				right channels are separately filtered ping-pong mode.	    //
//--------------------------------------------------------------------------//
void Process_Data(void)
{
	   
	// Ping-Pong Flag	
    static int ping = 0;

    /* core processing in ping-pong mode */
    if(0 == ping) {
        
        
        // left and right channels coding and decoding, ping slot
		#if IS_SERVER
		_code_mcvsd(RxPing+0,code_MCVSD_L,FRAMESIZE, delta0, delta_min, alpha, beta, &s1_tx_L, &s2_tx_L, &sr_tx_L, &delta_tx_L, &d_tx_L,2);
		_code_mcvsd(RxPing+1,code_MCVSD_R,FRAMESIZE, delta0, delta_min, alpha, beta, &s1_tx_R, &s2_tx_R, &sr_tx_R, &delta_tx_R, &d_tx_R,2);
		#endif

		
		_decode_mcvsd(code_MCVSD_L,TxPing+0,FRAMESIZE, delta0, delta_min, alpha, beta, &s1_rx_L, &s2_rx_L, &sr_rx_L, &delta_rx_L, &d_rx_L,2, &s3_rx_L);
		_decode_mcvsd(code_MCVSD_R,TxPing+1,FRAMESIZE, delta0, delta_min, alpha, beta, &s1_rx_R, &s2_rx_R, &sr_rx_R, &delta_rx_R, &d_rx_R,2, &s3_rx_R);	
		#endif
//        memcpy(TxPing, RxPing, 2*FRAMESIZE*sizeof(RxPing[0]));
        
    } else {

        
        // left and right channels coding and decoding, pong slot
		#if IS_SERVER
        _code_mcvsd(RxPong+0,code_MCVSD_L,FRAMESIZE, delta0, delta_min, alpha, beta, &s1_tx_L, &s2_tx_L, &sr_tx_L, &delta_tx_L, &d_tx_L,2);
		_code_mcvsd(RxPong+1,code_MCVSD_R,FRAMESIZE, delta0, delta_min, alpha, beta, &s1_tx_R, &s2_tx_R, &sr_tx_R, &delta_tx_R, &d_tx_R,2);
		#endif

		#if IS_CLIENT
		_decode_mcvsd(code_MCVSD_L,TxPong+0,FRAMESIZE, delta0, delta_min, alpha, beta, &s1_rx_L, &s2_rx_L, &sr_rx_L, &delta_rx_L, &d_rx_L,2, &s3_rx_L);
		_decode_mcvsd(code_MCVSD_R,TxPong+1,FRAMESIZE, delta0, delta_min, alpha, beta, &s1_rx_R, &s2_rx_R, &sr_rx_R, &delta_rx_R, &d_rx_R,2, &s3_rx_R);
		#endif
//        memcpy(TxPong, RxPong, 2*FRAMESIZE*sizeof(RxPong[0]));

    }    	    
    

    
/*    static int cnt = 0;
    cnt = cnt + 1;
    
    if((cnt>=100) && (cnt<140)) 
    {
        if (0==ping)
        {
     		memcpy((void *)(RxBUF+2*FRAMESIZE*(cnt-100)),RxPing,2*FRAMESIZE*sizeof(RxPing[0]));
     		memcpy((void *)(TxBUF+2*FRAMESIZE*(cnt-100)),TxPing,2*FRAMESIZE*sizeof(TxPing[0]));
        }
     	else
     	{
     		memcpy((void *)(RxBUF+2*FRAMESIZE*(cnt-100)),RxPong,2*FRAMESIZE*sizeof(RxPong[0]));
     		memcpy((void *)(TxBUF+2*FRAMESIZE*(cnt-100)),TxPong,2*FRAMESIZE*sizeof(TxPong[0]));
     	}
    }
*/    
    ping ^= 0x1;
       
}
