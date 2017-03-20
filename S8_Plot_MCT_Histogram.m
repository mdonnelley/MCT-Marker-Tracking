function S8_Plot_MCT_Histogram(MAT)

% Function to plot MCT histogram data

% Set the base pathname for the current machine
setbasepath;

load(MAT);
iptsetpref('ImshowBorder','tight');
iptsetpref('ImshowInitialMagnification', 40);
set(0,'DefaulttextInterpreter','none')

% Get the group information
grouplist = fieldnames(expt.group);

% Set default values
if isfield(expt.tracking, 'bins'), bins = expt.tracking(tracked).bins; else bins = 0:0.05:5; end

if exist('histogram') == 1,
    
    for Rx = 1:size(histogram, 3),
        
        figure, h = bar3(bins,histogram(:,:,Rx));
        
        % Sort out the axes and labels
        set(gca,'XTick',1:length(expt.tracking(tracked).times))
        set(gca,'XTickLabel',expt.tracking(tracked).times)
        xlabel('Timepoint(min)')
        ylabel('Particle MCT rate (mm/min)')
        zlabel('Number of particles')
        title(grouplist{Rx});
        axis equal
        axesLabelsAlign3D
        axis square
        ylim([min(bins) max(bins)])
        zlim([0 20])
        drawnow; set(get(handle(gcf),'JavaFrame'),'Maximized',1);
        
        % Scale bar color based on number of particles in bin
        shading interp
        for i = 1:length(h)
            zdata = get(h(i),'Zdata');
            set(h(i),'Cdata',zdata)
            set(h,'EdgeColor','k')
        end

        % Remove the zero-valued bars
        for i = 1:numel(h)
            index = logical(kron(histogram(:,i,Rx) == 0,ones(6,1)));
            zData = get(h(i),'ZData');
            zData(index,:) = nan;
            set(h(i),'ZData',zData);
        end
        
        % Determine the imagename
        imagename = [MAT(1:length(MAT)-4),...
            ' - ',...
            grouplist{Rx},...
            expt.fad.FAD_type_low];
        
        % Write the image
        saveas(gcf,imagename);
        
    end
    
else
    
    error('Histogram data not present in MAT file. Run S8_Collate_Histogram first');
    
end