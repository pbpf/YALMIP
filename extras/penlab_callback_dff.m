function H = penlab_callback_dff(x,model)

M = model.memo;
x = x(:);
if isequal(x,M.xF)
    df = M.df;
else
    [f,df] = fmincon_fun(x,model);
end
