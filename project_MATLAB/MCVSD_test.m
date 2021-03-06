clear all;
close all;
clc;

%DSP相关参数________________________________________________________________
framesize=1024; %dsp处理器的帧长（采样数）：1024

%CVSD相关参数_______________________________________________________________
alpha=0.995; %预测器（一阶）
beta=0.75; %音节滤波器（一阶）
delta0=0.0035; %斜率变化的步长
delta_min=0.001; %最低斜率
len_buffer_al=3; %自适应逻辑输入端的阶数3

%各滤波器定义_______________________________________________________________
len_LPF_CVSD=18; %解码端低通滤波器长度，采用重叠保留法实现分块卷积
len_LPF_MCVSD1=30; %编解码端MCVSD低通滤波器长度
len_LPF_MCVSD2=3;

LPF_CVSD=hamming(len_LPF_CVSD); %hamming窗
LPF_MCVSD1=hamming(len_LPF_MCVSD1); %hamming窗
LPF_MCVSD2=hamming(len_LPF_MCVSD2); %hamming窗


%语音信号相关参数___________________________________________________________
voice_in=wavread('voice_sample_02_48_16.wav'); %输入信号，单声道，48kHz，16bit量化
L=length(voice_in); %输入信号的样点数
if mod(L,framesize)~=0 %输入信号补0调成整数帧
    voice_in(L+1:L+framesize-mod(L,framesize))=zeros(1,framesize-mod(L,framesize));
    L=L+framesize-mod(L,framesize);
end  
voice_out=zeros(1,L); %输出信号

%CVSD相关变量定义___________________________________________________________

%编码器_______________________
buffer_tx=zeros(2,framesize); %模拟双缓存器（输入)
buffer_al_tx=zeros(1,len_buffer_al); %自适应逻辑输入端移位寄存器

delayline_MCVSD1_tx=zeros(1,len_LPF_MCVSD1); %MCVSD低通滤波器的延迟线
buffer_FWR_tx=0;

delayline_MCVSD2_tx=zeros(1,len_LPF_MCVSD2); %MCVSD包络滤波器的延迟线
p_tx=0;

sp_tx=0; %解码得到的采样值，与输入采样值做比较
sr_tx=0; %一阶预测器中上一次预测结果
d_tx=zeros(1,framesize); %对输入与sp的差值作一阶量化所得结果（0，1）

delta_mod_tx=0; %实际的斜率变化，0/delta0
delta_tx=0.1; %实际的斜率
delta_signed_tx=0; %实际的改变变量（+-），预测器输入

%解码器________________________
buffer_rx=zeros(2,framesize);
buffer_al_rx=zeros(1,len_buffer_al);

delayline_CVSD_rx=zeros(1,len_LPF_CVSD);%解码端输出低通滤波器的延迟线

delayline_MCVSD1_rx=zeros(1,len_LPF_MCVSD1); %MCVSD低通滤波器的延迟线
buffer_FWR_rx=0;

delayline_MCVSD2_rx=zeros(1,len_LPF_MCVSD2); %MCVSD包络滤波器的延迟线
p_rx=0;

sp_rx=0;
sr_rx=0;
d_rx=zeros(1,framesize);

delta_mod_rx=0;
delta_rx=0.1;
delta_signed_rx=0;

%_________________________________________________________________________
num_frame=ceil(L./framesize); %帧数
ping=0;%乒乓标志位，0->1;1->2

%模拟分帧进行CVSD编码和解码的过程____________________________________________
for m=0:num_frame-1
    %编码
    if ping==0
        buffer_tx(1,:)=voice_in(m*framesize+1:(m+1)*framesize);
        for n=1:framesize;
            
			sp_tx=alpha*sr_tx;
			
            %将输入与解码输出进行比较
            if buffer_tx(1,n)>sp_tx
                d_tx(n)=1;
            else
                d_tx(n)=0;
            end%写到这里了！
            
            %MCVSD算法，根据包络计算斜率增量的幅度p
            delayline_MCVSD1_tx=[sp_tx,delayline_MCVSD1_tx(1:len_LPF_MCVSD1-1)];
            buffer_FWR_tx=abs(delayline_MCVSD1_tx*LPF_MCVSD1);
            
            delayline_MCVSD2_tx=[buffer_FWR_tx,delayline_MCVSD2_tx(1:len_LPF_MCVSD2-1)];
            p_tx=delayline_MCVSD2_tx*LPF_MCVSD2;%写到这里了！
            
            %更新斜率
            buffer_al_tx=[d_tx(n),buffer_al_tx(1:len_buffer_al-1)];%不用更新
            delta_mod_tx=(all(buffer_al_tx)+~any(buffer_al_tx))*delta0*p_tx;
            delta_tx=beta*delta_tx+delta_mod_tx+delta_min;
            delta_signed_tx=delta_tx*(2*d_tx(n)-1);         
            
            %预测           
            sr_tx=sp_tx+delta_signed_tx;    
        end
    else
        buffer_tx(2,:)=voice_in(m*framesize+1:(m+1)*framesize);
        for n=1:framesize;
            
			sp_tx=alpha*sr_tx;
			
            %将输入与解码输出进行比较
            if buffer_tx(2,n)>sp_tx
                d_tx(n)=1;
            else
                d_tx(n)=0;
            end
            
            %MCVSD算法，根据包络计算斜率增量的幅度p
            delayline_MCVSD1_tx=[sp_tx,delayline_MCVSD1_tx(1:len_LPF_MCVSD1-1)];
            buffer_FWR_tx=abs(delayline_MCVSD1_tx*LPF_MCVSD1);
            
            delayline_MCVSD2_tx=[buffer_FWR_tx,delayline_MCVSD2_tx(1:len_LPF_MCVSD2-1)];
            p_tx=delayline_MCVSD2_tx*LPF_MCVSD2;
            
            %更新斜率
            buffer_al_tx=[d_tx(n),buffer_al_tx(1:len_buffer_al-1)];
            delta_mod_tx=(all(buffer_al_tx)+~any(buffer_al_tx))*delta0*p_tx;
            delta_tx=beta*delta_tx+delta_mod_tx+delta_min;
            delta_signed_tx=delta_tx*(2*d_tx(n)-1);  
            
            %预测
            sr_tx=sp_tx+delta_signed_tx;    
        end
    end
    
    %解码
    d_rx=d_tx;
    %记录测试数据
    d_record(m*framesize+1:(m+1)*framesize)=d_rx;
    if ping==0        
        for n=1:framesize
            
			sp_rx=alpha*sr_rx;
			
            %MCVSD算法，根据包络计算斜率增量的幅度p
            delayline_MCVSD1_rx=[sp_rx,delayline_MCVSD1_rx(1:len_LPF_MCVSD1-1)];
            buffer_FWR_rx=abs(delayline_MCVSD1_rx*LPF_MCVSD1);
            
            delayline_MCVSD2_rx=[buffer_FWR_rx,delayline_MCVSD2_rx(1:len_LPF_MCVSD2-1)];
            p_rx=delayline_MCVSD2_rx*LPF_MCVSD2;
            
            %更新斜率
            buffer_al_rx=[d_rx(n),buffer_al_rx(1:len_buffer_al-1)];
            delta_mod_rx=(all(buffer_al_rx)+~any(buffer_al_rx))*delta0*p_rx;
            delta_rx=beta*delta_rx+delta_mod_rx+delta_min;
            delta_signed_rx=delta_rx*(2*d_rx(n)-1);
            
            %预测    
            sr_rx=sp_rx+delta_signed_rx;
                 
            %对预测结果做低通滤波
            delayline_CVSD_rx=[sp_rx,delayline_CVSD_rx(1:len_LPF_CVSD-1)];
            buffer_rx(1,n)=delayline_CVSD_rx*LPF_CVSD;
        end
        voice_out(m*framesize+1:(m+1)*framesize)=buffer_rx(1,:);
    else
        for n=1:framesize
            
			sp_rx=alpha*sr_rx;
			
            %MCVSD算法，根据包络计算斜率增量的幅度p
            delayline_MCVSD1_rx=[sp_rx,delayline_MCVSD1_rx(1:len_LPF_MCVSD1-1)];
            buffer_FWR_rx=abs(delayline_MCVSD1_rx*LPF_MCVSD1);
        
            delayline_MCVSD2_rx=[buffer_FWR_rx,delayline_MCVSD2_rx(1:len_LPF_MCVSD2-1)];
            p_rx=delayline_MCVSD2_rx*LPF_MCVSD2;
        
            %更新斜率
            buffer_al_rx=[d_rx(n),buffer_al_rx(1:len_buffer_al-1)];
            delta_mod_rx=(all(buffer_al_rx)+~any(buffer_al_rx))*delta0*p_rx;
            delta_rx=beta*delta_rx+delta_mod_rx+delta_min;
            delta_signed_rx=delta_rx*(2*d_rx(n)-1);
           
            %预测
            sr_rx=sp_rx+delta_signed_rx;
            
            %对预测结果做低通滤波
            delayline_CVSD_rx=[sp_rx,delayline_CVSD_rx(1:len_LPF_CVSD-1)];
            buffer_rx(2,n)=delayline_CVSD_rx*LPF_CVSD;
        end
        voice_out(m*framesize+1:(m+1)*framesize)=buffer_rx(2,:);
    end
    ping=xor(ping,1);
end

%比较输入和输出波形_________________________________________________________
voice_out=voice_out/max(abs(voice_out));
wavwrite(voice_out,48000,'voice_sample_02_48_16_out.wav');
% t=1:L;
% figure;
% hold on;
% subplot(2,1,1),plot(t,voice_in);
% subplot(2,1,2),plot(t,voice_out);

