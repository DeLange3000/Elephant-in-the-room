clc
close all
clear


%% get audio device info

info = audiodevinfo; % contains the audio information of the device

%% recording settings

%channel 1 is DIY microphone
%channel 2 is measurement microphone

recDuration = 1; %seconds (duration of one recording)
sample_rate = 44000; % Hz
bit_rate = 24;
number_of_channels = 2; % 2 for stereo 1 for mono (can use one channel for reference and one channel for DIY mic in stereo)
audio_ID = 1; % select recording device (check in audiodevinfo)

%% distance measuring settings

noise_assesment_duration = 10; % seconds
calibration_distance = 70; % cm
calibration_duration = 20; % seconds
amount_of_measurements = 3; % how many measurements of measurement_duration, do you want to perform?
measuring_duration = 60; %seconds
measuring_frequency = 2000; %Hz
weight = 0.3; % takes weight*new value + (1-weighy)*previous values

%% audio setup

recObj = audiorecorder(sample_rate, bit_rate, number_of_channels, audio_ID) %set up adio device
Fs = recObj.SampleRate; % get samplerate


%% calibrate using known distance

disp('press key to calibrate')
pause;
disp('Calibrating...')
freqs = (0:sample_rate-1)*Fs/sample_rate; %calculates the frequency points of the fourier transform
i = 1;
cali_amplitudes_DIY = [];
cali_amplitudes_ref = [];
while freqs(i) < measuring_frequency % get the frequency you want to measure as an index for the fourier transform
    i = i + 1;
end

recordblocking(recObj,recDuration); %record audio
recording = getaudiodata(recObj); % get the audio as data
freq_transf_DIY = abs(fft(recording(:,1), Fs)); % perform fourier transform and get amplitude
freq_transf_ref = abs(fft(recording(:,2), Fs));
avg_signal_amplitude_DIY = freq_transf_DIY(i); % set first value of the moving average as the first measured value
avg_signal_amplitude_ref = freq_transf_ref(i);
cali_amplitudes_DIY = [cali_amplitudes_DIY avg_signal_amplitude_DIY]; % add this value to the weighted results
cali_amplitudes_ref = [cali_amplitudes_ref avg_signal_amplitude_ref];

for j = 1:calibration_duration
    fprintf(j+" out of "+calibration_duration+"\n")
    recordblocking(recObj,recDuration); % record audio 
    recording = getaudiodata(recObj); % get audio data
    freq_transf_DIY = abs(fft(recording(:, 1), Fs)); % perform fourier transform and get amplitude
    freq_transf_ref = abs(fft(recording(:, 2), Fs));
    avg_signal_amplitude_DIY = weight*freq_transf_DIY(i) + (1-weight)*avg_signal_amplitude_DIY; % use moving average to get average amplitude
    avg_signal_amplitude_ref = weight*freq_transf_ref(i) + (1-weight)*avg_signal_amplitude_ref;
    cali_amplitudes_DIY = [cali_amplitudes_DIY avg_signal_amplitude_DIY]; % add this value to the weighted results
    cali_amplitudes_ref = [cali_amplitudes_ref avg_signal_amplitude_ref];
end

disp('Calbirating done!')

%% 

% plots calibration in function of the amount of measurements
figure
hold on
title('Calibration of signal')
plot(cali_amplitudes_DIY)
hold on
plot(cali_amplitudes_ref)
xlabel('number of calibrations')
ylabel('amplitude')
legend("DIY", "ref")

% take last measured value including the moving average as the calibration
% value
cali_amp_DIY = avg_signal_amplitude_DIY; 
cali_amp_ref = avg_signal_amplitude_ref;


%% determine distance

disp('press key to determine distance')
pause;
disp('Measuring distance...')
signal_amplitudes_DIY = [];
signal_amplitudes_ref = [];
distances_DIY = [];
distances_ref = [];
for a = 1:amount_of_measurements
    avg_signal_amplitude_DIY = 0; % set moving average to zero
    avg_signal_amplitude_ref = 0;
    for j = 1:measuring_duration
        recordblocking(recObj,recDuration); % record audio
        recording = getaudiodata(recObj); % get audio data
        freq_transf_DIY = abs(fft(recording(:, 1), Fs));  % perform fourier transform and get amplitude
        freq_transf_ref = abs(fft(recording(:, 2), Fs));
        if j == 1
            avg_signal_amplitude_DIY = freq_transf_DIY(i); % set first value of measurements as moving average
            avg_signal_amplitude_ref = freq_transf_ref(i);
        else
            avg_signal_amplitude_DIY = weight*freq_transf_DIY(i) + (1-weight)*avg_signal_amplitude_DIY;  % use moving average to get average amplitude
            avg_signal_amplitude_ref = weight*freq_transf_ref(i) + (1-weight)*avg_signal_amplitude_ref;
        end
        A_DIY = avg_signal_amplitude_DIY/cali_amp_DIY; % get ratio of measured amplitude to calibrated amplitude
        A_ref = avg_signal_amplitude_ref/cali_amp_ref;
        signal_amplitudes_DIY = [signal_amplitudes_DIY avg_signal_amplitude_DIY]; % store measured amplitude
        signal_amplitudes_ref = [signal_amplitudes_ref avg_signal_amplitude_ref];
        distance_DIY = calibration_distance/A_DIY; % calculate distance
        distance_ref = calibration_distance/A_ref; 
        fprintf("distance (DIY) = "+distance_DIY+ " cm        ("+j+" out of "+measuring_duration+")\n")
        fprintf("distance (ref) = "+distance_ref+ " cm        ("+j+" out of "+measuring_duration+")\n")
        distances_DIY = [distances_DIY distance_DIY]; % store distance values
        distances_ref = [distances_ref distance_ref];
    end
    if a < amount_of_measurements
        disp('press key to determine new distance') % measurement is interrupted so source can be set at a new distance
    end
   pause;
end

%% plot

% plots amplitude of signals
figure
plot(1000*signal_amplitudes_DIY) % factor 1000 is here so it has around the same amplitude as the measurement mic
hold on
plot(signal_amplitudes_ref)
xlabel('number of measurements')
ylabel('amplitude')
legend('DIY', 'Ref')

% plots distance of signals
figure
plot(distances_DIY)
hold on
plot(distances_ref)
xlabel('number of measurements')
ylabel('distance (cm)')
legend('DIY', 'Ref')

