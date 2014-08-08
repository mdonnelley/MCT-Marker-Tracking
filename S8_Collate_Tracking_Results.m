% Script to collate all particle data from the Excel file and produce histograms

close all, clear, clc

if(strcmp(getenv('COMPUTERNAME'),'GT-DSK-DONNELLE')), datapath = 'I:/SPring-8/2012 B/MCT/Images/Processed/MCT Rate Calculation/'; end
if(strcmp(getenv('COMPUTERNAME'),'ASPEN')), datapath = 'S:/Temporary/WCH/2012 B/MCT/Images/Processed/MCT Rate Calculation/'; end

% particles = 50;                         % Number of particles to track
% frames = 20;                            % Number of frames to track each particle for
% times = [-0.5,1:0.5:2,3:10,12:2:20];	% Timepoint in minutes
% bins = 1:0.05:5;
% 
% H = 'R01/MCT Rate Calculation 2013-Sep-30 15-08-31 MD - HS.xls';
% M = 'R01/MCT Rate Calculation 2013-Sep-30 15-08-31 MD - Mannitol.xls';

particles = 200;                                    % Number of particles to track
frames = 10;                                        % Number of frames to track each particle for
times = [-1,1,2,4,8,12,16];                         % Timepoint in minutes
bins = 0:0.05:1;

H = 'R02/MCT Rate Calculation 2013-Nov-12 15-01-01 MD - HS.xls';
M = 'R02/MCT Rate Calculation 2013-Nov-12 15-01-01 MD - Mannitol.xls';

cols = 10;

[H_status,H_sheets] = xlsfinfo([datapath,H]);
[M_status,M_sheets] = xlsfinfo([datapath,M]);

%% Collate data from XLS sheets

for s = 1:length(H_sheets),
    
    % Read the data
    data = xlsread([datapath,H],s);
    H_raw(:,:,s) = reshape(data(:,cols),particles*frames,length(times));
    
    % Remove data outside the bin range
    H_raw(H_raw < min(bins)) = NaN;
    H_raw(H_raw > max(bins)) = NaN;
    
    % Create the histogram
    H_histogram(:,:,s) = hist(H_raw(:,:,s),bins);
    
end

for s = 1:length(M_sheets),
    
    % Read the data
    data = xlsread([datapath,M],s);
    M_raw(:,:,s) = reshape(data(:,cols),particles*frames,length(times));
    
    % Remove data outside the bin range
    M_raw(M_raw < min(bins)) = NaN;
    M_raw(M_raw > max(bins)) = NaN;
    
    % Create the histogram
    M_histogram(:,:,s) = hist(M_raw(:,:,s),bins);
    
end

%% Plot raw data
figure, subplot(121)
h=bar3(bins,sum(H_histogram,3),'detached');
set(gca,'XTickLabel',times)
set(gca,'zlim',[0 350])
ylabel('Particle MCT rate (mm/min)')
zlabel('Number of particles')
xlabel('Timepoint (min)')
title('Hypertonic Saline')

for k = 1:length(h)
    zdata = get(h(k),'ZData');
    set(h(k),'CData',zdata,...
             'FaceColor','interp')
end

subplot(122)
h=bar3(bins,sum(M_histogram,3),'detached');
set(gca,'XTickLabel',times)
set(gca,'zlim',[0 350])
ylabel('Particle MCT rate (mm/min)')
zlabel('Number of particles')
xlabel('Timepoint (min)')
title('Mannitol')

for k = 1:length(h)
    zdata = get(h(k),'ZData');
    set(h(k),'CData',zdata,...
             'FaceColor','interp')
end

%% Calculate and plot proportion data

H_proportion = sum(H_histogram,3) ./ repmat(sum(sum(H_histogram,3)),size(H_histogram,1),1);
M_proportion = sum(M_histogram,3) ./ repmat(sum(sum(M_histogram,3)),size(M_histogram,1),1);

figure, subplot(121)
h=bar3(bins,H_proportion,'detached');
set(gca,'XTickLabel',times)
set(gca,'zlim',[0 1])
ylabel('Particle MCT rate (mm/min)')
zlabel('Proportion of particles')
xlabel('Timepoint (min)')
title('Hypertonic Saline')

for k = 1:length(h)
    zdata = get(h(k),'ZData');
    set(h(k),'CData',zdata,...
             'FaceColor','interp')
end

subplot(122)
h=bar3(bins,M_proportion,'detached');
set(gca,'XTickLabel',times)
set(gca,'zlim',[0 1])
ylabel('Particle MCT rate (mm/min)')
zlabel('Proportion of particles')
xlabel('Timepoint (min)')
title('Mannitol')

for k = 1:length(h)
    zdata = get(h(k),'ZData');
    set(h(k),'CData',zdata,...
             'FaceColor','interp')
end

figure
h=bar3(bins,M_proportion-H_proportion,'detached');
set(gca,'XTickLabel',times)
ylabel('Particle MCT rate (mm/min)')
zlabel('Proportion of particles')
xlabel('Timepoint (min)')
title('Mannitol')

for k = 1:length(h)
    zdata = get(h(k),'ZData');
    set(h(k),'CData',zdata,...
             'FaceColor','interp')
end