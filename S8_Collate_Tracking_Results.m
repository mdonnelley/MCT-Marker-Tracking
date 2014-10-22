% Function to collate data about MCT rates in each group
%
% Function takes all of the particle MCT measurements and collates them
% into {mean, standard deviation, N} for each animal and timepoint.

function S8_Collate_Tracking_Results(XLS)

w = waitbar(0,'Reading MAT and XLS data');

% Set the base pathname for the current machine
setbasepath;

MAT = [XLS(1:length(XLS)-4),'.mat'];
load(MAT);

% Get the group information
grouplist = fieldnames(expt.group);
for i = 1:length(grouplist),
    for j = getfield(expt.group,grouplist{i})
        groups{j,1} = grouplist{i};
    end
end

% Get the sheet names
[status,sheets] = xlsfinfo(XLS);

% Pre-allocate the arrays
average = NaN(length(expt.info.image),length(expt.tracking.times));
SD = NaN(length(expt.info.image),length(expt.tracking.times));
number = NaN(length(expt.info.image),length(expt.tracking.times));

for s = 1:length(sheets)
    
    waitbar(s/length(sheets),w,['Reading sheet: ',sheets{s}(1:length(sheets{s})-1)]);
    
    if ~strcmp(sheets{s},'Sheet1') & ~strcmp(sheets{s},'Sheet2') & ~strcmp(sheets{s},'Sheet3') & ~strcmp(sheets{s},'Mean') & ~strcmp(sheets{s},'SD') & ~strcmp(sheets{s},'Number'),
        
        % Read each XLS sheet
        data = xlsread(XLS,sheets{s});
        
        if ~isempty(data)
            
            % Exclude stationary particles
            data(data(:,10) == 0,10) = NaN;
            
            % Exclude rapidly moving particles
            if isfield(expt.tracking,'maxrate'), data(data(:,10) > expt.tracking.maxrate,10) = NaN; end
            
            % Get the summary stats info
            stats = [];
            [C,ia,ic] = unique(data(:,1));
            for i = 1:length(C),
                stats(1,i) = C(i);
                stats(2,i) = nanmean(data(data(:,1) == C(i),10));
                stats(3,i) = nanstd(data(data(:,1) == C(i),10));
                stats(4,i) = max(data(data(:,1) == C(i),2));
            end
            
            % Get the row number
            m = 1;
            while ~strcmp(expt.info.imagestart{m},sheets{s}), m = m + 1; end
            
            for i = 1:size(stats,2)
                
                % Get the column number (in case there is no data for some timepoints)
                t = find(stats(1,i) == sort(expt.tracking.times));
                
                % Save the stats
                average(m,t) = stats(2,i);
                SD(m,t) = stats(3,i);
                number(m,t) = stats(4,i);
                
            end
            
        end
        
    end
    
end

% Write the mean data back to the XLS sheet
waitbar(0,w,'Writing sheet: Mean');
xlswrite(XLS,expt.info.imagestart,'Mean','A2');
xlswrite(XLS,groups,'Mean','B2');
xlswrite(XLS,sort(expt.tracking.times),'Mean','C1');
xlswrite(XLS,average,'Mean','C2');

% Write the standard deviation data back to the XLS sheet
waitbar(0.33,w,'Writing sheet: SD');
xlswrite(XLS,expt.info.imagestart,'SD','A2');
xlswrite(XLS,groups,'SD','B2');
xlswrite(XLS,sort(expt.tracking.times),'SD','C1');
xlswrite(XLS,SD,'SD','C2');

% Write the number of particles tracked back to the XLS sheet
waitbar(0.66,w,'Writing sheet: Number');
xlswrite(XLS,expt.info.imagestart,'Number','A2');
xlswrite(XLS,groups,'Number','B2');
xlswrite(XLS,sort(expt.tracking.times),'Number','C1');
xlswrite(XLS,number,'Number','C2');

close(w)
