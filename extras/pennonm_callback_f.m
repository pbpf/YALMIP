function f = pennonm_callback_f(x,model)

% We compute both function value and gradient. If pennon calls later to get
% gradient, it is served from the per-solve memo in the model.
x = x(:);
[f,model.memo.df] = fmincon_fun(x,model);
model.memo.x = x;
