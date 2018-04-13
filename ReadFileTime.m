function [im, t] = ReadFileTime(filename,varargin)

% Function to read an image and its acquisition time. Works for images
% acquired in HiPic at SPring-8 Synchrotron, the EPICS system (PCO) at the
% Australian Synchrotron, or the Hokawo system at the MuCLS
%
% EPICS: Returns the time since 1 Jan 1900 in seconds
% HiPic: Returns the time since the start of the imaging run in seconds
% Hokawo: Returns the time in seconds

% Check inputs are correct
if exist(filename),
    switch nargin,
        case 1
            page = 1;
            im = imread(filename);
        case 2
            [filepath,name,ext] = fileparts(filename);
            if ~strcmp(ext,'.TIF'),
                error('Multiple pages only supported for TIF files');
            end
            page = varargin{1};
            im = imread(filename,page);
        otherwise
            error('Incorrect number of input arguments. Must be 1 or 2');
    end
else
    error(['File ',filename,' does not exist!'])
end

info = imfinfo(filename);

% EPICS (AS) and HiPic (Orca Flash)
if isfield(info,'Software'),
    
    if contains(info.Software, 'EPICS'),
        
        [imNumber,t] = DateStampPCO(im);
        t = 24 * 60 * 60 * datenum(t);
        
    elseif contains(info.Software, 'HiPic'),
        
        t = HiPicAcquireTime(filename);
        
    else
        
        t = [];
        warning('File is not from HiPic or EPICS');
        
    end
    
% Hokawo (MuCLS Hammamatsu Camera)
elseif isfield(info, 'ImageDescription'),
    
    if contains(info(page).ImageDescription, 'Hokawo'),
        
        ImageDescription = info(page).ImageDescription;
        fieldList = strsplit(ImageDescription,';');
        vTStamp = fieldList{find(contains(fieldList,'vTStamp='))};
        vTStamp = str2num(vTStamp(9:length(vTStamp)));
        t = vTStamp / 1000;
        
    else
        
        t = [];
        warning('File is not from Hokawo');
        
    end
    
    % FD Correction code (t written as metadata)
elseif isfield(info, 'Comment'),
    
    t = str2num(info.Comment{1});
    
else
    
    t = [];
    warning('File is not from HiPic, EPICS, Hokawo, and contains no Comment field');
    
end