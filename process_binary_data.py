# -*- coding: utf-8 -*-
"""
Created on Wed Jun  7 13:46:32 2023

@author: Patrick, translated from MATLAB by chatgpt-4
"""

import os
import numpy as np
from multiprocessing import Pool
from concurrent.futures import ThreadPoolExecutor

def read_file(params):
    idx, num_samples, in_file_path, port_letter = params
    with open(os.path.join(in_file_path, f"amp-{port_letter.upper()}-{idx:03}.dat"), 'rb') as f:
        mmapped_data = np.memmap(f, dtype=np.int16, mode='r', shape=(num_samples,))
    return mmapped_data

def read_files_threaded(params):
    with ThreadPoolExecutor() as executor:
        results = executor.map(read_file, params)
    return list(results)

def process_binary_files(NUM_CHANNELS, num_samples, in_file_path, port_letter, file_name):
    # Create a memory-mapped array with the same dtype and shape as data_to_write
    fp = np.memmap(file_name, dtype='int16', mode='w+', shape=(num_samples, NUM_CHANNELS))

    # Create a parameter list for all the files
    params = [(idx, num_samples, in_file_path, port_letter) for idx in range(NUM_CHANNELS)]
    params_split = np.array_split(params, os.cpu_count())

    # Create a multiprocessing pool and read all files in parallel
    with Pool() as p:
        results = p.map(read_files_threaded, params_split)

    # Assign the results to the memmapped array
    for sublist in results:
        for ii, result in sublist:
            fp[:, ii] = result

    del fp  # this line ensures any remaining changes are written to disk before removing the object
