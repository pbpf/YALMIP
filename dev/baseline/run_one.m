function run_one(suite)
%RUN_ONE Run one test suite and store baseline results (Stage 0)
addpath(genpath('/media/connor/Data/YALMIP'));
addpath('/opt/mosek/11.2/toolbox/r2019b');
cd('/media/connor/Data/YALMIP');
try
    r = runxunittests(fullfile('dev','tests',suite), fullfile('dev','baseline',[suite '.xml']));
    summary = [sum(r.Passed), sum(~r.Passed & ~r.Incomplete), sum(r.Incomplete)];
    fprintf('SUITE_RESULT %s passed=%d failed=%d incomplete=%d\n', suite, summary(1), summary(2), summary(3));
    save(fullfile('dev','baseline',[suite '.mat']),'r');
catch e
    fprintf('SUITE_ERROR %s: %s | %s\n', suite, e.identifier, e.message);
    fprintf('%s\n', getReport(e, 'extended', 'hyperlinks', 'off'));
end
exit(0);
