# -*- coding: utf-8 -*-
"""
Created on Wed Jun  7 13:46:32 2023

@author: Patrick, translated from MATLAB by chatgpt-4
"""

def process_binary_files(NUM_CHANNELS, num_samples, in_file_path, port_letter, file_name):

    import numpy as np
    import os

    data_to_write = np.zeros((NUM_CHANNELS, num_samples), dtype=np.int16)

    for ii in range(NUM_CHANNELS):
        with open(os.path.join(in_file_path, f"amp-{port_letter.upper()}-{ii:03}.dat"), 'rb') as current_file:
            data_to_write[ii, :] = np.fromfile(current_file, dtype=np.int16, count=num_samples)

    # Transpose the data to match MATLAB's column-major order
    data_to_write.T.tofile(file_name)