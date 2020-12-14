function [CenterM1, CenterM2, radius] = getVOI()


%runType variable: 1 = Water/Air Calibration; 2 = Standard Calibration, 
% 3 =
%

global mark1
global mark2
global viewType
global matrix
global sliderPositon

viewLength = 20;
f = figure(1);

%%
    
    viewMark1(); %This subfunction is called at the end of this file
    CenterZoom = ginput(1);
    displayImageSubset(CenterZoom(1), CenterZoom(2),viewLength,1);
    CenterM1 = ginput(1);
    %msgbox(sprintf('Please indicate the center point of the ROI. then press the Enter key in the command window'))
    %Pixel correction for X Y location selection 
    CenterM1(1) = CenterM1(1) + CenterZoom(1)-viewLength;
    CenterM1(2) = CenterM1(2) + CenterZoom(2)-viewLength;

    %Switches between first and last slice, allowing using to
    %select center of stanadard ROI. Prompts user for center of ROI
    %after slice has been displayed.
    viewMark2()
    CenterZoom = ginput(1);
    displayImageSubset(CenterZoom(1), CenterZoom(2),viewLength,2);
    CenterM2 = ginput(1);

    %Pixel correction for X Y location selection 
    CenterM2(1) = CenterM2(1) + CenterZoom(1)-viewLength;
    CenterM2(2) = CenterM2(2) + CenterZoom(2)-viewLength;

    %Prompts user to enter radius to be used for RoI
    radius = input('Please specify what radius in pixels you would like to use for this ROI\n');



%%
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
            %noisereduc = imgaussfilt(imageSubset, 1);
            imshow(imageSubset,[]);
            drawnow;   
        elseif viewType == 2
            vol = squeeze(matrix(:,n,:));
            imageSubset = vol(y-viewLength:y+viewLength, x-viewLength:x+viewLength);
            %noisereduc = imgaussfilt(imageSubset, 1);
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
%%
    function viewMark1()
        figure(f)
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
%%
    function viewMark2()
        figure(f)
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

end