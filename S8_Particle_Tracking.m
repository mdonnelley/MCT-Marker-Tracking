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
start = 130:60:615; times = 1.5:2:17.5;        % TREATMENT

gap = 1;
frames = 10;
% gap = 15;
% repeat = 25;
repeat = 20;
marker = 10;
pauselength = 0.25;

info = ReadS8Data([datapath,experiment.filelist]);

h(1) = figure;

% Repeat for each mouse/run
for m = experiment.runlist,
    
    particlecount = 1;
    clear data;
    
    % Repeat for each timepoint
    for t = 1:length(start),
        
        % Load each of the images at that timepoint
        for i = 1:frames,
        
            % Calculate the framenumber
            framenumber = start(t) + (i-1)*gap;
            
            % Determine the filename
            filename = sprintf('%s%s%s%s%s%s%.4d%s',datapath,experiment.read,info.image{m},FAD_IMAGESET_L,info.imagestart{m},FAD_FILENAME_L,framenumber,FAD_FILETYPE_L);
            
            % Load the image
            images(:,:,i) = imread(filename);
            
        end
        
        % Repeat for each of the particles
        for p = 1:repeat,
            
            % Display the image series in reverse
            for i = frames:-1:1,
                
                tic
                figure(h(1)), imshow(images(:,:,i));
                title(['Reversed Sequence Preview (frame ', num2str(start(t)+i-1),')'],'color','r')
                
                % Mark each of the previously selected particles
                for j = 1:(p-1),
                    
                    line = (t-1)*frames*repeat + (j-1)*frames + i;
                    rectangle('Position',[data(line,4)-marker,data(line,5)-marker,2*marker,2*marker],'Curvature',[1,1],'FaceColor','r');
                    
                end
                
                toc
                pause(pauselength-toc);
                
            end
            
            % Select the particles
            for i = 1:frames,

                figure(h(1)), imshow(images(:,:,i));
                title([info.imagestart{m}, ' - Timepoint: t = ', num2str(times(t)), ' min (frame ', num2str(start(t)+i-1),') - Particle number: ', num2str(p)])
                
                % Mark each of the previously selected particles
                for j = 1:(p-1),
                    
                    line = (t-1)*frames*repeat + (j-1)*frames + i;
                    rectangle('Position',[data(line,4)-marker,data(line,5)-marker,2*marker,2*marker],'Curvature',[1,1],'FaceColor','r');
                    
                end
                
                data(particlecount,1) = times(t);
                data(particlecount,2) = p;
                data(particlecount,3) = start(t) + (i-1)*gap;
                [data(particlecount,4),data(particlecount,5)] = ginput(1);

                particlecount = particlecount + 1;
            
            end
            
        end
        
    end
    
    % Complete the calculations
    dt = data(:,3) - circshift(data(:,3),[1 0]);
    x = data(:,4) - circshift(data(:,4),[1 0]);
    y = data(:,5) - circshift(data(:,5),[1 0]);
    
    data(:,6)=sqrt(x.^2 + y.^2);
    data(:,7)=data(:,6)*1.43/2560;
    data(:,8)=dt;
    data(:,9)=data(:,8)*0.5/60;
    data(:,10)=data(:,7)./data(:,9);
    
    % Remove the wrong data at the start of each particle
    data(1:frames:length(times)*repeat*frames,6:10) = 0;
    
    % Remove any data related to selections outside the image area
    mask = (data(:,4) > 0) & (data(:,4) < size(images(:,:,i),2)) & ...
        (data(:,5) > 0) & (data(:,5) < size(images(:,:,i),1));
    mask = repmat(mask,1,size(data,2));
    mask(:,1:2) = 1;
    data = data .* mask;
    data(:,6:7) = data(:,6:7) .* circshift(mask(:,6:7),[1 0]);
    
    % Write the results to an XLS file
    xlswrite(xls,data(:,:),info.imagestart{m})

end

close all; clc;