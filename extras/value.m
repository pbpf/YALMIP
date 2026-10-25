function x = value(x, varargin) %#ok<INUSD>
%VALUE Identity for non-sdpvar inputs (sdpvar inputs dispatch to @sdpvar/value)
%   Numeric inputs are already their own value; an optional solution payload
%   is accepted and ignored.
