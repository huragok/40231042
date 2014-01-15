#include "server.h"

#if IS_SERVER
int Connect(ARP_DATA *arpPacket)
{
	int ArpSuccess = 0;
	for (int i=0; i<3; ++i)
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

#endif