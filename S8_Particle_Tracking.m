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

%% File parameters

if(strcmp(getenv('COMPUTERNAME'),'GT-DSK-DONNELLE')), expt.file.datapath = 'P:/'; end
if(strcmp(getenv('COMPUTERNAME'),'ASPEN')), expt.file.datapath = 'S:/Temporary/WCH/'; end
if(strcmp(getenv('COMPUTERNAME'),'THREDBO')), expt.file.datapath = 'C:/Users/Martin Donnelley/Documents/'; end

expt.file.read = [expt.file.datapath,'SPring-8/2014 A/MCT/Images/FD Corrected/'];
expt.file.write = [expt.file.datapath,'SPring-8/2014 A/MCT/Images/Processed/MCT Rate Calculation/'];
expt.file.filelist = [expt.file.datapath,'SPring-8/2014 A/MCT/Images/S8_14A_XU.csv'];
expt.file.runlist = [2:5,7:11,16:17,19:27];
expt.file.FAD_path_low = 'Low/';
expt.file.FAD_file_low = 'fad_';
expt.file.FAD_type_low = '.jpg';

%% Timing parameters

expt.timing.frameinterval = 0.2;                                            % Time between frames in seconds
expt.timing.blockimages = 40;                                               % Number of images per block
expt.timing.imsize = [2560,2160];                                           % Image size in pixels
expt.timing.pixelsize = 1.43/2560;                                          % Pixel size in mm

%% Analysis parameters

expt.analysis.particles = 200;                                              % Number of particles to track
expt.analysis.frames = 20;                                                  % Number of frames to track each particle for (up to a total of blockimages per block)
expt.analysis.times = [0,3,5:11];                                           % Timepoint in minutes
expt.analysis.gap = 5;                                                      % Gap between each analysis frame
expt.analysis.startframe = 10;                                              % Frame number to start with
expt.analysis.timepoints = 1:length(expt.analysis.times);                   % Timepoints to analyse
expt.analysis.starttimes = expt.timing.blockimages * expt.analysis.times + expt.analysis.startframe;           % Timepoint in frames

direction = 'Reverse';                                                      % Preview direction (Forward or Reverse)
dotsize = 35;                                                               % Marker size (20 for small particles and 35 for large)
pauselength = 0.1;                                                          % Time between frames in preview sequence

%% Perform setup

switch direction
    case 'Forward'
        preview = 1:expt.analysis.frames;
    case 'Reverse'
        preview = expt.analysis.frames:-1:1;
end

% Select whether to start or continue an analysis
button = questdlg('Would you like to continue an analysis?');

switch button    
    case 'Yes'
        [FileName,PathName] = uigetfile('*.mat','Select a file',[expt.file.datapath,expt.file.write,'/MCT Rate Calculation*.mat']);
        MAT = [PathName,FileName];
        XLS = [MAT(1:length(MAT)-4),'.xls'];
        load(MAT);    
    case 'No'
        datetime = datestr(now,'yyyy-mmm-dd HH-MM-SS');
        initials = inputdlg('Please enter your initials (i.e. MD)','User ID');
        MAT = [expt.file.write,'MCT Rate Calculation ',datetime,' ',char(initials),'.mat'];
        XLS = [expt.file.write,'MCT Rate Calculation ',datetime,' ',char(initials),'.xls'];
        m = 1;
        t = 1;
        p = 1;
        data = zeros(length(expt.analysis.times)*expt.analysis.particles*expt.analysis.frames,12);
        expt.info = ReadS8Data(expt.file.filelist);
        expt.file.runlist = expt.file.runlist(randperm(length(expt.file.runlist))); % Randomise the runlist order to blind observer
    case 'Cancel'
        break;
end

func = mfilename('fullpath');

iptsetpref('ImshowBorder','loose');
iptsetpref('ImshowInitialMagnification', 35);
h(1) = figure;

%% Begin analysis

% Repeat for each line in the XLS sheet
while m <= length(expt.file.runlist),

    % Repeat for each timepoint
    while t <= length(expt.analysis.timepoints),

        % Load each of the images at that timepoint
        w = waitbar(0,'Loading image sequence');
        for i = 1:expt.analysis.frames,
            
            waitbar(i/expt.analysis.frames,w);
        
            % Calculate the framenumber
            framenumber = expt.analysis.starttimes(expt.analysis.timepoints(t)) + (i-1)*expt.analysis.gap + 1;
            
            % Determine the filename
            filename = sprintf('%s%s%s%s%s%.4d%s',...
                expt.file.read,...
                expt.info.image{expt.file.runlist(m)},...
                expt.file.FAD_path_low,...
                expt.info.imagestart{expt.file.runlist(m)},...
                expt.file.FAD_file_low,...
                framenumber,...
                expt.file.FAD_type_low);

            % Load the image
            if(exist(filename)),
                images(:,:,i) = imread(filename);
            else
                images(:,:,i) = uint8(zeros(expt.timing.imsize));
            end
            
        end
        close(w)
        
        % Repeat for each of the particles
        while p <= expt.analysis.particles,
            
            % Display the image series to allow user to visualise the particles
            for i = preview,
                
                tic
                figure(h(1)), imshow(images(:,:,i));
                title(['Sequence Preview: Frame ',num2str(i)],'color','r')
                
                % Mark each of the previously selected particles
                for j = 1:(p-1),
                    
                    % Add the marker
                    line = (expt.analysis.timepoints(t)-1)*expt.analysis.frames*expt.analysis.particles + (j-1)*expt.analysis.frames + i;
                    rectangle('Position',[data(line,4)-dotsize,data(line,5)-dotsize,2*dotsize,2*dotsize],'Curvature',[1,1],'EdgeColor','r');
                    
                end
                
                pause(pauselength-toc);
                
            end
            
            % Select the particles
            for i = 1:expt.analysis.frames,

                figure(h(1)), imshow(images(:,:,i));
                title(['Run: ', num2str(m) ' of ', num2str(length(expt.file.runlist)),', ',...
                    'Timepoint: ', num2str(expt.analysis.timepoints(t)),' of ',num2str(max(expt.analysis.timepoints)),', ',...
                    'Particle: ', num2str(p), ' of ', num2str(expt.analysis.particles), ', ',...
                    'Frame: ', num2str(i),' of ', num2str(expt.analysis.frames)])
                
                % Mark each of the previously selected particles
                for j = 1:(p-1),
                    
                    % Add the marker
                    line = (expt.analysis.timepoints(t)-1)*expt.analysis.frames*expt.analysis.particles + (j-1)*expt.analysis.frames + i;
                    rectangle('Position',[data(line,4)-dotsize,data(line,5)-dotsize,2*dotsize,2*dotsize],'Curvature',[1,1],'EdgeColor','r');
                    
                end
                
                % Calculate the correct line number in the data array
                line = (expt.analysis.timepoints(t)-1)*expt.analysis.frames*expt.analysis.particles + (p-1)*expt.analysis.frames + i;
                data(line,1) = expt.analysis.times(expt.analysis.timepoints(t));
                data(line,2) = p;
                data(line,3) = expt.analysis.starttimes(expt.analysis.timepoints(t)) + (i-1)*expt.analysis.gap;
                [data(line,4),data(line,5),userinput] = ginput(1);
                
                % Perform action based on which button is pressed
                switch userinput,
                    % Middle button (remove all data for that particle and REPLAY)
                    case 2
                        data(line-i+1:line-i+expt.analysis.frames,4:5)=-10;
                        p=p-1;
                        break;
                    % Right button (Finish current particle and start next PARTICLE)
                    case 3
                        data(line:line-i+expt.analysis.frames,4:5)=-10;
                        break;
                    % Zero key (Finish current particle and start next TIMEPOINT)
                    case 48
                        p = expt.analysis.particles;
                        data(line:line-i+expt.analysis.frames,4:5)=-10;
                        break;
                    % One key (Remove current and previous particles and start previous particle)
                    case 49
                        data(line-i+1:line-i+expt.analysis.frames,4:5)=-10;
                        if(p > 1), p=p-2; else p=p-1; end
                        break;
                end
  
            end
            
            p=p+1;
            save(MAT,'expt','m','t','p');
            
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
    data(:,7)=data(:,6)*expt.timing.pixelsize;
    data(:,8)=dt;
    data(:,9)=data(:,8)*expt.timing.frameinterval/60;
    data(:,10)=data(:,7)./data(:,9);
    
    % Remove the data from the first particle in each sequence
    data(1:expt.analysis.frames:length(expt.analysis.times)*expt.analysis.particles*expt.analysis.frames,6:10) = NaN;
    
    % Calculate mean and standard deviation data for each timepoint
    for t = expt.analysis.timepoints,
        
        blockstart = (t-1)*expt.analysis.frames*expt.analysis.particles + 1;
        blockfinish = t*expt.analysis.frames*expt.analysis.particles;
        data(blockstart,11) = nanmean(data(blockstart:blockfinish,10));
        data(blockstart,12) = nanstd(data(blockstart:blockfinish,10));
        data(blockstart,13) = nanmedian(data(blockstart:blockfinish,10));
        
    end
    
    % Write the results to the XLS and MAT files
    w = waitbar(0,'Saving XLS and MAT');
    if(xlswrite(XLS,data(:,:),expt.info.imagestart{expt.file.runlist(m)}))
        m = m+1;
        t = 1;
        data = zeros(length(expt.analysis.times)*expt.analysis.particles*expt.analysis.frames,12);
        save(MAT,'expt','m','t','p');
    else
        error('Failed to write XLS file! Manually save data');
    end
    close(w)

end

close all; clc;