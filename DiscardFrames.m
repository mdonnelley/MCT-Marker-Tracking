function DiscardFrames(experiment)

setbasepath;

% Time between frames in preview sequence
pauselength = 0.2; 

% Load the metadata from the dataset to analyse
run(experiment);
expt.info = ReadS8Data(expt.file.filelist);
complete = false;
if isfield(expt.naming,'zeropad') zeropad = expt.naming.zeropad; else zeropad = 4; end

% Output file naming
datetime = datestr(now,'yyyy-mmm-dd HH-MM-SS');
file = ['Framelist ',datetime];
MAT = [basepath,...
    expt.file.datapath,...
    'Processed/',...
    file,...
    '.mat'];

% Process each experiment
for imageset = expt.tracking.runlist,

    % Process each timepoint
    for t = 1:length(expt.tracking.times),

        clear images;
        
        % Determine the frame numbers for each block
        firstframe = expt.info.imagegofrom(imageset) + expt.tracking.imagesperblock * (t - 1);
        startframe = firstframe + (expt.tracking.imagesperbreath - expt.tracking.frameoffset(imageset,t)) + expt.tracking.analysisframe;          % Start analysis in second breath of block
        framelist = startframe:expt.tracking.imagesperbreath:firstframe+expt.tracking.imagesperblock-1;
        framestatus = true(1,length(framelist));

        % Load the files
        for i = 1:length(framelist),
            
            imagename = [basepath,...
                expt.fad.corrected,...
                expt.info.image{imageset},...
                expt.fad.FAD_path_low,...
                expt.info.imagestart{imageset},...
                expt.fad.FAD_file_low,...
                sprintf(['%.',num2str(zeropad),'d'],framelist(i)),...
                expt.fad.FAD_type_low]
            
            if exist(imagename,'file'),   
                images(:,:,i) = imread(imagename);
            else
                images(:,:,i) = uint8(zeros(expt.tracking.imsize));
                framestatus(i) = false;
            end
            
        end
        
        % Select the files to keep and discard
        i = 1;
        while true,
        
            figure(1), imshow(images(:,:,i));
            titletext = ['R',num2str(imageset),' T',num2str(t),' F',num2str(framelist(i)),' (',num2str(i),' of ',num2str(length(framelist)),'): '];
            if framestatus(i),
                title([titletext,'Retain'],'color','g');
            else
                title([titletext,'Discard'],'color','r');
            end
            [x, y, button] = ginput(1);
            
            switch button,
                case 28 % Left arrow - Go to previous image
                    if i > 1, i = i - 1; end
                case 29 % Right arrow - Go to next image
                    if i < length(framelist), i = i + 1; end
                case 121 % Y key - Yes, keep image
                    framestatus(i) = true;
                case 110 % N key - No, discard image
                    framestatus(i) = false;
                case 116 % T key - Toggle current status of image
                    framestatus(i) = logical(1 - framestatus(i));
                case 30 % Up key - Move to next block of images
                    break;
                case 30 % Down key - Move to previous block of images
                    t = t - 1;
                    break;
            end
            
        end

        % Record the files to keep
        framelist(find(~framestatus)) = [];
        keepframes{imageset}{t} = framelist;
        save(MAT,'keepframes','imageset','t','complete');
        
    end
    
end

close(1)
complete = true;
save(MAT,'keepframes','complete');