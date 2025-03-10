function [nwb, recdev, probe] = i2nPRO(pp, nwb, recording_info, ii, num_recording_devices)

% NEEDS TO BE FIXED TO ACCOMODATE PROBES THAT USE MORE THAN ONE PORT.

% Initialize probe table
e_variables = {'x', 'y', 'z', 'imp', 'location', 'filtering', 'group', 'label' ,'probe'};
electrode_table = [];

% Loop through probes to setup nwb tables
probe_ctr = 0;
chan_ctr = 0;
for rd = 0 : num_recording_devices-1

    in_file_path_0 = findDir(pp.RAW_DATA, num2str(recording_info.Session(ii)));
    in_file_path_1 = findDir(pp.RAW_DATA, ['dev-' num2str(rd)]);
    in_file_path_2 = findDir(pp.RAW_DATA, recording_info.Subject{ii});

    match_dir_0 = ismember(in_file_path_2, in_file_path_0);
    match_dir_1 = ismember(in_file_path_2, in_file_path_1);
    match_dir_2 = match_dir_0 & match_dir_1;

    t_in_file_path = [in_file_path_2{match_dir_2} filesep];
    clear match_dir_* in_file_path_*

    % Read settings
    recdev{rd+1} = readIntanHeader(t_in_file_path);
    recdev{rd+1}.in_file_path = t_in_file_path;
    clear in_file_path

    recdev{rd+1}.num = rd;

    recdev{rd+1}.local_probes = str2double(strtrim(split(recording_info.Probe_System{ii}, ';'))) == rd;
    recdev{rd+1}.local_probes = recdev{rd+1}.local_probes(1:end-1);
    recdev{rd+1}.local_aio = str2double(strtrim(split(recording_info.AIO_System{ii}, ';'))) == rd;
    recdev{rd+1}.local_aio = recdev{rd+1}.local_aio(1:end-1);
    recdev{rd+1}.local_dio = str2double(strtrim(split(recording_info.DIO_System{ii}, ';'))) == rd;
    recdev{rd+1}.local_dio = recdev{rd+1}.local_dio(1:end-1);

    for jj = 1:numel(strtrim(split(recording_info.DIO_Port{ii}, ';')))-1
        recdev{rd+1}.dio_map{jj}.description = uncell(strtrim(split(recording_info.DIO_Channels{ii}, ';')), jj);
        recdev{rd+1}.dio_map{jj}.map = eval(uncell(strtrim(split(recording_info.DIO_Port{ii}, ';')), jj));
    end

    recdev{rd+1}.adc_map = strtrim(split(recording_info.AIO_Channels{ii}, ';'));
    recdev{rd+1}.adc_map = recdev{rd+1}.adc_map(1:end-1);
    recdev{rd+1}.adc_map = recdev{rd+1}.adc_map(find(recdev{rd+1}.local_aio));

    if ~isempty(find(recdev{rd+1}.local_probes))
        for jj = find(recdev{rd+1}.local_probes)'

            ind_e_table = cell2table(cell(0, length(e_variables)), ...
                'VariableNames', e_variables);

            if jj == recording_info.Probe_Count(ii)
                probe{probe_ctr+1}.last_probe = 1;
            else
                probe{probe_ctr+1}.last_probe = 0;
            end

            probe{probe_ctr+1}.recdev = rd;

            probe{probe_ctr+1}.port = char(strtrim(paren(strsplit(recording_info.Probe_Port{ii}, ';'), jj)));

            % Determine number of samples in datafiles
            probe{probe_ctr+1}.num_samples = length(recdev{rd+1}.time_stamp);

            % Determine the downsampling
            probe{probe_ctr+1}.downsample_fs = 1000;
            probe{probe_ctr+1}.downsample_factor = recdev{rd+1}.sampling_rate/probe{probe_ctr+1}.downsample_fs;
            recdev{rd+1}.time_stamps_s = recdev{rd+1}.time_stamp / recdev{rd+1}.sampling_rate;
            recdev{rd+1}.time_stamps_s_ds = downsample(recdev{rd+1}.time_stamps_s, probe{probe_ctr+1}.downsample_factor);
            recdev{rd+1}.downsample_size = length(recdev{rd+1}.time_stamps_s_ds);

            % Determine number of channels that should be present for probe
            probe{probe_ctr+1}.num_channels = str2double(strtrim(paren(strsplit(recording_info.Probe_Channels{ii}, ';'), jj)));
            probe{probe_ctr+1}.type = char(paren(strtrim(split(recording_info.Probe_Ident{ii}, ';')), jj));
            probe{probe_ctr+1}.num = probe_ctr;

            probe{probe_ctr+1}.chan_prior = chan_ctr;
            chan_ctr = chan_ctr + probe{probe_ctr+1}.num_channels;

            % Load the correct channel map file
            load([probe{probe_ctr+1}.type '.mat'], 'x', 'y', 'z')

            % Create device
            device = types.core.Device(...
                'description', paren(strtrim(split(recording_info.Probe_Ident{ii}, ';')), jj), ...
                'manufacturer', paren(strtrim(split(recording_info.Probe_Manufacturer{ii}, ';')), jj), ...
                'probe_id', probe{probe_ctr+1}.num, ...
                'sampling_rate', recdev{rd+1}.sampling_rate ...
                );
            nwb.general_devices.set(['probe' alphabet(probe{probe_ctr+1}.num+1)], device);

            electrode_group = types.core.ElectrodeGroup( ...
                'has_lfp_data', true, ...
                'lfp_sampling_rate', probe{probe_ctr+1}.downsample_fs, ...
                'probe_id', probe{probe_ctr+1}.num, ...
                'description', ['electrode group for probe' alphabet(probe{probe_ctr+1}.num+1)], ...
                'location', paren(strtrim(split(recording_info.Area{ii}, ';')), jj), ...
                'device', types.untyped.SoftLink(device) ...
                );
            nwb.general_extracellular_ephys.set(['probe' alphabet(probe{probe_ctr+1}.num+1)], electrode_group);

            group_object_view = types.untyped.ObjectView(electrode_group);

            % Grab X, Y, Z position
            try
                X = returnGSNum(recording_info.X, ii, jj);
            catch
                X = NaN;
            end
            try
                Y = returnGSNum(recording_info.Y, ii, jj);
            catch
                Y = NaN;
            end
            try
                Z = returnGSNum(recording_info.Z, ii, jj);
            catch
                Z = NaN;
            end

            temp_imp = NaN; % add impedance data in future rev
            temp_loc = paren(strtrim(split(recording_info.Area{ii}, ';')), jj);
            temp_filt = NaN; % Can probably grab this from the settings file eventually.

            for ielec = 1:probe{probe_ctr+1}.num_channels

                probe_label = ['probe' alphabet(probe{probe_ctr+1}.num+1)];
                electrode_label = ['probe' alphabet(probe{probe_ctr+1}.num+1) '_e' num2str(ielec)];

                temp_X = X + x(ielec);
                temp_Y = Y + y(ielec);
                temp_Z = Z - (max(abs(z)) - z(ielec));

                ind_e_table = [ind_e_table; {...
                    temp_X, temp_Y, temp_Z, ...
                    temp_imp, temp_loc, temp_filt, ...
                    group_object_view, electrode_label, ...
                    probe_label}];

            end

            electrode_table = [electrode_table; ind_e_table];
            probe_ctr = probe_ctr + 1;

        end
    end
end

if ~isempty(electrode_table)
    nwb.general_extracellular_ephys_electrodes = util.table2nwb(electrode_table);

    e_ctr = 0;
    probe_ctr = 0;
    for jj = 1 : recording_info.Probe_Count(ii)

        probe{probe_ctr+1}.electrode_table_region = types.hdmf_common.DynamicTableRegion( ...
            'table', types.untyped.ObjectView(nwb.general_extracellular_ephys_electrodes), ...
            'description', ['probe' alphabet(probe{probe_ctr+1}.num+1)], ...
            'data', (0+e_ctr:probe{probe_ctr+1}.num_channels+e_ctr-1)');

        e_ctr = e_ctr + probe{probe_ctr+1}.num_channels;
        probe_ctr = probe_ctr + 1;

    end
end

if ~exist('probe', 'var')
    probe = [];
end

end