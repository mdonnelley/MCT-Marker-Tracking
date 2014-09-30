[readname,pathname] = uigetfile({'*.xls','*.xlsx'});

% Get the sheet names
[status,sheets] = xlsfinfo([pathname,readname]);

% Create the output filename
writename = [readname(1:length(readname)-4), ' - Condensed', readname(length(readname)-3:length(readname))]

for i = 4:length(sheets),
    
    sheets{i}
    
    % Load the sheet
    data = xlsread([pathname,readname],sheets{i});
    
    % Remove rows that start with a zero in col 1
    data(data(:,1)==0,:) = [];
    
    % Remove rows that contain NaN in col 4
    data(isnan(data(:,4)),:) = [];
    
    if(isempty(data)), 
        
        data = NaN; 
    
    else
        
        % Calculate mean and standard deviation data for each timepoint
        [C,ia,ic] = unique(data(:,1));
        for j = 1:length(C),
            data(ia(j),11) = nanmean(data(data(:,1) == C(j),10));
            data(ia(j),12) = nanstd(data(data(:,1) == C(j),10));
        end
        
    end
    
    % Write the data out
    xlswrite([pathname,writename],data,sheets{i});
    
end