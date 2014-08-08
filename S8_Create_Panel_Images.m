% Script to mark timestamp and treatment delivery on each image

warning('off','vision:transition:usesOldCoordinates')

if(isunix), datapath = '/data/RAID0/exports/processing/SPring-8/';
elseif(ispc), datapath = 'P:/SPring-8/'; end

experiment.read = '2012 B/MCT/Images/FD Corrected/';
experiment.write = '2012 B/MCT/Images/Processed/Movie Frames/';
experiment.filelist = '2012 B/MCT/Images/2012B Data.csv';
experiment.runlist = [1,4:9,11:16];

FAD_IMAGESET_L = 'Low/';
FAD_FILENAME_L = 'fad_';
FAD_FILETYPE_L = '.jpg';

info = ReadS8Data([datapath,experiment.filelist]);

group = {...
    'Hypertonic Saline',... % S8_12B_XU_34
    'N/A',...
    'N/A',...
    'Hypertonic Saline',... % S8_12B_XU_37
    'Hypertonic Saline',... % S8_12B_XU_38
    'Hypertonic Saline',... % S8_12B_XU_39
    'Hypertonic Saline',... % S8_12B_XU_40
    'Hypertonic Saline',... % S8_12B_XU_41
    'Mannitol',... % S8_12B_XU_42
    'N/A',...
    'Mannitol',... % S8_12B_XU_43
    'Mannitol',... % S8_12B_XU_44
    'Mannitol',... % S8_12B_XU_45
    'Mannitol',... % S8_12B_XU_46
    'Mannitol',... % S8_12B_XU_48
    'Mannitol',... % S8_12B_XU_49
    };

% For each animal
for m = experiment.runlist,
    
    % Set the current write directory
    current_write = [datapath,experiment.write,info.image{m}]
    
    if(~exist(current_write)), mkdir(current_write), end
    
    count = 1;
    
    % For each frame
    for frame = 10:info.imagegoto(m),
        
        % Read the current image
        current = sprintf('%s%s%s%s%s%s%.4d%s',datapath,experiment.read,info.image{m},FAD_IMAGESET_L,info.imagestart{m},FAD_FILENAME_L,frame,FAD_FILETYPE_L);
        input = imread(current);
        
        % Determine the time information
        seconds = (frame - 120) / 2;
        min = fix(seconds/60);
        sec = abs(seconds) - min * 60;

        % Add the text
        if seconds <= 0
            htxtins = vision.TextInserter(sprintf('%.2d:%04.1f [Baseline]', min, sec));
        elseif (seconds > 0) & (seconds < 60)
            htxtins = vision.TextInserter(sprintf('%.2d:%04.1f [%s Aerosol ON]', min, sec, group{m}));
        else
            htxtins = vision.TextInserter(sprintf('%.2d:%04.1f [Post %s Rx]', min, sec, group{m}));
        end
        htxtins.Color = [255, 255, 255]; % [red, green, blue]
        htxtins.FontSize = 72;
        htxtins.Location = [20 20]; % [x y]
        output = step(htxtins, input);
        
        imwrite(output,sprintf('%sFrame %0.4d.jpg',current_write,count));
%         figure(1),imshow(output);

        count = count + 1;
        
    end
    
end