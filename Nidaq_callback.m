function Nidaq_callback(src,event)
%Callback function for nidaq acquisition. This function is used by a
%listener requiered when nidaq is started in background.
global nidaq

nidaq.ai_data = [nidaq.ai_data;event.Data];
        
% ExpectedSize=nidaq.duration*nidaq.sample_rate;
% nidaq.ai_data=NaN(ExpectedSize,size(event.Data));
% nidaq.ai_data = event.Data(1:ExpectedSize,:);
     
end