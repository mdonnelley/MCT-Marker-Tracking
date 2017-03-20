function S8_Collate_Tracking_Results(MAT)

% Function to collate data about MCT rates in each group
%
% Function takes all of the particle MCT measurements and collates them
% into {mean, standard deviation, N} for each animal and timepoint.

% Set the base pathname for the current machine
setbasepath;

w = waitbar(0,'Reading MAT and XLS data');
load(MAT);
XLS = [MAT(1:length(MAT)-4),'.xlsx'];

% Get the group information
groups = cell(size(expt.info.imagestart));
grouplist = fieldnames(expt.group);
for i = 1:length(grouplist),
    for j = getfield(expt.group,grouplist{i})
        groups{j,1} = grouplist{i};
        groups{j,2} = i;
    end
end

% % Retain only the subjects analysed in this run
groups = [expt.info.imagestart, groups];
% groups = groups(sort(expt.tracking(tracked).runlist),:);

% % Get the sheet names
% [status,sheets] = xlsfinfo(XLS);

% Set default values
if isfield(expt.tracking(tracked),'bins') & ~isempty(expt.tracking(tracked).bins), bins = expt.tracking(tracked).bins; else bins = 0:0.05:5; end
if isfield(expt.tracking(tracked),'maxrate') & ~isempty(expt.tracking(tracked).maxrate), maxrate = expt.tracking(tracked).maxrate; else maxrate = Inf; end
if isfield(expt.tracking(tracked),'minrate') & ~isempty(expt.tracking(tracked).minrate), minrate = expt.tracking(tracked).minrate; else minrate = 0; end
if isfield(expt.tracking(tracked),'minparticles') & ~isempty(expt.tracking(tracked).minparticles), minparticles = expt.tracking(tracked).minparticles; else minparticles = 0; end

% Pre-allocate the arrays
average = zeros(size(groups,1),length(expt.tracking(tracked).times));
SD = zeros(size(groups,1),length(expt.tracking(tracked).times));
number = zeros(size(groups,1),length(expt.tracking(tracked).times));
histogram = zeros(length(bins),length(expt.tracking(tracked).times),length(grouplist));

for m = 1:length(data)    

    waitbar(m/length(data),w,['Analysing: ',expt.info.imagestart{m}]);
    
%     if ~strcmp(sheets{s},'Sheet1') & ~strcmp(sheets{s},'Sheet2') & ~strcmp(sheets{s},'Sheet3') & ~strcmp(sheets{s},'Mean') & ~strcmp(sheets{s},'SD') & ~strcmp(sheets{s},'Number') & ~strcmp(sheets{s},'Histogram'),
%         
%         % Read the relevant section of each XLS sheet % MODIFY THIS TO USE MATLAB DATA RATHER THAN XLS DATA
%         data = xlsread(XLS,sheets{s},'A:K');
        
        if ~isempty(data{m})
            
            % Exclude stationary particles and those moving outside max/min rates
            data{m}(data{m}(:,10) >= maxrate,:) = NaN;
            data{m}(data{m}(:,10) <= minrate,:) = NaN;
            
            % Get the summary stats info for all particles at each timepoint
            stats = [];
            h2D = zeros(length(bins),length(expt.tracking(tracked).times));
            [C,ia,ic] = unique(data{m}(:,1));
            for i = 1:length(C),
                    
                % Exclude if there are an insufficient number of particles
                numparticles = max(data{m}(ic == i,2));
                if(numparticles >= minparticles),
                    
                    stats(1,i) = C(i);
                    stats(2,i) = nanmean(data{m}(ic == i,10));
                    stats(3,i) = nanstd(data{m}(ic == i,10));
                    stats(4,i) = length(unique(data{m}(ic == i,2)));
                    
                    % Calculate the histogram data based on the mean MCT rate of each particle
                    for j = 1:numparticles,
                        h1D = hist(nanmean(data{m}((ic == i) & (data{m}(:,2) == j),10)),bins)';
                        timepoint = find(expt.tracking(tracked).times == C(i));
                        h2D(:,timepoint) = h2D(:,timepoint) + h1D;
                    end
                    
                end
                
            end
            
%             % Save histogram in the XLS sheet
%             xlswrite(XLS,NaN(200,200),sheets{s},'L1');
%             xlswrite(XLS,sort(expt.tracking(tracked).times),sheets{s},'M1');
%             xlswrite(XLS,bins',sheets{s},'L2');
%             xlswrite(XLS,h2D,sheets{s},'M2');
            
%             % Get the row number
%             m = 1;
%             while ~strcmp(groups{m,1},sheets{s}), m = m + 1; end
         
            % Add the histogram data to the correct group
            histogram(:,:,groups{m,3}) = histogram(:,:,groups{m,3}) + h2D;

            for i = 1:size(stats,2)
                
                % Get the column number (in case there is no data for some timepoints)
                t = find(stats(1,i) == sort(expt.tracking(tracked).times));
                
                % Save the stats
                average(m,t) = stats(2,i);
                SD(m,t) = stats(3,i);
                number(m,t) = stats(4,i);
                
            end
            
%         end
        
    end
    
end

% Save the results in the MAT file
save(MAT,'average','SD','number','histogram','-append');

% Write the mean data back to the XLS sheet
waitbar(0,w,'Writing sheet: Mean');
xlswrite(XLS,groups(:,1),'Mean','A2');
xlswrite(XLS,groups(:,2),'Mean','B2');
xlswrite(XLS,sort(expt.tracking(tracked).times),'Mean','C1');
xlswrite(XLS,average,'Mean','C2');

% Write the standard deviation data back to the XLS sheet
waitbar(0.25,w,'Writing sheet: SD');
xlswrite(XLS,groups(:,1),'SD','A2');
xlswrite(XLS,groups(:,2),'SD','B2');
xlswrite(XLS,sort(expt.tracking(tracked).times),'SD','C1');
xlswrite(XLS,SD,'SD','C2');

% Write the number of particles tracked back to the XLS sheet
waitbar(0.5,w,'Writing sheet: Number');
xlswrite(XLS,groups(:,1),'Number','A2');
xlswrite(XLS,groups(:,2),'Number','B2');
xlswrite(XLS,sort(expt.tracking(tracked).times),'Number','C1');
xlswrite(XLS,number,'Number','C2');

% Write the histogram data back to the XLS sheet
waitbar(0.75,w,'Writing sheet: Histogram');
xlswrite(XLS,NaN(200,200),'Histogram','A1');
histogram = reshape(histogram,length(bins),[]);
xlswrite(XLS,repmat(sort(expt.tracking(tracked).times),[1 length(grouplist)]),'Histogram','B1');
xlswrite(XLS,bins','Histogram','A2');
xlswrite(XLS,histogram,'Histogram','B2');

close(w)
