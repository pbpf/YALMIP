function [dG,model] = penlab_callback_matrixdG(x,k,i,model)

x = x(:);

vecG = model.vecF{k}(:,i+1);
dG = reshape(vecG,model.K.s(k),model.K.s(k));
