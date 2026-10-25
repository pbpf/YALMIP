function S = sdpvarargumentsession(varargin)
%SDPVARARGUMENTSESSION Recover the session of the first sdpvar argument
S = [];
for k = 1:numel(varargin)
    if isa(varargin{k},'sdpvar')
        S = session(varargin{k});
        if ~isempty(S)
            return
        end
    end
end
