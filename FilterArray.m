%%Removes data that is "threshVal" standard deviations away from the mean

function [filteredArray] = FilterArray(array, threshVal)

    mean = mean2(array);
    stddev = std(array);
    rmArray = [];
        for i = 1:length(array)

            if array(i) < mean - (threshVal * stddev)
                rmArray=[rmArray,i];
            elseif array(i) > mean + (threshVal * stddev)
                rmArray=[rmArray,i];
            else

            end
        end
        for i = 1:length(rmArray)
            rmVal = rmArray(i);
            rmVal = rmVal - i + 1;
            array(rmVal) = [];
        end
        
        
       filteredArray = array;
end