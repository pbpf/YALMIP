function reDeclareForBinaryMax(y,X);
S = session(X);
vX = getvariables(X);
B = getbase(X);
vB = S.getBinvariables();
if all(ismember(vX,vB))
    if all(B(:,1)==0)
        if is(X,'lpcone') | is(X,'sdpcone')
            S.setbinvariables([vB getvariables(y)]);
        end
    end
end