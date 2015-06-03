function S8_Plot_MCT_Histogram(MAT)

% Function to plot MCT histogram data

% Set the base pathname for the current machine
setbasepath;

load(MAT);

% Get the group information
grouplist = fieldnames(expt.group);

if exist('histogram') == 1,
    
    for Rx = 1:size(histogram, 3),
        
        figure, h = bar3(expt.tracking(tracked).bins,histogram(:,:,Rx)/sum(sum(histogram(:,:,Rx))));
        set(gca,'XTickLabel',expt.tracking(tracked).times)
        xlabel('Timepoint(min)')
        ylabel('Particle MCT rate (mm/min)')
        title(grouplist{Rx});
%         zlim([0 max(max(max(histogram)))])
        
        shading interp
        for i = 1:length(h)
            zdata = get(h(i),'Zdata');
            set(h(i),'Cdata',zdata)
            set(h,'EdgeColor','k')
        end
        
    end
    
else
    
    error('Histogram data not present in MAT file. Run S8_Collate_Tracking_Results first');
    
end