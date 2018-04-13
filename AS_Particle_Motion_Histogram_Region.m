function AS_Particle_Motion_Histogram_Region(expt, data, m)

setbasepath;
if isfield(expt.naming,'zeropad') zeropad = expt.naming.zeropad; else zeropad = 4; end

subsetPath = [basepath,...
    expt.file.datapath,...
    'Processed/Subset/',...
    expt.info.image{m}];
if ~exist(subsetPath), mkdir(subsetPath); end

fig = figure(1);
set (fig, 'Units', 'normalized', 'Position', [0,0,1,1]);
load('MyColormaps','mycmap')

[dx,dy] = AS_Particle_Motion_Histogram(expt, data, m);

colormap(fig,mycmap)

[x,y]=ginput(2)
rectangle('Position',[min(x),min(y),abs(x(2)-x(1)),abs(y(2)-y(1))],'LineWidth',2)
saveas(gcf,[subsetPath,'ROI (',num2str(x(1)),',',num2str(y(1)),') to (',num2str(x(2)),',',num2str(y(2)),').jpg'])

indices = find(dx >= min(x) & dx <= max(x) & dy >= min(y) & dy <= max(y));

subset = data{m}(indices,:);

for f = unique(subset(:,3))',
    
    particles = find(subset(:,3) == f);
    
    imagename = [basepath,...
        expt.fad.corrected,...
        expt.info.image{m},...
        expt.fad.FAD_path_low,...
        expt.info.imagestart{m},...
        expt.fad.FAD_file_low,...
        sprintf(['%.',num2str(zeropad),'d'],f),...
        expt.fad.FAD_type_low];
    
    if exist(imagename),
        
        inimage = imread(imagename);
        
        % Mark the tracked particles and add text
        coordinates = subset(particles,4:5);
        RGB = insertShape(inimage, 'FilledCircle', [coordinates,expt.tracking.radius*2*ones(size(coordinates,1),1)], 'LineWidth', 5,'Color','blue','Opacity',0.25);
        text = [expt.info.imagestart{m},...
            expt.fad.FAD_file_low,...
            sprintf(['%.',num2str(zeropad),'d'],f),...
            ' (t = ',num2str(subset(particles(1),1)), ' min)']
        RGB = insertText(RGB,[50 50],text,'FontSize',36,'BoxOpacity',0,'TextColor','blue');
        
        % Save the marked image
        figure(2),imshow(RGB)
        outfile = [subsetPath,...
            'SubsetTrack (',num2str(x(1)),',',num2str(y(1)),') to (',num2str(x(2)),',',num2str(y(2)),') ',...
            sprintf(['%.',num2str(zeropad),'d'],f),...
            expt.fad.FAD_type_low];
        imwrite(RGB,outfile);
        
    end
end