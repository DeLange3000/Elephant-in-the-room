clc
close all
clear

%% get audio device info

info = audiodevinfo; % get audio device info

%% recording settings

%channel 1 is DIY microphone
%channel 2 is measurement microphone

recDuration = 40; %seconds
filename = '500cm_2000Mhz_test2.wav'; % name of file where you save the wav to
sample_rate = 44100; % Hz
bit_rate = 24;
number_of_channels = 2;  % 2 for stereo 1 for mono (can use one channel for reference and one channel for DIY mic in stereo)
audio_ID = 1; % select recording device (check in audiodevinfo)

%% audio setup

recObj = audiorecorder(sample_rate, bit_rate, number_of_channels, audio_ID)  %set up adio device

%% start recording

disp("Recording started.")
recordblocking(recObj,recDuration); % record
recording = getaudiodata(recObj); % get audio data
disp("End of recording.")

%% amplify DIY microphone

recording(: ,1) = recording(:,1)*1000; % amplify diy mic to get around the same amplitude as the measurement microphone

%% plot output

%recording = audioread('40_cm_1000Mhz.wav'); %uncomment this if you want to plot data from other recording

%time domain
figure
title('Recording in time domain')
Fs = recObj.SampleRate; % get sample rate from audio device
x = linspace(0, 5, length(recording)); % get time axis
plot(x ,recording)
xlabel('time (s)')
ylabel('amplitude')
legend('DIY mincrophone', 'measurement microphone')

%frequency domain
figure
title('Recording in frequency domain')
freq_transf = abs(fft(recording, Fs));
freqs = (0:length(freq_transf)-1)*Fs/length(freq_transf); % get frequency axis
hold on
stem(freqs(1000:length(freqs)/2), freq_transf(1000:length(freqs)/2, 1)) % plots first half of values (other half is just mirrored)
stem(freqs(1000:length(freqs)/2), freq_transf(1000:length(freqs)/2, 2))
xlabel('frequency (Hz)')
ylabel('Amplitude')
legend('DIY mincrophone', 'measurement microphone')

%% save recording

% write recording to a wav file
audiowrite(filename,recording,Fs)
disp('File has been made.')


