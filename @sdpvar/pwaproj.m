function p = pwaproj(h)

% Rewrites a0+c'*x+sum(f_i(x)) to a0+c'*x+max(aix+bi)

if prod(size(h))>1
    error('pwaproj is currently only applicable to scalars');
end

hvars = getvariables(h);
S = h.sess;
basis = getbase(h);
coefficients = basis(2:end);

Complicating = find(ismember(hvars,S.getExtvariables()));
if length(Complicating)==length(hvars)
    LinearTerm = 0;
else
    NonComplicating = find(~ismember(hvars,S.getExtvariables()));
    LinearTerm = recover(hvars(NonComplicating),S)'*coefficients(NonComplicating)';
end

if isempty(Complicating)
    p = h;
    return
end

basis = getbase(h);
coefficients = basis(2:end);

totalobjective = 0;
totalF = [];
allz = [];
allargs = [];
if ~isempty(Complicating)
    for i = 1:length(Complicating)
        extstruct = S.extstruct(hvars(Complicating(i)));
        [properties{i},F{i},arguments{i}]=model(recover(hvars(Complicating(i)),S));
        RequiresEpi(i) = 1;
        z = S.sdpvar(size(arguments{i},1),size(arguments{i},2));
        allz = [allz;z];
        allargs = [allargs;arguments{i}];
        extstruct.arg{1} = z;
        t = feval(properties{i}{1}.name,z);
        f = str2func(['@' properties{i}{1}.name]);
        t = f(extstruct.arg{1:end-1});
        [dummy{i},thisF]=model(t);
        totalF = totalF + thisF;
        totalobjective=coefficients(Complicating(i))*t+totalobjective;
    end
end
t = S.sdpvar('t',1,1);

totalF = [totalF, totalobjective < t];
P = projection([totalF,t<1234],[allz;t]);

P = full(getbase(P));
b = P(:,1);
A = P(:,2:end);
rmv = find(A(:,end)== 0);
A(rmv,:)=[];
b(rmv) = [];
rmv = find(abs(b-1234)<1e-8);
A(rmv,:)=[];
b(rmv) = [];

p = basis(1)+LinearTerm+max((A(:,1:end-1)*allargs-b)./A(:,end));

