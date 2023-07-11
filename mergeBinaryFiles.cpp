#include "mex.h"
#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <iomanip>
#include <sstream>

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    // Check for proper number of input and output arguments
    if(nrhs != 5)
        mexErrMsgTxt("Five input arguments required.");
    if(nlhs > 0)
        mexErrMsgTxt("No output arguments.");

    // Get the inputs from MATLAB
    size_t num_channels = mxGetScalar(prhs[0]);
    size_t num_samples = mxGetScalar(prhs[1]);
    std::string in_file_path(mxArrayToString(prhs[2]));
    std::string port_letter(mxArrayToString(prhs[3]));
    std::string file_name(mxArrayToString(prhs[4]));

    // Determine size of the chunk to process at a time based on available system memory
    size_t chunk_size = 100; // initial chunk size
    try {
        std::vector<std::vector<int16_t>> test(chunk_size, std::vector<int16_t>(num_samples, 0));
    } catch(std::bad_alloc&) {
        chunk_size = num_channels / 10; // adjust chunk_size based on your system's memory capacity
    }

    // Container to hold the chunk of data
    std::vector<std::vector<int16_t>> chunk_data(chunk_size, std::vector<int16_t>(num_samples, 0));
    std::ifstream current_fid;
    std::string in_file_name;
    std::stringstream ss; // Create a stringstream object for string formatting

    // Open output file
    std::ofstream written_fid(file_name, std::ios::binary);

    // Check if file opened successfully
    if (!written_fid.is_open()) {
        mexErrMsgTxt(("Could not open file for writing: " + file_name).c_str());
    }

    for(size_t chunk_start = 1; chunk_start <= num_channels; chunk_start += chunk_size) {
        size_t current_chunk_size = std::min(chunk_size, num_channels - chunk_start + 1);

        for(size_t ii = chunk_start; ii < chunk_start + current_chunk_size; ii++) {
            ss.str(std::string()); // Clear the stringstream
            ss << std::setw(3) << std::setfill('0') << ii-1; // Format the string
            char upper_port_letter = toupper(port_letter[0]);
            in_file_name = in_file_path + "amp-" + upper_port_letter + "-" + ss.str() + ".dat";
            current_fid.open(in_file_name, std::ios::binary);

            // Check if file opened successfully
            if (!current_fid.is_open()) {
                written_fid.close();
                mexErrMsgTxt(("Could not open file: " + in_file_name).c_str());
            }

            // Read binary data
            current_fid.read((char*)&chunk_data[ii - chunk_start][0], num_samples * sizeof(int16_t));

            // Check if read operation was successful
            if (current_fid.fail()) {
                current_fid.close();
                written_fid.close();
                mexErrMsgTxt(("Failed to read from file: " + in_file_name).c_str());
            }
            current_fid.close();
        }

        // Transpose chunk of data in memory
        std::vector<int16_t> chunk_data_transposed(current_chunk_size * num_samples);
        for (size_t i = 0; i < current_chunk_size; i++)
        {
            for (size_t j = 0; j < num_samples; j++)
            {
                // Adjust the calculation for index in transposed data
                chunk_data_transposed[j * num_channels + (chunk_start - 1 + i)] = chunk_data[i][j];
            }
        }

        // Write chunk of data
        written_fid.write((char*)chunk_data_transposed.data(), chunk_data_transposed.size() * sizeof(int16_t));

        // Check if write operation was successful
        if (written_fid.fail()) {
            written_fid.close();
            mexErrMsgTxt(("Failed to write to file: " + file_name).c_str());
        }
    }
    
    written_fid.close();
}
