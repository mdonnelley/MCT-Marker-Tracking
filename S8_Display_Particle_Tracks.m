function S8_Display_Particle_Tracks(MAT)

% Function to display particle tracks on images
%
% This function takes the raw XLS data and draws the particle tracks on the
% images at the correct timepoints. Only images for which tracking data
% exist are output.

% Set the base pathname for the current machine
setbasepath;

SCALE = 1;

w = waitbar(0,'Reading MAT and XLS data');
load(MAT);
XLS = [MAT(1:length(MAT)-4),'.xls'];

% Set the start timepoints (in frames)
startframes = expt.tracking(tracked).blockimages * sort(expt.tracking(tracked).blocks) + expt.tracking(tracked).startframe;

if ~exist([basepath,[basepath,expt.tracking(tracked).tracks]]), mkdir([basepath,expt.tracking(tracked).tracks]), end

% Get the sheet names
[status,sheets] = xlsfinfo(XLS);

%% Write the annotated images
for s = 1:length(sheets),
    
    waitbar(s/length(sheets),w,['Reading sheet: ',sheets{s}(1:length(sheets{s})-1)]);
    
    if ~strcmp(sheets{s},'Sheet1') & ~strcmp(sheets{s},'Sheet2') & ~strcmp(sheets{s},'Sheet3') & ~strcmp(sheets{s},'Mean') & ~strcmp(sheets{s},'SD') & ~strcmp(sheets{s},'Number') & ~strcmp(sheets{s},'Histogram'),
        
        % Read the sheet from the XLS file
        data = xlsread(XLS,sheets{s},'','basic');
        
        if ~isempty(data)
            
            % Get the row number
            m = 1;
            while ~strcmp(expt.info.imagestart{m},sheets{s}), m = m + 1; end
            
            % Determine the timepoints to analyse
            times = unique(data(:,1));
            
            for t = 1:length(times),
                
                % Calculate the framenumber
                idx = find(expt.tracking(tracked).times == times(t));
                framenumber = startframes(idx) + 1;
                
                % Determine the imagename
                imagename = [basepath,...
                    expt.fad.corrected,...
                    expt.info.image{m},...
                    expt.fad.FAD_path_low,...
                    expt.info.imagestart{m},...
                    expt.fad.FAD_file_low,...
                    sprintf('%.4d',framenumber),...
                    expt.fad.FAD_type_low];
                
                if exist(imagename),
                    
                    % Load and prep the image data
                    im = imread(imagename);
                    im = repmat(im,[1 1 3]);
                    im = imresize(im,SCALE);
                    
                    % Add information text to the image
                    text = [expt.info.imagestart{m},...
                        expt.fad.FAD_file_low,...
                        sprintf('%.4d',framenumber),...
                        ' (t = ',num2str(times(t)), ' min)'];
                    
                    textInserter = vision.TextInserter(text, 'Color', [0 0 255], 'FontSize', 36, 'Location', [50 50]);
                    im = step(textInserter, im);
                    
                    for p = unique(data(data(:,1) == times(t), 2))'
                        
                        % Get the coordinates of the current particle
                        coordinates = data((data(:,1) == times(t)) & (data(:,2) == p) & isfinite(data(:,4)), 4:5);
                        
                        % % Add the X marker showing initial position
                        % markerInserter = vision.MarkerInserter('Shape','X-mark','Size',20*SCALE,'BorderColor','Custom','CustomBorderColor',[255 0 0]);
                        % marker = SCALE*int32(coordinates(1,:));
                        % im = step(markerInserter, im, marker);
                        
                        % Add the O marker showing the initial position (30 for large and 18 for small)
                        markerInserter = vision.MarkerInserter('Shape','Circle','Size',18*SCALE,'Fill',1,'FillColor','Custom','CustomFillColor',[255 0 0],'Opacity',0.2);
                        marker = SCALE*int32(coordinates(1,:));
                        im = step(markerInserter, im, marker);
                        
                        % Add the O markers showing subsequent positions
                        markerInserter = vision.MarkerInserter('Shape','Circle','Size',8*SCALE,'Fill',1,'FillColor','Custom','CustomFillColor',[0 0 255],'Opacity',0.5);
                        marker = SCALE*int32(coordinates(2:size(coordinates,1),:));
                        im = step(markerInserter, im, marker);
                        
                        if size(coordinates,1) > 1,
                            
                            % Add the line tracks joining the positions
                            shapeInserter = vision.ShapeInserter('Shape','Lines','BorderColor','Custom','CustomBorderColor',[255 255 0]);
                            shape = SCALE * reshape(coordinates',1,2*size(coordinates,1));
                            im = step(shapeInserter, im, int32(shape));
                            
                        end
                        
                        figure(1),imshow(im)
                        
                    end
                    
                    % Determine the imagename
                    imagename = sprintf('%s%s%s%s%+05.1f%s',...
                        basepath,...
                        expt.tracking(tracked).tracks,...
                        sheets{s},...
                        '_t',...
                        times(t),...
                        expt.fad.FAD_type_low);
                    
                    % Write the image
                    imwrite(im,imagename);
                    
                end
                
            end
            
        end
        
    end
    
end

close(w)