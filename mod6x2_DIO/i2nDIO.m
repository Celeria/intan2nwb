function [nwb,digital_failed] = i2nDIO(nwb, recdev)

digital_failed = 0;

for mm = 1 : numel(recdev.dio_map)
    if strcmp(recdev.dio_map{mm}.description, 'EVT')

        digital_ordered = recdev.board_dig_in_data(recdev.dio_map{mm}.map,:);

        if nwb.session_start_time < datetime(2022, 12, 1, 'TimeZone', 'America/Chicago') & ...
                nwb.session_start_time > datetime(2022, 8, 1, 'TimeZone', 'America/Chicago') & ...
                strcmp(nwb.general_lab, 'Bastos Lab')

            % Strobe-bit-less digital events that were used for a short
            % period of time. They seem to produce some inaccurate values
            % on decode...

            intan_code_times_unprocessed = find(sum(digital_ordered) > 0);
            intan_code_times = nan(length(intan_code_times_unprocessed),1);
            intan_code_values = nan(numel(recdev.dio_map{mm}.map),length(intan_code_times_unprocessed));

            temp_ctr = 1;
            intan_code_times(temp_ctr) = intan_code_times_unprocessed(temp_ctr);
            intan_code_values(:,temp_ctr) = digital_ordered(:,intan_code_times(temp_ctr));
            previous_value = intan_code_times(temp_ctr);
            temp_ctr = temp_ctr + 1;
            for jj = 2:length(intan_code_times_unprocessed)
                if ~(intan_code_times_unprocessed(jj) == previous_value + 1)
                    intan_code_times(temp_ctr) = intan_code_times_unprocessed(jj);
                    intan_code_values(:,temp_ctr) = digital_ordered(:,intan_code_times(temp_ctr)+1);
                    temp_ctr = temp_ctr + 1;
                end
                previous_value = intan_code_times_unprocessed(jj);
            end

            intan_code_times = intan_code_times(1:temp_ctr-1) ./ recdev.sampling_rate;
            intan_code_values = intan_code_values(:,1:temp_ctr-1);
            intan_code_values = bit2int(flip(intan_code_values),numel(recdev.dio_map{mm}.map))';

            temp_data = VANDERBILT_PassiveGLOv1(intan_code_values, intan_code_times);
            event_data = {};
            event_data{1} = temp_data; clear temp_data

        else

            % Assumes strobe bit is first bit and checks to see if it was
            % flipped
            strobe_check_win = 60;
            strobe_dir = ones(1, size(digital_ordered, 2));
            strobe_local_sum = movsum(digital_ordered(1,:), recdev.sampling_rate*strobe_check_win); 
            strobe_dir(strobe_local_sum > (0.5 * strobe_check_win * recdev.sampling_rate)) = 0;
            strobe_dir(1:round(recdev.sampling_rate * 0.5 * strobe_check_win)) = strobe_dir(round(recdev.sampling_rate * 0.5 * strobe_check_win));
            strobe_dir(end-round(recdev.sampling_rate * 0.5 * strobe_check_win):end) = strobe_dir(end-round(recdev.sampling_rate * 0.5 * strobe_check_win));
            digital_ordered(1, ~strobe_dir) = ~digital_ordered(1, ~strobe_dir);

            digital_ordered = ...
                bit2int(flip(digital_ordered), numel(recdev.dio_map{mm}.map))';

            strobe = find(recdev.board_dig_in_data(1,:))';
            intan_code_times = strobe(find(diff(strobe) > 1));
            intan_code_values = digital_ordered(intan_code_times);

            intan_code_times = intan_code_times / recdev.sampling_rate;
            
            try
                event_data = identEvents(intan_code_values, intan_code_times);
            catch
                digital_failed = 1;
                disp('!!!!!COULD NOT DECODE EVENTS. CREATING PLACEHOLDER WITH DATA IN NWB FILE!!!!!')
                event_data{1}.task = 'UNDECODABLE_PRESUMED_CODES';
                event_data{1}.codes = intan_code_values;
                event_data{1}.start_time = intan_code_times;
                event_data{1}.stop_time = intan_code_times;

                digi_state = types.core.TimeSeries( ...
                    'description', 'digital codes from failed decode attempt', ...
                    'data', int16(recdev.board_dig_in_data(recdev.dio_map{mm}.map,:)), ...
                    'data_unit', 'state', ...
                    'starting_time_rate', recdev.sampling_rate ... % Hz
                    );

                digi_tracking = types.core.BehavioralTimeSeries();
                digi_tracking.timeseries.set('digital_input_raw_data', digi_state);

                nwb.acquisition.set('digital_input_raw', digi_tracking);

            end

        end

        for jj = 1 : numel(event_data)
            temp_fields = fields(event_data{jj});
            temp_fields = temp_fields(~strcmp(temp_fields, 'task'));

            eval_str = [];
            for kk = 1 : numel(temp_fields)
                eval_str = ...
                    [ eval_str ...
                    ',convertStringsToChars("' temp_fields{kk} ...
                    '"), types.hdmf_common.VectorData(convertStringsToChars("data"), ' ...
                    'event_data{jj}.' temp_fields{kk} ...
                    ', convertStringsToChars("description"), ' ...
                    'convertStringsToChars("placeholder"))'];
            end
            eval_str = [
                'trials=types.core.TimeIntervals(convertStringsToChars("description"), ' ...
                'convertStringsToChars("events"), ' ...
                'convertStringsToChars("colnames"), ' ...
                'temp_fields' ...
                eval_str ');'];

            eval(eval_str); clear eval_str
            try
                nwb.intervals.set(event_data{jj}.task{1}, trials); clear trials
            catch
                nwb.intervals.set(event_data{jj}.task, trials); clear trials
            end
        end

    end
end
end