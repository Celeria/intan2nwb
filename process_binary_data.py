# -*- coding: utf-8 -*-
"""
Created on Wed Jun  7 13:46:32 2023

@author: Patrick, translated from MATLAB by chatgpt-4
"""

def process_binary_data(NUM_CHANNELS, num_samples, in_file_path, port_letter, file_name, chunk_size=9000000):
    import numpy as np
    import os
    
    data_to_write = np.zeros((NUM_CHANNELS, chunk_size), dtype=np.int16)

    # Open all the input files
    input_files = [open(os.path.join(in_file_path, f"amp-{port_letter.upper()}-{ii:03}.dat"), 'rb') for ii in range(NUM_CHANNELS)]

    with open(file_name, 'wb') as writtenFileID:
        for i in range(0, num_samples, chunk_size):
            for ii, current_fid in enumerate(input_files):
                data_to_write[ii, :min(chunk_size, num_samples - i)] = np.fromfile(current_fid, dtype=np.int16, count=min(chunk_size, num_samples - i))
            data_to_write[:,:min(chunk_size, num_samples - i)].tofile(writtenFileID)

    # Close all the input files
    for fid in input_files:
        fid.close()
