function PhotometryCal()
% Learning to Nose Poke side ports

global BpodSystem
global TaskParameters
global nidaq

%% Task parameters
TaskParameters = BpodSystem.ProtocolSettings;
if isempty(fieldnames(TaskParameters))
    
    %general
    TaskParameters.GUI.T = 4; % (s)
    TaskParameters.GUIPanels.General = {'T'};
    
    %photometry
    TaskParameters.GUI.Photometry=1;
    TaskParameters.GUIMeta.Photometry.Style='checkbox';
    TaskParameters.GUI.DbleFibers=0;
    TaskParameters.GUIMeta.DbleFibers.Style='checkbox';
    TaskParameters.GUIMeta.DbleFibers.String='Auto';
    TaskParameters.GUI.Isobestic405=0;
    TaskParameters.GUIMeta.Isobestic405.Style='checkbox';
    TaskParameters.GUIMeta.Isobestic405.String='Auto';
    TaskParameters.GUI.RedChannel=1;
    TaskParameters.GUIMeta.RedChannel.Style='checkbox';
    TaskParameters.GUIMeta.RedChannel.String='Auto';    
    TaskParameters.GUIPanels.Recording={'Photometry','DbleFibers','Isobestic405','RedChannel'};
    
    %plot photometry
    TaskParameters.GUI.TimeMin=-4;
    TaskParameters.GUI.TimeMax=4;
    TaskParameters.GUI.NidaqMin=-5;
    TaskParameters.GUI.NidaqMax=10;
    TaskParameters.GUI.StateToZero=1;
	TaskParameters.GUIMeta.StateToZero.Style='popupmenu';
    TaskParameters.GUIMeta.StateToZero.String={'ITI'};
    TaskParameters.GUI.BaselineBegin=0.1;
    TaskParameters.GUI.BaselineEnd=1.1;
    TaskParameters.GUIPanels.Plot={'TimeMin','TimeMax','NidaqMin','NidaqMax','StateToZero','BaselineBegin','BaselineEnd'};
    
    %% Nidaq and Photometry
    TaskParameters.GUI.PhotometryVersion=1;
    TaskParameters.GUI.Modulation=1;
    TaskParameters.GUIMeta.Modulation.Style='checkbox';
    TaskParameters.GUIMeta.Modulation.String='Auto';
	TaskParameters.GUI.NidaqDuration=4;
    TaskParameters.GUI.NidaqSamplingRate=6100;
    TaskParameters.GUI.DecimateFactor=610;
    TaskParameters.GUI.LED1_Name='Fiber1 470-A1';
    TaskParameters.GUI.LED1_Amp=2;
    TaskParameters.GUI.LED1_Freq=211;
    TaskParameters.GUI.LED2_Name='Fiber1 405 / 565';
    TaskParameters.GUI.LED2_Amp=2;
    TaskParameters.GUI.LED2_Freq=531;
    TaskParameters.GUI.LED1b_Name='Fiber2 470-mPFC';
    TaskParameters.GUI.LED1b_Amp=2;
    TaskParameters.GUI.LED1b_Freq=531;

    TaskParameters.GUIPanels.Photometry={'PhotometryVersion','Modulation','NidaqDuration',...
                            'NidaqSamplingRate','DecimateFactor',...
                            'LED1_Name','LED1_Amp','LED1_Freq',...
                            'LED2_Name','LED2_Amp','LED2_Freq',...
                            'LED1b_Name','LED1b_Amp','LED1b_Freq'};
                        
    %% rig-specific
        TaskParameters.GUI.nidaqDev='Dev2';
        
        TaskParameters.GUIPanels.PhotometryRig={'nidaqDev'};
    
    TaskParameters.GUI = orderfields(TaskParameters.GUI);

end   
BpodParameterGUI('init', TaskParameters);


%% Initialize plots
BpodSystem.ProtocolFigures.SideOutcomePlotFig = figure('name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.OutcomePlot.HandleOutcome = axes('Position',    [  .055            .15 .91 .3]);
PhotometryCal_PlotSideOutcome(BpodSystem.GUIHandles.OutcomePlot,'init');

%% NIDAQ Initialization and Plots

if (TaskParameters.GUI.DbleFibers+TaskParameters.GUI.Isobestic405+TaskParameters.GUI.RedChannel)*TaskParameters.GUI.Photometry >1
    disp('Error - Incorrect photometry recording parameters')
    return
end

Nidaq_photometry('ini');

FigNidaq1=Online_NidaqPlot('ini','470');
if TaskParameters.GUI.DbleFibers || TaskParameters.GUI.Isobestic405 || TaskParameters.GUI.RedChannel
    FigNidaq2=Online_NidaqPlot('ini','channel2');
end


%% Main loop
RunSession = true;
iTrial = 1;

while RunSession
    
    BpodSystem.Data.TrialTypes(iTrial)=1;
    
    TaskParameters = BpodParameterGUI('sync', TaskParameters);
    
    sma = stateMatrix(iTrial);
    SendStateMatrix(sma);
    
    %% NIDAQ Get nidaq ready to start
    Nidaq_photometry('WaitToStart');
    
    %% Run Trial
    RawEvents = RunStateMatrix;
    
    %% NIDAQ Stop acquisition and save data in bpod structure
    Nidaq_photometry('Stop');
    [PhotoData,Photo2Data]=Nidaq_photometry('Save');
    BpodSystem.Data.NidaqData{iTrial}=PhotoData;
    if TaskParameters.GUI.DbleFibers || TaskParameters.GUI.RedChannel
        BpodSystem.Data.Nidaq2Data{iTrial}=Photo2Data;
    end
     
    %% Bpod save
    if ~isempty(fieldnames(RawEvents))
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
        SaveBpodSessionData;
    end

    
    PhotometryCal_PlotSideOutcome(BpodSystem.GUIHandles.OutcomePlot,'update',iTrial);
    
    % plot photometry data
        [currentNidaq1, rawNidaq1]=Online_NidaqDemod(PhotoData(:,1),nidaq.LED1,TaskParameters.GUI.LED1_Freq,TaskParameters.GUI.LED1_Amp,TaskParameters.GUIMeta.StateToZero.String{TaskParameters.GUI.StateToZero});
    FigNidaq1=Online_NidaqPlot('update',[],FigNidaq1,currentNidaq1,rawNidaq1);

    if TaskParameters.GUI.Isobestic405 || TaskParameters.GUI.DbleFibers || TaskParameters.GUI.RedChannel
        if TaskParameters.GUI.Isobestic405
        [currentNidaq2, rawNidaq2]=Online_NidaqDemod(PhotoData(:,1),nidaq.LED2,TaskParameters.GUI.LED2_Freq,TaskParameters.GUI.LED2_Amp,TaskParameters.GUIMeta.StateToZero.String{TaskParameters.GUI.StateToZero});
        elseif TaskParameters.GUI.RedChannel
        [currentNidaq2, rawNidaq2]=Online_NidaqDemod(Photo2Data(:,1),nidaq.LED2,TaskParameters.GUI.LED2_Freq,TaskParameters.GUI.LED2_Amp,TaskParameters.GUIMeta.StateToZero.String{TaskParameters.GUI.StateToZero});
        elseif TaskParameters.GUI.DbleFibers
        [currentNidaq2, rawNidaq2]=Online_NidaqDemod(Photo2Data(:,1),nidaq.LED2,TaskParameters.GUI.LED1b_Freq,TaskParameters.GUI.LED1b_Amp,TaskParameters.GUIMeta.StateToZero.String{TaskParameters.GUI.StateToZero});
        end
        FigNidaq2=Online_NidaqPlot('update',[],FigNidaq2,currentNidaq2,rawNidaq2);
    end
    
    %% End of trial
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.BeingUsed == 0
        return
    end
    
    iTrial = iTrial + 1;    
end

%% photometry check
%% Photometry QC
    thismax=max(PhotoData(TaskParameters.GUI.NidaqSamplingRate:TaskParameters.GUI.NidaqSamplingRate*2,1))
    if thismax>4 || thismax<0.3
        disp('WARNING - Something is wrong with fiber #1 - run check-up! - unpause to ignore')
        BpodSystem.Pause=1;
        HandlePauseCondition;
    end
    if TaskParameters.GUI.DbleFibers
    thismax=max(Photo2Data(TaskParameters.GUI.NidaqSamplingRate:TaskParameters.GUI.NidaqSamplingRate*2,1))
    if thismax>4 || thismax<0.3
        disp('WARNING - Something is wrong with fiber #2 - run check-up! - unpause to ignore')
        BpodSystem.Pause=1;
        HandlePauseCondition;
    end
    end


end

function sma = stateMatrix(iTrial)

global BpodSystem
global TaskParameters

%% Define ports

    
sma = NewStateMatrix();
sma = AddState(sma, 'Name', 'state_0',...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'ITI'},...
    'OutputActions', {});
sma = AddState(sma, 'Name', 'ITI',...
    'Timer', TaskParameters.GUI.T,...
    'StateChangeConditions', {'Tup','exit'},...
    'OutputActions', {});

end

