function S8_Particle_Track_Movie(MAT)

% Function to output movie frames after tracking
%
% This function takes the raw XLS data and creates movie frames showing the
% location of tracked particles throughout the image sequence.

% Set the base pathname for the current machine
setbasepath;

% Set image scaling
SCALE = 1;

% w = waitbar(0,'Reading MAT and XLS data');
% load(MAT);
% XLS = [MAT(1:length(MAT)-4),'.xls'];
w = waitbar(0,'Reading MAT data');
load(MAT);

% Set the start timepoints (in frames)
startframes = expt.tracking(tracked).blockimages * sort(expt.tracking(tracked).blocks) + expt.tracking(tracked).startframe;
if isfield(expt.naming,'zeropad') zeropad = expt.naming.zeropad; else zeropad = 4; end

% % Get the sheet names
% [status,sheets] = xlsfinfo(XLS);

%% Write the annotated images
for m = 1:length(data)    

    waitbar(m/length(data),w,['Analysing: ',expt.info.imagestart{m}]);
        
        if isempty(data{m})
            
% for s = 1:length(sheets),
%     
%     waitbar(s/length(sheets),w,['Reading sheet: ',sheets{s}(1:length(sheets{s})-1)]);
%     
%     if ~strcmp(sheets{s},'Sheet1') & ~strcmp(sheets{s},'Sheet2') & ~strcmp(sheets{s},'Sheet3') & ~strcmp(sheets{s},'Mean') & ~strcmp(sheets{s},'SD') & ~strcmp(sheets{s},'Number') & ~strcmp(sheets{s},'Histogram'),
%         
%         % Read the sheet from the XLS file
%         data = xlsread(XLS,sheets{s},'','basic');
%         
%         % Get the row number
%         m = 1;
%         while ~strcmp(expt.info.imagestart{m},sheets{s}), m = m + 1; end
%         
%         if isempty(data)
            
            % Remove rows from list that have no data, so no movies made
            ind = find(expt.tracking(tracked).runlist == m);
            expt.tracking(tracked).runlist(ind) = [];
            
        else
            
            t = 1;
            framecounter = 1;
            
            % Set the output directory
            current_dir = [basepath,...
                expt.tracking(tracked).MCT,...
                file,...
                expt.tracking(tracked).movies,...
                expt.info.image{m}];

            mkdir(current_dir);
            
            % Repeat for each timepoint
            for t = 1:length(startframes),
                
                % Load each of the images at that timepoint
                waitbar(0,w,['Analysing: ',num2str(m),' of ',num2str(length(data)),': Timepoint ',num2str(t),' of ',num2str(length(startframes))]);
%                 waitbar(0,w,['Sheet ',num2str(s),' of ',num2str(length(sheets)),': Timepoint ',num2str(t),' of ',num2str(length(startframes))]);
                for i = 1:expt.tracking(tracked).frames,
                    
                    waitbar(i/expt.tracking(tracked).frames,w);
                    
                    % Calculate the framenumber
                    framenumber = startframes(t) + (i - 1) * expt.tracking(tracked).gap + 1;
                    
                    % Determine the input imagename 
                    imagename = [basepath,...
                        expt.fad.corrected,...
                        expt.info.image{m},...
                        expt.fad.FAD_path_low,...
                        expt.info.imagestart{m},...
                        expt.fad.FAD_file_low,...
                        sprintf(['%.',num2str(zeropad),'d'],framenumber),...
                        expt.fad.FAD_type_low];
                    
                    % Read the image
                    if exist(imagename),
                        im = imread(imagename);
                    else
                        im = uint8(zeros(expt.tracking(tracked).imsize));
                    end
                    
                    % Prep the image data
                    im = imresize(im,SCALE);
                    
                    % Add information text to the image
                    text = [expt.info.imagestart{m},...
                        expt.fad.FAD_file_low,...
                        sprintf('%.4d',framenumber),...
                        ' (t = ',...
                        num2str(expt.tracking(tracked).times(t)),...
                        ' min)'];
                    
                    im = insertText(im,[50 50],text,'FontSize',36,'BoxOpacity',0,'TextColor','blue');
                    
                    % Find frame numbers in data that match the current frame
                    coordinates = data((data(:,3) == framenumber) & isfinite(data(:,4)),4:5);
                    
                    if ~isempty(coordinates)
                        
                        % Add the O markers showing particle positions (30 for large and 18 for small)
                        position = [round(coordinates),24*SCALE*ones(size(coordinates,1),1)];
                        im = insertShape(im,'FilledCircle',position,'Color','red','Opacity',0.2); 
                        
                    end
                    
%                     figure(1),imshow(im)
                    
                    % Determine the output imagename and write the image                    
                    imagename = [current_dir,...
                        expt.info.imagestart{m},...
                        sprintf(['%.',num2str(zeropad),'d'],framecounter),...
                        expt.fad.FAD_type_low];
                    
                    imwrite(im,imagename);
                    framecounter = framecounter + 1;
                    
                end
            end
        end
    end
end

% Modify parameters to enable VirtualDub script to create movies from the frames
expt.fad.movies = [expt.tracking(tracked).MCT,file,expt.tracking(tracked).movies];
expt.fad.runlist = expt.tracking(tracked).runlist;
expt.fad.corrected = [expt.tracking(tracked).MCT,file,expt.tracking(tracked).movies];
expt.info.imagegofrom(1:length(expt.info.imagegofrom)) = 1;
expt.info.imagegoto(1:length(expt.info.imagegoto)) = expt.tracking(tracked).frames * length(expt.tracking(tracked).times);
expt.fad.FAD_path_low = '';
expt.fad.FAD_file_low = '';

% Call the VirtualDub script using the modified parameters above
VirtualDub(expt);