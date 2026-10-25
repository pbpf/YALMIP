function sys = sdpvar(varargin)
%SDPVAR Create symbolic decision variable (session-based)
%
%   Since the stateless refactoring, variables are created through a
%   session object which owns the variable registry:
%
%       S = yalmip.Session();
%       x = S.sdpvar(3,1);                % Full 3x1
%       x = S.sdpvar("x",3,1);            % With display name
%       P = S.sdpvar(3,3,'symmetric');    % Symmetric 3x3
%       u = S.intvar(2,2);                % Integer (see INTVAR)
%
%   The optional display name (a char/string first argument) is used by
%   SDISPLAY instead of workspace introspection.
%
%   This file retains the internal fast-path constructors used by the
%   operator overloads; they append an optional trailing session argument
%   which is copied into the result.
%
%   See also yalmip.Session, INTVAR, BINVAR, methods('sdpvar')

superiorto('double');

if nargin==0
    error('YALMIP:sessionRequired','Create variables via a session: S = yalmip.Session(); x = S.sdpvar(3,1).')
end

if isstruct(varargin{1})
    sys = class(varargin{1},'sdpvar');
    return
end

% 1-argument copy/convert paths used internally by operator overloads
if nargin==1
    if isa(varargin{1},'sdpvar')
        sys = varargin{1};
        sys.typeflag = 0;
        return
    end
    if isempty(varargin{1})
        sys = varargin{1};
        return
    end
    error('YALMIP:sessionRequired',['Create variables via a session: S = yalmip.Session(); x = S.sdpvar(' num2str(varargin{1}) ').'])
end

% Internal fast paths (5 to 9 arguments). An optional trailing session
% argument is stored in the result so that the session travels with every
% symbolic object created during operator evaluation.
if nargin >= 5
    if isa(varargin{end},'yalmip.Session')
        sess = varargin{end};
        varargs = varargin(1:end-1);
    else
        sess = [];
        varargs = varargin;
    end
    switch numel(varargs)
        case 5 % Fast version for internal use
            sys.basis = varargs{5};
            sys.lmi_variables=varargs{4};
            sys.dim(1) = varargs{1};
            sys.dim(2) = varargs{2};
            sys.typeflag = 0;
            sys.savedata = [];
            sys.extra = [];
            sys.extra.expanded = [];
            sys.extra.opname = '';
            sys.extra.createTime = definecreationtime;
            sys.conicinfo = 0;
            sys.originalbasis = 'unknown';
        case 6 % Fast version for internal use
            sys.basis = varargs{5};
            sys.lmi_variables=varargs{4};
            sys.dim(1) = varargs{1};
            sys.dim(2) = varargs{2};
            sys.typeflag = varargs{6};
            sys.savedata = [];
            sys.extra = [];
            sys.extra.expanded = [];
            sys.extra.opname = '';
            sys.extra.createTime = definecreationtime;
            sys.conicinfo = 0;
            sys.originalbasis = 'unknown';
        case 7 % Fast version for internal use
            sys.basis = varargs{5};
            sys.lmi_variables=varargs{4};
            sys.dim(1) = varargs{1};
            sys.dim(2) = varargs{2};
            sys.typeflag = varargs{6};
            sys.savedata = [];
            sys.extra = varargs{7};
            sys.extra.expanded = [];
            sys.extra.opname = '';
            sys.extra.createTime = '';
            sys.conicinfo = varargs{7};
            sys.originalbasis = 'unknown';
        case 8
            sys = varargs{8};
        otherwise
            error('Wrong number of arguments in sdpvar creation');
    end
    sys.sess = sess;
    if ~isfield(sys,'name')
        sys.name = '';
    end
    % Find zero-variables (not applicable for the struct-passthrough case 8)
    if numel(varargs) ~= 8
        constants = find(sys.lmi_variables==0);
        if ~isempty(constants);
            sys.lmi_variables(constants)=[];
            sys.basis(:,1) = sys.basis(:,1) + sum(sys.basis(:,1+constants),2);
            sys.basis(:,1+constants)=[];
        end
    end
    if isempty(sys.lmi_variables)
        sys = full(reshape(sys.basis(:,1),sys.dim(1),sys.dim(2)));
    else
        sys = class(sys,'sdpvar');
    end
    return
end

% All user-facing creation (1-4 arguments) requires a session.
error('YALMIP:sessionRequired','Create variables via a session: S = yalmip.Session(); x = S.sdpvar(3,1).')
