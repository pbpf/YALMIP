function sys = uncvarCore(S, varargin)
%UNCVARCORE Create a symbolic uncertain variable in session S
%
%   See also yalmip.Session, SDPVAR

switch numel(varargin)
    case 1
        sys = sdpvarCore(S, varargin{1});
    case 2
        sys = sdpvarCore(S, varargin{1},varargin{2});
    case 3
        sys = sdpvarCore(S, varargin{1},varargin{2},varargin{3});
    case 4
        sys = sdpvarCore(S, varargin{1},varargin{2},varargin{3},varargin{4});
    otherwise
        error('Wrong number of input arguments. See help-text for sdpvar')
end
S.uncVariables = [S.uncVariables getvariables(sys)];
