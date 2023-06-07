classdef IntracellularResponsesTable < types.hdmf_common.DynamicTable & types.untyped.GroupClass
% INTRACELLULARRESPONSESTABLE Table for storing intracellular response related metadata.


% REQUIRED PROPERTIES
properties
    response; % REQUIRED (TimeSeriesReferenceVectorData) Column storing the reference to the recorded response for the recording (rows)
end

methods
    function obj = IntracellularResponsesTable(varargin)
        % INTRACELLULARRESPONSESTABLE Constructor for IntracellularResponsesTable
        varargin = [{'description' 'Table for storing intracellular response related metadata.'} varargin];
        obj = obj@types.hdmf_common.DynamicTable(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'response',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.response = p.Results.response;
        if strcmp(class(obj), 'types.core.IntracellularResponsesTable')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
        if strcmp(class(obj), 'types.core.IntracellularResponsesTable')
            types.util.dynamictable.checkConfig(obj);
        end
    end
    %% SETTERS
    function obj = set.response(obj, val)
        obj.response = obj.validate_response(val);
    end
    %% VALIDATORS
    
    function val = validate_response(obj, val)
        val = types.util.checkDtype('response', 'types.core.TimeSeriesReferenceVectorData', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.DynamicTable(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.response.export(fid, [fullpath '/response'], refs);
    end
end

end