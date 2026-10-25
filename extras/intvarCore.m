function sys = intvarCore(S, varargin)
%INTVARCORE Create a symbolic integer variable in session S
%
%   INTVAR works exactly as SDPVAR, with the only difference that the
%   elements in the variable automatically will be constrained to be
%   integer when an optimization problem is solved.
%
%   See also yalmip.Session, SDPVAR, BINVAR

sys = sdpvarCore(S, varargin{:});
if isa(sys,'cell')
    for i = 1:length(sys)
        S.intVariables = [S.intVariables getvariables(sys{i})];
    end
else
    S.intVariables = [S.intVariables getvariables(sys)];
end
