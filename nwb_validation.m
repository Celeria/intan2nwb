%% Header
%Takes all the NWB files currently on the preprocesser server and 

function nwb_validation(SLACK_ID)

fprintf("Running the Validation Function right now...")

%% pathing...can change to varargin or change function defaults for own machine
pp = pipelinePaths();

% add toolboxes
addpath(genpath(pp.TBOXES));
addpath(genpath(pp.REPO));
addpath(genpath("C:\Users\preprocess-server\Documents\GitHub\matnwb"));
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
    nwb = nwbRead(path_to_nwb + nwb_name);

    %Send this text to slack
    slack_text = sprintf("\n NWB DATA VALIDATION \n");

    %Print out passive glo specific information
    try
        %Written by Hamed Nejat, to count the number of trials in passive
        %glo for each block, and trial types. Modified by Patrick Meng to
        %append to the slack notification text
        a = (nwb.intervals.get("passive_glo").vectordata.get("task_block_number").data(:) == 1) & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:) & (nwb.intervals.get("passive_glo").vectordata.get("stimulus_number").data(:) == 5);
        b = (nwb.intervals.get("passive_glo").vectordata.get("task_block_number").data(:) == 2) & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:) & (nwb.intervals.get("passive_glo").vectordata.get("stimulus_number").data(:) == 5);
        c = (nwb.intervals.get("passive_glo").vectordata.get("task_block_number").data(:) == 3) & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:) & (nwb.intervals.get("passive_glo").vectordata.get("stimulus_number").data(:) == 5);    
        d = (nwb.intervals.get("passive_glo").vectordata.get("task_block_number").data(:) == 4) & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:) & (nwb.intervals.get("passive_glo").vectordata.get("stimulus_number").data(:) == 5);
        
        slack_text = slack_text + sprintf("\n> Session %s\n\n->Total correct trials: %d\n", nwb.identifier, sum(a + b + c + d));
        slack_text = slack_text + sprintf("-> Habituation(1) = %d, Main(2) = %d, Random control(3) = %d, Sequence control(4) = %d \n", sum(a), sum(b), sum(c), sum(d));
        slack_text = slack_text + sprintf("\n--> (1) LO habituation : %d \n", sum(a));
    
        a = nwb.intervals.get("passive_glo").vectordata.get("go_gloexp").data(:) & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:) & (nwb.intervals.get("passive_glo").vectordata.get("task_block_number").data(:) == 2);
        slack_text = slack_text + sprintf("\n--> (2) GO main : %d ", sum(a));
        b = nwb.intervals.get("passive_glo").vectordata.get("lo_gloexp").data(:) & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:) & (nwb.intervals.get("passive_glo").vectordata.get("task_block_number").data(:) == 2);
        slack_text = slack_text + sprintf("\n--> (2) LO main : %d \n", sum(b));
    
        a = nwb.intervals.get("passive_glo").vectordata.get("go_rndctl").data(:) & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:);
        slack_text = slack_text + sprintf("\n--> (3) GO random control : %d ", sum(a));
        b = nwb.intervals.get("passive_glo").vectordata.get("lo_rndctl").data(:) & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:);
        slack_text = slack_text + sprintf("\n--> (3) LO random control : %d ", sum(b));
        
        c = nwb.intervals.get("passive_glo").vectordata.get("igo_rndctl").data(:) & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:);
        slack_text = slack_text + sprintf("\n--> (3) iGO random control : %d ", sum(c));
        d = nwb.intervals.get("passive_glo").vectordata.get("ilo_rndctl").data(:) & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:);
        slack_text = slack_text + sprintf("\n--> (3) iLO random control : %d ", sum(d));
    
        e = nwb.intervals.get("passive_glo").vectordata.get("rndctl").data(:) & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:) & (nwb.intervals.get("passive_glo").vectordata.get("stimulus_number").data(:) == 5);
        slack_text = slack_text + sprintf("\n--> (3) Other random control : %d \n", sum(e) - sum(a + b + c + d));
    
        a = nwb.intervals.get("passive_glo").vectordata.get("go_seqctl").data(:) & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:);
        slack_text = slack_text + sprintf("\n--> (4) GO sequence control : %d ", sum(a));
        b = nwb.intervals.get("passive_glo").vectordata.get("igo_seqctl").data(:) & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:);
        slack_text = slack_text + sprintf("\n--> (4) iGO sequence control : %d \n", sum(b));

        try
        %Add the good unit count
        slack_text = slack_text + sprintf("\nGood Units: %d",sum(nwb.units.vectordata.get('quality').data(:)));
        catch
        slack_text = slack_text + sprintf("\nNo units found ): \n");
        end

    catch
    end

    if send_slack_alerts
        SendSlackNotification( ...
            SLACK_ID, ...
            [char(slack_text)], ...
            'nwb-validation', ...
            'HumanErrorExterminator', ...
            '', ...
            ':credit_card:');
    end

    %Just to not rate limit in case there's a bunch of files that need
    %processing, pauses the code for 2 seconds
    pause(2)

end

end