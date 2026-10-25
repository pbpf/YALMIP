function X = ndsdpvar(varargin)
%NDSDPVAR Constructor for multi-dimensional SDPVAR object (session-based)
%
%   Created through a session: X = S.sdpvar(3,3,2) dispatches here with an
%   internal session payload. A single sdpvar argument casts a 2D SDPVAR
%   variable to an nD variable (legacy conversion path).

if numel(varargin) == 1 && isa(varargin{1},'sdpvar')
    X = varargin{1};
    X = struct(X);
    X.conicinfo = [0 0];
    X = class(X,'ndsdpvar');
    return
end

if numel(varargin) >= 2 && isequal(varargin{end-1},'session') && iscell(varargin{end})
    S = varargin{end}{1};
    args = varargin(1:end-2);
    varargin = args;
type  = 'symmetric';
field = 'real';

d = 0;
i = 1;
while i<=numel(varargin)
    if isa(varargin{i},'double')
        d = d + 1;
    end
    i = i + 1;
end

n = [varargin{1:d}];

if numel(varargin) > d
    type = varargin{d+1};
    if n(1)~=n(2) & ~isempty(strmatch_octavesafe(type,'symmetric'))
        error('non-square matrix cannot be symmetric');
    end
else
    if n(1)==n(2)
        type = 'symmetric';
    else
        type = 'full';
    end
end
if numel(varargin) > d+1
    field = varargin{d+2};
end

v0 = S.nvars();
X = S.sdpvar(n(1),n(2),type,field);
vars = getvariables(X);
N = prod(n(3:end));
nNewVars = length(vars)*N;
usedNewVars = v0+(1:nNewVars);
appendYALMIPvariables(S, (vars(end)+1):usedNewVars(end));

X = struct(X);
X.dim = n;
X.basis = [spalloc(size(X.basis,1)*N,1,0) kron(speye(N),X.basis(:,2:end))];
X.lmi_variables = usedNewVars;

X = class(X,'ndsdpvar');
X = clean(X);

    return
end

error('YALMIP:sessionRequired','Create variables via a session: S = yalmip.Session(); X = S.sdpvar(3,3,2).')
