%% Advanced Data Visualization for Long-Term SHM Data
% Generates 3D plots, 2D Histograms, and 1D Distributions for the Humber Bridge.
% Renamed from histogram.m to avoid shadowing the built-in MATLAB function.

clear; clc; close all;

%% 1. Load and Clean Data
if exist('h_summaries20160405_simple.mat', 'file')
    load('h_summaries20160405_simple.mat');
elseif exist(fullfile('CW1-data', 'h_summaries20160405_simple.mat'), 'file')
    load(fullfile('CW1-data', 'h_summaries20160405_simple.mat'));
else
    error('Data file not found.');
end

% Replace missing data flags with NaN
data(data == -999) = NaN;

%% 2. Find Channel Indices
% Helper function to find column index safely
get_idx = @(name) find(strcmp(lab, name), 1);

idx_wind_spd = get_idx('HBB_WIH000CDS'); % Wind Speed
idx_wind_dir = get_idx('HBB_WIH000CDD'); % Wind Direction
idx_lat_rms  = get_idx('RMS_H');         % Lateral Sway
idx_vert_rms = get_idx('RMS_VE');        % Vertical Traffic
idx_temp     = get_idx('HBB_TSH000CDA'); % Air Temperature
idx_exp      = get_idx('EXH077ED');      % Expansion Joint

% Extract vectors for cleaner code
N = size(data, 1);
if ~isempty(idx_wind_spd), W_spd = data(:, idx_wind_spd); else, W_spd = nan(N,1); end
if ~isempty(idx_wind_dir), W_dir = data(:, idx_wind_dir); else, W_dir = nan(N,1); end
if ~isempty(idx_lat_rms),  Lat   = data(:, idx_lat_rms);  else, Lat   = nan(N,1); end
if ~isempty(idx_vert_rms), Vert  = data(:, idx_vert_rms); else, Vert  = nan(N,1); end
if ~isempty(idx_temp),     Temp  = data(:, idx_temp);     else, Temp  = nan(N,1); end
if ~isempty(idx_exp),      Exp   = data(:, idx_exp);      else, Exp   = nan(N,1); end

%% 3. Plot 1: 3D Aerodynamic Correlation (plot3)
figure('Name', '3D Wind-Direction-Vibration', 'Position', [100, 100, 800, 600]);
% We use scatter3 instead of plot3 so we can colour-code the points by vibration severity
% This helps identify which wind conditions cause the most movement
scatter3(W_dir, W_spd, Lat, 10, Lat, 'filled'); 
colormap(jet);
colorbar;
title('3D Aerodynamic Response: Direction vs Speed vs Sway');
xlabel('Wind Direction (Degrees)');
ylabel('Wind Speed (m/s)');
zlabel('Lateral RMS Acceleration (g)');
view(45, 30); % Set a nice 3D viewing angle
grid on;

%% 4. Plot 2: 2D Bivariate Histogram for Thermal Expansion
figure('Name', '2D Thermal Density', 'Position', [150, 150, 800, 600]);
% Remove NaNs just for this specific pair to avoid histogram errors
% Shows the most common operating conditions (Temperature vs Expansion)
valid_idx = ~isnan(Temp) & ~isnan(Exp);
if any(valid_idx)
    histogram2(Temp(valid_idx), Exp(valid_idx), 'DisplayStyle', 'tile', 'ShowEmptyBins', 'off');
    colormap(parula);
    cb = colorbar;
    cb.Label.String = 'Number of Observations (Density)';
else
    text(0.5, 0.5, 'Insufficient Data for Thermal Plot', 'HorizontalAlignment', 'center');
end
title('Bivariate Histogram: Thermal Expansion Operating Regime');
xlabel('Temperature (C)');
ylabel('Expansion Joint Displacement (mm)');
grid on;

%% 5. Plot 3: 1D Loading Histograms (Overlaid)
figure('Name', 'Load Distributions', 'Position', [200, 200, 800, 600]);
% Compare the statistical distribution of traffic vs wind loading
% Plot Traffic Vibration Histogram
histogram(Vert, 'Normalization', 'probability', 'BinWidth', 0.005, 'FaceColor', 'k', 'EdgeColor', 'none');
hold on;
% Plot Wind Vibration Histogram
histogram(Lat, 'Normalization', 'probability', 'BinWidth', 0.005, 'FaceColor', 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.6);
% Formatting
title('Statistical Distribution of Bridge Loading (2011-2016)');
xlabel('RMS Acceleration Magnitude (g)');
ylabel('Probability / Frequency of Occurrence');
legend('Vertical Vibration (Traffic Dominated)', 'Lateral Vibration (Wind Dominated)');
grid on;