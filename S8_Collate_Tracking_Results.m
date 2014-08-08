% Script to collate data about number of particles in each animal

PathName = 'I:/SPring-8/2012 A/20XU/MCT/Images/Processed/MCT Rate Calculation/R01/';

baseline_IX = 1:24;
three_IX = 17:24;
nine_IX = 9:16;
twentyfive_IX = 1:8;

B = 'Particle Count 2013-Jul-30 10-34-23 Baseline.xls';
R = 'Particle Count 2013-Jul-30 11-59-36 Repeat';

[B_status,B_sheets] = xlsfinfo([PathName,B]);
[R_status,R_sheets] = xlsfinfo([PathName,R]);

[animals,B_IX] = sort(B_sheets);

for s = 1:length(B_sheets),
    
    IX = find(strcmp(animals,B_sheets(s)));
    data = xlsread([PathName,B],s);
    B_counts(IX) = size(data,1);
    
end

[animals,R_IX] = sort(R_sheets);

for s = 1:length(R_sheets),
    
    IX = find(strcmp(animals,R_sheets(s)));
    data = xlsread([PathName,R],s);
    R_counts(IX) = size(data,1);
    
end

B_counts(baseline_IX)'
R_counts(three_IX)'
R_counts(nine_IX)'
R_counts(twentyfive_IX)'