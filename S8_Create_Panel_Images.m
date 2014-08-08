% Script to make 3 panel image comparing NT, NS and HS

if(isunix), datapath = '/data/RAID0/exports/processing/SPring-8/';
elseif(ispc), datapath = 'P:/SPring-8/'; end

% Set read and write paths
read = [datapath,'2011 B/20XU/MCT/Images/Processed/Movie Frames/'];
write = [datapath,'2011 B/20XU/MCT/Images/Processed/Panels/Three/'];

for frame = 1:708,
    
    NT = imread(sprintf('%sMX17/Frame %0.3d.jpg',read,frame));
    NS = imread(sprintf('%sMX09/Frame %0.3d.jpg',read,frame));
    HS = imread(sprintf('%sMX15/Frame %0.3d.jpg',read,frame));
    
    output = [NT,NS,HS];
    
    output = imresize(output,0.3);
   
    imwrite(output,sprintf('%sFrame %0.3d.jpg',write,frame));
    
end