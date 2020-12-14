function []=CalibrationWithWater()

    global firstDir
    global mark1
    global mark2
    global viewType
    global matrix
    
    %Values of EXPECTED standard values
    HU1 = -1000;
    HU2 = 0;
    HU3 = NaN;
    HU4 = NaN;
  
    %Verifies correct order for first and second marks
    if(mark1>mark2)
        tempVar = mark1;
        mark1=mark2;
        mark2 = tempVar;
    end

    for calib = [1:2]
        if calib == 1
        msgbox(sprintf('Please indicate Mark1 and Mark2 of a region of air, then press the Enter key in the command window. You will then be asked to select the center point of this region. (Note: please select slices adjacent to your region of interest)'))
        elseif calib == 2
        msgbox(sprintf('Please indicate Mark1 and Mark2 of a region of water, then press the Enter key in the command window. You will then be asked to select the center point of this region. (Note: please select slices adjacent to your region of interest)'))
        end
        pause
        [CenterM1, CenterM2, radius] = getVOI();
        deltay = double(CenterM2(2))-double(CenterM1(2));
        deltaz = mark2 - mark1;
        my = double(deltay)/double(deltaz);
        by = double(CenterM1(2)) -double(my)*double(mark1);
        deltax = double(CenterM2(1))-double(CenterM1(1));
        mx = double(deltax)/double(deltaz);
        bx = double(CenterM1(1))- double(mx)*double(mark1);

        cd(firstDir)
        %Defines the number of slices to be averaged
        count = int16(mark2-mark1);
        %Defines size of data to be collected
        struct1 = size(matrix);

        %Creates appropriately sized array depending on the view of
        %user selected view.
        if viewType == 1
            struct = zeros(count, struct1(1), struct1(2));
        elseif viewType == 2 
            struct = zeros(count, struct1(1), struct1(3));   
        elseif viewType == 3
            struct = zeros(count, struct1(2), struct1(3));
        end

        %Stores EVERY value calculated from standard.
        GSVstring = [];
        %Organizes strings by slice
        GSVmatrix = [];

        %Iterates through each and calcuates the average GS values
        %over area of interest
        for slicenumber = mark1:mark2

            locationX = (double(slicenumber)*double(mx))+bx;
            locationY = (double(slicenumber)*double(my))+by;
            Center = [double(locationX), double(locationY)];

            %Chooses appropriate slice depending on user view. 
            if viewType == 1
                [gsValues] = CircularAVG(squeeze(matrix(:,:,slicenumber)), radius, Center(2), Center(1));
                GSVstring = [GSVstring, gsValues];
                GSVmatrix{slicenumber-mark1+1,1} = gsValues;

            elseif viewType == 2
                [gsValues] = CircularAVG(squeeze(matrix(:,slicenumber,:)), radius, Center(2), Center(1));
                GSVstring = [GSVstring, gsValues];
                GSVmatrix{slicenumber-mark1+1,1} = gsValues;

            elseif viewType == 3
                [gsValues] = CircularAVG(squeeze(matrix(slicenumber,:,:)), radius, Center(2), Center(1));
                GSVstring = [GSVstring, gsValues];
                GSVmatrix{slicenumber-mark1+1,1} = gsValues;

            end

        end

        totalAverage = VOIaverage(GSVmatrix);

        totalValue = GSVstring;
            
        STD = std(double(struct));
        
        
        %Generates statistics for each standard.
        if calib == 1;
            TV1 = totalValue;
            PV1 = totalAverage;
            PV1std = STD(1);
        elseif calib == 2;
            TV2 = totalValue;
            PV2 = totalAverage;
            PV2std = STD(1);
        end
    end
    HounsfieldUnitmat = [HU1;HU2];
    Dmat = [PV1; PV2];
    plotfig = figure(3);

    %Here we are solving for the rescale coeff. using the average
    %PV. Below we will then use average PV values for each slice to
    %solve for the rescale coeff for each slice. 
    rescale = polyfit(Dmat, HounsfieldUnitmat, 1);
    f1 = fit(Dmat, HounsfieldUnitmat, 'exp1');
    RS_lin = rescale(1);
    RI_lin = rescale(2);
    fixHU_lin = (Dmat*RS_lin) +RI_lin;

    figure(plotfig)
    subplot(3,1,1)
    plot(Dmat, fixHU_lin, 'r--')
    hold on
    plot(Dmat, HounsfieldUnitmat, 'k+', 'MarkerSize', 15)
    hold off

    %Histogram Visualization for each standard
    subplot(3,1,2)
    s1Hist = histogram(TV1)
    s1Hist.BinEdges = [0:5500];

    title('Air Histogram')
    size(TV1)
    S1Data = [[PV1,PV1std],TV1];
    S1Data = S1Data.';

    subplot(3,1,3)
    s2Hist = histogram(TV2)
    s2Hist.BinEdges = [0:5500];
    title('Water Histogram')
    S2Data = [[PV2,PV2std],TV2];
    S2Data = S2Data.';


    % Displays the mean and standard deviation of the GSV data

    display = msgbox({['Mean 1 = ' num2str(mean2(TV1))]; ['Std 1 = ' num2str(std(double(TV1)))]; ['Mean 2 = ' num2str(mean2(TV2))]; ['Std 2 = ' num2str(std(double(TV2)))];});
    
        %vol = DICOM2VolumeCBCT(dirname);
        cd(firstDir)
        %calibratedDir = GenerateCalibratedDicoms(dirname,vol,"standard",RS_lin,RI_lin)
        saveas(gcf,'CalibrationData.png')

       

        %Ensures that each array has the same number of elements,
        %length is choosen as smallest length of th setl
        if length(S1Data) < length(S2Data)


            dataCatIndex = length(S1Data);
        else
            dataCatIndex = length(S2Data);
        end


        %Array containing values for each standard in a different
        %column. 
        SData = [S1Data(1:dataCatIndex), S2Data(1:dataCatIndex)];

        cd(firstDir)
        %Writes raw standard data as .csv file
        dlmwrite('RawDataStandard.csv',SData,'roffset',1,'coffset',0,'-append')
        cd(firstDir)
        %Generates distribution of RS and RI values based on raw
        %standard data. 
        GenerateRescaleDist(SData,HU1,HU2,HU3,HU4,firstDir)   
    

end
