function [] = dataAnalysis ()

continueon = true;
count = 1;
names = [];

while continueon == true
    
    [fileName, pathName] = uigetfile('*.csv');
    data{count} = csvread(fullfile(pathName,fileName)) ;
    names{count} = fileName;
    
    question = questdlg('Do you want to analyze more data sets than you have already selected?', 'Choose One', 'Yes', 'No', 'Cancel');
        switch question
        case 'Yes'
            count = count + 1;
        case 'No'
            continueon = false;
        end

    
    
end 

figure(10)

    for i = 1:size(data,2)
        data{i}(data{i}==0) = NaN;
        avgs(i) = mean(nanmean(data{i})');
        stds(i) = mean(nanstd(data{i})');
        %Histogram Visualization for each standard
        h(i) = histogram(data{i});
        hold on
        
    end
    
 legend(names)
 
 disp(avgs)
 disp(stds)

end

