%% Wind Rose Analysis
% Visualizes wind speed and direction for the long-term summary data 
% and the specific storm event (Nov 25, 2012) using detailed data.

clear; clc; close all;

%% 1. Load Long-Term Summary Data
filename_summary = 'h_summaries20160405_simple.mat';
if exist(filename_summary, 'file')
    load(filename_summary);
elseif exist(fullfile('CW1-data', filename_summary), 'file')
    load(fullfile('CW1-data', filename_summary));
elseif exist(fullfile('..', 'CW1-data', filename_summary), 'file')
    load(fullfile('..', 'CW1-data', filename_summary));
else
    error('Summary file %s not found.', filename_summary);
end

% Clean data
data(data == -999) = NaN;

% Extract Summary Wind Data
idx_ws = find(strcmp(lab, 'HBB_WIH000CDS'), 1);
idx_wd = find(strcmp(lab, 'HBB_WIH000CDD'), 1);

if isempty(idx_ws) || isempty(idx_wd)
    error('Could not find wind speed/direction channels in summary data.');
end

ws_sum_raw = data(:, idx_ws);
wd_sum_raw = data(:, idx_wd);
t_sum      = t; % Keep time vector for interpolation

valid_idx_sum = ~isnan(ws_sum_raw) & ~isnan(wd_sum_raw);
ws_sum = ws_sum_raw(valid_idx_sum);
wd_sum = wd_sum_raw(valid_idx_sum);
t_sum_valid = t_sum(valid_idx_sum);

clear data lab t; % Clean up (t is safely stored in t_sum)

%% 2. Load Detailed Event Data (Day Data)
filename_day = 'humberdefs_20121125_dsa.mat';
if exist(filename_day, 'file')
    load(filename_day);
elseif exist(fullfile('CW1-data', filename_day), 'file')
    load(fullfile('CW1-data', filename_day));
elseif exist(fullfile('..', 'CW1-data', filename_day), 'file')
    load(fullfile('..', 'CW1-data', filename_day));
else
    error('File %s not found.', filename_day);
end

%% 3. Extract Wind Data for Day
if exist('D', 'var')
    if isfield(D, 'data')
        day_data = D.data;
    elseif isfield(D, 'accs')
        day_data = D.accs;
    else
        error('Structure D found but .data or .accs field is missing.');
    end
elseif exist('tdata', 'var')
    day_data = tdata;
    if size(day_data, 1) < size(day_data, 2), day_data = day_data'; end
elseif exist('accs', 'var')
    day_data = accs;
else
    error('Data variable not found.');
end

if size(day_data, 2) >= 11
    % Explicit 16-Channel Format:
    % Col 10 is D.WIND
    ws_day = day_data(:, 10); 
    
    % Col 11 is D.LAT (not wind direction). The detailed data does not contain wind direction.
    % Extract actual Wind Direction from the summary data and interpolate it to the 1Hz day data.
    n_samples = length(ws_day);
    if exist('D', 'var') && isfield(D, 'accs_timestamp')
        t_day = D.accs_timestamp;
    elseif exist('time', 'var') && isnumeric(time) && length(time) == n_samples
        t_day = time;
    else
        t_day = datenum(2012, 11, 25) + (0:n_samples-1)' / 86400;
    end
    
    [t_sum_uniq, uniq_idx] = unique(t_sum_valid);
    wd_sum_uniq = wd_sum(uniq_idx);
    wd_day = interp1(t_sum_uniq, wd_sum_uniq, t_day, 'nearest', 'extrap');
elseif size(day_data, 2) >= 5
    % 5-Channel Format
    ws_day = day_data(:, 4);
    wd_day = day_data(:, 5);
else
    error('Data format unrecognized. Cannot extract wind speed and direction.');
end

% Remove NaNs
valid_idx_day = ~isnan(ws_day) & ~isnan(wd_day);
ws_day = ws_day(valid_idx_day);
wd_day = wd_day(valid_idx_day);

if isempty(ws_day)
    error('No valid wind data found. Check if Summary file covers the date of the Detailed file.');
end

%% 4. Unit Conversion
% Convert Wind Speed to desired units (e.g., Knots, MPH)
target_unit = 'mps'; % Options: 'mps', 'knots', 'mph'

switch lower(target_unit)
    case 'knots'
        ws_day = ws_day * 1.94384; % 1 m/s = 1.94 knots
        ws_sum = ws_sum * 1.94384;
        unit_label = 'Knots';
    case 'mph'
        ws_day = ws_day * 2.23694; % 1 m/s = 2.24 mph
        ws_sum = ws_sum * 2.23694;
        unit_label = 'mph';
    otherwise
        unit_label = 'm/s';
end

[max_ws_day, max_idx_day] = max(ws_day);
fprintf('Max Wind Speed on 25/11/12: %.2f %s (Direction: %.0f deg)\n', max_ws_day, unit_label, wd_day(max_idx_day));

%% 5. Generate Plots
figure('Name', 'Wind Rose Analysis', 'Color', 'w', 'Position', [100, 100, 1200, 500]);

% --- Plot 1: Long-Term Summary ---
subplot(1, 2, 1);
if exist('windrose', 'file') == 2
    % Use built-in windrose (R2023b+)
    windrose(wd_sum, ws_sum);
    title('Long-Term Summary Wind Rose');
else
    % Fallback to polar scatter if windrose is not available
    polarscatter(deg2rad(wd_sum), ws_sum, 10, ws_sum, 'filled', 'MarkerFaceAlpha', 0.1);
    ax1 = gca;
    ax1.ThetaZeroLocation = 'top'; % North at the top
    ax1.ThetaDir = 'clockwise';    % NESW direction
    colormap(ax1, parula);
    c1 = colorbar;
    c1.Label.String = ['Wind Speed (' unit_label ')'];
    title('Long-Term Summary (Polar Scatter)');
    ax1.ThetaTick = 0:45:315;
    ax1.ThetaTickLabel = {'N','NE','E','SE','S','SW','W','NW'};
end

% --- Plot 2: Detailed Event Day ---
subplot(1, 2, 2);
if exist('windrose', 'file') == 2
    windrose(wd_day, ws_day);
    title('Wind Rose for Nov 25, 2012');
else
    polarscatter(deg2rad(wd_day), ws_day, 10, ws_day, 'filled', 'MarkerFaceAlpha', 0.05);
    ax2 = gca;
    ax2.ThetaZeroLocation = 'top'; 
    ax2.ThetaDir = 'clockwise';    
    colormap(ax2, parula);
    c2 = colorbar;
    c2.Label.String = ['Wind Speed (' unit_label ')'];
    title('Nov 25, 2012 (Polar Scatter)');
    rlim([0 max(ws_day)*1.1]);
    ax2.ThetaTick = 0:45:315;
    ax2.ThetaTickLabel = {'N','NE','E','SE','S','SW','W','NW'};
end
