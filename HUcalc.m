%Outputs expected HU of HA-HDPE standards or composition from wanted HU. 
%Can also determine theoretical density of standards with a known concentration 

function HUs = HUcalc(keV)

%keV = input('Enter the effective energy of the scanner in keV \n');

%Known variables: DHAp = density of HA particles, DHA = Density of HA
%within particles, Dair = density of air (also within particles, DHDPE =
%density of HDPE [g/cm^3]

DHAp = 1.67;
DHA = 3.1;
Dair = 0.001225;
DHDPE = 0.97;
DLeadNitrate = 4.53;


while keV ~= 20 && keV ~= 25.2 && keV ~= 31 && keV ~= 40 && keV ~= 50 && keV ~= 70 && keV ~= 80
    
    disp('invalid input')
    keV = input('Enter the effective energy of the scanner in keV (20/25.2/31/40/50/70/80) \n');
    
end

%Attenuation coefficients: Linear = [cm^-1], mass = [cm^2/g]
%Mass attenuation coefficients are gathered from the NIST website
%http://physics.nist.gov/PhysRefData/Xcom/html/xcom1.html
%Mass attenuation is multiplied by density to obtain linear coefficient

if keV == 20
    
    massuair = 0.7057;
    massuHA = 6.32;
    massuHDPE = 0.3751;
    massuLN = 52.84;
    massuwater = 0.7213;
    
elseif keV == 25.2
    
    massuair = 0.4234;
    massuHA = 3.235;
    massuHDPE = 0.2788;
    massuLN = 28.78;
    massuwater = 0.4386;
    
elseif keV == 31
    
    massuair = 0.2979;
    massuHA = 1.798;
    massuHDPE = 0.2364;
    massuLN = 16.7;
    massuwater = 0.314;
    
elseif keV == 40
    
    massuair = 0.2247;
    massuHA = 0.9068;
    massuHDPE = 0.2097;
    massuLN = 8.49;
    massuwater = 0.2395;
    
elseif keV == 50
    
    massuair = 0.1914;
    massuLN = 4.692;
    massuHDPE = 0.1965;
    massuHA = 0.5309;
    massuwater = 0.2076;
    
elseif keV == 70
    
    massuair = 0.1656;
    massuLN = 1.94;
    massuHDPE = 0.1824;
    massuHA = 0.282;
    massuwater = 0.1824;
    
elseif keV == 80
    
    massuair = 0.1589;    
    massuHA = 0.2345;   
    massuHDPE = 0.1773;    
    massuLN = 1.38;
    massuwater = 0.1755;
    
end

linearuwater = massuwater;
linearuair = massuair * Dair;


    
    %Asks for concentrations of HA in standards and assigns sizes to
    %variables of interest.
    %M = mass [g], V = volume [cm^3], D = density [g/cm^3]
    %MHAp = input('enter the range of mass percentages of HAp\n');
    MHAp = 0:0.1:1;
    size = length(MHAp);
    MHA = zeros(1, size);
    Mair = zeros(1, size);
    MHDPE = zeros(1, size);
    
    VHAp = zeros(1, size);
    VHA = zeros(1, size);
    Vair = zeros(1, size);
    VHDPE = zeros(1, size);
    Vtot = zeros(1, size);
    
    DHAsoln = zeros(1, size);
    DHDPEsoln = zeros(1, size);
    Dairsoln = zeros(1, size);
    
    linearu = zeros(1, size);
    HU = zeros(1, size);
    
    %For each given composition of HAp (assuming 1 gram total), calculates 
    %volume and mass of HA and air in the HA particles. Then calculates 
    %the mass and volume of HDPE for each, as well as a total volume.
    %Next, it calculates the relative density of HA, HDPE, and air with
    %respect to the entire standard by dividing the mass of the component
    %of interest by the total volume. These relative densities are
    %multiplied by the known mass attenuation coefficients of each
    %component and the products are added together to obtain the linear
    %attenuation coefficient of each standard. The coefficient is then used
    %to find HU
    for i = 1:size
        
        VHAp(i) = MHAp(i) / DHAp;
        VHA(i) = (MHAp(i) - (Dair*VHAp(i))) / (DHA - Dair);
        Vair(i) = VHAp(i) - VHA(i);
        MHA(i) = DHA * VHA(i);
        Mair(i) = Dair * Vair(i);
        MHDPE(i) = 1 - MHAp(i);
        VHDPE(i) = MHDPE(i) / DHDPE;
        Vtot(i) = VHA(i) + Vair(i) + VHDPE(i) ;
        DHAsoln(i) = MHA(i) / Vtot(i);
        DHDPEsoln(i) = MHDPE(i) / Vtot(i);
        Dairsoln(i) = Mair(i) / Vtot(i);
        linearu(i) = (massuHA * DHAsoln(i)) + (massuHDPE * DHDPEsoln(i)) + (massuair * Dairsoln(i));
        HU(i) = 1000 * (linearu(i) - linearuwater) / (linearuwater - linearuair) ;
        
    end
    
    %Plots a graph of the theoretical HU values vs. the composition of HAp
    %for each standard
    figure(2)
    plot(MHAp, HU, 'o')
    hold on
    title(['HU vs. mass percent HA at ' num2str(keV) ' keV'])
    xlabel('mass percent HA')
    ylabel('HU')
    %Asigns a fit to the graph. Can change to linear, quadratic, cubic, or
    %exponential.
    %p = polyfit(MHAp, HU, 1);
    p = polyfit(MHAp, HU, 2);
    %p = polyfit(MHAp, HU, 3);
    f1 = polyval(p, MHAp);
    plot(MHAp, f1, '-')
    %legend('HU', ['y = ' num2str(p(1)) 'x + ' num2str(p(2))], 'Location', 'northwest')
    legend('HU', ['y = ' num2str(p(1)) 'x^2 + ' num2str(p(2)) 'x + ' num2str(p(3))], 'Location', 'northwest')
    %legend('HU', ['y = ' num2str(p(1)) 'x^3 + ' num2str(p(2)) 'x^2 + ' num2str(p(3)) 'x + ' num2str(p(4))], 'Location', 'northwest')
    %MHAp = MHAp';
    %HU = HU';
    %p2 = fit(MHAp, HU, 'exp2');
    %plot(p2, MHAp, HU);
    
    %Uses the fit to get desired HU values from composition of standards 
    %that were used.
    
    prompt = {'HA mass fraction standard 1:','Standard 2:','Standard 3:'};
                windowtitle = 'Enter HA mass fraction';
                dims = [1 50];
                definput = {'0.2','0.3','0.4'};
                answer = inputdlg(prompt,windowtitle,dims,definput);
            HA(1) = str2num(answer{1});
            HA(2) = str2num(answer{2});
            HA(3) = str2num(answer{3});
    
    for i = 1:length(HA)
        HUstring(i) = p(1) * (HA(i)^2) + p(2) * HA(i) + p(3);
    end
HUs = HUstring;
end



