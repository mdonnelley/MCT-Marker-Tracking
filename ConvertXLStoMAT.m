function ConvertXLStoMAT(MAT)

% Function to convert XLS data store into MAT data store

% Set the base pathname for the current machine
setbasepath;

w = waitbar(0,'Reading MAT and XLS data');
load(MAT);
XLS = [MAT(1:length(MAT)-4),'.xlsx'];

% Make a backup copy of the MAT file
copyfile(MAT,[MAT(1:length(MAT)-4),' BACKUP.mat'],'f');

% Get the sheet names
[status,sheets] = xlsfinfo(XLS);

% Create the data array
data = cell.empty(length(expt.info.imagestart),0);

for s = 1:length(sheets)
    
    waitbar(s/length(sheets),w,['Reading sheet: ',sheets{s}(1:length(sheets{s})-1)]);
    
    if ~strcmp(sheets{s},'Sheet1') & ~strcmp(sheets{s},'Sheet2') & ~strcmp(sheets{s},'Sheet3') & ~strcmp(sheets{s},'Mean') & ~strcmp(sheets{s},'SD') & ~strcmp(sheets{s},'Number') & ~strcmp(sheets{s},'Histogram'),

        % Find the line number in the XLS Experiment Sheet
        m = 1;
        while ~strcmp(expt.info.imagestart{m},sheets{s}), m = m + 1; end
        
        % Read the relevant section of each XLS sheet
        data{m} = xlsread(XLS,sheets{s},'A:K');
        
ia = find(data{m}(:,2) - circshift(data{m}(:,2),[1 0]) ~= 0);
data{m}(ia,6:11) = NaN;
        
    end
    
end

% Save the MAT file
waitbar(1,w,'Writing MAT file');
save(MAT,'data','-append');

close(w)