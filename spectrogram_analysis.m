[file, path] = uigetfile('*.wav', 'Select a wave file');
nameoffile = fullfile(path,file);

[signal,fs] = audioread(nameoffile);
signal = signal(:,1);

velocity = 1; %Average Peak Systolic Velocity, '1' : yes | '0' : no

type = 'velocity';      %'freq' or 'velocity' on y-axis

time = 5;               %plot for specific time period (in seconds)
t=1:fix(time*fs);
%signal=signal(t);

frame = 21.3;             %size for spectrogram (ms)

s_length = length(signal);
sampleTime = ( 1:s_length )/fs;
frameSize = fix(frame*0.001*fs);

figure()

if ( strcmp(type, 'freq') )
        [B,f,T] = spectrogram(signal,hanning(frameSize),round(frameSize/2),frameSize*2,fs);
        B = 20*log10(abs(B));
        imagesc(T,f,B);axis xy;colorbar;ylim([0 5000]);caxis([-25 25]);%datacursormode on;
        t=colormap(gray);
        colormap(1-t);
        h = zoom;
        h.motion = 'horizontal';
        h.enable = 'on';
        xlabel('Time (s)');ylabel('Frequency (Hz)'); 
end

if ( strcmp(type, 'velocity') )
        [B,f,T] = spectrogram(signal,hann(frameSize),round(frameSize/2),frameSize*2,fs);
        B = 20*log10(abs(B));
        v = f*0.040526;
        imagesc(T,v,B);axis xy;ylim([0 100]);colorbar;caxis([-25 25]);
        t=colormap(gray);
        colormap(1-t);
        g = zoom;
        g.motion = 'horizontal';
        g.enable = 'on';
        xlabel('Time (s)');ylabel('Velocity (cm/s)');
end

set(gcf, 'Position', get(0,'Screensize'));

if velocity
    
[a,b] = find(B>-5);
vel = v(a);
Time = T(b);

[p,loc] = findpeaks(vel,'MinPeakHeight',0.7*max(vel),'MinPeakDistance',500);

figure()
plot(Time,vel,Time(loc),p,'o');xlabel('Time (s)');ylabel('velocity (cm/s)');ylim([0 0.040526*4000]);
set(gcf, 'Position', get(0,'Screensize'));

max_velocity = max(p);
Velocity = mean(p);

fprintf('\nMax Systolic Peak Velocity     = %.2f cm/s\n',max_velocity);
fprintf('\nAverage Systolic Peak Velocity = %.2f cm/s\n\n',Velocity);

end