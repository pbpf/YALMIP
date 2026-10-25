function [f,df] = knitro_callback_f(x,model)

M = model.memo;
x = x(:);
if isequal(x,M.xF)
    df = M.df;
    f = M.f;
else
    [f,df] = fmincon_fun_liftlayer(x,model);
    M.xF = x;
    M.f = f;
    M.df = df;
end
