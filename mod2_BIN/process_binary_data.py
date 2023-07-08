# -*- coding: utf-8 -*-
"""
Created on Wed Jun  7 13:46:32 2023

@author: Patrick, translated from MATLAB by chatgpt-4
"""

import numpy as np
import os

def process_binary_data(NUM_CHANNELS, num_samples, in_file_path, port_letter, file_name):
    data_to_write = np.zeros((NUM_CHANNELS, num_samples), dtype=np.int16)

    for ii in range(NUM_CHANNELS):
        with open(os.path.join(in_file_path, f"amp-{port_letter.upper()}-{ii:03}.dat"), 'rb') as current_fid:
            data_to_write[ii, :] = np.fromfile(current_fid, dtype=np.int16, count=num_samples)

    print('\nSaving binary data file...\n')
    with open(file_name, 'wb') as writtenFileID:
        data_to_write.tofile(writtenFileID)
