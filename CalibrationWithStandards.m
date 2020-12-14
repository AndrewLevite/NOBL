function []=CalibrationWithStandards()

runType = 1; %Designates that the script is running calibration of standards. 
    
    global firstDir
    global mark1
    global mark2
    global viewType
    global matrix
    
    keV = input('Enter the effective energy of the scanner in keV \n');
    cd(firstDir)
    HUs = HUcalc(keV);
    HU1 = HUs(1);
    HU2 = HUs(2);
    HU3 = HUs(3);
    %HU4 = Have the user enter a HU of a forth standard if applicable
    HU4 = NaN; %if there is no forth standard

    %This if statement determines if there is a forth standard included
    if ~isnan(HU4)
        numCalib = 4;
    else 
        numCalib = 3;
    end
        


        %Verifies correct order for first and second marks. If not,
        %switches the order for the user
        if(mark1>mark2)
            tempVar = mark1;
            mark1=mark2;
            mark2 = tempVar;
        end


        %Iterates through each of the standards, allowing the user
        %to select which standard they are calibrating.
        if ~isnan(HU4)
            numCalib = 4;
        else 
            numCalib = 3;
        end

        %for each standard
        for calib = [1:numCalib]

                %Switches between first and last slice, allowing using to
                %select center of stanadard ROI. Prompts user for center of ROI
                %after slice has been displayed.
                msgbox(sprintf('Please indicate Mark1 and Mark2 of standard #%d, then press the Enter key in the command window. You will then be asked to select the center point of the standard. (Note: please start with the least dense standard)',calib))
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

            %Stores every value calculated from standard within radius.
            %(Excludes 0 value pixels)
            GSVstring = [];
            
            %Organizes strings by slice
            GSVmatrix = [];

            %Iterates through each and calcuates the average GS values
            %over area of interest
            %For each slice
            for slicenumber = mark1:mark2

                locationX = (double(slicenumber)*double(mx))+bx;
                locationY = (double(slicenumber)*double(my))+by;
                Center = [double(locationX), double(locationY)];

                %Chooses appropriate slice depending on user view. 
                if viewType == 1
                    [gsValues] = CircularAVG(squeeze(matrix(:,:,slicenumber)), radius, Center(2), Center(1));
                    %create matrix of values where each row is the
                    %pixels of interest in one slice of the VOI
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
                filename = ('VOI Standard 1.csv');
                writetable(cell2table(GSVmatrix), filename, 'writevariablenames', false)
                
            elseif calib == 2;
                TV2 = totalValue;
                PV2 = totalAverage;
                PV2std = STD(1);
                filename = ('VOI Standard 2.csv');
                writetable(cell2table(GSVmatrix), filename, 'writevariablenames', false)
                
            elseif calib == 3
                TV3 = totalValue;
                PV3 = totalAverage;
                PV3std = STD(1);
                filename = ('VOI Standard 3.csv');
                writetable(cell2table(GSVmatrix), filename, 'writevariablenames', false)
                
            elseif calib == 4
                TV4 = totalValue;
                PV4= totalAverage;
                PV4std = STD(1);
                filename = ('VOI Standard 4.csv');
                writetable(cell2table(GSVmatrix), filename, 'writevariablenames', false)
                
            end
        end
        if ~isnan(HU4)

            HounsfieldUnitmat = [HU1;HU2;HU3;HU4;];
            Dmat = [PV1; PV2; PV3; PV4;];
        else
            HounsfieldUnitmat = [HU1;HU2;HU3;];
            Dmat = [PV1; PV2; PV3;];

        end


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
        subplot(5,1,1)
        plot(Dmat, fixHU_lin, 'r--')
        hold on
        plot(Dmat, HounsfieldUnitmat, 'k+', 'MarkerSize', 15)
        hold off

        %Histogram Visualization for each standard
        subplot(5,1,2)
        s1Hist = histogram(TV1)
        s1Hist.BinEdges = [0:5500];

        title('Standard 1 Histogram')
        size(TV1)
        S1Data = [[PV1,PV1std],TV1];
        S1Data = S1Data.';

        subplot(5,1,3)
        s2Hist = histogram(TV2)
        s2Hist.BinEdges = [0:5500];
        title('Standard 2 Histogram')
        S2Data = [[PV2,PV2std],TV2];
        S2Data = S2Data.';

        subplot(5,1,4)
        s3Hist = histogram(TV3)
        s3Hist.BinEdges = [0:5500];
        title('Standard 3 Histogram')
        S3Data = [[PV3,PV3std],TV3];
        S3Data = S3Data.';

        if ~isnan(HU4)
            subplot(5,1,5)
            s3Hist = histogram(TV4)
            s3Hist.BinEdges = [0:5500];
            title('Standard 4 Histogram')
            S4Data = [[PV4,PV4std],TV4];
            S4Data = S4Data.';
        end

        % Displays the mean and standard deviation of the GSV data
        if ~isnan(HU4)
            display = msgbox({['Mean 1 = ' num2str(mean2(TV1))]; ['Std 1 = ' num2str(std(double(TV1)))]; ['Mean 2 = ' num2str(mean2(TV2))]; ['Std 2 = ' num2str(std(double(TV2)))]; ['Mean 3 = ' num2str(mean2(TV3))]; ['Std 3 = ' num2str(std(double(TV3)))]; ['Mean 4 = ' num2str(mean2(TV4))]; ['Std 4 = ' num2str(std(double(TV4)))]});
        else
            display = msgbox({['Mean 1 = ' num2str(mean2(TV1))]; ['Std 1 = ' num2str(std(double(TV1)))]; ['Mean 2 = ' num2str(mean2(TV2))]; ['Std 2 = ' num2str(std(double(TV2)))]; ['Mean 3 = ' num2str(mean2(TV3))]; ['Std 3 = ' num2str(std(double(TV3)))]});
        end

        %Parts of this section are commented out because we use a linear
        %fit to calibrate the data. If it is desired in the future, an
        %exponential fit may be more accurate
        %choice = questdlg('Use the linear or exponential fit for calibration?',' ', 'Linear','Cancel','Cancel');
        
        %switch choice     
        %case 'Linear'

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

            if length(S3Data) < dataCatIndex
                dataCatIndex = length(S3Data);
            end
            if ~isnan(HU4)
                if length(S4Data) < dataCatIndex
                    dataCatIndex = length(S4Data);
                end
            end
            %Array containing values for each standard in a different
            %column. 
            if ~isnan(HU4)
                SData = [S1Data(1:dataCatIndex), S2Data(1:dataCatIndex), S3Data(1:dataCatIndex), S4Data(1:dataCatIndex)];
            else
                SData = [S1Data(1:dataCatIndex), S2Data(1:dataCatIndex), S3Data(1:dataCatIndex)];
            end

            cd(dirname)
            %Writes raw standard data as .csv file
            dlmwrite('RawDataStandard.csv',SData,'roffset',1,'coffset',0,'-append')
            cd(firstDir)
            %Generates distribution of RS and RI values based on raw
            %standard data. 
            GenerateRescaleDist(SData,HU1,HU2,HU3,HU4,dirname)



        %Does nothing if calibration data is not sufficient.     
        %case 'Cancel'

        %end
        updateImage()
end