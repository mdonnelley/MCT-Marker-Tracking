function S8_Collate_Tracking_Results(MAT)

% Function to collate data about MCT rates in each group
%
% Function takes all of the particle MCT measurements and collates them
% into {mean, standard deviation, N} for each animal and timepoint.

w = waitbar(0,'Reading MAT and XLS data');

% Set the base pathname for the current machine
setbasepath;

load(MAT);
XLS = [MAT(1:length(MAT)-4),'.xls'];

% Get the group information
grouplist = fieldnames(expt.group);
for i = 1:length(grouplist),
    for j = getfield(expt.group,grouplist{i})
        groups{j,1} = grouplist{i};
        groups{j,2} = i;
    end
end

% Get the sheet names
[status,sheets] = xlsfinfo(XLS);

% Pre-allocate the arrays
average = NaN(length(expt.info.image),length(expt.tracking(tracked).times));
SD = NaN(length(expt.info.image),length(expt.tracking(tracked).times));
number = NaN(length(expt.info.image),length(expt.tracking(tracked).times));
histogram = zeros(length(expt.tracking(tracked).bins),length(expt.tracking(tracked).times),length(grouplist));

for s = 1:length(sheets)
    
    waitbar(s/length(sheets),w,['Reading sheet: ',sheets{s}(1:length(sheets{s})-1)]);
    
    if ~strcmp(sheets{s},'Sheet1') & ~strcmp(sheets{s},'Sheet2') & ~strcmp(sheets{s},'Sheet3') & ~strcmp(sheets{s},'Mean') & ~strcmp(sheets{s},'SD') & ~strcmp(sheets{s},'Number') & ~strcmp(sheets{s},'Histogram'),
        
        % Read the relevant section of each XLS sheet
        data = xlsread(XLS,sheets{s},'A2:J5000');
        
        if ~isempty(data)
            
            % Exclude stationary particles and those moving outside max/min rates
            data(data(:,10) == 0,10) = NaN;
            if isfield(expt.tracking,'maxrate'), data(data(:,10) >= expt.tracking(tracked).maxrate,10) = NaN; end
            if isfield(expt.tracking,'minrate'), data(data(:,10) <= expt.tracking(tracked).minrate,10) = NaN; end
            
            % Get the summary stats info for all particles at each timepoint
            stats = [];
            h2D = zeros(length(expt.tracking(tracked).bins),length(expt.tracking(tracked).times));
            [C,ia,ic] = unique(data(:,1));
            for i = 1:length(C),
                
                stats(1,i) = C(i);
                stats(2,i) = nanmean(data(ic == i,10));
                stats(3,i) = nanstd(data(ic == i,10));
                stats(4,i) = max(data(ic == i,2));
                
                % Calculate the histogram data based on the mean MCT rate of each particle
                for j = 1:max(data(ic == i,2)),
                    h1D = hist(nanmean(data((ic == i) & (data(:,2) == j),10)),expt.tracking(tracked).bins)';
                    timepoint = find(expt.tracking(tracked).times == C(i));
                    h2D(:,timepoint) = h2D(:,timepoint) + h1D;
                end
                
            end
            
            % Save histogram in the XLS sheet
            xlswrite(XLS,NaN(200,200),sheets{s},'L1');
            xlswrite(XLS,sort(expt.tracking(tracked).times),sheets{s},'M1');
            xlswrite(XLS,expt.tracking(tracked).bins',sheets{s},'L2');
            xlswrite(XLS,h2D,sheets{s},'M2');
            
            % Get the row number
            m = 1;
            while ~strcmp(expt.info.imagestart{m},sheets{s}), m = m + 1; end
            
            % Add the histogram data to the correct group
            histogram(:,:,groups{m,2}) = histogram(:,:,groups{m,2}) + h2D;

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
save(MAT,'average','SD','number','histogram','-append');

% Write the mean data back to the XLS sheet
waitbar(0,w,'Writing sheet: Mean');
xlswrite(XLS,expt.info.imagestart,'Mean','A2');
xlswrite(XLS,groups(:,1),'Mean','B2');
xlswrite(XLS,sort(expt.tracking(tracked).times),'Mean','C1');
xlswrite(XLS,average,'Mean','C2');

% Write the standard deviation data back to the XLS sheet
waitbar(0.25,w,'Writing sheet: SD');
xlswrite(XLS,expt.info.imagestart,'SD','A2');
xlswrite(XLS,groups(:,1),'SD','B2');
xlswrite(XLS,sort(expt.tracking(tracked).times),'SD','C1');
xlswrite(XLS,SD,'SD','C2');

% Write the number of particles tracked back to the XLS sheet
waitbar(0.5,w,'Writing sheet: Number');
xlswrite(XLS,expt.info.imagestart,'Number','A2');
xlswrite(XLS,groups(:,1),'Number','B2');
xlswrite(XLS,sort(expt.tracking(tracked).times),'Number','C1');
xlswrite(XLS,number,'Number','C2');

% Write the histogram data back to the XLS sheet
waitbar(0.75,w,'Writing sheet: Histogram');
xlswrite(XLS,NaN(200,200),'Histogram','A1');
histogram = reshape(histogram,length(expt.tracking(tracked).bins),[]);
xlswrite(XLS,repmat(sort(expt.tracking(tracked).times),[1 size(groups,2)]),'Histogram','B1');
xlswrite(XLS,expt.tracking(tracked).bins','Histogram','A2');
xlswrite(XLS,histogram,'Histogram','B2');

close(w)
