function [f,model] = penlab_callback_f(x,model)

M = model.memo;
x = x(:);
[f,M.df] = fmincon_fun(x,model);
M.xF = x;
