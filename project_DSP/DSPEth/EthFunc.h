#include "header.h"
#include "dm9000.h"
#include "EthPacket.h"
#include <stdlib.h>
#include <string.h>

#include "bf5xx.h"
#define IS_SERVER 1
#define IS_CLIENT 0

#ifndef SWAP8
#define SWAP8(A)		(A)
#define SWAP16(A)		((((A)&0x00ff)<<8) | ((A)>>8))
#define SWAP32(A)		((((A)&0x000000ff)<<24) | (((A)&0x0000ff00)<<8) | (((A)&0x00ff0000)>>8) | (((A)&0xff000000)>>24))
#endif

short checksum(ushort *buffer,int size);
void PacketCheckSum(unsigned char packet[]);
void ArpDeal(ARP_DATA* arpPacket);

#if IS_SERVER
void NewUDPHeader(UDP_HEADER* udpHeader, short srcPort, short destPort, short udpLen);
void NewIPHeader(IP_HEADER* ipHeader, char hdrlen, short length, char prot, long src, long dest);
void NewEthHeader(ETH_HEADER* ethHeader, uchar* srcMac, uchar* destMac, short prot);
void InitPacketHead(ETH_DATA* SendData);
int EthPacketSend(ETH_DATA* SendData, uint16_t* TxBuffer, short BufferSize);
void ArpRequest();
int Connect(ARP_DATA *arpPacket);
#endif

#if IS_CLIENT
int EthPacketRecv(ETH_DATA* RecvData, uint16_t* RxBuffer, short BufferSize);
void ArpReply(ARP_DATA* arpPacket);
void GetConnect(ARP_DATA *arpPacket);
void client(char* RxBuffer);
#endif
