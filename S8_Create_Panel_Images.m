% Script to make panel images showing all timepoints

% Cumulative image counts taken from the Labchart file for MX02 to MX18
imcountsA = [zeros(3,12);...
    728,787,847,907,967,1027,1087,1147,1207,1267,1326,1386;...
    1711,1771,1831,1891,1951,2011,2071,2130,2190,2250,2310,2370;...
    2513,2567,2627,2687,2747,2807,2867,2926,2986,3046,3106,3166;...
    3779,3838,3898,3958,4017,4077,4137,4197,4257,4316,4376,4436;...
    647,706,766,826,886,946,1006,1065,1125,1185,1245,1305;...
    1663,1723,1783,1843,1902,1962,2022,2081,2141,2201,2261,2321;...
    2545,2605,2665,2724,2784,2844,2904,2964,3023,3083,3143,3203;...
    3345,3405,3464,3524,3584,3644,3703,3763,3823,3882,3942,4002;...
    4279,4339,4399,4459,4519,4578,4638,4698,4758,4818,4877,4937;...
    5114,5174,5234,5294,5354,5413,5473,5533,5593,5653,5712,5772;...
    6132,6192,6252,6312,6372,6432,6492,6552,6612,6671,6731,6791;...
    7052,7117,7177,7237,7297,7357,7416,7476,7536,7595,7655,7711;...
    7979,8039,8099,8158,8218,8278,8338,8398,8457,8517,8577,8637;...
    148,208,268,328,388,447,507,567,627,687,746,806;...
    1010,1070,1130,1189,1249,1309,1369,1429,1489,1549,1609,1668;...
    1914,1974,2034,2094,2154,2214,2273,2333,2393,2453,2513,2573];

% Calculate the number of images in each group
imcountsB = imcountsA(:,2:12)-imcountsA(:,1:11);

% Calculate the number of images to the start of each group
imcountsC = [zeros(19,1),cumsum(imcountsB,2)];

if(isunix), datapath = '/media/RAID0/Data/SPring-8/';
elseif(ispc), datapath = 'X:/SPring-8/'; end

% Set read and write paths
read = [datapath,'2011 B/20XU/MCT/Images/FD Corrected/'];
write = [datapath,'2011 B/20XU/MCT/Images/Processed/Panels/Nine/'];
% write = [datapath,'2011 B/20XU/MCT/Images/Processed/Panels/Four/'];

% Determine the animals in the read path
animals = dir(read);

% Set the output layout
% layout = [1,4;7,9];
layout = [1,4,5;6,7,8;9,10,11];

for i = 4:19,
    
    % Set the current read and write directory
    current_read = [read,animals(i).name,'/Low/'];
    current_write = [write,animals(i).name,'/Low/']
    
    if(~exist(current_write)), mkdir(current_write), end
    files = dir([current_read,'*.jpg']);
    
    % Create each composite frame
    for frame = 1:59,
        
        output = [];
        
        % Composite rows
        for a = 1:size(layout,1),
            
            row = [];
            
            % Composite columns
            for b = 1:size(layout,2),
                
                current = [current_read,files(frame + imcountsC(i,layout(a,b))).name];
                input = imread(current);
                row = [row,input];
                
            end
            
            output = [output;row];
            
        end
        
        % Resize the image to be the same size as a single input image
        output = imresize(output,1/size(layout,1));
        
        % Write the image
        imwrite(output,sprintf('%s%s-%0.2d.jpg',current_write,animals(i).name,frame));
        
    end
end