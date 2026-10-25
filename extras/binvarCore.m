function sys = binvarCore(S, varargin)
%BINVARCORE Create a symbolic binary variable in session S
%
%   BINVAR works exactly as SDPVAR, with the only difference that the
%   elements in the variable automatically will be constrained to be
%   binary (0/1) when an optimization problem is solved.
%
%   See also yalmip.Session, SDPVAR, INTVAR

sys = sdpvarCore(S, varargin{:});
if isa(sys,'cell')
    for i = 1:length(sys)
        S.binVariables = [S.binVariables getvariables(sys{i})];
    end
else
    S.binVariables = [S.binVariables getvariables(sys)];
end
