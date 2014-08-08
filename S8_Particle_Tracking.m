% Script to manually track movement of lead between adjacent frames

clear all; clc;

datapath = 'P:/SPring-8/';
experiment.read = '2011 B/20XU/MCT/Images/FD Corrected/';
experiment.filelist = '2011 B/20XU/MCT/Images/2011B Data.csv';
xls = ['I:/SPring-8/2011 B/20XU/MCT/Images/Matlab/MCT Rate Calculation ',datestr(now,'yyyy-mmm-dd HH-MM-SS'),'.xls'];

FAD_IMAGESET_L = 'Low/';
FAD_FILENAME_L = '_fad_';
FAD_FILETYPE_L = '.jpg';

% experiment.runlist = [4:6,8,10:12,14,16:19];	% ALL
% experiment.runlist = [4,6,17:19];             % BASELINE
experiment.runlist = [5,8,10:12,14,16];         % TREATMENT
experiment.runlist = [8,10:12,14,16];

% frames = 10:60:615; times = -2.5:2:17.5;      % ALL
% frames = [10,70]; times = [-2.5,-0.5];        % BASELINE
frames = 130:60:615; times = 1.5:2:17.5;        % TREATMENT

gap = 1;
% gap = 15;
repeat = 25;
marker = 10;

info = ReadS8Data([datapath,experiment.filelist]);

h(1) = figure;
h(2) = figure;

% Repeat for each mouse/run
for m = experiment.runlist,
    
    % Repeat for each timepoint
    for i = 1:length(frames),
        
        % Determine the input filenames
        a = sprintf('%s%s%s%s%s%s%.4d%s',datapath,experiment.read,info.image{m},FAD_IMAGESET_L,info.imagestart{m},FAD_FILENAME_L,frames(i),FAD_FILETYPE_L)
        b = sprintf('%s%s%s%s%s%s%.4d%s',datapath,experiment.read,info.image{m},FAD_IMAGESET_L,info.imagestart{m},FAD_FILENAME_L,frames(i)+gap,FAD_FILETYPE_L)
        
        % Read the two images
        a = imread(a);
        b = imread(b);
        
        figure(h(1)), imshow(a);
        figure(h(2)), imshow(b);
        
        % Repeat for each of the particles
        for j = 1:repeat,

            count = repeat*(i-1)+j;
            
            data(count,1) = times(i);
            data(count,2) = j;
            data(count,3) = frames(i);
            data(count,6) = frames(i)+gap;
            
            figure(h(1)), set(h(1), 'Position', get(0,'ScreenSize'));
            title([info.imagestart{m}, ' - Timepoint: t = ', num2str(times(i)), ' min (frame ', num2str(frames(i)),') - Particle number: ', num2str(j), ' (START)'])
            [data(count,4),data(count,5)] = ginput(1);
            rectangle('Position',[data(count,4)-marker,data(count,5)-marker,2*marker,2*marker],'Curvature',[1,1],'FaceColor','r');
            
            figure(h(2)), set(h(2), 'Position', get(0,'ScreenSize'));
            title([info.imagestart{m}, ' - Timepoint: t = ', num2str(times(i)), ' min (frame ', num2str(frames(i)+gap),') - Particle number: ', num2str(j), ' (FINISH)'])
            [data(count,7),data(count,8)] = ginput(1);
            rectangle('Position',[data(count,7)-marker,data(count,8)-marker,2*marker,2*marker],'Curvature',[1,1],'FaceColor','g');
            
        end
        
        % Complete calculations
        data(:,9)=sqrt((data(:,7)-data(:,4)).^2 + (data(:,8)-data(:,5)).^2);
        data(:,10)=data(:,9)*1.43/2560;
        data(:,11)=data(:,6)-data(:,3);
        data(:,12)=data(:,11)*0.5/60;
        data(:,13)=data(:,10)./data(:,12);
        
        % Remove any data related to selections outside the image area
        mask = (data(:,4) > 0) & (data(:,4) < size(a,2)) & ...
                (data(:,5) > 0) & (data(:,5) < size(a,1)) & ...
            	(data(:,7) > 0) & (data(:,7) < size(b,2)) & ...
                (data(:,8) > 0) & (data(:,8) < size(b,1));
        mask = repmat(mask,1,size(data,2));
        mask(:,1:2) = 1;
        data = data .* mask;
        
        % Write the results to an XLS file
        xlswrite(xls,data(:,:),info.imagestart{m})
        
    end
    
end

close all; clear; clc;