function pnew = degreduce(p,d)
% DEGREDUCE Remove higher order terms

if islinear(p)
    pnew = p;
else
    S = p.sess;
    [sqrList,CompressedList] = S.nonlinearvariables();

    base = getbase(p);
    vars = getvariables(p);

    for i = 1:length(vars)
        v = vars(i);
        if ismember(v,CompressedList(:,1))
            j = find(CompressedList(:,1)==v);
            if sum(any(CompressedList(j,2:end),1))>d
                base(i+1)=0;
            end
        end
    end
    pnew = clean(sdpvarFast(1,1,[],vars,base,S));

end