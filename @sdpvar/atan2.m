function varargout = atan2(varargin)

switch class(varargin{1})

    case 'sdpvar'
        S = sessCheck(varargin{1},varargin{2});
        varargout{1} = S.define('define','atan2_internal',[varargin{:}]);
   
    otherwise
        error('SDPVAR/atan2 called with CHAR argument?');
end