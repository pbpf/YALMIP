function S = session(X)
%SESSION Session handle of an nD SDPVAR object
w = struct(X); % struct() does not trigger subsref
if isfield(w,'sess')
    S = w.sess;
else
    S = [];
end
