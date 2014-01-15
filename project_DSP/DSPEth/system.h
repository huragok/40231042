#ifndef  _SYSTEM_DEFINED
#define _SYSTEM_DEFINED

#include "cdefBF561.h"
#include "ccblkfn.h"
#include <sys\exception.h>


#define TC_PER 			0xFFC00B0C
#define pTC_PER 		(volatile unsigned short *)TC_PER
	

/********************************************************************************/
/***** Multipproject global variables and types								*****/
/********************************************************************************/

// semaphores
extern volatile bool semaphore_frames_received;		// signals to core B that output stream can be started

// DMA buffers for each frame 

extern volatile short sFrame0[];
extern volatile short sFrame1[];
extern volatile short sFrame2[];
extern volatile short sFrame3[];

extern int _CORE;


/********************************************************************************/
/***** Symbolic constants													*****/
/********************************************************************************/

// system constants  

#define CLKIN	  (30.0e6)		// clockin frequency in Hz
#define CORECLK  (600.0e6)		// core clock frequency in Hz
#define SYSCLK	  (120.0e6)		// system clock frequency in Hz


// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// ONLY ENTIRE FIELD MODE IS IMPLEMENTED AT THIS TIME
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#define ENTIRE_FIELD_MODE		// comment out for Active Field only
#define PACK_32					// comment out for unpacked DMA transfers


#ifdef ENTIRE_FIELD_MODE
	#define PIXEL_PER_LINE 	(858)
#else
	#define PIXEL_PER_LINE 	(720)
#endif

#define LINES_PER_FRAME		(525)


#define Frame_Size   		(PIXEL_PER_LINE * LINES_PER_FRAME)





#endif

