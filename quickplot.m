filename    = 'calorimeter.txt';
%'tests_data/calorimeter_120618.txt';

graphics_toolkit("gnuplot");

%pkg load signal

while 1,

  %if exist('filename') == 0,
  try
    fid         = fopen(filename,'r');
    %cellDATA    = textscan(fid,'%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%d:%d:%d-%d/%d/%d');
    cellDATA 	= textscan(fid,'%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%d:%d:%d-%d/%d/%d');
    fclose(fid);
  catch
    continue;
  end_try_catch

    % Remove jitters
    for jj = 2 : 8
      sig_ = cellDATA{jj};
      for ii = 2 : numel(cellDATA{1})-1
        if sig_(ii-1) == sig_(ii+1) && sig_(ii) ~= sig_(ii-1)
            sig_(ii) = sig_(ii-1);
        end
      end
    cellDATA{jj} = sig_;
    end

    TIME        = cellDATA{1};
    TA1         = cellDATA{2};
    TA2         = cellDATA{3};
    TA3         = cellDATA{4};
    TW1         = cellDATA{5};
    TW2         = cellDATA{6};
    TW3         = cellDATA{7};
    TWm         = cellDATA{8};
    hh          = cellDATA{9};
    mm          = cellDATA{10};
    ss          = cellDATA{11};
    DD          = cellDATA{12};
    MM          = cellDATA{13};
    YY          = cellDATA{14};

    dateLabel   = sprintf('%d:%d:%d, %d/%d/%d',hh(end),mm(end),ss(end),DD(end),MM(end),YY(end));

    TIMEn       = TIME - TIME(1);
    %ts          = mean(Dt);

    % Data for determination
    rho = 998.2; % kg/m3
    c = 4182.6; % J/kg.K
    V = 0.040224; % m3
    C = rho*c*V; % in J/K
    R = 1.17; % K/W
    tau = R*C;
    %Cpoly = [1833.8, 1.6645e+05]; % correction factor

    % Obtain the heat Power
    x           = TIMEn;
    toPrint = 'There are NOT enough data';
    if numel(x) > 2
      Y           = [TW1,TW2,TW3];
      % preprocess preprocess
      for iy = 1 : 3
        Y(:,iy) = Y(:,iy) - min(Y(:,iy));
      end

      y = mean(Y,2);

      chosen = [true;diff(y)>0];
      xx = x(chosen);
      yy = y(chosen);

      R21 = nan(numel(xx),1);
      R22 = R21;
      Heat1 = R21;
      Heat2 = R22;

      % Perform the algorithm
      for kk = 2 : numel(xx)
          % Assume current data
          x_curr  = xx(1:kk);
          y_curr  = yy(1:kk);

          % Find coefficients
          beta1    = polyfit(x_curr,y_curr,1);
          y_eval1  = polyval(beta1,x_curr);

          % Using the known value of tau
          new_x   = 1 - exp(-x_curr/tau);
          beta2    = polyfit(new_x,y_curr,1);
          y_eval2  = polyval(beta2,new_x);

          % Obtain R2
          SStot   = norm(y_curr - mean(y_curr))^2;
          SSres1   = norm(y_curr - y_eval1)^2;
          SSres2   = norm(y_curr - y_eval2)^2;
          if SStot ~= 0, R21(kk)  = 1 - SSres1/SStot;  else,  R21(kk) = nan;  end
          if SStot ~= 0, R22(kk)  = 1 - SSres2/SStot;  else,  R22(kk) = nan;  end

          % Determinate
          Heat1(kk) = C*beta1(end-1);
          Heat2(kk) = beta2(1)/R*0.85 + 0.28;
      end

      [HeatPower1,iHP] = max(Heat1);
      HeatPower2 = Heat2(iHP);
      Time2 = xx(iHP)/3600;

      %[~,iHP] = min(1-R2);
      %HeatPower = Heat(iHP);
      %Time = x(iHP)/3600;
      toPrint = sprintf('Q = %.4f W at %.2f h',HeatPower2,Time2);

    %graphics_toolkit gnuplot

    % First plot - Air and Water temperatures
    f = figure('visible','off');
    plot(TIMEn/3600,[TA1,TA2,TA3,TW1,TW2,TW3,TWm],'-','linewidth',2);
    l1 = legend('Air 1','Air 2','Air 3','Water 1','Water 2','Water 3','Water Avg.');
    set(l1, 'location','northoutside','Orientation','horizontal','box','off');
    title(['Last Update: ',dateLabel],'fontsize',16);
    xlabel('Time, t [h]','fontsize',16);
    ylabel('Temperature, T [degC]','fontsize',16);
    set(gca,'fontsize',16);
    print -djpg /var/www/html/figure1.jpg;

    % Second plot - Water temperature
    f = figure('visible','off');
    %toPrint = sprintf('Q = %.4f W at %.2f h',HeatPower,Time);
    %
    subplot(211),
    plot(x_curr/3600,Heat1,'r','linewidth',2), hold on,
    plot(x_curr/3600,Heat2,'b','linewidth',2), hold off,
    l2 = legend('Linear Fit','Exponential Fit');
    set(l2,'location','southeast','box','off')
    ylabel('Heat Power, dQ/dt [W]','fontsize',16),
    xlabel('Time, t [h]','fontsize',16)
    title(toPrint,'fontsize',16);
    set(gca,'fontsize',16);
    %
    yR21 = 1 - R21; yR21(yR21 == 0) = nan;
    yR22 = 1 - R22; yR22(yR22 == 0) = nan;
    subplot(212),
    semilogy(x_curr/3600,yR21,'r','linewidth',2), hold on
    semilogy(x_curr/3600,yR22,'b','linewidth',2), hold off
    l3 = legend('Linear Fit','Exponential Fit');
    set(l3,'location','northwest','box','off')
    ylabel('FVU = 1 - R^2','fontsize',16),
    xlabel('Time, t [h]','fontsize',16);

    set(gca,'fontsize',16);
    print -djpg /var/www/html/figure2.jpg;

    close all;
    system("sudo tail -n 5 /home/pi/calorimeter.txt > /var/www/html/calorimeter-tail.txt");

    end
    pause(60*5)

endwhile
