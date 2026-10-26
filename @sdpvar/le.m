function y = le(X,Y)
%LE (overloaded)

S = sessCheck(X,Y);

try
    y = constraint(X,'<=',Y);
catch ME
    rethrow(ME)
end
