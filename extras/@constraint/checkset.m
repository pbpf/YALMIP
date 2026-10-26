function [p,d] = checkset(X,varargin)
% OBSOLETE USE CHECK(F,SOL)

switch nargout
    case 0
        check(lmi(X),varargin{:});
    case 1
        p = check(lmi(X),varargin{:});
    case 2
        [p,d] = check(lmi(X),varargin{:});
end
