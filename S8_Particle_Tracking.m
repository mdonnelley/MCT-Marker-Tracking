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
% XLS Columns: timepoint, particle, framenumber, x, y, pixeldistance, mm, frames, min, rate, mean, stdev

%% Perform setup

% Set the base pathname for the current machine
setbasepath;

% Select whether to start or continue an analysis
button = questdlg('Would you like to continue an analysis?');

switch button    
    case 'Yes'
        
        [filename,pathname] = uigetfile('*.mat','Select a file',[basepath,'/MCT Rate Calculation*.mat']);
        MAT = [pathname,filename];
        XLS = [MAT(1:length(MAT)-4),'.xls'];
        load(MAT);    
    
    case 'No'
        
        experiment = uigetfile('*.mat','Select an experiment','/*.m');
        run(experiment);
        expt.info = ReadS8Data(expt.file.filelist);
        expt.tracking.runlist = expt.tracking.runlist(randperm(length(expt.tracking.runlist)));     % Randomise the runlist order to blind observer 
        
        timepoints = randperm(length(expt.tracking.times));                                         % Randomise the timepoints to analyse
        data = NaN(length(expt.tracking.times)*expt.tracking.particles*expt.tracking.frames,12);
        m = 1;
        t = 1;
        p = 1;
        
        datetime = datestr(now,'yyyy-mmm-dd HH-MM-SS');
        initials = inputdlg('Please enter your initials (i.e. MD)','User ID');
        MAT = [basepath,expt.tracking.MCT,'MCT Rate Calculation ',datetime,' ',char(initials),'.mat'];
        XLS = [basepath,expt.tracking.MCT,'MCT Rate Calculation ',datetime,' ',char(initials),'.xls'];
        if(~exist([basepath,expt.tracking.MCT])), mkdir([basepath,expt.tracking.MCT]); end
        
    case 'Cancel'
        
        return;
        
end

pauselength = 0.1;                                                                      % Time between frames in preview sequence
preview = expt.tracking.frames:-1:1;                                                    % Set preview to show in reverse direction
starttimes = expt.timing.blockimages * expt.tracking.times + expt.tracking.startframe;  % Set the start timepoints (in frames)

iptsetpref('ImshowBorder','loose');
iptsetpref('ImshowInitialMagnification', 35);
h(1) = figure;

%% Begin analysis

% Repeat for each line in the XLS sheet
while m <= length(expt.tracking.runlist),

    % Repeat for each timepoint
    while t <= length(timepoints),

        % Load each of the images at that timepoint
        w = waitbar(0,'Loading image sequence');
        for i = 1:expt.tracking.frames,
            
            waitbar(i/expt.tracking.frames,w);
        
            % Calculate the framenumber
            framenumber = starttimes(timepoints(t)) + (i - 1) * expt.tracking.gap + 1;
            
            % Determine the filename
            filename = sprintf('%s%s%s%s%s%.4d%s',...
                [basepath,expt.fad.corrected],...
                expt.info.image{expt.tracking.runlist(m)},...
                expt.fad.FAD_path_low,...
                expt.info.imagestart{expt.tracking.runlist(m)},...
                expt.fad.FAD_file_low,...
                framenumber,...
                expt.fad.FAD_type_low);

            % Load the image
            if(exist(filename)),
                images(:,:,i) = imread(filename);
            else
                images(:,:,i) = uint8(zeros(expt.timing.imsize));
            end
            
        end
        close(w)
        
        % Repeat for each of the particles
        while p <= expt.tracking.particles,
            
            % Display the image series to allow user to visualise the particles
            for i = preview,
                
                tic
                figure(h(1)), imshow(images(:,:,i));
                title(['Sequence Preview: Frame ',num2str(i)],'color','r')
                
                % Mark each of the previously selected particles
                for j = 1:(p-1),
                    
                    % Add the marker
                    line = (timepoints(t)-1)*expt.tracking.frames*expt.tracking.particles + (j-1)*expt.tracking.frames + i;
                    if(~isnan(data(line,1))) rectangle('Position',[data(line,4)-expt.tracking.dotsize,data(line,5)-expt.tracking.dotsize,2*expt.tracking.dotsize,2*expt.tracking.dotsize],'Curvature',[1,1],'EdgeColor','r'); end
                    
                end
                
                pause(pauselength-toc);
                
            end
            
            % Select the particles
            for i = 1:expt.tracking.frames,

                figure(h(1)), imshow(images(:,:,i));
                title(['Run: ', num2str(m) ' of ', num2str(length(expt.tracking.runlist)),', ',...
                    'Timepoint: ', num2str(t),' of ',num2str(length(timepoints)),', ',...
                    'Particle: ', num2str(p), ' of ', num2str(expt.tracking.particles), ', ',...
                    'Frame: ', num2str(i),' of ', num2str(expt.tracking.frames)])
                
                % Mark each of the previously selected particles
                for j = 1:(p-1),
                    
                    % Add the marker
                    line = (timepoints(t)-1)*expt.tracking.frames*expt.tracking.particles + (j-1)*expt.tracking.frames + i;
                    if(~isnan(data(line,1))) rectangle('Position',[data(line,4)-expt.tracking.dotsize,data(line,5)-expt.tracking.dotsize,2*expt.tracking.dotsize,2*expt.tracking.dotsize],'Curvature',[1,1],'EdgeColor','r'); end
                    
                end

                % Calculate the correct line number in the data array
                line = (timepoints(t)-1)*expt.tracking.frames*expt.tracking.particles + (p-1)*expt.tracking.frames + i;

                % Get the user input
                [x, y, userinput] = ginput(1);
                
                % Perform action based on which button is pressed
                switch userinput,
                    % Left button (select and track a particle)
                    case 1
                        data(line,1) = expt.tracking.times(timepoints(t));
                        data(line,2) = p;
                        data(line,3) = starttimes(timepoints(t)) + (i-1)*expt.tracking.gap;
                        data(line,4) = x;
                        data(line,5) = y;
                    % Middle button (remove all data for that particle and REPLAY)
                    case 2
                        data(line-i+1:line-i+expt.tracking.frames,4:5)=NaN;
                        p=p-1;
                        break;
                    % Right button (Finish current particle and start next PARTICLE)
                    case 3
                        data(line:line-i+expt.tracking.frames,4:5)=NaN;
                        break;
                    % Zero key (Finish current particle and start next TIMEPOINT)
                    case 48
                        p = expt.tracking.particles;
                        data(line:line-i+expt.tracking.frames,4:5)=NaN;
                        break;
                    % One key (Remove current and previous particles and start previous particle)
                    case 49
                        data(line-i+1:line-i+expt.tracking.frames,4:5)=NaN;
                        if(p > 1), p=p-2; else p=p-1; end
                        break;
                end
  
            end
            
            p=p+1;
            
            % Save the temporary results in the MAT file
            save(MAT,'expt','m','t','p','timepoints','data');
            
        end
        
        p = 1;
        t = t+1;
        
    end
    
    % Remove any data from selections outside the image area
    data(data(:,4) < 0,:) = NaN;
    data(data(:,4) >  expt.timing.imsize(2),:) = NaN;
    data(data(:,5) < 0,:) = NaN;
    data(data(:,5) > expt.timing.imsize(1),:) = NaN;

    % Complete the calculations
    dt = data(:,3) - circshift(data(:,3),[1 0]);
    dx = data(:,4) - circshift(data(:,4),[1 0]);
    dy = data(:,5) - circshift(data(:,5),[1 0]);
    data(:,6)=sqrt(dx.^2 + dy.^2);
    data(:,7)=data(:,6)*expt.timing.pixelsize;
    data(:,8)=dt;
    data(:,9)=data(:,8)*expt.timing.frameinterval/60;
    data(:,10)=data(:,7)./data(:,9);
    
    % Remove the data from the first particle in each sequence
    data(1:expt.tracking.frames:length(expt.tracking.times)*expt.tracking.particles*expt.tracking.frames,6:10) = NaN;
    
    % Condense the data by removing unnecessary rows
    data(isnan(data(:,1)),:) = [];

    % Calculate mean and standard deviation data for each timepoint
    [C,ia,ic] = unique(data(:,1));
    for i = 1:length(C),
        data(ia(i),11) = nanmean(data(data(:,1) == C(i),10));
        data(ia(i),12) = nanstd(data(data(:,1) == C(i),10));
    end
    
    % Write the results to the XLS and MAT files
    w = waitbar(0,'Saving XLS and MAT');
    if(xlswrite(XLS,data(:,:),expt.info.imagestart{expt.tracking.runlist(m)}))
        m = m+1;
        t = 1;
        data = NaN(length(expt.tracking.times)*expt.tracking.particles*expt.tracking.frames,12);
        if m < length(expt.tracking.runlist),
            save(MAT,'expt','m','t','p','timepoints');
        else
            save(MAT,'expt','timepoints');
        end
    else
        error('Failed to write XLS file! Manually save data');
    end
    close(w)

end

% Collate all the data in the XLS file
S8_Collate_Tracking_Results(XLS);
S8_Display_Particle_Tracks(XLS);

close all; clc;