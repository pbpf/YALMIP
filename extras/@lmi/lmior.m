function varargout = or(varargin)
%OR (overloaded)

% Models OR using a nonlinear operator definition
switch class(varargin{1})
    case 'char'
        z = varargin{2};
        X = varargin{3};
        Y = varargin{4};
        % The derived variable carries the session on the model.m path; on
        % the expandmeta path z is empty, so take it from the operands
        if isa(z,'sdpvar')
            S = sessOf(z);
        else
            S = sessOf(X);
        end

        F = ([]);
        x = S.binvar(1,1);
        F = F + (implies_internal(x,X));
        y = S.binvar(1,1);
        F = F + (implies_internal(y,Y));

        xy = [x y];
        varargout{1} = F + (sum(xy) >= 1);
        varargout{2} = struct('convexity','none','monotonicity','exact','definiteness','none','extra','marker');
        varargout{3} = recover(depends(F),S);

    case {'lmi'}
        x = varargin{1};
        y = varargin{2};
        varargout{1} = (sessOf(varargin{1}).define('define','lmior',varargin{:}) == 1);

    otherwise
end

end