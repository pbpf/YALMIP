function S = sdpsession(varargin)
%SDPSESSION Session from a trailing argument list (char-branch operators)
%   Operators receive the session as trailing argument; recover it.
S = [];
for k = numel(varargin):-1:1
    if isa(varargin{k},'yalmip.Session')
        S = varargin{k};
        return
    end
    if isa(varargin{k},'sdpvar')
        S = session(varargin{k});
        return
    end
end
