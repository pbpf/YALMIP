function [nnz,ind,val] = pennonm_callback_df(x,model)

M = model.memo;
x = x(:);
if isequal(x,M.x)
    df = M.df;
else
    [f,df] = fmincon_fun(x,model);
end

nnz = length(df);
ind = 1:length(df);
val = full(df);
