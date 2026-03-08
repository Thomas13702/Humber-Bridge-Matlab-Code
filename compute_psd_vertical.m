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
[pxx, f] = pwelch(y, window_len, noverlap, nfft, Fs);

%% 4. Find Peaks (Top 3)
% Limit search to 0-0.5 Hz range as requested
idx_limit = f <= 0.5;
[pks, locs] = findpeaks(pxx(idx_limit), f(idx_limit), ...
                        'SortStr', 'descend', 'NPeaks', 3);

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
ylabel('Power/Frequency');
xlim([0 0.5]);
grid on;
legend('PSD Estimate', 'Resonant Peaks');