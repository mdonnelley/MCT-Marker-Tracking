% Script to manually track movement of lead between adjacent frames
%
% NOTE 1: Track only particles that are moving. Stationary particles should
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

if(strcmp(getenv('COMPUTERNAME'),'GT-DSK-DONNELLE')), datapath = 'P:/'; end
if(strcmp(getenv('COMPUTERNAME'),'ASPEN')), datapath = 'S:/Temporary/WCH/'; end
if(strcmp(getenv('COMPUTERNAME'),'THREDBO')), datapath = 'C:/Users/Martin Donnelley/Documents/'; end

experiment.read = [datapath,'SPring-8/2013 B/MCT/Images/FD Corrected/'];
experiment.write = [datapath,'SPring-8/2013 B/MCT/Images/Processed/MCT Rate Calculation/'];
experiment.filelist = [datapath,'SPring-8/2013 B/MCT/Images/S8_13B_XU.csv'];
experiment.runlist = [9:13,16:17,20:24,26:30,33,35:44,46:50,52:54,56:58,60:61];

FAD_IMAGESET_L = 'Low/';
FAD_FILENAME_L = 'fad_';
FAD_FILETYPE_L = '.jpg';

particles = 200;                                    % Number of particles to track
% frames = 15;                                        % Number of frames to track each particle for
% times = -5:-1;                                      % Timepoint in minutes
% CHANGE FRAMES TO BE THE ACTUAL FRAME NUMBERS FOR THE BLOCK THAT YOU WANT i.e. 
% frames = 10:10:60
% times = -5:21;                                      % Timepoint in minutes
frames = 15;                                        % Number of frames to track each particle for
times = [-1,1:4,6:3:15];                                      % Timepoint in minutes
gap = 5;                                            % Gap between each analysis frame

timepoints = 1:length(times);                       % Timepoints to analyse
frameinterval = 0.2;                                % Time between frames in seconds
start = 75 * (times + 5);                           % Timepoint in frames
imsize = [2560,2160];                               % Image size in pixels
pixelsize = 1.43/2560;                              % Pixel size in mm
direction = 'Reverse';                              % Preview direction (Forward or Reverse)
dotsize = 25;                                       % Marker size
pauselength = 0.1;                                  % Time between frames in preview sequence

%% Perform setup

switch direction
    case 'Forward'
        preview = 1:frames;
    case 'Reverse'
        preview = frames:-1:1;
end

% Read the XLS sheet
info = ReadS8Data([datapath,experiment.filelist]);

% Randomise the experiment.runlist order to blind observer
experiment.runlist = experiment.runlist(randperm(length(experiment.runlist)));

% Select whether to start or continue an analysis
button = questdlg('Would you like to continue an analysis?');

switch button    
    case 'Yes'
        [FileName,PathName] = uigetfile('*.mat','Select a file',[datapath,experiment.write,'/MCT Rate Calculation*.mat']);
        MAT = [PathName,FileName];
        XLS = [MAT(1:length(MAT)-4),'.xls'];
        load(MAT);    
    case 'No'
        datetime = datestr(now,'yyyy-mmm-dd HH-MM-SS');
        initials = inputdlg('Please enter your initials (i.e. MD)','User ID');
        MAT = [datapath,experiment.write,'MCT Rate Calculation ',datetime,' ',char(initials),'.mat'];
        XLS = [datapath,experiment.write,'MCT Rate Calculation ',datetime,' ',char(initials),'.xls'];
        m = 1;
        t = 1;
        p = 1;
        data = zeros(length(times)*particles*frames,12);
    case 'Cancel'
        break;
end

func = mfilename('fullpath');

iptsetpref('ImshowBorder','loose');
iptsetpref('ImshowInitialMagnification', 35);
h(1) = figure;

%% Begin analysis

% Repeat for each line in the XLS sheet
while m <= length(experiment.runlist),
    
%     disp(['Current analysis: ',info.image{experiment.runlist(m)}])
    
    % Repeat for each timepoint
    while t <= length(timepoints),

        % Load each of the images at that timepoint
        w = waitbar(0,'Loading image sequence');
        for i = 1:frames,
            
            waitbar(i/frames,w);
        
            % Calculate the framenumber
            framenumber = start(timepoints(t)) + (i-1)*gap + 1;
            
            % Determine the filename
            filename = sprintf('%s%s%s%s%s%s%.4d%s',datapath,experiment.read,info.image{experiment.runlist(m)},FAD_IMAGESET_L,info.imagestart{experiment.runlist(m)},FAD_FILENAME_L,framenumber,FAD_FILETYPE_L);

            % Load the image
            if(exist(filename)),
                images(:,:,i) = imread(filename);
            else
                images(:,:,i) = uint8(zeros(imsize));
            end
            
        end
        close(w)
        
        % Repeat for each of the particles
        while p <= particles,
            
            % Display the image series to allow user to visualise the particles
            for i = preview,
                
                tic
                figure(h(1)), imshow(images(:,:,i));
                title(['Sequence Preview: Frame ',num2str(i)],'color','r')
                
                % Mark each of the previously selected particles
                for j = 1:(p-1),
                    
                    % Add the marker
                    line = (timepoints(t)-1)*frames*particles + (j-1)*frames + i;
                    rectangle('Position',[data(line,4)-dotsize,data(line,5)-dotsize,2*dotsize,2*dotsize],'Curvature',[1,1],'EdgeColor','r');
                    
                end
                
                pause(pauselength-toc);
                
            end
            
            % Select the particles
            for i = 1:frames,

                figure(h(1)), imshow(images(:,:,i));
                title(['Run: ', num2str(m) ' of ', num2str(length(experiment.runlist)),', Timepoint: ', num2str(times(timepoints(t))),' min (',num2str(timepoints(t)),' of ',num2str(max(timepoints)),'), Particle: ', num2str(p), ' of ', num2str(particles), ', Frame: ', num2str(i),' of ', num2str(frames)])
                
                % Mark each of the previously selected particles
                for j = 1:(p-1),
                    
                    % Add the marker
                    line = (timepoints(t)-1)*frames*particles + (j-1)*frames + i;
                    rectangle('Position',[data(line,4)-dotsize,data(line,5)-dotsize,2*dotsize,2*dotsize],'Curvature',[1,1],'EdgeColor','r');
                    
                end
                
                % Calculate the correct line number in the data array
                line = (timepoints(t)-1)*frames*particles + (p-1)*frames + i;
                data(line,1) = times(timepoints(t));
                data(line,2) = p;
                data(line,3) = start(timepoints(t)) + (i-1)*gap;
                [data(line,4),data(line,5),userinput] = ginput(1);
                
                % Perform action based on which button is pressed
                switch userinput,
                    % Middle button (remove all data for that particle and REPLAY)
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
            save(MAT,'experiment.runlist','timepoints','m','t','p','gap','frames','particles','start','times','data','func');
            
        end
        
        p = 1;
        t = t+1;
        
    end
    
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
    data(1:frames:length(times)*particles*frames,6:10) = NaN;
    
    % Calculate mean and standard deviation data for each timepoint
    for t = timepoints,
        
        blockstart = (t-1)*frames*particles + 1;
        blockfinish = t*frames*particles;
        data(blockstart,11) = nanmean(data(blockstart:blockfinish,10));
        data(blockstart,12) = nanstd(data(blockstart:blockfinish,10));
        data(blockstart,13) = nanmedian(data(blockstart:blockfinish,10));
        
    end
    
    % Write the results to the XLS and MAT files
    w = waitbar(0,'Saving XLS and MAT');
    if(xlswrite(XLS,data(:,:),info.imagestart{experiment.runlist(m)}))
        m = m+1;
        t = 1;
        data = zeros(length(times)*particles*frames,12);
        save(MAT,'experiment.runlist','timepoints','m','t','p','gap','frames','particles','start','times','func');
    else
        error('Failed to write XLS file! Manually save data');
    end
    close(w)

end

close all; clc;