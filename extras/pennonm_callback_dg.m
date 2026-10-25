function [nnz,ind,val] = pennonm_callback_dg(i,x,model)

M = model.memo;

x = x(:);
if ~isequal(M.xG,x)
    % Compute the nonlinear terms in the constraints
    [g,geq,dg,dgeq] = fmincon_con(x,model);
    M.xG = x;

    % Append with linear constraints
    g = [g;geq];
    if ~isempty(model.A)
        g = [g;model.A*x - model.b];
    end
    if ~isempty(model.Aeq)
        g = [g;model.Aeq*x - model.beq];
    end

    % Append with linear terms
    G = [dg';dgeq'];
    if ~isempty(model.A)
        G = [G;model.A];
    end
    if ~isempty(model.Aeq)
        G = [G;model.Aeq];
    end



    start = length(x) - sum((model.K.s).*(model.K.s+1)/2)+1;
    for j = 1:length(model.K.s)
        ni = model.K.s(j);
        T = ones(ni);T = triu(T);
        Ti = find(triu(T));
        xs = x(start:start+ni*(ni+1)/2-1);
        T = T*0;
        T(Ti)=xs;
        X = T+T'-diag(diag(T));
        start = start + ni*(ni+1)/2;
    end
    [cc,cg] = detfun(X,6);



    G(end+1,1)=0;
    g(end+1)=0;

    M.G = G;
    M.g = g;
else
    G = M.G;
end
Gi = G(i+1,:);
[aux,ind,val] = find(Gi);
nnz = length(val);
