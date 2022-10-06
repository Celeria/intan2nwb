%% Header
% Jake Westerberg, PhD (westerberg-science)
% Vanderbilt University
% jakewesterberg@gmail.com
% Code contributions from Patrick Meng (VU)

% Description
% Written as a pipeline for data collected in the Bastos Lab (or similar
% setup using the intan system) to be transformed from raw to the nwb
% format.

% Requirements
% Certain aspects of the data processing require toolboxes found in other
% github repos. Original or forked versions of all required can be found on
% Jake's github page (westerberg-science). Kilosort (2 is used here) is
% required for spike sorting, extended-GLM-for-synapse-detection (a modified
% version found on Jake's github) is required to estimate connectivity
% between units. Also, this of course requires the matnwb toolbox.

% Notes
% 1. This version of the code requires having a google sheet with some
% information pertaining to the recordings.


function intan2nwb(varargin)
%% Defaults
workers                         = 0; % use parallel computing where possible

skip_completed                  = true;

in_file_path                    = '\\teba.psy.vanderbilt.edu\bastoslab\_BL_DATA_PIPELINE\_0_RAW_DATA\';
out_file_path                   = '\\teba.psy.vanderbilt.edu\bastoslab\_BL_DATA_PIPELINE\_3_NWB_DATA\';

this_subject                    = []; % used to specify processing for only certain subjects
this_ident                      = []; % used to specify specific session(s) with their ident

bin_file_path                    = '\\teba.psy.vanderbilt.edu\bastoslab\_BL_DATA_PIPELINE\_1_BIN_DATA\';
spk_file_path                    = '\\teba.psy.vanderbilt.edu\bastoslab\_BL_DATA_PIPELINE\_2_SPK_DATA\';

quick_storage_path               = [userpath filesep 'kilosort_scratch'];

params.downsample_fs            = 1000;

params.car_bin                  = false;
params.trigger_PRO              = false; % not useable now.

%% Varargin
varStrInd = find(cellfun(@ischar,varargin));
for iv = 1:length(varStrInd)
    switch varargin{varStrInd(iv)}
        case {'-i', 'in_file_path'}
            in_file_path = varargin{varStrInd(iv)+1};
        case {'-o', 'out_file_path'}
            out_file_path = varargin{varStrInd(iv)+1};
        case {'-b', 'bin_file_path'}
            bin_file_path = varargin{varStrInd(iv)+1};
        case {'skip'}
            skip_completed = varargin{varStrInd(iv)+1};
        case {'this_subject'}
            this_subject = varargin{varStrInd(iv)+1};
        case {'this_ident'}
            this_ident = varargin{varStrInd(iv)+1};
        case {'-p', 'params'}
            params = varargin{varStrInd(iv)+1};
        case {'-pc', 'parallel_compute'}
            parallel_compute = varargin{varStrInd(iv)+1};
        case {'-gpu', 'gpu_compute'}
            gpu_compute = varargin{varStrInd(iv)+1};
        case {'ID'}
            ID = varargin{varStrInd(iv)+1};
    end
end

%% Use UI if desired
if ~exist('ID', 'var')
    ID = load(uigetfile(pwd, 'SELECT RECORDING ID FILE'));
    in_file_path = uigetdir(pwd, 'SELECT DATA INPUT DIRECTORY');
    out_file_path = uigetdir(pwd, 'SELECT DATA OUTPUT DIRECTORY');
end

%% Read recording session information
url_name = sprintf('https://docs.google.com/spreadsheets/d/%s/gviz/tq?tqx=out:csv&sheet=%s', ID);
recording_info = webread(url_name);

% Create default processing list
n_idents = length(recording_info.Identifier);
to_proc = 1:n_idents;

% Limit to sessions within subject (if applicable)
if ~isempty(this_subject)
    to_proc = find(strcmp(recording_info.Subject, this_subject));
end

% Limit to a specific session in a specific subject
if ~isempty(this_ident)
    to_proc = nan(1, numel(this_ident));
    for ii = 1 : numel(this_ident)
        to_proc(ii) = find(strcmp(recording_info.Identifier, this_ident{ii}));
    end
end

%% Loop through sessions
for ii = to_proc

    % Find the correct subpath
    in_file_path_1 = findDir(in_file_path, datestr(recording_info.Session(ii), 'yymmdd'));
    in_file_path_2 = findDir(in_file_path, recording_info.Subject{ii});

    match_dir = ismember(in_file_path_2, in_file_path_1);
    if isempty(match_dir)
        in_file_path_2 = findDir(in_file_path, recording_info.Subject_Nickname{ii});
        match_dir = ismember(in_file_path_2, in_file_path_1);
        if isempty(match_dir)
            warning(['COULD NOT FIND DIR FOR ' recording_info.Subject{ii} '-' ...
                datestr(recording_info.Session(ii), 'yymmdd') ' MOVING ON.'])
            continue
        end
    end

    in_file_path_itt = [in_file_path_2{match_dir} filesep];
    clear in_file_path_1 in_file_path_2 match_dir

    % Create file identifier
    file_ident = ['sub-' recording_info.Subject{ii} '_ses-' datestr(recording_info.Session(ii), 'yymmdd')];

    % Skip files already processed if desired
    if exist([out_file_path file_ident '.nwb'], 'file') & ...
            skip_completed
        continue;
    end

    % Read settings
    intan_header = readIntanHeader(in_file_path_itt);

    % Determine number of samples in datafiles
    n_samples = length(intan_header.time_stamp);

    % Determine the downsampling
    params.downsample_factor = intan_header.sampling_rate/params.downsample_fs;
    time_stamps_s = intan_header.time_stamp / intan_header.sampling_rate;
    time_stamps_s_ds = downsample(time_stamps_s, params.downsample_factor);
    downsample_size = length(time_stamps_s_ds);

    % Initialize nwb file
    nwb                                 = NwbFile;
    nwb.identifier                      = recording_info.Identifier{ii};
    nwb.session_start_time              = datetime(recording_info.Session(ii));
    nwb.general_experimenter            = recording_info.Investigator{ii};
    nwb.general_institution             = recording_info.Institution{ii};
    nwb.general_lab                     = recording_info.Lab{ii};
    nwb.general_session_id              = recording_info.Identifier{ii};
    nwb.general_experiment_description  = recording_info.Experiment_Description{ii};

    % Determine which probes are present
    probes = strtrim(split(recording_info.Probe_Ident{ii}, ','));

    % Loop through probes to setup nwb tables
    for jj = 1 : recording_info.Probe_Count

        % Initialize probe table
        variables = {'x', 'y', 'z', 'imp', 'location', 'filtering', 'group', 'label'};
        e_table = cell2table(cell(0, length(variables)), 'VariableNames', variables);

        % Determine number of channels that should be present for probe
        n_channels = returnGSNum(recording_info.Probe_Channels, ii, jj);

        % Load the correct channel map file
        load([probes{jj} '.mat'], 'channel_map', 'x', 'y', 'z')

        % Create device
        device = types.core.Device(...
            'description', paren(strtrim(split(recording_info.Probe_Ident{ii}, ',')), jj), ...
            'manufacturer', paren(strtrim(split(recording_info.Probe_Manufacturer{ii}, ',')), jj), ...
            'probe_id', jj-1, ...
            'sampling_rate', intan_header.sampling_rate ...
            );

        % Input device information
        nwb.general_devices.set(['probe' alphabet(jj)], device);

        electrode_group = types.core.ElectrodeGroup( ...
            'has_lfp_data', true, ...
            'lfp_sampling_rate', params.downsample_fs, ...
            'probe_id', jj-1, ...
            'description', ['electrode group for probe' alphabet(jj)], ...
            'location', paren(strtrim(split(recording_info.Area{ii}, ',')), jj), ...
            'device', types.untyped.SoftLink(device) ...
            );

        nwb.general_extracellular_ephys.set(['probe' alphabet(jj)], electrode_group);
        group_object_view = types.untyped.ObjectView(electrode_group);

        % Grab X, Y, Z position
        X = returnGSNum(recording_info.X, ii, jj);
        Y = returnGSNum(recording_info.Y, ii, jj);
        Z = returnGSNum(recording_info.Z, ii, jj);

        temp_imp = NaN; % Can we add in impedance data, day-to-day from intan file?

        temp_loc = paren(strtrim(split(recording_info.Area{ii}, ',')), jj);

        temp_filt = NaN; % Can probably grab this from the settings file eventually.

        for ielec = 1:n_channels
            electrode_label = ['probe' alphabet(jj) '_e' num2str(ielec)];

            temp_X = X + x(ielec);
            temp_Y = Y + y(ielec);
            temp_Z = Z - (max(abs(y)) - y(ielec));

            e_table = [e_table; {temp_X, temp_Y, temp_Z, temp_imp, temp_loc, temp_filt, group_object_view, electrode_label}];
        end

        % Record electrode table
        electrode_table = util.table2nwb(e_table, ['probe' alphabet(jj)]);
        nwb.general_extracellular_ephys_electrodes = electrode_table;

        % Initialize electrode table region
        electrode_table_region = types.hdmf_common.DynamicTableRegion( ...
            'table', types.untyped.ObjectView(electrode_table), ...
            'description', ['probe' alphabet(jj)], ...
            'data', (0:height(e_table)-1)');

        % Initialize DC offset filter
        [DC_offset_bwb, DC_offset_bwa] = butter(1, 0.1/(intan_header.sampling_rate/2), 'high');

        % Initialize filter information
        [muae_bwb, muae_bwa] = butter(2, [500 5000]/(intan_header.sampling_rate/2), 'bandpass');
        [muae_power_bwb, muae_power_bwa] = butter(4, 250/(intan_header.sampling_rate/2), 'low');
        [lfp_bwb, lfp_bwa] = butter(2, [1 250]/(intan_header.sampling_rate/2), 'bandpass');


        % Determine number of channels that should be present for probe
        if strcmp(class(recording_info.Probe_Channels), 'double')
            n_channels = recording_info.Probe_Channels(jj);
        elseif strcmp(class(recording_info.Probe_Channels), 'cell')
            temp_array_1 = strtrim(split(recording_info.Probe_Channels{ii}, ','));
            n_channels = str2double(temp_array_1{jj});
            clear temp_array_1
        end

        % Load the correct channel map file
        load([probes{jj} '.mat'], 'channel_map', 'x', 'y', 'z')

        % Initialize data matrices. Need to fix for multiprobe
        lfp = zeros(n_channels, downsample_size);
        muae = zeros(n_channels, downsample_size);

        if workers == 0
            test_fid = fopen(in_file_path_itt + "\amp-" + intan_header.amplifier_channels(1).native_channel_name + ".dat");
            test_size = byteSize(double(fread(test_fid, n_samples, 'int16')) * 0.195);
            workers = floor((gpuDevice().AvailableMemory) / (8*test_size));
            if workers > feature('numcores')
                workers = feature('numcores');
            elseif workers == 0
                workers = 1;
            end
            fclose(test_fid);
            clear test_size
        end

        pvar_amp_ch = cat(1,{intan_header.amplifier_channels.native_channel_name});
        pvar_ds_factor = params.downsample_factor;

        if ~isempty(gcp('nocreate'))
            delete(gcp);
        end
        pool1 = parpool(workers);
        parfor kk = 1:n_channels
            % Open file and init data
            current_fid             = fopen(in_file_path_itt + "\amp-" + pvar_amp_ch{kk} + ".dat");

            % Setup array on GPU or in mem depending on run parameters
            current_data            = gpuArray(double(fread(current_fid, n_samples, 'int16')) * 0.195);

            % Do data type specific filtering
            muae(kk,:)  = gather(downsample(filtfilt(muae_power_bwb, muae_power_bwa, ...
                abs(filtfilt(muae_bwb, muae_bwa, ...
                filtfilt(DC_offset_bwb, DC_offset_bwa, ...
                current_data)))), pvar_ds_factor));
            lfp(kk,:)   = gather(downsample(filtfilt(lfp_bwb, lfp_bwa, ...
                filtfilt(DC_offset_bwb, DC_offset_bwa, ...
                current_data)), pvar_ds_factor));
            reset(gpuDevice)

            % Close file
            fclose(current_fid);
            disp([num2str(kk) '/' num2str(n_channels) ' COMPLETED.'])
        end
        delete(pool1)
        clear pvar_*

        %Rearrange the channels to the order on the probe (starts at 0, +1 so it
        %matches matlab indexing)
        muae = muae(channel_map+1,:);
        lfp = lfp(channel_map+1,:);

        lfp_electrical_series = types.core.ElectricalSeries( ...
            'electrodes', electrode_table_region,...
            'starting_time', 0.0, ... % seconds
            'starting_time_rate', params.downsample_fs, ... % Hz
            'data', lfp, ...
            'data_unit', 'uV', ...
            'filtering', '4th order Butterworth 1-250 Hz (DC offset high-pass 1st order Butterworth 0.1 Hz)', ...
            'timestamps', time_stamps_s_ds);

        lfp_series = types.core.LFP(['probe_' num2str(jj-1) '_lfp_data'], lfp_electrical_series);
        nwb.acquisition.set(['probe_' num2str(jj-1) '_lfp'], lfp_series);
        clear lfp

        muae_electrical_series = types.core.ElectricalSeries( ...
            'electrodes', electrode_table_region,...
            'starting_time', 0.0, ... % seconds
            'starting_time_rate', params.downsample_fs, ... % Hz
            'data', muae, ...
            'data_unit', 'uV', ...
            'filtering', '4th order Butterworth 500-500 Hz, full-wave rectified, then low pass 4th order Butterworth 250 Hz (DC offset high-pass 1st order Butterworth 0.1 Hz)', ...
            'timestamps', time_stamps_s_ds);

        muae_series = types.core.LFP('ElectricalSeries', muae_electrical_series);
        nwb.acquisition.set(['probe_' num2str(jj-1) '_muae'], muae_series);
        clear muae

        reset(gpuDevice)

        % Create Spiking bin file
        if ~exist([bin_file_path file_ident filesep], 'dir')
            mkdir([bin_file_path file_ident filesep])
        end
        intan2bin(in_file_path_itt, [bin_file_path file_ident filesep], [file_ident '_probe-' num2str(jj-1) '.bin'], ...
            intan_header, paren(recording_info.Probe_Port{ii}, jj))

        if params.car_bin; applyCAR2Dat([bin_file_path file_ident filesep file_ident '_probe-' num2str(jj-1) '.bin'], n_channels); end

        %Setup kilosort dirs
        spk_file_path_itt = [spk_file_path file_ident filesep 'probe-' num2str(jj-1) filesep]; % the raw data binary file is in this folder
        if ~exist(spk_file_path_itt, 'dir')
            mkdir(spk_file_path_itt)
        end

        p_type = paren(strtrim(split(recording_info.Probe_Ident{ii}, ',')), jj);
        ops.chanMap = which([p_type{1}, '_kilosortChanMap.mat']);
        run(which([p_type{1} '_config.m']))

        ops.trange      = [0 Inf]; % time range to sort
        ops.NchanTOT    = n_channels; % total number of channels in your recording

        ops.fig = 0;
        ops.fs = intan_header.sampling_rate;

        if ~exist(quick_storage_path, 'dir')
            mkdir(quick_storage_path)
        end
        ops.fproc       = fullfile(quick_storage_path, 'temp_wh.dat'); % proc file on a fast SSD

        % find the binary file
        if params.car_bin; ops.fbinary = [bin_file_path file_ident filesep file_ident '_probe-' num2str(jj-1) '_CAR.bin'];
        else; ops.fbinary = [bin_file_path file_ident filesep file_ident '_probe-' num2str(jj-1) '.bin']; end

        % preprocess data to create temp_wh.dat
        rez = preprocessDataSub(ops);

        % time-reordering as a function of drift
        rez = clusterSingleBatches(rez);

        % saving here is a good idea, because the rest can be resumed after loading rez
        save(fullfile(spk_file_path_itt, 'rez.mat'), 'rez', '-v7.3', '-nocompression');

        % main tracking and template matching algorithm
        rez = learnAndSolve8b(rez);

        % final merges
        rez = find_merges(rez, 1);

        % final splits by SVD
        rez = splitAllClusters(rez, 1);

        % final splits by amplitudes
        rez = splitAllClusters(rez, 0);

        % decide on cutoff
        rez = set_cutoff(rez);

        fprintf('found %d good units \n', sum(rez.good>0))

        % write to Phy
        fprintf('Saving results to Phy  \n')
        rezToPhy(rez, spk_file_path_itt);

        % discard features in final rez file (too slow to save)
        rez.cProj = [];
        rez.cProjPC = [];

        % final time sorting of spikes, for apps that use st3 directly
        [~, isort]   = sortrows(rez.st3);
        rez.st3      = rez.st3(isort, :);

        % Ensure all GPU arrays are transferred to CPU side before saving to .mat
        rez_fields = fieldnames(rez);
        for i = 1:numel(rez_fields)
            field_name = rez_fields{i};
            if(isa(rez.(field_name), 'gpuArray'))
                rez.(field_name) = gather(rez.(field_name));
            end
        end

        % save final results as rez2
        fprintf('Saving final results in rez2  \n')
        fname = fullfile(spk_file_path_itt, 'rez2.mat');
        save(fname, 'rez', '-v7.3', '-nocompression');

        reset(gpuDevice)

    end

    %         % Estimate interconnectivity of single units
    %         if params.cnx
    %
    %         end
    %
    %         % Record eye trace
    %         if params.eye
    %
    %         end

    % Save to NWB
    nwbExport(nwb, [out_file_path 'sub-' recording_info.Subject{ii} '_ses-' datestr(recording_info.Session(ii), 'yymmdd') '.nwb']);
    disp(['SUCCESSFULLY SAVED: ' out_file_path_itt 'sub-' recording_info.Subject '_ses-' recording_info.Session '.nwb'])

    % Increment counter
    n_procd = n_procd + 1;

end

disp(['SUCCESSFULLY PROCESSED ' n_procd ' FILES.'])

end