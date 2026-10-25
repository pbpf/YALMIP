function id = cleardual(F)

if isempty(F.sess)
    error('YALMIP:sessionRequired','Cannot determine the session of this constraint expression.')
end

for i = 1:length(F.LMIid)
    F.sess.cleardual(F.LMIid(i));
end
