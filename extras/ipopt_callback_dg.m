function G = ipopt_callback_dg(x,model)%returnStructOnly,model)
x = x(:);
M = model.memo;
if isequal(x,M.xG)
    % Jacobian was computed already in the call for constraints
    G = M.G;
else
    % Compute the nonlinear terms in the constraints
    [g,geq,dg,dgeq] = fmincon_con_liftlayer(x,model);

    % Append with linear terms
    if isempty(dg)
        G = dgeq';
    else
        G = [dg';dgeq'];
    end

    if ~isempty(model.A)
        G = [G;model.A];
    end
    if ~isempty(model.Aeq)
        G = [G;model.Aeq];
    end
    G = sparse(G);
end
if model.dense
    G = full(G);
end
