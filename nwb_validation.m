%% Header
%Takes the nwb generated, and

function nwb_validation(SLACK_ID)
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
    slack_text = string(nwb.identifier);

    %Print out passive glo specific information
    try
        passive_glo_info = nwb.intervals.get('passive_glo');
        a = (nwb.intervals.get("passive_glo").vectordata.get("task_block_number").data(:) == 1) & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:) & (nwb.intervals.get("passive_glo").vectordata.get("stimulus_number").data(:) == 5);
        b = (nwb.intervals.get("passive_glo").vectordata.get("task_block_number").data(:) == 2) & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:) & (nwb.intervals.get("passive_glo").vectordata.get("stimulus_number").data(:) == 5);
        c = (nwb.intervals.get("passive_glo").vectordata.get("task_block_number").data(:) == 3) & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:) & (nwb.intervals.get("passive_glo").vectordata.get("stimulus_number").data(:) == 5);
        d = (nwb.intervals.get("passive_glo").vectordata.get("task_block_number").data(:) == 4) & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:) & (nwb.intervals.get("passive_glo").vectordata.get("stimulus_number").data(:) == 5);

        slack_text = slack_text + string("\n-> hab(1) = %d, Main(2) = %d, rndctl(3) = %d, seqctl(4) = %d ", sum(a), sum(b), sum(c), sum(d));
        x = sum(a);
        a = nwb.intervals.get("passive_glo").vectordata.get("go_gloexp").data(:) & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:) & (nwb.intervals.get("passive_glo").vectordata.get("task_block_number").data(:) == 2);
        slack_text = slack_text + string("\n-> GO main : %d ", sum(a));
        b = nwb.intervals.get("passive_glo").vectordata.get("lo_gloexp").data(:) & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:) & (nwb.intervals.get("passive_glo").vectordata.get("task_block_number").data(:) == 2);
        slack_text = slack_text + string("\n-> LO main : %d ", sum(b));

        a = nwb.intervals.get("passive_glo").vectordata.get("go_rndctl").data(:);% & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:);
        slack_text = slack_text + string("\n-> GO rnd control : %d ", sum(a));
        b = nwb.intervals.get("passive_glo").vectordata.get("lo_rndctl").data(:);% & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:);
        slack_text = slack_text + string("\n-> LO rnd control : %d ", sum(b));

        c = nwb.intervals.get("passive_glo").vectordata.get("igo_rndctl").data(:);% & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:);
        slack_text = slack_text + string("\n-> iGO rnd control : %d ", sum(c));
        d = nwb.intervals.get("passive_glo").vectordata.get("ilo_rndctl").data(:);% & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:);
        slack_text = slack_text + string("\n-> iLO rnd control : %d ", sum(d));

        a = nwb.intervals.get("passive_glo").vectordata.get("go_seqctl").data(:) & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:);
        slack_text = slack_text + string("\n-> GO seq control : %d ", sum(a));
        b = nwb.intervals.get("passive_glo").vectordata.get("igo_seqctl").data(:) & nwb.intervals.get("passive_glo").vectordata.get("correct").data(:);
        slack_text = slack_text + string("\n-> iGO seq control : %d ", sum(b));
    catch
    end

    if send_slack_alerts
        SendSlackNotification( ...
            SLACK_ID, ...
            [nwb.identifier ': ' slack_text], ...
            'preprocess', ...
            'iJakebot', ...
            '', ...
            ':robot_face:');
    end

end

end
%
% for ii = to_proc
%
%     tic
%     ttt=toc;
%     if send_slack_alerts
%         SendSlackNotification( ...
%                 SLACK_ID, ...
%                 [recording_info.Identifier{ii} ': [' s2HMS(ttt) '] Session processing started.'], ...
%                 'preprocess', ...
%                 'iJakebot', ...
%                 '', ...
%                 ':robot_face:');
%     end
%
%     if strcmp(recording_info.Raw_Data_Format{ii}, 'AI-NWB')
%
%         if send_slack_alerts
%             SendSlackNotification( ...
%                 SLACK_ID, ...
%                 [recording_info.Identifier{ii} ': [' s2HMS(ttt) '] Allen Institute NWB-raw-data identified.'], ...
%                 'preprocess', ...
%                 'iJakebot', ...
%                 '', ...
%                 ':robot_face:');
%         end
%
%         raw_data_dir = [pp.RAW_DATA 'dandi' filesep '000253' ...
%             filesep 'sub_' recording_info.Subject{ii} ...
%             filesep 'sub_' recording_info.Subject{ii} ...
%             'sess_' num2str(recording_info.Session(ii)) ...
%             filesep 'sub_' recording_info.Subject{ii} ...
%             '+sess_' num2str(recording_info.Session(ii)) ...
%             '_ecephys.nwb'];
%
%         fpath = fileparts(raw_data_dir);
%
%         if ~exist(raw_data_dir, 'file')
%             warning('raw allen data not detected.')
%             continue
%         end
%
%         copyfile(raw_data_dir, [pp.NWB_DATA recording_info.Identifier{ii} '.nwb'])
%         nwb = nwbRead([pp.NWB_DATA recording_info.Identifier{ii} '.nwb']);
%
%         i2nAIC(pp, nwb, recording_info, ii, fpath);
%
%         if send_slack_alerts
%             SendSlackNotification( ...
%                 SLACK_ID, ...
%                 [recording_info.Identifier{ii} ': [' s2HMS(ttt) '] AI conversion complete.'], ...
%                 'preprocess', ...
%                 'iJakebot', ...
%                 '', ...
%                 ':robot_face:');
%         end
%
%         n_procd = n_procd + 1;
%         continue
%
%     end
%
%     % Initialize nwb file
%     nwb                                 = NwbFile;
%     nwb.identifier                      = recording_info.Identifier{ii};
%     nwb.session_start_time              = datetime(datestr(datenum(num2str(recording_info.Session(ii)), 'yymmdd')));
%     nwb.general_experimenter            = recording_info.Investigator{ii};
%     nwb.general_institution             = recording_info.Institution{ii};
%     nwb.general_lab                     = recording_info.Lab{ii};
%     nwb.general_session_id              = recording_info.Identifier{ii};
%     nwb.general_experiment_description  = recording_info.Experiment_Description{ii};
%
%     num_recording_devices = sum(strcmp(recording_info.Identifier, recording_info.Identifier{ii}));
%
%     for rd = 1 : num_recording_devices
%
%         % RAW DATA
%         fd1 = findDir(pp.RAW_DATA, nwb.identifier);
%         fd2 = findDir(pp.RAW_DATA, ['dev-' num2str(rd-1)]);
%         raw_data_present = sum(ismember(fd2, fd1));
%         clear fd*
%
%         if ~raw_data_present
%
%             if (exist([pp.SCRATCH '\i2n_grab_data.bat'],'file'))
%                 delete([pp.SCRATCH '\i2n_grab_data.bat']);
%             end
%
%             fd1 = findDir(pp.DATA_SOURCE, nwb.identifier);
%             fd2 = findDir(pp.DATA_SOURCE, ['dev-' num2str(rd-1)]);
%             raw_data_temp = fd2(ismember(fd2, fd1));
%             raw_data_temp = raw_data_temp{1};
%
%             [~, dir_name_temp] = fileparts(raw_data_temp);
%
%             % Grab data if missing
%             workers = feature('numcores');
%             fid = fopen([pp.SCRATCH '\i2n_grab_data.bat'], 'w');
%
%             fprintf(fid, '%s\n', ...
%                 ['robocopy ' ...
%                 raw_data_temp ...
%                 ' ' ...
%                 [pp.RAW_DATA dir_name_temp] ...
%                 ' /e /j /mt:' ...
%                 num2str(workers)]);
%
%             fclose('all');
%             system([pp.SCRATCH '\i2n_grab_data.bat']);
%             delete([pp.SCRATCH '\i2n_grab_data.bat']);
%             ttt = toc;
%
%             if send_slack_alerts
%                 SendSlackNotification( ...
%                     SLACK_ID, ...
%                     [nwb.identifier ': [' s2HMS(ttt) '] dev-' num2str(rd-1) ', Downloaded raw data from server.'], ...
%                     'preprocess', ...
%                     'iJakebot', ...
%                     '', ...
%                     ':robot_face:');
%             end
%
%         end
%     end
%
%     [nwb, recdev, probe] = i2nPRO(pp, nwb, recording_info, ii, num_recording_devices);
%     ttt=toc;
%     if send_slack_alerts
%         SendSlackNotification( ...
%                 SLACK_ID, ...
%                 [nwb.identifier ': [' s2HMS(ttt) '] NWB initialization complete.'], ...
%                 'preprocess', ...
%                 'iJakebot', ...
%                 '', ...
%                 ':robot_face:');
%     end
%
%     probe_ctr = 0;
%     for rd = 1 : num_recording_devices
%
%         % Record analog traces
%         nwb = i2nAIO(nwb, recdev{rd});
%         ttt = toc;
%         if send_slack_alerts
%             SendSlackNotification( ...
%                 SLACK_ID, ...
%                 [nwb.identifier ': [' s2HMS(ttt) '] dev-' num2str(rd-1) ', Extracted analog I/O.'], ...
%                 'preprocess', ...
%                 'iJakebot', ...
%                 '', ...
%                 ':robot_face:');
%         end
%
%         % Digital events
%         nwb = i2nDIO(nwb, recdev{rd});
%         ttt = toc;
%         if send_slack_alerts
%             SendSlackNotification( ...
%                 SLACK_ID, ...
%                 [nwb.identifier ': [' s2HMS(ttt) '] dev-' num2str(rd-1) ', Extracted Digital I/O.'], ...
%                 'preprocess', ...
%                 'iJakebot', ...
%                 '', ...
%                 ':robot_face:');
%         end
%
%         % Loop through probes to setup nwb tables
%         for jj = 1 : recording_info.Probe_Count(ii)
%
%             % BIN DATA
%             if ~exist([pp.BIN_DATA nwb.identifier filesep ...
%                     nwb.identifier '_probe-' num2str(probe{probe_ctr+1}.num) '.bin'], 'file')
%                 i2nBIN(pp, nwb, recdev{rd}, probe{probe_ctr+1});
%                 ttt = toc;
%
%                 if send_slack_alerts
%                     SendSlackNotification( ...
%                         SLACK_ID, ...
%                         [nwb.identifier ': [' s2HMS(ttt) '] dev-' num2str(rd-1) ', Binarized raw data.'], ...
%                         'preprocess', ...
%                         'iJakebot', ...
%                         '', ...
%                         ':robot_face:');
%                 end
%             end
%
%             % LFP AND MUA CALC
%             try
%                 eval(['nwb.acquisition.probe_' num2str(probe{probe_ctr+1}.num) '_lfp']);
%             catch
%                 nwb = i2nCDS(nwb, recdev{rd}, probe{probe_ctr+1});
%                 ttt = toc;
%
%                 if send_slack_alerts
%                     SendSlackNotification( ...
%                         SLACK_ID, ...
%                         [nwb.identifier ': [' s2HMS(ttt) '] dev-' num2str(rd-1) ', Filtered MUAe and LFP.'], ...
%                         'preprocess', ...
%                         'iJakebot', ...
%                         '', ...
%                         ':robot_face:');
%                 end
%
%             end
%
%             % SPIKE SORTING
%             try
%                 nwb = i2nSPK(pp, nwb, recdev{rd}, probe{probe_ctr+1});
%
%                 ttt = toc;
%
%                 if send_slack_alerts
%                     SendSlackNotification( ...
%                         SLACK_ID, ...
%                         [nwb.identifier ': [' s2HMS(ttt) '] dev-' num2str(rd-1) ', Completed spike sorting/curation (~' ...
%                         num2str(sum(nwb.units.vectordata.get('quality').data(:))) ' good units).'], ...
%                         'preprocess', ...
%                         'iJakebot', ...
%                         '', ...
%                         ':robot_face:');
%                 end
%             catch
%                 warning('KS DIDNT PAN OUT!!!!!!')
%             end
%
%             probe_ctr = probe_ctr + 1;
%
%         end
%     end
%
%     ttt = toc;
%     if send_slack_alerts
%         SendSlackNotification( ...
%             SLACK_ID, ...
%             [nwb.identifier ': [' s2HMS(ttt) '] Session processing complete.'], ...
%             'preprocess', ...
%             'iJakebot', ...
%             '', ...
%             ':robot_face:');
%     end
%
%     n_procd = n_procd + 1;
%     nwbExport(nwb, [pp.NWB_DATA nwb.identifier '.nwb']);
%
%     % Cleanup
%     i2nCleanup(pp, keepers);
%
%
% end
% disp(['SUCCESSFULLY PROCESSED ' num2str(n_procd) ' FILES.'])
% end