function sys=islinear(x)
%ISLINEAR Check if variable is linear       
%
% p = islinear(X)
%
% X : SDPVAR object
% p : boolean 0/1

try
    sys = is(x,'linear');
catch
    disp('I have messed up something internally in YALMIP. Sorry...')
    disp('Re-define the problem with variables from a fresh session.');
    disp(' ')
    disp('This problem typically occurs if you have SDPVAR variables in');
    disp('work-space, and call a function where you are using ')
    disp('variables from an old session. When control is returned to');
    disp('the work-space, things are messed up...');
    error('Internal problems in YALMIP');
end