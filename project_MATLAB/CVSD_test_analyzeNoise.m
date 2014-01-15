clear all;
close all;
clc;

%DSP相关参数________________________________________________________________
framesize=1024; %dsp处理器的帧长（采样数）：512
len_filter=40; %解码端低通滤波器长度，采用重叠保留法实现分块卷积
delta0=0.005; %斜率变化的步长
delta_min=0.001; %最低斜率

%CVSD相关参数_______________________________________________________________
alpha=0.99; %预测器（一阶）
beta=0.6; %音节滤波器（一阶）
len_buffer_al=3; %自适应逻辑输入端的阶数3/4

%语音信号相关参数___________________________________________________________
voice_in=wavread('zero_48kHz_16bit.wav'); %输入信号，单声道，48kHz，16bit量化
L=length(voice_in); %输入信号的样点数
if mod(L,framesize)~=0 %输入信号补0调成整数帧
    voice_in(L+1:L+framesize-mod(L,framesize))=zeros(1,framesize-mod(L,framesize));
    L=L+framesize-mod(L,framesize);
end  
voice_out=zeros(1,L); %输出信号
% fs=8000; %采样率：8kHz
% n=8; %量化比特数：8bit

%CVSD相关变量定义___________________________________________________________
%编码器
buffer_tx=zeros(2,framesize); %模拟双缓存器（输入）
buffer_al_tx=zeros(1,len_buffer_al); %自适应逻辑输入端移位寄存器
sp_tx=0; %解码得到的采样值，与输入采样值做比较
sr_tx=0; %一阶预测器中上一次预测结果
d_tx=zeros(1,framesize); %对输入与sp的差值作一阶量化所得结果（0，1）

delta_mod_tx=0; %实际的斜率变化，0/delta0
delta_tx=0.1; %实际的斜率
delta_signed_tx=0; %实际的改变变量（+-），预测器输入

%解码器
buffer_rx=zeros(2,framesize);
buffer_overlap=zeros(1,len_filter-1); %保留上一帧末尾的重叠部分
buffer_al_rx=zeros(1,len_buffer_al);
sp_rx=0;
sr_rx=0;
d_rx=zeros(1,framesize);

delta_mod_rx=0;
delta_rx=0.1;
delta_signed_rx=0;

d_record=zeros(1,L);
%_________________________________________________________________________
num_frame=ceil(L./framesize); %帧数
ping=0;%乒乓标志位，0->1;1->2

%模拟分帧进行CVSD编码和解码的过程____________________________________________
for m=0:num_frame-1
    %编码
    if ping==0
        buffer_tx(1,:)=voice_in(m*framesize+1:(m+1)*framesize);
        for n=1:framesize;
            if buffer_tx(1,n)>sp_tx
                d_tx(n)=1;
            else
                d_tx(n)=0;
            end
            
            buffer_al_tx=[d_tx(n),buffer_al_tx(1:len_buffer_al-1)];
            delta_mod_tx=(all(buffer_al_tx) || ~any(buffer_al_tx))*delta0;
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
            delta_mod_tx=(all(buffer_al_tx) || ~any(buffer_al_tx))*delta0;
            delta_tx=beta*delta_tx+delta_mod_tx+delta_min;
            delta_signed_tx=delta_tx*(2*d_tx(n)-1);
            
            sp_tx=alpha*sr_tx;
            sr_tx=sp_tx+delta_signed_tx;
        end
    end
    ping=xor(ping,1);
    
    %解码
    d_rx=d_tx;
    d_record(m*framesize+1:(m+1)*framesize)=d_rx;
    if ping==0        
        for n=1:framesize
            buffer_al_rx=[d_rx(n),buffer_al_rx(1:len_buffer_al-1)];
            delta_mod_rx=(all(buffer_al_rx) || ~any(buffer_al_rx))*delta0;
            delta_rx=beta*delta_rx+delta_mod_rx+delta_min;
            delta_signed_rx=delta_rx*(2*d_rx(n)-1);
            
            sp_rx=alpha*sr_rx;
            sr_rx=sp_rx+delta_signed_rx;
            
            buffer_rx(1,n)=sp_rx;
        end

        voice_out(m*framesize+1:(m+1)*framesize)=buffer_rx(1,:);

    else
        for n=1:framesize
            buffer_al_rx=[d_rx(n),buffer_al_rx(1:len_buffer_al-1)];
            delta_mod_rx=(all(buffer_al_rx) || ~any(buffer_al_rx))*delta0;
            delta_rx=beta*delta_rx+delta_mod_rx+delta_min;
            delta_signed_rx=delta_rx*(2*d_rx(n)-1);
            
            sp_rx=alpha*sr_rx;
            sr_rx=sp_rx+delta_signed_rx;
            
            buffer_rx(2,n)=sp_rx;
        end

         voice_out(m*framesize+1:(m+1)*framesize)=buffer_rx(2,:);

    end
    ping=xor(ping,1);
end

%比较输入和输出波形_________________________________________________________
t=100:200;
figure;
hold on;
plot(t,voice_in(t),'b'),stem(t,voice_out(t),'r');
stem(t,2*d_record(t)-1,'g');

t=100100:100200;
figure;
hold on;
plot(t,voice_in(t),'b'),stem(t,voice_out(t),'r');
stem(t,2*d_record(t)-1,'g');

