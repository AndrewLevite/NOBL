%% Takes measurement based on current dataset. Uses the rescale slope and
%rescale intercept written into the dicom file. 
    function [] = singleROI()
    
            global firstDir
            global mark1
            global mark2
            global viewType
            global matrix
            cd(firstDir)
            
            msgbox(sprintf('Please indicate Mark1 and Mark2 of your region of interest, then press the Enter key in the command window.'))
            pause
            
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
            
            [CenterM1, CenterM2, radius] = getVOI();
%             This next section is commented out but can be used to
%             evaluate multiple radii within a region of interest
%             prompt = {'Number of radii to evaluate:','Starting radius:','Ending Radius:'};
%                 windowtitle = 'Evaluation parameters';
%                 dims = [1 50];
%                 definput = {'1','5','N/A'};
%                 answer = inputdlg(prompt,windowtitle,dims,definput);
%             numbofradi = str2num(answer{1});
%             firstradius = str2num(answer{2});
%             lastradius = str2num(answer{3});
%             if ~isempty(lastradius)
%                 delta = (lastradius - firstradius)/numbofradi;
%                 radius = zeros(((lastradius-firstradius)/delta)+1,1);
%                 tempradius = firstradius;
%                 for i = 1:length(radius)
%                     radius(i) = tempradius; 
%                     tempradius = tempradius + delta;
%                 end
%             else
%                 radius = firstradius;
%             end            
            %Computes proper transforms for each slice. Simply y = mx+b
            %from center of mark 1 to center of mark 2.
            deltay = double(CenterM2(2))-double(CenterM1(2))
            deltax = double(CenterM2(1))-double(CenterM1(1))
            deltaz = mark2 - mark1
            
            my = double(deltay)/double(deltaz)
            by = double(CenterM1(2)) -double(my)*double(mark1)
            
            mx = double(deltax)/double(deltaz)
            bx = double(CenterM1(1))- double(mx)*double(mark1)
            
            m = m+1;
            matrixSize = size(matrix);
            
            %Stores every value calculated from ROI within radius.
            %(Excludes 0 value pixels)
            GSVstring = [];
            
            %Organizes strings by slice
            GSVmatrix = []; 
            
            %Iterates over each slice finding the average value of
            %grayscale value value depending on user specificied view.
            for slicenumber = mark1:mark2

                locationX = (double(slicenumber)*double(mx))+bx;
                locationY = (double(slicenumber)*double(my))+by;
                Center = [double(locationX), double(locationY)];

                %Uses difference slice depending on user selected view.
                %Takes a slice from the "matrix", provides x,y and R and
                %calculates the average of the area.   
                if viewType == 1
                    
                    filterraw = squeeze(matrix(:,:,slicenumber));
                    %filterimg = wiener2(filterraw);
                    %filterimg = medfilt2(filterraw);
                    
                    [gsValues] = CircularAVG(filterraw, radius, Center(2), Center(1));
                    
                    %figure(10);
                    %imshowpair(filterraw,filterimg,'montage')
                    
                    GSVstring = [GSVstring, gsValues];
                    GSVmatrix{slicenumber-mark1+1,1} = gsValues;
                    
                elseif viewType == 2
                    
                    filterraw = squeeze(matrix(:,slicenumber,:));
                    %filterimg = wiener2(squeeze(matrix(:,slicenumber,:)));
                    %filterimg = medfilter2(filterraw);
                    %figure(10);
                    %imshowpair(filterraw,filterimg,'montage')
                    
                    
                    [gsValues] = CircularAVG(filterraw, radius, Center(2), Center(1));
                    
                   
                    GSVstring = [GSVstring, gsValues];
                    GSVmatrix{slicenumber-mark1+1,1} = gsValues;
                    
                elseif viewType == 3
                    filterraw = squeeze(matrix(slicenumber,:,:));
                    %filterimg = wiener2(squeeze(matrix(slicenumber,:,:)));
                    %filterimg = medfilter2(filterraw);
                    
                    [gsValues] = CircularAVG(filterraw, radius, Center(2), Center(1));
                    
                    %figure(10);
                    %imshowpair(filterraw,filterimg,'montage')
                    
                    GSVstring = [GSVstring, gsValues];
                    GSVmatrix{slicenumber-mark1+1,1} = gsValues;
                    
                end
                
                
                
            end
          
            
            
           
           totalAverage = VOIaverage(GSVmatrix);

           totalValue = GSVstring;
            
           STD = std(double(GSVstring));
           
           filename = ('VOI.csv');
           writetable(cell2table(GSVmatrix), filename, 'writevariablenames', false)
      
            
            HUs = [];
            for structnumber = 1:length(struct)
                rescaleint(structnumber)= ginfo1{structnumber-1+mark1}.RescaleIntercept;
                
                rescaleslope(structnumber)= ginfo1{structnumber-1+mark1}.RescaleSlope;
                
                struct = double(struct);
                HUstruct(structnumber) = (rescaleslope(structnumber)*struct(structnumber))+rescaleint(structnumber);
            end
           
            
            
            for i = 1:length(avgStruct)
                tempHUs(i) = (rescaleslope(structnumber)*avgStruct(i))+rescaleint(structnumber);
            end
            HUs = [HUs tempHUs];
        
            %Plots data showing dist. of grayscale values. 
            plotfig = figure(3);
            figure(plotfig)
            subplot(2,1,1)
            h = histogram(avgStruct)
            h.BinEdges = [0:min(avgStruct)+range(avgStruct)+1000];
            h.NumBins = 100;
            axis tight
            title('Dist. of Grayscale over Volume of Interest')
            avgStr = (strcat('Avg. GSV: ', num2str(mean2(avgStruct))));
            stdStr = (strcat('Std. GSV: ', num2str(std(double(avgStruct)))));
            h = annotation('textbox',[0.58 0.75 0.1 0.1]);          
            set(h,'String',{avgStr,stdStr});
            subplot(2,1,2)
            % Plots data showing distribution of HU values.
            HUs = HUs';
            h1 = histogram(HUs)
            h1.BinEdges = [0:min(HUs)+range(HUs)+1000];
            h1.NumBins = 100;
            axis tight
            title('Dist. of HU over Volume of Interest')
            
            
            %Transforms each grayscale value based on rescale slope and
            %rescale intercept of written into the dicom file.
      
            
           rangeofGSV = range(struct);
           rangeofHU = range(HUstruct);
           xaxis = mark2-mark1+2;

           %Flips axis based on ranges of HU and GS values. 
           if rangeofGSV>rangeofHU
               yaxismax = round(min(struct)+(rangeofGSV+(.5*rangeofGSV)));
               yaxismin = round(min(struct)-(.5*rangeofGSV));
               plotaxis = 1;
               axis([-1 150 yaxismin yaxismax])
           elseif rangeofGSV<rangeofHU
               plotaxis = 0;
               yaxismax = round(min(struct)+(rangeofHU+(.5*rangeofHU)));
               yaxismin = round(min(struct)-(.5*rangeofHU));
               axis([-1 150 yaxismin yaxismax])
           end 
           
           % For analyzing HU as a function of slice number:
%            plot(HUstruct);
%            title('Avg HU Units versus Slice Number')
%            xlabel('Number of Slices')
%            ylabel('PV in HU')

           sixstruct = int16(struct);
           sixstruct = sixstruct +32767;
           total(m) = mean2(sixstruct)
           totalAverage(m) = mean2(struct)
           STD(m) = std(HUstruct)
           HU(m) = mean2(HUstruct)
           
           
           avgStr = (strcat('Avg. HU: ', string(mean2(HUs))))
           stdStr = (strcat('Std. HU: ',string(std(double(avgStruct)))))
           
           plotfig = figure(4);
            figure(plotfig)
            p = polyfit([1:1:length(struct)],struct,2)
            poly = polyval(p,[1:1:length(struct)]); 
            plot([1:1:length(struct)],struct);
            hold on;
            plot([1:1:length(struct)],poly)
            ylim([-500 1500])
            title('Slice # Vs Grayscale Value')
            xlabel('Slice #')
           
%            label2 = uicontrol('Style', 'text','Parent', plotfig, 'String', avgStr,'Position',[100 100 100 32]);
%            label1 = uicontrol('Style', 'text','Parent', plotfig, 'String', stdStr,'Position',[100 50 100 32]);

    end