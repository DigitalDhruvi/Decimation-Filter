% Creating a Delta-Sigma Modulator and Filter Chain for the given specs:
% Bandwidth = 2MHz
% Oversampling ratio = 128
% sampling frequency 256MHz 
% SNR should be atleast 90dB
% Droop < 1dB 
% Engineer: Dhruvi A
% Date: 30/12/25

% Your Variable Values according to specification
fs = %Sampling frequency (Hz) ;
OSR = %Oversampling ratio ;
fb = %Signal bandwidth ;
N = %Number of samples ;
t = %Time vector ;

%Input signal parameters
fin = %Input frequency (within signal band);

x = %Input signal;
ntf=synthesizeNTF(4,128,0,1.5,0);
[a,g,b,c] = realizeNTF(ntf,'CRFB');
ABCD = stuffABCD(a,g,b,c,'CRFB');
v=simulateDSM(x,ABCD);
fid = fopen('dsm_data_out.txt','w');
fprintf(fid,'%d\n',v);

writematrix(v','dsm_output.txt');
%Power spectral density
[Pxx, f] = pwelch(v, hanning(N,'periodic'),1, N, fs, 'onesided');
Pxx_dB = 10*log10(Pxx);
%semilogx(f, Pxx_dB, 'b-', 'LineWidth', 1);
figure;
plot(f, Pxx_dB); grid on;
xlabel('Frequency (Hz)');
ylabel('PSD (dB)')
% Find bin closest to tone
f_tone=fin;
[~, tone_idx] = min(abs(f - f_tone));
signal_bins = Pxx(tone_idx-1:tone_idx+1);
noise_bins = [Pxx(2:tone_idx-2); Pxx(tone_idx+2:256)];

snr_dB = 10*log10(sum(signal_bins) / sum(noise_bins));
fprintf('Estimated output SNR of DSM = %.2f dB\n', snr_dB);

%% SINC filter definition
z = tf('z',1);
H1=1+z^-1+z^-2+z^-3+z^-4+z^-5+z^-6+z^-7+z^-8+z^-9+z^-10+z^-11+z^-12+z^-13+z^-14+z^-15+z^-16+z^-17+z^-18+z^-19+z^-20+z^-21+z^-22+z^-23+z^-24+z^-25+z^-26+z^-27+z^-28+z^-29+z^-30+z^-31;
% Implemented as an FIR filter and not as Hogenour structure due to IIR
% characteristic
Hsinc = H1^5;
[B1,A1] = tfdata(Hsinc,'v');
% SINC filter frequency response
[HB0,W0] = freqz(B1,A1,N);
figure;
plot(W0,20*log10(abs(HB0)),'linewidth',2);
title('SINC filter');

%Filtering the data and decimation by 32
Y1 = filter(B1,A1,v);
Y1_d = Y1(1:32:length(Y1));

% PSD after SINC + decimation
[Pyy, fyy] = pwelch(Y1_d, hanning(N/32,'periodic'),1, N/32, fs/32, 'onesided');
%Pyy_dB = 10*log10(Pyy*0.73*(length(Y1_d))/(32768*N/32));
Pyy_dB = 10*log10(Pyy) - 10*log10(max(Pyy));

% Find bin closest to tone
[~, tone_idx_d] = min(abs(fyy - f_tone));
signal_bins_d = Pyy(tone_idx_d-1:tone_idx_d+1);
noise_bins_d = [Pyy(2:tone_idx_d-2); Pyy(tone_idx_d+2:256)];

snr_sinc_dB = 10*log10(sum(signal_bins_d) / sum(noise_bins_d));
fprintf('Estimated output SNR after SINC = %.2f dB\n', snr_sinc_dB);

%% HFB1 filter definition
% First halfband filter
% Note - If I use a 6th order halfband filter, the SNR degradation is >2dB
% for any value of attenuation. So I went for 10th order. Also if the
% passband ripple should be <0.05dB then stop-band attenuation had to be
% increased to atleast 50dB

B2 = designHalfbandFIR(FilterOrder=10,TransitionWidth=0.3,DesignMethod="equiripple");
A2 = zeros(1,length(B2));
A2(1) = 1;

% Half-band filter-1 frequency response
[HB1,W1] = freqz(B2,A2,N);
figure;
plot(W1,20*log10(abs(HB1)),'linewidth',2);
title('First Half-band filter');

%Filtering the data and decimation by 2
Y2 = filter(B2,A2,Y1_d);
Y2_d = Y2(1:2:length(Y2));

%Spectrum of decimated signal
%Y2_d_f = 10*log10(pwelch(Y2_d(end-255:end),hann(256,'periodic')));  %Signal bin - 19 (+1)

% PSD after HBF1
[Ph1, fh1] = pwelch(Y2_d, hanning(N/64,'periodic'),1, N/64, fs/64, 'onesided');
Ph1_dB = 10*log10(Ph1) - 10*log10(max(Ph1));
% Find bin closest to tone
[~, tone_idx_h1] = min(abs(fh1 - f_tone));
signal_bins_h1 = Ph1(tone_idx_h1-1:tone_idx_h1+1);
noise_bins_h1 = [Ph1(2:tone_idx_h1-2); Ph1(tone_idx_h1+2:256)];

snr_h1_dB = 10*log10(sum(signal_bins_h1) / sum(noise_bins_h1));
fprintf('Estimated output SNR after HBF1 = %.2f dB\n', snr_h1_dB);

%% HBF2
B3 = designHalfbandFIR(FilterOrder=6,TransitionWidth=0.3,DesignMethod="equiripple");
A3 = zeros(1,length(B3));
A3(1) = 1;
% Half-band filter-2 frequency response
[HB2,W2] = freqz(B3,A3,N);
figure;
plot(W2,20*log10(abs(HB2)),'linewidth',2);
title('Second Half-band filter');

%Filtering the data and decimation by 2
Y3 = filter(B3,A3,Y2_d);
Y3_d = Y3(1:2:length(Y3));

%Spectrum of decimated signal
%Y2_d_f = 10*log10(pwelch(Y2_d(end-255:end),hann(256,'periodic')));  %Signal bin - 19 (+1)

% PSD after HBF2
[Ph2, fh2] = pwelch(Y3_d, hanning(N/128,'periodic'),1, N/128, fs/128, 'onesided');
Ph2_dB = 10*log10(Ph2) - 10*log10(max(Ph2));
% Find bin closest to tone
[~, tone_idx_h2] = min(abs(fh2 - f_tone));
signal_bins_h2 = Ph2(tone_idx_h2-1:tone_idx_h2+1);
noise_bins_h2 = [Ph2(3:tone_idx_h2-2); Ph2(tone_idx_h2+2:256)];

snr_h2_dB = 10*log10(sum(signal_bins_h2) / sum(noise_bins_h2));
fprintf('Estimated output SNR after HBF2 = %.2f dB\n', snr_h2_dB);

%% Calculation of droop
% === Calculate passband droop for HBF1===
% Magnitude response
mag = abs(HB1);

% Passband edge: in filter (normalized relative to Nyquist)
Fpass = 0.2*pi; 

% Gain at DC
gain_DC = mag(1);
Fb = 1e6;  % 1 MHz signal bandwidth edge
Fb_norm = Fb / (fs/2);  % normalized to Nyquist
% Gain at passband edge
[~, idx_edge] = min(abs(W1/pi - Fb_norm));
gain_edge = mag(idx_edge);

% Droop in dB
droop_dB = 20*log10(gain_DC / gain_edge);

fprintf('Passband droop for HBF1 = %.5f dB\n', droop_dB);

% === Calculate passband droop for HBF2===
% Magnitude response
mag2 = abs(HB2);

% Gain at DC
gain_DC2 = mag2(1);
Fb = 1e6;  % 1 MHz signal bandwidth edge
Fb_norm = Fb / (fs/2);  % normalized to Nyquist

% Gain at passband edge
[~, idx_edge2] = min(abs(W2/pi - Fb_norm));
gain_edge2 = mag2(idx_edge2);

% Droop in dB
droop_dB2 = 20*log10(gain_DC2 / gain_edge2);

fprintf('Passband droop for HBF2 = %.5f dB\n', droop_dB2);

figure;

semilogx(Pyy_dB); grid on;
hold on;

semilogx(Ph1_dB); grid on;
hold on; 

semilogx(Ph2_dB); grid on;
hold off; 

xlabel('Frequency (Hz)'); ylabel('Power (dB)');
title('FILTER RESPONSE');
legend('SINC Output', 'HBF1 Output', 'HBF2 Output');
