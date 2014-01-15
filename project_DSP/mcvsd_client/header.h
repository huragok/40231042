#ifndef __NET_STRUCT_
#define __NET_STRUCT_
// cs8900a packet page.

typedef unsigned long	ulong;
typedef unsigned short	ushort;
typedef unsigned char	uchar;
typedef unsigned int	uint;
#pragma pack 1
#ifndef NULL
#define NULL (void *)0
#endif

typedef struct {
	// Bus Interface Registers
	ulong	pp_id;				// Product identification.
	uchar	pp_res1[28];		// reserved.
	ushort	pp_baddr;			// ip base address.
	ushort	pp_int_num;			// interrupt number.
	ushort	pp_dchan;			// DMA Channel Number.
	ushort	pp_dstart_frame;	// DMA Start of Frame.
	ushort	pp_dframe_cnt;		// DMA Frame Count.
	ushort	pp_rx_dbyte_cnt;	// RxDMA Byte Count.
	ulong	pp_mbase_addr;		// Memory Base Address Register.
	ulong	pp_bprom_base_addr;	// Boot PROM Base Address.
	ulong	pp_bprom_addr_mask;	// Boot PROM Address Mask.
	uchar	pp_res2[8];			// reserved.
	ushort	pp_eeprom_cmd;		// EEPROM Command.
	ushort	pp_eeprom_data;		// EEPROM Data.
	uchar	pp_res3[12];		// reserved.
	ushort	pp_rxf_byte_cnt;	// Received Frame Byte Counter.
	uchar	pp_res4[174];		// reserved.
	// Status and Control Registers.
	uchar	pp_conf_ctrl[32];	// Configuration & Control Registers.
	uchar	pp_state_event[32];	// Status & Event Registers.
	uchar	pp_res5[4];
	// Initiate Transmit Registers.
	ushort	pp_txcmd;			// TxCMD (transmit command).
	ushort	pp_txlen;			// TxLENGTH (transmit length).
	uchar	pp_res6[8];			// reserved.
	// Address Filter Registers.
	uchar	pp_addr_filter[8];	// Logical Address Filter.
	uchar	pp_iaddr[6];		// Individual Address.
	uchar	pp_res7[674];
	// Frame Location.
	ushort	pp_rxstatus;		// RxStatus.
	ushort	pp_rxlen;			// RxLength.
	uchar	pp_rxfloc[1532];	// Rx Frame Location.
	uchar	pp_txfloc[1536];	// Tx Frame Location.
} PACKET_PAGE;					// cs8900a.

// Ethernet Header.
typedef struct {
	uchar		et_dest[6];		// Destination Mac Address.
	uchar		et_src[6];		// Source Mac Address.
	ushort		et_protlen;		// if ethernet header protocol, else length.
	//uchar		et_dsap;		// DSAP.
	//uchar		et_ssap;		// SSAP.
	//uchar		et_ctl;			// contorl.
	//uchar		et_snap1;		// SNAP.
	//uchar		et_snap2;
	//uchar		et_snap3;
	//ushort		et_prot;		// protocol.
} ETH_HEADER;
#define	ETHER_HDR_SIZE			14
#define	E802_HDR_SIZE			22
#define PROT_IP					0x0800
#define	PROT_ARP				0x0806
#define PROT_RARP				0x8035


// IP Header.
typedef struct {
	char	ip_hl_v;	// version and header length
	char	ip_tos;		// type of service.
	short	ip_len;		// total length 
	short	ip_id;		// identification.
	short	ip_off;		// fragment offset field.
	char	ip_ttl;		// time to live 
	char	ip_p;		// protocol (UDP:17).
	short	ip_chksum;	// checksum.
	long	ip_src;		// source ip address.
	long	ip_dest;	// destination ip address.
} IP_HEADER;
#define IP_HDR_SIZE		20

// UDP Header
typedef struct {
    short udp_srcport;	// source port.
    short udp_destport;	// destination port.
    short udp_len;		// UDP length.
    short udp_chksum;	// checksum.
} UDP_HEADER;
#define UDP_HDR_SIZE	8

// UDP Pseudo-header
typedef struct {
    long udp_srcip;
    long udp_destip;
    char udp_mbz;
    char udp_p;
    short udp_len;
} UDP_PSD;

//ICMP Header
typedef struct{
	char icmp_op;//0 or 8
	char icmp_code;//0
	short icmp_chksum;// checksum
	short icmp_id;//identification
	short icmp_no;
} ICMP_HEADER;
#define ICMP_HEADER_SIZE 8


// Address Resolution Protocol (ARP) header.
typedef struct {
	ushort		ar_hrd;		// Format of hardware address.
	ushort		ar_pro;		// Format of protocol address.
	uchar		ar_hln;		// Length of hardware address.
	uchar		ar_pln;		// Length of protocol address.
	ushort		ar_op;		// Operation.
	uchar		ar_sha[6];         /* sender hardware address */
	ulong		ar_spa;            /* sender protocol address */
	uchar		ar_tha[6];         /* target hardware address */
	ulong		ar_tpa;            /* target protocol address */
} ARP_HEADER;
#define ARP_HDR_SIZE			(8+20)	// Size assuming ethernet.
// for ar_hrd of ARP_HEADER.
#define ARP_ETHER				1		// Ethernet hardware address.
// for ar_op of ARP_HEADER.
#define ARPOP_REQUEST			1		// Request to resolve address.
#define ARPOP_REPLY				2		// Response to previous request.
#define RARPOP_REQUEST			3		// Request to resolve address.
#define RARPOP_REPLY			4		// Response to previous request.



#endif

