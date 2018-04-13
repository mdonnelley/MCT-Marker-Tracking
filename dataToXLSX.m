function dataToXLSX(MAT)

load(MAT)
XLS = [MAT(1:length(MAT)-4),'.xlsx'];

for imageset = 1:size(data,1),
    
    if ~isempty(data{imageset}),

    % Add column headings
    % (timepoint) (particle #) (frame) (x) (y) (time) (pixels) (mm) (dt) (rate) (angle)
    xlsdata = [{'Timepoint (min)', 'Particle number', 'Frame number',...
        'x', 'y', 'Acquire time',...
        'Distance (pixels)', 'Distance (mm)',...
        'Time (min)', 'Rate (mm/min)', 'Angle'};...
        num2cell(data{imageset})];
    
    % Write XLS data
    disp(['Writing file ', XLS]);
    xlswrite(XLS,xlsdata,expt.info.imagestart{imageset});
    
    end
    
end
