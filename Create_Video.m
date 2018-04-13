function Create_Video(infiles,outfile,framerate)

% Create a movie from image frames
%
% % Example from AS 2015-3 data
% MAT = '\\gt-srv-synology\imaging\Australian Synchrotron\2015-3\Images\Processed\Detected\Tracking 2016-Nov-16 11-17-02.mat';
% load(MAT)
% framerate = 5;
% framerate = framerate * 1/expt.tracking.frameinterval;
% for imageset = expt.tracking.runlist,  
%     % Get the input file list
%     infiles = dir([basepath,...
%         expt.tracking.trackPath,...
%         expt.info.image{imageset},...
%         expt.info.imagestart{imageset},'Det_*']);
%     % Get the output folder and filename
%     outfolder = [basepath,...
%         expt.tracking.trackPath,...
%         'Movies/'];
%     if ~exist(outfolder), mkdir(outfolder); end
%     outfile = [outfolder,...
%         expt.info.imagestart{imageset},...
%         'mov'];
%     Create_Video(infiles,outfile,framerate); 
% end

w = waitbar(0,'Setup');

% Open the video object
outputVideo = VideoWriter(outfile,'MPEG-4');
outputVideo.FrameRate = framerate;
open(outputVideo)

% Write each image as a movie frame
for i = 1:length(infiles),
    
    waitbar(i/length(infiles),w,['Adding frame ',num2str(i),' of ',num2str(length(infiles))]);
    img = imread(fullfile(infiles(i).folder,infiles(i).name));
    writeVideo(outputVideo,img)
    
end

close(outputVideo)
close(w)

