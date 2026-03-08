%% Compute PSD for Vertical Acceleration (Channel 16)
% This script calculates the Power Spectral Density of the vertical
% acceleration data to identify natural frequencies.

% Check for data existence
if ~exist('D', 'var') && ~exist('tdata', 'var') && ~exist('accs', 'var')
    filename = 'humberdefs_20121125_dsa.mat';
    if exist(filename, 'file')
        load(filename);
    elseif exist(fullfile('CW1-data', filename), 'file')
        load(fullfile('CW1-data', filename));
    elseif exist(fullfile('..', 'CW1-data', filename), 'file')
        load(fullfile('..', 'CW1-data', filename));
    else
        error('Data file %s not found. Please ensure data is loaded.', filename);
    end
end

% Map available data to D.data
if exist('tdata', 'var')
    if size(tdata, 1) < size(tdata, 2) && size(tdata, 1) <= 20
        tdata = tdata';
    end
    D.data = tdata;
elseif exist('accs', 'var')
    D.data = accs;
elseif exist('D', 'var') && isfield(D, 'accs') && ~isfield(D, 'data')
    D.data = D.accs;
end

if ~exist('D', 'var') || ~isfield(D, 'data')
    error('Variable D.data (or tdata/accs) not found in workspace.');
end

%% 1. Parameters
Fs = 1;             % Sampling Frequency (Hz)
if exist('fs', 'var'), Fs = fs; end
target_col = 16;    % Channel 16: D.VERT2 (g)

% pwelch settings
window_len = 2048;  % Window length (higher = better freq resolution)
noverlap = 1024;    % 50% overlap
nfft = 2048;        % FFT points

%% 2. Extract and Preprocess Data
% Check dimensions
if size(D.data, 2) < target_col
    error('Data matrix has fewer than %d columns.', target_col);
end

y = D.data(:, target_col);

% Remove NaNs and Detrend (remove static offset)
y(isnan(y)) = [];
y = detrend(y, 'constant');

%% 3. Compute PSD
% [pxx, f] = pwelch(y, window_len, noverlap, nfft, Fs); % This requires Signal Processing Toolbox

% --- Manual Welch's Method Implementation ---
fprintf("Signal Processing Toolbox not found. Using manual Welch's method...\n");

% 1. Define window
win = 0.5 * (1 - cos(2 * pi * (0:window_len-1)' / (window_len-1))); % Hann window

% 2. Get segment start indices
step = window_len - noverlap;
indices = 1:step:(length(y) - window_len + 1);

% 3. Calculate number of segments and initialize
num_segments = length(indices);
psd_sum = zeros(nfft, 1);

% 4. Process each segment
for i = 1:num_segments
    segment = y(indices(i) : indices(i) + window_len - 1);
    windowed_segment = segment .* win;
    X = fft(windowed_segment, nfft);
    psd_segment = (abs(X).^2) / (Fs * sum(win.^2));
    psd_sum = psd_sum + psd_segment;
end

% 5. Average the PSDs and create one-sided spectrum
pxx = psd_sum / num_segments;
pxx(2:nfft/2) = 2 * pxx(2:nfft/2);
pxx = pxx(1:nfft/2 + 1);

% 6. Create frequency vector
f = (0:nfft/2)' * Fs / nfft;
% --- End of Manual Implementation ---

%% 4. Find Peaks (Top 3)
% Limit search to 0-0.5 Hz range as requested
idx_limit = f <= 0.5;
% [pks, locs] = findpeaks(...) % This requires Signal Processing Toolbox

% --- Manual Peak Finding ---
f_search = f(idx_limit);
pxx_search = pxx(idx_limit);
is_peak = pxx_search > [0; pxx_search(1:end-1)] & pxx_search > [pxx_search(2:end); 0];
[sorted_pks, sort_idx] = sort(pxx_search(is_peak), 'descend');
sorted_locs = f_search(is_peak);
sorted_locs = sorted_locs(sort_idx);
num_peaks_to_find = min(3, length(sorted_pks));
pks = sorted_pks(1:num_peaks_to_find);
locs = sorted_locs(1:num_peaks_to_find);
% --- End of Manual Peak Finding ---

%% 5. Plot Results
figure('Name', 'PSD Vertical Acceleration', 'Color', 'w');
plot(f, pxx, 'b', 'LineWidth', 1.5);
hold on;

% Mark and Label the peaks
plot(locs, pks, 'rv', 'MarkerFaceColor', 'r');
for i = 1:length(locs)
    text(locs(i), pks(i), sprintf(' %.3f Hz', locs(i)), ...
         'VerticalAlignment', 'bottom', 'FontWeight', 'bold');
end

title('Vertical Natural Frequencies of Humber Bridge');
xlabel('Frequency (Hz)');
ylabel('Power/Frequency (g^2/Hz)');
xlim([0 0.5]);
grid on;
legend('PSD Estimate', 'Resonant Peaks');