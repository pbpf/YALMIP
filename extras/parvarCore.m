function sys = parvarCore(S, varargin)
%PARVARCORE Create a symbolic parametric variable in session S
%
%   See also yalmip.Session, SDPVAR

switch numel(varargin)
    case 1
        sys = S.sdpvar(varargin{1});
    case 2
        sys = S.sdpvar(varargin{1},varargin{2});
    case 3
        sys = S.sdpvar(varargin{1},varargin{2},varargin{3});
    case 4
        sys = S.sdpvar(varargin{1},varargin{2},varargin{3},varargin{4});
    otherwise
        error('Wrong number of input arguments. See help-text for sdpvar')
end
S.parVariables = [S.parVariables getvariables(sys)];
