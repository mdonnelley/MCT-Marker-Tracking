function t = HiPicAcquireTime(filename)

% Function to extract image acquire time from TIF images saved by HiPic
% software. The return value is the number of seconds that have elapsed
% since the first image in the sequence was captured.

info = imfinfo(filename);
HiPicMetadata = info.ImageDescription;

a = strfind(HiPicMetadata,'Time="');
b = strfind(HiPicMetadata,'ms",');
t = str2num(HiPicMetadata(a+6:b-1));

if isempty(t), t = 0; end

t = t/1000;