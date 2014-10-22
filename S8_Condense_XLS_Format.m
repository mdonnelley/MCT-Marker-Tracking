% Condense the original sparse XLS file to the new compact format
%
% The original XLS file contained a row for each possible particle that
% might be tracked. That is, if up to 200 particles were to be tracked at
% 20 timepoints then 4000 lines would be allocated. If no particles were
% tracked for that animal then those lines were still allocated. The new
% format only records the actual points that are clicked by the user. This
% makes the XLS file more readable and also reduces the disk size of the
% XLS file.

function S8_Condense_XLS_Format(XLS)

w = waitbar(0,'Condensing XLS format');

% Get the sheet names
[status,sheets] = xlsfinfo(XLS);

% Create the output filename
writename = [XLS(1:length(XLS)-4), ' - Condensed', XLS(length(XLS)-3:length(XLS))];

for s = 1:length(sheets),
    
    waitbar(s/length(sheets),w,['Condensing sheet: ',sheets{s}(1:length(sheets{s})-1)]);
    
    if ~strcmp(sheets{s},'Sheet1') & ~strcmp(sheets{s},'Sheet2') & ~strcmp(sheets{s},'Sheet3') & ~strcmp(sheets{s},'Mean') & ~strcmp(sheets{s},'SD') & ~strcmp(sheets{s},'Number'),
        
        % Load the sheet
        data = xlsread(XLS,sheets{s},'','basic');
        
        if isempty(data),
            
            data = NaN;
            
        else
            
            % Remove rows that start with a zero in col 2
            data(data(:,2)==0,:) = [];
            
            % Remove rows that contain NaN in col 4
            data(isnan(data(:,4)),:) = [];
            
            % Remove the stats columns if present
            if size(data,2) > 10, data(:,11:size(data,2)) = []; end
            
        end
        
        % Add column headings
        data = [{'Timepoint (min)', 'Particle number', 'Frame number',...
            'x', 'y', 'Distance (pixels)', 'Distance (mm)',...
            'Frames', 'Time (min)', 'Rate (mm/min)'};...
            num2cell(data)];
        
        % Write the data out
        xlswrite(writename,data,sheets{s});
        
    end
    
end

close(w)