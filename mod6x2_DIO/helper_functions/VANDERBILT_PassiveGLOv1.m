function task_data = VANDERBILT_PassiveGLOv1(codes, times)

task_data.task = 'passive_glo';

ii_ctr = 1;

block_mat = ["gloexp", "rndctl", "seqctl"];
condition_mat = [ ...
    1 45 45 45 135 2; ...
    1 45 45 45 135 2; ...
    1 45 45 45 45 1; ...
    2 45 45 45 45 1; ...
    2 45 45 45 45 1; ...
    2 45 45 45 45 1; ...
    2 135 135 135 135 16; ...
    2 135 135 135 135 16; ...
    2 135 135 135 135 16; ...
    2 45 45 45 135 2; ...
    2 45 45 45 135 2; ...
    2 45 45 45 135 2; ...
    2 135 135 135 45 15; ...
    2 135 135 135 45 15; ...
    2 135 135 135 45 15; ...
    2 45 45 135 135 6; ...
    2 45 135 135 135 12; ...
    2 135 135 45 45 11; ...
    2 135 45 45 45 5 ; ...
    2 135 45 45 135 8; ...
    2 45 135 135 45 9; ...
    2 45 135 45 45 4; ...
    2 45 45 135 45 3; ...
    2 45 135 45 135 7; ...
    2 135 45 135 45 10; ...
    2 135 45 135 135 13; ...
    2 135 135 45 135 14; ...
    3 135 135 135 135 16; ...
    3 45 45 45 45 1];

trial_ct = 0;
for ii = 1 : numel(codes)

    if codes(ii)>100 & codes(ii)<150

        current_trial_seq = condition_mat(codes(ii)-100, 1);
        current_trial_type = condition_mat(codes(ii)-100, 2:5);
        temp_note = codes(ii) - 100;
        trial_ct = trial_ct + 1;
        temp_seq_type = condition_mat(codes(ii)-100, 6);
        continue

    end

    if codes(ii) == 10 | codes(ii) == 255 | codes(ii) == 20 | codes(ii) == 22 | codes(ii) == 24 | codes(ii) == 30 | codes(ii) == 40
        task_data.codes(ii_ctr)         = codes(ii);
        task_data.start_time(ii_ctr)   = times(ii);
        task_data.trial_num(ii_ctr)     = trial_ct;
        
        if strcmp(block_mat(current_trial_seq), 'gloexp')
            task_data.gloexp(ii_ctr) = 1;
        else
            task_data.gloexp(ii_ctr) = 0;
        end

        if strcmp(block_mat(current_trial_seq), 'rndctl')
            task_data.rndctl(ii_ctr) = 1;
        else
            task_data.rndctl(ii_ctr) = 0;
        end

        if strcmp(block_mat(current_trial_seq), 'seqctl')
            task_data.seqctl(ii_ctr) = 1;
        else
            task_data.seqctl(ii_ctr) = 0;
        end

        try
            task_data.stop_time(ii_ctr)    = times(ii+1);
        catch
            task_data.stop_time(ii_ctr)    = times(ii);
        end
        switch codes(ii)
            case 10
                task_data.orientation(ii_ctr) = NaN;
                task_data.presentation(ii_ctr) = NaN;
                task_data.sequence_type{ii_ctr} = block_mat(current_trial_seq);
                task_data.notes{ii_ctr} = temp_note; 
                task_data.event_code_type{ii_ctr} = "fix cue appearance";
                task_data.seq_type(ii_ctr) = temp_seq_type;
            case 255
                task_data.orientation(ii_ctr) = NaN;
                task_data.presentation(ii_ctr) = NaN;
                task_data.sequence_type{ii_ctr} = block_mat(current_trial_seq);
                task_data.notes{ii_ctr} = temp_note;
                task_data.event_code_type{ii_ctr} = "fixation made";
                task_data.seq_type(ii_ctr) = temp_seq_type;
            case 20
                task_data.orientation(ii_ctr) = current_trial_type(1);
                task_data.presentation(ii_ctr) = 1;
                task_data.sequence_type{ii_ctr} = block_mat(current_trial_seq);
                task_data.notes{ii_ctr} = temp_note;
                task_data.event_code_type{ii_ctr} = "presentation 1";
                task_data.seq_type(ii_ctr) = temp_seq_type;
            case 22
                task_data.orientation(ii_ctr) = current_trial_type(2);
                task_data.presentation(ii_ctr) = 2;
                task_data.sequence_type{ii_ctr} = block_mat(current_trial_seq);
                task_data.notes{ii_ctr} = temp_note;
                task_data.event_code_type{ii_ctr} = "presentation 2";
                task_data.seq_type(ii_ctr) = temp_seq_type;
            case 24
                task_data.orientation(ii_ctr) = current_trial_type(3);
                task_data.presentation(ii_ctr) = 3;
                task_data.sequence_type{ii_ctr} = block_mat(current_trial_seq);
                task_data.notes{ii_ctr} = temp_note;
                task_data.event_code_type{ii_ctr} = "presentation 3";
                task_data.seq_type(ii_ctr) = temp_seq_type;
            case 30
                task_data.orientation(ii_ctr) = current_trial_type(4);
                task_data.presentation(ii_ctr) = 4;
                task_data.sequence_type{ii_ctr} = block_mat(current_trial_seq);
                task_data.notes{ii_ctr} = temp_note;
                task_data.event_code_type{ii_ctr} = "presentation 4";
                task_data.seq_type(ii_ctr) = temp_seq_type;
            case 40
                task_data.orientation(ii_ctr) = NaN;
                task_data.presentation(ii_ctr) = NaN;
                task_data.sequence_type{ii_ctr} = block_mat(current_trial_seq);
                task_data.notes{ii_ctr} = temp_note;
                task_data.event_code_type{ii_ctr} = "reward";
                task_data.seq_type(ii_ctr) = temp_seq_type;
        end
        ii_ctr = ii_ctr +1;
    end
end

task_data.correct = zeros(numel(task_data.codes), 1);
u_trials = unique(task_data.trial_num);
for ii = u_trials
    temp_inds = sum(task_data.codes == 40 & task_data.trial_num == ii);
    if temp_inds
        task_data.correct(task_data.trial_num == ii) = 1;
    end
end

task_data.contrast       = repmat(0.8, numel(task_data.start_time), 1); % stimulus contrast
task_data.drift_rate     = repmat(2, numel(task_data.start_time), 1); % temporal frequency (drift rate)  

task_data.codes             = task_data.codes';
task_data.seq_type          = task_data.seq_type';
task_data.trial_num         = task_data.trial_num';
task_data.presentation      = task_data.presentation';
task_data.start_time        = task_data.start_time';
task_data.stop_time         = task_data.stop_time';
task_data.orientation       = task_data.orientation';
task_data.sequence_type     = task_data.sequence_type';
task_data.notes             = task_data.notes';
task_data.event_code_type   = task_data.event_code_type';
task_data.gloexp            = task_data.gloexp';
task_data.rndctl            = task_data.rndctl';
task_data.seqctl            = task_data.seqctl';

% % all possible sequence combinations
% seq_combos                         = [ ...
%     go, go, go, go; ...
%     go, go, go, lo; ...
%     go, go, lo, go; ...
%     go, lo, go, go; ...
%     lo, go, go, go; ...
%     go, go, lo, lo; ...
%     go, lo, go, lo; ...
%     lo, go, go, lo; ...  
%     go, lo, lo, go; ...
%     lo, go, lo, go; ...
%     lo, lo, go, go; ...
%     go, lo, lo, lo; ...
%     lo, go, lo, lo; ...
%     lo, lo, go, lo; ...
%     lo, lo, lo, go; ...
%     lo, lo, lo, lo ];

% and code them relative to the combo matrix above
seq_go_type                        = 1;
seq_lo_type                        = 2;
seq_ilo_type                       = 15;
seq_igo_type                       = 16;

% identify useful sequences
task_data.go_seq                             = double(task_data.seq_type == seq_go_type);
task_data.lo_seq                             = double(task_data.seq_type == seq_lo_type);
task_data.igo_seq                            = double(task_data.seq_type == seq_igo_type);
task_data.ilo_seq                            = double(task_data.seq_type == seq_ilo_type); 

% predetermine some useful combinations
task_data.go_gloexp                          = double(task_data.seq_type == seq_go_type & task_data.gloexp & task_data.presentation==4); % global oddball presentations
task_data.lo_gloexp                          = double(task_data.seq_type == seq_lo_type & task_data.gloexp & task_data.presentation==4); % local oddball presentations

task_data.go_rndctl                          = double(task_data.seq_type == seq_go_type & task_data.rndctl & task_data.presentation==4); % 'global oddball' presentation in random control
task_data.lo_rndctl                          = double(task_data.seq_type == seq_lo_type & task_data.rndctl & task_data.presentation==4); % 'local oddball' presentation in random control
task_data.igo_rndctl                         = double(task_data.seq_type == seq_igo_type & task_data.rndctl & task_data.presentation==4); % inverse 'global oddball' presentation in random control [l l l g] insead of [g g g l]
task_data.ilo_rndctl                         = double(task_data.seq_type == seq_ilo_type & task_data.rndctl & task_data.presentation==4); % inverse 'local oddball' presentation in random control [l l l l] insead of [g g g g]

task_data.go_seqctl                          = double(task_data.seq_type == seq_go_type & task_data.seqctl & task_data.presentation==4); % 'global oddball' presentation in sequence control
task_data.igo_seqctl                         = double(task_data.seq_type == seq_igo_type & task_data.seqctl & task_data.presentation==4); % inverse 'local oddball' presentation in sequence control [l l l l] insead of [g g g g]

end