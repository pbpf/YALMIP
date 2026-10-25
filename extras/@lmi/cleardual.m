function id = cleardual(F)

if isempty(sessOf(F))
    error('YALMIP:sessionRequired','Cannot determine the session of this constraint expression.')
end

for i = 1:length(F.LMIid)
    sessOf(F).cleardual(F.LMIid(i));
end
