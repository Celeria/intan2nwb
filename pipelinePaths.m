function pp = pipelinePaths(varargin)

% Defaults
pp.DATA_SOURCE  = '\\teba.psy.vanderbilt.edu\bastoslab\_BL_DATA_PIPELINE\_0_RAW_DATA';
pp.DATA_DEST    = '\\teba.psy.vanderbilt.edu\bastoslab\_BL_DATA_PIPELINE\';

pp.RAW_DATA     = 'D:\_BL_DATA_PIPELINE\_0_RAW_DATA\';
pp.CAT_DATA     = 'D:\_BL_DATA_PIPELINE\_1_CAT_DATA\';
pp.BIN_DATA     = 'D:\_BL_DATA_PIPELINE\_2_BIN_DATA\';
pp.SPK_DATA     = 'D:\_BL_DATA_PIPELINE\_3_SPK_DATA\';
pp.SSC_DATA     = 'D:\_BL_DATA_PIPELINE\_4_SSC_DATA\';
pp.CNX_DATA     = 'D:\_BL_DATA_PIPELINE\_5_CNX_DATA\';
pp.NWB_DATA     = 'D:\_BL_DATA_PIPELINE\_6_NWB_DATA\';
pp.EPO_DATA     = 'D:\_BL_DATA_PIPELINE\_7_EPO_DATA\';
pp.FIG_DATA     = 'D:\_BL_DATA_PIPELINE\_9_FIG_DATA\';

pp.CONDA        = 'C:\Users\preprocess-server\anaconda3';
pp.REPO         = 'C:\Users\preprocess-server\Documents\GitHub\pipelinev2\';
pp.TBOXES       = 'C:\Users\preprocess-server\Documents\GitHub\';

pp.SCRATCH      = 'D:\_BL_DATA_PIPELINE\_SCRATCH\';

% Varargin
varStrInd = find(cellfun(@ischar,varargin));                        
for iv = 1:length(varStrInd)
    switch varargin{varStrInd(iv)}
        case {'DATA_SOURCE'}
            pp.DATA_SOURCE = varargin{varStrInd(iv)+1};
        case {'DATA_DEST'}
            pp.DATA_DEST = varargin{varStrInd(iv)+1};
        case {'RAW_DATA'}
            pp.RAW_DATA = varargin{varStrInd(iv)+1};
        case {'CAT_DATA'}
            pp.CAT_DATA = varargin{varStrInd(iv)+1};
        case {'BIN_DATA'}
            pp.BIN_DATA = varargin{varStrInd(iv)+1};
        case {'SPK_DATA'}
            pp.SPK_DATA = varargin{varStrInd(iv)+1};
        case {'SSC_DATA'}
            pp.SSC_DATA = varargin{varStrInd(iv)+1};
        case {'CNX_DATA'}
            pp.CNX_DATA = varargin{varStrInd(iv)+1};
        case {'NWB_DATA'}
            pp.NWB_DATA = varargin{varStrInd(iv)+1};
        case {'EPO_DATA'}
            pp.EPO_DATA = varargin{varStrInd(iv)+1};
        case {'CONDA'}
            pp.CONDA = varargin{varStrInd(iv)+1};
        case {'REPO'}
            pp.REPO = varargin{varStrInd(iv)+1};
        case {'TBOXES'}
            pp.TBOXES = varargin{varStrInd(iv)+1};
        case {'SCRATCH'}
            pp.SCRATCH = varargin{varStrInd(iv)+1};
        case {'pp'}
            pp = varargin{varStrInd(iv)+1};
    end
end

end