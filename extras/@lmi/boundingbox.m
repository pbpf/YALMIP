function varargout = boundingbox(F,ops,x,fun_eval)
%BOUNDINGBOX Computes bounding box of a constraint
%
% If only one output is requested, only the symbolic model is returned
%  B = boundingbox(F)
%
% If three outputs are requested, numerical values are returned too
%  [B,L,U] = boundingbox(F)
%
% A second argument can be used to specificy solver settings
%  B = boundingbox(F,sdpsettings('solver','cplex'))
%
% A third argument can (should!) be used to obtain a bounding box in a
% particular set of variables, i.e. the bounding box of a projection.
% Unless you specify which variables you are computing the bounding box
% w.r.t, it will be very hard for you to understand which variables the
% values in L and U relate to
%  [B,L,U] = boundingbox(F,[],x)
% B will now be the box [L <= x <= U] (infinite bounds not included)

S = session(F);

if nargin < 3 | isempty(x)
    x = recover(depends(F),S);
else
    x = x(:);
    if ~isa(x,'sdpvar')
        error('The third argument should be an SDPVAR obeject');
    end
end

if nargin < 2
    ops = sdpsettings('verbose',0);
end
if isempty(ops)
    ops = sdpsettings('verbose',0);
end
if ~isa(ops,'struct')
    error('The second argument should be an SDPSETTINGS struct (or empty)');
end

sol = solvesdp(F,[x;-x],ops);
n = length(x);
sols = {};
vals = {};
for i = 1:n
    xi = x(i);
    if isa(xi,'sdpvar')
        if sol.problem(i)==0
            sI = localSolutionOf(S,i);
            L(i,1) = value(xi,sI);
            if nargin > 3
              sols{end+1} = value(x,sI);
              vals{end+1} = value(fun_eval,sI);
            end
        else
            L(i,1) = -inf;            
        end
        if sol.problem(n+i)==0
            sI = localSolutionOf(S,n+i);
            U(i,1) = value(xi,sI);
            if nargin > 3
              sols{end+1} = value(x,sI);
              vals{end+1} = value(fun_eval,sI);
            end
        else
            U(i,1) = inf;
        end
    else
        L(i,1) = xi;
        U(i,1) = xi;
    end
end

% Only add finite bounds
Lf = find(~isinf(L));
Uf = find(~isinf(U));
B = [];
if ~isempty(Lf)
    xLf = x(Lf);
    if isa(xLf,'sdpvar')
        B = [B, (xLf >= L(Lf)):'Finite lower bounds'];
    end
end
if ~isempty(Uf)
    xUf = x(Uf);
    if isa(xUf,'sdpvar')
        B = [B, (xUf <= U(Uf)):'Finite upper bounds'];
    end
end
varargout{1} = B;
varargout{2} = L;
varargout{3} = U;
varargout{4} = sols;
varargout{5} = vals;
end

function s = localSolutionOf(S,k)
%LOCALSOLUTIONOF Solution k of the just-solved problem, as a payload struct.
% solvesdp_multiple stores one solution per objective on the session; the old
% double(x,k) accessor read the k-th entry of the global solution set, so the
% equivalent here is to select it and snapshot it into a value()-compatible
% struct.
S.selectsolution(k);
s = struct('eval',S.evalSnapshot());
end
