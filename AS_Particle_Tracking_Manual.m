function AS_Particle_Tracking_Manual

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

% Time between frames in preview sequence
pauselength = 0.2;

% Set the axis visible for grid lines
iptsetpref('ImshowAxesVisible','on');
iptsetpref('ImshowBorder','loose');
iptsetpref('ImshowInitialMagnification', 40);

tmpdata = [];

% Select whether to start or continue an analysis
button = questdlg('Would you like to continue or begin a new analysis?', 'Analysis options', 'Continue', 'New', 'New');

switch button
    case 'Continue'
        
        [filename,pathname] = uigetfile('*.mat','Select a file',[basepath,'/MCT*.mat']);
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
        expt.tracking(tracked).blocks = expt.tracking(tracked).blocks(randperm(length(expt.tracking(tracked).blocks)));        % Randomise the timepoints to analyse

        m = 1;
        t = 1;
        p = 1;
        complete = false;
        
        datetime = datestr(now,'yyyy-mmm-dd HH-MM-SS');
        initials = inputdlg('Please enter your initials (i.e. MD)','User ID');
        file = ['MCT ',datetime,' ',char(initials)];
        MAT = [basepath,expt.tracking(tracked).MCT,file,'.mat'];
        XLS = [basepath,expt.tracking(tracked).MCT,file,'.xls'];
        if(~exist([basepath,expt.tracking(tracked).MCT])), mkdir([basepath,expt.tracking(tracked).MCT]); end
        
        data = cell.empty(length(expt.info.imagestart),0);
        
end

if isfield(expt.naming,'zeropad') zeropad = expt.naming.zeropad; else zeropad = 4; end
h = figure;

% Load the frames to analyse
load([basepath,...
    expt.file.datapath,...
    'Processed/',...
    'Framelist 2017-Jul-05 14-02-55.mat'],...
    'keepframes');

%% Begin analysis

% Repeat for each line in the XLS sheet
while m <= length(expt.tracking(tracked).runlist),

    % Repeat for each timepoint
    while t <= length(expt.tracking(tracked).times),

        % Load each of the images at that timepoint
        for i = 1:length(keepframes{expt.tracking(tracked).runlist(m)}{expt.tracking(tracked).blocks(t)}),
            
            % Calculate the framenumber
            framenumber(i) = keepframes{expt.tracking(tracked).runlist(m)}{expt.tracking(tracked).blocks(t)}(i);
            
            % Determine the filename
            imagename = [basepath,...
                expt.fad.corrected,...
                expt.info.image{expt.tracking(tracked).runlist(m)},...
                expt.fad.FAD_path_low,...
                expt.info.imagestart{expt.tracking(tracked).runlist(m)},...
                expt.fad.FAD_file_low,...
                sprintf(['%.',num2str(zeropad),'d'],framenumber(i)),...
                expt.fad.FAD_type_low];
            
            % Load the image
            if exist(imagename),
                disp(['Loading image ', num2str(i), ' of ', num2str(length(keepframes{expt.tracking(tracked).runlist(m)}{expt.tracking(tracked).blocks(t)}))]);
                [images(:,:,i),acquired(i)] = ReadFileTime(imagename);
            else
                images(:,:,i) = uint8(zeros(expt.tracking(tracked).imsize));
            end
            
        end
        
        acquired = acquired ./ 60;
        
        % Repeat for each of the particles
        while p < expt.tracking(tracked).particles,
            
            % Display the image series to allow user to visualise the particles
            for i = length(keepframes{expt.tracking(tracked).runlist(m)}{expt.tracking(tracked).blocks(t)}):-1:1,
                
                tic
                figure(h), imshow(images(:,:,i));
                grid on
                title(['Sequence Preview: Frame ',num2str(i)],'color','r')
                
                if ~isempty(tmpdata),
                    
                    % Determine the previous particles to mark
                    previous = find((tmpdata(:,1) == t) & (tmpdata(:,3) == framenumber(i)));
                    
                    % Mark each of the previously selected particles
                    for j = 1:length(previous), rectangle('Position',[tmpdata(previous(j),4)-expt.tracking(tracked).radius,tmpdata(previous(j),5)-expt.tracking(tracked).radius,2*expt.tracking(tracked).radius,2*expt.tracking(tracked).radius],'Curvature',[1,1],'EdgeColor','r'); end
                    
                end
                
                pause(pauselength-toc);
                
            end
            
            % Select the particles
            for i = 1:length(keepframes{expt.tracking(tracked).runlist(m)}{expt.tracking(tracked).blocks(t)}),
                
                figure(h), imshow(images(:,:,i));
                grid on
                title(['Run: ', num2str(m) ' of ', num2str(length(expt.tracking(tracked).runlist)),', ',...
                    'Timepoint: ', num2str(t),' of ',num2str(length(expt.tracking(tracked).times)),', ',...
                    'Particle: ', num2str(p), ' of ', num2str(expt.tracking(tracked).particles), ', ',...
                    'Frame: ', num2str(i),' of ', num2str(length(keepframes{expt.tracking(tracked).runlist(m)}{expt.tracking(tracked).blocks(t)}))])
                
                if ~isempty(tmpdata),
                    
                    % Determine the previous particles to mark
                    previous = find((tmpdata(:,1) == t) & (tmpdata(:,3) == framenumber(i)));
                    
                    % Mark each of the previously selected particles
                    for j = 1:length(previous), rectangle('Position',[tmpdata(previous(j),4)-expt.tracking(tracked).radius,tmpdata(previous(j),5)-expt.tracking(tracked).radius,2*expt.tracking(tracked).radius,2*expt.tracking(tracked).radius],'Curvature',[1,1],'EdgeColor','r'); end
                    
                end
                
                % Get the user input
                [x, y, userinput] = ginput(1);
                
                % Perform action based on which button is pressed
                switch userinput,
                    
                    % Left button (select and track a particle)
                    case 1
                        tmpdata = [tmpdata; t, p, framenumber(i), x, y, acquired(i)];
                        if i == length(keepframes{expt.tracking(tracked).runlist(m)}{expt.tracking(tracked).blocks(t)}),
                            p = p + 1;
                            break;
                        end
                        
                        % Middle button or spacebar (remove all data for that particle and REPLAY)
                    case {2, 32}
                        if i > 1,
                            tmpdata((tmpdata(:,1) == t) & (tmpdata(:,2) == p),:) = [];
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
                        tmpdata((tmpdata(:,1) == t) & (tmpdata(:,2) >= p - 1),:) = [];
                        p = p - 1;
                        if p < 1, p = 1; end
                        break;
                        
                        % X key (Finish current particle and start next LINE IN THE XLS)
                    case 120
                        p = expt.tracking(tracked).particles;
                        t = length(expt.tracking(tracked).times);
                        break;
                        
                    otherwise
                        disp('Key has no effect')
                        break;
                        
                end
                
            end
            
            % Save the temporary results in the MAT file
            save(MAT,'expt','m','t','p','tmpdata','data','tracked','complete');
            
        end
        
        p = 1;
        t = t+1;
        
    end
    
    if isempty(tmpdata),
        
        % In case no points were selected at any timepoint
        tmpdata = NaN;
        
    else
        
        % Sort the data into the correct order
        tmpdata(:,1) = expt.tracking.times(tmpdata(:,1))';
        tmpdata = sortrows(tmpdata,[1 2 3]);
        
        % Remove any data from selections outside the image area
        tmpdata(tmpdata(:,4) < 0,4:5) = NaN;
        tmpdata(tmpdata(:,4) >  expt.tracking(tracked).imsize(2),4:5) = NaN;
        tmpdata(tmpdata(:,5) < 0,4:5) = NaN;
        tmpdata(tmpdata(:,5) > expt.tracking(tracked).imsize(1),4:5) = NaN;
        
        % Perform the remainder of the MCT rate calculations
        % (timepoint) (particle #) (frame) (x) (y) (time) (pixels) (mm) (dt) (rate) (angle)
        dx = tmpdata(:,4) - circshift(tmpdata(:,4),[1 0]);
        dy = tmpdata(:,5) - circshift(tmpdata(:,5),[1 0]);
        dt = tmpdata(:,6) - circshift(tmpdata(:,6),[1 0]);
        tmpdata(:,7) = sqrt(dx.^2 + dy.^2);
        tmpdata(:,8) = tmpdata(:,7)*expt.tracking(tracked).pixelsize;
        tmpdata(:,9) = dt;
        tmpdata(:,10) = tmpdata(:,8)./tmpdata(:,9);
        tmpdata(:,11) = -sign(dy) .* (90 - atand(dx./abs(dy)));     % Relative to 90 degrees
%         tmpdata(:,11) = sign(dx) .* (90 - atand(-dy./abs(dx)));     % Angle measured from 12 o'clock position
        
        % Remove the rate data for the first recorded frame for each tracked particle
        ia = find(sum(tmpdata(:,1:2) - circshift(tmpdata(:,1:2),[1 0]) ~= 0,2) ~= 0);
        tmpdata(ia,7:11) = NaN;
        
    end
    
    %% Save the data
    disp(['Writing file ', MAT]);
    data{expt.tracking(tracked).runlist(m)} = tmpdata;
    
    m = m+1;
    t = 1;
    tmpdata = [];
    if m < length(expt.tracking(tracked).runlist),
        save(MAT,'expt','data','m','t','p','tracked','complete');
    else
        complete = true;
        save(MAT,'expt','data','tracked','complete');
    end
    
end

close(h)

% % Collate all the data in the XLS file, write particle track images and display histograms
% dataToXLSX(MAT)
% S8_Collate_Tracking_Results(MAT);
% S8_Display_Particle_Tracks(MAT);
% S8_Plot_MCT_Histogram(MAT);
% S8_Particle_Track_Movie(MAT);

close all; clc;