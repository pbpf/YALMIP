function sys = binvar(varargin)
%BINVAR Create symbolic binary variable (session-based)
%
%   Since the stateless refactoring, variables are created through a
%   session object:
%       S = yalmip.Session();
%       b = S.binvar(3,1);
%
%   See also yalmip.Session, SDPVAR, INTVAR

error('YALMIP:sessionRequired','Create variables via a session: S = yalmip.Session(); b = S.binvar(3,1).')
