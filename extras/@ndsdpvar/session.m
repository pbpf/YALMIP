function S = session(X)
%SESSION Session handle of a symbolic object
S = sdpvar(X);
S = S.sess;
