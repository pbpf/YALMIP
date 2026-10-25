function isint=isinteger(X)
%ISINTEGER Check if (part of) a variable is integer

S = X.sess;
isint = any(ismember(getvariables(X),S.getIntvariables()));
