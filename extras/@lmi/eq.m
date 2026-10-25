function sys = eq(X,Y)
%EQ Overloaded

S = session(X);
dX = S.binvar(1);
dY = S.binvar(1);
sys = [iff(dX,X), iff(dY,Y), dX == dY];
