function sys = parvar(varargin)
%PARVAR Create symbolic parametric variable (session-based)
%
%   Since the stateless refactoring, variables are created through a
%   session object: P = S.parvar(2,3);
%
%   See also yalmip.Session, SDPVAR, UNCVAR

error('YALMIP:sessionRequired','Create variables via a session: S = yalmip.Session(); P = S.parvar(2,3).')
