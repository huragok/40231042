#if IS_SERVER
#include "Talkthrough.h"
#include "coder.h"
#include "EthFunc.h"
#include <string.h>

extern fract16 delta0;
extern fract16 delta_min;
extern fract16 alpha;
extern fract16 beta; 

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

extern ETH_DATA SendData;
extern fract16 *packetBuffer;


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
    if(0 == ping) 
	{    
        // left and right channels coding, ping slot
		_code_mcvsd(RxPing+0,packetBuffer,FRAMESIZE, delta0, delta_min, alpha, beta, &s1_tx_L, &s2_tx_L, &sr_tx_L, &delta_tx_L, &d_tx_L,2);
		_code_mcvsd(RxPing+1,packetBuffer+BIT_OUTPUT_SIZE,FRAMESIZE, delta0, delta_min, alpha, beta, &s1_tx_R, &s2_tx_R, &sr_tx_R, &delta_tx_R, &d_tx_R,2);
		

//        memcpy(TxPing, RxPing, 2*FRAMESIZE*sizeof(RxPing[0]));
        
    } 
	else 
	{  
        // left and right channels coding, pong slot
        _code_mcvsd(RxPong+0,packetBuffer,FRAMESIZE, delta0, delta_min, alpha, beta, &s1_tx_L, &s2_tx_L, &sr_tx_L, &delta_tx_L, &d_tx_L,2);
		_code_mcvsd(RxPong+1,packetBuffer+BIT_OUTPUT_SIZE,FRAMESIZE, delta0, delta_min, alpha, beta, &s1_tx_R, &s2_tx_R, &sr_tx_R, &delta_tx_R, &d_tx_R,2);

//        memcpy(TxPong, RxPong, 2*FRAMESIZE*sizeof(RxPong[0]));

    }    	    
    EthPacketSend(&SendData, packetBuffer, DATA_SIZE);

    
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
#endif
