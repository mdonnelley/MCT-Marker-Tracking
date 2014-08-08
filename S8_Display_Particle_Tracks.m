% Script to display all located particles on images

clear all; clc;

datapath = 'I:/SPring-8/2011 B/20XU/MCT/Images/';
experiment.read = 'FD Corrected/';
experiment.filelist = 'S8_2011B.csv';
experiment.write = 'Processed/Particle Movies/';

FAD_IMAGESET_L = 'Low/';
FAD_FILENAME_L = '_fad_';
FAD_FILETYPE_L = '.jpg';

[FileName,PathName] = uigetfile('*.xls','Select a file',[datapath,'MCT Rate Calculation*.xls']);
XLS = [PathName,FileName];
[status,sheets] = xlsfinfo(XLS);

MAT = [XLS(1:length(XLS)-4),'.mat'];
load(MAT);

%% Read the data sheets
for s = 1:length(sheets),
    
    data = xlsread(XLS,s);
    
    % Set start frame count (21 for CONTROL and RX, 1 for baseline)
    count = 1;
    
    % Repeat for each timepoint
    for t = timepoints,
        
        % Load each of the images at that timepoint
        for i = 1:frames,
            
            % Calculate the framenumber
            framenumber = start(t) + (i-1)*gap;
            
            % Determine the filename
            filename = sprintf('%s%s%s/%s%s%s%.4d%s',datapath,experiment.read,sheets{s}(7:10),FAD_IMAGESET_L,sheets{s},FAD_FILENAME_L,framenumber,FAD_FILETYPE_L)
            
            % Load the image
            im = imread(filename);
            im = repmat(im,[1 1 3]);
            
            % Determine the lines in the array for this timepoint
            blockstart = (t-1)*frames*particles + 1;
            blockfinish = t*frames*particles;
            
            % Add the selected points
%             markerInserter = vision.MarkerInserter ('Shape','X-mark','Size',10,'BorderColor','Custom','CustomBorderColor',[0 255 0]);
            markerInserter = vision.MarkerInserter ('Shape','Circle','Size',8,'Fill',1,'FillColor','Custom','CustomFillColor',[255 0 0]);
            marker = int32(data(blockstart+i-1:frames:blockfinish,4:5));
            im = step(markerInserter, im, marker);
            
            % Write the image
            filename = sprintf('%s%s%s%s%.3d%s',datapath,experiment.write,sheets{s},'_F',count,FAD_FILETYPE_L);
            imwrite(im,filename);
            
            count = count + 1;
            
        end
    end
    
end

close all; clc;