% =========================================================================
% --- Project Initialization ---
% =========================================================================
clc; % Clear the command window
clear; % Clear all variables from the workspace
close all; % Close any currently open figure windows

% =========================================================================
% --- 1. Variable and Signal Generation ---
% =========================================================================
fs = 100000; % Sampling frequency (100 kHz) to ensure smooth signal plots
t = 0:1/fs:0.002; % Time vector from 0 to 2 milliseconds
A = 4; % Amplitude 'A' set to 4 (from ID 253849)
f = 9000; % Frequency 'f' set to 9000 Hz (from ID 253849)

% Generate the three original clean signals
X1 = A * sin(2*pi*f*t); % Signal 1: Real Sine Wave
X2 = A * cos(2*pi*f*t); % Signal 2: Real Cosine Wave
X3 = A * exp(1j*2*pi*f*t); % Signal 3: Complex Exponential Wave

% Generate random noise signals
noise_amp = 2; % Amplitude multiplier for the noise
n1 = noise_amp * randn(size(t)); % Real white noise for X1
n2 = noise_amp * randn(size(t)); % Real white noise for X2
n3 = noise_amp * randn(size(t)) + 1j * noise_amp * randn(size(t)); % Complex white noise for X3

% Add noise to the original signals
X1_noisy = X1 + n1; % Noisy Signal 1
X2_noisy = X2 + n2; % Noisy Signal 2
X3_noisy = X3 + n3; % Noisy Signal 3

% =========================================================================
% --- 2. Multiple Filter Designs ---
% =========================================================================

% Filter 1 (for X1): IIR Peak Filter (Resonator)
% Specifically designed to resonate exactly at 9 kHz and reject everything else.
Wo = 9000 / (fs/2);  % Target peak frequency normalized to Nyquist
BW = 200 / (fs/2);   % Extremely tight bandwidth of just 200 Hz
[b1, a1] = iirpeak(Wo, BW); % Calculate filter coefficients
y1_filter = filtfilt(b1, a1, X1_noisy); % Apply zero-phase filtering to X1

% Filter 2 (for X2): Narrow Band Pass Filter 
% Cutoffs at 8.5 kHz and 9.5 kHz for aggressive noise rejection
Wn_narrow = [8500 9500] / (fs/2); % Normalize frequencies
[b2, a2] = butter(4, Wn_narrow, 'bandpass'); % 4th order Butterworth
y2_filter = filtfilt(b2, a2, X2_noisy); % Apply zero-phase filtering to X2

% Filter 3 (for X3): Standard Band Pass Filter 
% Cutoffs at 8 kHz and 10 kHz for standard noise rejection
Wn_standard = [8000 10000] / (fs/2); % Normalize frequencies
[b3, a3] = butter(4, Wn_standard, 'bandpass'); % 4th order Butterworth
y3_filter = filtfilt(b3, a3, X3_noisy); % Apply zero-phase filtering to X3

% =========================================================================
% --- 3. Fourier Transform Filtering Method ---
% =========================================================================
Y1_fft = fft(X1_noisy); % FFT of Noisy X1
Y2_fft = fft(X2_noisy); % FFT of Noisy X2
Y3_fft = fft(X3_noisy); % FFT of Noisy X3

N = length(t); % Number of samples
frequencies = (0:N-1)*(fs/N); % Frequency vector

% Create an ideal frequency mask keeping only the 8kHz to 10kHz band
mask = (frequencies >= 8000 & frequencies <= 10000) | (frequencies >= (fs-10000) & frequencies <= (fs-8000)); 

Y1_fft_filtered = Y1_fft .* mask; % Apply mask to X1
Y2_fft_filtered = Y2_fft .* mask; % Apply mask to X2
Y3_fft_filtered = Y3_fft .* mask; % Apply mask to X3

y1_fourier = real(ifft(Y1_fft_filtered)); % Inverse FFT for X1
y2_fourier = real(ifft(Y2_fft_filtered)); % Inverse FFT for X2
y3_fourier = ifft(Y3_fft_filtered); % Inverse FFT for X3 (Kept Complex)

% =========================================================================
% --- 4. Plotting: Time Domain & Frequency Domain ---
% =========================================================================

xlim_freq = [0 20000]; % Limit x-axis to 20 kHz to clearly see the 9 kHz peak

% Robust amplitude calculation for frequency spectrums
get_mag = @(sig) abs(fft(sig)/N) * 2; 
get_mag_complex = @(sig) abs(fft(sig)/N); 

% --- Figure 1: Original Clean Signals ---
figure('Name', 'Figure 1: Original Signals', 'Position', [50, 50, 1000, 850]);
subplot(4,2,1); plot(t, X1); title('Time: Orig X1'); xlabel('Time (s)'); grid on;
subplot(4,2,2); plot(frequencies, get_mag(X1)); title('Freq: Orig X1'); xlabel('Frequency (Hz)'); xlim(xlim_freq); grid on;
subplot(4,2,3); plot(t, X2); title('Time: Orig X2'); xlabel('Time (s)'); grid on;
subplot(4,2,4); plot(frequencies, get_mag(X2)); title('Freq: Orig X2'); xlabel('Frequency (Hz)'); xlim(xlim_freq); grid on;
subplot(4,2,5); plot(t, real(X3)); title('Time: Orig X3 (Real)'); xlabel('Time (s)'); grid on;
subplot(4,2,6); plot(t, imag(X3)); title('Time: Orig X3 (Imaginary)'); xlabel('Time (s)'); grid on;
subplot(4,2,7); plot(t, abs(X3)); title('Time: Orig X3 (Amplitude)'); xlabel('Time (s)'); ylim([0 6]); grid on;
subplot(4,2,8); plot(frequencies, get_mag_complex(X3)); title('Freq: Orig X3'); xlabel('Frequency (Hz)'); xlim(xlim_freq); grid on;

% --- Figure 2: RAW ISOLATED NOISE (n1, n2, n3) ---
figure('Name', 'Figure 2: Raw Isolated Noises', 'Position', [75, 75, 1000, 850]);
subplot(4,2,1); plot(t, n1); title('Time: Raw Noise n1'); xlabel('Time (s)'); grid on;
subplot(4,2,2); plot(frequencies, get_mag(n1)); title('Freq: Raw Noise n1'); xlabel('Frequency (Hz)'); xlim(xlim_freq); grid on;
subplot(4,2,3); plot(t, n2); title('Time: Raw Noise n2'); xlabel('Time (s)'); grid on;
subplot(4,2,4); plot(frequencies, get_mag(n2)); title('Freq: Raw Noise n2'); xlabel('Frequency (Hz)'); xlim(xlim_freq); grid on;
subplot(4,2,5); plot(t, real(n3)); title('Time: Raw Noise n3 (Real)'); xlabel('Time (s)'); grid on;
subplot(4,2,6); plot(t, imag(n3)); title('Time: Raw Noise n3 (Imag)'); xlabel('Time (s)'); grid on;
subplot(4,2,7); plot(t, abs(n3)); title('Time: Raw Noise n3 (Amplitude)'); xlabel('Time (s)'); ylim([0 10]); grid on;
subplot(4,2,8); plot(frequencies, get_mag_complex(n3)); title('Freq: Raw Noise n3'); xlabel('Frequency (Hz)'); xlim(xlim_freq); grid on;

% --- Figure 3: Noisy Signals (Signal + Noise) ---
figure('Name', 'Figure 3: Noisy Signals', 'Position', [100, 100, 1000, 850]);
subplot(4,2,1); plot(t, X1_noisy); title('Time: Noisy X1'); xlabel('Time (s)'); grid on;
subplot(4,2,2); plot(frequencies, get_mag(X1_noisy)); title('Freq: Noisy X1'); xlabel('Frequency (Hz)'); xlim(xlim_freq); grid on;
subplot(4,2,3); plot(t, X2_noisy); title('Time: Noisy X2'); xlabel('Time (s)'); grid on;
subplot(4,2,4); plot(frequencies, get_mag(X2_noisy)); title('Freq: Noisy X2'); xlabel('Frequency (Hz)'); xlim(xlim_freq); grid on;
subplot(4,2,5); plot(t, real(X3_noisy)); title('Time: Noisy X3 (Real)'); xlabel('Time (s)'); grid on;
subplot(4,2,6); plot(t, imag(X3_noisy)); title('Time: Noisy X3 (Imag)'); xlabel('Time (s)'); grid on;
subplot(4,2,7); plot(t, abs(X3_noisy)); title('Time: Noisy X3 (Amplitude)'); xlabel('Time (s)'); ylim([0 10]); grid on;
subplot(4,2,8); plot(frequencies, get_mag_complex(X3_noisy)); title('Freq: Noisy X3'); xlabel('Frequency (Hz)'); xlim(xlim_freq); grid on;

% --- Figure 4: Filter Outputs (Mixed Filters) ---
figure('Name', 'Figure 4: Filter Outputs', 'Position', [150, 150, 1000, 850]);
subplot(4,2,1); plot(t, y1_filter); title('Time: IIR Peak Filter X1'); xlabel('Time (s)'); grid on;
subplot(4,2,2); plot(frequencies, get_mag(y1_filter)); title('Freq: IIR Peak Filter X1'); xlabel('Frequency (Hz)'); xlim(xlim_freq); grid on;
subplot(4,2,3); plot(t, y2_filter); title('Time: Narrow BPF X2'); xlabel('Time (s)'); grid on;
subplot(4,2,4); plot(frequencies, get_mag(y2_filter)); title('Freq: Narrow BPF X2'); xlabel('Frequency (Hz)'); xlim(xlim_freq); grid on;
subplot(4,2,5); plot(t, real(y3_filter)); title('Time: Standard BPF X3 (Real)'); xlabel('Time (s)'); grid on;
subplot(4,2,6); plot(t, imag(y3_filter)); title('Time: Standard BPF X3 (Imag)'); xlabel('Time (s)'); grid on;
subplot(4,2,7); plot(t, abs(y3_filter)); title('Time: Standard BPF X3 (Amp)'); xlabel('Time (s)'); ylim([0 6]); grid on;
subplot(4,2,8); plot(frequencies, get_mag_complex(y3_filter)); title('Freq: Standard BPF X3'); xlabel('Frequency (Hz)'); xlim(xlim_freq); grid on;

% --- Figure 5: Fourier Filter Outputs ---
figure('Name', 'Figure 5: Fourier Filter Outputs', 'Position', [200, 200, 1000, 850]);
subplot(4,2,1); plot(t, y1_fourier); title('Time: Fourier X1'); xlabel('Time (s)'); grid on;
subplot(4,2,2); plot(frequencies, get_mag(y1_fourier)); title('Freq: Fourier X1'); xlabel('Frequency (Hz)'); xlim(xlim_freq); grid on;
subplot(4,2,3); plot(t, y2_fourier); title('Time: Fourier X2'); xlabel('Time (s)'); grid on;
subplot(4,2,4); plot(frequencies, get_mag(y2_fourier)); title('Freq: Fourier X2'); xlabel('Frequency (Hz)'); xlim(xlim_freq); grid on;
subplot(4,2,5); plot(t, real(y3_fourier)); title('Time: Fourier X3 (Real)'); xlabel('Time (s)'); grid on;
subplot(4,2,6); plot(t, imag(y3_fourier)); title('Time: Fourier X3 (Imag)'); xlabel('Time (s)'); grid on;
subplot(4,2,7); plot(t, abs(y3_fourier)); title('Time: Fourier X3 (Amplitude)'); xlabel('Time (s)'); ylim([0 6]); grid on;
subplot(4,2,8); plot(frequencies, get_mag_complex(y3_fourier)); title('Freq: Fourier X3'); xlabel('Frequency (Hz)'); xlim(xlim_freq); grid on;

% =========================================================================
% --- 5. PROOF OF SUCCESS: PEAKS & MINIMUMS ---
% =========================================================================

% 1. Calculate the Filter Responses (to get their max gain)
[h1, ~] = freqz(b1, a1, 4096, fs); 
[h2, ~] = freqz(b2, a2, 4096, fs); 
[h3, ~] = freqz(b3, a3, 4096, fs); 

% 2. Print the Proof to the Command Window
fprintf('\n======================================================\n');
fprintf('--- 1. FILTER DESIGN PROOF (Should peak at 1.00) ---\n');
fprintf('Filter 1 (IIR Peak) Max Gain: %.4f\n', max(abs(h1)));
fprintf('Filter 2 (Narrow BPF) Max Gain: %.4f\n', max(abs(h2)));
fprintf('Filter 3 (Standard BPF) Max Gain: %.4f\n', max(abs(h3)));
fprintf('------------------------------------------------------\n');

fprintf('--- 2. SIGNAL RECOVERY PROOF (Should recover to +/- 4.00) ---\n');
fprintf('X1 Original Peak: %5.2f  |  Filtered Peak: %5.2f\n', max(X1), max(y1_filter));
fprintf('X1 Original Min : %5.2f  |  Filtered Min : %5.2f\n', min(X1), min(y1_filter));
fprintf('------------------------------------------------------\n');
fprintf('X2 Original Peak: %5.2f  |  Filtered Peak: %5.2f\n', max(X2), max(y2_filter));
fprintf('X2 Original Min : %5.2f  |  Filtered Min : %5.2f\n', min(X2), min(y2_filter));
fprintf('------------------------------------------------------\n');
fprintf('X3 Original Amp : %5.2f  |  Filtered Amp : %5.2f\n', max(abs(X3)), max(abs(y3_filter)));
fprintf('======================================================\n\n');