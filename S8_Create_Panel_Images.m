if(isunix), datapath = '/media/RAID0/Data/SPring-8/';
elseif(ispc), datapath = 'P:/SPring-8/'; end

% Set read and write paths
read = [datapath,'2012 A/20XU/MCT/Images/FD Corrected/'];
write = [datapath,'2012 A/20XU/MCT/Images/Processed/Vertical/'];

% Determine the animals in the read path
animals = dir(read);

% gap = uint8(255*ones(2160,50));
gap = uint8(255*ones(50,2560));

for i = 3:length(animals),
    
    % Set the current read and write directory
    current_read = [read,animals(i).name,'/Low/'];
    current_write = [write,animals(i).name,'/'];
    
    if(~exist(current_write)), mkdir(current_write), end
    
    R01 = dir([current_read,'*R01*.jpg']);
    R03 = dir([current_read,'*R03*.jpg']);
    
    % Create each composite frame
    for frame = 1:110,
        
        % Load the right frame
        r = imread([current_read,R03(frame).name]);
        
        % Load the left frame
        if((frame >= 1)&(frame <= 12)),
            l = imread([current_read,R01(frame).name]);
        
        elseif((frame >= 55)&(frame <= 66)),
            l = imread([current_read,R01(frame-42).name]);
        else
            l = zeros(size(r));
        end

        % Create the panel image
%         output = [l,gap,r];
        output = [l;gap;r];
        
        % Write the image
        imwrite(output,sprintf('%s%s-%0.2d.jpg',current_write,animals(i).name,frame));
        
    end
end