function out = DN_M_kscomp(x,pinkbeanie)
% Performs certain simple statistics on the difference between the 
% empirical distribution from data x, the standard distribution specified
% by pinkbeanie, and the statistic specified by ange

%% PREPROCESSING
% fit the standard distribution
% xtry=linspace(-40,40,400);
xstep = std(x)/100;
switch pinkbeanie
    case 'norm'
        [a b] = normfit(x);
		peaky=normpdf(a,a,b); thresh=peaky/100; % stop when gets to 1/100 of peak value
		xf(1)=mean(x); ange=10; while ange>thresh, xf(1)=xf(1)-xstep; ange=normpdf(xf(1),a,b); end
		xf(2)=mean(x); ange=10; while ange>thresh, xf(2)=xf(2)+xstep; ange=normpdf(xf(2),a,b); end
    case 'ev'
        a = evfit(x);
		peaky=evpdf(a(1),a(1),a(2)); thresh=peaky/100;
		xf(1)=0; ange=10; while ange>thresh, xf(1)=xf(1)-xstep; ange=evpdf(xf(1),a(1),a(2)); end
		xf(2)=0; ange=10; while ange>thresh, xf(2)=xf(2)+xstep; ange=evpdf(xf(2),a(1),a(2)); end
    case 'uni'
        [a b]=unifit(x);
		peaky=unifpdf(mean(x),a,b); thresh=peaky/100;
		xf(1)=0; ange=10; while ange>thresh, xf(1)=xf(1)-xstep; ange=unifpdf(xf(1),a,b); end
		xf(2)=0; ange=10; while ange>thresh, xf(2)=xf(2)+xstep; ange=unifpdf(xf(2),a,b); end
    case 'beta'
        % clumsily scale to the range (0,1)
        x=(x-min(x)+0.01*std(x))/(max(x)-min(x)+0.02*std(x));
        a=betafit(x);
		thresh=1E-5; % ok -- consistent since all scaled to the same range
		xf(1)=mean(x); ange=10; while ange>thresh, xf(1)=xf(1)-xstep; ange=betapdf(xf(1),a(1),a(2)); end
		xf(2)=mean(x); ange=10; while ange>thresh, xf(2)=xf(2)+xstep; ange=betapdf(xf(2),a(1),a(2)); end
    case 'rayleigh'
        if any(x<0),
            out = NaN;
            return
        else % valid domain to fit a Rayleigh distribution
            a=raylfit(x);
			peaky=raylpdf(a,a); thresh=peaky/100;
			xf(1)=0;
			xf(2)=a; ange=10; while ange>thresh, xf(2)=xf(2)+xstep; ange=raylpdf(xf(2),a); end
        end
    case 'exp'
        if any(x<0)
            out = NaN;
            return
        else a=expfit(x);
			peaky=exppdf(0,a); thresh=peaky/100;
			xf(1)=0;
			xf(2)=0; ange=10; while ange>thresh, xf(2)=xf(2)+xstep; ange=exppdf(xf(2),a); end
        end
    case 'gamma'
        if any(x<0)
            out = NaN;
            return
        else a=gamfit(x);
			if a(1)<1
				thresh=gampdf(0,a(1),a(2))/100;
			else
				peaky=gampdf((a(1)-1)*a(2),a(1),a(2)); thresh=peaky/100;
			end
			xf(1)=0;
			xf(2)=a(1)*a(2); ange=10; while ange>thresh, xf(2)=xf(2)+xstep; ange=gampdf(xf(2),a(1),a(2)); end
        end
    case 'gp'
        disp('forget about gp fits. Too difficult.');
        out = NaN;
        return
%         if any(x<0),out=NaN; return
%         else a=gpfit(x);
%         end
    case 'logn'
        if any(x<=0),out = NaN; return
        else
			a=lognfit(x);
			peaky=lognpdf(exp(a(1)-a(2)^2),a(1),a(2)); thresh=peaky/100;
			xf(1)=0;
			xf(2)=exp(a(1)-a(2)^2); ange=10; while ange>thresh, xf(2)=xf(2)+xstep; ange=lognpdf(xf(2),a(1),a(2)); end
        end
    case 'wbl'
        if any(x<=0),out = NaN; return
        else
			a=wblfit(x);
			if a(2)<=1;
				thresh=wblpdf(0,a(1),a(2));
			else
				peaky=wblpdf(a(1)*((a(2)-1)/a(2))^(1/a(2)),a(1),a(2));
				thresh=peaky/100;
			end
			xf(1)=0;
			xf(2)=0; ange=10; while ange>thresh, xf(2)=xf(2)+xstep; ange=wblpdf(xf(2),a(1),a(2)); end
        end
end
% xtmafit=[floor(xtmafit(1)*10)/10 ceil(xtmafit(end)*10)/10];

% determine smoothed empirical distribution
[f xi]=ksdensity(x);
xi=xi(f>1E-6); % only keep values greater than 1E-6
if isempty(xi)
    out=NaN; return
    % in future should change to the threshold from 1E-6 to some fraction
    % of the peak value...
end

xi=[floor(xi(1)*10)/10 ceil(xi(end)*10)/10];

% find appropriate range [x1 x2] that incorporates the full range of both
x1=min([xf(1) xi(1)]);
x2=max([xf(2) xi(end)]);

%% Inefficient, but easier to just rerun both over the same range
xi=linspace(x1,x2,1000);
f=ksdensity(x,xi); % the smoothed empirical distribution
switch pinkbeanie
    case 'norm'
        ffit=normpdf(xi,a,b);
    case 'ev'
        ffit=evpdf(xi,a(1),a(2));
    case 'uni'
        ffit=unifpdf(xi,a,b);
    case 'beta'
%         if x1<0,x1=1E-5;end
%         if x2>1,x2=1-1E-5;end
        ffit=betapdf(xi,a(1),a(2));
    case 'rayleigh'
%         if x1<0,x1=0;end
        ffit=raylpdf(xi,a);
    case 'exp'
%         if x1<0,x1=0;end
        ffit=exppdf(xi,a);
    case 'gamma'
%         if x1<0,x1=0;end
        ffit=gampdf(xi,a(1),a(2));
    case 'logn'
%         if x1<0,x1=0;end
        ffit=lognpdf(xi,a(1),a(2));
    case 'wbl'
%         if x1<0,x1=0;end
        ffit=wblpdf(xi,a(1),a(2));
end

% now the two cover the same range in x

%% Retrieving Output
% out=struct('adiff',[],'peaksepy',[],'peaksepx',[],'olapint',[],'relent',[])

% ADIFF: returns absolute area between the curves
out.adiff=sum(abs(f-ffit)*(xi(2)-xi(1)));

% PEAKSEPY: returns the seperation (in y) between the maxima of each distrn
% NOT WELL POSED FOR ARBTIRARY DISTRIBUTIONS -- scales with variance
max1=max(f);
max2=max(ffit);
out.peaksepy=max2-max1;

% PEAKSEPX: returns the seperation (in x) between the maxima of each distrn
% NOT WELL POSED FOR ARBITRARY DISTRIBUTIONS -- scales with variance
[max1 i1]=max(f);
[max2 i2]=max(ffit);
out.peaksepx=xi(i2)-xi(i1);

% OLAPINT: returns the overlap integral between the two curves; normalized by variance
out.olapint=sum(f.*ffit*(xi(2)-xi(1)))*std(x);

% RELENT: returns the relative entropy of the two distributions
r=find(ffit~=0);
out.relent=sum(f(r).*log(f(r)./ffit(r))*(xi(2)-xi(1)));


%     function out=sub_nanmeup
%        % returns a structure with NaNs in all the entries of the output structure 
%        out.adiff=NaN;
%        out.peaksepy=NaN;
%        out.peaksepx=NaN;
%        out.olapint=NaN;
%        out.relent=NaN;
%     end


end