function [sys,x0,str,ts,simStateCompliance] = nnbp(t,x,u,flag,T,nh,xite,alfa)
switch flag,
  case 0,
    [sys,x0,str,ts,simStateCompliance]=mdlInitializeSizes(T,nh);
%��ʼ������
  case 3,
    sys=mdlOutputs(t,x,u,nh,xite,alfa);
%�������
  case {1,2,4,9},
    sys=[];
  otherwise
    DAStudio.error('Simulink:blocks:unhandledFlag', num2str(flag));
end
function [sys,x0,str,ts,simStateCompliance]=mdlInitializeSizes(T,nh)
%���ó�ʼ�������������ⲿ������� ����Tȷ������ʱ�䣬����nhȷ�����������
sizes = simsizes;
sizes.NumContStates  = 0;
sizes.NumDiscStates  = 0;
sizes.NumOutputs     = 4+6*nh;
%��������������������Ʊ���u,������+��������м�Ȩϵ��
sizes.NumInputs      = 7+12*nh;
%�����������������ǰ7������[e(k);e(k-1);e(k-2);y(k);y(k-1);r(k);u(k-1)]
%������+�����Ȩֵϵ����k-2),������+�����Ȩֵϵ����k-1��
sizes.DirFeedthrough = 1;
sizes.NumSampleTimes = 1; 
sys = simsizes(sizes);
x0  = [];
str = [];
ts  = [T 0];
simStateCompliance = 'UnknownSimState';
function sys=mdlOutputs(t,x,u,nh,xite,alfa)
%�����������
wi_2 = reshape(u(8:7+3*nh),nh,3);
%�����㣨k-2)Ȩֵϵ������ά��nh*3
wo_2 = reshape(u(8+3*nh:7+6*nh),3,nh);
%����㣨k-2��Ȩֵϵ������ά��3*nh
wi_1 = reshape(u(8+6*nh:7+9*nh),nh,3);
%�����㣨k-1)Ȩֵϵ������ά��nh*3
wo_1 = reshape(u(8+9*nh:7+12*nh),3,nh);
%����㣨k-1��Ȩֵϵ������ά��3*nh
xi = [u(6),u(4),u(1)];
%�����������xi=[u(6),u(4),u(1)]=[r(k),y(k),e(k)]
xx = [u(1)-u(2);u(1);u(1)+u(3)-2*u(2)];
%xx=[u(1)-u(2);u(1);u(1)+u(3)-2*u(2)]=[e(k)-e(k-1);e(k);e(k)+e(k-2)-2*e(k-1)]
I = xi*wi_1';
%��������������룬I=�����������*������Ȩֵϵ�������ת��wi_1'�����Ϊ��
%I=[net0(k),net1(k)...netnh(k)]Ϊ1*nh����
Oh = exp(I)./(exp(I)+exp(-I));
%��������ɸ���
%����������������(exp(I)-exp(-I))./(exp(I)+exp(-I))Ϊ������ļ����Sigmoid
%Oh=[o0(k),o1(k)...onh(k)],Ϊ1*nh�ľ���
O = wo_1*Oh';
%�������������룬ά��3*1
K = 2./(exp(O)+exp(-O)).^2;
%��������ɸ���
%�������������K=[Kp,Ki,Kd]��ά��Ϊ1*3
%exp(Oh)./(exp(Oh)+exp(-Oh))Ϊ�����ļ����Sigmoid
uu = u(7)+K'*xx;
%��������ʽPID�����㷨������Ʊ���u(k)
dyu = sign((u(4)-u(5))/(uu-u(7)+0.0000001));
%����������Ȩϵ��������ʽ��sgn
%sign((y(k)-y(k-1))/(u(k)-u(k-1)+0.0000001)���ƴ���ƫ��
dK = 2./(exp(K)+exp(-K)).^2;
%��������ɸ���
delta3 = u(1)*dyu*xx.*dK;
wo = wo_1+xite*delta3*Oh+alfa*(wo_1-wo_2);
%������Ȩϵ�����������
dOh = 2./(exp(Oh)+exp(-Oh)).^2;
%��������ɸ���
wi = wi_1+xite*(dOh.*(delta3'*wo))'*xi+alfa*(wi_1-wi_2);
%�������Ȩϵ������
sys = [uu;K(:);wi(:);wo(:)];
%��������sys=[uu;K(:);wi(:);wo(:)]=
%[uu;Kp;Ki;Kd;������+���������Ȩֵϵ��]
%K(:),wi(:),wo(:),������������˳����Ϊ������
