function Condense_XLS_Format(XLS)

% Get the sheet names
[status,sheets] = xlsfinfo(XLS);

% Create the output filename
writename = [XLS(1:length(XLS)-4), ' - Condensed', XLS(length(XLS)-3:length(XLS))];

for s = length(sheets)-1,
    
    if ~strcmp(sheets{s},'Sheet1') & ~strcmp(sheets{s},'Sheet2') & ~strcmp(sheets{s},'Sheet3'),
        
        % Load the sheet
        data = xlsread(XLS,sheets{s});
        
        if isempty(data),
            
            data = NaN;
            
        else
            
            % Remove rows that start with a zero in col 1
            data(data(:,1)==0,:) = [];
            
            % Remove rows that contain NaN in col 4
            data(isnan(data(:,4)),:) = [];
            
            % Remove zeros from stats columns
            data(data(:,11) == 0,11) = NaN;
            data(data(:,12) == 0,12) = NaN;
            
            % Remove median value if present
            if size(data,2) == 13, data(:,13) = []; end
            
            % Calculate mean and standard deviation data for each timepoint
            [C,ia,ic] = unique(data(:,1));
            for j = 1:length(C),
                data(ia(j),11) = nanmean(data(data(:,1) == C(j),10));
                data(ia(j),12) = nanstd(data(data(:,1) == C(j),10));
            end
            
        end
        
        % Write the data out
        xlswrite(writename,data,sheets{s});
        
    end
    
end