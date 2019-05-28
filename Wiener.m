function [output,time] = Wiener(signal,fs,type,IS)

if (nargin<4 || isstruct(IS))
    IS=.25; %Initial Silence or Noise Only part in seconds
end

W=fix(.025*fs); %Window length is 25 ms
SP=.4; %Shift percentage is 40% (10ms) %Overlap-Add method works good with this value(.4)
wnd=hann(W);

pre_emph=0;
signal=filter([1 -pre_emph],1,signal);

NIS=fix((IS*fs-W)/(SP*W) +1);%number of initial silence segments

y=segment(signal,W,SP,wnd); % This function chops the signal into frames
Y=fft(y);
YPhase=angle(Y(1:fix(end/2)+1,:)); %Noisy Speech Phase
Y=abs(Y(1:fix(end/2)+1,:));%Specrogram
numberOfFrames=size(Y,2);
FreqResol=size(Y,1);

N=mean(Y(:,1:NIS)')'; %initial Noise Power Spectrum mean
LambdaD=mean((Y(:,1:NIS)').^2)';%initial Noise Power Spectrum variance
alpha=.99; %used in smoothing xi (For Deciesion Directed method for estimation of A Priori SNR)
NoiseCounter=0;
NoiseLength=9;%This is a smoothing factor for the noise updating
G=ones(size(N));%Initial Gain used in calculation of the new xi
Gamma=G;

X=zeros(size(Y)); % Initialize X (memory allocation)

h=waitbar(0,'Wait...');

for i=1:numberOfFrames
    %%%%%%%%%%%%%%%%VAD and Noise Estimation START
    if i<=NIS % If initial silence ignore VAD
        SpeechFlag=0;
        NoiseCounter=100;
    else % Else Do VAD
        [NoiseFlag, SpeechFlag, NoiseCounter, Dist]=vad(Y(:,i),N,NoiseCounter); %Magnitude Spectrum Distance VAD
    end
    
    if SpeechFlag==0 % If not Speech Update Noise Parameters
        N=(NoiseLength*N+Y(:,i))/(NoiseLength+1); %Update and smooth noise mean
        LambdaD=(NoiseLength*LambdaD+(Y(:,i).^2))./(1+NoiseLength); %Update and smooth noise variance
    end
    %%%%%%%%%%%%%%%%%%%VAD and Noise Estimation END
    
    gammaNew=(Y(:,i).^2)./LambdaD; %A postiriori SNR
    xi=alpha*(G.^2).*Gamma+(1-alpha).*max(gammaNew-1,0); %Decision Directed Method for A Priori SNR
    Gamma=gammaNew;
    
    G=(xi./(xi+1));
    
    X(:,i)=G.*Y(:,i); %Obtain the new Cleaned value
    
    waitbar(i/numberOfFrames,h,num2str(fix(100*i/numberOfFrames)));
end

close(h);
output = OverlapAdd2(X,YPhase,W,SP*W); %Overlap-add Synthesis of speech
output = filter(1,[1 -pre_emph],output); %Undo the effect of Pre-emphasis

num = [0.00247553277809987,0.00495106555619995,0.00247553277809975];
den = [1,-1.80098109524571,0.810883226358106];

output = filter(num,den,output);
time = (0:1/fs:(size(output,1)-1)/fs);

if type == 1
    output = 100.*output;
end


function ReconstructedSignal=OverlapAdd2(XNEW,yphase,windowLen,ShiftLen)

if nargin<2
    yphase=angle(XNEW);
end
if nargin<3
    windowLen=size(XNEW,1)*2;
end
if nargin<4
    ShiftLen=windowLen/2;
end
if fix(ShiftLen)~=ShiftLen
    ShiftLen=fix(ShiftLen);
    disp('The shift length have to be an integer as it is the number of samples.')
    disp(['shift length is fixed to ' num2str(ShiftLen)])
end

[FreqRes, FrameNum]=size(XNEW);

Spec=XNEW.*exp(1i*yphase);

if mod(windowLen,2) %if FreqResol is odd
    Spec=[Spec;flipud(conj(Spec(2:end,:)))];
else
    Spec=[Spec;flipud(conj(Spec(2:end-1,:)))];
end
sig=zeros((FrameNum-1)*ShiftLen+windowLen,1);
weight=sig;
for i=1:FrameNum
    start=(i-1)*ShiftLen+1;    
    spec=Spec(:,i);
    sig(start:start+windowLen-1)=sig(start:start+windowLen-1)+real(ifft(spec,windowLen));    
end
ReconstructedSignal=sig;

function Seg=segment(signal,W,SP,Window)

if nargin<3
    SP=.4;
end
if nargin<2
    W=256;
end
if nargin<4
    Window=hamming(W);
end
Window=Window(:); %make it a column vector

L=length(signal);
SP=fix(W.*SP);
N=fix((L-W)/SP +1); %number of segments

Index=(repmat(1:W,N,1)+repmat((0:(N-1))'*SP,1,W))';
hw=repmat(Window,1,N);
Seg=signal(Index).*hw;

function [NoiseFlag, SpeechFlag, NoiseCounter, Dist]=vad(signal,noise,NoiseCounter,NoiseMargin,Hangover)

if nargin<4
    NoiseMargin=3;
end
if nargin<5
    Hangover=8;
end
if nargin<3
    NoiseCounter=0;
end
    
FreqResol=length(signal);

SpectralDist= 20*(log10(signal)-log10(noise));
SpectralDist(SpectralDist<0)=0;

Dist=mean(SpectralDist); 
if (Dist < NoiseMargin) 
    NoiseFlag=1; 
    NoiseCounter=NoiseCounter+1;
else
    NoiseFlag=0;
    NoiseCounter=0;
end

% Detect noise only periods and attenuate the signal     
if (NoiseCounter > Hangover) 
    SpeechFlag=0;    
else 
    SpeechFlag=1; 
end