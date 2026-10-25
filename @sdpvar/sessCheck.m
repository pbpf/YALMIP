function S = sessCheck(X,Y)
%SESSCHECK Verify two symbolic operands share one session and return it
%   Mixing variables from different yalmip.Session objects is an error:
%   their variable IDs refer to different registries.
S = [];
if isa(X,'sdpvar') && isfield(X,'sess') && ~isempty(X.sess)
    S = X.sess;
end
if isa(Y,'sdpvar') && isfield(Y,'sess') && ~isempty(Y.sess)
    if isempty(S)
        S = Y.sess;
    elseif S ~= Y.sess
        error('YALMIP:sessionMismatch','Operands belong to different yalmip.Session objects. Create all variables in one expression from the same session.');
    end
end
if isempty(S)
    error('YALMIP:sessionRequired','No session found on the operands. Create variables via S = yalmip.Session(); x = S.sdpvar(...).');
end
