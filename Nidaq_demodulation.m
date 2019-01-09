function demodData=Nidaq_demodulation(rawData,sampleRate,modFreq,lowCutoff)
% Demodulate an AM-modulated input ('rawData') in quadrature given a
% reference ('refData'). 'LowCutOff' is a corner frequency for 5-pole
% butterworth lowpass filter.

if nargin<5
    lowCutoff=[];
end

%% Prepare reference data and generates 90deg shifted ref data
refData             = Nidaq_modulation(S.LED1_amp,modFreq);
refData             = refData(1:length(rawData),1);   % adjust length of refData to rawData
refData             = refData-mean(refData);          % suppress DC offset
samplesPerPeriod    = (1/modFreq)/(1/sampleRate);
quarterPeriod       = round(samplesPerPeriod/4);
refData90           = circshift(refData,[1 quarterPeriod]);

%% Quadrature decoding
processedData_0     = rawData .* refData;
processedData_90    = rawData .* refData90;
demodData = (processedData_0 .^2 + processedData_90 .^2) .^(1/2);

%% Filter
if lowCutoff
    lowCutoff = lowCutoff/(sampleRate/2); % normalized CutOff by half SampRate (see doc)
    [b, a] = butter(5, lowCutoff, 'low'); 
    % pad the data to suppress windows effect upon filtering
    pad = 1;
    if pad
        paddedData      = demodData(randperm(sampleRate), 1);
        demodDataFilt	= filtfilt(b,a,[paddedData; demodData]);        
        demodData       = demodDataFilt(sampleRate + 1: end, 1);
    else
        demodData       = filtfilt(b, a, demodData);
    end
end

end