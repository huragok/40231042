.section program;
.global    __decode_mcvsd;
.align 8;
__decode_mcvsd:
			
			LINK    60; //还需要更多更多的本地变量空间
			[--SP]=(R7:4,P5:3); //保存一些寄存器的值
			[FP+8]=R0; //IN
			[FP+12]=R1; //OUT_MCVSD
			[FP+16]=R2; //nsample=1024
			
			//把LPF_MCVSD1的延迟线读、写，系数读写循环指针存为本地变量
			P0=[FP+36];//后面插3个泡
			
			P1=[P0++];//滤波器系数
			P2=[P0++];//延迟线
			R3=[P0];//延迟线长度
			
			[FP-4]=P2;//I01
			R3=R3+R3;//后面插3个泡
			[FP-8]=P2;//B01
			[FP-12]=P1;//I2
			[FP-16]=P1;//B2
			[FP-20]=R3;//L012
			
			//把LPF_MCVSD2的延迟线读、写，系数读写循环指针存为本地变量
			P0=[FP+40];	//后面插3个泡		
			P1=[P0++];//滤波器系数
			P2=[P0++];//延迟线
			R3=[P0];//延迟线长度
			
			[FP-24]=P2;//I01
			R3=R3+R3;//后面插3个泡
			[FP-28]=P2;//B01
			[FP-32]=P1;//I2
			[FP-36]=P1;//B2
			[FP-40]=R3;//L012
			
			//把LPF_CVSD的延迟线读、写，系数读写循环指针存为本地变量
			P0=[FP+56];	//后面插3个泡		
			P1=[P0++];//滤波器系数
			P2=[P0++];//延迟线
			R3=[P0];//延迟线长度
			
			[FP-44]=P2;//I0
			R3=R3+R3;//后面插3个泡
			[FP-48]=P2;//B0
			[FP-52]=P1;//I2
			[FP-56]=P1;//B2
			[FP-60]=R3;//L012
			
			P0=R0;// Address of the input array
			P1=R2;// outer loop counter
			
			R2=R2+R2;

			I3=R1;// Initialize I3 to the start of the output buffer
			B3=R1;// Output buffer initialized as circular buffer
			L3=R2;//输出序列长度(Byte数)
			
			R6=[FP+24];
			R7=[FP+32];
			R0=[FP+20];
			R1=[FP+28];
			R0<<=16;
			R1<<=16;
			R6=R6+R0;//R6.H=delta0, R6.L=delta_min
			R7=R7+R1;//R7.H=alpha, R7.L=beta
			R4.H=1;//R4.L=Sp, R4.H=count(16);
			
			
			LSETUP(E_CODE_START,E_CODE_END) LC0=P1; //开始进行编码
			P1=[FP+52];
			R5=[P1];//读入上一轮的编码结果
			R5.L=W[P0];//在R5的低16位中读入16个编码结果，最早的编码结果在最高位
			P0+=2;
E_CODE_START:

			P3=[FP+44];//读出sr
			R1.L=W[P3];
			R4.L=R1.L*R7.H;//更新sp
			
			//MCVSD 中第一个滤波器的滤波过程
			P3=[FP-4];
			P4=[FP-12];
			I0=P3;//初始化环形缓存器
			I1=P3;
			I2=P4;
			P3=[FP-8];
			P4=[FP-16];
			P2=[FP-20];
			B0=P3;//初始化环形缓存器
			B1=P3;
			B2=P4;			
			L0=P2;
			L1=P2;
			L2=P2;
			
			W[I0++]=R4.L;//向延迟线里写一个数
			A0=0 ;//累加寄存器初始化
			R3.L=0; //buffer_FWR_tx
			LSETUP(E_MAC1_ST,E_MAC1_END)LC1=P2>>1;
			I1+=2;
			
E_MAC1_ST:	R0.H=W[I2++] || R0.L=W[I1--];
E_MAC1_END:	A0+=R0.H*R0.L;		
			
			A0=ABS A0;
			R3.L=A0;//滤波-绝对值输出
						
			P3=I0;//回写环形缓存器指针
			P4=I2;
			[FP-4]=P3;
			[FP-12]=P4;
			
			//MCVSD 中第二个滤波器的滤波过程
			P3=[FP-24];
			P4=[FP-32];
			I0=P3;//初始化环形缓存器
			I1=P3;
			I2=P4;
			P3=[FP-28];
			P4=[FP-36];
			P2=[FP-40];
			B0=P3;//初始化环形缓存器
			B1=P3;
			B2=P4;			
			L0=P2;
			L1=P2;
			L2=P2;
			
			W[I0++]=R3.L;//向延迟线里写一个数
			A1=0 ;//累加寄存器初始化
			R3.H=0; //buffer_FWR_tx
			LSETUP(E_MAC2_ST,E_MAC2_END)LC1=P2>>1;
			I1+=2;
			
E_MAC2_ST:	R0.H=W[I2++] || R0.L=W[I1--];
E_MAC2_END:	A1+=R0.H*R0.L;

			R3.H=A1;//p
	
			P3=I0;//回写环形缓存器指针
			P4=I2;
			[FP-24]=P3;
			[FP-32]=P4;
			
			//更新斜率
			R0.H=3;
			R0.L=32768;
			
			R1=R5 & R0;
			R1=R1-R0(ns);
			CC=AZ;
			
			IF !CC JUMP NOT_ALL_1;
			R2=R6.H*R3.H;//delta_mod,前3个都是1	
			R2=R2<<5;//补回来
			JUMP SLOPE_MODIFIED;
			
NOT_ALL_1:	R2=0xFFFFFFFF;
			R1=R2 ^ R5;
			R1=R1 & R0;
			R1=R1-R0(ns);
			CC=AZ;
			
			IF !CC JUMP NO_MOD;
			R2=R6.H*R3.H;//delta_mod，前3个都是0
			R2=R2<<5;//补回来
			JUMP SLOPE_MODIFIED;

NO_MOD:		R2.H=0;//前3个bit不相等，不用修改量阶

SLOPE_MODIFIED:
	
			P3=[FP+48];
			R1.L=W[P3];//读出原来的delta
			
			R2.L=R2.H+R6.L(s);
			R1.H=R7.L*R1.L;
			R2.H=R2.L+R1.H(s);//delta
			W[P3]=R2.H;//更新delta
			
			P3=[FP+44];
			CC=BITTST(R5,15);
			
			IF !CC JUMP D_ZERO;
			R3.H=R4.L+R2.H(s);
			JUMP SR_DONE;

D_ZERO:		R3.H=R4.L-R2.H(s);
			
SR_DONE:	W[P3]=R3.H;//更新Sr
			
			//MCVSD 中输出低通滤波器的滤波过程
			P3=[FP-44];
			P4=[FP-52];
			I0=P3;//初始化环形缓存器
			I1=P3;
			I2=P4;
			P3=[FP-48];
			P4=[FP-56];
			P2=[FP-60];
			B0=P3;//初始化环形缓存器
			B1=P3;
			B2=P4;			
			L0=P2;
			L1=P2;
			L2=P2;
			
			W[I0++]=R3.H;//向延迟线里写一个数
			A0=0 ;//累加寄存器初始化
			R3.L=0; //输出
			LSETUP(E_MAC3_ST,E_MAC3_END)LC1=P2>>1;
			I1+=2;
			
E_MAC3_ST:	R0.H=W[I2++] || R0.L=W[I1--];
E_MAC3_END:	A0+=R0.H*R0.L;

			R3.L=A0;//输出
			W[I3++]=R3.L;
	
			P3=I0;//回写环形缓存器指针
			P4=I2;
			[FP-44]=P3;
			[FP-52]=P4;

			R5<<=1;//编码结果移位寄存器左移一位
			
			//每当R5中写满16位后读入一个输入
			R0.L=16;
			R0.H=1;
			R1.L=R4.H-R0.L(ns);
			CC=AZ;
			
			IF !CC JUMP NO_WR;
			R4.H=0;
			R5.L=W[P0];
			P0+=2;
NO_WR:
E_CODE_END:	R4.H=R4.H+R0.H(ns);

			[P1]=R5;//把最后的d移位缓存器存出来
						
			(R7:4,P5:3)=[SP++]; 
			UNLINK; 
			RTS;				

__decode_mcvsd.end:	