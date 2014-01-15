/*******************************************************************************************
File Name      : code_mcvsd.asm
Module Name    : MCVSD coder
Function Name  : __code_mcvsd

Description    : This function performs MCVSD coding on given voice input (16 bit, stereo, 48kHz).
Operands	   : R0- Address of input vector, R1-Address of output vector,
               : R2- Number of input elements	
			   : LPF structures for MCVSD decoding are on stack.             

Prototype:
		void code_mcvsd(const fract16 x[],fract32 y[],int n, const fract16 delta0, const fract16 delta_min, const fract16 alpha, const fract16 beta, fir_state_fr16 *s1, fir_state_fr16 *s2, const fract16 *sr, const fract16 *delta, const fract32 *d);
    
        x[]  -  input array 
		y[]  -  output array
		n    -  number of input samples()
		delta0	-	step of the change of the slope
		delta_min	-	minimum slope
		alpha	-	predictor codfficient
		beta	-	syllabic filter coefficient
        s1    -  LPF fed with decoded signal. 
			Structure of type fir_state_fr16:
	     	{
		    	fract16 *h, // filter coefficients 
			    fract16 *d, // start of delay line 
			    int k,	   	// no. of coefficients 
		    } fir_state_fr16;
		s2	-  another 2-pole LPF to output the instantaneous envelop of the decoded signal
		sr	-	重建语音的历史（相当于一位延迟线）
		delta	-	实际量阶（相当于一位延迟线）
		d	-	前32bit编码结果
Registers used   :   

	R0, R1, R2, R3, R4, R5, R6, R7

	I0 -> Address of delay line (used for updating the delay line)
   	I1 -> Address of delay line (used for fetching the delay line data)
	I2 -> Address of filter coeff. h0, h1 , ... , hn-1

	P0 -> Address of input array x[]
	P4 -> Address of output array y[]
	P5 -> input/output step
	P1 -> outer loop counter
	P2 -> inner loop counter

	不写汇编会死尼玛有木有？！一个寄存器掰成两半花有木有？！FP上开到+44下开到-56有木有？！差不多5个滤波器写到一块有木有？！
********************************************************************************************/
/*   Input buffer(in) , Output buffer(out), Delay line Buffer(delay) and filter coefficient
     buffer(h) are all aligned to 4 byte(word) boundary. 
*/

.section program;
.global    __code_mcvsd;
.align 8;
__code_mcvsd:
			
			LINK    56; //还需要更多更多的本地变量空间
			[--SP]=(R7:4,P5:3); //保存一些寄存器的值
			[FP+8]=R0; //IN
			[FP+12]=R1; //OUT_MCVSD
			[FP+16]=R2; //nsample=1024
			
			//把LPF_MCVSD1的延迟线读、写，系数读写循环指针存为本地变量
			P0=[FP+36];//后面插3个泡
			
			P1=[P0++];//滤波器系数
			P2=[P0++];//延迟线
			R3=[P0];//延迟线长度
			
			[FP-4]=P2;//I0
			R3=R3+R3;//后面插3个泡
			[FP-8]=P2;//B0
			[FP-12]=P2;//I1
			[FP-16]=P2;//B1
			[FP-20]=P1;//I2
			[FP-24]=P1;//B2
			[FP-28]=R3;//L0,1,2
			
			//把LPF_MCVSD2的延迟线读、写，系数读写循环指针存为本地变量
			P0=[FP+40];	//后面插3个泡		
			P1=[P0++];//滤波器系数
			P2=[P0++];//延迟线
			R3=[P0];//延迟线长度
			
			[FP-32]=P2;//I0
			R3=R3+R3;//后面插3个泡
			[FP-36]=P2;//B0
			[FP-40]=P2;//I1
			[FP-44]=P2;//B1
			[FP-48]=P1;//I2
			[FP-52]=P1;//B2
			[FP-56]=R3;//L0,1,2
			
			P0=R0;// Address of the input array
			P1=R2;// outer loop counter
			
			//P3=[FP+44];//sr这个嘛，指针地址寄存器好像不太够用，你俩忍忍吧
			//P4=[FP+48];//delta
			
			R2>>=3;

			I3=R1;// Initialize I3 to the start of the output buffer
			B3=R1;// Output buffer initialized as circular buffer
			L3=R2;//输出序列长度(Byte数)
			I3-=2;//Adjust the output pointer to the last location (520-4)
			
			R6=[FP+24];
			R7=[FP+32];
			R0=[FP+20];
			R1=[FP+28];
			R0<<=16;
			R1<<=16;
			R6=R6+R0;//R6.H=delta0, R6.L=delta_min
			R7=R7+R1;//R7.H=alpha, R7.L=beta
			R4.H=1;//R4.L=Sp, R4.H=count(32);
			
			
			LSETUP(E_CODE_START,E_CODE_END) LC0=P1; //开始进行编码
			P1=[FP+52];
			R5=[P1];//存入上一个d移位缓存器
E_CODE_START:

			P3=[FP+44];
			R1.L=W[P3];
			R4.L=R1.L*R7.H;//更新sp
			
			R5<<=1;//准备写一个d,默认为0
			R1.L=W[P0];//读一个数
			R1.H=R1.L-R4.L(s); //用R4.L保存sp
			CC=AN;
			
			IF CC JUMP D_DONE;
			BITSET(R5,0);

D_DONE:		//MCVSD 中第一个滤波器的滤波过程
			P3=[FP-4];
			P4=[FP-12];
			P5=[FP-20];
			I0=P3;//初始化环形缓存器
			I1=P4;
			I2=P5;
			P3=[FP-8];
			P4=[FP-16];
			P5=[FP-24];
			P2=[FP-28];
			B0=P3;//初始化环形缓存器
			B1=P4;
			B2=P5;			
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
			P4=I1;
			P5=I2;
			[FP-4]=P3;
			[FP-12]=P4;
			[FP-20]=P5;
			
			//MCVSD 中第二个滤波器的滤波过程
			P3=[FP-32];
			P4=[FP-40];
			P5=[FP-48];
			I0=P3;//初始化环形缓存器
			I1=P4;
			I2=P5;
			P3=[FP-36];
			P4=[FP-44];
			P5=[FP-52];
			P2=[FP-56];
			B0=P3;//初始化环形缓存器
			B1=P4;
			B2=P5;			
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
			P4=I1;
			P5=I2;
			[FP-32]=P3;
			[FP-40]=P4;
			[FP-48]=P5;
			
			//更新斜率
			R0=7;
			
			R1=R5 & R0;
			R1.H=R1.L-R0.L(ns);
			CC=AZ;
			
			IF !CC JUMP NOT_ALL_1;
			R2.L=R6.H*R3.H;//delta_mod,前3个都是1	
			JUMP SLOPE_MODIFIED;
			
NOT_ALL_1:	R2=0xFFFFFFFF;
			R1=R2 ^ R5;
			R1=R1 & R0;
			R1.H=R1.L-R0.L(ns);
			CC=AZ;
			
			IF !CC JUMP NO_MOD;
			R2.L=R6.H*R3.H;//delta_mod，前3个都是0
			JUMP SLOPE_MODIFIED;

NO_MOD:		R2.L=0;//前3个bit不相等，不用修改量阶

SLOPE_MODIFIED:
	
			P3=[FP+48];
			R1.L=W[P3];//读出原来的delta
			
			R2.H=R2.L+R6.L(s);
			R1.H=R7.L*R1.L;
			R2.L=R2.H+R1.H(s);//delta
			
			P3=[FP+44];
			CC=BITTST(R5,0);
			
			IF !CC JUMP D_ZERO;
			R3.H=R4.L+R2.L(s);
			JUMP SR_DONE;

D_ZERO:		R3.H=R4.L-R2.L(s);		

SR_DONE:	W[P3]=R3.H;//更新Sr

			//每当R5中写满32位后保存一次
			R0.L=16;
			R0.H=1;
			R1.L=R4.H-R0.L(ns);
			CC=AZ;
			
			IF !CC JUMP NO_WR;
			W[I3++]=R5.L;
			R4.H=0;
NO_WR:		R4.H=R4.H+R0.H(ns);
E_CODE_END:	P0+=2;

			[P1]=R5;//把最后的d移位缓存器存出来
			
			
			(R7:4,P5:3)=[SP++]; 
			UNLINK; 
			RTS;				

__code_mcvsd.end:	