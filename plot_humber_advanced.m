%% Advanced Structural Behaviour Plots
% This script visualizes aerodynamic stability, GPS filtering, and buffeting
% correlations for the Humber Bridge using data from Nov 25, 2012.

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

%% 2. Extract Data Variables
% Handle different variable names (D.data, tdata, or accs)
if exist('D', 'var') && isfield(D, 'data')
    data = D.data;
elseif exist('tdata', 'var')
    data = tdata;
    % Ensure data is (samples x channels)
    if size(data, 1) < size(data, 2) && size(data, 1) <= 20
        data = data';
    end
elseif exist('accs', 'var')
    data = accs;
else
    error('Variable D.data, tdata, or accs not found in workspace.');
end

%% 3. Extract Specific Channels
% Correct Mapping based on standard Humber dataset (Cols 1-3 Sensor 1, 4-6 Sensor 2)
% Col 3: GPS Height East
% Col 6: GPS Height West
% Col 10: Wind Speed
% Col 11: Lateral Acceleration

if size(data, 2) < 11
    error('Data matrix has fewer than 11 columns. Cannot extract required channels.');
end

% Extract Heights and Calculate Torsion
h_east = data(:, 3);
h_west = data(:, 6);
deck_rotation = h_east - h_west; % Differential height represents twist (torsion)

% GPS Height for Filtering Plot (Use East Height)
gps_height_raw = h_east;

% Calculate LPF (Quasi-Static) Component
% Window size for ~0.05Hz cutoff at 1Hz sampling -> ~20 samples
% Moving average acts as a Low Pass Filter to remove high-freq vibrations
window_size = 20; 
gps_height_lpf = movmean(gps_height_raw, window_size);

wind_speed     = data(:, 10);
lat_accel      = data(:, 11) / 1000; % Convert mm/s^2 to m/s^2

%% 4. Create Time Vector
% Data is 1Hz for 1 day
N = size(data, 1);
Fs = 1; 
t_hours = (0:N-1)' / 3600; % Time in hours (0 to ~24)

%% 5. Generate Plots
% Plot 1: Aerodynamic Stability (Wind vs Deck Torsion)
% Checks if high wind speeds cause the deck to twist
figure('Name', 'Aerodynamic Stability', 'Color', 'w', 'Position', [100, 100, 800, 600]);
yyaxis left
plot(t_hours, wind_speed, 'b', 'LineWidth', 1);
ylabel('Wind Speed (m/s)');
ylim([0 max(wind_speed)*1.1]);

yyaxis right
plot(t_hours, deck_rotation, 'r', 'LineWidth', 1);
ylabel('Deck Rotation (mm)');

title('Aerodynamic Stability: Wind vs. Deck Torsion');
xlabel('Time (Hours)');
grid on;
axis tight;

% Plot 2: Filtering (Raw vs LPF Height)
% Visualizes the difference between total movement and static deflection
figure('Name', 'GPS Filtering', 'Color', 'w', 'Position', [150, 150, 800, 600]);
plot(t_hours, gps_height_raw, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5); hold on;
plot(t_hours, gps_height_lpf, 'k', 'LineWidth', 1.5); % Thick black for LPF
title('Filtering: High-Freq Buffeting vs. Quasi-Static');
ylabel('GPS Height (mm)');
xlabel('Time (Hours)');
legend('Raw GPS', 'LPF GPS', 'Location', 'best');
grid on;
axis tight;


% Plot 3: Buffeting Correlation (Wind vs Lat Accel)
% Scatter plot to show how wind speed drives lateral vibration
figure('Name', 'Buffeting Correlation', 'Color', 'w', 'Position', [200, 200, 800, 600]);
scatter(wind_speed, lat_accel, 10, 'filled', 'MarkerFaceAlpha', 0.4);
title('Wind vs Lateral Acceleration Correlation');
xlabel('Wind Speed (m/s)');
ylabel('Transverse Acceleration (m/s^2)');
grid on;
