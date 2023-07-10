#include "mex.h"
#include <fstream>
#include <vector>
#include <iomanip>
#include <sstream>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    // Arguments validation
    if (nrhs != 4) {
        mexErrMsgIdAndTxt("mexFunction:invalidNumInputs",
                          "Four input arguments required.");
    }
    
    // Retrieve input arguments
    char *in_file_path = mxArrayToString(prhs[0]);
    char *port_letter = mxArrayToString(prhs[1]);
    int NUM_CHANNELS = mxGetScalar(prhs[2]);
    int num_samples = mxGetScalar(prhs[3]);
    char *file_name = mxArrayToString(prhs[4]);

    std::vector<int16_t> data_to_write(NUM_CHANNELS*num_samples);
    
    for (int ii = 1; ii <= NUM_CHANNELS; ++ii) {
        std::ostringstream fileName;
        fileName << in_file_path << "amp-" << port_letter << "-" << std::setfill('0') << std::setw(3) << (ii - 1) << ".dat";
        
        std::ifstream file(fileName.str(), std::ios::binary);
        if (!file) {
            mexErrMsgIdAndTxt("mexFunction:FileOpenError", "Unable to open file");
        }
        
        file.read((char *)&data_to_write[(ii-1)*num_samples], num_samples*sizeof(int16_t));
        file.close();
    }
    
    // Writing the result
    std::ofstream outFile(file_name, std::ios::binary);
    if (!outFile) {
        mexErrMsgIdAndTxt("mexFunction:FileOpenError", "Unable to open output file");
    }

    outFile.write((char *)data_to_write.data(), data_to_write.size()*sizeof(int16_t));
    outFile.close();

    // Clean up
    mxFree(in_file_path);
    mxFree(port_letter);
    mxFree(file_name);
}
