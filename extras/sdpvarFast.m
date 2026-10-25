function X = sdpvarFast(varargin)
%SDPVARFAST Internal fast-path sdpvar constructor
%
%   sdpvarFast(dim1,dim2,vars,basis,...) builds an sdpvar object without
%   registry registration; optional trailing yalmip.Session argument is
%   stored in the result. Lives outside the @sdpvar folder so that calls
%   with a trailing session are not mis-dispatched to yalmip.Session/sdpvar.

if isa(varargin{end},'yalmip.Session')
    sess = varargin{end};
    varargs = varargin(1:end-1);
else
    sess = [];
    varargs = varargin;
end
switch numel(varargs)
    case 5
        sys.basis = varargs{5};
        sys.lmi_variables = varargs{4};
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
    case 6
        sys.basis = varargs{5};
        sys.lmi_variables = varargs{4};
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
    case 7
        sys.basis = varargs{5};
        sys.lmi_variables = varargs{4};
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
    otherwise
        error('YALMIP:sdpvarInternal','Wrong number of internal fast-path arguments (%d).', numel(varargs))
end
if numel(varargs) ~= 7
    constants = find(sys.lmi_variables==0);
    if ~isempty(constants)
        sys.lmi_variables(constants) = [];
        sys.basis(:,1) = sys.basis(:,1) + sum(sys.basis(:,1+constants),2);
        sys.basis(:,1+constants) = [];
    end
end
sys.sess = sess;
if ~isfield(sys,'name')
    sys.name = '';
end
if isempty(sys.lmi_variables)
    X = full(reshape(sys.basis(:,1),sys.dim(1),sys.dim(2)));
else
    % Finalize through the class constructor (class() requires @sdpvar scope)
    X = sdpvar('finalize',sys);
end
end
