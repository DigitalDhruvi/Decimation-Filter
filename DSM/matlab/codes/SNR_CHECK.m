%% MATLAB Code to generate DSM Output int he form of -1 and 1s 
%% Followed by 3 cascaded filters and calculating Power Spectral Density
%% And calculation of SNR 
% Engineer: Dhruvi A
% Date: July 2025
v = load('chain_output.txt');
%Variables
fs =  %Sampling frequency (Hz)
OSR = %Oversampling ratio
fb = %Signal bandwidth
N = %Number of samples
t = %Time vector

%Input signal parameters
fin = %Input frequency (within signal band)
f_tone=fin;
x = %Input signal
%% PSD after Filter + decimation
delay=20;
[Pxx, fxx] = pwelch(v(1+delay:N/OSR+delay),hanning(N/OSR,'periodic'),1, N/OSR, fs/OSR, 'onesided');
Pxx_dB = 10*log10(abs(Pxx));
% Find bin closest to one
[~, tone_idx_cic] = min(abs(fxx - f_tone));
semilogx(Pxx_dB);
hold on;
% SNR 
signal_bins_cic = Pxx(tone_idx_cic-1:tone_idx_cic+1);
noise_bins_cic = [Pxx(3:tone_idx_cic-2); Pxx(tone_idx_cic+2:256)];
snr_sinc_dB = 10*log10(sum(signal_bins_cic) / sum(noise_bins_cic));
fprintf('Estimated output SNR after filtering and decimation = %.2f dB\n', snr_sinc_dB);
