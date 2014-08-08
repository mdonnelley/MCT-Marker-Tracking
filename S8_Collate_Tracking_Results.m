% Script to collate data about MCT rates in each animal

PathName = 'I:/SPring-8/2011 B/20XU/MCT/Images/Processed/MCT Rate Calculation/R03/';
cols = 11:13;

B = 'MCT Rate Calculation 2013-Apr-23 12-05-32 MD - Baseline.xls';
C = 'MCT Rate Calculation 2013-Apr-23 13-01-13 MD - Control.xls';
T = 'MCT Rate Calculation 2013-Apr-29 09-43-48 MD - Treatment.xls';

[B_status,B_sheets] = xlsfinfo([PathName,B]);
[C_status,C_sheets] = xlsfinfo([PathName,C]);
[T_status,T_sheets] = xlsfinfo([PathName,T]);

B_rows = [1,251];
C_rows = 501:250:2750;
T_rows = 1001:500:5500;

[animals,B_IX] = sort(B_sheets);

for s = 1:length(B_sheets),
    
    IX = find(strcmp(animals,B_sheets(s)));
    data = xlsread([PathName,B],s);
    stats(1:2,:,IX) = data(B_rows,cols);
    
end

for s = 1:length(C_sheets),
    
    IX = find(strcmp(animals,C_sheets(s)));
    data = xlsread([PathName,C],s);
    stats(3:11,:,IX) = data(C_rows,cols);
    
end

for s = 1:length(T_sheets),
    
    IX = find(strcmp(animals,T_sheets(s)));
    data = xlsread([PathName,T],s);
    stats(3:11,:,IX) = data(T_rows,cols);
    
end

stats(isnan(stats)) = 0;
average = squeeze(stats(:,1,:));
stdev = squeeze(stats(:,2,:));
extra = squeeze(stats(:,3,:));

average = average(:,[1 3 10 11 12 2 5 6 7 4 8 9]);
stdev = stdev(:,[1 3 10 11 12 2 5 6 7 4 8 9]);
extra = extra(:,[1 3 10 11 12 2 5 6 7 4 8 9]);