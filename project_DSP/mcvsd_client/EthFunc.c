#include "EthFunc.h"
static short recvPacketId = 0;
uchar LOCAL_MAC[6] = {0x01, 0x02, 0x03, 0x04, 0x05, 0x07};
uchar REMOTE_MAC[6] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff};

short checksum(ushort *buffer,int size)
{
	unsigned long cksum=0;
	while(size>1)
	{
 		cksum+=*buffer++;
		size-=sizeof(short);
 	}
 	if(size)
 	{
  		cksum+=*(char* )buffer;
	 }
 	//将32位数转换成16
 	while (cksum>>16)
		cksum=(cksum>>16)+(cksum & 0xffff);
 	return (short) (~cksum);
}

void PacketCheckSum(unsigned char packet[])
{
	ETH_HEADER *pdlc_header=0; //以太头指针
	IP_HEADER *pip_header=0;  //IP头指针
	unsigned short attachsize=0; //传输层协议头以及附加数据的总长度
	pdlc_header=(ETH_HEADER *)packet;
	//判断ethertype,如果不是IP包则不予处理
	if(SWAP16(pdlc_header->et_protlen)!=PROT_IP) return;
	pip_header=(IP_HEADER  *)(packet+14);
	//UDP包
	if(0x11==pip_header->ip_p)
	{
		UDP_HEADER *pudp_header=0; //UDP头指针
		UDP_PSD *pudp_psd_header=0;
		pudp_header=(UDP_HEADER *)(packet+14+((pip_header->ip_hl_v)&15)*4);
		attachsize=SWAP16(pip_header->ip_len)-((pip_header->ip_hl_v)&15)*4;
		pudp_psd_header=(UDP_PSD *)malloc(attachsize+sizeof(UDP_PSD));
		if(!pudp_psd_header) return;
        memset(pudp_psd_header,0,attachsize+sizeof(UDP_PSD));
		//填充伪UDP头
		pudp_psd_header->udp_destip=pip_header->ip_dest;
		pudp_psd_header->udp_srcip=pip_header->ip_src;
		pudp_psd_header->udp_mbz=0;
		pudp_psd_header->udp_p=0x11;
		pudp_psd_header->udp_len=SWAP16(attachsize);
  
		//计算UDP校验和
		pudp_header->udp_chksum=0;
		memcpy((unsigned char *)pudp_psd_header+sizeof(UDP_PSD),
			(unsigned char *)pudp_header,attachsize);
 		pudp_header->udp_chksum=checksum((unsigned short *)pudp_psd_header,
			attachsize+sizeof(UDP_PSD));
    
		//计算ip头的校验和
		pip_header->ip_chksum=0;
		pip_header->ip_chksum=checksum((unsigned short *)pip_header,20);  

  		return;
	}
	return;
}
#if IS_SERVER
void NewUDPHeader(UDP_HEADER* udpHeader, short srcPort, short destPort, short udpLen)
{
    udpHeader->udp_srcport = SWAP16(srcPort);
    udpHeader->udp_destport = SWAP16(destPort);
    udpHeader->udp_len = SWAP16(udpLen);
    udpHeader->udp_chksum = 0;
}

void NewIPHeader(IP_HEADER* ipHeader, char hdrlen, short length, char prot, long src, long dest)
{
    ipHeader->ip_hl_v = 0x40+hdrlen;
    ipHeader->ip_tos = 0;
    ipHeader->ip_len = SWAP16(length);
    ipHeader->ip_id = 0;
    ipHeader->ip_off = SWAP16(0x4000);
    ipHeader->ip_ttl = 0xff;
    ipHeader->ip_p = 0x11;
    ipHeader->ip_chksum = 0;
    ipHeader->ip_src = SWAP32(src);
    ipHeader->ip_dest = SWAP32(dest);
}
#endif

void NewEthHeader(ETH_HEADER* ethHeader, uchar* srcMac, uchar* destMac, short prot)
{
	memcpy((char*)(ethHeader->et_dest), destMac, 6);
    memcpy((char*)(ethHeader->et_src), srcMac, 6);
    ethHeader->et_protlen = SWAP16(prot);
}
#if IS_SERVER
void InitPacketHead(ETH_DATA* SendData)
{
	NewUDPHeader(&(SendData->udpHeader), SRC_PORT, DEST_PORT, UDP_HDR_SIZE + DATA_SIZE);
    NewIPHeader(&(SendData->ipHeader), (char)(IP_HDR_SIZE/4), IP_HDR_SIZE + UDP_HDR_SIZE + DATA_SIZE*2, 0x11, LOCAL_IP, REMOTE_IP);
    NewEthHeader(&(SendData->ethHeader), LOCAL_MAC, REMOTE_MAC, PROT_IP);
}

int EthPacketSend(ETH_DATA* SendData, uint16_t* TxBuffer, short BufferSize)
{
    int sendStatus = 0;

	memcpy((char*)SendData->voiceData, (char*)TxBuffer, BufferSize*2);
	SendData->ipHeader.ip_id = SWAP16(SWAP16(SendData->ipHeader.ip_id) + 1);
    //PacketCheckSum((unsigned char*)SendData);
	sendStatus = eth_send((void*)SendData, ETH_PACK_SIZE);
	return sendStatus;
}

void ArpRequest()
{
	ARP_DATA arpPacket;
	NewEthHeader(&(arpPacket.ethHeader), LOCAL_MAC, REMOTE_MAC, PROT_ARP);
	arpPacket.arpHeader.ar_hrd = SWAP16(ARP_ETHER);
	arpPacket.arpHeader.ar_pro = SWAP16(PROT_IP);
	arpPacket.arpHeader.ar_hln = 6;
	arpPacket.arpHeader.ar_pln = 4;
	arpPacket.arpHeader.ar_op = SWAP16(ARPOP_REQUEST);
	memcpy(arpPacket.arpHeader.ar_sha, LOCAL_MAC, 6);
	arpPacket.arpHeader.ar_spa = SWAP32(LOCAL_IP);
	memcpy(arpPacket.arpHeader.ar_tha, REMOTE_MAC, 6);
	arpPacket.arpHeader.ar_tpa = SWAP32(REMOTE_IP);
	memset(arpPacket.fillData, 0, 18);
	eth_send((void*)&arpPacket, ARP_PACK_SIZE);
}

int Connect(ARP_DATA *arpPacket)
{
	int ArpSuccess = 0;
	int i;
	for (i=0; i<3; ++i)
	{
		ArpRequest();
		mdelay(2000);
		eth_rx((uint16_t*)&arpPacket);
		if (arpPacket->ethHeader.et_protlen == SWAP16(PROT_ARP)
			&&arpPacket->arpHeader.ar_hrd == SWAP16(ARP_ETHER)
			&& arpPacket->arpHeader.ar_pro == SWAP16(PROT_IP)
			&& arpPacket->arpHeader.ar_hln == 6 && arpPacket->arpHeader.ar_pln == 4
			&& arpPacket->arpHeader.ar_op == SWAP16(ARPOP_REQUEST)
			&& arpPacket->arpHeader.ar_spa == SWAP32(REMOTE_IP)
			&& arpPacket->arpHeader.ar_tpa == SWAP32(LOCAL_IP))
		{
			ArpDeal(arpPacket);
			ArpSuccess = 1;
			return ArpSuccess;
		}
	}
	return ArpSuccess;
}

#endif

#if IS_CLIENT

int EthPacketRecv(ETH_DATA* RecvData, uint16_t* RxBuffer, short BufferSize)
{
	int recvStatus = 0;
	int l = 0;
	while(l==0)
	{
		l = eth_rx((uint16_t*)RecvData);
	    mdelay(1);
	}
	//printf("Recieved\n");
	//short ipChkSum = RecvData->ipHeader.ip_chksum;
	//short udpChkSum = RecvData->udpHeader.udp_chksum;
	//PacketCheckSum((unsigned char*)RecvData);
	//if (ipChkSum != RecvData->ipHeader.ip_chksum || udpChkSum != RecvData->udpHeader.udp_chksum)
	//{
	//	return recvStatus;
	//}
	//if (recvPacketId+1 == SWAP16(RecvData->ipHeader.ip_id) && memcmp(RecvData->ethHeader.et_dest, LOCAL_MAC, 6) == 0 && SWAP32(RecvData->ipHeader.ip_dest) == LOCAL_IP && SWAP16(RecvData->udpHeader.udp_destport) == DEST_PORT)
	{
		//memcpy((char*)RxBuffer, (char*)RecvData->voiceData, BufferSize*2);
		//++recvPacketId;
		recvStatus = 1;
	}
	printf("%d\t", RecvData->ipHeader.ip_ttl);
	//printf("Dealing\n");
	//mdelay(10);
	return recvStatus;
}

void ArpReply(ARP_DATA* arpPacket)
{	
	ARP_DATA arpPacketRep;
	memcpy(REMOTE_MAC, arpPacket->arpHeader.ar_sha, 6);

	NewEthHeader(&(arpPacketRep.ethHeader), LOCAL_MAC, REMOTE_MAC, PROT_ARP);
	arpPacketRep.arpHeader.ar_hrd = SWAP16(ARP_ETHER);
	arpPacketRep.arpHeader.ar_pro = SWAP16(PROT_IP);
	arpPacketRep.arpHeader.ar_hln = 6;
	arpPacketRep.arpHeader.ar_pln = 4;
	arpPacketRep.arpHeader.ar_op = SWAP16(ARPOP_REPLY);
	memcpy(arpPacketRep.arpHeader.ar_sha, LOCAL_MAC, 6);
	arpPacketRep.arpHeader.ar_spa = SWAP32(LOCAL_IP);
	memcpy(arpPacketRep.arpHeader.ar_tha, REMOTE_MAC, 6);
	arpPacketRep.arpHeader.ar_tpa = SWAP32(REMOTE_IP);
	
	eth_send((void*)&arpPacketRep, ARP_PACK_SIZE);
}

void GetConnect(ARP_DATA *arpPacket)
{
	int ArpSuccess = 0;
	while (!ArpSuccess)
	{
		eth_rx((uint16_t*)&arpPacket);
		if (arpPacket->ethHeader.et_protlen == SWAP16(PROT_ARP)
			&&arpPacket->arpHeader.ar_hrd == SWAP16(ARP_ETHER)
			&& arpPacket->arpHeader.ar_pro == SWAP16(PROT_IP)
			&& arpPacket->arpHeader.ar_hln == 6 && arpPacket->arpHeader.ar_pln == 4
			&& arpPacket->arpHeader.ar_op == SWAP16(ARPOP_REQUEST)
			&& arpPacket->arpHeader.ar_spa == SWAP32(REMOTE_IP)
			&& arpPacket->arpHeader.ar_tpa == SWAP32(LOCAL_IP))
		{
			printf("ARP Recived.\n");
		    ArpDeal(arpPacket);
			ArpReply(arpPacket);
			ArpSuccess = 1;
			printf("ARP Succeed.\n");
		}
		mdelay(20);
	}
}

/*void client(char* RxBuffer)
{
	ARP_DATA arpPacket;
	ETH_DATA RecvData;

	mdelay(2000);
	GetConnect(&arpPacket);
	while(1)
	{
		while(EthPacketRecv(&RecvData, RxBuffer, ETH_PACK_SIZE))
		{
			// Decode
		    mdelay(10);
		}
	}
}
*/
#endif

void ArpDeal(ARP_DATA* arpPacket)
{
	memcpy(REMOTE_MAC, arpPacket->arpHeader.ar_sha, 6);
}

