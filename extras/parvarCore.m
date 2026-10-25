function sys = parvarCore(S, varargin)
%PARVARCORE Create a symbolic parametric variable in session S
%
%   See also yalmip.Session, SDPVAR

switch numel(varargin)
    case 1
        sys = sdpvar(varargin{1},'session',{S});
    case 2
        sys = sdpvar(varargin{1},varargin{2},'session',{S});
    case 3
        sys = sdpvar(varargin{1},varargin{2},varargin{3},'session',{S});
    case 4
        sys = sdpvar(varargin{1},varargin{2},varargin{3},varargin{4},'session',{S});
    otherwise
        error('Wrong number of input arguments. See help-text for sdpvar')
end
S.parVariables = [S.parVariables getvariables(sys)];
