function AS_Particle_Track_Movie(MAT)

% Function to output movie frames after tracking
%
% This function takes the raw data and creates movie frames showing the
% location of tracked particles throughout the image sequence.

% Set the base pathname for the current machine
setbasepath;
FrameRate = 5;

w = waitbar(0,'Reading MAT data');

load(MAT)

% Process each experiment
for imageset = expt.tracking.runlist,
    
    outfile = [basepath,...
        expt.tracking.MCT,...
        expt.info.imagestart{imageset},...
        'mov.avi'];
    
    % Open the video object
    outputVideo = VideoWriter(outfile);
    outputVideo.FrameRate = FrameRate * 1/expt.tracking.frameinterval;
    open(outputVideo)
    
    % Get the file list
    infiles = dir([basepath,...
        expt.tracking.MCT,...
        expt.info.image{imageset},...
        expt.info.imagestart{imageset},...
        'Det_*']);
    
    % Write each image as a movie frame
    for i = 1:length(infiles),
        
        waitbar(i/length(infiles),w,['Adding frame ',num2str(i),' of ',num2str(length(infiles)),' in imageset ',num2str(imageset)]);
        img = imread(fullfile(infiles(i).folder,infiles(i).name));
        writeVideo(outputVideo,img)
        
    end
    
    close(outputVideo)
    
end