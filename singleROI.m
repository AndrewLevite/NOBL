%% Takes measurement based on current dataset. Uses the rescale slope and
%rescale intercept written into the dicom file. 
    function [] = singleROI()
    
            global firstDir
            global mark1
            global mark2
            global viewType
            global matrix
            global ginfo1
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
            GSVstring=[count];
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
            
           STD = std(double(GSVstring));
           
           filename = ('VOI.csv');
           writetable(cell2table(GSVmatrix), filename, 'writevariablenames', false)
           
           rescaleint = ginfo1{1}.RescaleIntercept;
                
           rescaleslope= ginfo1{1}.RescaleSlope;
            
           
           
               
                
            GSVstring = double(GSVstring);
                
          
            HUs = GSVstring.*rescaleslope+rescaleint;
       
           
            %Plots data showing dist. of grayscale values. 
            plotfig = figure(3);
            figure(plotfig)
            subplot(2,1,1)
            h = histogram(GSVstring)
            h.BinEdges = [0:min(GSVstring)+range(GSVstring)+1000];
            h.NumBins = 100;
            axis tight
            title('Dist. of Grayscale over Volume of Interest')
            avgStr = (strcat('Avg. GSV: ', num2str(mean2(GSVstring))));
            stdStr = (strcat('Std. GSV: ', num2str(std(double(GSVstring)))));
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
            
            avgStr = (strcat('Avg. HU: ', num2str(mean2(HUs))));
            stdStr = (strcat('Std. HU: ', num2str(std(double(HUs)))));
            h = annotation('textbox',[0.58 0.25 0.1 0.1]);          
            set(h,'String',{avgStr,stdStr});
            
            
            %Transforms each grayscale value based on rescale slope and
            %rescale intercept of written into the dicom file.
      
            
           rangeofGSV = range(GSVstring);
           rangeofHU = range(HUs);
           xaxis = mark2-mark1+2;

           %Flips axis based on ranges of HU and GS values. 
           if rangeofGSV>rangeofHU
               yaxismax = round(min(GSVstring)+(rangeofGSV+(.5*rangeofGSV)));
               yaxismin = round(min(GSVstring)-(.5*rangeofGSV));
               plotaxis = 1;
               axis([-1 150 yaxismin yaxismax])
           elseif rangeofGSV<rangeofHU
               plotaxis = 0;
               yaxismax = round(min(GSVstring)+(rangeofHU+(.5*rangeofHU)));
               yaxismin = round(min(GSVstring)-(.5*rangeofHU));
               axis([-1 150 yaxismin yaxismax])
           end 
           
           % For analyzing HU as a function of slice number:
%            plot(HUstruct);
%            title('Avg HU Units versus Slice Number')
%            xlabel('Number of Slices')
%            ylabel('PV in HU')

           
           avgStr = (strcat('Avg. GSV: ', num2str(mean2(GSVstring))))
           stdStr = (strcat('Std. GSV: ', num2str(std(double(GSVstring)))))
           avgStr = (strcat('Avg. HU: ', num2str(mean2(HUs))))
           stdStr = (strcat('Std. HU: ', num2str(std(double(HUs)))))
           
%            label2 = uicontrol('Style', 'text','Parent', plotfig, 'String', avgStr,'Position',[100 100 100 32]);
%            label1 = uicontrol('Style', 'text','Parent', plotfig, 'String', stdStr,'Position',[100 50 100 32]);
    end