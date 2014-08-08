% Script to collate data about MCT rates in each group

close all, clear, clc

if(strcmp(getenv('COMPUTERNAME'),'GT-DSK-DONNELLE')), datapath = 'I:/SPring-8/2013 B/MCT/Images/Processed/MCT Rate Calculation/R01/'; end
if(strcmp(getenv('COMPUTERNAME'),'ASPEN')), datapath = 'S:/Temporary/WCH/2013 B/MCT/Images/Processed/MCT Rate Calculation/R01/'; end

particles = 50;                         % Number of particles to track
frames = 15;                            % Number of frames to track each particle for
times = -5:-1	% Timepoint in minutes
bins = 0:0.05:6;

C = 'MCT Rate Calculation 2014-Feb-25 08-54-57 MD - C57.xls';
T = 'MCT Rate Calculation 2014-Feb-25 08-54-57 MD - CF.xls';

[C_status,C_sheets] = xlsfinfo([datapath,C]);
[T_status,T_sheets] = xlsfinfo([datapath,T]);

%% Collate data from XLS sheets

for s = 1:length(C_sheets),
    
    data = xlsread([datapath,C],s);
    
    for timepoint = 1:length(times),
    
        range = particles*frames*(timepoint-1)+1:particles*frames*timepoint;
        C_raw(:,timepoint,s) = data(range,10);
        C_histogram(:,timepoint,s) = hist(C_raw(:,timepoint,s),bins);
 
    end
    
end

for s = 1:length(T_sheets),
    
    data = xlsread([datapath,T],s);
    
    for timepoint = 1:length(times),
    
        range = particles*frames*(timepoint-1)+1:particles*frames*timepoint;
        T_raw(:,timepoint,s) = data(range,10);
        T_histogram(:,timepoint,s) = hist(T_raw(:,timepoint,s),bins);
 
    end
    
end

%% Plot data

% plotrange = 21:121;
% 
% figure,surf(times, bins(plotrange), sum(C_histogram(plotrange,:,:),3))
% view(115,45)
% ylabel('Particle MCT rate (mm/min)')
% zlabel('Number of particles')
% xlabel('Timepoint (min)')
% title('Hypertonic Saline')
% 
% figure,surf(times, bins(plotrange), sum(T_histogram(plotrange,:,:),3))
% view(115,45)
% ylabel('Particle MCT rate (mm/min)')
% zlabel('Number of particles')
% xlabel('Timepoint (min)')
% title('Mannitol')

% %% Additional stats
% C_raw(C_raw<1) = NaN;
% C_raw(C_raw>6) = NaN;
% T_raw(T_raw<1) = NaN;
% T_raw(T_raw>6) = NaN;
C_mean = nanmean(C_raw,1);
T_mean = nanmean(T_raw,1);
C_mean(isnan(C_mean)) = 0;
T_mean(isnan(T_mean)) = 0;
C_mean = squeeze(C_mean);
T_mean = squeeze(T_mean);


C_mean2 = C_mean;
C_mean2(C_mean2 == 0) = NaN
C_mean2=nanmean(C_mean2)
C_mean2(isnan(C_mean2)) = [];

T_mean2 = T_mean;
T_mean2(T_mean2 == 0) = NaN
T_mean2=nanmean(T_mean2)
T_mean2(isnan(T_mean2)) = [];
