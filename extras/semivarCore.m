function sys = semivarCore(S, varargin)
%SEMIVARCORE Create a semicontinuous variable in session S
%
%   The lower and upper bounds are defined separately.
%
%   See also yalmip.Session, SDPVAR, BINVAR, INTVAR

sys = sdpvar(varargin{:}, 'session', {S});
if isa(sys,'cell')
    for i = 1:length(sys)
        S.semicontVariables = [S.semicontVariables getvariables(sys{i})];
    end
else
    S.semicontVariables = [S.semicontVariables getvariables(sys)];
end
