function S8_Particle_Track_Movie(MAT)

% Function to output movie frames after tracking
%
% This function takes the raw XLS data and creates movie frames showing the
% location of tracked particles throughout the image sequence.

% Set the base pathname for the current machine
setbasepath;

% Set image scaling
SCALE = 1;

w = waitbar(0,'Reading MAT and XLS data');
load(MAT);
XLS = [MAT(1:length(MAT)-4),'.xls'];

% Set the start timepoints (in frames)
startframes = expt.tracking(tracked).blockimages * expt.tracking(tracked).blocks + expt.tracking(tracked).startframe;
startframes = sort(startframes);

% Get the sheet names
[status,sheets] = xlsfinfo(XLS);

%% Write the annotated images
for s = 1:length(sheets),
    
    waitbar(s/length(sheets),w,['Reading sheet: ',sheets{s}(1:length(sheets{s})-1)]);
    
    if ~strcmp(sheets{s},'Sheet1') & ~strcmp(sheets{s},'Sheet2') & ~strcmp(sheets{s},'Sheet3') & ~strcmp(sheets{s},'Mean') & ~strcmp(sheets{s},'SD') & ~strcmp(sheets{s},'Number') & ~strcmp(sheets{s},'Histogram'),
        
        % Read the sheet from the XLS file
        data = xlsread(XLS,sheets{s},'','basic');
        
%         if ~isempty(data)
            
            t = 1;
            framecounter = 1;
            
            % Get the row number
            m = 1;
            while ~strcmp(expt.info.imagestart{m},sheets{s}), m = m + 1; end
            
            % Set the output directory
            current_dir = [basepath,expt.tracking(tracked).movies,expt.info.image{m}];
            mkdir(current_dir);
            
            % Repeat for each timepoint
            for t = 1:length(startframes),
                
                % Load each of the images at that timepoint
                waitbar(0,w,['Sheet ',num2str(s),' of ',num2str(length(sheets)),': Timepoint ',num2str(t),' of ',num2str(length(startframes))]);
                for i = 1:expt.tracking(tracked).frames,
                    
                    waitbar(i/expt.tracking(tracked).frames,w);
                    
                    % Calculate the framenumber
                    framenumber = startframes(t) + (i - 1) * expt.tracking(tracked).gap + 1;
                    
                    % Determine the input imagename and read the image
                    imagename = sprintf('%s%s%s%s%s%.4d%s',...
                        [basepath,expt.fad.corrected],...
                        expt.info.image{m},...
                        expt.fad.FAD_path_low,...
                        expt.info.imagestart{m},...
                        expt.fad.FAD_file_low,...
                        framenumber,...
                        expt.fad.FAD_type_low);

                    if exist(imagename),
                        im = imread(imagename);
                    else
                        im = uint8(zeros(expt.tracking(tracked).imsize));
                    end

                    % Prep the image data
                    im = repmat(im,[1 1 3]);
                    im = imresize(im,SCALE);

                    % Add information text to the image
                    text = sprintf('%s%s%.4d (t = %d min)',...
                        expt.info.imagestart{m},...
                        expt.fad.FAD_file_low,...
                        framenumber,...
                        expt.tracking(tracked).times(t));
                    textInserter = vision.TextInserter(text, 'Color', [0 0 255], 'FontSize', 36, 'Location', [50 50]);
                    im = step(textInserter, im);
                    
                    % Find frame numbers in data that match the current frame
                    coordinates = data((data(:,3) == framenumber) & isfinite(data(:,4)),4:5);
                    
                    if ~isempty(coordinates)
                        
                        % Add the O markers showing particle positions (30 for large and 18 for small)
                        markerInserter = vision.MarkerInserter('Shape','Circle','Size',24*SCALE,'Fill',1,'FillColor','Custom','CustomFillColor',[255 0 0],'Opacity',0.2);
                        marker = SCALE*int32(coordinates(1:size(coordinates,1),:));
                        im = step(markerInserter, im, marker);
                        
                    end
                    
                    % Determine the output imagename and write the image
                    imagename = sprintf('%s%s%.4d%s',...
                        current_dir,...
                        expt.info.imagestart{m},...
                        framecounter,...
                        expt.fad.FAD_type_low);

                    imwrite(im,imagename);
                    framecounter = framecounter + 1;
                    
                end
            end
%         end
    end
end

close(w)

% Modify parameters to enable VirtualDub script to create movies from the frames
expt.fad.movies = expt.tracking(tracked).movies;
expt.fad.runlist = expt.tracking(tracked).runlist;
expt.fad.corrected = expt.tracking(tracked).movies;
expt.info.imagegofrom(1:length(expt.info.imagegofrom)) = 1;
expt.info.imagegoto(1:length(expt.info.imagegoto)) = expt.tracking(tracked).frames * length(expt.tracking(tracked).times);
expt.fad.FAD_path_low = '';
expt.fad.FAD_file_low = '';

% Call the VirtualDub script using the modified parameters above
VirtualDub(expt);