function [G,model] = penlab_callback_matrixG(x,k,model)

M = model.memo;
x = x(:);

if isequal(x,M.xXevaled)
    xevaled = M.xevaled;
else
    xevaled = zeros(1,length(model.c));
    xevaled(model.linearindicies) = x;
    xevaled = apply_recursive_evaluation(model,xevaled);
    M.xXevaled = x;
    M.xevaled = xevaled;
end

vecG = model.vecF{k}*[1;xevaled];
G = reshape(vecG,model.K.s(k),model.K.s(k));
