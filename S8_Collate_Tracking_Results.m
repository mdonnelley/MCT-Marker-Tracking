% Script to collate data about MCT rate of all particles in each animal

PathName = 'I:/SPring-8/2012 A/20XU/MCT/Images/Processed/MCT Rate Calculation/R01/';
cols = 10;

B = 'MCT Rate Calculation 2013-Jul-29 10-52-28 MD Baseline.xls';
R = 'MCT Rate Calculation 2013-Jul-29 13-44-21 MD Repeat.xls';

[B_status,B_sheets] = xlsfinfo([PathName,B]);
[R_status,R_sheets] = xlsfinfo([PathName,R]);

baseline = [];
three = [];
nine = [];
twentyfive = [];

for s = 1:length(B_sheets),
    
    data = xlsread([PathName,B],s);
    
    % Get mean MCT rate for each particle
    for i = 1:max(data(data(:,4) > 0, 2))
       
        rate = nanmean(data(data(:,2) == i,10));
        baseline = [baseline;rate];
        
	end

end

[animals,R_IX] = sort(R_sheets);

for s = 1:length(R_sheets),
    
    IX = find(R_IX == s);
    data = xlsread([PathName,R],s);
    
    % Get mean MCT rate for each particle
    for i = 1:max(data(data(:,4) > 0, 2))
        
        rate = nanmean(data(data(:,2) == i,10));
        
        if(IX <= 8),
            nine = [nine;rate];
        elseif(IX >= 9 && IX <= 16),
            twentyfive = [twentyfive;rate];
        elseif(IX >= 17),
            three = [three;rate];
        end
        
    end
    
end