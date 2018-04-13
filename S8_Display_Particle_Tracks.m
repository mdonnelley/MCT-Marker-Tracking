function S8_Display_Particle_Tracks(MAT)

% Function to display particle tracks on images
%
% This function takes the raw XLS data and draws the particle tracks on the
% images at the correct timepoints. Only images for which tracking data
% exist are output.

% Set the base pathname for the current machine
setbasepath;

SCALE = 1;

% w = waitbar(0,'Reading MAT and XLS data');
% load(MAT);
% XLS = [MAT(1:length(MAT)-4),'.xls'];
w = waitbar(0,'Reading MAT data');
load(MAT);

% Set the start timepoints (in frames)
startframes = expt.tracking(tracked).blockimages * sort(expt.tracking(tracked).blocks) + expt.tracking(tracked).startframe;
if isfield(expt.naming,'zeropad') zeropad = expt.naming.zeropad; else zeropad = 4; end
if ~exist([MAT(1:length(MAT)-4),expt.tracking(tracked).tracks]), mkdir([MAT(1:length(MAT)-4),expt.tracking(tracked).tracks]), end

% % Get the sheet names
% [status,sheets] = xlsfinfo(XLS);

%% Write the annotated images
for m = 1:length(data)
    
    waitbar(m/length(data),w,['Analysing: ',expt.info.imagestart{m}]);
    
    if ~isempty(data{m})
        %
        % for s = 1:length(sheets),
        %
        %     waitbar(s/length(sheets),w,['Reading sheet: ',sheets{s}(1:length(sheets{s})-1)]);
        %
        %     if ~strcmp(sheets{s},'Sheet1') & ~strcmp(sheets{s},'Sheet2') & ~strcmp(sheets{s},'Sheet3') & ~strcmp(sheets{s},'Mean') & ~strcmp(sheets{s},'SD') & ~strcmp(sheets{s},'Number') & ~strcmp(sheets{s},'Histogram'),
        %
        %         % Read the sheet from the XLS file
        %         data = xlsread(XLS,sheets{s},'','basic');
        %
        %         if ~isempty(data)
        %
        %             % Get the row number
        %             m = 1;
        %             while ~strcmp(expt.info.imagestart{m},sheets{s}), m = m + 1; end
        
        % Determine the timepoints to analyse
        times = unique(data{m}(:,1));
        
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
                sprintf(['%.',num2str(zeropad),'d'],framenumber),...
                expt.fad.FAD_type_low];
            
            if exist(imagename),
                
                % Load and prep the image data
                im = imread(imagename);
                im = repmat(im,[1 1 3]);
                im = imresize(im,SCALE);
                
                % Add information text to the image
                text = [expt.info.imagestart{m},...
                    expt.fad.FAD_file_low,...
                    sprintf(['%.',num2str(zeropad),'d'],framenumber),...
                    ' (t = ',num2str(times(t)), ' min)'];
                
                im = insertText(im,[50 50],text,'FontSize',36,'BoxOpacity',0,'TextColor','blue');
                
                for p = unique(data{m}(data{m}(:,1) == times(t), 2))'
                    
                    % Get the coordinates of the current particle
                    coordinates = data{m}((data{m}(:,1) == times(t)) & (data{m}(:,2) == p) & isfinite(data{m}(:,4)), 4:5);
                    
                    % Add the O marker showing the initial position (30 for large and 18 for small)
                    position = [round(coordinates(1,:)),18*SCALE];
                    im = insertShape(im,'FilledCircle',position,'Color','red','Opacity',0.2);
                    
                    % Add the O markers showing subsequent positions
                    position = [round(coordinates(2:size(coordinates,1),:)),8*SCALE*ones(size(coordinates,1)-1,1)];
                    im = insertShape(im,'FilledCircle',position,'Color','blue','Opacity',0.5);
                    
                    if size(coordinates,1) > 1,
                        
                        % Add the line tracks joining the positions
                        position = SCALE * reshape(coordinates',1,2*size(coordinates,1));
                        im = insertShape(im,'Line',position,'Color','yellow','Opacity',0.5);
                        
                    end
                    
                    %                         figure(1),imshow(im)
                    
                end
                
                % Determine the imagename
                imagename = [basepath,...
                    expt.tracking(tracked).MCT...
                    file,...
                    expt.tracking(tracked).tracks,...
                    expt.info.imagestart{m},...
                    '_t',...
                    sprintf('%+05.1f',times(t)),...
                    expt.fad.FAD_type_low];
                
                % Write the image
                imwrite(im,imagename);
                
            end
            
        end
        
    end

end

close(w)