%% Operational Modal Analysis (OMA) - Humber Bridge
% Identifies fundamental vertical mode and phase relationship between sensors.

clear; clc; close all;

%% 1. Load Data
filename = 'humberdefs_20121125_dsa.mat';

% Check for file in likely locations
if exist(filename, 'file')
    load(filename);
elseif exist(fullfile('CW1-data', filename), 'file')
    load(fullfile('CW1-data', filename));
elseif exist(fullfile('..', 'CW1-data', filename), 'file')
    load(fullfile('..', 'CW1-data', filename));
else
    error('File %s not found. Please ensure the data file is in the path.', filename);
end

%% 2. Extract Data
% Handle variable mapping (D.data, tdata, or accs)
if exist('D', 'var') && isfield(D, 'data')
    data = D.data;
elseif exist('tdata', 'var')
    data = tdata;
    if size(data, 1) < size(data, 2), data = data'; end
elseif exist('accs', 'var')
    data = accs;
else
    error('Data variable not found in workspace.');
end

% Extract Channels (15 and 16)
if size(data, 2) < 16
    error('Data matrix has fewer than 16 columns. Cannot extract VERT1/VERT2.');
end

vert1 = data(:, 15); % Sensor 1 (D.VERT1)
vert2 = data(:, 16); % Sensor 2 (D.VERT2)

% Remove NaNs and Detrend (remove static offset)
valid_idx = ~isnan(vert1) & ~isnan(vert2);
vert1 = detrend(vert1(valid_idx), 'constant');
vert2 = detrend(vert2(valid_idx), 'constant');

%% 3. Signal Processing (Frequency Domain)
Fs = 1;             % Sampling Frequency (Hz)
window = 2048;      % Window length for pwelch
noverlap = 1024;    % 50% overlap
nfft = 2048;        % FFT points

% PSD of Sensor 1
[pxx, f] = pwelch(vert1, window, noverlap, nfft, Fs);

% Find Fundamental Frequency (Max Peak)
% Limit search to 0.05 - 0.5 Hz to avoid DC/low freq noise
idx_search = f > 0.05 & f <= 0.5;
[pks, locs] = findpeaks(pxx(idx_search), f(idx_search), 'SortStr', 'descend', 'NPeaks', 1);

if isempty(pks)
    error('No peaks found in the specified frequency range.');
end

f_peak = locs(1);
peak_power = pks(1);

fprintf('Fundamental Frequency Identified: %.3f Hz\n', f_peak);

%% 4. Cross-Spectral Analysis (Phase)
[pxy, f_cpsd] = cpsd(vert1, vert2, window, noverlap, nfft, Fs);

% Find index of peak frequency in CPSD vector
[~, idx_peak] = min(abs(f_cpsd - f_peak));

% Calculate Phase Difference at Peak
phase_rad = angle(pxy(idx_peak));
phase_deg = rad2deg(phase_rad);

fprintf('Phase Difference at %.3f Hz: %.2f degrees\n', f_peak, phase_deg);

%% 5. Visualization
figure('Name', 'OMA: Fundamental Mode & Phase', 'Color', 'w', 'Position', [100, 100, 1000, 500]);

% Subplot 1: PSD Spectrum
subplot(1, 2, 1);
plot(f, 10*log10(pxx), 'b', 'LineWidth', 1.5); hold on;
plot(f_peak, 10*log10(peak_power), 'ro', 'MarkerFaceColor', 'r');
title('Power Spectral Density (Identifying Fundamental Mode)');
xlabel('Frequency (Hz)');
ylabel('Power/Frequency (dB/Hz)');
xlim([0 0.5]);
grid on;
text(f_peak, 10*log10(peak_power), sprintf('  %.3f Hz', f_peak), 'VerticalAlignment', 'bottom');

% Subplot 2: Phase Bar Chart
subplot(1, 2, 2);
bar_data = [0, phase_deg];
b = bar(bar_data);
b.FaceColor = 'flat';
b.CData(1,:) = [0 0.4470 0.7410]; % Blue (Ref)
b.CData(2,:) = [0.8500 0.3250 0.0980]; % Red (Relative)

title('Relative Phase at Fundamental Frequency');
ylabel('Phase Angle (Degrees)');
set(gca, 'XTickLabel', {'Sensor 1 (Ref)', 'Sensor 2'});
ylim([-180 180]);
grid on;

% Determine Mode Type
if abs(phase_deg) < 45
    mode_type = 'In-Phase (Vertical Bending)';
elseif abs(abs(phase_deg) - 180) < 45
    mode_type = 'Out-of-Phase (Torsional)';
else
    mode_type = 'Complex/Coupled Mode';
end

text(1.5, phase_deg + sign(phase_deg)*20, sprintf('%.1f°\n%s', phase_deg, mode_type), ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold');