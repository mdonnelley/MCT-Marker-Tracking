function markParticles(expt, data, color)

setbasepath;
if isfield(expt.naming,'zeropad') zeropad = expt.naming.zeropad; else zeropad = 4; end

for imageset = 1:length(data),
    
    if ~isempty(data{imageset})
        
        for i = unique(data{imageset,1}(:,3))',
            
            imagename = [basepath,...
                expt.fad.corrected,...
                expt.info.image{imageset},...
                expt.fad.FAD_path_low,...
                expt.info.imagestart{imageset},...
                expt.fad.FAD_file_low,...
                sprintf(['%.',num2str(zeropad),'d'],i),...
                expt.fad.FAD_type_low]
            
            if exist(imagename),
                
                disp(['Marking particles in file ', num2str(i), ' of ', num2str(expt.info.imagegoto(imageset))]);
                inimage = imread(imagename);
                
                % Mark the tracked particles and add text
                indices = find(data{imageset}(:,3) == i & ~isnan(data{imageset}(:,4)))
                coordinates = data{imageset}(indices,4:5);
                RGB = insertShape(inimage, 'FilledCircle', [coordinates,expt.tracking.radius*2*ones(size(coordinates,1),1)], 'LineWidth', 5,'Color',color,'Opacity',0.25);
                text = [expt.info.imagestart{imageset},...
                    expt.fad.FAD_file_low,...
                    sprintf(['%.',num2str(zeropad),'d'],i),...
                    ' (t = ',num2str(expt.tracking.times(data{imageset}(indices(1),1))), ' min)'];
                RGB = insertText(RGB,[50 50],text,'FontSize',36,'BoxOpacity',0,'TextColor','blue');
                
                % Save the marked image
                figure(2),imshow(RGB)
                outfolder = [basepath,...
                    expt.tracking.trackPath,...
                    expt.info.image{imageset}];
                if ~exist(outfolder) mkdir(outfolder); end
                outfile = [...
                    expt.info.imagestart{imageset},...
                    'Track_',...
                    sprintf(['%.',num2str(zeropad),'d'],i),...
                    expt.fad.FAD_type_low];
                imwrite(RGB,[outfolder,outfile]);
                
            end 
        end
    end
end