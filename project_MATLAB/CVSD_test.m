clear all;
close all;
clc;

%DSP��ز���________________________________________________________________
framesize=1024; %dsp��������֡��������������512
len_filter=30; %����˵�ͨ�˲������ȣ������ص�������ʵ�ַֿ����
delta0=0.01; %б�ʱ仯�Ĳ���
delta_min=0.001; %���б��

%CVSD��ز���_______________________________________________________________
alpha=0.99; %Ԥ������һ�ף�
beta=0.5; %�����˲�����һ�ף�
len_buffer_al=3; %����Ӧ�߼�����˵Ľ���3/4

%�����ź���ز���___________________________________________________________
voice_in=wavread('zero_48kHz_16bit.wav'); %�����źţ���������48kHz��16bit����
L=length(voice_in); %�����źŵ�������
if mod(L,framesize)~=0 %�����źŲ�0��������֡
    voice_in(L+1:L+framesize-mod(L,framesize))=zeros(1,framesize-mod(L,framesize));
    L=L+framesize-mod(L,framesize);
end  
voice_out=zeros(1,L); %����ź�
% fs=8000; %�����ʣ�8kHz
% n=8; %������������8bit

%CVSD��ر�������___________________________________________________________
%������
buffer_tx=zeros(2,framesize); %ģ��˫�����������룩
buffer_al_tx=zeros(1,len_buffer_al); %����Ӧ�߼��������λ�Ĵ���
sp_tx=0; %����õ��Ĳ���ֵ�����������ֵ���Ƚ�
sr_tx=0; %һ��Ԥ��������һ��Ԥ����
d_tx=zeros(1,framesize); %��������sp�Ĳ�ֵ��һ���������ý����0��1��

delta_mod_tx=0; %ʵ�ʵ�б�ʱ仯��0/delta0
delta_tx=0.1; %ʵ�ʵ�б��
delta_signed_tx=0; %ʵ�ʵĸı������+-����Ԥ��������

%������
buffer_rx=zeros(2,framesize);
buffer_overlap=zeros(1,len_filter-1); %������һ֡ĩβ���ص�����
buffer_LPF_out=zeros(1,framesize); %�����ͨ�˲����
w=hamming(len_filter); %hamming��
buffer_al_rx=zeros(1,len_buffer_al);
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
            if buffer_tx(1,n)>sp_tx
                d_tx(n)=1;
            else
                d_tx(n)=0;
            end
            
            buffer_al_tx=[d_tx(n),buffer_al_tx(1:len_buffer_al-1)];
            delta_mod_tx=(all(buffer_al_tx)+~any(buffer_al_tx))*delta0;
            delta_tx=beta*delta_tx+delta_mod_tx+delta_min;
            delta_signed_tx=delta_tx*(2*d_tx(n)-1);
            
            sp_tx=alpha*sr_tx;
            sr_tx=sp_tx+delta_signed_tx;
        end
    else
        buffer_tx(2,:)=voice_sample(m+1:m+framesize);
        for n=1:framesize;
            if buffer_tx(2,n)>sp_tx
                d_tx(n)=1;
            else
                d_tx(n)=0;
            end
            
            buffer_al_tx=[d_tx(n),buffer_al_tx(1:len_buffer_al-1)];
            delta_mod_tx=(all(buffer_al_tx)+~any(buffer_al_tx))*delta0;
            delta_tx=beta*delta_tx+delta_mod_tx+delta_min;
            delta_signed_tx=delta_tx*(2*d_tx(n)-1);
            
            sp_tx=alpha*sr_tx;
            sr_tx=sp_tx+delta_signed_tx;
        end
    end
    ping=xor(ping,1);
    
    %����
    d_rx=d_tx;
    if ping==0        
        for n=1:framesize
            buffer_al_rx=[d_rx(n),buffer_al_rx(1:len_buffer_al-1)];
            delta_mod_rx=(all(buffer_al_rx)+~any(buffer_al_rx))*delta0;
            delta_rx=beta*delta_rx+delta_mod_rx+delta_min;
            delta_signed_rx=delta_rx*(2*d_rx(n)-1);
            
            sp_rx=alpha*sr_rx;
            sr_rx=sp_rx+delta_signed_rx;
            
            buffer_rx(1,n)=sp_rx;
        end

        %�˲����̣�Ϊ�˱�����ֲ���룬���ǹ�����ѭ��ʵ�ֵģ���
        for n=1:len_filter-1
            buffer_LPF_out(n)=[buffer_overlap(n:len_filter-1),buffer_rx(1,1:n)]*w;
        end
        for n=len_filter:frame_size
            buffer_LPF_out(n)=buffer_rx(1,n-len_filter+1:n)*w;
        end
         voice_out(m*framesize+1:(m+1)*framesize)=buffer_LPF_out;
         buffer_overlap=buffer_rx(1,framesize-len_filter+2:framesize);
    else
        for n=1:framesize
            buffer_al_rx=[d_rx(n),buffer_al_rx(1:len_buffer_al-1)];
            delta_mod_rx=(all(buffer_al_rx)+~any(buffer_al_rx))*delta0;
            delta_rx=beta*delta_rx+delta_mod_rx+delta_min;
            delta_signed_rx=delta_rx*(2*d_rx(n)-1);
            
            sp_rx=alpha*sr_rx;
            sr_rx=sp_rx+delta_signed_rx;
            
            buffer_rx(2,n)=sp_rx;
        end

        %�˲����̣�Ϊ�˱�����ֲ���룬���ǹ�����ѭ��ʵ�ֵģ���
        for n=1:len_filter-1
            buffer_LPF_out(n)=[buffer_overlap(n:len_filter-1),buffer_rx(2,1:n)]*w;
        end
        for n=len_filter:framesize
            buffer_LPF_out(n)=buffer_rx(2,n-len_filter+1:n)*w;
        end
         voice_out(m*framesize+1:(m+1)*framesize)=buffer_LPF_out;
         buffer_overlap=buffer_rx(2,framesize-len_filter+2:framesize);
    end
    ping=xor(ping,1);
end

%�Ƚ�������������_________________________________________________________
voice_out=voice_out/max(abs(voice_out));
wavwrite(voice_out,48000,'voice_out.wav');
t=1:L;
figure;
hold on;
subplot(2,1,1),plot(t,voice_in);
subplot(2,1,2),plot(t,voice_out);