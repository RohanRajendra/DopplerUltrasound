[file, path] = uigetfile('*.wav', 'Select a wave file');
nameoffile = fullfile(path,file);

type = 0; % 1- hand, 0- col;
audio = 0; %play audio, '1' : yes | '0' : no
filter = 1;  %Wiener Filter, '1' : yes | '0' : no

[signal,fs] = audioread(nameoffile);
signal = signal(:,1);
time = 0:1/fs:(length(signal)-1)/fs;

if audio
sound(signal,fs)
end

figure;
plot(time, signal);
xlabel('Time (s)');ylabel('Amplitude');
set(gcf, 'Position', get(0,'Screensize'));

if filter
[filtered,Time] = Wiener(signal,fs,type);   %Wiener Filter

figure();
plot(Time,filtered);
xlabel('Time (s)');ylabel('Amplitude');
set(gcf, 'Position', get(0,'Screensize'));

[filename,pathname,index] = uiputfile(strcat('filtr_',file));
savefile = fullfile(pathname,filename);
audiowrite(savefile,filtered,fs)

end