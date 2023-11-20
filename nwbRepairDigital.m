%% Header
% Takes all of the nwb files inside the nwb output folder, and regenerates
% the digital part of the file

function nwbRepairDigital(ID,IMAGE_TOKEN,varargin)
fprintf("Running the Validation Function right now...")

%% pathing...can change to varargin or change function defaults for own machine
pp = pipelinePaths();

%add toolboxes
addpath(genpath("C:\Users\preprocess-server\Documents\GitHub\matnwb"));
addpath(genpath("C:\Users\preprocess-server\Documents\GitHub\SlackMatlab"));
generateCore();

%% Prepare slack
if exist('SLACK_ID', 'var')
    send_slack_alerts = true;
else
    send_slack_alerts = false;
end

%% Loop through sessions
old_dir = pwd;
cd(pp.NWB_DATA);
nwb_file_list = dir('*.nwb');
cd(old_dir);

for ii = 1:length(nwb_file_list)
    path_to_nwb = string(nwb_file_list(ii).folder) + "\";
    nwb_name = string(nwb_file_list(ii).name);
    
    try
        nwb = nwbRead(path_to_nwb + nwb_name);
    catch
        slack_text = "Could not open nwb file";
    end

    %Send this text to slack
    slack_text = sprintf("\n> Repairing Session %s\n", nwb.identifier);



end

end