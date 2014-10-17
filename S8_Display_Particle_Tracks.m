% Script to display particle tracks on images
%
% This function takes the raw XLS data and draws the particle tracks on the
% images at the correct timepoints. Only images for which tracking data
% exist are output.

function S8_Display_Particle_Tracks(XLS)

% Set the base pathname for the current machine
setbasepath;

SCALE = 0.5;

MAT = [XLS(1:length(XLS)-4),'.mat'];
load(MAT);

if ~exist([basepath,[basepath,expt.tracking.tracks]]), mkdir([basepath,expt.tracking.tracks]), end

% Get the sheet names
[status,sheets] = xlsfinfo(XLS);

%% Write the annotated images
for s = 1:length(sheets),
    
    if ~strcmp(sheets{s},'Sheet1') & ~strcmp(sheets{s},'Sheet2') & ~strcmp(sheets{s},'Sheet3') & ~strcmp(sheets{s},'Mean') & ~strcmp(sheets{s},'SD') & ~strcmp(sheets{s},'Number'),
        
        % Read the sheet from the XLS file
        data = xlsread(XLS,sheets{s},'','basic');
        
        if ~isempty(data)
            
            % Get the row number
            m = 1;
            while ~strcmp(expt.info.imagestart{m},sheets{s}), m = m + 1; end
            
            % Determine the timepoints to analyse
            trackingtimes = unique(data(:,1));
            starttimes = expt.timing.blockimages * trackingtimes + expt.tracking.startframe;  % Set the start timepoints (in frames)
            
            for t = 1:length(starttimes),
                
                % Calculate the framenumber
                framenumber = starttimes(t) + 1;
                
                % Determine the filename
                filename = sprintf('%s%s%s%s%s%.4d%s',...
                    [basepath,expt.fad.corrected],...
                    expt.info.image{m},...
                    expt.fad.FAD_path_low,...
                    expt.info.imagestart{m},...
                    expt.fad.FAD_file_low,...
                    framenumber,...
                    expt.fad.FAD_type_low);
                
                % Load and prep the image data
                im = imread(filename);
                im = repmat(im,[1 1 3]);
                im = imresize(im,SCALE);
                
                for p = unique(data(data(:,1) == trackingtimes(t), 2))'
                  
                    % Get the coordinates of the current particle
                    coordinates = data((data(:,1) == trackingtimes(t)) & (data(:,2) == p) & isfinite(data(:,4)), 4:5);
                    
                    % Add the X marker showing initial position
                    markerInserter = vision.MarkerInserter ('Shape','X-mark','Size',10,'BorderColor','Custom','CustomBorderColor',[255 0 0]);
                    marker = SCALE*int32(coordinates(1,:));
                    im = step(markerInserter, im, marker);
                    
                    % Add the O markers showing subsequent positions
                    markerInserter = vision.MarkerInserter ('Shape','Circle','Size',2,'Fill',1,'FillColor','Custom','CustomFillColor',[0 0 255]);
                    marker = SCALE*int32(coordinates(2:size(coordinates,1),:));
                    im = step(markerInserter, im, marker);
                    
                    % Add the line tracks joining the positions
                    shapeInserter = vision.ShapeInserter('Shape','Lines','BorderColor','Custom','CustomBorderColor',[255 255 0]);
                    shape = SCALE * reshape(coordinates',1,2*size(coordinates,1));
                    im = step(shapeInserter, im, int32(shape));
                    
                end
                
                % Write the image
                filename = sprintf('%s%s%s%s%.1f%s%s',basepath,expt.tracking.tracks,sheets{s},'_',trackingtimes(t),'_min',expt.fad.FAD_type_low);
                imwrite(im,filename);
                
            end
            
        end
        
    end
    
end