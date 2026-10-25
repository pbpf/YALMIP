function output = callpennlp(interfacedata)

% Retrieve needed data
options = interfacedata.options;
F_struc = interfacedata.F_struc;
c       = interfacedata.c;
K       = interfacedata.K;
x0      = interfacedata.x0;
Q       = interfacedata.Q;
lb      = interfacedata.lb;
ub      = interfacedata.ub;
monomtable = interfacedata.monomtable;

switch options.verbose
    case 0
        options.fmincon.Display = 'off';
    case 1
        options.fmincon.Display = 'final';
    otherwise
        options.fmincon.Display = 'iter';
end

% Do some pre-calc to be used in calls from pennlp
temp = sum(interfacedata.monomtable,2)>1;
temp = (sum(interfacedata.monomtable,2)==1 & sum(interfacedata.monomtable~=0,2)==1);
nonlinearindicies = find(full(~temp));
linearindicies = find(full(temp));
interfacedata.nonlinearindicies = nonlinearindicies;
interfacedata.linearindicies = linearindicies;

Infinity = 1.0E38;
if isempty(lb)
    lb = -Infinity*ones(length(linearindicies),1);
else
    lb(isinf(lb)) =  -Infinity;
end
if isempty(ub)
    ub = Infinity*ones(length(linearindicies),1);
else
    ub(isinf(ub)) =  Infinity;
end

% Numer of constraints
m = K.l+K.f;
n = length(linearindicies);

lb = lb(linearindicies);
ub = ub(linearindicies);

lbc =  0*ones(m,1);
ubc =  Infinity*ones(m,1);
ubc(1:K.f) = 0;

if isempty(x0)
    x0 = zeros(length(linearindicies),1);
else
    x0 = x0(linearindicies);
end

linearConstraints = ~any(F_struc(1:K.f+K.l,1+nonlinearindicies),2);
if ~isempty(linearConstraints)
    F = F_struc(1:K.f+K.l,:);
    F_struc = [F(~linearConstraints,:);F(linearConstraints,:);F_struc(K.f+K.l+1:end,:)];
    lbc = [lbc(~linearConstraints);lbc(linearConstraints)];
    ubc = [ubc(~linearConstraints);ubc(linearConstraints)];
end

functiondata.nonlinearindicies = nonlinearindicies;
functiondata.linearindicies = linearindicies;
functiondata.monomtable = monomtable;
functionGradientdata.nonlinearindicies = nonlinearindicies;
functionGradientdata.linearindicies = linearindicies;
functionGradientdata.monomtable = monomtable;
functionHessiandata.nonlinearindicies = nonlinearindicies;
functionHessiandata.linearindicies = linearindicies;
functionHessiandata.monomtable = monomtable;

constraintdata.nonlinearindicies = nonlinearindicies;
constraintdata.linearindicies = linearindicies;
constraintdata.monomtable = monomtable;
constraintGradientdata.nonlinearindicies = nonlinearindicies;
constraintGradientdata.linearindicies = linearindicies;
constraintGradientdata.monomtable = monomtable;
constraintHessiandata.nonlinearindicies = nonlinearindicies;
constraintHessiandata.linearindicies = linearindicies;
constraintHessiandata.monomtable = monomtable;

functiondata.F_struc = [interfacedata.f c(:)'];
constraintdata.F_struc = F_struc(1:K.l+K.f,:);start = K.f + K.l + 1;
functionGradientdata.F_struc   = F_struc(start:start+n-1,:);start = start+n;
functionHessiandata.F_struc    = F_struc(start:start+n^2-1,:);start = start+n^2;
constraintGradientdata.F_struc = F_struc(start:start+n*m-1,:);start = start+n*m;
constraintHessiandata.F_struc  = F_struc(start:end,:);start = start+n*m;

% The compiled data and the callback cache live on the per-solve memo
% handle (replaces the former persistent storage in datasaver).
model.memo = yalmip.EvalMemo();
model.memo.payload = struct('savedfunctiondata',functiondata, ...
    'savedfunctionGradientdata',functionGradientdata, ...
    'savedfunctionHessiandata',functionHessiandata, ...
    'savedconstraintdata',constraintdata, ...
    'savedconstraintGradientdata',constraintGradientdata, ...
    'savedconstraintHessiandata',constraintHessiandata, ...
    'm',size(constraintdata.F_struc,1),'n',length(functiondata.linearindicies), ...
    'monomials',[],'x',randn(length(functiondata.linearindicies),1));

Infinity = 1.0E38;
pen.nvars = n;
pen.nlin = length(find(linearConstraints));
pen.nconstr = m;
pen.nnz_gradient = n;
pen.nnz_hessian = (n+1)*n/2;
pen.lbv = lb(:)';
pen.ubv = ub(:)';
pen.lbc = lbc(:)';
pen.ubc = ubc(:)';
pen.xinit= x0(:)';
% Compiled data is passed to the callbacks via function handles (no
% persistent or global variables).
pen.my_f = @(x) pennlp_fun(x,model);
pen.my_f_gradient = @(x) pennlp_fungrad(x,model);
pen.my_f_hessian = @(x) pennlp_funhess(x,model);
pen.my_g = @(i,x) pennlp_con(i,x,model);
pen.my_g_gradient = @(i,x) pennlp_congrad(i,x,model);
pen.my_g_hessian =  @(i,x) pennlp_conhess(i,x,model);

ops = struct2cell(options.pennlp);ops = [ops{1:end}];
pen.ioptions = [ops(1:2) options.verbose ops(3:15)];
if options.verbose>0
    pen.ioptions(3) = pen.ioptions(3)+1;
end
pen.doptions = ops(16:end);

%pen.ioptions = ops(1:15);
%pen.foptions = ops(16:end);
%pen.ioptions(4) = max(0,min(3,options.verbose+1));

%pen.ioptions = [100 100 2 0 0 0 1 0 0 2 0 0 0 -1 0 1];
%pen.doptions = [1.0E-7 1.0E0 1.0E-0 1.0E-2 5.0E-1 1.0E-1 1.0E-6 1.0E-12 1.0e-1 0.05 1.0 1.0 1.0];

if options.savedebug
    save pennlpdebug pen
end

showprogress('Calling PENNLP',options.showprogress);

solvertime = tic;
[obj,xout,duals,flag] = pennlpm(pen);
solvertime = toc(solvertime);

if isempty(nonlinearindicies)
    x = xout(:);
else
    x = zeros(length(interfacedata.c),1);
    for i = 1:length(linearindicies)
        x(linearindicies(i)) = xout(i);
    end
end

switch flag
    case 0
        problem = 0;
    case {1,6,7}
        problem = 4;
    otherwise
        problem = 9;
end

% Internal format for duals
D_struc = [];

% Save all data sent to solver?
if options.savesolverinput
    solverinput.pen = pen;
else
    solverinput = [];
end

% Save all data from the solver?
if options.savesolveroutput
    solveroutput.obj = obj;
    solveroutput.xout = xout;
    solveroutput.duals = duals;
    solveroutput.flag = flag;
else
    solveroutput = [];
end

% Standard interface 
output = createOutputStructure(x,D_struc,[],problem,interfacedata.solver.tag,solverinput,solveroutput,solvertime);
