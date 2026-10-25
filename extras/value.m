function varargout = value(varargin)
%VALUE Shadow so that non-method calls resolve to @sdpvar/value

[varargout{1:nargout}] = sdpvar('value', varargin{:});
