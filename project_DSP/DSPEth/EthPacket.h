#include "header.h"
#pragma pack 1
#define SRC_PORT 84
#define DEST_PORT 85
#define LOCAL_IP 0xc0a80002
#define REMOTE_IP 0xc0a80003
#define DATA_SIZE 128
#define ETH_PACK_SIZE ETHER_HDR_SIZE + IP_HDR_SIZE + UDP_HDR_SIZE + 2*DATA_SIZE
#define ARP_PACK_SIZE 60
typedef struct {
    ETH_HEADER ethHeader;
	IP_HEADER ipHeader;
	UDP_HEADER udpHeader;
	short voiceData[DATA_SIZE];
} ETH_DATA;

typedef struct {
	ETH_HEADER ethHeader;
	ARP_HEADER arpHeader;
	char fillData[18];
} ARP_DATA;
