%LIBSVC Support Vector Classifier by libsvm
% 
% 	[W,J] = LIBSVC(A,KERNEL,C)
%
% INPUT
%   A	    Dataset
%   KERNEL  Mapping to compute kernel by A*MAP(A,KERNEL)
%           or string to compute kernel by FEVAL(KERNEL,A,A)
%           or cell array with strings and parameters to compute kernel by
%           FEVAL(KERNEL{1},A,A,KERNEL{2:END})
%           Default: linear kernel (PROXM([],'P',1))
%   C       Trade_off parameter in the support vector classifier.
%           Default C = 1;
%
% OUTPUT
%   W       Mapping: Support Vector Classifier
%   J       Object idences of support objects. Can be also obtained as W{4}		
%
% DESCRIPTION
% Optimizes a support vector classifier for the dataset A by the libsvm
% package, see http://www.csie.ntu.edu.tw/~cjlin/libsvm/. LIBSVC calls the
% svmtrain routine of libsvm for training. Classifier execution for a
% test dataset B may be done by D = B*W; In D posterior probabilities are
% given as computed by svmpredict using the '-b 1' option. 
% 
% The kernel may be supplied in KERNEL by
% - an untrained mapping, e.g. a call to PROXM like W = LIBSVC(A,PROXM([],'R',1))
% - a string with the name of the routine to compute the kernel from A
% - a cell-array with this name and additional parameters.
% This will be used for the evaluation of a dataset B by B*W or MAP(B,W) as
% well. 
%
% If KERNEL = 0 (or not given) it is assumed that A is already the 
% kernelmatrix (square). In this also a kernel matrix should be supplied at 
% evaluation by B*W or MAP(B,W). However, the kernel has to be computed with 
% respect to support objects listed in J (the order of objects in J does matter).
% 
% REFERENCES
% R.-E. Fan, P.-H. Chen, and C.-J. Lin. Working set selection using the second order 
% information for training SVM. Journal of Machine Learning Research 6, 1889-1918, 2005
%
% SEE ALSO 
% MAPPINGS, DATASETS, SVC, PROXM

% Copyright: R.P.W. Duin, r.p.w.duin@prtools.org
% Faculty EWI, Delft University of Technology
% P.O. Box 5031, 2600 GA Delft, The Netherlands
  
function [W,J,u] = libsvc(a,kernel,C)
		prtrace(mfilename);

	if ~exist('svmtrain')
		error('LIBSVM not found. Download it and add to the path')
	end
	
	if nargin < 3 
		C = 1;
	end
	if nargin < 2 | isempty(kernel)
		kernel = proxm([],'p',1);
	end

	if nargin < 1 | isempty(a)
		W = mapping(mfilename,{kernel,C});
		W = setname(W,'LIBSVM Classifier');
		return;
	end

	%opt = ['-s 0 -t 4 -b 1 -c ',num2str(C)];
	opt = ['-s 0 -t 4 -b 1 -e 1e-3 -c ',num2str(C), ' -q'];
	if (~ismapping(kernel) | isuntrained(kernel)) % training
	
		islabtype(a,'crisp');
		isvaldfile(a,1,2); % at least 1 object per class, 2 classes
		a = testdatasize(a,'objects');
		[m,k,c] = getsize(a);
		nlab = getnlab(a); 
	
		K = compute_kernel(a,a,kernel);
		K = min(K,K');   % make sure kernel is symmetric
		K = [[1:m]' K];  % as libsvm wants it
	                   % call libsvm
		u = svmtrain(nlab,K,opt);
		                 % Store the results:
		J = full(u.SVs);
		if isequal(kernel,0)
			s = [];
%			in_size = length(J);
			in_size = 0; % to allow old and new style calls
		else
			s = a(J,:);
			in_size = k;
		end

		lablist = getlablist(a);         
		W = mapping(mfilename,'trained',{u,s,kernel,J,opt},lablist(u.Label,:),in_size,c);
		
		W = setname(W,'LIBSVM Classifier');
		W = setcost(W,a);
		
	else % execution
		v = kernel;
		w = +v;
		m = size(a,1);
	
		u = w{1};
		s = w{2};
		kernel = w{3};
		J = w{4};
		opt = w{5};
	
		K = compute_kernel(a,s,kernel);
		k = size(K,2);
		if k ~= length(J)
			if isequal(kernel,0)
				if (k > length(J)) &  (k >= max(J))
					% precomputed kernel; old style call
					prwarning(2,'Old style execution call: The precomputed kernel was calculated on a test set and the whole training set!')  
				else
					error(['Inappropriate precomputed kernel!' newline ...
							'For the execution the kernel matrix should be computed on a test set' ...
							newline 'and the set of support objects']);
				end  
			else
				error('Kernel matrix has the wrong number of columns');
			end
		else  
			% kernel was computed with respect to the support objects
			% we make an approprite correction in the libsvm structure
			u.SVs = sparse((1:length(J))');
		end  
		K = [[1:m]' K];  % as libsvm wants it
		[lab,acc,d] = svmpredict(getnlab(a),K,u,' -b 1');
		W = setdat(a,d,v);
	end
	
return;

function K = compute_kernel(a,s,kernel)

	% compute a kernel matrix for the objects a w.r.t. the support objects s
	% given a kernel description

	if  isstr(kernel) % routine supplied to compute kernel
		K = feval(kernel,a,s);
	elseif iscell(kernel)
		K = feval(kernel{1},a,s,kernel{2:end});
	elseif ismapping(kernel)
		K = a*map(s,kernel);
	elseif kernel == 0 % we have already a kernel
		K = a;
	else
		error('Do not know how to compute kernel matrix')
	end
		
	K = +K;
		
return
