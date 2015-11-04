function S8_Collate_Histogram(MAT)

% Function to collate data about MCT rates in each group
%
% Function takes all of the particle MCT measurements and collates them
% into {mean, standard deviation, N} for each animal and timepoint.

w = waitbar(0,'Reading MAT and XLS data');

% Set the base pathname for the current machine
setbasepath;

load(MAT);
XLS_in = [MAT(1:length(MAT)-4),'.xls'];
XLS_out = [MAT(1:length(MAT)-4),' - Histogram.xls'];

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
histogram = zeros(length(expt.tracking(tracked).bins),length(expt.tracking(tracked).times),length(grouplist));

for s = 1:length(sheets)
    
    waitbar(s/length(sheets),w,['Reading sheet: ',sheets{s}(1:length(sheets{s})-1)]);
    
    if ~strcmp(sheets{s},'Sheet1') & ~strcmp(sheets{s},'Sheet2') & ~strcmp(sheets{s},'Sheet3'),
        
        % Read the relevant section of each XLS sheet
        data = xlsread(XLS_in,sheets{s});
        
        if ~isempty(data)
            
            % Exclude header, stationary particles and those moving outside max/min rates
            data(1,:) = [];
            data(data(:,10) == 0,10) = NaN;
            if isfield(expt.tracking(tracked),'maxrate') & ~isempty(expt.tracking(tracked).maxrate), data(data(:,10) >= expt.tracking(tracked).maxrate,10) = NaN; end
            if isfield(expt.tracking(tracked),'minrate') & ~isempty(expt.tracking(tracked).minrate), data(data(:,10) <= expt.tracking(tracked).minrate,10) = NaN; end
            
            % Calculate the histogram data based on the mean MCT rate of each particle
            h2D = zeros(length(expt.tracking(tracked).bins),length(expt.tracking(tracked).times));
            [C,ia,ic] = unique(data(:,1));
            for i = 1:length(C),
                for j = 1:max(data(ic == i,2)),
                    h1D = hist(nanmean(data((ic == i) & (data(:,2) == j),10)),expt.tracking(tracked).bins)';
                    timepoint = find(expt.tracking(tracked).times == C(i));
                    h2D(:,timepoint) = h2D(:,timepoint) + h1D;
                end   
            end
            
            % Save histogram in the XLS sheet
            xlswrite(XLS_out,NaN(200,200),sheets{s},'A1');
            xlswrite(XLS_out,sort(expt.tracking(tracked).times),sheets{s},'B1');
            xlswrite(XLS_out,expt.tracking(tracked).bins',sheets{s},'A2');
            xlswrite(XLS_out,h2D,sheets{s},'B2');
            
            % Get the row number
            m = 1;
            while ~strcmp(expt.info.imagestart{m},sheets{s}), m = m + 1; end
            
            % Add the histogram data to the correct group
            histogram(:,:,groups{m,2}) = histogram(:,:,groups{m,2}) + h2D;
            
        end
        
    end
    
end

% Save the results in the MAT file
save(MAT,'histogram','-append');

% Write the histogram data to an XLS file
waitbar(0.5,w,'Writing sheet: Histogram');
xlswrite(XLS_out,NaN(200,200),'Histogram','A1');
histogram = reshape(histogram,length(expt.tracking(tracked).bins),[]);
xlswrite(XLS_out,repmat(sort(expt.tracking(tracked).times),[1 size(groups,2)]),'Histogram','B1');
xlswrite(XLS_out,expt.tracking(tracked).bins','Histogram','A2');
xlswrite(XLS_out,histogram,'Histogram','B2');

close(w)
