function sys = uncvar(varargin)
%UNCVAR Create symbolic uncertain variable (session-based)
%
%   Since the stateless refactoring, variables are created through a
%   session object:
%       S = yalmip.Session();
%       w = S.uncvar(2,2);
%
%   See also yalmip.Session, SDPVAR

error('YALMIP:sessionRequired','Create variables via a session: S = yalmip.Session(); w = S.uncvar(2,2).')
