function sol = assign(X,value,sol,ls)
%Obsolete, see WARMSTART

if nargin<4
    ls = 0;
end
if nargin<3 || ~(isstruct(sol) && isfield(sol,'eval'))
    error('YALMIP:sessionRequired',['Since the stateless refactoring, pass the solution and capture the result: ', ...
        'sol = assign(x, x0, sol) with sol = optimize(F,obj).'])
end

if ~isa(X,'sdpvar')
    error('First argument should be an SDPVAR object.');
end

if isa(value,'logical')
    value = double(value);
end

if ~isnumeric(value)
    error('Second argument should be NUMERIC.');
end

if prod(size(value)) == 1
    value = repmat(value,size(X));
end

if isempty(value)
    return
end

if min(size(X))==1 && min(size(value))==1 && (length(size(X))==2) && (length(size(value))==2)
    X = reshape(X,[],1);
    value = reshape(value,[],1);
end

if ~isequal(size(X),size(value))
    error('Both arguments must have same size')
end
if ~isa(X,'sdpvar')
    error('First arguments must be an sdpvar object')
end

if is(X,'complex')
    assign(real(X),real(value));
    assign(imag(X),imag(value));
    return
end

x_lmi_variables = X.lmi_variables;
b = value(:)-X.basis(:,1);
A = X.basis(:,2:end);
feas_var = A\b;
% Improve
e = A*feas_var-b;
de = A\e;
feas_var = feas_var-de;

if ~ls
    if norm(A*feas_var-b)>sqrt(eps)
        error('Inconsistent assignment')
    end
end

e = sol.eval;
keep_these = find(~ismember(e.variables,x_lmi_variables));
e.optvar = [e.optvar(keep_these);feas_var(:)];
e.variables = [e.variables(keep_these);x_lmi_variables(:)];
sol.eval = e;



