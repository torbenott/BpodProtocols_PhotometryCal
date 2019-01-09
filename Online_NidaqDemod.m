function [NidaqDemod, NidaqRaw]=Online_NidaqDemod(rawData,refData,modFreq,modAmp,StateToZero)
global BpodSystem TaskParameters

decimateFactor=TaskParameters.GUI.DecimateFactor;
duration=TaskParameters.GUI.NidaqDuration;
sampleRate=TaskParameters.GUI.NidaqSamplingRate;
baseline_begin=TaskParameters.GUI.BaselineBegin;
baseline_end=TaskParameters.GUI.BaselineEnd;
lowCutoff=15;
pad=1;
if TaskParameters.GUI.Modulation
%% Prepare reference data and generates 90deg shifted ref data
refData             = refData(1:length(rawData),1);   % adjust length of refData to rawData
refData             = refData-mean(refData);          % suppress DC offset
samplesPerPeriod    = (1/modFreq)/(1/sampleRate);
quarterPeriod       = round(samplesPerPeriod/4);
refData90           = circshift(refData,[1 quarterPeriod]);

%% Quadrature decoding and filtering
processedData_0     = rawData .* refData;
processedData_90    = rawData .* refData90;

%% Filter
    lowCutoff = lowCutoff/(sampleRate/2); % normalized CutOff by half SampRate (see doc)
    [b, a] = butter(5, lowCutoff, 'low'); 
    % pad the data to suppress windows effect upon filtering
    if pad == 1
        paddedData_0        = processedData_0(1:sampleRate, 1);
        paddedData_90       = processedData_90(1:sampleRate, 1);
        demodDataFilt_0     = filtfilt(b,a,[paddedData_0; processedData_0]);
        demodDataFilt_90    = filtfilt(b,a,[paddedData_90; processedData_90]);        
        processedData_0     = demodDataFilt_0(sampleRate + 1: end, 1);
        processedData_90    = demodDataFilt_90(sampleRate + 1: end, 1);
    else
        processedData_0     = filtfilt(b,a,processedData_0);
        processedData_90    = filtfilt(b,a,processedData_90); 
    end
    
demodData = (processedData_0 .^2 + processedData_90 .^2) .^(1/2);

%% Correct for amplitude of reference
demodData=demodData*2/modAmp;
else
    demodData=rawData;
end
%% Expeced Data set
SampRate=sampleRate/decimateFactor;
ExpectedSize=duration*SampRate;
Data=NaN(ExpectedSize,1);
TempData=decimate(demodData,decimateFactor);
Data(1:length(TempData))=TempData;

%% DF/F calculation
Fbaseline=mean(Data(baseline_begin*SampRate:baseline_end*SampRate));
DFF=100*(Data-Fbaseline)/Fbaseline;

%% Time
Time=linspace(0,duration,ExpectedSize);
TimeToZero=BpodSystem.Data.RawEvents.Trial{1,end}.States.(StateToZero)(1,1);
Time=Time'-TimeToZero;

%% Raw Data
ExpectedSizeRaw=duration*sampleRate;
DataRaw=NaN(ExpectedSizeRaw,1);
DataRaw(1:length(rawData))=rawData;

TimeRaw=linspace(0,duration,ExpectedSizeRaw);
TimeRaw=TimeRaw'-TimeToZero;
%% NewDataSet
NidaqDemod(:,1)=Time;
NidaqDemod(:,2)=Data;
NidaqDemod(:,3)=DFF;

NidaqRaw(:,1)=TimeRaw;
NidaqRaw(:,2)=DataRaw;
end