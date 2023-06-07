# -*- coding: utf-8 -*-
"""
Created on Wed Jun  7 13:46:32 2023

@author: Patrick, translated from MATLAB by chatgpt-4
"""
    

def process_binary_data(num_samples, slice_size, NUM_CHANNELS, INT_16_SIZE, in_file_path, port_letter, file_name):
    
    try:
    import os  
    import numpy as np 
    
    indices = np.full((1000000, 2), np.nan)
    remaining_to_deal_with = num_samples
    indices[0, 0] = 0
    indices[0, 1] = slice_size
    indices_counter = 1
    remaining_to_deal_with -= slice_size
    previous_end = slice_size
    while remaining_to_deal_with > slice_size:
        indices[indices_counter, 0] = previous_end
        previous_end += 1
        indices[indices_counter, 1] = previous_end + slice_size
        previous_end += slice_size
        remaining_to_deal_with -= slice_size + 1
        indices_counter += 1
    indices[indices_counter, 0] = previous_end
    indices[indices_counter, 1] = num_samples
    indices = indices[~np.isnan(indices).any(axis=1)]

    with open(file_name, 'wb') as writtenFileID:
        for data_chunks in range(len(indices) - 1):
            data_chunk_length = len(range(int(indices[data_chunks, 0]), int(indices[data_chunks, 1])))
            data_to_write_this_time = np.zeros((NUM_CHANNELS, data_chunk_length), dtype=np.int16)
            skip_amount = int(indices[data_chunks, 0]) * INT_16_SIZE - INT_16_SIZE
            for ii in range(NUM_CHANNELS):
                with open(f"{in_file_path}amp-{port_letter.upper()}-{str(ii).zfill(3)}.dat", 'rb') as current_fid:
                    current_fid.seek(skip_amount, os.SEEK_SET)
                    data_to_write_this_time[ii, :] = np.fromfile(current_fid, dtype=np.int16, count=data_chunk_length)
            writtenFileID.write(data_to_write_this_time.tobytes())
            print(f"\nSuccessfully saved {round(data_chunks / len(indices) * 100)} percent of the data")

        last_data_chunk_length = len(range(int(indices[-1, 0]), int(indices[-1, 1])))
        data_to_write_this_time = np.zeros((NUM_CHANNELS, last_data_chunk_length), dtype=np.int16)
        skip_amount = int(indices[-1, 0]) * INT_16_SIZE - INT_16_SIZE
        for ii in range(NUM_CHANNELS):
            with open(f"{in_file_path}amp-{port_letter.upper()}-{str(ii).zfill(3)}.dat", 'rb') as current_fid:
                current_fid.seek(skip_amount, os.SEEK_SET)
                data_to_write_this_time[ii, :] = np.fromfile(current_fid, dtype=np.int16, count=last_data_chunk_length)
        writtenFileID.write(data_to_write_this_time.tobytes())
        print("\nSuccessfully saved last of the data, processing complete")
    except Exception as e:
        return(str(e))
#z = process_binary_data(a,b,c,d,e,f,g)