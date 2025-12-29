
v = load('/Users/dhruviagrawal/Desktop/VS14/cic_output.txt');
%v=v/(max(abs(v)));
v1 = load('/Users/dhruviagrawal/Desktop/VS14/hbf1_output.txt');
%v1=v1/max(abs(v1));
v2 = load('/Users/dhruviagrawal/Desktop/VS14/hbf2_output.txt');
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
%% PSD after SINC + decimation
delay1=14;
factor1=32;
[Pxx, fxx] = pwelch(v(1+delay1:N/factor1+delay1),hanning(N/factor1,'periodic'),1, N/factor1, fs/factor1, 'onesided');
Pxx_dB = 10*log10(abs(Pxx));
% Find bin closest to one
[~, tone_idx_cic] = min(abs(fxx - f_tone));
semilogx(Pxx_dB,'black');
hold on;
% SNR 
signal_bins_cic = Pxx(tone_idx_cic-1:tone_idx_cic+1);
noise_bins_cic = [Pxx(3:tone_idx_cic-2); Pxx(tone_idx_cic+2:256)];
snr_sinc_dB = 10*log10(sum(signal_bins_cic) / sum(noise_bins_cic));
fprintf('Estimated output SNR after SINC = %.2f dB\n', snr_sinc_dB);

%% PSD after hbf1 
delay2=9;
factor2 = 64;
[Pyy, fyy] = pwelch(v1(1+delay2:N/factor2+delay2),hanning(N/factor2,'periodic'),1, N/factor2, fs/factor2, 'onesided');
Pyy_dB = 10*log10(abs(Pyy));
[~, tone_idx_hbf1] = min(abs(fyy - f_tone));
semilogx(Pyy_dB,'r'); 
hold on;
%SNR
signal_bins_hbf1 = Pyy(tone_idx_hbf1-1:tone_idx_hbf1+1);
noise_bins_hbf1 = [Pyy(3:tone_idx_hbf1-2); Pyy(tone_idx_hbf1+2:256)];
snr_hbf1_dB = 10*log10(sum(signal_bins_hbf1) / sum(noise_bins_hbf1));
fprintf('Estimated output SNR after hbf1 = %.2f dB\n', snr_hbf1_dB);

%% PSD after hbf2 
delay3=6;
factor3 = 64*2;
[Pzz, fzz] = pwelch(v2(1+delay3:N/factor3+delay3),hanning(N/factor3,'periodic'),1, N/factor3, fs/factor3, 'onesided');
Pzz_dB = 10*log10(abs(Pzz));
[~, tone_idx_hbf2] = min(abs(fzz - f_tone));
semilogx(Pzz_dB,'blue'); 
hold off;
%SNR
signal_bins_hbf2 = Pzz(tone_idx_hbf2-1:tone_idx_hbf2+1);
noise_bins_hbf2 = [Pzz(3:tone_idx_hbf2-2); Pzz(tone_idx_hbf1+2:256)];
snr_hbf2_dB = 10*log10(sum(signal_bins_hbf2) / sum(noise_bins_hbf2));
fprintf('Estimated output SNR after hbf2 = %.2f dB\n', snr_hbf2_dB);

%xlabel('Frequency (Hz)'); ylabel('Power (dB)');
%title('PSD with tone marker');
legend('SINC Output', 'HBF1 Output', 'HBF2 Output');