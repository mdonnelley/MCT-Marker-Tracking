% Script to collate average MCT rates (column K) from the Excel file

if(strcmp(getenv('COMPUTERNAME'),'GT-DSK-DONNELLE')), datapath = 'I:/SPring-8/2012 B/MCT/Images/Processed/MCT Rate Calculation/'; end
if(strcmp(getenv('COMPUTERNAME'),'ASPEN')), datapath = 'S:/Temporary/WCH/2012 B/MCT/Images/Processed/MCT Rate Calculation/'; end

% particles = 50;                         % Number of particles to track
% frames = 20;                            % Number of frames to track each particle for
% times = [-0.5,1:0.5:2,3:10,12:2:20];	% Timepoint in minutes
% 
% H = 'R01/MCT Rate Calculation 2013-Sep-30 15-08-31 MD - HS.xls';
% M = 'R01/MCT Rate Calculation 2013-Sep-30 15-08-31 MD - Mannitol.xls';

particles = 200;                                    % Number of particles to track
frames = 10;                                        % Number of frames to track each particle for
times = [-1,1,2,4,8,12,16];                         % Timepoint in minutes

H = 'R02/MCT Rate Calculation 2013-Nov-12 15-01-01 MD - HS.xls';
M = 'R02/MCT Rate Calculation 2013-Nov-12 15-01-01 MD - Mannitol.xls';

cols = 11;
rows = 1:particles*frames:particles*frames*length(times);

[H_status,H_sheets] = xlsfinfo([datapath,H]);
[M_status,M_sheets] = xlsfinfo([datapath,M]);

for s = 1:length(H_sheets),
    
    data = xlsread([datapath,H],s);
    H_stats(1:length(times),:,s) = data(rows,cols);
    
end

for s = 1:length(M_sheets),
    
    data = xlsread([datapath,M],s);
    M_stats(1:length(times),:,s) = data(rows,cols);
    
end

H_stats(isnan(H_stats)) = 0;
H_average = squeeze(H_stats(:,1,:));

M_stats(isnan(M_stats)) = 0;
M_average = squeeze(M_stats(:,1,:));