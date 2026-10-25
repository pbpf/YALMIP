function gi = pennonm_callback_g(i,x,model)

M = model.memo;

% Compute the nonlinear terms in the constraints
x = x(:);
if ~isequal(M.xG,x)
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

    G(end+1,end-2)=0;%cg(Ti);
    g(end+1)=0;%X(end-2,end);

    M.G = G;
    M.g = g;

else
    g = M.g;
end
gi = full(g(i+1));
