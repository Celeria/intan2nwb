# -*- coding: utf-8 -*-
"""
Created on Wed Jun  7 13:46:32 2023

@author: Patrick, translated from MATLAB by chatgpt-4
"""
def process_binary_data(NUM_CHANNELS, num_samples, in_file_path, port_letter, file_name, chunk_size=10000000):
    import numpy as np
    import os
    import sys
    
    try:
        # try with original method first
        data_to_write = np.zeros((NUM_CHANNELS, num_samples), dtype=np.int16)
        
        for ii in range(NUM_CHANNELS):
            with open(os.path.join(in_file_path, f"amp-{port_letter.upper()}-{ii:03}.dat"), 'rb') as current_fid:
                data_to_write[ii, :] = np.fromfile(current_fid, dtype=np.int16, count=num_samples)

        print('\nSaving binary data file...\n')
        with open(file_name, 'wb') as writtenFileID:
            data_to_write.tofile(writtenFileID)
            
    except MemoryError:
        print('Not enough memory for original method, trying chunked method...')
        
        # fall back to chunked method
        with open(file_name, 'wb') as writtenFileID:
            for i in range(0, num_samples, chunk_size):
                data_to_write = np.zeros((NUM_CHANNELS, min(chunk_size, num_samples - i)), dtype=np.int16)
                for ii in range(NUM_CHANNELS):
                    with open(os.path.join(in_file_path, f"amp-{port_letter.upper()}-{ii:03}.dat"), 'rb') as current_fid:
                        current_fid.seek(i * np.dtype(np.int16).itemsize)  # skip to the correct position
                        data_to_write[ii, :min(chunk_size, num_samples - i)] = np.fromfile(current_fid, dtype=np.int16, count=min(chunk_size, num_samples - i))
                data_to_write.tofile(writtenFileID)
    except:
        print('Unexpected error:', sys.exc_info()[0])
        raise