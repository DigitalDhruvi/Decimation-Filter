v = load('chain_output.txt');
%Variables
fs = 256e6;           %Sampling frequency (Hz)
OSR = 128;           %Oversampling ratio
fb = fs/(2*OSR);    %Signal bandwidth
N = 2^16;           %Number of samples
t = (0:2*N)/fs;     %Time vector

%Input signal parameters
fin = (23*fs)/N;         %Input frequency (within signal band)
f_tone=fin;
x = 0.5*sin(2*pi*fin*t); %Input signal
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
