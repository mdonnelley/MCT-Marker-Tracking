function S8_Particle_Track_Movie(MAT)

% Function to output movie frames after tracking
%
% This function takes the raw XLS data and creates movie frames showing the
% location of tracked particles throughout the image sequence.

% Set the base pathname for the current machine
setbasepath;

SCALE = 0.5;

w = waitbar(0,'Reading MAT and XLS data');
load(MAT);
XLS = [MAT(1:length(MAT)-4),'.xls'];

% Set the start timepoints (in frames)
starttimes = expt.tracking(tracked).blockimages * expt.tracking(tracked).times + expt.tracking(tracked).startframe;
starttimes = sort(starttimes);

% Get the sheet names
[status,sheets] = xlsfinfo(XLS);

%% Write the annotated images
for s = 1:length(sheets),
    
    waitbar(s/length(sheets),w,['Reading sheet: ',sheets{s}(1:length(sheets{s})-1)]);
    
    if ~strcmp(sheets{s},'Sheet1') & ~strcmp(sheets{s},'Sheet2') & ~strcmp(sheets{s},'Sheet3') & ~strcmp(sheets{s},'Mean') & ~strcmp(sheets{s},'SD') & ~strcmp(sheets{s},'Number') & ~strcmp(sheets{s},'Histogram'),
        
        % Read the sheet from the XLS file
        data = xlsread(XLS,sheets{s},'','basic');
        
        if ~isempty(data)
            
            t = 1;
            framecounter = 1;
            
            % Get the row number
            m = 1;
            while ~strcmp(expt.info.imagestart{m},sheets{s}), m = m + 1; end
            
            % Set the output directory
            current_dir = [basepath,expt.tracking(tracked).movies,expt.info.image{m}];
            mkdir(current_dir);
            
            % Repeat for each timepoint
            for t = 1:length(starttimes),
                
                % Load each of the images at that timepoint
                waitbar(0,w,['Sheet ',num2str(s),' of ',num2str(length(sheets)),': Timepoint ',num2str(t),' of ',num2str(length(starttimes))]);
                for i = 1:expt.tracking(tracked).frames,
                    
                    waitbar(i/expt.tracking(tracked).frames,w);
                    
                    % Calculate the framenumber
                    framenumber(i) = starttimes(t) + (i - 1) * expt.tracking(tracked).gap + 1;
                    
                    % Determine the imagename
                    imagename = sprintf('%s%s%s%s%s%.4d%s',...
                        [basepath,expt.fad.corrected],...
                        expt.info.image{m},...
                        expt.fad.FAD_path_low,...
                        expt.info.imagestart{m},...
                        expt.fad.FAD_file_low,...
                        framenumber(i),...
                        expt.fad.FAD_type_low)
                    
                    if exist(imagename),
                        
                        % Load and prep the image data
                        im = imread(imagename);
                        im = repmat(im,[1 1 3]);
                        im = imresize(im,SCALE);
                        
                        % Find frame numbers in data that match the current frame
                        coordinates = data((data(:,3) == framenumber(i)) & isfinite(data(:,4)),4:5);
                        
                        if ~isempty(coordinates)
                            
                            % Add the O markers showing particle positions
                            markerInserter = vision.MarkerInserter('Shape','Circle','Size',8*SCALE,'Fill',1,'FillColor','Custom','CustomFillColor',[0 0 255],'Opacity',0.5);
                            marker = SCALE*int32(coordinates(1:size(coordinates,1),:));
                            im = step(markerInserter, im, marker);
                            
                        end
                        
                        % Determine the imagename
                        imagename = sprintf('%s%s%.4d%s',...
                            current_dir,...
                            expt.info.imagestart{m},...
                            framecounter,...
                            expt.fad.FAD_type_low);
                        
                        % Write the image
                        imwrite(im,imagename);
                        framecounter = framecounter + 1;
                        
                    end
                    
                end
            end
        end
    end
end

close(w)