clc, clear all, close all
%{
 ----------------------------------------
Fluent parametric AoA 
September 2023
Author: Fatih Demirtaş
Used information from; 
*Sorin @ https://www.cfd-online.com/Forums/fluent/46143-looking-smart-interface-matlab-fluent.html
*and https://dl.cfdexperts.net/cfd_resources/Ansys_Documentation/Fluent/Ansys_Fluent_as_a_Server_Users_Guide.pdf
FLUENT_AAS=1
!!!Warning: can slow down workbench project. 
On the other hand, the problem haven't experienced in Standalone yet!!!
-----------------------------------------
%}

fluent = actxserver('ANSYS.CoFluentUnit');
tui=fluent.getSchemeControllerInstance();
fid=fopen('aaS_FluentId.txt','r');
fluentkey=fscanf(fid,'%s');
fclose(fid);
fluent.ConnectToServer(fluentkey)
%-------------------------------------------------------------------------%
%***%
aoa=[0,1:2];
itcount=100;
%***%
angle=deg2rad(aoa);
c=0;
for k=1:length(angle)

i=length(angle)-k+1

%inlet
%x
tui.DoMenuCommandToString(sprintf('setup boundary-conditions pressure-far-field edit inlet flow-direction edit 1 value %d',cos(angle(i))));
%y
tui.DoMenuCommandToString(sprintf('setup boundary-conditions pressure-far-field edit inlet flow-direction edit 2 value %d',0));
%z
tui.DoMenuCommandToString(sprintf('setup boundary-conditions pressure-far-field edit inlet flow-direction edit 3 value %d',sin(angle(i))));

%sides
%x
tui.DoMenuCommandToString(sprintf('setup boundary-conditions pressure-far-field edit sides flow-direction edit 1 value %d',cos(angle(i))));
%y
tui.DoMenuCommandToString(sprintf('setup boundary-conditions pressure-far-field edit sides flow-direction edit 2 value %d',0));
%z
tui.DoMenuCommandToString(sprintf('setup boundary-conditions pressure-far-field edit sides flow-direction edit 3 value %d',sin(angle(i))));


%cl
tui.DoMenuCommandToString(sprintf(' solve report-definitions edit cl force-vector -%d 0 %d',sin(angle(i)),cos(angle(i))));
%cd
tui.DoMenuCommandToString(sprintf(' solve report-definitions edit cd force-vector %d 0 %d',cos(angle(i)),sin(angle(i))));
try
    tui.DoMenuCommandToString('solve initialize hyb-initialization yes')
catch
    tui.DoMenuCommandToString('solve initialize hyb-initialization')
end

tui.DoMenuCommandToString('solve initialize fmg-initialization yes')
%}
try
    proceed=tui.DoMenuCommandToString(sprintf('solve iterate 1 ok %d',itcount))
catch
    proceed=tui.DoMenuCommandToString(sprintf('solve iterate %d',itcount))
end

while 1
    checkcon=input('Is solution converged? ','s')
    if strcmpi(checkcon,'no')
        moreiter=input('please enter iteration number: ')
        tui.DoMenuCommandToString(sprintf('solve iterate %d',moreiter))
        itcount=itcount+moreiter;
    elseif strcmpi(checkcon,'yes')
        break
    else
        fprintf('not valid input \n')
    end
    
end
tui.DoMenuCommandToString('file write-case-data ')        
tui.DoMenuCommandToString(sprintf('display save-picture residual_%.2f',rad2deg(angle(i))))
saved(1) = copyfile('./*.cas.h5', sprintf('AngleOfAttack/%.2f',rad2deg(angle(i))));
saved(2) = copyfile('./*.dat.h5', sprintf('AngleOfAttack/%.2f',rad2deg(angle(i))));
%saved(3) = copyfile(sprintf('./residual_%.2f.png',rad2deg(angle(i))), 'AngleOfAttack');
saved(3) = copyfile('./residual_*.png', 'AngleOfAttack/');
saved(4) = copyfile('./cl-rfile.out', sprintf('AngleOfAttack/cl-rfile%.2f.out',rad2deg(angle(i))));
saved(5) = copyfile('./cd-rfile.out', sprintf('AngleOfAttack/cd-rfile%.2f.out',rad2deg(angle(i))));
saved(6) = copyfile('./cm-rfile.out', sprintf('AngleOfAttack/cm-rfile%.2f.out',rad2deg(angle(i))));
saved
%mkdir('./AngleOfAttack',sprintf('%.2f',rad2deg(angle(i))))
tui.DoMenuCommandToString('solve report-plots clear-data cm-rplot cl-rplot cd-rplot')
tui.DoMenuCommandToString('solve report-files clear-data cm-rfile cl-rfile cd-rfile  ')
tui.DoMenuCommandToString('solve monitors residual reset? yes')
end




