#define __DEBUG
#include <string.h>
#include <cdefBF561.h>

#include "types.h"
#include "bf5xx.h"
#include "dm9000.h"
//#include "EthFunc.h"

//static void phy_write( int reg, uint16_t value);

static uint8_t ior(int reg);
uint16_t NetRxPackets[PKTSIZE_ALIGN+PKTALIGN]; 
uint8_t env_enetaddr[6];



/****************************************************************************
* 名称 ： GetDM9000ID
* 功能 ： 读取DM9000E ID并打印
* 入口参数 ：无
* 出口参数 ：无
****************************************************************************/
uint32_t GetDM9000ID(void)
{
 	uint32_t id_val;
 	
 	id_val = ior(DM9000_PID_H);
 	printf("DM9000E ID is %x",id_val);
	id_val = ior(DM9000_PID_L);
	printf("%x",id_val);
    id_val = ior(DM9000_VID_H);
    printf("%x",id_val);
    id_val = ior(DM9000_VID_L);
 	printf(" %x\n\r",id_val);
 	return id_val;
}

/****************************************************************************
* 名称 ： iow
* 功能 ： 将值写入指定的寄存器
* 入口参数 ：reg，value
* 出口参数 ：无
****************************************************************************/ 
static void iow(int reg, uint8_t value)
{
 	DM9000_PPTR = reg;
 	asm("csync;");
 	asm("csync;");
 	asm("csync;");
 	DM9000_PDATA  =  value & 0xff;
	asm("csync;");
	asm("csync;");
	asm("csync;"); 	
}
/****************************************************************************
* 名称 ： ior
* 功能 ： 送入要读取的寄存器地址返回当前寄存器值
* 入口参数 ：reg
* 出口参数 ：DM9000_PDATA & 0xff
****************************************************************************/
static uint8_t ior(int reg)
{
 	DM9000_PPTR = reg;
	asm("csync;");
	asm("csync;");
	asm("csync;");
 	return DM9000_PDATA & 0xff;
}
/****************************************************************************
* 名称 ： eth_reset
* 功能 ： 复位，初始化dm9000E并打印相关设置
* 入口参数 ：无
* 出口参数 ：无
****************************************************************************/
void eth_reset (void)
{
 	int IoMode;
 	uint8_t  tmp;
 	
 	iow(0, 1); 									//	复位
 	mdelay(50); 								// delay 100us 
 	IoMode = ior(0xfe) >> 6;  					//读取io模式
 	//printf("%d", IoMode);
 	if(!IoMode)
  	printf("DM9000 work in 16 bus width\r\n");	
 	else if(IoMode == 2)
  	printf("DM9000 work in 8 bus width\r\n");
 	else if(IoMode == 1)
  	printf("DM9000 work in 32 bus width\r\n");
 	else
  	printf("DM9000 work in wrong bus width, error\r\n");
 	iow(0x1e, 0x01);  						
 	iow(0x1f, 0x00);  							// 使能 PHY 
 	iow(0xff, 0x80);  
 	iow(0x01, 0xc);   							// 清除 TX 状态 
 	iow(0x5, 0x33); 							// 使能 RX 
 	ior(0x6);
 	iow(0x2, 1);   								// 使能TX 
 	mdelay(100);
 	IoMode = ior(0x01);
 	if(IoMode & 0x40)
 	printf("Link on ethernet at:%d Mbps\r\n", (IoMode & 0x80) ? 10:100);

}
/****************************************************************************
* 名称 ： eth_rx
* 功能 ： 读取网络传输数据
* 入口参数 ：addr
* 出口参数 ：rxlen
****************************************************************************/
int eth_rx (uint16_t *addr)
{
 	int i;
 	uint16_t rxlen;
 	uint16_t status;
 	uint8_t RxRead;
 	uint8_t *tmp;
 	
 	RxRead = ior(0xf0);
 	RxRead = (DM9000_PDATA) & 0xff;
 	RxRead = (DM9000_PDATA) & 0xff;
 	if (RxRead != 1)  
  		return 0;				
 	status = ior(0xf2);//获得状态
 	rxlen = DM9000_PDATA;  						//获得长度
 		asm("csync;");
 	if (rxlen > PKTSIZE_ALIGN + PKTALIGN)
  	printf ("packet too big! %d %d\r\n", rxlen, PKTSIZE_ALIGN + PKTALIGN);
 	for ( i =0; i<rxlen/2;i++)
  	addr[i] = DM9000_PDATA;
  		asm("csync;");
 	return rxlen;
}

unsigned char txCmd;
/****************************************************************************
* 名称 ： eth_send
* 功能 ： 向网络发送数据包
* 入口参数 ：packet，length
* 出口参数 ：0
****************************************************************************/
int eth_send (volatile void *packet, int length)
{
	unsigned int i;
 	volatile uint16_t *addr;
 	int tmo;
 	uint8_t TxStatus;
 	int length1 = length>>1;
 	int IoMode;
 	
 	TxStatus = ior(0x01);
 	TxStatus = TxStatus & 0xc;
 	
 	DM9000_PPTR = 0xf8;  // data copy ready set
 	for(i=0;i<2;i++)			//延时匹配时序。		
     	asm("csync;");
     	
 	for (addr = packet; length1 > 0; length1 --)
 	{
  		DM9000_PDATA = *addr++;
  		for(i=0;i<3;i++)			//延时匹配84nS延时时序。		
     		asm("csync;");
 
  	//	delay(1000);
 	}
 	iow(0xfd, (length >> 8) & 0xff);  //set transmit leng
 	iow(0xfc, length & 0xff);
 /* start transmit */
 	iow(0x02, txCmd|0x1);
///	while(!(ior(0x01)&0x40));
 	return 1;
}

/****************************************************************************
* 名称 ： phy_read
* 功能 ： 读取DM9000E物理寄存器
* 入口参数 ：reg
* 出口参数 ：( ior( 0xe) << 8 ) | ior( 0xd)
****************************************************************************/
static uint16_t phy_read(int reg)
{
	/* Fill the phyxcer register into REG_0C */
	iow( 0xc, DM9000_PHY | reg);
	iow( 0xb, 0xc); 	/* Issue phyxcer read command */
	mdelay(100);		/* Wait read complete */
	iow(0xb, 0x0); 	/* Clear phyxcer read command */
	/* The read data keeps on REG_0D & REG_0E */
	return ( ior( 0xe) << 8 ) | ior( 0xd);
}
/****************************************************************************
* 名称 ： phy_write
* 功能 ： 写DM9000E物理寄存器
* 入口参数 ：reg，value
* 出口参数 ：无
****************************************************************************/
static void phy_write( int reg, uint16_t value)
{
	/* Fill the phyxcer register into REG_0C */	
	iow( 0xc, DM9000_PHY | reg);
	/* Fill the written data into REG_0D & REG_0E */
	iow( 0xd, (value & 0xff));
	iow(0xe, ( (value >> 8) & 0xff));
	iow(0xb, 0xa);		/* Issue phyxcer write command */
	mdelay(100);			/* Wait write complete */
	iow(0xb, 0x0);		/* Clear phyxcer write command */
}
/****************************************************************************
* 名称 ： set_PHY_mode
* 功能 ： 设置网卡工作模式 10M:100M
* 入口参数 ：op_mode
* 出口参数 ：无
****************************************************************************/
void set_PHY_mode(char op_mode)
{
	int phy_reg4,phy_reg0;
	switch(op_mode) 
	{
			case DM9000_10MHD: 
				 phy_reg4 = 0x21; 
				 	asm("csync;");
                 phy_reg0 = 0x0000;
                 	asm("csync;");
				 break;
			case DM9000_10MFD:  
				 phy_reg4 = 0x41;
				 	asm("csync;");
				 phy_reg0 = 0x1100;
				 	asm("csync;");
				 break;
			case DM9000_100MHD:
				 phy_reg4 = 0x81;
				 	asm("csync;"); 
				 phy_reg0 = 0x2000;
				 	asm("csync;"); 
				 break;
			case DM9000_100MFD: 
				 phy_reg4 = 0x101;
				 	asm("csync;"); 
				 phy_reg0 = 0x3100;
				 	asm("csync;");
				 break;
	} // end of switch
	phy_write( 0, phy_reg0);
//	delay(100);
	phy_write( 4, 0x0400|phy_reg4);
}
/****************************************************************************
* 名称 ： loopback
* 功能 ： 网卡环路测试,设置网卡工作于何种环路测试模式
* 入口参数 ：mode
* 出口参数 ：无
****************************************************************************/
void loopback(int mode)
{
	switch(mode)
	{
		case LOOP_MAC:
		
			iow(DM9000_NCR, 0x02);
			phy_write( 0, 0x40);

			break;
		case LOOP_PHY100M:
			
			iow(DM9000_NCR, 0x04);
			phy_write( 0, 0x40);
			break;			
			
	}		
}

uint16_t pack[128];
uint16_t packLen=0;

//#define PHY_LOOPBACK_TEST 1



/*void main()
{
	int i;
	ETH_DATA SendData;

	InitPacketHead(&SendData);
//	Set_PLL( (short)(CORECLK/CLKIN), (short)(CORECLK/SYSCLK));		
	Init_EBIU();
	set_PHY_mode(DM9000_100MHD);
	eth_reset();
	#if PHY_LOOPBACK_TEST    
//	loopback(LOOP_MAC);	
//	loopback(LOOP_PHY100M);	    	
    #endif   
    mdelay(100);
	GetDM9000ID();
	//for(i=0;i<128;i++)
	//	pack[i] = i;
    while(1)
    {  

    	//for(i=0;i<1000000;i++)
    	{
    		packLen = 512;
    		//EthPacketSend(&SendData, pack, 128);
    		ArpRequest();
    		mdelay(20);
    		//eth_send(pack,packLen);
    	}
    	
    	//eth_rx(NetRxPackets);     //接收数据包	   	    	  	
    }
}*/





