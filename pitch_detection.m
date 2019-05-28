
%% Signal Definition

[file, path] = uigetfile('*.wav', 'Select a wave file');
nameoffile = fullfile(path,file);

[y,fs] = audioread(nameoffile);
y = y(:,1);
y = y(fix(10*fs):fix(20*fs));

%% Frames and Windows

frame_size=20;
frame_shift=10;
window_length=(frame_size/1000)*fs;
sample_shift=(frame_shift/1000)*fs;
no_of_windows = (floor((length(y))/sample_shift)-ceil(window_length/sample_shift));
f0=zeros(1,no_of_windows);
maxamp = 0;
flag_y= envelop_hilbert(y);

%% Autocorrelation

for i=1: no_of_windows
    
    sig = y(i*sample_shift:(i*sample_shift)+window_length);
    thres = flag_y(i*sample_shift:(i*sample_shift)+window_length);
    activity_flag = max(abs(thres));    
    
    if activity_flag == 1                     % discarding low amplitude freq
        cor = xcorr(sig);
        [pks,locs] = findpeaks(cor);
        [midval, midloc] = max(pks);
        [maxval,maxloc] = max(pks(midloc+1:end));
        
        if isequal(maxval,maxloc)
            f0(i) = 0;
        else
            period = (abs(locs(midloc)-locs(maxloc+midloc)));
            f0(i) = fs / period;
        end
    else
        f0(i) = 0;
    end
    
end

v = f0 .* 4.0526e-2;

%% plots
t=1/fs:1/fs:(length(y)/fs);

[peaks,locs] = findpeaks(f0,'MinpeakHeight',0.5*max(f0),'MinPeakDistance',50);ylim([0 1200]);xlim([0 2000]);

plot(1:no_of_windows,f0*4.0526e-2,locs,peaks*4.0526e-2,'o');title('Pitch of each window');ylabel('Velocity (cm/s)');xlabel('Windows');
ylim([0 100]);
g = zoom;
g.enable = 'on';
set(gcf, 'Position', get(0,'Screensize'));

max_velocity = max(peaks)*4.0526e-2;
Velocity = mean(peaks)*4.0526e-2;

fprintf('\nMax Systolic Peak Velocity     = %.2f cm/s\n',max_velocity);
fprintf('\nAverage Systolic Peak Velocity = %.2f cm/s\n\n',Velocity);
