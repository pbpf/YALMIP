function sys = intvar(varargin)
%INTVAR Create symbolic integer variable (session-based)
%
%   Since the stateless refactoring, variables are created through a
%   session object:
%       S = yalmip.Session();
%       u = S.intvar(2,3);
%
%   See also yalmip.Session, SDPVAR, BINVAR

error('YALMIP:sessionRequired','Create variables via a session: S = yalmip.Session(); u = S.intvar(2,3).')
