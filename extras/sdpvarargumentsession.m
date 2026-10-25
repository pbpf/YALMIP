function S = sdpvarargumentsession(varargin)
%SDPVARARGUMENTSESSION Recover the session of the first sdpvar argument
S = [];
for k = 1:numel(varargin)
    if isa(varargin{k},'sdpvar') || isa(varargin{k},'lmi') || isa(varargin{k},'constraint')
        S = sessOf(varargin{k});
        if ~isempty(S)
            return
        end
    end
end
