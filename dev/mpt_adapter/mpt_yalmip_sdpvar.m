function varargout = mpt_yalmip_sdpvar(varargin)
%MPT_YALMIP_SDPVAR Session-aware stand-in for bare sdpvar() calls in MPT3.
%
%   X = MPT_YALMIP_SDPVAR(dim1,dim2,...) creates an sdpvar exactly like the
%   bare constructor, but routed through a YALMIP session when the stateless
%   YALMIP refactor is on the path.
%
%   YALMIP's stateless design removed all ambient state: bare sdpvar(...)
%   errors with YALMIP:sessionRequired. MPT3 internals predate that API and
%   cannot be session-aware, so the patched MPT3 call sites (see
%   apply_mpt_adapter.sh) route through this adapter instead. All MPT3
%   variables of one MATLAB process share the single session returned by the
%   private helper below.
%
%   With the pre-refactor (global-state) YALMIP on the path, this falls back
%   to the bare constructor, so the same patched MPT3 tree works with both.
%
%   See also: dev/mpt_adapter/README.md, yalmip.Session.

if exist('yalmip.Session', 'class') == 8
    varargout{1} = mpt_yalmip_session().sdpvar(varargin{:});
else
    varargout{1} = sdpvar(varargin{:});
end
end

function S = mpt_yalmip_session()
%MPT_YALMIP_SESSION Process-wide legacy session for MPT3 internals.
%   Deliberately ambient state: it exists only for third-party code that
%   predates the session API. Nothing in YALMIP itself consults it, and
%   YALMIP's own pipeline never touches this session.
persistent S0
if isempty(S0) || ~isvalid(S0)
    S0 = yalmip.Session();
end
S = S0;
end
