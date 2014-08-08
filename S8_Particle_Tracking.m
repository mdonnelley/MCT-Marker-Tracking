% Script to manually track movement of lead between adjacent frames
%
% NOTE: Track only particles that are moving. Stationary particles should
% be excluded.
%
% BUTTON ASSIGNMENT:
%
%   LEFT MOUSE:     Select (and track) a particle.
%
%   MIDDLE MOUSE:	Replay sequence
%                   Remove any selected points for the current particle
%
%   RIGHT MOUSE:	Finish tracking the current particle and begin the next PARTICLE
%                   NOTE: This click is not counted as a selection
%
%   ZERO KEY:       Finish tracking the current particle and begin the next TIMEPOINT
%
%   ONE KEY:        Remove current and previous particles and start previous particle
%

clear all; clc;

%% Analysis specific parameters

% datapath = 'P:/SPring-8/2012 A/20XU/MCT/Images/';
datapath = 'I:/SPring-8/2012 A/20XU/MCT/Images/';
% datapath = 'S:/Temporary/WCH/2012 A/20XU/MCT/Images/';

experiment.read = 'FD Corrected/';
experiment.filelist = 'S8_2012A.csv';
experiment.write = 'Processed/';

FAD_IMAGESET_L = 'Low/';
FAD_FILENAME_L = 'fad_';
FAD_FILETYPE_L = '.jpg';

particles = 50;         % Number of particles to track
frames = 12;            % Number of frames to track each particle for
frameinterval = 5.5;    % Time between frames in seconds
pixelsize = 1.43/2560;  % Pixel size in mm
direction = 'Reverse';

type = 'REPEAT'

switch type
    case 'BASELINE'
        gap = 1;
        runlist = [1 5 8 11 15 19 23 27 30 34 37 41 44 47 51 54 57 61 65 69 73 77 81 84];
    case 'REPEAT'
        gap = 1;
        runlist = [3 7 10 13 17 21 25 29 32 36 39 43 46 49 53 56 59 63 67 71 75 79 83 86];
end

dotsize = 10;           % Marker size
pauselength = 0.25;     % Time between frames in preview sequence

%% Begin analysis

info = ReadS8Data([datapath,experiment.filelist]);

% Randomise the runlist order to blind observer
runlist = runlist(randperm(length(runlist)));

% Select whether to start or continue an analysis
button = questdlg('Would you like to continue an analysis?');

switch button
    case 'Yes'
        [FileName,PathName] = uigetfile('*.mat','Select a file',[datapath,experiment.write,'/MCT Rate Calculation*.mat'])
        MAT = [PathName,FileName];
        XLS = [MAT(1:length(MAT)-4),'.xls'];
        load(MAT);
        runlist(1:find(runlist == m)) = [];
    case 'No'
        datetime = datestr(now,'yyyy-mmm-dd HH-MM-SS');
        initials = inputdlg('Please enter your initials (i.e. MD)','User ID');
        MAT = [datapath,experiment.write,'MCT Rate Calculation ',datetime,' ',char(initials),'.mat'];
        XLS = [datapath,experiment.write,'MCT Rate Calculation ',datetime,' ',char(initials),'.xls'];
    case 'Cancel'
        break;
end

h(1) = figure;

%% Get the user selected points and save the data
for m = runlist,
    
    clear data;
    data = zeros(particles*frames,12);

    % Load each of the images at that timepoint
    for i = 1:frames,
        
        % Calculate the framenumber
        framenumber = info.imagegofrom(m) + (i-1)*gap;
        
        % Determine the filename
        filename = sprintf('%s%s%s%s%s%s%.4d%s',datapath,experiment.read,info.image{m},FAD_IMAGESET_L,info.imagestart{m},FAD_FILENAME_L,framenumber,FAD_FILETYPE_L)
        
        % Load the image
        images(:,:,i) = imread(filename);
        
    end
    
    % Repeat for each of the particles
    p = 1;
    while p <= particles,
        
        % Display the image series to allow user to visualise the particles
        switch direction
            case 'Forward'
                preview = 1:frames;
            case 'Reverse'
                preview = frames:-1:1;
        end
        
        for i = preview,
            
            tic
            
            figure(h(1)), imshow(images(:,:,i));
            title(['Sequence Preview'],'color','r')
            
            % Mark each of the previously selected particles
            for j = 1:(p-1),
                
                % Add the marker
                line = (j-1)*frames + i;
                rectangle('Position',[data(line,4)-dotsize,data(line,5)-dotsize,2*dotsize,2*dotsize],'Curvature',[1,1],'FaceColor','r');
                
            end
            
            pause(pauselength-toc);
            
        end
        
        % Select the particles
        for i = 1:frames,
            
            figure(h(1)), imshow(images(:,:,i));
            title(['Particle: ', num2str(p), ' of ', num2str(particles), ', Frame: ', num2str(i),' of ', num2str(frames)])
            
            % Mark each of the previously selected particles
            for j = 1:(p-1),
                
                % Add the marker
                line = (j-1)*frames + i;
                rectangle('Position',[data(line,4)-dotsize,data(line,5)-dotsize,2*dotsize,2*dotsize],'Curvature',[1,1],'FaceColor','r');
                
            end
            
            % Calculate the correct line number in the data array
            line = (p-1)*frames + i;
            data(line,2) = p;
            data(line,3) = 1 + (i-1)*gap;
            [data(line,4),data(line,5),userinput] = ginput(1);
            
            % Perform action based on which button is pressed
            switch userinput,
                % Middle button (remove all data for that particle)
                case 2
                    data(line-i+1:line-i+frames,4:5)=-10;
                    p=p-1;
                    break;
                    % Right button (Finish current particle and start next PARTICLE)
                case 3
                    data(line:line-i+frames,4:5)=-10;
                    break;
                    % Zero key (Finish current particle and start next TIMEPOINT)
                case 48
                    p = particles;
                    data(line:line-i+frames,4:5)=-10;
                    break;
                    % One key (Remove current and previous particles and start previous particle)
                case 49
                    data(line-i+1:line-i+frames,4:5)=-10;
                    if(p > 1), p=p-2; else p=p-1; end
                    break;
            end
            
        end
        p=p+1;
        
    end
    
    % Record what's been analysed
    save(MAT,'runlist','m','gap','frames','particles');
    
    % Remove any data from selections outside the image area
    data(data(:,4) < 0,4:10) = NaN;
    data(data(:,4) >  size(images(:,:,i),2),4:10) = NaN;
    data(data(:,5) < 0,4:10) = NaN;
    data(data(:,5) > size(images(:,:,i),1),4:10) = NaN;
    
    % Complete the calculations
    dt = data(:,3) - circshift(data(:,3),[1 0]);
    x = data(:,4) - circshift(data(:,4),[1 0]);
    y = data(:,5) - circshift(data(:,5),[1 0]);
    data(:,6)=sqrt(x.^2 + y.^2);
    data(:,7)=data(:,6)*pixelsize;
    data(:,8)=dt;
    data(:,9)=data(:,8)*frameinterval/60;
    data(:,10)=data(:,7)./data(:,9);
    
    % Remove the data from the first particle in each sequence
    data(1:frames:particles*frames,6:10) = NaN;
    
    % Calculate mean and standard deviation data
    blockstart = 1;
    blockfinish = frames*particles;
    data(blockstart,11) = nanmean(data(blockstart:blockfinish,10));
    data(blockstart,12) = nanstd(data(blockstart:blockfinish,10));
    data(blockstart,13) = nanmedian(data(blockstart:blockfinish,10));
    
    % Write the results to the XLS file
    xlswrite(XLS,data(:,:),info.imagestart{m})
    
end

close all; clc;