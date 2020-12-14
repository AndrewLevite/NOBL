function PVaverage = VOIaverage(Values)

PVstring=[];

for i = 1:size(Values,2)
    
    tempArray = Values{i};
    PVstring = [PVstring tempArray]; 
    
end

PVaverage = mean(PVstring);