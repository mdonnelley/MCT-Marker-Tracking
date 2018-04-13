function AddAcquireTime(experiment)

setbasepath;
w = waitbar(0);

% Load the metadata from the dataset to analyse
run(experiment);
expt.info = ReadS8Data(expt.file.filelist);
if isfield(expt.naming,'zeropad') zeropad = expt.naming.zeropad; else zeropad = 4; end

% Process each experiment
for imageset = 25%expt.fad.runlist,

    for i = expt.info.imagegofrom(imageset):expt.info.imagegoto(imageset),
        
        waitbar(find(expt.fad.runlist == imageset) / length(expt.fad.runlist),w,['Set ',num2str(imageset),' of ',num2str(length(expt.fad.runlist)),': Image ', num2str(i),' of ',num2str(expt.info.imagegoto(imageset))])
                   
        % Get the raw file name
        imagename = [basepath,...
            expt.file.raw,...
            expt.info.image{imageset},...
            expt.info.imagestart{imageset},...
            sprintf(['%.',num2str(zeropad),'d'],i),...
            expt.info.imageformat{imageset}];
        
        if exist(imagename,'file'),
            
            % Determine the acquisition time from the raw file
            [rawimage, t] = ReadFileTime(imagename);
                
            % Get the FD corrected filename
            imagename = [basepath,...
                expt.fad.corrected,...
                expt.info.image{imageset},...
                expt.fad.FAD_path_low,...
                expt.info.imagestart{imageset},...
                expt.fad.FAD_file_low,...
                sprintf(['%.',num2str(zeropad),'d'],i),...
                expt.fad.FAD_type_low];
            
            if exist(imagename,'file'),
                
                % Load the FD corrected image
                fdimage = imread(imagename);
                
                % Overwrite the file with the acquisition time in the comments
                imwrite(fdimage,imagename,'Comment',num2str(t));
                
            end
            
        end
        
    end
    
end

close(w)