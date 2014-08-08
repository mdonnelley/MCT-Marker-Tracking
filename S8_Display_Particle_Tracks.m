% Script to display particle tracks on images

clear all; clc;

datapath = 'I:/SPring-8/2011 B/20XU/MCT/Images/';
experiment.read = 'FD Corrected/';
experiment.filelist = 'S8_2011B.csv';
experiment.write = 'Processed/Particle Tracks/';

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
    
    % Repeat for each timepoint
    for t = timepoints,
        
        % Load the first image at that timepoint
        filename = sprintf('%s%s%s/%s%s%s%.4d%s',datapath,experiment.read,sheets{s}(7:10),FAD_IMAGESET_L,sheets{s},FAD_FILENAME_L,start(t),FAD_FILETYPE_L);
        im = imread(filename);
        im = repmat(im,[1 1 3]);

        % Determine the lines in the array for this timepoint
        blockstart = (t-1)*frames*particles + 1;
        blockfinish = t*frames*particles;
        
        % Add the line tracks
        shapeInserter = vision.ShapeInserter('Shape','Lines','BorderColor','Custom','CustomBorderColor',[255 255 0]);
        shape = reshape(data(blockstart:blockfinish,4:5)',[2*frames,particles])';
        for i = 1:size(shape,1),
            currentShape = shape(i,:);
            currentShape(isnan(currentShape)) = [];
            if(length(currentShape) >= 4),
                im = step(shapeInserter, im, int32(currentShape));
            end
        end
        
        % Add the selected points
%         markerInserter = vision.MarkerInserter ('Shape','X-mark','Size',10,'BorderColor','Custom','CustomBorderColor',[255 0 0]);
        markerInserter = vision.MarkerInserter ('Shape','Circle','Size',10,'Fill',1,'FillColor','Custom','CustomFillColor',[255 0 0]);
        marker = int32(data(blockstart:blockfinish,4:5));
        im = step(markerInserter, im, marker);
        
        markerInserter = vision.MarkerInserter ('Shape','Circle','Size',10,'Fill',1,'FillColor','Custom','CustomFillColor',[0 255 0]);
        marker = int32(data(blockstart:frames:blockfinish,4:5));
        im = step(markerInserter, im, marker);
        
        % Write the image
        filename = sprintf('%s%s%s%s%.2d%s',datapath,experiment.write,sheets{s},'_T',t,FAD_FILETYPE_L);
        imwrite(im,filename);

    end

end

close all; clc;