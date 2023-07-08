# -*- coding: utf-8 -*-
"""
Created on Wed Jun  7 13:46:32 2023

@author: Patrick, translated from MATLAB by chatgpt-4
"""

def process_binary_files(NUM_CHANNELS, num_samples, in_file_path, port_letter, file_name):
    import numpy as np
    from concurrent.futures import ProcessPoolExecutor
    import os

    data_to_write = np.zeros((NUM_CHANNELS, num_samples), dtype=np.int16)

    def read_data(ii):
        with open(os.path.join(in_file_path, f"amp-{port_letter.upper()}-{ii:03}.dat"), 'rb') as current_file:
            return np.fromfile(current_file, dtype=np.int16, count=num_samples)

    with ProcessPoolExecutor() as executor:
        for ii, data in enumerate(executor.map(read_data, range(NUM_CHANNELS)), 1):
            data_to_write[ii-1, :] = data

    data_to_write.tofile(file_name)