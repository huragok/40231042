/*******************************************************************************************
File Name      : code_mcvsd.asm
Module Name    : MCVSD coder
Function Name  : __code_mcvsd

Description    : This function performs MCVSD coding on given voice input (16 bit, stereo, 48kHz).
Operands	   : R0- Address of input vector, R1-Address of output vector,
               : R2- Number of input elements	
			   : Other input arguments for MCVSD coding are on stack.             

Prototype:
		void code_mcvsd(const fract16 x[],fract16 y[],int n, const fract16 delta0, const fract16 delta_min, const fract16 alpha, const fract16 beta, fir_state_fr16 *s1, fir_state_fr16 *s2, const fract16 *sr, const fract16 *delta, const fract32 *d, const int step);
    
        x[]  -  input array, sampled at 48kHz, quantized with 16bit, stereo
		y[]  -  output array, each word contains coding outputs for 16 input samples
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
		s2	-  another 3-order LPF to output the instantaneous envelop of the decoded signal
		sr	-	delay line for syllabic filter
		delta	-	delay line for slope filter
		d	-	the current and previous 31 coding result
		step	-	input step
Registers used:   

	R0, R1, R2, R3, R4, R5, R6, R7

	R4.H -> outer loop counter, flag to write every 16 input samples, R4.L -> sp 
	R5 -> d
	R6.H -> delta0, R6.L -> delta_min
	R7.H -> alpha, R7.L -> beta
	R0,R1,R2,R3 -> temp value
	
	I0 -> Address of delay line (used for updating the delay line)
   	I1 -> Address of delay line (used for fetching the delay line data)
	I2 -> Address of filter coeff. h0, h1 , ... , hn-1
	I3 -> Address of output array y[]
	
	P0 -> Address of input array x[]
	P5 -> input step
	P1 -> outer loop counter
	P2 -> inner loop counter
	P3 -> random access pointer
	P4 -> random access pointer

Codename: Forward Unto Dawn
********************************************************************************************/

.section program;
.global    __code_mcvsd;
.align 8;
__code_mcvsd:
			
			LINK    40;
			[--SP]=(R7:4,P5:3);
			
			P5=[FP+56];
			P0=[FP+36];
			
			[FP+8]=R0; //IN
			[FP+12]=R1; //OUT_MCVSD
			[FP+16]=R2; //nsample=1024
			
			P5 =P5+P5;
			//��LPF_MCVSD2���ӳ��߶���д��ϵ����дѭ��ָ���Ϊ���ر���				
			P1=[P0++];//�˲���ϵ��
			P2=[P0++];//�ӳ���
			R3=[P0];//�ӳ��߳���			
			P0=[FP+40];
			
			[FP-4]=P2;//I01
			R3=R3+R3;
			[FP-8]=P2;//B01
			[FP-12]=P1;//I2
			[FP-16]=P1;//B2
			[FP-20]=R3;//L012
			
			//��LPF_MCVSD2���ӳ��߶���д��ϵ����дѭ��ָ���Ϊ���ر���
					
			P1=[P0++];//�˲���ϵ��
			P2=[P0++];//�ӳ���
			R3=[P0];//�ӳ��߳���
			P3=[FP+52];
			
			[FP-24]=P2;//I01
			R3=R3+R3;
			[FP-28]=P2;//B01
			[FP-32]=P1;//I2
			[FP-36]=P1;//B2
			[FP-40]=R3;//L012
						
			R5=[P3];//������һ�ֵı�����
			
			P0=R0;// Address of the input array
			P1=R2;// outer loop counter
			
			R2>>=3;

			I3=R1;// Initialize I3 to the start of the output buffer
			B3=R1;// Output buffer initialized as circular buffer
			L3=R2;//
			
			R6=[FP+24];
			R7=[FP+32];
			R0=[FP+20];
			R1=[FP+28];
			R0<<=16;
			R1<<=16;
			
			P3=[FP+44];//����sr
			
			R6=R6+R0;//R6.H=delta0, R6.L=delta_min
			R7=R7+R1;//R7.H=alpha, R7.L=beta
			R4.H=1;//R4.L=Sp, R4.H=count(32);
					
			LSETUP(E_CODE_START,E_CODE_END) LC0=P1;//��ʼ���б���
			R1.H=W[P3];
			
E_CODE_START:

			R1.L=W[P0++P5];//����һ��word
			R5<<=1;//
			
			R4.L=R1.H*R7.H;//����sp
			R1.H=R1.L-R4.L(s); //��ֱ���
			CC=AN;
			
			IF CC JUMP D_DONE;
			BITSET(R5,0);

D_DONE:			//MCVSD �е�һ���˲������˲�����
			P3=[FP-8];
			P4=[FP-16];
			P2=[FP-20];
			B0=P3;
			B1=P3;
			B2=P4;
			P3=[FP-4];
			P4=[FP-12];			
			L0=P2;
			L1=P2;
			L2=P2;
			I0=P3;
			I1=P3;
			I2=P4;
			
			W[I0++]=R4.L;//���ӳ�����дһ����
			A0=0 ;//�ۼӼĴ�����ʼ��
			R3.L=0; //buffer_FWR_tx
			LSETUP(E_MAC1_ST,E_MAC1_END)LC1=P2>>1;
			I1+=2;
			
E_MAC1_ST:	R0.H=W[I2++] || R0.L=W[I1--];
E_MAC1_END:	A0+=R0.H*R0.L;		
			
			A0=ABS A0;
			R3.L=A0;//�˲�-����ֵ���						
			P3=I0;//��д���λ�����ָ��			
			P4=I2;
			[FP-4]=P3;
			[FP-12]=P4;
			
			//MCVSD �еڶ����˲������˲�����
			P3=[FP-28];
			P4=[FP-36];
			P2=[FP-40];
			B0=P3;
			B1=P3;
			B2=P4;
			P3=[FP-24];
			P4=[FP-32];			
			L0=P2;
			L1=P2;
			L2=P2;
			I0=P3;
			I1=P3;
			I2=P4;
			
			W[I0++]=R3.L;//���ӳ�����дһ����
			A1=0 ;//�ۼӼĴ�����ʼ��
			R3.H=0; //buffer_FWR_tx
			LSETUP(E_MAC2_ST,E_MAC2_END)LC1=P2>>1;
			I1+=2;
			
E_MAC2_ST:	R0.H=W[I2++] || R0.L=W[I1--];
E_MAC2_END:	A1+=R0.H*R0.L;

			R3.H=A1;//p
	
			P3=I0;
			P4=I2;
			[FP-24]=P3;
			[FP-32]=P4;
			
			//����б��
			R0=7;
			P3=[FP+48];
			
			R1=R5 & R0;
			R1.H=R1.L-R0.L(ns);
			CC=AZ;
			
			IF !CC JUMP NOT_ALL_1;
			R2=R6.H*R3.H;//delta_mod������ȫ��1	
			R2=R2<<5 (s);//��б������������
			
			JUMP SLOPE_MODIFIED;
			
NOT_ALL_1:	R2=0xFFFFFFFF;
			R1=R2 ^ R5;
			R1=R1 & R0;
			R1.H=R1.L-R0.L(ns);
			CC=AZ;
			
			IF !CC JUMP NO_MOD;
			R2=R6.H*R3.H;//delta_mod������ȫ��0
			R2=R2<<5;//��б������������
			JUMP SLOPE_MODIFIED;

NO_MOD:		R2.H=0;//б������Ϊ0

SLOPE_MODIFIED:
	
			R1.L=W[P3];//����ԭ����delta
			R2.L=R2.H+R6.L(s);
			
			R1.H=R7.L*R1.L;
			R2.H=R2.L+R1.H(s);//delta
			W[P3]=R2.H;//����delta
			
			P3=[FP+44];
			CC=BITTST(R5,0);
			
			IF !CC JUMP D_ZERO;
			R1.H=R4.L+R2.H(s);
			JUMP SR_DONE;

D_ZERO:		R1.H=R4.L-R2.H(s);		

SR_DONE:	W[P3]=R1.H;//����Sr

			//��R5��ÿ��16λ��дһ��word
			R0.L=16;
			R0.H=1;
			R1.L=R4.H-R0.L(ns);
			CC=AZ;
			
			IF !CC JUMP NO_WR;
			W[I3++]=R5.L;
			R4.H=0;
NO_WR:		
E_CODE_END:	R4.H=R4.H+R0.H(ns);
			
			P1=[FP+52];
			[P1]=R5;//��󱣴�d�е�����
			
			
			(R7:4,P5:3)=[SP++]; 
			UNLINK; 
			RTS;				

__code_mcvsd.end:	