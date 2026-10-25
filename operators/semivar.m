function sys = semivar(varargin)
%SEMIVAR Create semicontinuous variable (session-based)
%
%   Since the stateless refactoring, variables are created through a
%   session object:
%       S = yalmip.Session();
%       z = S.semivar(2,2);
%
%   The lower and upper bounds are defined separately.
%
%   See also yalmip.Session, SDPVAR, BINVAR, INTVAR

error('YALMIP:sessionRequired','Create variables via a session: S = yalmip.Session(); z = S.semivar(2,2).')
