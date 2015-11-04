function S8_Collate_Statistics(MAT)

% Function to collate data about MCT rates in each group
%
% Function takes all of the particle MCT measurements and collates them
% into {mean, standard deviation, N} for each animal and timepoint.

w = waitbar(0,'Reading MAT and XLS data');

% Set the base pathname for the current machine
setbasepath;

load(MAT);
XLS_in = [MAT(1:length(MAT)-4),'.xls'];
XLS_out = [MAT(1:length(MAT)-4),' - Statistics.xls'];

% Get the group information
grouplist = fieldnames(expt.group);
for i = 1:length(grouplist),
    for j = getfield(expt.group,grouplist{i})
        groups{j,1} = grouplist{i};
        groups{j,2} = i;
    end
end

% Get the sheet names
[status,sheets] = xlsfinfo(XLS_in);

% Pre-allocate the arrays
average = NaN(length(expt.info.image),length(expt.tracking(tracked).times));
SD = NaN(length(expt.info.image),length(expt.tracking(tracked).times));
number = NaN(length(expt.info.image),length(expt.tracking(tracked).times));

for s = 1:length(sheets)
    
    waitbar(s/length(sheets),w,['Reading sheet: ',sheets{s}(1:length(sheets{s})-1)]);
    
    if ~strcmp(sheets{s},'Sheet1') & ~strcmp(sheets{s},'Sheet2') & ~strcmp(sheets{s},'Sheet3'),
        
        % Read the relevant section of each XLS sheet
        data = xlsread(XLS_in,sheets{s},'A2:J5000');
        
        if ~isempty(data)
            
            % Exclude stationary particles and those moving outside max/min rates
            data(data(:,10) == 0,10) = NaN;
%             if isfield(expt.tracking(tracked),'maxrate') & ~isempty(expt.tracking(tracked).maxrate), data(data(:,10) >= expt.tracking(tracked).maxrate,10) = NaN; end
%             if isfield(expt.tracking(tracked),'minrate') & ~isempty(expt.tracking(tracked).minrate), data(data(:,10) <= expt.tracking(tracked).minrate,10) = NaN; end
            
            % Get the summary stats info for all particles at each timepoint
            stats = [];
            [C,ia,ic] = unique(data(:,1));
            for i = 1:length(C),
                stats(1,i) = C(i);
                stats(2,i) = nanmean(data(ic == i,10));
                stats(3,i) = nanstd(data(ic == i,10));
                stats(4,i) = max(data(ic == i,2));
            end
            
            % Get the row number
            m = 1;
            while ~strcmp(expt.info.imagestart{m},sheets{s}), m = m + 1; end

            for i = 1:size(stats,2)
                
                % Get the column number (in case there is no data for some timepoints)
                t = find(stats(1,i) == sort(expt.tracking(tracked).times));
                
                % Save the stats
                average(m,t) = stats(2,i);
                SD(m,t) = stats(3,i);
                number(m,t) = stats(4,i);
                
            end
            
        end
        
    end
    
end

% Save the results in the MAT file
save(MAT,'average','SD','number','-append');

% Write the mean data to an XLS file
waitbar(0,w,'Writing sheet: Mean');
xlswrite(XLS_out,expt.info.imagestart,'Mean','A2');
xlswrite(XLS_out,groups(:,1),'Mean','B2');
xlswrite(XLS_out,sort(expt.tracking(tracked).times),'Mean','C1');
xlswrite(XLS_out,average,'Mean','C2');

% Write the standard deviation data to an XLS file
waitbar(0.25,w,'Writing sheet: SD');
xlswrite(XLS_out,expt.info.imagestart,'SD','A2');
xlswrite(XLS_out,groups(:,1),'SD','B2');
xlswrite(XLS_out,sort(expt.tracking(tracked).times),'SD','C1');
xlswrite(XLS_out,SD,'SD','C2');

% Write the number of particles tracked to an XLS file
waitbar(0.5,w,'Writing sheet: Number');
xlswrite(XLS_out,expt.info.imagestart,'Number','A2');
xlswrite(XLS_out,groups(:,1),'Number','B2');
xlswrite(XLS_out,sort(expt.tracking(tracked).times),'Number','C1');
xlswrite(XLS_out,number,'Number','C2');

close(w)
