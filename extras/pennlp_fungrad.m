function  [nnz,ind,val] = pennlp_fungrad(x,model)


f = datasaver(2,x,[],model.memo);
[ind,dummy,val] = find(f(:));
nnz = length(ind);
