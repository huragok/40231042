.section program;
.global    __decode_mcvsd;
.align 8;
__decode_mcvsd:
			
			LINK    60; //����Ҫ�������ı��ر����ռ�
			[--SP]=(R7:4,P5:3); //����һЩ�Ĵ�����ֵ
			[FP+8]=R0; //IN
			[FP+12]=R1; //OUT_MCVSD
			[FP+16]=R2; //nsample=1024
			
			//��LPF_MCVSD1���ӳ��߶���д��ϵ����дѭ��ָ���Ϊ���ر���
			P0=[FP+36];//�����3����
			
			P1=[P0++];//�˲���ϵ��
			P2=[P0++];//�ӳ���
			R3=[P0];//�ӳ��߳���
			
			[FP-4]=P2;//I01
			R3=R3+R3;//�����3����
			[FP-8]=P2;//B01
			[FP-12]=P1;//I2
			[FP-16]=P1;//B2
			[FP-20]=R3;//L012
			
			//��LPF_MCVSD2���ӳ��߶���д��ϵ����дѭ��ָ���Ϊ���ر���
			P0=[FP+40];	//�����3����		
			P1=[P0++];//�˲���ϵ��
			P2=[P0++];//�ӳ���
			R3=[P0];//�ӳ��߳���
			
			[FP-24]=P2;//I01
			R3=R3+R3;//�����3����
			[FP-28]=P2;//B01
			[FP-32]=P1;//I2
			[FP-36]=P1;//B2
			[FP-40]=R3;//L012
			
			//��LPF_CVSD���ӳ��߶���д��ϵ����дѭ��ָ���Ϊ���ر���
			P0=[FP+56];	//�����3����		
			P1=[P0++];//�˲���ϵ��
			P2=[P0++];//�ӳ���
			R3=[P0];//�ӳ��߳���
			
			[FP-44]=P2;//I0
			R3=R3+R3;//�����3����
			[FP-48]=P2;//B0
			[FP-52]=P1;//I2
			[FP-56]=P1;//B2
			[FP-60]=R3;//L012
			
			P0=R0;// Address of the input array
			P1=R2;// outer loop counter
			
			R2=R2+R2;

			I3=R1;// Initialize I3 to the start of the output buffer
			B3=R1;// Output buffer initialized as circular buffer
			L3=R2;//������г���(Byte��)
			
			R6=[FP+24];
			R7=[FP+32];
			R0=[FP+20];
			R1=[FP+28];
			R0<<=16;
			R1<<=16;
			R6=R6+R0;//R6.H=delta0, R6.L=delta_min
			R7=R7+R1;//R7.H=alpha, R7.L=beta
			R4.H=1;//R4.L=Sp, R4.H=count(16);
			
			
			LSETUP(E_CODE_START,E_CODE_END) LC0=P1; //��ʼ���б���
			P1=[FP+52];
			R5=[P1];//������һ�ֵı�����
			R5.L=W[P0];//��R5�ĵ�16λ�ж���16��������������ı����������λ
			P0+=2;
E_CODE_START:

			P3=[FP+44];//����sr
			R1.L=W[P3];
			R4.L=R1.L*R7.H;//����sp
			
			//MCVSD �е�һ���˲������˲�����
			P3=[FP-4];
			P4=[FP-12];
			I0=P3;//��ʼ�����λ�����
			I1=P3;
			I2=P4;
			P3=[FP-8];
			P4=[FP-16];
			P2=[FP-20];
			B0=P3;//��ʼ�����λ�����
			B1=P3;
			B2=P4;			
			L0=P2;
			L1=P2;
			L2=P2;
			
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
			P3=[FP-24];
			P4=[FP-32];
			I0=P3;//��ʼ�����λ�����
			I1=P3;
			I2=P4;
			P3=[FP-28];
			P4=[FP-36];
			P2=[FP-40];
			B0=P3;//��ʼ�����λ�����
			B1=P3;
			B2=P4;			
			L0=P2;
			L1=P2;
			L2=P2;
			
			W[I0++]=R3.L;//���ӳ�����дһ����
			A1=0 ;//�ۼӼĴ�����ʼ��
			R3.H=0; //buffer_FWR_tx
			LSETUP(E_MAC2_ST,E_MAC2_END)LC1=P2>>1;
			I1+=2;
			
E_MAC2_ST:	R0.H=W[I2++] || R0.L=W[I1--];
E_MAC2_END:	A1+=R0.H*R0.L;

			R3.H=A1;//p
	
			P3=I0;//��д���λ�����ָ��
			P4=I2;
			[FP-24]=P3;
			[FP-32]=P4;
			
			//����б��
			R0.H=3;
			R0.L=32768;
			
			R1=R5 & R0;
			R1=R1-R0(ns);
			CC=AZ;
			
			IF !CC JUMP NOT_ALL_1;
			R2=R6.H*R3.H;//delta_mod,ǰ3������1	
			R2=R2<<5;//������
			JUMP SLOPE_MODIFIED;
			
NOT_ALL_1:	R2=0xFFFFFFFF;
			R1=R2 ^ R5;
			R1=R1 & R0;
			R1=R1-R0(ns);
			CC=AZ;
			
			IF !CC JUMP NO_MOD;
			R2=R6.H*R3.H;//delta_mod��ǰ3������0
			R2=R2<<5;//������
			JUMP SLOPE_MODIFIED;

NO_MOD:		R2.H=0;//ǰ3��bit����ȣ������޸�����

SLOPE_MODIFIED:
	
			P3=[FP+48];
			R1.L=W[P3];//����ԭ����delta
			
			R2.L=R2.H+R6.L(s);
			R1.H=R7.L*R1.L;
			R2.H=R2.L+R1.H(s);//delta
			W[P3]=R2.H;//����delta
			
			P3=[FP+44];
			CC=BITTST(R5,15);
			
			IF !CC JUMP D_ZERO;
			R3.H=R4.L+R2.H(s);
			JUMP SR_DONE;

D_ZERO:		R3.H=R4.L-R2.H(s);
			
SR_DONE:	W[P3]=R3.H;//����Sr
			
			//MCVSD �������ͨ�˲������˲�����
			P3=[FP-44];
			P4=[FP-52];
			I0=P3;//��ʼ�����λ�����
			I1=P3;
			I2=P4;
			P3=[FP-48];
			P4=[FP-56];
			P2=[FP-60];
			B0=P3;//��ʼ�����λ�����
			B1=P3;
			B2=P4;			
			L0=P2;
			L1=P2;
			L2=P2;
			
			W[I0++]=R3.H;//���ӳ�����дһ����
			A0=0 ;//�ۼӼĴ�����ʼ��
			R3.L=0; //���
			LSETUP(E_MAC3_ST,E_MAC3_END)LC1=P2>>1;
			I1+=2;
			
E_MAC3_ST:	R0.H=W[I2++] || R0.L=W[I1--];
E_MAC3_END:	A0+=R0.H*R0.L;

			R3.L=A0;//���
			W[I3++]=R3.L;
	
			P3=I0;//��д���λ�����ָ��
			P4=I2;
			[FP-44]=P3;
			[FP-52]=P4;

			R5<<=1;//��������λ�Ĵ�������һλ
			
			//ÿ��R5��д��16λ�����һ������
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

			[P1]=R5;//������d��λ�����������
						
			(R7:4,P5:3)=[SP++]; 
			UNLINK; 
			RTS;				

__decode_mcvsd.end:	