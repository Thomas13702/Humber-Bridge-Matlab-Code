%% Wind Rose Analysis for Nov 25, 2012
% Visualizes wind speed and direction for the specific storm event using detailed data.

clear; clc; close all;

%% 1. Load Detailed Event Data
filename = 'humberdefs_20121125_dsa.mat';
if exist(filename, 'file')
    load(filename);
elseif exist(fullfile('CW1-data', filename), 'file')
    load(fullfile('CW1-data', filename));
elseif exist(fullfile('..', 'CW1-data', filename), 'file')
    load(fullfile('..', 'CW1-data', filename));
else
    error('File %s not found.', filename);
end

%% 2. Extract Variables
if exist('D', 'var')
    if isfield(D, 'data')
        data = D.data;
    elseif isfield(D, 'accs')
        data = D.accs;
    else
        error('Structure D found but .data or .accs field is missing.');
    end
elseif exist('tdata', 'var')
    data = tdata;
    if size(data, 1) < size(data, 2), data = data'; end
elseif exist('accs', 'var')
    data = accs;
else
    error('Data variable not found.');
end

%% 3. Extract Wind Data
% Channel Mapping based on provided definitions:
% Col 10: Wind Speed
if size(data, 2) >= 16
    % 16-Channel Format
    ws = data(:, 10); % Channel 10 is Wind Speed. Direction is separate.
    % Attempt to find direction
    if exist('D', 'var') && isfield(D, 'wind')
        wd = D.wind;
    elseif exist('wind', 'var')
        wd = wind;
    elseif exist('wind_direction', 'var')
        wd = wind_direction;
    else
        fprintf('Wind Direction not found in detailed file. Fetching from summary...\n');
        % Fallback: Load Summary Data for Direction
        sum_filename = 'h_summaries20160405_simple.mat';
        if exist(sum_filename, 'file')
            S = load(sum_filename);
        elseif exist(fullfile('CW1-data', sum_filename), 'file')
            S = load(fullfile('CW1-data', sum_filename));
        elseif exist(fullfile('..', 'CW1-data', sum_filename), 'file')
            S = load(fullfile('..', 'CW1-data', sum_filename));
        else
            error('Wind Direction not found and summary file missing.');
        end
        
        % Extract Summary Direction
        idx_wd_sum = find(strcmp(S.lab, 'HBB_WIH000CDD'), 1);
        if isempty(idx_wd_sum), error('Direction channel not found in summary.'); end
        
        t_sum = S.t;
        wd_sum = S.data(:, idx_wd_sum);
        
        % Determine Detailed Time Vector
        t_detailed = [];
        if exist('D', 'var') && isfield(D, 'accs_timestamp')
            t_detailed = D.accs_timestamp;
        elseif exist('time', 'var')
            try
                if iscell(time) || ischar(time), t_detailed = datenum(time); else, t_detailed = double(time); end
            catch
                t_detailed = [];
            end
        end
        
        % Fallback if time vector is missing, invalid length, or all NaNs
        if isempty(t_detailed) || length(t_detailed) ~= length(ws) || all(isnan(t_detailed))
            t_detailed = datenum(2012, 11, 25) + (0:length(ws)-1)' / 86400; % Default 1Hz assumption
        end
        
        % Ensure t_detailed is a column vector
        if size(t_detailed, 1) < size(t_detailed, 2), t_detailed = t_detailed'; end

        % Interpolate Direction to Detailed Time (Nearest Neighbor handles 0/360 wrap)
        valid_s = ~isnan(wd_sum) & ~isnan(t_sum);
        wd = interp1(t_sum(valid_s), wd_sum(valid_s), t_detailed, 'nearest', 'extrap');
    end
    
    if size(wd, 1) < size(wd, 2), wd = wd'; end
    % Ensure lengths match
    if length(wd) ~= length(ws)
        min_len = min(length(wd), length(ws));
        wd = wd(1:min_len);
        ws = ws(1:min_len);
    end
elseif size(data, 2) >= 4
    % 5-Channel Format
    ws = data(:, 4);
    if size(data, 2) >= 5
        wd = data(:, 5);
    else
        error('Wind Direction column not found.');
    end
else
    error('Data format unrecognized.');
end

% Remove NaNs
valid_idx = ~isnan(ws) & ~isnan(wd);
ws = ws(valid_idx);
wd = wd(valid_idx);

if isempty(ws)
    error('No valid wind data found. Check if Summary file covers the date of the Detailed file.');
end

%% 4. Unit Conversion
% Convert Wind Speed to desired units (e.g., Knots, MPH)
target_unit = 'mps'; % Options: 'mps', 'knots', 'mph'

switch lower(target_unit)
    case 'knots'
        ws = ws * 1.94384; % 1 m/s = 1.94 knots
        unit_label = 'Knots';
    case 'mph'
        ws = ws * 2.23694; % 1 m/s = 2.24 mph
        unit_label = 'Miles per Hour (mph)';
    otherwise
        unit_label = 'm/s';
end

WindDir = wd; % Wind Direction in degrees

[max_ws, max_idx] = max(ws);
fprintf('Max Wind Speed on 25/11/12: %.2f %s (Direction: %.0f deg)\n', max_ws, unit_label, WindDir(max_idx));

%% 5. Generate Plots
% Plot 1: Polar Scatter (Speed vs Direction)
% Visualizes the frequency and intensity of wind speed by direction
figure('Name', 'Wind Speed vs Direction', 'Color', 'w', 'Position', [100, 100, 600, 600]);
polarscatter(deg2rad(WindDir), ws, 25, ws, 'filled');
ax = gca;
ax.ThetaZeroLocation = 'top';
ax.ThetaDir = 'clockwise';
colormap(parula); % Professional colormap
c = colorbar;
c.Label.String = ['Wind Speed (' unit_label ')'];
title('Wind Speed vs Direction (Scatter)');
rlim([0 max(ws)*1.1]);
ax.ThetaTick = 0:45:315;
ax.ThetaTickLabel = {'N','NE','E','SE','S','SW','W','NW'};


% Plot 2: Directional Histogram
% Shows the frequency of wind coming from each direction sector
figure('Name', 'Wind Direction Frequency', 'Color', 'w', 'Position', [150, 150, 600, 600]);
polarhistogram(deg2rad(WindDir), 16, 'FaceColor', [0 0.4470 0.7410], 'FaceAlpha', 0.6);
ax = gca;
ax.ThetaZeroLocation = 'top';
ax.ThetaDir = 'clockwise';
title('Wind Direction Frequency');
ax.ThetaTick = 0:45:315;
ax.ThetaTickLabel = {'N','NE','E','SE','S','SW','W','NW'};
