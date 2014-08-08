% Script to manually track movement of lead between adjacent frames

clear all; clc;

datapath = 'P:/SPring-8/';
experiment.read = '2011 B/20XU/MCT/Images/FD Corrected/';
experiment.filelist = '2011 B/20XU/MCT/Images/2011B Data.csv';
experiment.write = '2011 B/20XU/MCT/Images/Matlab/Particle Tracks/';
XLS = ['I:/SPring-8/2011 B/20XU/MCT/Images/Matlab/MCT Rate Calculation ',datestr(now,'yyyy-mmm-dd HH-MM-SS'),'.xls'];

FAD_IMAGESET_L = 'Low/';
FAD_FILENAME_L = '_fad_';
FAD_FILETYPE_L = '.jpg';

% experiment.runlist = [4:6,8,10:12,14,16:19];	% ALL
% experiment.runlist = [4,6,17:19];             % BASELINE
experiment.runlist = [5,8,10:12,14,16];         % TREATMENT

start = 10:60:615; times = -2.5:2:17.5;
% analyse = 1:length(start);                      % ALL
% analyse = 1:2;                                  % BASELINE
analyse = 3:length(start);                      % TREATMENT

gap = 1;
frames = 10;
repeat = 25;
dotsize = 10;
pauselength = 0.25;

info = ReadS8Data([datapath,experiment.filelist]);

h(1) = figure;

%% Get the user selected points and save the data
for m = experiment.runlist,

    clear data;
    data = zeros(length(times)*repeat*frames,12);
    
    % Repeat for each timepoint
    for t = analyse,
        
        % Load each of the images at that timepoint
        for i = 1:frames,
        
            % Calculate the framenumber
            framenumber = start(t) + (i-1)*gap;
            
            % Determine the filename
            filename = sprintf('%s%s%s%s%s%s%.4d%s',datapath,experiment.read,info.image{m},FAD_IMAGESET_L,info.imagestart{m},FAD_FILENAME_L,framenumber,FAD_FILETYPE_L);
            
            % Load the image
            images(:,:,i) = imread(filename);
            
        end
        
        % Repeat for each of the particles
        p = 1;
        while p <= repeat,
            
            % Display the image series in reverse to allow user to visualise the particles
            for i = frames:-1:1,
                
                tic
                
                figure(h(1)), imshow(images(:,:,i));
                title(['Reversed Sequence Preview (frame ', num2str(start(t)+(i-1)*gap),')'],'color','r')
                
                % Mark each of the previously selected particles
                for j = 1:(p-1),
                    
                    % Add the marker
                    line = (t-1)*frames*repeat + (j-1)*frames + i;
                    rectangle('Position',[data(line,4)-dotsize,data(line,5)-dotsize,2*dotsize,2*dotsize],'Curvature',[1,1],'FaceColor','r');
                    
                end
                
                pause(pauselength-toc);
                
            end
            
            % Select the particles
            for i = 1:frames,

                figure(h(1)), imshow(images(:,:,i));
                title([info.imagestart{m}, ' - Timepoint: t = ', num2str(times(t)), ' min (frame ', num2str(start(t)+(i-1)*gap),') - Particle number: ', num2str(p), ' of ', num2str(repeat)])
                
                % Mark each of the previously selected particles
                for j = 1:(p-1),
                    
                    % Add the marker
                    line = (t-1)*frames*repeat + (j-1)*frames + i;
                    rectangle('Position',[data(line,4)-dotsize,data(line,5)-dotsize,2*dotsize,2*dotsize],'Curvature',[1,1],'FaceColor','r');
                    
                end
                
                % Calculate the correct line number in the data array
                line = (t-1)*frames*repeat + (p-1)*frames + i;
                data(line,1) = times(t);
                data(line,2) = p;
                data(line,3) = start(t) + (i-1)*gap;
                [data(line,4),data(line,5),button] = ginput(1);
                
                % Perform action based on which button is pressed
                switch button,
                    
                    % Middle button (remove all data for that particle)
                    case 2
                        data(line-i+1:line-i+frames,4:5)=-10;
                        p=p-1;
                        break;
                    % Right button (stop acquiring data for that particle)
                    case 3
                        data(line:line-i+frames,4:5)=-10;
                        break;
                        
                end
  
            end
            p=p+1;
            
        end

    end

    % Remove any data from selections outside the image area
    data(data(:,4) < 0,4:10) = NaN;
    data(data(:,4) >  size(images(:,:,i),2),4:10) = NaN;
    data(data(:,5) < 0,4:10) = NaN;
    data(data(:,5) > size(images(:,:,i),1),4:10) = NaN;

    % Complete the calculations
    dt = data(:,3) - circshift(data(:,3),[1 0]);
    x = data(:,4) - circshift(data(:,4),[1 0]);
    y = data(:,5) - circshift(data(:,5),[1 0]);
    data(:,6)=sqrt(x.^2 + y.^2);
    data(:,7)=data(:,6)*1.43/2560;
    data(:,8)=dt;
    data(:,9)=data(:,8)*0.5/60;
    data(:,10)=data(:,7)./data(:,9);
    
    % Remove the data from the first particle in each sequence
    data(1:frames:length(times)*repeat*frames,6:10) = NaN;
    
    % Calculate mean and standard deviation data for each timepoint
    for t = analyse,
        
        blockstart = (t-1)*frames*repeat + 1;
        blockfinish = t*frames*repeat;
        data(blockstart,11) = nanmean(data(blockstart:blockfinish,10));
        data(blockstart,12) = nanstd(data(blockstart:blockfinish,10));
        
    end
    
    % Write the results to the XLS file
    xlswrite(XLS,data(:,:),info.imagestart{m})

end

%% Write the annotated images
for m = experiment.runlist,
    
%     data = xlsread(['I:\SPring-8\2011 B\20XU\MCT\Images\Matlab\','MCT Rate Calculation 2013-Feb-14 09-12-10','.xls'],info.imagestart{m});
    data = xlsread(XLS,info.imagestart{m});
    
    % Repeat for each timepoint
    for t = analyse,
        
        % Load the first image at that timepoint
        filename = sprintf('%s%s%s%s%s%s%.4d%s',datapath,experiment.read,info.image{m},FAD_IMAGESET_L,info.imagestart{m},FAD_FILENAME_L,start(t),FAD_FILETYPE_L);
        im = imread(filename);
        
        % CHANGE THIS TO REDUCE THE IMAGE SIZE SO THE MARKS ARE LARGER?
        
        im = repmat(im,[1 1 3]);

        % Determine the lines in the array for this timepoint
        blockstart = (t-1)*frames*repeat + 1;
        blockfinish = t*frames*repeat; 
        
        % Add the line tracks
        shapeInserter = vision.ShapeInserter('Shape','Lines','BorderColor','Custom','CustomBorderColor',[255 255 0]);
        shape = reshape(data(blockstart:blockfinish,4:5)',[2*frames,repeat])';
        for i = 1:size(shape,1),
            currentShape = shape(i,:);
            currentShape(isnan(currentShape)) = [];
            if(length(currentShape) >= 4),
                im = step(shapeInserter, im, int32(currentShape));
            end
        end
        
        % Add the selected points
        markerInserter = vision.MarkerInserter ('Shape','X-mark','Size',10,'BorderColor','Custom','CustomBorderColor',[255 0 0]);
        marker = int32(data(blockstart:blockfinish,4:5));
        im = step(markerInserter, im, marker);
        
        % Write the image
        filename = sprintf('%s%s%s%s%.1f%s%s','I:/SPring-8/',experiment.write,info.imagestart{m},'_',times(t),'_min',FAD_FILETYPE_L);
        imwrite(im,filename);

    end

end

close all; clc;