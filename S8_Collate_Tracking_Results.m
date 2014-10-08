% Script to collate data about MCT rates in each group
function S8_Collate_Tracking_Results(XLS)

% Set the base pathname for the current machine
setbasepath;

MAT = [XLS(1:length(XLS)-4),'.mat'];
load(MAT);

% Get the sheet names
[status,sheets] = xlsfinfo(XLS);

% Pre-allocate the arrays
average = NaN(length(expt.info.image),length(expt.tracking.times));
SD = NaN(length(expt.info.image),length(expt.tracking.times));

for s = 1:length(sheets)
    
    if ~strcmp(sheets{s},'Sheet1') & ~strcmp(sheets{s},'Sheet2') & ~strcmp(sheets{s},'Sheet3') & ~strcmp(sheets{s},'Average') & ~strcmp(sheets{s},'SD'),
        
        % Read each XLS sheet
        data = xlsread(XLS,sheets{s},'','basic');
        
        if ~isempty(data)
            
            % Get the summary stats info
            stats = data(data(:,11) ~= 0,[1,11,12])';
            
            % Get the row number
            m = 1;
            while ~strcmp(expt.info.imagestart{m},sheets{s}), m = m + 1; end
            
            for i = 1:size(stats,2)
                
                % Get the column number (in case there is no data for some timepoints)
                t = find(stats(1,i) == expt.tracking.times);
                
                average(m,t) = stats(2,i);
                SD(m,t) = stats(3,i);
                
            end
            
        end
        
    end
    
end

% Write the mean data back to the XLS sheet
xlswrite(XLS,expt.info.imagestart,'Average','A2');
xlswrite(XLS,expt.tracking.times,'Average','B1');
xlswrite(XLS,average,'Average','B2');

% Write the standard deviation data back to the XLS sheet
xlswrite(XLS,expt.info.imagestart,'SD','A2');
xlswrite(XLS,expt.tracking.times,'SD','B1');
xlswrite(XLS,SD,'SD','B2');
