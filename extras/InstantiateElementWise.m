function y = InstantiateElementWise(funName,varargin);
% InstantiateElementWise is called from session-aware @sdpvar methods. The
% session is recovered from the sdpvar arguments via the public session()
% accessor (no global registry).

if length(varargin{1}) == 1
    S = sdpvarargumentsession(varargin{:});
if isempty(S)
    error('YALMIP:sessionRequired','No session found on the arguments. Create variables via S = yalmip.Session().')
end
y = S.define('define',funName,varargin{:});
else
    y = [];
    args = varargin{1};
    dims = size(args);
    args = args(:);
    Base = getbase(args);
    iD = ~any(Base(:,2:end),2);
    iS = any(Base(:,2:end),2);
    if nnz(iD)>0
        iD = find(iD);
        varargin{1} = args(iD);
        yDoubles = feval(funName,varargin{:});
    else
        yDoubles = [];
        iD = [];
    end
    iS = find(iS);
    args = args(iS);
    for i = 1:length(args)
        varargin{1} = args(i);
        y = [y;S.define('define',funName,varargin{:})];
    end
    y = sparse([iD;iS],ones(length(iD)+length(iS),1),[yDoubles;y],prod(dims),1);
    y = reshape(y,dims);
end