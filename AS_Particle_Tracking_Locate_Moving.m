% % Load the frames to analyse
% setbasepath;
% MAT = [basepath,...
%     expt.file.datapath,...
%     'Processed/',...
%     'Framelist 2017-Jul-05 14-02-55.mat'];
% load(MAT);
%
% for imageset = expt.tracking.runlist,
%
%     for t = 1:length(expt.tracking.times),
%
%         frames = keepframes{imageset}{t};
%
%         for i = 2:length(frames), % Start at 2 since first frame has NaN movement
%
%             indices = find(data{imageset}(:,3) == frames(i));
%             subset = data{imageset}(indices,10:11);
%
%         end
%
%     end
%
% end






% function moving = AS_Particle_Tracking_Locate_Moving(expt, data)
% 
% setbasepath;
% if isfield(expt.naming,'zeropad') zeropad = expt.naming.zeropad; else zeropad = 4; end
% 
% threshold = 1; % Threshold in mm for particle movement
% imageset = 20,
% 
% if ~isempty(data{imageset})
%     
%     data2 = [];
%     
%     for f = unique(data{imageset,1}(:,3))',
%         
%         indices = find(data{imageset,1}(:,3) == f);
%         frameData = data{imageset,1}(indices,:);
%         
%         diffFromMedian = abs(frameData(:,10) - nanmedian(frameData(:,10)));
%         particles = find(diffFromMedian > threshold);
%         
%         particleData = frameData(particles,:);
%         
%         data2 = [data2; particleData];
%         
%     end
%     
%     moving{imageset,:} = data2;
%     
% end






function moving = AS_Particle_Tracking_Locate_Moving(expt, data)

setbasepath;
if isfield(expt.naming,'zeropad') zeropad = expt.naming.zeropad; else zeropad = 4; end

threshold = 0.2; % Threshold in mm for particle movement
imageset = 20;

Xdiv = 6;
Ydiv = 5;

if ~isempty(data{imageset})

    data2 = [];

    for t = unique(data{imageset,1}(:,1))',

        indices = find(data{imageset,1}(:,1) == t);
        timepointData = data{imageset,1}(indices,:);
        
        
        
        
        
        y = 2; x = 1;        
        Ymin = round((y - 1) * expt.tracking.imsize(1) / Ydiv) + 1;
        Ymax = round(y * expt.tracking.imsize(1) / Ydiv);
        Xmin = round((x - 1) * expt.tracking.imsize(2) / Xdiv) + 1;
        Xmax = round(x * expt.tracking.imsize(2) / Xdiv);
        
        indices = find(timepointData(:,4) > Xmin & timepointData(:,4) < Xmax & timepointData(:,5) > Ymin & timepointData(:,5) < Ymax);
        regionData = timepointData(indices,:);
        
        for f = unique(regionData(:,3))',
        
            indices = find(regionData(:,3) == f);
            particleData = regionData(indices,:);
        
            diffFromMedian = abs(particleData(:,10) - nanmedian(particleData(:,10)));
            particles = find(diffFromMedian > threshold);
        

%         for p = unique(timepointData(:,2))',
% 
%             indices = find(timepointData(:,2) == p);
%             particleData = timepointData(indices,:);
% 
%             dx = particleData(:,4) - circshift(particleData(:,4),[1 0]);
%             dy = particleData(:,5) - circshift(particleData(:,5),[1 0]);
%             pixels = sqrt(dx(1).^2 + dx(2).^2);
%             totalDistance = pixels * expt.tracking.pixelsize;
% 
%             if totalDistance > threshold, data2 = [data2; particleData]; end

        end

    end

    moving{imageset,:} = data2;

end








