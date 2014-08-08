% Script to display particle tracks on images

clear all; clc;

if(strcmp(getenv('COMPUTERNAME'),'GT-DSK-DONNELLE')), datapath = 'I:/SPring-8/2012 B/MCT/Images/'; end
if(strcmp(getenv('COMPUTERNAME'),'ASPEN')), datapath = 'S:/Temporary/WCH/2012 B/MCT/Images/'; end
experiment.read = 'FD Corrected/';
experiment.filelist = 'S8_12B_XU.csv';
experiment.write = 'Processed/MCT Rate Calculation/R02/Particle Tracks/';

FAD_IMAGESET_L = 'Low/';
FAD_FILENAME_L = 'fad_';
FAD_FILETYPE_L = '.jpg';

SCALE = 0.5;
imsize = [2560,2160]; % Image size in pixels

[FileName,PathName] = uigetfile('*.xls','Select a file',[datapath,'MCT Rate Calculation*.xls']);
XLS = [PathName,FileName];
MAT = [XLS(1:length(XLS)-4),'.mat'];
load(MAT);
[status,sheets] = xlsfinfo([PathName,FileName]);

%% Write the annotated images
for s = 1:length(sheets),
    
    data = xlsread(XLS,s);
    
    % Repeat for each timepoint
    for t = timepoints,
        
        % Load the first image at that timepoint
        filename = sprintf('%s%s%s/%s%s%s%.4d%s',datapath,experiment.read,sheets{s}(1:12),FAD_IMAGESET_L,sheets{s},FAD_FILENAME_L,start(t)+1,FAD_FILETYPE_L);
        
        % Load the image
        if(exist(filename)),
            im = imread(filename);
        else
            im = uint8(zeros(imsize));
        end
        
        im = repmat(im,[1 1 3]);
        im = imresize(im,SCALE);

        % Determine the lines in the array for this timepoint
        blockstart = (t-1)*frames*particles + 1;
        blockfinish = t*frames*particles; 
        
        % Add the line tracks
        shapeInserter = vision.ShapeInserter('Shape','Lines','BorderColor','Custom','CustomBorderColor',[255 255 0]);
        shape = SCALE * reshape(data(blockstart:blockfinish,4:5)',[2*frames,particles])';
        for i = 1:size(shape,1),
            currentShape = shape(i,:);
            currentShape(isnan(currentShape)) = [];
            if(length(currentShape) >= 4),
                im = step(shapeInserter, im, int32(currentShape));
            end
        end
        
        % Add the selected points
        markerInserter = vision.MarkerInserter ('Shape','X-mark','Size',10,'BorderColor','Custom','CustomBorderColor',[255 0 0]);
        marker = SCALE*int32(data(blockstart:blockfinish,4:5));
        im = step(markerInserter, im, marker);
        
        % Write the image
        filename = sprintf('%s%s%s%s%.1f%s%s',datapath,experiment.write,sheets{s},'_',times(t),'_min',FAD_FILETYPE_L);
        imwrite(im,filename);

    end

end

close all; clc;