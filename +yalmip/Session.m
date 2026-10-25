classdef Session < handle
%SESSION Stateless YALMIP session holding the variable registry and solver state.
%
%   Since the stateless refactoring, YALMIP keeps no global or persistent
%   variables. All symbolic state (the variable registry, monomial table,
%   integer/binary declarations, extended operator map, solution stack,
%   duals, ...) lives in a Session object:
%
%       S = yalmip.Session();
%       x = S.sdpvar("x",[3 1]);
%       u = S.intvar(2,2);
%       F = [x >= 0, sum(u) <= 5];
%       sol = optimize(F);          % session discovered from F
%       v  = value(x, sol);
%
%   Sessions are handle objects: the session reference travels with the
%   symbolic objects created from it (their "sess" field), so optimize and
%   the internal pipeline recover it without any global state. Multiple
%   independent sessions can coexist; mixing objects from different
%   sessions in one expression is an error.
%
%   The methods below implement the commands of the former yalmip.m
%   string-command dispatcher.

    properties
        monomtable = []                 % polynomial powers table (variable ID = row)
        hashedmonomtable = []
        hash = []
        boundlist = []
        variabletype = []               % linear/quad/poly/signomial classification
        intVariables = []
        binVariables = []
        tempintVariables = []
        tempbinVariables = []
        semicontVariables = []
        uncVariables = []
        parVariables = []
        extVariables = []
        auxVariables = []
        auxVariablesW = []
        logicVariables = []
        complexpair = []
        internalconstraints = {}
        ExtendedMap = []
        ExtendedMapHashes = []
        DependencyMap = []
        DependencyMap_i = []
        DependencyMap_j = []
        DependencyMapUser = []
        sosid = 0
        sos_index = []
        sos_data = []
        sos_ParV = []
        sos_Q = []
        sos_v = []
        optSolution = {}
        activeSolution = 1
        nonCommutingTable = []
        nonHermitiannonCommutingTable = []
        containsSemivar = false
        LMIid = 0
        duals_index = []
        duals_data = []
        duals_associated_index = []
        duals_associated_data = []
        preferedSolver = ''
        solverCache = []                % deduplicated solver-scan cache
        variableNames = {}              % display name per variable id (from S.sdpvar("name",...))
        variableNameIndex = []          % element position within its variable
    end

    properties (Access = private)
        gemFound = []
    end

    methods
        function S = Session()
            S.monomtable = spalloc(0,0,0);   % Polynomial powers table
            S.hashedmonomtable = [];
            S.hash = [];
            S.boundlist = [];
            S.variabletype = spalloc(0,0,0); % Pre-calc linear/quadratic/polynomial/signomial
            S.intVariables = [];
            S.binVariables = [];
            S.tempintVariables = [];
            S.tempbinVariables = [];
            S.semicontVariables = [];
            S.uncVariables = [];
            S.parVariables = [];
            S.extVariables = [];
            S.auxVariables = [];
            S.auxVariablesW = [];
            S.logicVariables = [];
            S.complexpair = [];
            S.internalconstraints = {};
            S.ExtendedMap = [];
            S.ExtendedMapHashes = [];
            S.DependencyMap = sparse(0);
            S.DependencyMap_i = [];
            S.DependencyMap_j = [];
            S.DependencyMapUser = sparse(0);
            S.sosid = 0;
            S.sos_index = [];
            S.sos_data = [];
            S.sos_ParV = [];
            S.sos_Q = [];
            S.sos_v = [];
            S.optSolution = {struct('info','Initialized by YALMIP','variables',[],'optvar',[],'values',[])};
            S.activeSolution = 1;
            S.nonCommutingTable = [];
            S.nonHermitiannonCommutingTable = [];
            S.containsSemivar = false;
            S.LMIid = 0;
            S.duals_index = [];
            S.duals_data = [];
            S.duals_associated_index = [];
            S.duals_associated_data = [];
            S.preferedSolver = '';
            S.solverCache = struct('CACHED_SOLVERS',[],'allsolvers',[],'EXISTTIME',[],'NCHECKS',[]);
            S.variableNames = {};
            S.variableNameIndex = [];
        end

        function registerVariablenames(obj, displayname, ids)
            %REGISTERVARIABLENAMES Store the display name of a new variable
            for k = 1:numel(ids)
                obj.variableNames{ids(k)} = displayname;
                obj.variableNameIndex(ids(k)) = k;
            end
        end

        function n = getvariablenames(obj, ids)
            %GETVARIABLENAMES Display names (with element indexing) for ids
            n = cell(length(ids),1);
            for k = 1:length(ids)
                nm = '';
                idx = 0;
                if ids(k) >= 1 && ids(k) <= length(obj.variableNames)
                    nm = obj.variableNames{ids(k)};
                    if ids(k) <= length(obj.variableNameIndex)
                        idx = obj.variableNameIndex(ids(k));
                    end
                end
                if isempty(nm)
                    n{k} = ['internal(' num2str(ids(k)) ')'];
                elseif idx > 1
                    n{k} = sprintf('%s(%d)', nm, idx);
                else
                    n{k} = nm;
                end
            end
        end


        % ----- variable creation -----------------------------------------
        function X = sdpvar(obj, varargin)
            X = sdpvarCore(obj, varargin{:});
        end

        function X = intvar(obj, varargin)
            X = intvarCore(obj, varargin{:});
        end

        function X = binvar(obj, varargin)
            X = binvarCore(obj, varargin{:});
        end

        function X = uncvar(obj, varargin)
            X = uncvarCore(obj, varargin{:});
        end

        function X = semivar(obj, varargin)
            X = semivarCore(obj, varargin{:});
        end

        % ----- state snapshots -------------------------------------------
        function s = snapshotState(obj)
            %SNAPSHOTSTATE Copy of all registry fields (former getinternalsdpvarstate)
            s = struct();
            f = properties(obj);
            for i = 1:numel(f)
                if strcmp(f{i},'gemFound'); continue; end
                s.(f{i}) = obj.(f{i});
            end
        end

        function restoreState(obj, s)
            %RESTORESTATE Write a snapshot back (former setinternalsdpvarstate)
            f = properties(obj);
            for i = 1:numel(f)
                if strcmp(f{i},'gemFound'); continue; end
                if isfield(s,f{i})
                    obj.(f{i}) = s.(f{i});
                end
            end
        end

        function r = gemInPath(obj, varargin)
            %GEMINPATH Cached detection of the high-precision gem class
            if nargin >= 2
                switch varargin{1}
                    case 'clear'
                        obj.gemFound = [];
                    otherwise
                        disp('Invalid command for gemInPath');
                end
                return;
            end
            if isempty(obj.gemFound)
                obj.gemFound = (exist('gem', 'class') == 8);
            end
            r = logical(obj.gemFound);
        end

        function c = evalSnapshot(obj)
            %EVALSNAPSHOT Payload attached to optimize() output so VALUE/DUAL
            % can evaluate expressions without global state.
            c = struct();
            c.monomtable = obj.monomtable;
            c.variabletype = obj.variabletype;
            sol = obj.optSolution{obj.activeSolution};
            c.variables = sol.variables;
            c.optvar = sol.optvar;
            c.values = sol.values;
            c.duals_index = obj.duals_index;
            c.duals_data = obj.duals_data;
        end

    function varargout = clearsolution(obj, varargin)
    obj.optSolution{1}.variables = [];
    obj.optSolution{1}.optvar  =[];
    obj.optSolution{1}.values  =[];
    obj.activeSolution = 1;
    obj.tempintVariables = [];   
    obj.tempbinVariables = [];   
    obj.intVariables = [];   
    obj.binVariables = [];   
    end

    function varargout = getMonomtable(obj, varargin)
    varargout{1} = obj.monomtable;
    n = size(obj.monomtable,1);
    if size(obj.monomtable,2) < n
        % Normalize the monomtalbe. Some external functions presume the
        % table is square
        varargout{1}(n,n) = 0;
        obj.monomtable = varargout{1};
        need_new = size(obj.monomtable,1) - length(obj.hash);            
        obj.hash = [obj.hash ; 3*gen_rand_hash(size(obj.monomtable,1),need_new,1)];
        obj.hashedmonomtable = obj.monomtable*obj.hash;
    end
    if nargout == 2
        varargout{2} = obj.variabletype;
    elseif nargout == 4
        varargout{2} = obj.variabletype;
        varargout{3} = obj.hashedmonomtable;
        varargout{4} = obj.hash;
    end
    end

    function varargout = setmonomtable(obj, varargin)
    % New monom table
    obj.monomtable = varargin{1};
    if (nargin+1)>=4
        % User has up-dated the hash tables him self.
        obj.hashedmonomtable=varargin{3};
        obj.hash = varargin{4};
    end
    if size(obj.monomtable,2)>length(obj.hash)
        need_new = size(obj.monomtable,1) - length(obj.hash);
        obj.hash = [obj.hash ; 3*gen_rand_hash(size(obj.monomtable,1),need_new,1)];
    end
    if size(obj.monomtable,1)>size(obj.hashedmonomtable,1)
        % Need to add some hash values
        need_new = size(obj.monomtable,1) - size(obj.hashedmonomtable,1);
        temp = obj.monomtable(end-need_new+1:end,:);
        obj.hashedmonomtable = [obj.hashedmonomtable;temp*obj.hash];
    end
    if (nargin+1) >= 3 && ~isempty(varargin{2})
        obj.variabletype = varargin{2};
        if length(obj.variabletype) ~=size(obj.monomtable,1)
            error('ASSERT')
        end
    else
        obj.variabletype = zeros(size(obj.monomtable,1),1)';
        nonlinear = ~(sum(obj.monomtable,2)==1 & sum(obj.monomtable~=0,2)==1);
        if ~isempty(nonlinear)
            %mt = obj.monomtable;
            obj.variabletype(nonlinear) = 3;
            quadratic = sum(obj.monomtable,2)==2;
            obj.variabletype(quadratic) = 2;
            bilinear = max(obj.monomtable,[],2)<=1;
            obj.variabletype(bilinear & quadratic) = 1;
            signomial = any(0>obj.monomtable,2) | any(obj.monomtable-fix(obj.monomtable),2);
            obj.variabletype(signomial) = 4;
        end
    end
    end

    function varargout = getVariabletype(obj, varargin)
    varargout{1} = obj.variabletype;
    end

    %% ALIASGROUP addextendedvariable|addEvalVariable
    function varargout = addextendedvariable(obj, varargin)
    varargin{1}
    disp('Obsolete use of the terms addextendedvariable and addEvalVariable');
    error('Obsolete use of the terms addextendedvariable and addEvalVariable');
    end

    function varargout = defineVectorizedUnitary(obj, varargin)
    varargin{1} = strrep(varargin{1},'sdpvar/',''); % Clean due to different behaviour of the function mfilename in ML 5,6 and 7
    
    % Is this operator variable already defined
    correct_operator = [];
    if ~isempty(obj.ExtendedMap)
                                          
        OperatorName = varargin{1};
        Arguments = {varargin{2:end}};
        this_hash = create_trivial_hash(firstSDPVAR(Arguments));
        correct_operator = find([obj.ExtendedMapHashes == this_hash]);
        
        if ~isempty(correct_operator)
            correct_operator = correct_operator(strcmp(OperatorName,{obj.ExtendedMap(correct_operator).fcn}));
        end
                                                                     
        for i = correct_operator                
            if this_hash == obj.ExtendedMap(i).Hash
                if isequaln(Arguments, {obj.ExtendedMap(i).arg{1:end-1}});
                    if length(obj.ExtendedMap(i).computes)>1
                        varargout{1} =  recover(obj.ExtendedMap(i).computes);
                    else
                        varargout{1} =  obj.ExtendedMap(i).var;
                    end
                    varargout{1} = setoperatorname(varargout{1},varargin{1});
                    return
                end
            end
        end
    else
        this_hash = create_trivial_hash(firstSDPVAR({varargin{2:end}}));
    end
    
    X = varargin{2:end};
    if is(X,'unitary')
        allXunitary = 1;
    else
        allXunitary = 0;
    end
    y = sdpvarCore(obj, numel(X),1);
    allNewExtended = [];
    allNewExtendedIndex = [];
    allPreviouslyDefinedExtendedToIndex = [];
    allPreviouslyDefinedExtendedFromIndex = [];
    if ~isempty(obj.ExtendedMap)
        correct_operator = find(strcmp(varargin{1},{obj.ExtendedMap(:).fcn}));
    end
            
    z = sdpvarCore(obj, numel(X),1); % Standard format     y=f(z),z==arg
    
    obj.auxVariables = [ obj.auxVariables  getvariables(z)];
    obj.auxVariables = [ obj.auxVariables  getvariables(y)];
    
    vec_hashes = create_trivial_vechash(X);
    vec_isdoubles = create_vecisdouble(X);
    
    if isempty(correct_operator)
        availableHashes  = [];
    else
        availableHashes = [obj.ExtendedMap(correct_operator).Hash];
    end
    
    if isempty(availableHashes) &&  length(vec_hashes)>1 && all(diff(sort(vec_hashes))>0)
        simpleAllDifferentNew = 1;
    else
        simpleAllDifferentNew = 0;
    end
    
    for i = 1:numel(X)
        % we have to search through all scalar operators
        % to find this single element
        found = 0;            
        Xi = [];
        
        if ~simpleAllDifferentNew
            if vec_isdoubles(i)
                found = 1;
                y(i) = feval(varargin{1},X(i));
            else
                if ~isempty(correct_operator)
                    this_hash = vec_hashes(i);
                    correct_hash = correct_operator(find(this_hash == availableHashes));
                    
                    if ~isempty(correct_hash)
                        Xi = X(i);
                    end
                    for j = correct_hash(:)'
                        if isequal(Xi,obj.ExtendedMap(j).arg{1},1)
                            allPreviouslyDefinedExtendedToIndex = [allPreviouslyDefinedExtendedToIndex i];
                            allPreviouslyDefinedExtendedFromIndex = [allPreviouslyDefinedExtendedFromIndex j];
                            found = 1;
                            break
                        end
                    end
                end
            end
        end
        
        if ~found
            if vec_isdoubles(i)                    
                y(i) = feval(varargin{1},X(i));
            else
            yi = y(i);
            if isempty(Xi)
                 Xi = X(i);
            end
            obj.ExtendedMap(end+1).fcn = varargin{1};
            if allXunitary
                 obj.ExtendedMap(end).arg = {Xi,[]};
            else
                if is(Xi,'unitary')
                obj.ExtendedMap(end).arg = {Xi,[]};
            else
                obj.ExtendedMap(end).arg = {Xi,z(i)};
                end
            end
            obj.ExtendedMap(end).var = yi;
            obj.ExtendedMap(end).computes = getvariables(yi);
            new_hash = create_trivial_hash(Xi);
            obj.ExtendedMap(end).Hash = new_hash;
            obj.ExtendedMapHashes = [obj.ExtendedMapHashes new_hash];
				obj.containsSemivar = obj.containsSemivar | strcmp(varargin{1}, 'semivar');
            allNewExtendedIndex = [allNewExtendedIndex i];
            availableHashes = [availableHashes new_hash];
            correct_operator = [correct_operator length( obj.ExtendedMap)];
             end
        end
    end

    y(allPreviouslyDefinedExtendedToIndex) = [obj.ExtendedMap(allPreviouslyDefinedExtendedFromIndex).var];
    allNewExtended = y(allNewExtendedIndex);
    y_vars = getvariables(allNewExtended);
    obj.extVariables = [obj.extVariables y_vars];
    y = reshape(y,size(X,1),size(X,2));
    y = setoperatorname(y,varargin{1});
    varargout{1} = y;     

    yV = getvariables(y);
    yB = getbase(y);yB = yB(:,2:end);
    xV = getvariables(X);
    xB = getbase(X);xB = xB(:,2:end);
    %obj.DependencyMap(max(yV),max(xV))=sparse(0);
    for i = 1:length(yV)
        ii = yV(find(yB(i,:)));
        jj = xV(find(xB(i,:)));
        obj.DependencyMap_i = [obj.DependencyMap_i repmat(ii,1,length(jj))];
        obj.DependencyMap_j = [obj.DependencyMap_j jj(:)'];
      %  obj.DependencyMap(yV(find(yB(i,:))),xV(find(xB(i,:))))=1;
    end        
    return
    end

    %% ALIASGROUP define|definemulti
    function varargout = define(obj, varargin)
    %DEFINE Define an extended operator variable (command string first:
    % 'define' or 'definemulti', mirroring the former dispatcher payload)
    varargout = obj.defineImpl(varargin{:});
    end

    function varargout = defineImpl(obj, varargin)
    if strcmpi(varargin{1},'define')
        multioutput = 0;
        nout = [1 1];
    else
        multioutput = 1;
        nout = varargin{end};
        varargin = {varargin{1:end-1}};            
    end
    
    for i = 1:length(varargin)
        if isa(varargin{i},'sdpvar')
            varargin{i} = clearcreationtime(varargin{i});
            varargin{i} = clearconicinfo(varargin{i});
        end
    end
    
    varargin{2} = strrep(varargin{2},'sdpvar/',''); % Clean due to different behaviour of the function mfilename in ML 5,6 and 7
    
    % Is this operator variable already defined
    correct_operator = [];
    if ~isempty(obj.ExtendedMap)
                                          
        OperatorName = varargin{2};
        Arguments = {varargin{3:end}};
        this_hash = create_trivial_hash(firstSDPVAR(Arguments));
        correct_operator = find([obj.ExtendedMapHashes == this_hash]);
        
        if ~isempty(correct_operator)
            correct_operator = correct_operator(strcmp(OperatorName,{obj.ExtendedMap(correct_operator).fcn}));
        end
                                                                     
        for i = correct_operator
            if isequaln(Arguments, {obj.ExtendedMap(i).arg{1:end-1}});
                if length(obj.ExtendedMap(i).computes)>1
                    varargout{1} =  recover(obj.ExtendedMap(i).computes);
                else
                    varargout{1} =  obj.ExtendedMap(i).var;
                end
                varargout{1} = setoperatorname(varargout{1},varargin{2});
                return
            end
        end
    else
        this_hash = create_trivial_hash(firstSDPVAR({varargin{3:end}}));
    end
    
    switch varargin{2}
        
        case {'max_internal'}
            % MAX is a bit special since we need one
            % new variable for each column...
            % (can be implemented standard way, but this is better
            % for performance, and since MAX is so common...
            X = varargin{3:end};
            [n,m] = size(X);
            if min([n m]) == 1
                y = sdpvarCore(obj, 1,1);
                obj.ExtendedMap(end+1).fcn = varargin{2};
                obj.ExtendedMap(end).arg = {varargin{3:end},[]};
                obj.ExtendedMap(end).var = y;
                obj.ExtendedMap(end).computes = getvariables(y);
                obj.extVariables = [obj.extVariables getvariables(y)];
                obj.ExtendedMap(end).Hash = this_hash;
                obj.ExtendedMapHashes = [obj.ExtendedMapHashes this_hash];
            else
                y = sdpvarCore(obj, 1,m);
                for i = 1:m
                    if isa(X(:,i),'double')
                        y(i) = max(X(:,i));
                    else
                        obj.ExtendedMap(end+1).fcn = varargin{2};
                        obj.ExtendedMap(end).arg = {X(:,i),[]};
                        obj.ExtendedMap(end).var = y(i);
                        obj.ExtendedMap(end).computes = getvariables(y(i));
                        new_hash = create_trivial_hash(X(:,i));
                        obj.ExtendedMap(end).Hash = new_hash;
                        obj.ExtendedMapHashes = [obj.ExtendedMapHashes new_hash];
                    end
                end
                obj.extVariables = [obj.extVariables getvariables(y)];
            end
            y = setoperatorname(y,varargin{2});
            
        case {'abs'}
            % ABS is a bit special since we need one
            % new variable for each element...
            X = varargin{3:end};
            y = sdpvarCore(obj, numel(X),1);
            allNewExtended = [];
            allNewExtendedIndex = [];
            allPreviouslyDefinedExtendedToIndex = [];
            allPreviouslyDefinedExtendedFromIndex = [];
            if ~isempty(obj.ExtendedMap)
                correct_operator = find(strcmp(varargin{2},{obj.ExtendedMap(:).fcn}));
            end
            if numel(X)==1
                found = 0;
                if ~isempty(correct_operator)
                    this_hash = create_trivial_hash(X);
                    for j = correct_operator;% find(correct_operator)
                        if this_hash == obj.ExtendedMap(j).Hash
                            if isequal(X,obj.ExtendedMap(j).arg{1},1)
                                %  y = obj.ExtendedMap(j).var;
                                allPreviouslyDefinedExtendedToIndex = [1];
                                allPreviouslyDefinedExtendedFromIndex = [j];
                                found = 1;
                                break
                            end
                        end
                    end
                end
                if ~found
                    obj.ExtendedMap(end+1).fcn = varargin{2};
                    obj.ExtendedMap(end).arg = {X,binvarCore(obj, 1),[]};
                    obj.ExtendedMap(end).var = y;
                    obj.ExtendedMap(end).computes = getvariables(y);
                    new_hash = create_trivial_hash(X);
                    obj.ExtendedMap(end).Hash = new_hash;
                    obj.ExtendedMapHashes = [obj.ExtendedMapHashes new_hash];
                    allNewExtended = y;
                    allNewExtendedIndex = 1;
                end
            else
                aux_bin = binvarCore(obj, numel(X),1);
                vec_hashes = create_trivial_vechash(X);
                vec_isdoubles = create_vecisdouble(X);
                for i = 1:numel(X)
                    % This is a bummer. If we scalarize the abs-operator,
                    % we have to search through all scalar abs-operators
                    % to find this single element
                    found = 0;
                    Xi = X(i);
                    if vec_isdoubles(i)%isa(Xi,'double')
                        found = 1;
                        y(i) = abs(X(i));
                    else
                        if ~isempty(correct_operator)
                            this_hash = vec_hashes(i);                                
                            j = correct_operator(find(this_hash == obj.ExtendedMapHashes(correct_operator)));
                            if ~isempty(j)
                                for matches = 1:length(j)
                                    if isequal(Xi,obj.ExtendedMap(j(matches)).arg{1},1)
                                        allPreviouslyDefinedExtendedToIndex = [allPreviouslyDefinedExtendedToIndex i];
                                        allPreviouslyDefinedExtendedFromIndex = [allPreviouslyDefinedExtendedFromIndex j];
                                        found = 1;                                        
                                        break
                                    end    
                                end
                            end
                        end
                    end
                    if ~found
                        yi = y(i);
                        obj.ExtendedMap(end+1).fcn = varargin{2};
                        obj.ExtendedMap(end).arg = {Xi,aux_bin(i),[]};
                        obj.ExtendedMap(end).var = yi;
                        obj.ExtendedMap(end).computes = getvariables(yi);
                        new_hash = create_trivial_hash(Xi);
                        obj.ExtendedMap(end).Hash = new_hash;
                        obj.ExtendedMapHashes = [obj.ExtendedMapHashes new_hash];
                        allNewExtendedIndex = [allNewExtendedIndex i];
                        % Add this to the list of possible matches.
                        % Required for repeated elements in argument
                        % (such as a symmetric matrix)
                        correct_operator = [correct_operator length(obj.ExtendedMap)];
                    end
                end
            end
            y(allPreviouslyDefinedExtendedToIndex) = [obj.ExtendedMap(allPreviouslyDefinedExtendedFromIndex).var];
            allNewExtended = y(allNewExtendedIndex);
            y_vars = getvariables(allNewExtended);
            obj.extVariables = [obj.extVariables y_vars];
            y = reshape(y,size(X,1),size(X,2));
            y = setoperatorname(y,varargin{2});
                            
        otherwise
            % This is the standard operators. INPUTS -> 1 scalar output
            if isequal(varargin{2},'or') || isequal(varargin{2},'xor') || isequal(varargin{2},'and') || isequal(varargin{2},'not')
                y = binvarCore(obj, 1,1);
            elseif isequal(varargin{2},'sign')
                y = intvarCore(obj, nout(1),nout(2));
            else
                y = sdpvarCore(obj, nout(1),nout(2));
            end
            if ~strcmpi({'sort'},varargin{2})
                % Oh fuck is this ugly. Sort assumes ordering on some
                % variables, and thus assumes no z in between. This
                % will be generalized when R^n -> R^m is supported for
                % real
                
                % Actually, we can skip these normalizing variables for
                % everything which isn't based on callbacks. This saves
                % a lot of setup time on huge models
                if ~(strcmp(varargin{2},'norm') || strcmp(varargin{2},'abs'))
                    z = sdpvarCore(obj, size(varargin{3},1),size(varargin{3},2),'full'); % Standard format     y=f(z),z==arg
                    obj.auxVariables = [ obj.auxVariables  getvariables(z)];
                else
                    z = [];
                end
                obj.auxVariables = [ obj.auxVariables  getvariables(y)];
            else
                z = [];
            end
            for i = 1:prod(nout)
                % Avoid subsref to save time
                if prod(nout) == 1
                    yi = y;
                else
                    yi = y(i);
                end                
                obj.ExtendedMap(end+1).fcn = varargin{2};
                obj.ExtendedMap(end).arg = {varargin{3:end},z};
                obj.ExtendedMap(end).var = yi;
                obj.ExtendedMap(end).computes = getvariables(y);
                obj.ExtendedMap(end).Hash = this_hash;
                obj.ExtendedMapHashes = [obj.ExtendedMapHashes this_hash];
                obj.extVariables = [obj.extVariables getvariables(yi)];
					obj.containsSemivar = obj.containsSemivar | strcmp(varargin{2}, 'semivar');
            end
            y = setoperatorname(y,varargin{2});
    end
    for i = 3:length(varargin)
        if isa(varargin{i},'sdpvar')
            obj.setdependence(,getvariables(y),getvariables(varargin{i}));
        end
    end        
    varargout{1} = clearconic(y);
    return
    end

    function varargout = setdependence(obj, varargin)
    if ~isempty(varargin{1}) && ~isempty(varargin{2})
        if isa(varargin{1},'sdpvar')
            varargin{1} = getvariables(varargin{1});
        end
        if isa(varargin{2},'sdpvar')
            varargin{2} = getvariables(varargin{2});
        end
        % This dies not work since the arguments have different
        % ordering. Try for instance x=sdpvarCore(obj, 2),[x>=0,abs(x)>=0]
        % nx = max(size(obj.DependencyMap,1),max(varargin{1}));
        % ny = max(size(obj.DependencyMap,2),max(varargin{2}));
        % index = sub2ind([nx ny], varargin{1},varargin{2});
        % if size(obj.DependencyMap,1) < nx || size(obj.DependencyMap,2) < ny
        %     obj.DependencyMap(nx,ny) = 0;
        % end
        
        temp1 = repmat(varargin{1},size(varargin{2},2),1);temp1 = temp1(:)';
        temp2 = repmat(varargin{2},1,size(varargin{1},2));temp2 = temp2(:)';
       
        obj.DependencyMap_i = [obj.DependencyMap_i temp1];
        obj.DependencyMap_j = [obj.DependencyMap_j temp2];
        
        n = size(obj.monomtable,1);
        if size(obj.DependencyMap,1) < n
            obj.DependencyMap(n,1)=0;
        end
        if size(obj.DependencyMap,2) < n
            obj.DependencyMap(end,n)=0;
        end
    end
    end

    function varargout = setdependenceUser(obj, varargin)
    if ~isempty(varargin{1}) && ~isempty(varargin{2})
        if isa(varargin{1},'sdpvar')
            varargin{1} = getvariables(varargin{1});
        end
        if isa(varargin{2},'sdpvar')
            varargin{2} = getvariables(varargin{2});
        end
        obj.DependencyMapUser(varargin{1},varargin{2}) = 1;
        n = size(obj.monomtable,1);
        if size(obj.DependencyMapUser,1) < n
            obj.DependencyMapUser(n,1)=0;
        end
        if size(obj.DependencyMapUser,2) < n
            obj.DependencyMapUser(end,n)=0;
        end
    end
    end

    function varargout = getdependence(obj, varargin)
    %varargout{1} =   obj.DependencyMap;
    if isempty(obj.DependencyMap_i)
        varargout{1} = sparse(0);
    else
        try
            varargout{1} = sparse(obj.DependencyMap_i,obj.DependencyMap_j,1);
        catch
            1
        end
    end
    n =  size(obj.monomtable,1);
    if size(varargout{1},1) < n || size(varargout{1},2)<n
        varargout{1}(n,n) = 0;
    end
    end

    function varargout = getdependenceUser(obj, varargin)
    varargout{1} =   obj.DependencyMapUser;
    n =  size(obj.monomtable,1);
    if size(varargout{1},1) < n || size(varargout{1},2)<n
        varargout{1}(n,n) = 0;
    end
    end

    function varargout = getarguments(obj, varargin)
    varargout{1} = obj.extstruct(,getvariables(varargin{1}));
    end

    function varargout = getAuxvariables(obj, varargin)
    varargout{1} = obj.auxVariables;
    end

    function varargout = getAuxvariablesW(obj, varargin)
    varargout{1} = obj.auxVariablesW;
    end

    function varargout = getExtvariables(obj, varargin)
    varargout{1} = obj.extVariables;
    end

    function varargout = extstruct(obj, varargin)
    if (nargin+1) == 1
        varargout{1} = obj.ExtendedMap;
    elseif length(varargin{1})==1
        found = 0;
        varargout{1} = [];
        i = 1;
        while ~found && i <=length(obj.ExtendedMap)
            if varargin{1} == getvariables(obj.ExtendedMap(i).var)
                found = 1;
                varargout{1} = obj.ExtendedMap(i);
            end
            i = i + 1;
        end
    else
        % If requests several extended variables, returns as cell
        found = zeros(1,length(varargin{1}));
        varargout{1} = cell(0,length(varargin{1}));
        i = 1;
        while ~all(found) && i <=length(obj.ExtendedMap)
            j = find(varargin{1} == getvariables(obj.ExtendedMap(i).var));
            if ~isempty(j)
                found(j) = 1;
                varargout{1}{j} = obj.ExtendedMap(i);
            end
            i = i + 1;
        end
    end
  
 case 'expvariables'    
    expvariables     = [];      
    for i = 1:length(obj.ExtendedMap)
       if any(strcmpi(obj.ExtendedMap(i).fcn,{'exp','pexp','log','slog','plog','logsumexp','kullbackleibler','entropy'}))
         expvariables = [ expvariables obj.ExtendedMap(i).computes];
       end
    end
    varargout{1} = expvariables;       
    end

    function varargout = rankvariables(obj, varargin)
    i = 1;
    rankvariables     = [];
    dualrankvariables = [];
    for i = 1:length(obj.ExtendedMap)
        if strcmpi('rank',obj.ExtendedMap(i).fcn)
            rankvariables = [rankvariables getvariables(obj.ExtendedMap(i).var)];
        end
        if strcmpi('dualrank',obj.ExtendedMap(i).fcn)
            dualrankvariables = [dualrankvariables getvariables(obj.ExtendedMap(i).var)];
        end
    end
    varargout{1} = rankvariables;
    varargout{2} = dualrankvariables;
    end

    %% ALIASGROUP lmiid|ConstraintID
    function varargout = lmiid(obj, varargin)
    if not(isempty(obj.LMIid))
        obj.LMIid = obj.LMIid+1;
        varargout{1}=obj.LMIid;
    else
        obj.LMIid=1;
        varargout{1}=obj.LMIid;
    end
    end

    function varargout = setnonlinearvariables(obj, varargin)
    error('Internal error (ref. setnonlinearvariables). Report please.')
    end

    function varargout = clear(obj, varargin)
    W = evalin('caller','whos');
    for i = 1:size(W,1)
        if strcmp(W(i).class,'sdpvar') || strcmp(W(i).class,'lmi')
            evalin('caller', ['clear ' W(i).name ';']);
        end
    end
    
    obj.LMIid = 0;
    obj.duals_index = [];
    obj.duals_data = [];
    obj.duals_associated_index = [];
    obj.duals_associated_data  = [];
    
    
    obj.sosid = 0;
    obj.sos_index = [];
    obj.sos_data = [];
    obj.sos_ParV = [];
    obj.sos_Q    = [];
    obj.sos_v    = [];
    
    obj.monomtable = spalloc(0,0,0);
    obj.hashedmonomtable = [];
    obj.hash = [];
    obj.boundlist = [];
    obj.variabletype = spalloc(0,0,0);
    obj.intVariables = [];
    obj.binVariables = [];
    obj.tempintVariables = [];
    obj.tempbinVariables = [];
    obj.semicontVariables = [];
    obj.uncVariables = [];
    obj.parVariables = [];
    obj.extVariables = [];
    obj.auxVariables = [];
    obj.auxVariablesW = [];
    obj.logicVariables = [];
    ;obj.complexpair = [];
    obj.internalconstraints = [];
    obj.ExtendedMap = [];
    obj.ExtendedMapHashes = [];
    obj.DependencyMap = sparse(0);
    obj.DependencyMap_i = [];
    obj.DependencyMap_j = [];
    obj.DependencyMapUser = sparse(0);
    obj.optSolution{1}.info = 'Initialized by YALMIP';
    obj.optSolution{1}.variables = [];
    obj.optSolution{1}.optvar = [];
    obj.optSolution{1}.values = [];
    obj.activeSolution = 1;
    
    obj.nonCommutingTable = [];
		
		obj.containsSemivar = false;
    
    obj.gemInPath('clear');
    end

    function varargout = cleardual(obj, varargin)
    if (nargin+1)==1
        obj.duals_index = [];
        obj.duals_data = [];
        obj.duals_associated_index = [];
        obj.duals_associated_data = [];
    else
        if ~isempty(obj.duals_index)
            obj.lmiid = varargin{1};
            for i = 1:length(varargin{1})
                j = find(obj.duals_index==obj.lmiid(i));
                if ~isempty(j)
                    obj.duals_index = obj.duals_index([1:1:j-1 j+1:1:length(obj.duals_index)]);
                    obj.duals_data = {obj.duals_data{[1:1:j-1 j+1:1:length(obj.duals_data)]}};
                end
            end
        end
    end
    end

    function varargout = associatedual(obj, varargin)
    obj.duals_associated_index = [obj.duals_associated_index varargin{1}];
    obj.duals_associated_data{end+1} = varargin{2};
    end

    function varargout = addcomplexpair(obj, varargin)
    obj.complexpair = [obj.complexpair;varargin{1}];
    end

    function varargout = getcomplexpair(obj, varargin)
    error('Please report this error!')
    varargout{1} = obj.complexpair;
    return
    end

    function varargout = setallsolution(obj, varargin)
    obj.optSolution{obj.activeSolution}.optvar = varargin{1}.optvar;
    obj.optSolution{obj.activeSolution}.variables = varargin{1}.variables;
    obj.optSolution{obj.activeSolution}.values = [];
    return
    end

    function varargout = setvalues(obj, varargin)
    obj.optSolution{obj.activeSolution}.values = varargin{1};
    end

    function varargout = numbersolutions(obj, varargin)
    varargout{1} = length(obj.optSolution);
    end

    function varargout = selectsolution(obj, varargin)
    if length(obj.optSolution)>=varargin{1}
        obj.activeSolution = varargin{1};
    else
        error('Solution not available');
    end
    end

    function varargout = setsolution(obj, varargin)
    if (nargin+1) < 3
        solutionIndex = 1;
    else
        solutionIndex = varargin{2};
    end
    obj.activeSolution = 1;
    
    % Clear trailing solutions
    if solutionIndex < length(obj.optSolution)
        obj.optSolution = {obj.optSolution{1:solutionIndex}};
    elseif solutionIndex > length(obj.optSolution)+1
        for j = length(obj.optSolution)+1:solutionIndex
            obj.optSolution{j}.optvar=[];
            obj.optSolution{j}.variables=[];
            obj.optSolution{j}.values=[];
        end
    elseif solutionIndex == length(obj.optSolution)+1
        obj.optSolution{solutionIndex}.optvar=[];
        obj.optSolution{solutionIndex}.variables=[];
        obj.optSolution{solutionIndex}.values=[];
    end
    
    if isempty(obj.optSolution{solutionIndex}.variables)
        obj.optSolution{solutionIndex} = varargin{1};
    else
        % Just save some stuff first
        newSolution = varargin{1};
        oldSolution = obj.optSolution{solutionIndex};
        optSolution = varargin{1};
        keep_these = find(~ismember(oldSolution.variables,newSolution.variables));
        obj.optSolution{solutionIndex}.optvar    = [oldSolution.optvar(keep_these);newSolution.optvar(:)];
        obj.optSolution{solutionIndex}.variables = [oldSolution.variables(keep_these);newSolution.variables(:)];
    end
    % clear evaluated values (only used cache-wise)
    obj.optSolution{solutionIndex}.values = [];
    return
    
    %    case 'setsolution'
    %
    %         if isempty(obj.optSolution.variables)
    %             obj.optSolution = varargin{1};
    %         else
    %             % Just save some stuff first
    %             newSolution = varargin{1};
    %             oldSolution = obj.optSolution;
    %             optSolution = varargin{1};
    %             keep_these = find(~ismember(oldSolution.variables,newSolution.variables));
    %             obj.optSolution.optvar    = [oldSolution.optvar(keep_these);newSolution.optvar(:)];
    %             obj.optSolution.variables = [oldSolution.variables(keep_these);newSolution.variables(:)];
    %         end
    %         % clear evaluated values (only used cache-wise)
    %         obj.optSolution.values = [];
    %         return
    end

    function varargout = addauxvariables(obj, varargin)
    obj.auxVariables = [obj.auxVariables varargin{1}(:)'];
    end

    function varargout = addauxvariablesW(obj, varargin)
    obj.auxVariablesW = [obj.auxVariablesW varargin{1}(:)'];
    end

    function varargout = getsolution(obj, varargin)
    varargout{1} = obj.optSolution{obj.activeSolution};
    return
    end

    function varargout = setdual(obj, varargin)
    obj.duals_index = varargin{1};
    obj.duals_data = varargin{2};
    
    temp1 = [];
    temp2 = [];
    if ~isempty(obj.duals_associated_index)
        if ~isempty(intersect(obj.duals_index,obj.duals_associated_index))
            for i = 1:length(obj.duals_index)
                itshere = find(obj.duals_associated_index==obj.duals_index(i));
                if ~isempty(itshere)
                    temp1 = [temp1;obj.duals_associated_data{itshere}(:)];
                    temp2 = [temp2;obj.duals_data{i}(:)];
                end
                if length(temp1)>1000
                    assign(temp1,temp2);
                    temp1 = [];
                    temp2 = [];
                end
            end
        end
        if ~isempty(temp1)
            assign(temp1,temp2);
        end
    end
    end

    function varargout = dual(obj, varargin)
    if isempty(obj.duals_index)
        varargout{1}=[];
    else
        LMIid = varargin{1};
        index_to_dual = find(LMIid==obj.duals_index);
        if isempty(index_to_dual)
            varargout{1}=[];
        else
            varargout{1} = obj.duals_data{index_to_dual};
        end
    end
    end

    function varargout = clearsos(obj, varargin)
    if (nargin+1)==1
        obj.sos_index = [];
        obj.sos_data = [];
        obj.sos_ParV = [];
        obj.sos_Q    = [];
        obj.sos_v    = [];
        
    end
    end

    function varargout = setsos(obj, varargin)
    if ~isempty(obj.sos_index)
        where = find(obj.sos_index==varargin{1});
        if ~isempty(where)
            obj.sos_index(where) = varargin{1};
            obj.sos_data{where} = varargin{2};
            obj.sos_ParV{where} = varargin{3};
            obj.sos_Q{where} = varargin{4};
            obj.sos_v{where} = varargin{5};
            
        else
            obj.sos_index(end+1) = varargin{1};
            obj.sos_data{end+1} = varargin{2};
            obj.sos_ParV{end+1} = varargin{3};
            obj.sos_Q{end+1} = varargin{4};
            obj.sos_v{end+1} = varargin{5};
            
        end
    else
        obj.sos_index(end+1) = varargin{1};
        obj.sos_data{end+1} = varargin{2};
        obj.sos_ParV{end+1} = varargin{3};
        obj.sos_Q{end+1} = varargin{4};
        obj.sos_v{end+1} = varargin{5};
    end
    end

    function varargout = nextSosId(obj, varargin)
    if not(isempty(obj.sosid))
        obj.sosid = obj.sosid+1;
        varargout{1}=obj.sosid;
    else
        obj.sosid=1;
        varargout{1}=obj.sosid;
    end
    end

    function varargout = getsos(obj, varargin)
    if isempty(obj.sos_index)
        varargout{1}=[];
        varargout{2}=[];
        varargout{3}=[];
        varargout{4}=[];
    else
        SOSid = varargin{1};
        index_to_sos = find(SOSid==obj.sos_index);
        if isempty(index_to_sos)
            varargout{1}=[];
            varargout{2}=[];
            varargout{3}=[];
            varargout{4}=[];
        else
            varargout{1} = obj.sos_data{index_to_sos};
            varargout{2} = obj.sos_ParV{index_to_sos};
            varargout{3} = obj.sos_Q{index_to_sos};
            varargout{4} = obj.sos_v{index_to_sos};
            % FIX
        end
    end
    end

    function varargout = getinternalsetstate(obj, varargin)
    varargout{1} = obj.setstatesnapshot(); % Get internal state, called from saveobj
    end

    function varargout = setinternalsetstate(obj, varargin)
    obj.setstatesnapshot() = varargin{1}; % Set internal state, called from loadobj
    end

    function varargout = getinternalsdpvarstate(obj, varargin)
    varargout{1} = obj.snapshotState(); % Get internal state, called from saveobj
    end

    function varargout = setinternalsdpvarstate(obj, varargin)
    st = varargin{1}; % Set internal state, called from loadobj

    % Back-wards compability....
    if ~isfield(st,'extVariables')
        st.extVariables = [];
    end
    if ~isfield(st,'ExtendedMap')
        st.ExtendedMap = [];
        st.containsSemivar = false;
    end
    if ~isfield(st,'ExtendedMapHashes')
        st.ExtendedMapHashes = [];
    end
    if ~isfield(st,'variabletype')
        st.variabletype = ~(sum(st.monomtable,2)==1 & sum(st.monomtable~=0,2)==1);
    end
    if ~isfield(st,'hash')
        st.hash=[];
        st.hashedmonomtable=[];
    end

    % Re-compute some stuff for safety
    st.variabletype = st.variabletype(:)';
    st.variabletype = spalloc(size(st.monomtable,1),1,0)';
    nonlinear = ~(sum(st.monomtable,2)==1 & sum(st.monomtable~=0,2)==1);
    if ~isempty(nonlinear)
        st.variabletype(nonlinear) = 3;
        quadratic = sum(st.monomtable,2)==2;
        st.variabletype(quadratic) = 2;
        bilinear = max(st.monomtable,[],2)<=1;
        st.variabletype(bilinear & quadratic) = 1;
        signomial = any(0>st.monomtable,2) | any(st.monomtable-fix(st.monomtable),2);
        st.variabletype(signomial) = 4;
    end

    [n,mm] = size(st.monomtable);
    if n>mm
        st.monomtable(n,n) = 0;
    end

    if size(st.monomtable,2)>length(st.hash)
        % Need new hash-keys
        need_new = size(st.monomtable,1) - length(st.hash);
        st.hash = [st.hash ; 3*gen_rand_hash(size(st.monomtable,1),need_new,1)];
    end
    if size(st.monomtable,1)>size(st.hashedmonomtable,1)
        % Need to add some hash values
        need_new = size(st.monomtable,1) - size(st.hashedmonomtable,1);
        st.hashedmonomtable = [st.hashedmonomtable;st.monomtable(end-need_new+1:end,:)*st.hash];
    end

    obj.restoreState(st);
    end
    if ~isfield(obj.snapshotState(),'ExtendedMap')
        obj.ExtendedMap = [];
			obj.containsSemivar = false;
    end
    if ~isfield(obj.snapshotState(),'ExtendedMapHashes')
        obj.ExtendedMapHashes = [];
    end  
    if ~isfield(obj.snapshotState(),'variabletype')
        obj.variabletype = ~(sum(obj.monomtable,2)==1 & sum(obj.monomtable~=0,2)==1);
    end
    if ~isfield(obj.snapshotState(),'hash')
        obj.hash=[];
        obj.hashedmonomtable=[];
    end
    
    % Re-compute some stuff for safety
    obj.variabletype = obj.variabletype(:)';
    obj.variabletype = spalloc(size(obj.monomtable,1),1,0)';
    nonlinear = ~(sum(obj.monomtable,2)==1 & sum(obj.monomtable~=0,2)==1);
    if ~isempty(nonlinear)
        mt = obj.monomtable;
        obj.variabletype(nonlinear) = 3;
        quadratic = sum(obj.monomtable,2)==2;
        obj.variabletype(quadratic) = 2;
        bilinear = max(obj.monomtable,[],2)<=1;
        obj.variabletype(bilinear & quadratic) = 1;
        signomial = any(0>obj.monomtable,2) | any(obj.monomtable-fix(obj.monomtable),2);
        obj.variabletype(signomial) = 4;
    end
    
    [n,m] = size(obj.monomtable);
    if n>m
        obj.monomtable(n,n) = 0;
    end
    
    if size(obj.monomtable,2)>length(obj.hash)
        % Need new hash-keys
        obj.hash = [obj.hash ; 3*gen_rand_hash(size(obj.monomtable,1),need_new,1)];
    end
    if size(obj.monomtable,1)>size(obj.hashedmonomtable,1)
        % Need to add some hash values
        need_new = size(obj.monomtable,1) - size(obj.hashedmonomtable,1);
        obj.hashedmonomtable = [obj.hashedmonomtable;obj.monomtable(end-need_new+1:end,:)*obj.hash];
    end
    end

    %% ALIASGROUP version|ver
    function varargout = version(obj, varargin)
    varargout{1} = '20250626';
    end

    function varargout = setintvariables(obj, varargin)
    obj.intVariables = varargin{1};
    end

    function varargout = getIntvariables(obj, varargin)
    varargout{1} = obj.intVariables;
    end

    function varargout = setbinvariables(obj, varargin)
    obj.binVariables = varargin{1};
    end

    function varargout = getBinvariables(obj, varargin)
    varargout{1} = obj.binVariables;
    end

    function varargout = settempintvariables(obj, varargin)
    obj.tempintVariables = varargin{1};
    end

    function varargout = getTempintvariables(obj, varargin)
    varargout{1} = obj.tempintVariables;
    end

    function varargout = settempbinvariables(obj, varargin)
    obj.tempbinVariables = varargin{1};
    end

    function varargout = getTempbinvariables(obj, varargin)
    varargout{1} = obj.tempbinVariables;
    end

    function varargout = quantvariables(obj, varargin)
    varargout{1} = [obj.binVariables obj.intVariables];
    end

    function varargout = setsemicontvariables(obj, varargin)
    obj.semicontVariables = varargin{1};
    end

    function varargout = getSemicontvariables(obj, varargin)
    varargout{1} = obj.semicontVariables;
    end

    function varargout = setuncvariables(obj, varargin)
    obj.uncVariables = varargin{1};
    end

    function varargout = getUncvariables(obj, varargin)
    varargout{1} = obj.uncVariables;
    end

    function varargout = setparvariables(obj, varargin)
    obj.parVariables = varargin{1};
    end

    function varargout = getParvariables(obj, varargin)
    varargout{1} = obj.parVariables;
    end

    function varargout = nonCommutingVariables(obj, varargin)
    if isempty(obj.nonCommutingTable)
         varargout{1} = [];
    else
        varargout{1} = find(isnan(obj.nonCommutingTable(:,1)));
    end
    end

    function varargout = getSetNonCommutingTable(obj, varargin)
    if (nargin+1) == 2
        obj.nonCommutingTable = varargin{1};       
    else
        varargout{1} = obj.nonCommutingTable;
    end
    end

    function varargout = nonlinearvariables(obj, varargin)
    error('Internal error (ref. nonlinear variables). Report!')
    varargout{1} = obj.nonlinearvariables;
    if nargout==2
        varargout{2} = obj.nonlinearvariablesCompressed;
    end
    %
    end

    function varargout = addinternal(obj, varargin)
    obj.internalconstraints{end+1} = varargin{1};
    
    %  case {'setnvars'}
    %      sdpvarCore(obj, 'setnvars',varargin{1});
    end

    function varargout = nvars(obj, varargin)
    varargout{1} = size(obj.monomtable,1);
    % varargout{1} = sdpvarCore(obj, 'nvars');
    end

    function varargout = info(obj, varargin)
    [version,release] = obj.version();
    currentversion = num2str(version(1));
    i = 1;
    while i<length(version)
        i = i+1;
        currentversion = [currentversion '.' num2str(version(i))];
    end
    
    info_str = ['- - - - YALMIP ' currentversion ' ' num2str(release) ' - - - -'];
    
    disp(' ');
    disp(char(repmat(double('*'),1,length(info_str))));
    disp(info_str)
    disp(char(repmat(double('*'),1,length(info_str))));
    disp(' ');
    disp(['Variable     Size'])
    spaces = ['                                    '];
    ws = evalin('caller','whos');
    n = 0;
    for i = 1:size(ws,1)
        if strcmp(ws(i).class,'sdpvar')
            n = n+1;
            wsname = ws(i).name;
            wssize = [num2str(ws(i).size(1)) 'x' num2str(ws(i).size(2))];
            disp([wsname spaces(1:13-length(wsname)) wssize]);
        end
    end
    if n == 0
        disp('No SDPVAR objects found');
    end
    disp(' ');
    disp(['LMI']);
    n = 0;
    for i = 1:size(ws,1)
        if strcmp(ws(i).class,'lmi')
            n = n+1;
            wsname = ws(i).name;
            disp([wsname]);
        end
    end
    if n == 0
        disp('No SET objects found');
    end
    end

    function varargout = getbounds(obj, varargin)
    if ~isfield(obj.snapshotState(),'boundlist')
        obj.boundlist = inf*repmat([-1 1],size(obj.monomtable,1),1);
    elseif isempty(obj.boundlist)
        obj.boundlist = inf*repmat([-1 1],size(obj.monomtable,1),1);
    end
    indicies = varargin{1};
    if max(indicies)>size(obj.boundlist,1)
        need_new = max(indicies)-size(obj.boundlist,1);
        obj.boundlist = [obj.boundlist;inf*repmat([-1 1],size(obj.monomtable,1),1)];
    end
    varargout{1} = obj.boundlist(indicies,:);
    varargout{2} = obj.boundlist(indicies,:);
    end

    function varargout = setbounds(obj, varargin)
    if ~isfield(obj.snapshotState(),'boundlist')
        obj.boundlist = inf*repmat([-1 1],size(obj.monomtable,1),1);
    elseif isempty(obj.boundlist)
        obj.boundlist = inf*repmat([-1 1],size(obj.monomtable,1),1);
    end
    indicies = varargin{1};
    if size(obj.boundlist,1)<min(indicies)
        obj.boundlist = [obj.boundlist;repmat([-inf inf],max(indicies)-size(obj.boundlist,1),1)];
    end
    obj.boundlist(indicies,1) = -inf ;
    obj.boundlist(indicies,2) = inf;
    
    obj.boundlist(indicies(:),1) = varargin{2};
    obj.boundlist(indicies(:),2) = varargin{3};
    varargout{1}=0;
    end

    function varargout = getExtendedmap(obj, varargin)
    varargout{1} = obj.ExtendedMap;
    end

    function varargout = logicextvariables(obj, varargin)
    logicextvariables = [];
    for i = 1:length(obj.ExtendedMap)
        %            if ismember(obj.ExtendedMap(i).fcn,{'or','and'})
        if isequal(obj.ExtendedMap(i).fcn,'or') || isequal(obj.ExtendedMap(i).fcn,'and')
            logicextvariables = [logicextvariables obj.extVariables(i)];
        end
    end
    varargout{1} = logicextvariables;
    end

    function varargout = getLogicvariables(obj, varargin)
    varargout{1} = obj.logicVariables;
    end

    function varargout = addlogicvariable(obj, varargin)
    % This code essentially the same as the addextended code. The only
    % difference is that we keep track of logic variables in order to
    % know when we have to collect bounds for the big-M relaxations.
    
    varargin{1} = strrep(varargin{1},'sdpvar/','');
    
    % Is this operator variable already defined
    if ~isempty(obj.ExtendedMap)
        i = 1;
        while i<=length(obj.ExtendedMap)
            if isequal(varargin{1},obj.ExtendedMap(i).fcn) && isequal({varargin{2:end}}, {obj.ExtendedMap(i).arg{1:end-1}})
                varargout{1} =  obj.ExtendedMap(i).var;
                return
            end
            i = i + 1;
        end
    end
    
    % This is the standard operators. INPUTS -> 1 scalar output
    y = sdpvarCore(obj, 1,1);
    obj.ExtendedMap(end+1).fcn = varargin{1};
    obj.ExtendedMap(end).arg = {varargin{2:end}};
    obj.ExtendedMap(end).var = y;
    obj.extVariables = [obj.extVariables getvariables(y)];
    obj.logicVariables = [obj.logicVariables getvariables(y)];
		obj.containsSemivar = obj.containsSemivar | strcmp(varargin{1}, 'semivar');
    varargout{1} = y;
    return
    end

    function varargout = setNonHermitianNonCommuting(obj, varargin)
    obj.nonHermitiannonCommutingTable(varargin{1}) = 1;
    end

    function varargout = solver(obj, varargin)
    if ((nargin+1)==2)
        if isa(varargin{1},'char')
            solver = varargin{1};
            obj.preferedSolver = solver;
        else
            error('Second argument should be a string with solver name');
        end
    else
        if isempty(obj.preferedSolver)
            varargout{1}='';
        else
            varargout{1} = obj.preferedSolver;
        end
    end
		
	case 'containsSemivar'
		varargout = {obj.containsSemivar};
    end

    function varargout = gemInPath(obj, varargin)
    varargout{1} = obj.gemInPath();
    end


    function varargout = definemulti(obj, varargin)
    % DEFINEMULTI Alias for define
    varargout = obj.define('definemulti', varargin{:});
    end

    function varargout = ver(obj, varargin)
    % VER Alias for version
    varargout = obj.version('ver', varargin{:});
    end

    function varargout = ConstraintID(obj, varargin)
    % CONSTRAINTID Alias for lmiid
    varargout = obj.lmiid('ConstraintID', varargin{:});
    end

    function varargout = addEvalVariable(obj, varargin)
    % ADDEVALVARIABLE Alias for addextendedvariable
    varargout = obj.addextendedvariable('addEvalVariable', varargin{:});
    end

    end
end
