function y = ge(X,Y)
%GE (overloaded)

S = sessCheck(X,Y);

try
    y = constraint(X,'>=',Y);
catch
    error(lasterr)
end
