function [P,p,M,N,K,D,L,R,Rj,RRj,SigJ,M0,N0,a0,b0,a,b,dimx,dimX,dimu,dimuj,e1,e2,H,EE]= SVLorenz(theta,kbar,tol,binmax)
EE=1;
%%
try
    
rho1=theta(1); %persistence of technology
rho2=theta(2); %persistence of demand
sigu=theta(3);  %s.d. of state innov
sigud=theta(4); %s.d. "demand" shock
sigur=theta(5);  %s.d. of m.p. shock
sigaj=theta(6);  %s.d. of island tech
sigzj1=theta(7);  %s.d. of private info noise
sigzj2=theta(8);  %s.d. of private info noise
sigdj=theta(9);  %s.d. of private info noise
sigmbd=theta(10); %s.d. of m-b-d signal
varphi=theta(11); %labour supply curvature
delta=theta(12); %elasticity of demand
fir=theta(13);%Interest inertia
fipi=(1-fir)*theta(14); %Taylor param;
fiy=(1-fir)*theta(15); %Taylor rule param
stick=theta(16); %Calvo parameter
beta=theta(17); %discount rate


%MBD params
omega=theta(18);  %unconditional prob of S=1, i.e. of observing pub signal
gamma=theta(19);    %s.d. multiplier of u when S=1

lambda=(1-stick)*(1-stick*beta)/stick;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Define dimensions etc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dimx=2;
dimX=dimx*kbar;
dimZ=6;
dimuj=4;
dimu=4;
dimY=2;
dimPub=2;
dimPriv=4;
dimS=dimu+dimuj;

if dimZ >= dimu+dimuj;
    disp('Dear Sir, you may have a perfectly revealing equilibrium.')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Define matrix arrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Exogenously specified matrices
C=zeros(dimx,dimu,dimS);
R=zeros(dimZ,dimu,binmax);
Rj=zeros(dimZ,dimuj,binmax);

%Other useful stuff
e1=[1,zeros(1,dimX-1)];
e2=[0,1,zeros(1,dimX-2)];
H=[zeros(dimX,dimx) eye(dimX);];
H=H(:,1:end-dimx);

%Innovations to aggregate productivity and demand
C(1,1,1)=sigu;
C(1,1,2)=gamma*sigu;

C(2,2,1)=sigud;
C(2,2,2)=sigud;


%Private noise
Rj(1,1,1)=sigaj;
Rj(1,1,2)=sigaj;

Rj(2,4,1)=sigdj;
Rj(2,4,2)=sigdj;

Rj(3,2,1)=sigzj1;
Rj(3,2,2)=sigzj1;


Rj(4,3,1)=sigzj2;
Rj(4,3,2)=sigzj2;

%Public noise
R(5,:,1)=[0,0,0,sigur;];
R(5,:,2)=[0,0,0,sigur;];

R(6,:,1)=[0,0,sigmbd,0;];
R(6,:,2)=[0,0,sigmbd,0;];





D0=zeros(dimZ,dimX); %D used to find starting values
D0(1:2,1:2)=eye(2);
D0(3:6,1)=1;



P=zeros(dimX,dimX,binmax);
p=zeros(dimX,dimX,binmax);
K=zeros(dimX,dimZ,binmax);
L=zeros(dimZ,dimZ,binmax);
a=zeros(1,dimX,binmax);
b=zeros(1,dimX,binmax);
d=zeros(1,dimX,binmax);

RRj=zeros(dimZ,dimu+dimuj,binmax);
EE=1;




%Endogenously specified matrices
D=zeros(dimZ,dimX,binmax);
SigJ=zeros(dimX,dimX,binmax);
M=zeros(dimX,dimX,binmax);
N=zeros(dimX,dimu+dimuj,binmax);
N0st=zeros(dimX,dimu+dimuj);

Ast=[rho1,0;0,rho2;];
for j=1:dimx:dimX;
%         M0st(j:j+dimx-1,1:dimx)=Ast;
    M0st(j:j+dimx-1,j:j+dimx-1)=Ast;
    N0st(j:j+dimx-1,1:dimu)=C(:,:,1);
end
N0=N0st;

a0st=(lambda -lambda*delta*varphi)*e1;
b0st=(a0st*M0st*H)-fipi*a0st;





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%define and assign hyperparamters for iterative solution loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Diff=1;iter=1;


M0=M0st;
% N0=[N0st zeros(dimX,dimuj);];
N0st=N0;
R0=[R(:,:,2) Rj(:,:,1)];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Starting values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Step=ones(4,1)*0.1;
Hstep=0;
Diff=ones(1,4);DiffOld=ones(1,4);iter=0;

% p0=zeros(dimX,dimX);
p0=eye(dimX);%*0;
% P0=N0*N0';
P0=eye(dimX);%1e2*N0*N0';

SigJ0=eye(dimX);
L=eye(dimZ);
% IRFst=[[a0st;b0st;]*M0st*N0st  [a0st;b0st;]*M0st^(2)*N0st  [a0st;b0st;]*M0st^(5)*N0st [a0st;b0st;]*M0st^(10)*N0st];

% DiffIRF=1;
%%
while max(abs(Diff)) > tol;
    %%
  if max(max(abs(M0*H)))<= 1;
    a0=lambda*(b0st-e1)+lambda*delta*varphi*(b0st-e1) + beta*a0st*M0st*H;
    b0=e2+(a0st+b0st)*M0st*H-fipi*a0st-fiy*b0st;
  
  else
      a0=a0st;
      b0=b0st;
   
  end 
    
    D0(3,:)=a0;
    D0(4,:)=delta*a0 + b0;
    D0(5,:)=(1-theta(12))*fipi*a0 + (1-theta(12))*fiy*b0;
   
    
    
    %The Nimark Filter option
    L=(D0*M0)*p0*(D0*M0)'+(D0*N0+R0)*(D0*N0+R0)';
    K0=(M0*p0*(D0*M0)'+N0*N0'*D0'+N0*R0')/(L);
    p0=P0-K0*L*K0';
    P0=M0*p0*M0'+N0*N0';
    
    
    KD0M=K0*D0*M0;
    M0(dimx+1:end,:)=[KD0M(1:end-dimx,1:end-dimx) zeros(dimX-dimx,dimx)] + [zeros(dimX-dimx,dimx) M0(1:end-dimx,1:end-dimx)] - [zeros(dimX-dimx,dimx) KD0M(1:end-dimx,1:end-dimx)];
    
    
    KDN0=K0*D0*N0;
    KR0=K0*[R(:,:,1) Rj(:,:,1)*0];
    N0(dimx+1:dimX,:)=KDN0(1:end-dimx,:) + KR0(1:end-dimx,:) ;
    
%     IRF=[[a0;b0;]*M0st*N0st  [a0;b0;]*M0st^(2)*N0st  [a0;b0;]*M0st^(5)*N0st [a0;b0;]*M0st^(10)*N0st];
    
    SigJ0=(eye(dimX)-K0*D0)*M0*SigJ0*M0'*(eye(dimX)-K0*D0)'+K0*Rj(:,:,1)*Rj(:,:,1)'*K0';
    
    Step=(1-Hstep)*Step+Hstep*Step.*(DiffOld./Diff)';
    Step(1)=max([Step(1),0.00001;]);
    Step(2)=max([Step(2),0.00001;]);
    Step(3)=max([Step(3),0.1;]);
    Step(4)=max([Step(4),0.1;]);
    
    
    
    Step(1)=min([Step(1),1;]);
    Step(2)=min([Step(2),1;]);
    Step(3)=min([Step(3),1;]);
    Step(4)=min([Step(4),1;]);
   
    
    DiffOld=Diff;
    DiffM=max(max(abs(M0-M0st)));
    DiffN=max(max(abs(N0-N0st)));
    Diffa=max(max(abs(a0-a0st)));
    Diffb=max(max(abs(b0-b0st)));
  
    Diff=[DiffM,DiffN,Diffa,Diffb;];

    
    M0st=Step(1)*M0+(1-Step(1))*M0st;M0=M0st;
    N0st=Step(2)*N0+(1-Step(2))*N0st;N0=N0st;
    a0st=Step(3)*a0+(1-Step(3))*a0st;a0=a0st;
    b0st=Step(4)*b0+(1-Step(4))*b0st;b0=b0st;

    iter=iter+1;
    
%     %%
    if iter > 2000;
%         iter
%         Diff
        EE=0;
        
        M=[];
%         Diff=Diff*0;
        break
    end
end;
if EE==1;
    
    %assign (i.e. output) starting values
    for j=1:binmax;
        P(:,:,j)=P0;
        p(:,:,j)=p0;
        M(:,:,j)=M0;
        K(:,:,j)=K0;
        D(:,:,j)=D0;
         D(6,1,j)=0;
        N(:,:,j)=N0;
        a(:,:,j)=a0;
        b(:,:,j)=b0;
        L(:,:,j)=(D0*P0*D0'+[R(:,:,2) Rj(:,:,2)]*[R(:,:,2) Rj(:,:,2)]');
        SigJ(:,:,j)=SigJ0;
    end
    
    for j=2:2:binmax;
        D(6,1,j)=1;
        N(1:dimx,1:dimu,j)=C(:,:,2);
        R(:,:,j-1)=R(:,:,1);
        R(:,:,j)=R(:,:,2);
        Rj(:,:,j)=Rj(:,:,2);
        Rj(:,:,j-1)=Rj(:,:,1);
        RRj(:,:,j)=[R(:,:,j) Rj(:,:,j)];
        RRj(:,:,j-1)=[R(:,:,j-1) Rj(:,:,j-1)];
    end
end
catch
    EE=0;
    M=[];
end