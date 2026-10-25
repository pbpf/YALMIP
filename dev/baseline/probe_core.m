function probe_core()
addpath(genpath('/media/connor/Data/YALMIP'));
addpath('/opt/mosek/11.2/toolbox/r2019b');
cd('/media/connor/Data/YALMIP');
try
    r = runxunittests('dev/tests/core', 'dev/baseline/probe_core.xml');
    fprintf('runxunittests ok: passed=%d failed=%d\n', sum([r.Passed]), sum(~[r.Passed]));
catch e
    disp(getReport(e, 'extended', 'hyperlinks', 'off'));
end
% Also probe XMLPlugin directly
try
    p = matlab.unittest.plugins.XMLPlugin.producingJUnitFormat('dev/baseline/probe_core2.xml');
    fprintf('XMLPlugin ok\n');
catch e
    disp('XMLPlugin FAILED:');
    disp(getReport(e, 'extended', 'hyperlinks', 'off'));
end
exit(0);
