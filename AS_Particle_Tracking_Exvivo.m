function AS_Particle_Tracking(experiment)

setbasepath;

% Load the metadata from the dataset to analyse
run(experiment);
expt.info = ReadS8Data(expt.file.filelist);
tracked = 1;
complete = false;
if isfield(expt.naming,'zeropad') zeropad = expt.naming.zeropad; else zeropad = 4; end

% Create the data array
data = cell.empty(length(expt.info.imagestart),0);

% Output file naming
datetime = datestr(now,'yyyy-mmm-dd HH-MM-SS');
file = ['Tracking ',datetime];
XLS = [basepath,...
    expt.tracking.MCT,...
    file,...
    '.xlsx'];
MAT = [basepath,...
    expt.tracking.MCT,...
    file,...
    '.mat'];

% Process each experiment
for imageset = expt.tracking.runlist,
    
    disp(['Processing imageset ', num2str(imageset), ' of ', num2str(length(expt.info.image))]);
    
    xlsdata = [];
    
    outpath = [basepath,...
        expt.tracking.MCT,...
        expt.info.image{imageset}];
    if ~exist(outpath), mkdir(outpath); end
    
    %% Determine the background image
    
    outfile = [outpath,...
        expt.info.imagestart{imageset},...
        'Background',...
        expt.fad.FAD_type_low];
    
    if exist(outfile),
        
        disp(['Loading file ', outfile]);
        maximage = imread(outfile);
        
    else
        
        indices = expt.info.imagegofrom(imageset):expt.tracking.bgimageskip:expt.info.imagegoto(imageset);
        stack = uint8(zeros(expt.tracking.imsize(1),expt.tracking.imsize(2),length(indices)));

        count = 1;
        
        for i = indices,
            
            disp(['Loading file ', num2str(i), ' of ', num2str(expt.info.imagegoto(imageset)), ' for background identification']);
            
            imagename = [basepath,...
                expt.fad.corrected,...
                expt.info.image{imageset},...
                expt.fad.FAD_path_low,...
                expt.info.imagestart{imageset},...
                expt.fad.FAD_file_low,...
                sprintf(['%.',num2str(zeropad),'d'],i),...
                expt.fad.FAD_type_low];
            stack(:,:,count) = imread(imagename);
            
            count = count + 1;
            
        end
        
        % Determine the maximum value in the stack
        maximage = max(stack,[],3);
        
        % Save the background image
        disp(['Writing file ', outfile]);
        imwrite(maximage,outfile);
        
    end
    
    for t = expt.tracking.times
        
        tmpdata = [];
        
        %% Perform background subtraction and locate circles
        for f = 1:expt.tracking.length / expt.tracking.frameinterval,
            
            i = t * 60 / expt.tracking.frameinterval + f;
            
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
                inimage = imread(imagename);

                % Perform the background subtraction
                foreground = maximage - inimage;

                % Locate the circle centres
                [centersDark, radiiDark] = imfindcircles(foreground,[4 12],'ObjectPolarity','bright','Sensitivity',0.9);

                % Remove particles that are not the right radius
                idx = radiiDark > expt.tracking.minRadius & radiiDark < expt.tracking.maxRadius;
                centersDark(~idx,:) = [];

                % Concatenate the data and include the timepoint and frame number
                tmpdata = [tmpdata;[centersDark,repmat(i,[size(centersDark,1),1])]];

                %         figure(1),imshow(inimage)
                %         figure(2),imshow(maximage)
                %         figure(3),imshow(foreground)

            end
            
        end
        
        %% Link the detected circles into particle tracks and calculate MCT rate
        if ~isempty(tmpdata),
            
            disp('Linking identified particles into tracks');
            tracks = track(tmpdata,expt.tracking.maxdisp);

            % Convert data array to match manual MCT analysis format
            tmpdata(:,1) = repmat(t,[1,size(tracks,1)]);
            tmpdata(:,2) = tracks(:,4);
            tmpdata(:,3) = tracks(:,3);
            tmpdata(:,4:5) = tracks(:,1:2);

            % Remove any particles that are not tracked for long enough
            for i = 1:max(tmpdata(:,2)),
                if(length(find(tmpdata(:,2) == i)) <= expt.tracking.frameThreshold) tmpdata(find(tmpdata(:,2) == i),:) = []; end
            end

            % Perform the remainder of the MCT rate calculations
            dt = tmpdata(:,3) - circshift(tmpdata(:,3),[1 0]);
            dx = tmpdata(:,4) - circshift(tmpdata(:,4),[1 0]);
            dy = tmpdata(:,5) - circshift(tmpdata(:,5),[1 0]);
            tmpdata(:,6) = sqrt(dx.^2 + dy.^2);
            tmpdata(:,7) = tmpdata(:,6)*expt.tracking.pixelsize;
            tmpdata(:,8) = dt;
            tmpdata(:,9) = tmpdata(:,8)*expt.tracking.frameinterval/60;
            tmpdata(:,10) = tmpdata(:,7)./tmpdata(:,9);
            tmpdata(:,11) = sign(dx) .* (90 - atand(-dy./abs(dx)));         % Angle measured from 12 o'clock position

            % Remove the rate data for the first recorded frame for each tracked particle
            ia = find(tmpdata(:,2) - circshift(tmpdata(:,2),[1 0]) ~= 0);
            tmpdata(ia,6:11) = NaN;
        
            %% Write the tracked images
            for f = 1:expt.tracking.length / expt.tracking.frameinterval,

                i = t * 60 / expt.tracking.frameinterval + f;

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
                    coordinates = tmpdata(find(tmpdata(:,3) == i),4:5);
                    RGB = insertShape(inimage, 'FilledCircle', [coordinates,expt.tracking.maxRadius*2*ones(size(coordinates,1),1)], 'LineWidth', 5,'Color','blue','Opacity',0.25);
                    text = [expt.info.imagestart{imageset},...
                        expt.fad.FAD_file_low,...
                        sprintf(['%.',num2str(zeropad),'d'],i),...
                        ' (t = ',num2str(t), ' min)'];
                    RGB = insertText(RGB,[50 50],text,'FontSize',36,'BoxOpacity',0,'TextColor','blue');

                    % Save the marked image
        %             figure(4),imshow(RGB)
                    outfile = [outpath,...
                        expt.info.imagestart{imageset},...
                        'Det_',...
                        sprintf(['%.',num2str(zeropad),'d'],i),...
                        expt.fad.FAD_type_low];
                    imwrite(RGB,outfile);

                end

            end

            xlsdata = [xlsdata;tmpdata];
             
        end
        
    end
    
    %% Save the data
    disp(['Writing file ', MAT]);
    data{imageset} = xlsdata;
    save(MAT,'expt','data','tracked','complete','file');
    
    % Add column headings
    xlsdata = [{'Timepoint (min)', 'Particle number', 'Frame number',...
        'x', 'y', 'Distance (pixels)', 'Distance (mm)',...
        'Frames', 'Time (min)', 'Rate (mm/min)', 'Angle'};...
        num2cell(xlsdata)];
    
    % Write XLS data
    disp(['Writing file ', XLS]);
    xlswrite(XLS,xlsdata,expt.info.imagestart{imageset});
    
end

complete = true;
save(MAT,'expt','data','tracked','complete','file');