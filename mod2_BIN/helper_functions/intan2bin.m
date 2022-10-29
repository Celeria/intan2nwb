function intan2bin(in_file_path, out_file_path, file_name, intan_header, port_letter)

%This file when run, takes intan data in the "One file per channel" format,
%and returns a num_channels x num_samples_total array of binary data
%contained in a single file
%The file can be adjusted for the amount of RAM on your system

%Full path where intan data is located (one file per channel only)
%Open the folder containing the data, so you can see all the .dat files for
%each channel, then copy the filepath in your file explorer and this will
%do the rest
file_name = [out_file_path file_name];

%There is a good chance your data is larger than your computer RAM, this is
%just a good number where everything should fit in memory. If it still
%doesn't work (highly unlikely), make this number smaller
RAM_NUMBER_ADJUSTER = 4;

%This number keeps popping up, its the size in bytes, of an int16, the data
%type we work with
INT_16_SIZE = 2;

%If you are doing this again, and the old file exists, things get messed
%up, so delete the old file before messing with it
if (exist(file_name,'file'))
    delete(file_name);
end

folder_intan = dir(in_file_path);
sampling_rate = intan_header.sampling_rate;
channel_information = intan_header.amplifier_channels;
NUM_CHANNELS = sum(vertcat(intan_header.amplifier_channels.port_prefix) == upper(port_letter));
num_samples = intan_header.num_samples;

%Slice up the data into more manageable pieces, so that large files will
%fit in RAM
try
    slice_size = round(RAM_NUMBER_ADJUSTER * 10e9 / INT_16_SIZE / gcp().NumWorkers / NUM_CHANNELS/ 3);
catch
    slice_size = round(RAM_NUMBER_ADJUSTER * 10e9 / INT_16_SIZE / NUM_CHANNELS/ 3);
end

if(slice_size > num_samples)
    %Everything fits in memory
    fprintf('\nReading intan data files....\n')
    data_to_write = zeros(NUM_CHANNELS,num_samples,'int16');
    parfor ii = 1:NUM_CHANNELS
        current_fid = fopen(string(in_file_path+"\amp-" + upper(port_letter) + "-" + sprintf('%03d',ii-1) + ".dat"));
        data_to_write(ii,:) = int16(fread(current_fid,num_samples,'int16'));
        fclose(current_fid);
    end

    fprintf('\nSaving binary data file...\n')
    writtenFileID = fopen(file_name,'w');
    fwrite(writtenFileID,data_to_write,'int16');
    fclose(writtenFileID);

else
    fprintf('\nData won''t fit in memory, optimizing....\n')

    %Can't fit it all in memory, something tricker needs to happen
    %The structure that's explains where to start reading data each time
    indices = nan(1000000,2);
    remaining_to_deal_with = num_samples;
    indices(1,1) = 1;
    indices(1,2) = slice_size;
    indices_counter = 2;
    remaining_to_deal_with = remaining_to_deal_with - slice_size;
    previous_end = slice_size;
    while remaining_to_deal_with > slice_size
        indices(indices_counter,1) = previous_end + 1;
        previous_end = previous_end + 1;
        indices(indices_counter,2) = previous_end + slice_size;
        previous_end = previous_end + slice_size;
        remaining_to_deal_with = remaining_to_deal_with - slice_size - 1;
        indices_counter = indices_counter + 1;
    end
    indices(indices_counter,1) = previous_end + 1;
    indices(indices_counter,2) = num_samples;
    %The array was arbitrarily large just in case, but this trims it to the
    %exact size necessary
    indices = rmmissing(indices);


    %Break the files into different time blocks, size dependant on how much
    %system RAM you have available, the more, the faster
    writtenFileID = fopen(file_name,'w');
    for data_chunks = 1:height(indices)-1

        %How much data can be fit into memory at once
        data_chunk_length = length(indices(data_chunks,1):indices(data_chunks,2));
        %Store it here temporarily
        data_to_write_this_time = zeros(NUM_CHANNELS,data_chunk_length,'int16');
        %Skip over previously read data
        skip_amount = indices(data_chunks,1)*INT_16_SIZE-INT_16_SIZE;
        parfor ii = 1:NUM_CHANNELS
            current_fid = fopen(string(in_file_path+"\amp-" + upper(port_letter) + "-" + sprintf('%03d',ii-1) + ".dat"),'r');
            %Don't read data that's already been read
            fseek(current_fid,skip_amount,'bof');
            data_to_write_this_time(ii,:) = int16(fread(current_fid,data_chunk_length,'int16'));
            fclose(current_fid);
        end
        %Write it to the binary file
        fwrite(writtenFileID,data_to_write_this_time,'int16');
        fprintf('\nSuccessfully saved %d percent of the data\n',round(data_chunks/height(indices)*100))

    end

    %Deal with the last bit of the data
    last_data_chunk_length = length(indices(end,1):indices(end,2));
    data_to_write_this_time = zeros(NUM_CHANNELS,last_data_chunk_length,'int16');
    skip_amount = indices(end,1)*INT_16_SIZE-INT_16_SIZE;
    parfor ii = 1:NUM_CHANNELS
        current_fid = fopen(string(in_file_path+"\amp-" + upper(port_letter) + "-" + sprintf('%03d',ii-1) + ".dat"),'r');
        fseek(current_fid,skip_amount,'bof');
        data_to_write_this_time(ii,:) = int16(fread(current_fid,last_data_chunk_length,'int16'));
        fclose(current_fid);
    end
    fwrite(writtenFileID,data_to_write_this_time,'int16');
    fprintf('\nSuccessfully saved last of the data, processing complete\n')
    fclose(writtenFileID);
 
end