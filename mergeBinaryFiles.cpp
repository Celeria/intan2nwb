#include "mex.h"
#include <iostream>
#include <fstream>
#include <vector>
#include <string>

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

    // Container to hold all data
    std::vector<std::vector<int16_t>> data_to_write(num_channels, std::vector<int16_t>(num_samples, 0));
    std::ifstream current_fid;
    std::string in_file_name;

    for(int ii = 1; ii <= num_channels; ii++) {
        in_file_name = in_file_path + "amp-" + std::string(1, toupper(port_letter[0])) + "-" + std::to_string(ii-1) + ".dat";
        current_fid.open(in_file_name, std::ios::binary);

        // Read binary data
        current_fid.read((char*)&data_to_write[ii - 1][0], num_samples * sizeof(int16_t));
        current_fid.close();
    }

    // Transpose and write to binary file
    std::ofstream written_fid(file_name, std::ios::binary);
    for(int jj = 0; jj < num_samples; jj++) {
        for(int ii = 0; ii < num_channels; ii++) {
            written_fid.write((char*)&data_to_write[ii][jj], sizeof(int16_t)); // Note the transpose operation here
        }
    }
    written_fid.close();
}
