% Script to make 2 panel image sequences comparing Mannitol and HS

if(isunix), datapath = '/data/RAID0/exports/processing/SPring-8/';
elseif(ispc), datapath = 'P:/SPring-8/'; end

% Set read and write paths
read = [datapath,'2012 B/MCT/Images/Processed/Movie Frames/'];
write = [datapath,'2012 B/MCT/Images/Processed/Panels/'];

panels = [34,42;37,43;38,44;39,45;40,46;41,48];
gap = 20;

for panel = 2:size(panels,1),
    
    for frame = 1:2400,
 
        M = sprintf('%sS8_12B_XU_%d/Frame %0.4d.jpg',read,panels(panel,1),frame);
        HS = sprintf('%sS8_12B_XU_%d/Frame %0.4d.jpg',read,panels(panel,2),frame);
        
        M = imread(M);
        HS = imread(HS);
        
        output = [M,zeros(size(M,1),gap),HS];
        output = imresize(output,0.25);
        
        outFolder = sprintf('%s%d and %d/',write,panels(panel,1),panels(panel,2));
        if(~exist(outFolder)), mkdir(outFolder), end
        outFile = sprintf('Frame %0.4d.jpg',frame);
        imwrite(output,[outFolder,outFile]);
        
    end
    
end