function setsos(X,h,ParametricVariables,Q,v)
%SETSOS Internal function

S = X.sess;
S.setsos(X.extra.sosid,h,ParametricVariables,Q,v);
