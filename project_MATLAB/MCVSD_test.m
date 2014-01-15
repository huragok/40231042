clear all;
close all;
clc;

%DSP��ز���________________________________________________________________
framesize=1024; %dsp��������֡��������������1024

%CVSD��ز���_______________________________________________________________
alpha=0.995; %Ԥ������һ�ף�
beta=0.75; %�����˲�����һ�ף�
delta0=0.0035; %б�ʱ仯�Ĳ���
delta_min=0.001; %���б��
len_buffer_al=3; %����Ӧ�߼�����˵Ľ���3

%���˲�������_______________________________________________________________
len_LPF_CVSD=18; %����˵�ͨ�˲������ȣ������ص�������ʵ�ַֿ���
len_LPF_MCVSD1=30; %������MCVSD��ͨ�˲�������
len_LPF_MCVSD2=3;

LPF_CVSD=hamming(len_LPF_CVSD); %hamming��
LPF_MCVSD1=hamming(len_LPF_MCVSD1); %hamming��
LPF_MCVSD2=hamming(len_LPF_MCVSD2); %hamming��


%�����ź���ز���___________________________________________________________
voice_in=wavread('voice_sample_02_48_16.wav'); %�����źţ���������48kHz��16bit����
L=length(voice_in); %�����źŵ�������
if mod(L,framesize)~=0 %�����źŲ�0��������֡
    voice_in(L+1:L+framesize-mod(L,framesize))=zeros(1,framesize-mod(L,framesize));
    L=L+framesize-mod(L,framesize);
end  
voice_out=zeros(1,L); %����ź�

%CVSD��ر�������___________________________________________________________

%������_______________________
buffer_tx=zeros(2,framesize); %ģ��˫������������)
buffer_al_tx=zeros(1,len_buffer_al); %����Ӧ�߼��������λ�Ĵ���

delayline_MCVSD1_tx=zeros(1,len_LPF_MCVSD1); %MCVSD��ͨ�˲������ӳ���
buffer_FWR_tx=0;

delayline_MCVSD2_tx=zeros(1,len_LPF_MCVSD2); %MCVSD�����˲������ӳ���
p_tx=0;

sp_tx=0; %����õ��Ĳ���ֵ�����������ֵ���Ƚ�
sr_tx=0; %һ��Ԥ��������һ��Ԥ����
d_tx=zeros(1,framesize); %��������sp�Ĳ�ֵ��һ���������ý����0��1��

delta_mod_tx=0; %ʵ�ʵ�б�ʱ仯��0/delta0
delta_tx=0.1; %ʵ�ʵ�б��
delta_signed_tx=0; %ʵ�ʵĸı������+-����Ԥ��������

%������________________________
buffer_rx=zeros(2,framesize);
buffer_al_rx=zeros(1,len_buffer_al);

delayline_CVSD_rx=zeros(1,len_LPF_CVSD);%����������ͨ�˲������ӳ���

delayline_MCVSD1_rx=zeros(1,len_LPF_MCVSD1); %MCVSD��ͨ�˲������ӳ���
buffer_FWR_rx=0;

delayline_MCVSD2_rx=zeros(1,len_LPF_MCVSD2); %MCVSD�����˲������ӳ���
p_rx=0;

sp_rx=0;
sr_rx=0;
d_rx=zeros(1,framesize);

delta_mod_rx=0;
delta_rx=0.1;
delta_signed_rx=0;

%_________________________________________________________________________
num_frame=ceil(L./framesize); %֡��
ping=0;%ƹ�ұ�־λ��0->1;1->2

%ģ���֡����CVSD����ͽ���Ĺ���____________________________________________
for m=0:num_frame-1
    %����
    if ping==0
        buffer_tx(1,:)=voice_in(m*framesize+1:(m+1)*framesize);
        for n=1:framesize;
            
			sp_tx=alpha*sr_tx;
			
            %�����������������бȽ�
            if buffer_tx(1,n)>sp_tx
                d_tx(n)=1;
            else
                d_tx(n)=0;
            end%д�������ˣ�
            
            %MCVSD�㷨�����ݰ������б�������ķ���p
            delayline_MCVSD1_tx=[sp_tx,delayline_MCVSD1_tx(1:len_LPF_MCVSD1-1)];
            buffer_FWR_tx=abs(delayline_MCVSD1_tx*LPF_MCVSD1);
            
            delayline_MCVSD2_tx=[buffer_FWR_tx,delayline_MCVSD2_tx(1:len_LPF_MCVSD2-1)];
            p_tx=delayline_MCVSD2_tx*LPF_MCVSD2;%д�������ˣ�
            
            %����б��
            buffer_al_tx=[d_tx(n),buffer_al_tx(1:len_buffer_al-1)];%���ø���
            delta_mod_tx=(all(buffer_al_tx)+~any(buffer_al_tx))*delta0*p_tx;
            delta_tx=beta*delta_tx+delta_mod_tx+delta_min;
            delta_signed_tx=delta_tx*(2*d_tx(n)-1);         
            
            %Ԥ��           
            sr_tx=sp_tx+delta_signed_tx;    
        end
    else
        buffer_tx(2,:)=voice_in(m*framesize+1:(m+1)*framesize);
        for n=1:framesize;
            
			sp_tx=alpha*sr_tx;
			
            %�����������������бȽ�
            if buffer_tx(2,n)>sp_tx
                d_tx(n)=1;
            else
                d_tx(n)=0;
            end
            
            %MCVSD�㷨�����ݰ������б�������ķ���p
            delayline_MCVSD1_tx=[sp_tx,delayline_MCVSD1_tx(1:len_LPF_MCVSD1-1)];
            buffer_FWR_tx=abs(delayline_MCVSD1_tx*LPF_MCVSD1);
            
            delayline_MCVSD2_tx=[buffer_FWR_tx,delayline_MCVSD2_tx(1:len_LPF_MCVSD2-1)];
            p_tx=delayline_MCVSD2_tx*LPF_MCVSD2;
            
            %����б��
            buffer_al_tx=[d_tx(n),buffer_al_tx(1:len_buffer_al-1)];
            delta_mod_tx=(all(buffer_al_tx)+~any(buffer_al_tx))*delta0*p_tx;
            delta_tx=beta*delta_tx+delta_mod_tx+delta_min;
            delta_signed_tx=delta_tx*(2*d_tx(n)-1);  
            
            %Ԥ��
            sr_tx=sp_tx+delta_signed_tx;    
        end
    end
    
    %����
    d_rx=d_tx;
    %��¼��������
    d_record(m*framesize+1:(m+1)*framesize)=d_rx;
    if ping==0        
        for n=1:framesize
            
			sp_rx=alpha*sr_rx;
			
            %MCVSD�㷨�����ݰ������б�������ķ���p
            delayline_MCVSD1_rx=[sp_rx,delayline_MCVSD1_rx(1:len_LPF_MCVSD1-1)];
            buffer_FWR_rx=abs(delayline_MCVSD1_rx*LPF_MCVSD1);
            
            delayline_MCVSD2_rx=[buffer_FWR_rx,delayline_MCVSD2_rx(1:len_LPF_MCVSD2-1)];
            p_rx=delayline_MCVSD2_rx*LPF_MCVSD2;
            
            %����б��
            buffer_al_rx=[d_rx(n),buffer_al_rx(1:len_buffer_al-1)];
            delta_mod_rx=(all(buffer_al_rx)+~any(buffer_al_rx))*delta0*p_rx;
            delta_rx=beta*delta_rx+delta_mod_rx+delta_min;
            delta_signed_rx=delta_rx*(2*d_rx(n)-1);
            
            %Ԥ��    
            sr_rx=sp_rx+delta_signed_rx;
                 
            %��Ԥ��������ͨ�˲�
            delayline_CVSD_rx=[sp_rx,delayline_CVSD_rx(1:len_LPF_CVSD-1)];
            buffer_rx(1,n)=delayline_CVSD_rx*LPF_CVSD;
        end
        voice_out(m*framesize+1:(m+1)*framesize)=buffer_rx(1,:);
    else
        for n=1:framesize
            
			sp_rx=alpha*sr_rx;
			
            %MCVSD�㷨�����ݰ������б�������ķ���p
            delayline_MCVSD1_rx=[sp_rx,delayline_MCVSD1_rx(1:len_LPF_MCVSD1-1)];
            buffer_FWR_rx=abs(delayline_MCVSD1_rx*LPF_MCVSD1);
        
            delayline_MCVSD2_rx=[buffer_FWR_rx,delayline_MCVSD2_rx(1:len_LPF_MCVSD2-1)];
            p_rx=delayline_MCVSD2_rx*LPF_MCVSD2;
        
            %����б��
            buffer_al_rx=[d_rx(n),buffer_al_rx(1:len_buffer_al-1)];
            delta_mod_rx=(all(buffer_al_rx)+~any(buffer_al_rx))*delta0*p_rx;
            delta_rx=beta*delta_rx+delta_mod_rx+delta_min;
            delta_signed_rx=delta_rx*(2*d_rx(n)-1);
           
            %Ԥ��
            sr_rx=sp_rx+delta_signed_rx;
            
            %��Ԥ��������ͨ�˲�
            delayline_CVSD_rx=[sp_rx,delayline_CVSD_rx(1:len_LPF_CVSD-1)];
            buffer_rx(2,n)=delayline_CVSD_rx*LPF_CVSD;
        end
        voice_out(m*framesize+1:(m+1)*framesize)=buffer_rx(2,:);
    end
    ping=xor(ping,1);
end

%�Ƚ�������������_________________________________________________________
voice_out=voice_out/max(abs(voice_out));
wavwrite(voice_out,48000,'voice_sample_02_48_16_out.wav');
% t=1:L;
% figure;
% hold on;
% subplot(2,1,1),plot(t,voice_in);
% subplot(2,1,2),plot(t,voice_out);

