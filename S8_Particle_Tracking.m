function S8_Particle_Tracking

% Function to manually track movement of particles between adjacent frames
%
% NOTE 1: Track only particles that are moving. Stationary particles should
% be excluded.
%
% BUTTON ASSIGNMENT: 
%
%   LEFT MOUSE:                 Select and track a particle.
%
%   MIDDLE MOUSE (SPACEBAR):    Replay sequence
%                               Remove any selected points for the current particle
%
%   RIGHT MOUSE (UP ARROW):     Next. Finish tracking the current particle and begin the next PARTICLE
%                               NOTE: This action is not counted as a selection
%
%   RIGHT ARROW:                Move on. Finish tracking the current particle & timepoint and begin the next TIMEPOINT
%
%   LEFT ARROW:                 Go back. Remove current and previous particle and start previous particle (Only works in current timepoint)
%
%   X KEY:                      Run / animal no good. Complete the current run and begin the next LINE IN THE XLS

%% Perform setup

% Set the base pathname for the current machine
setbasepath;

% Set the axis visible for grid lines
iptsetpref('ImshowAxesVisible','on');

data = [];

% Select whether to start or continue an analysis
button = questdlg('Would you like to continue or begin a new analysis?', 'Analysis options', 'Continue', 'New', 'New');

switch button
    case 'Continue'
        
        [filename,pathname] = uigetfile('*.mat','Select a file',[basepath,'/MCT Rate Calculation*.mat']);
        if filename == 0, return; end
        MAT = [pathname,filename];
        XLS = [MAT(1:length(MAT)-4),'.xls'];
        load(MAT);
        if complete,
            disp('Tracking complete for this experimental run!')
            return;
        end
    
    case 'New'
        
        experiment = uigetfile('*.mat','Select an experiment','/*.m');
        if experiment == 0, return; end
        run(experiment);
        
        if length(expt.tracking) > 1, 
            tracked = listdlg('PromptString','Select experiment:','SelectionMode','single','ListString',num2str([1:length(expt.tracking)]'));
        else
            tracked = 1;
        end
        
        expt.info = ReadS8Data(expt.file.filelist);
        expt.tracking(tracked).runlist = expt.tracking(tracked).runlist(randperm(length(expt.tracking(tracked).runlist)));     % Randomise the runlist order to blind observer
        expt.tracking(tracked).times = expt.tracking(tracked).times(randperm(length(expt.tracking(tracked).times)));           % Randomise the timepoints to analyse

        m = 1;
        t = 1;
        p = 1;
        complete = false;
        
        datetime = datestr(now,'yyyy-mmm-dd HH-MM-SS');
        initials = inputdlg('Please enter your initials (i.e. MD)','User ID');
        MAT = [basepath,expt.tracking(tracked).MCT,'MCT Rate Calculation ',datetime,' ',char(initials),'.mat'];
        XLS = [basepath,expt.tracking(tracked).MCT,'MCT Rate Calculation ',datetime,' ',char(initials),'.xls'];
        if(~exist([basepath,expt.tracking(tracked).MCT])), mkdir([basepath,expt.tracking(tracked).MCT]); end
        
end

pauselength = 0.2;                                                                      % Time between frames in preview sequence
starttimes = expt.tracking(tracked).blockimages * expt.tracking(tracked).times + expt.tracking(tracked).startframe;  % Set the start timepoints (in frames)

iptsetpref('ImshowBorder','loose');
iptsetpref('ImshowInitialMagnification', 35);
h = figure;

%% Begin analysis

% Repeat for each line in the XLS sheet
while m <= length(expt.tracking(tracked).runlist),

    % Repeat for each timepoint
    while t <= length(starttimes),

        % Load each of the images at that timepoint
        w = waitbar(0,'Loading image sequence');
        for i = 1:expt.tracking(tracked).frames,
            
            waitbar(i/expt.tracking(tracked).frames,w);
        
            % Calculate the framenumber
            framenumber(i) = starttimes(t) + (i - 1) * expt.tracking(tracked).gap + 1;
            
            % Determine the filename
            imagename = sprintf('%s%s%s%s%s%.4d%s',...
                [basepath,expt.fad.corrected],...
                expt.info.image{expt.tracking(tracked).runlist(m)},...
                expt.fad.FAD_path_low,...
                expt.info.imagestart{expt.tracking(tracked).runlist(m)},...
                expt.fad.FAD_file_low,...
                framenumber(i),...
                expt.fad.FAD_type_low);

            % Load the image
            if exist(imagename),
                images(:,:,i) = imread(imagename);
            else
                images(:,:,i) = uint8(zeros(expt.tracking(tracked).imsize));
            end
            
        end
        close(w)
        
        % Repeat for each of the particles
        while p < expt.tracking(tracked).particles,
            
            % Display the image series to allow user to visualise the particles
            for i = expt.tracking(tracked).frames:-1:1,
                
                tic
                figure(h), imshow(images(:,:,i));
                grid on
                title(['Sequence Preview: Frame ',num2str(i)],'color','r')
                
                if ~isempty(data),
                    
                    % Determine the previous particles to mark
                    previous = find((data(:,1) == expt.tracking(tracked).times(t)) & (data(:,3) == framenumber(i)));
                    
                    % Mark each of the previously selected particles
                    for j = 1:length(previous), rectangle('Position',[data(previous(j),4)-expt.tracking(tracked).dotsize,data(previous(j),5)-expt.tracking(tracked).dotsize,2*expt.tracking(tracked).dotsize,2*expt.tracking(tracked).dotsize],'Curvature',[1,1],'EdgeColor','r'); end
                    
                end
                
                pause(pauselength-toc);
                
            end
            
            % Select the particles
            for i = 1:expt.tracking(tracked).frames,

                figure(h), imshow(images(:,:,i));
                grid on
                title(['Run: ', num2str(m) ' of ', num2str(length(expt.tracking(tracked).runlist)),', ',...
                    'Timepoint: ', num2str(t),' of ',num2str(length(starttimes)),', ',...
                    'Particle: ', num2str(p), ' of ', num2str(expt.tracking(tracked).particles), ', ',...
                    'Frame: ', num2str(i),' of ', num2str(expt.tracking(tracked).frames)])
                
                if ~isempty(data),
                    
                    % Determine the previous particles to mark
                    previous = find((data(:,1) == expt.tracking(tracked).times(t)) & (data(:,3) == framenumber(i)));
                    
                    % Mark each of the previously selected particles
                    for j = 1:length(previous), rectangle('Position',[data(previous(j),4)-expt.tracking(tracked).dotsize,data(previous(j),5)-expt.tracking(tracked).dotsize,2*expt.tracking(tracked).dotsize,2*expt.tracking(tracked).dotsize],'Curvature',[1,1],'EdgeColor','r'); end
                    
                end                

                % Get the user input
                [x, y, userinput] = ginput(1);
                
                % Perform action based on which button is pressed
                switch userinput,
                    
                    % Left button (select and track a particle)
                    case 1
                        data = [data; expt.tracking(tracked).times(t), p, framenumber(i), x, y];
                        if i == expt.tracking(tracked).frames,
                            p = p + 1;
                            break;
                        end
                        
                    % Middle button or spacebar (remove all data for that particle and REPLAY)
                    case {2, 32}
                        if i > 1,
                            data((data(:,1) == expt.tracking(tracked).times(t)) & (data(:,2) == p),:) = [];
                        end
                        break;
                        
                    % Right button (Finish current particle and start next PARTICLE)
                    case {3, 30}
                        p = p + 1;
                        break;
                        
                    % Right arrow (Finish current particle and start next TIMEPOINT)
                    case 29
                        p = expt.tracking(tracked).particles;
                        break;
                        
                    % Left arrow (Remove current and previous particles and start previous particle)
                    case 28
                        data((data(:,1) == expt.tracking(tracked).times(t)) & (data(:,2) >= p - 1),:) = [];
                        p = p - 1;
                        if p < 1, p = 1; end
                        break;
                        
                    % X key (Finish current particle and start next LINE IN THE XLS)
                    case 120
                        p = expt.tracking(tracked).particles;
                        t = length(starttimes);
                        break;
                        
                    otherwise
                        disp('Key has no effect')
                        break;
                        
                end
  
            end

            % Save the temporary results in the MAT file
            save(MAT,'expt','m','t','p','data','tracked','complete');
            
        end
        
        p = 1;
        t = t+1;
        
    end
    
    if isempty(data), 
        
        % In case no points were selected at any timepoint
        data = NaN; 
        
    else
        
        % Sort the data into the correct order
        data = sortrows(data,[1 2 3]);
        
        % Remove any data from selections outside the image area
        data(data(:,4) < 0,4:5) = NaN;
        data(data(:,4) >  expt.tracking(tracked).imsize(2),4:5) = NaN;
        data(data(:,5) < 0,4:5) = NaN;
        data(data(:,5) > expt.tracking(tracked).imsize(1),4:5) = NaN;
        
        % Complete the calculations
        dt = data(:,3) - circshift(data(:,3),[1 0]);
        dx = data(:,4) - circshift(data(:,4),[1 0]);
        dy = data(:,5) - circshift(data(:,5),[1 0]);
        data(:,6)=sqrt(dx.^2 + dy.^2);
        data(:,7)=data(:,6)*expt.tracking(tracked).pixelsize;
        data(:,8)=dt;
        data(:,9)=data(:,8)*expt.tracking(tracked).frameinterval/60;
        data(:,10)=data(:,7)./data(:,9);
        
        % Remove the data for each new particle or timepoint
        data(data(:,8) ~= expt.tracking(tracked).gap,6:10) = NaN;
        
        % Add column headings
        data = [{'Timepoint (min)', 'Particle number', 'Frame number',...
            'x', 'y', 'Distance (pixels)', 'Distance (mm)',...
            'Frames', 'Time (min)', 'Rate (mm/min)'};...
            num2cell(data)];
        
    end
    
    % Write the results to the XLS and MAT files
    w = waitbar(0,'Saving XLS and MAT');
    if xlswrite(XLS,data,expt.info.imagestart{expt.tracking(tracked).runlist(m)}),
        
        m = m+1;
        t = 1;
        data = [];
        
        if m < length(expt.tracking(tracked).runlist),
            save(MAT,'expt','m','t','p','tracked');
        else
            complete = true;
            save(MAT,'expt','tracked','complete');
        end
        
    else
        error('Failed to write XLS file! Manually save XLS and MAT data');
    end
    close(w)

end

close(h)

% Collate all the data in the XLS file, write particle track images and display histograms
S8_Collate_Tracking_Results(MAT);
S8_Display_Particle_Tracks(MAT);
S8_Plot_MCT_Histogram(MAT)

close all; clc;