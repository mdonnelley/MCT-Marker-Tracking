function AS_Particle_Motion_Histogram(expt, data, m)
% https://au.mathworks.com/matlabcentral/fileexchange/45325-efficient-2d-histogram--no-toolboxes-needed
%
% % Example of individual / timed analysis
% MAT = 'I:\Australian Synchrotron\2015-1\Images\Processed\Detected\Tracking 2016-Nov-21 21-41-24.mat'
% load(MAT)
% for m = 1:length(data),
% AS_Particle_Motion_Histogram(expt, data, m);
% end
%
% % Example of grouped analysis
% MAT = 'I:\Australian Synchrotron\2015-1\Images\Processed\Detected\Tracking 2016-Nov-21 21-41-24.mat'
% load(MAT)
% Baseline{1} = cell2mat(data(expt.group.Baseline));
% AS_Particle_Motion_Histogram(expt, Baseline, 1);
% 
% % Example of MuCLS data analysis
% MAT = 'I:\MuCLS\2017-1\Processed\Detected\Tracking 2017-May-15 08-38-29.mat';
% load(MAT)
% tube{4,:} = data{4}(data{4}(:,5) <= 640,:);
% trachea{4,:} = data{4}(data{4}(:,5) > 640,:);
% AS_Particle_Motion_Histogram(expt, data, 4);

setbasepath;

fig = figure(1);
set (fig, 'Units', 'normalized', 'Position', [0,0,1,1]);
load('MyColormaps','mycmap')

if isempty(data{m})
    
    disp(['No data for row ',num2str(m)])
    
else
    
    clf
    
    dx = data{m}(:,4) - circshift(data{m}(:,4),[1 0]);
    dy = data{m}(:,5) - circshift(data{m}(:,5),[1 0]);
    dx = dx * expt.tracking.pixelsize ./ data{m}(:,9);
    dy = dy * expt.tracking.pixelsize ./ data{m}(:,9);
    
    % Perform for all timepoints pooled together
    N = ndhist(dx,-dy,'bins',3,'filter','axis',[-4 4 -4 4]);
    
    % NOTE: Added extra lines to ndhist for MuCLS data. Remove when finished:
    %371:    binWidthX = 0.075
    %372:    binWidthY = 0.075
    %451:    N(1,1)=25;
    
    title(['Instantaneous tracking particle velocity (mm/min) for ',expt.info.imagestart{m}], 'Interpreter', 'none')
    axes0
    axis equal
    colormap(fig,mycmap)

%     % Perform for each timepoint individually
%     for i = 0:9,
%         
%         subplot(2,5,i+1)
%         
%         ndhist(dx(find(data{m}(:,1) == i)),-dy(find(data{m}(:,1) == i)),'bins',2,'filter','axis',[-5 5 -5 5]);
%         title(['t = ',num2str(i), ' minutes'])
%         %         title(['Instantaneous tracking particle velocity (mm/min) for ',expt.info.imagestart{m}], 'Interpreter', 'none')
%         axes0
%         axis equal
%         colormap(ax,mycmap)
%         
%     end

    % Write the image
    outfile = [basepath,...
        expt.tracking.MCT,...
        expt.info.imagestart{m},...
        'hist2d.jpg'];
    saveas(fig,outfile);
    
end