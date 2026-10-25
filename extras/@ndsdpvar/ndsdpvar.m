function X = ndsdpvar(varargin)
%NDSDPVAR Constructor for multi-dimensional SDPVAR object (session-based)
%
%   Since the stateless refactoring, variables are created through a
%   session object: X = S.sdpvar(3,3,2) creates an n-D variable via the
%   ndsdpvar pathway.
%
%   See also yalmip.Session, SDPVAR

error('YALMIP:sessionRequired','Create variables via a session: S = yalmip.Session(); X = S.sdpvar(3,3,2).')
