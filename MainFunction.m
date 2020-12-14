
function MainFunction

%% This code actually changes the rescale slop and intercept for all slices.
%-- KV
clear global
close all

%% Set all of your global variables.

global firstDir
firstDir = cd;

global activeMatSize
activeMatSize = 1;

%RS and RI is the rescale slope and rescale intercept for the linear
%calibration. RS and RI are obtained from the totalAverage variable. 
global RS_lin 
global RI_lin 
global RS_exp
global RI_exp

%Intial and final slice of region of interest -EL
global mark1
global mark2

%coeffa coeffb are the rescale slopes for the exponential calibration using
%the equation coeffa(exp(coeffb*PV)). coeffa and coeffb are
%obtained using the totalAverage variable.
global coeffa
global coeffb

%ginfo1 is used here to store the dicominfo information for each slice in
%the Generate3dMatrix -- KV
global ginfo1

%Axis of view
global viewType
%Postion of slider viewer
global sliderPositon

mark1 = 1;
mark2 = 1;
RS_lin = [];
RI_lin = [];
RS_exp = [];
RI_exp = [];
coeffb = [];
coeffa = [];
n = 1;
measurementCount = 1;

cordinates3 = 0;
viewType = 1;
sliderPositon = 1;

global matrix
matrix = [];

%% Selection of the DICOM files to analyze/calibrate
% First time loading a dicom file saves a matrix of pixel values to a
% matlab variable stored into the folder with all the dicom files to save
% time. 

%This is the introduction of the first subfunction, Generate3dMatrixCBCT.
%This is the function that was written to turn dicom files into a matlab
%matrix. 

[dirname] = uigetdir('Please choose dicom directory');
filetype = questdlg('Have you used this set of DiCOM files before?', 'Choose One', 'Yes', 'No', 'Cancel');
switch filetype
    case 'Yes'
        dataset = 2;
    case 'No'
        dataset = 1; 
end

if dataset == 1
    matrix = Generate3dMatrixCBCT(dirname); 
    cd(dirname)
    save('PVmatrix.mat','matrix')
    save('ginfo.mat','ginfo1')
elseif dataset == 2
    cd(dirname)
    load('PVmatrix.mat')
    load('ginfo.mat')
    
end


%% UI CALLBACKS %%%%%%%%%%
    %% This function dynamically switches to Axial view
    function switchViewAxialCallback(hObject,event)
        viewType = 1;
        activeMatSize = 1;
        updateImage()
       
    end
    
    %% This function dynamically switches to Sagittal view
    function switchViewSagittalCallback(hObject, event)
        viewType = 2;
        activeMatSize = 2;
        updateImage()
    end

    %% This function dynamically switches to Coronal view
    function switchViewCoronalCallback(hObject, event)
        viewType = 3;
        activeMatSize = 3;
        updateImage()
    end


%% This function is updating the image we see as we scroll through the z slices -- KV
    function updateImageCallback(hObject,event)
        sliderPositon = uint16(get(hObject,'Value'));
        
        updateImage();
    end

%% This function is the callback for running the "take Line measurement" routine.
    function takeLineMeasurementCallback(hObject, event)
        takeLineMeasurement()
        
    end

%% This function is the callback for running the "take measurement" routine.
    function takeMeasurementCallback(hObject, event)
        %takeMeasurement()
        takeMeasurement()
        
    end

    function takeMeasurementWithDistCallback(hObject, event)
        takeMeasurementWithDist()
        
    end

%% This function is the callback for running the water air calibration 
    function initWaterAirCalibCallback(hObject,event)
        waterAirCalibration();
    end

%% This function is the callback for running the standard calibration

    function initStandardCalibrationCallback(hObject,event)        
        standardCalibration();
    end

%% This function is indicating the Z slice we choose for Mark1 -- KV
    function setmark1(hObject,event)
        mark1 = sliderPositon;
        set(btn1, 'string', strcat('Mark1: ',num2str(sliderPositon)));
    end
%% This function is indicating the Z slice we choose for Mark2 -- KV
    function setmark2(hObject,event)
        mark2 = sliderPositon;
        set(btn2, 'string', strcat('Mark2: ',num2str(sliderPositon)));
    end

%% inserting the x and y cordinates for the first and second point we choose to indicate the radius
 %cordinates1 is the center of the of the standard at Mark1. cordinates2
 %is the outer border of the standard. cordinates3 below is the
 %center of the of the standard at Mark2. -- KV
    function getradiusCallback(hObject,event)
        radius_coordinates1 = ginput(1)
        radius_coordinates2 = ginput(1)
        X1 = radius_coordinates1(1);
        Y1 = radius_coordinates1(2);
       
        X2 = radius_coordinates2(1);
        Y2 = radius_coordinates2(2);
        radius = sqrt((X2-X1)^2 + (Y2-Y1)^2)
        set(getRadius, 'string', strcat('Radius: ',num2str(radius)));
        
    end

%% getting the pixel value from the ginput -- KV
    function getpoint(hObject,event)
        cordinates3 = ginput(1);
        xvalue = cordinates3(1)
        yvalue = cordinates3(2)
        set(mark2Center, 'string', strcat('X= ', num2str(xvalue), 'Y= ',num2str(yvalue)))
        
    end

%% initiaizes 3d im view
    function threeDimensionalAnalysisCallback(hObject,event)
       
        cd(firstDir)
        %Defines the values in which model is viewable
        pixelRangeX = 40;
        pixexlRangeZ = 80;
        
        %Asks user to select point from image
        selectionPoint = ginput(1);
        
        %Sets limit for image subsetx`
        xvalue = selectionPoint(1);
        yvalue = selectionPoint(2);
   
        xmin = xvalue - pixelRangeX
        xmax = xvalue + pixelRangeX
        
        ymin = yvalue - pixelRangeX
        ymax = yvalue + pixelRangeX
        
        zmin = sliderPositon
        zmax = sliderPositon + pixexlRangeZ
        
        %Seperates out subset of image set
        reducedMatrix = matrix(xmin:xmax,ymin:ymax,zmin:zmax);
        modelView(reducedMatrix)
        
    end

%%% callback for testing the threshholding funtion 
    function threshholdAnalysisCallback(hObject,event)
        standardThreshHoldInit();
        
    end


%% Calculation and Calibration Functions
%% Calibrate using Water / Air Standards. 
    function waterAirCalibration()
        
        cd(firstDir)
        CalibrationWithWater()
        
    end
   
    %% Calibration using HA-HDPE Samples. 
    %Allows the user to create a set of rescale intercept and rescale slope
    %pairs for later use. The user will enter the EXPECTED Hounsfield units
    %of each of the standards, manually locate each standard and create a
    %set of calibration curves using a guassian distribution. 
    function standardCalibration()
        
        cd(firstDir)
        CalibrationWithStandards()
        
    end

%% Takes measurement based on current dataset. Uses the rescale slope and
%rescale intercept written into the dicom file. 
     function takeMeasurement(hObject, event)
         
         cd(firstDir)
         singleROI
         
     end



%% Takes measurement based on current dataset, this function asks the user 
%to specify a csv file with sets of rescale intercept and rescale slope values. 
%This list can either be generated through the calibration function or can 
%be specificed by the user. This will end by generating a csv file with
%every calculated housnfeild unit from the average grayscale value based on
%supplied rs and ri values.
    function takeMeasurementWithDist()
            
            clear avgStruct
            pixel_reduc = 1;
            
            %Askes the user to specifc the location of the CSV file
            %containing the rescale slope and rescale intercept values.
            [dirname] = uigetdir('*.csv','Please choose CSV directory');
            cd(dirname)
            [filename] = uigetfile('*.csv','Please choose CSV directory');
            rs_ri_Vals = csvread(filename);
            
            %Structs containing information regarding all of the rescale
            %intercept and rescale values. 
            RS_Vals = rs_ri_Vals(1:end,1);
            RI_Vals = rs_ri_Vals(1:end,2);
            
            cd(firstDir)
            %ensures mark1 is before mark2
            if(mark1>mark2)
                tempVar = mark1;
                mark1=mark2;
                mark2 = tempVar;
            end
            
            count = int16(mark2-mark1);
            struct=[count];
            struct1=size(matrix);
            struct2 = [struct1(1), struct1(2)];
            m = 0;
            
            
            %Defines the number of pixels that will be displayed after
            %center of ROI is specified,
            viewLength=20;
            
            %Switches to first marked location.
            viewMark1()
            %Transformation for zoom
            CenterZoom = ginput(1);
            displayImageSubset(CenterZoom(1), CenterZoom(2),viewLength,1);
            CenterM1 = ginput(1);
            CenterM1(1) = CenterM1(1) + CenterZoom(1)-viewLength;
            CenterM1(2) = CenterM1(2) + CenterZoom(2)-viewLength;
            
            %Switches to second marked location.
            viewMark2()
            %Transformation for zoom
            CenterZoom = ginput(1);
            displayImageSubset(CenterZoom(1), CenterZoom(2),viewLength,2);
            CenterM2 = ginput(1);
            CenterM2(1) = CenterM2(1) + CenterZoom(1)-viewLength;
            CenterM2(2) = CenterM2(2) + CenterZoom(2)-viewLength;

            %Prompts the user for a radius for area of interest.
            radius = input('Please specify what radius you want to start with\n');
            
            %Calculates parameters for finding roi over each slice.
            deltay = double(CenterM2(2))-double(CenterM1(2))
            deltax = double(CenterM2(1))-double(CenterM1(1))
            deltaz = mark2 - mark1
            
            my = double(deltay)/double(deltaz)
            by = double(CenterM1(2)) -double(my)*double(mark1)
            
            mx = double(deltax)/double(deltaz)
            bx = double(CenterM1(1))- double(mx)*double(mark1)
            
            m = m+1;
            matrixSize = size(matrix);
            
            avgStruct = []  
    
            %This loop iterates over each speccified slice (between Mark 1
            %and Mark 2 inclusive) and calcuates the averageg grayscale
            %value of the area. 
            for slicenumber = mark1:mark2

                locationX = (double(slicenumber)*double(mx))+bx;
                locationY = (double(slicenumber)*double(my))+by;
                Center = [double(locationX), double(locationY)];
            
                %Uses difference slice depending on user selected view.
                %Takes a slice from the "matrix", provides x,y and R and
                %calculates the average of the area. 
                if viewType == 1                    
                    [avgValue,gsValues] = CircularAVG(squeeze(matrix(:,:,slicenumber)), radius, Center(2), Center(1),pixel_reduc);
                    avgStruct = [avgStruct, gsValues];
                    tempStruct = avgValue;

                elseif viewType == 2
                    [avgValue,gsValues] = CircularAVG(squeeze(matrix(:,slicenumber,:)), radius, Center(2), Center(1),pixel_reduc);
                    avgStruct = [avgStruct, gsValues];
                    tempStruct = avgValue;


                elseif viewType == 3
                    [avgValue,gsValues] = CircularAVG(squeeze(matrix(slicenumber,:,:)), radius, Center(2), Center(1),pixel_reduc);
                    avgStruct = [avgStruct, gsValues];
                    tempStruct = avgValue;
                end

                struct(slicenumber - mark1 + 1) = tempStruct;

            end

            %This struct contains the total number of average slice values.
            %
            totalAvgValues = [length(RS_Vals)];
            
            %This loop computes an equivelant hounsfeild unit for every
            %rescale intercept and rescale slope supplied. This loop uses
            %the parallel computing toolbox. The more cores your computer
            %has the faster it goes.
            avgGS = mean2(struct);

            %{
            parfor rs_value_index = 1:length(totalAvgValues)
            
               HUstruct = [];
               
               for structnumber = 1:length(struct)
                   
                   HUstruct(structnumber) = (RS_Vals(rs_value_index)*struct(structnumber))+RI_Vals(rs_value_index);
                    
               end

               totalAvgValues(rs_value_index) = mean2(HUstruct);

            end
            %}
            
            HUstruct = zeros(length(RS_Vals),length(gsValues));
            HUstruct = [];
            
            parfor rs_value_index = 1:length(RS_Vals)
           
               HUSubStruct = [length(gsValues)];
               for gsValue = 1:length(gsValues)
                   
                   HUSubStruct(gsValue) = (RS_Vals(rs_value_index)*gsValues(gsValue))+RI_Vals(rs_value_index);
                    
               end
               
               HUstruct  = [HUstruct,HUSubStruct];
            end
            
            totalAvgValues = HUstruct(:)
            plotfig = figure(5);
            figure(plotfig)

            totalAvgValues = totalAvgValues.';
            %{
            for k=length(totalAvgValues):-1:1
                if(totalAvgValues(k) < 0)
                    totalAvgValues(k) = [];
                end
            end
            meanStd = (mean2(totalAvgValues)+std(totalAvgValues));
            for k=length(totalAvgValues):-1:1
                if(totalAvgValues(k) > meanStd)
                    totalAvgValues(k) = [];
                end
            end
            %}
            cd(dirname)
            
            %Wites a csv file with all calcuated hounsfeild units. 
            dlmwrite('totalAvgValuestest.csv',totalAvgValues,'roffset',1,'coffset',0,'-append')

            x = 0:100:10000;
            hold on;
            h1 = histogram(totalAvgValues,x)
            xlabel('HU');
            ylabel('Count');
            title('Dist. of HU over Volume of Interest')
            avgStr = (strcat('Avg. HU: ', num2str(mean2(totalAvgValues))));
            stdStr = (strcat('Std. HU: ', num2str(std(double(totalAvgValues)))));
            if measurementCount == 1
                h = annotation('textbox',[0.58 0.65 0.1 0.1]);          
                set(h,'String',{avgStr,stdStr})
            elseif measurementCount ==2
                h = annotation('textbox',[0.68 0.75 0.1 0.1]);          
                set(h,'String',{avgStr,stdStr})
            else
                h = annotation('textbox',[0.78 0.85 0.1 0.1]);          
                set(h,'String',{avgStr,stdStr})
            end
            measurementCount = measurementCount + 1;
           
           %label2 = uicontrol('Style', 'text','Parent', plotfig, 'String', avgStr,'Position',[100 measurementCount*100 100 32]);
           %label1 = uicontrol('Style', 'text','Parent', plotfig, 'String', stdStr,'Position',[100 (measurementCount-1)*50+50 100 32]);
          
    end
%% This function updates slice based on slider value
    function updateImage()
        
        figure(f)
        if viewType == 1
            imshow(squeeze(matrix(:,:,sliderPositon)),[0 6000]);
            title(['Slice Number ' num2str(sliderPositon)])
            drawnow;   
        elseif viewType == 2
            imshow(squeeze(matrix(:,sliderPositon,:)),[0 6000]);
            title(['Slice Number ' num2str(sliderPositon)])
            drawnow;
        elseif viewType == 3
            imshow(squeeze(matrix(sliderPositon,:,:)),[0 6000]);
            title(['Slice Number ' num2str(sliderPositon)])
            drawnow;
        else
        end
        
    end

%% This function updates based on giving volume
    function displayImageSubset(x,y,viewLength,mark)
        if mark == 1
            n = mark1;
        else
            n = mark2;
        end
        
        figure(f)
        if viewType == 1
            vol = squeeze(matrix(:,:,n));
            imageSubset = vol(y-viewLength:y+viewLength, x-viewLength:x+viewLength);
            noisereduc = imgaussfilt(imageSubset, 1);
            imshow(imageSubset,[]);
            drawnow;   
        elseif viewType == 2
            vol = squeeze(matrix(:,n,:));
            imageSubset = vol(y-viewLength:y+viewLength, x-viewLength:x+viewLength);
            noisereduc = imgaussfilt(imageSubset, 1);
            imshow(imageSubset,[]);
            drawnow;
        elseif viewType == 3
            vol = squeeze(matrix(n,:,:));
            imageSubset = vol(y-viewLength:y+viewLength, x-viewLength:x+viewLength);
            %noisereduc = imgaussfilt(imageSubset, 1);
            imshow(imageSubset,[]);
            drawnow;
        else
        end

    end


%%This function intializes standard threshholding analysis
    function standardThreshHoldInit()
        cd(firstDir)
        if viewType == 1
            standardThreshHold(squeeze(matrix(:,:,sliderPositon)));
        elseif viewType == 2
            standardThreshHold(squeeze(matrix(:,sliderPositon,:)));
        elseif viewType == 3
            standardThreshHold(squeeze(matrix(sliderPositon,:,:)));
        else
        end
    end

%% This function is used to view mark 1 when specific radius in calibration -- EL
    function viewMark1()
        n = mark1;
        if viewType == 1
            imshow(squeeze(matrix(:,:,n)),[]);
        elseif viewType == 2
            imshow(squeeze(matrix(:,n,:)),[]);
        elseif viewType == 3
            imshow(squeeze(matrix(n,:,:)),[]);
        end
        title(['Slice Number ' num2str(sliderPositon)])
        drawnow;
    end

%% This function is used to view mark 2 when specific radius in calibration -- EL
    function viewMark2()
        n = mark2;
        if viewType == 1
            imshow(squeeze(matrix(:,:,n)),[]);
        elseif viewType == 2
            imshow(squeeze(matrix(:,n,:)),[]);
        elseif viewType == 3
            imshow(squeeze(matrix(n,:,:)),[]);
        end
        title(['Slice Number ' num2str(sliderPositon)])
        drawnow;
    end



%% This function allows the user to switch the view between the calibrated and uncalibrated set of Dicome Files
    function switchImageSetStandardCal()
        cd(firstDir)
        [dirname]=uigetdir('Please choose dicom directory');
        filetype = questdlg('Have you used this set of DiCOM files before?', 'Choose One', 'Yes', 'No', 'Cancel');
        switch filetype
            case 'Yes'
                dataset = 2;
            case 'No'
                dataset = 1; 
        end

        if dataset == 1
            matrix = Generate3dMatrixCBCT(dirname);
            cd(dirname)
            save('PVmatrix.mat','matrix')
            save('ginfo.mat','ginfo1')
        elseif dataset == 2
            cd(dirname)
            load('PVmatrix.mat')
            load('ginfo.mat')

        end
        updateImage()
       
    end


%% UI Elements
f=figure(1);

%Slider to adjust view position.
slider = uicontrol('Parent',f,'Style','slider','Position',[81,390,420,40],'min',0, 'max',size(matrix,2), 'SliderStep', [1/size(matrix,2) 0.5]);

btn1 = uicontrol('Style', 'pushbutton', 'String', 'Mark 1','Position', [81,110,210,40],'Callback', @(hObject, event) setmark1(hObject, event));
btn2 = uicontrol('Style', 'pushbutton', 'String', 'Mark 2','Position', [291,110,210,40],'Callback', @(hObject, event) setmark2(hObject, event));

%View Switcher Buttons
viewSwitchAxial = uicontrol('Style', 'pushbutton', 'String', 'Axial View','Position', [81,350,140,40], 'Callback', @(hObject, event) switchViewAxialCallback(hObject, event));
viewSwitchSagittal = uicontrol('Style', 'pushbutton', 'String', 'Sagittal View','Position', [221,350,140,40], 'Callback', @(hObject, event) switchViewSagittalCallback(hObject, event));
viewSwitchCoronal = uicontrol('Style', 'pushbutton', 'String', 'Coronal View','Position', [361,350,140,40], 'Callback', @(hObject, event) switchViewCoronalCallback(hObject, event));

%Calibration Buttons
calibrateUsingAirAndWater = uicontrol('Style', 'pushbutton', 'String', ' Calibrate using Air and Water','Position', [81,310,210,40], 'Callback', @(hObject, event) initWaterAirCalibCallback(hObject, event));
calibrateUsingStandards = uicontrol('Style', 'pushbutton', 'String', 'Calibrate using Standards','Position', [291,310,210,40], 'Callback', @(hObject, event) initStandardCalibrationCallback(hObject, event));


uicontrol('Style', 'pushbutton', 'String', 'Hounsfield Unit Measurement','Position', [81,30,420,40],'Callback', @(hObject, event) takeMeasurementWithDistCallback(hObject, event));
uicontrol('Style', 'pushbutton', 'String', 'Grayscale Line Measurement','Position', [501,30,420,40],'Callback', @(hObject, event) takeLineMeasurementCallback(hObject, event));
%uicontrol('Style', 'pushbutton', 'String', 'Take Measurement','Position', [511,14,420,40],'Callback', @(hObject, event) takeMeasurementCallback(hObject, event));

initRun = uicontrol('Style', 'pushbutton', 'String', 'Grayscale Value Measurement','Position', [81,70,420,40],'Callback', @(hObject, event) takeMeasurement(hObject, event));
switchView = uicontrol('Style', 'pushbutton', 'String', 'Threshhold Test','Position', [81,150,420,40],'Callback', @(hObject, event) threshholdAnalysisCallback(hObject, event));

imageSetChange = uicontrol('Style', 'pushbutton', 'String', 'Change Image Set','Position', [81,270,420,40],'Callback', @(hObject, event) switchImageSetStandardCal());
getRadius = uicontrol('Style', 'pushbutton', 'String', 'Radius','Position', [81,230,420,40],'Callback', @(hObject, event) getradiusCallback(hObject, event));
mark2Center = uicontrol('Style', 'pushbutton', 'String', 'Select Pixel', 'Position', [81, 190, 420, 40], 'Callback', @(hObject, event) getpoint(hObject, event));

addlistener(slider,'ContinuousValueChange',@(hObject, event) updateImageCallback(hObject, event));

%dialogBox = ('Style', 
%display%
ax1=axes('parent',f,'position',[0.2 0.1 0.8 0.8]);
set(gcf, 'units', 'normalized', 'outerposition', [0 0 1 1]);
imshow(squeeze(matrix(:,:,n)),[]);

end
