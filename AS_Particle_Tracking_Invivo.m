function AS_Particle_Tracking_Invivo(experiment)

setbasepath;

% Load the metadata from the dataset to analyse
run(experiment);
expt.info = ReadS8Data(expt.file.filelist);
tracked = 1;
complete = false;
if isfield(expt.naming,'zeropad') zeropad = expt.naming.zeropad; else zeropad = 4; end

% Load the frames to analyse
load([basepath,...
    expt.file.datapath,...
    'Processed/',...
    'Framelist 2017-Jul-05 14-02-55.mat'],...
    'keepframes');

% Create the data array
data = cell.empty(length(expt.info.imagestart),0);

% Output file naming
datetime = datestr(now,'yyyy-mmm-dd HH-MM-SS');
file = ['Tracking ',datetime];
XLS = [basepath,...
    expt.tracking.trackPath,...
    file,...
    '.xlsx'];
MAT = [basepath,...
    expt.tracking.trackPath,...
    file,...
    '.mat'];

% Process each experiment
for imageset = expt.tracking.runlist,
    
    disp(['Processing imageset ', num2str(imageset), ' of ', num2str(length(expt.info.image))]);
    
    subjectData = [];
 
    detectPath = [basepath,...
        expt.tracking.detectPath,...
        expt.info.image{imageset}];
    if ~exist(detectPath), mkdir(detectPath); end
    
    trackPath = [basepath,...
        expt.tracking.trackPath,...
        expt.info.image{imageset}];
    if ~exist(trackPath), mkdir(trackPath); end
    
    for t = 1:length(expt.tracking.times),
        
        timepointData = [];
        
        for i = keepframes{imageset}{t},

            imagename = [basepath,...
                expt.fad.corrected,...
                expt.info.image{imageset},...
                expt.fad.FAD_path_low,...
                expt.info.imagestart{imageset},...
                expt.fad.FAD_file_low,...
                sprintf(['%.',num2str(zeropad),'d'],i),...
                expt.fad.FAD_type_low];
            
            if exist(imagename),
                
                disp(['Identifying particles in file ', num2str(i), ' of ', num2str(expt.info.imagegoto(imageset))]);
                [inimage, time] = ReadFileTime(imagename);
                time = time / 60;
                
                corrected = im2uint8(mat2gray(correctIllumination(double(inimage))));
                im2=imadjust(corrected);
                [centersDark, radiiDark] = imfindcircles(im2,[10,40],'ObjectPolarity','dark','Sensitivity',0.75);
                
                % Find the centres (this section is different the the AS ex-vivo algorithm that used the CHT algorithm)
%                 h = adapthisteq(uint8(inimage));
%                 BW = h < expt.tracking.fgthreshold;
%                 circles = uint8(BW).* inimage;
%                 [centersDark, radiiDark] = imfindcircles(circles,[10,40],'ObjectPolarity','bright','Sensitivity',0.9);

%                 s = regionprops(BW,'centroid','area','solidity');
%                 s(find(cat(1,s.Area) < expt.tracking.minArea | cat(1,s.Area) > expt.tracking.maxArea)) = [];
%                 s(find(cat(1,s.Solidity) < expt.tracking.solidity)) = [];
%                 coordinates = cat(1, s.Centroid);
                
                % Mark the detected particles and add text
                RGB = insertShape(inimage, 'FilledCircle', [centersDark,expt.tracking.radius*2*ones(size(centersDark,1),1)], 'LineWidth', 5,'Color','red','Opacity',0.25);
                text = [expt.info.imagestart{imageset},...
                    expt.fad.FAD_file_low,...
                    sprintf(['%.',num2str(zeropad),'d'],i),...
                    ' (t = ',num2str(t), ' min)'];
                RGB = insertText(RGB,[50 50],text,'FontSize',36,'BoxOpacity',0,'TextColor','red');
                
                % Save the marked image
%                 figure(1),imshow(RGB)
                outfile = [detectPath,...
                    expt.info.imagestart{imageset},...
                    'Detect_',...
                    sprintf(['%.',num2str(zeropad),'d'],i),...
                    expt.fad.FAD_type_low];
                imwrite(RGB,outfile);

                % Concatenate the data and include the timepoint and frame number
                timepointData = [timepointData;[centersDark,repmat([i, time], [size(centersDark,1),1])]];

            end
            
        end
        
        %% Link the detected circles into particle tracks and calculate MCT rate
        if ~isempty(timepointData),
            
            disp('Linking identified particles into tracks');
            % (x) (y) (frame) (time) (particle #)
            tracks = track(timepointData,expt.tracking.maxdisp);

            % Convert data array to match manual MCT analysis format
            % (timepoint) (particle #) (frame) (x) (y) (time) 
            timepointData(:,1) = repmat(t,[1,size(tracks,1)]);
            timepointData(:,2) = tracks(:,5);
            timepointData(:,3) = tracks(:,3);
            timepointData(:,4:5) = tracks(:,1:2);
            timepointData(:,6) = tracks(:,4);

            % Perform the remainder of the MCT rate calculations
            % (timepoint) (particle #) (frame) (x) (y) (time) (pixels) (mm) (dt) (rate) (angle)
            dx = timepointData(:,4) - circshift(timepointData(:,4),[1 0]);
            dy = timepointData(:,5) - circshift(timepointData(:,5),[1 0]);
            dt = timepointData(:,6) - circshift(timepointData(:,6),[1 0]);
            timepointData(:,7) = sqrt(dx.^2 + dy.^2);
            timepointData(:,8) = timepointData(:,7)*expt.tracking.pixelsize;
            timepointData(:,9) = dt;
            timepointData(:,10) = timepointData(:,8)./timepointData(:,9);
            timepointData(:,11) = -sign(dy) .* (90 - atand(dx./abs(dy)));     % Angle measured from 3 o'clock position
%             timepointData(:,11) = sign(dx) .* (90 - atand(-dy./abs(dx)));

            % Remove the rate data for the first recorded frame for each tracked particle
            ia = find(sum(timepointData(:,1:2) - circshift(timepointData(:,1:2),[1 0]) ~= 0,2) ~= 0);
            timepointData(ia,7:11) = NaN;

            % Remove any particles that are not tracked for long enough
            for i = 1:max(timepointData(:,2)),
                if(length(find(timepointData(:,2) == i)) <= expt.tracking.frameThreshold) timepointData(find(timepointData(:,2) == i),:) = []; end
            end
        
            %% Write the tracked images
            for i = keepframes{imageset}{t},

                imagename = [basepath,...
                    expt.fad.corrected,...
                    expt.info.image{imageset},...
                    expt.fad.FAD_path_low,...
                    expt.info.imagestart{imageset},...
                    expt.fad.FAD_file_low,...
                    sprintf(['%.',num2str(zeropad),'d'],i),...
                    expt.fad.FAD_type_low];                

                if exist(imagename),

                    disp(['Marking particles in file ', num2str(i), ' of ', num2str(expt.info.imagegoto(imageset))]);                
                    inimage = imread(imagename);

                    % Mark the tracked particles and add text
                    coordinates = timepointData(find(timepointData(:,3) == i),4:5);
                    RGB = insertShape(inimage, 'FilledCircle', [coordinates,expt.tracking.radius*2*ones(size(coordinates,1),1)], 'LineWidth', 5,'Color','blue','Opacity',0.25);
                    text = [expt.info.imagestart{imageset},...
                        expt.fad.FAD_file_low,...
                        sprintf(['%.',num2str(zeropad),'d'],i),...
                        ' (t = ',num2str(expt.tracking.times(t)), ' min)'];
                    RGB = insertText(RGB,[50 50],text,'FontSize',36,'BoxOpacity',0,'TextColor','blue');

                    % Save the marked image
%                     figure(2),imshow(RGB)
                    outfile = [trackPath,...
                        expt.info.imagestart{imageset},...
                        'Track_',...
                        sprintf(['%.',num2str(zeropad),'d'],i),...
                        expt.fad.FAD_type_low];
                    imwrite(RGB,outfile);

                end

            end

            subjectData = [subjectData;timepointData];
             
        end
        
    end
    
    %% Save the data
    disp(['Writing file ', MAT]);
    data{imageset} = subjectData;
    save(MAT,'expt','data','tracked','complete','file');
    
%     % Add column headings
%     subjectData = [{'Timepoint (min)', 'Particle number', 'Frame number',...
%         'x', 'y', 'Distance (pixels)', 'Distance (mm)',...
%         'Frames', 'Time (min)', 'Rate (mm/min)', 'Angle'};...
%         num2cell(subjectData)];
%     
%     % Write XLS data
%     disp(['Writing file ', XLS]);
% %    xlswrite(XLS,xlsdata,expt.info.imagestart{imageset});
    
end

complete = true;
save(MAT,'expt','data','tracked','complete','file');

% Write XLS file
if ispc, dataToXLSX(MAT); end