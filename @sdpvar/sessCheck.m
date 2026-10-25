function S = sessCheck(X,Y)
%SESSCHECK Verify two symbolic operands share one session and return it
%   Mixing variables from different yalmip.Session objects is an error:
%   their variable IDs refer to different registries.
S = sess1(X);
if isempty(S)
    S = sess1(Y);
end
if isempty(S)
    error('YALMIP:sessionRequired','No session found on the operands. Create variables via S = yalmip.Session(); x = S.sdpvar(...).');
end

function S = sess1(Z)
% Direct field access works on legacy-class objects; isfield() does not.
S = [];
if isa(Z,'sdpvar')
    try
        S = Z.sess;
    catch
        S = [];
    end
end
