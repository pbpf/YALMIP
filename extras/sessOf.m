function S = sessOf(X)
%SESSOF Safely extract the session handle from any symbolic object
%
%   Legacy-class field access (X.sess) triggers the object's overloaded
%   SUBSREF when done outside its own class methods, so all cross-class
%   reads go through this accessor (direct access / session() dispatch).

S = [];
if isempty(X)
    return
end
if isa(X,'yalmip.Session')
    S = X;
    return
end
if isa(X,'sdpvar') || isa(X,'lmi') || isa(X,'constraint') || isa(X,'optimizer')
    S = session(X);
    return
end
% struct-like payloads (structs in progress, wrapped objects)
try
    w = struct(X);
    if isfield(w,'sess')
        S = w.sess;
    end
catch
end
