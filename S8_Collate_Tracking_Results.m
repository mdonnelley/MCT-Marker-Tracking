% Script to collate data about mean MCT rate in each animal

PathName = 'I:/SPring-8/2012 A/20XU/MCT/Images/Processed/MCT Rate Calculation/R01/';
cols = 11:12;

B = 'MCT Rate Calculation 2013-Jul-29 10-52-28 MD Baseline.xls';
R = 'MCT Rate Calculation 2013-Jul-29 13-44-21 MD Repeat.xls';

[B_status,B_sheets] = xlsfinfo([PathName,B]);
[R_status,R_sheets] = xlsfinfo([PathName,R]);

[animals,B_IX] = sort(B_sheets);

for s = 1:length(B_sheets),
    
    IX = find(B_IX == s);
    data = xlsread([PathName,B],s);
    particles = max(data((data(:,4) > 0) & (data(:,5) > 0),2));
    if(isempty(particles)), particles=0; end
    B_stats(IX,:) = [data(1,cols),particles];
    
end

[animals,R_IX] = sort(R_sheets);

for s = 1:length(R_sheets),
    
    IX = find(R_IX == s);
    data = xlsread([PathName,R],s);
    particles = max(data((data(:,4) > 0) & (data(:,5) > 0),2));
    if(isempty(particles)), particles=0; end
    R_stats(IX,:) = [data(1,cols),particles];
    
end

output = [B_stats,R_stats];
output(isnan(output))=0)