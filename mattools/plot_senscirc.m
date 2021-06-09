function plot_senscirc(ax,allmain,alljoint,maxcirclesize,minjoint,maxlinewidth,paranames,add_legend)
    npara = length(allmain);
    
    if isempty(maxcirclesize)
        maxcirclesize = 0.4;
    end
    if isempty(minjoint)
        minjoint      = 0.01;
    end
    if isempty(maxlinewidth)
        maxlinewidth  = 300;
    end
    npts = 800;
    thi2 = 0:pi/(npts/2-0.5):2*pi;
    thi = [thi2(npts/4+1:npts) thi2(1:npts/4)]; clear thi2;
        
    if add_legend
        % add legend for main sensitivity
        nleg = 5;
        %mainleg = min(allmain) : (max(allmain)-min(allmain))/(nleg-1) : max(allmain);
        mainleg = [0.01 0.1 0.2 0.3 0.4];
        yi = -1:2./(nleg-1):1;
        xi = zeros(nleg,1);
        for i = 1 : nleg
            xii = mainleg(i) * maxcirclesize * cos(thi)+0;
            yii = mainleg(i) * maxcirclesize * sin(thi)+yi(i);
            plot(ax,xii,yii,'k-','LineWidth',3);axis equal; hold on;
            fill(ax,xii,yii,[248, 187, 0]./255);
            text(ax,xi(i)-0.075,min(yii)-0.075,num2str(mainleg(i)),'fontsize',12);
        end
        ylim([-1.4 1.4]);
        xlim([-1.4 1.4]);
        
        % add parameter names
        yi = 1:-2/(npara-1):-1;
        for i = 1 : npara
            if i < 10
                text(ax,-1.2,yi(i),[num2str(i) ':  ' paranames{i}],'fontsize',14);
            else
                text(ax,-1.2,yi(i),[num2str(i) ': ' paranames{i}],'fontsize',14);
            end
        end
        
        % add legend for joint sensitivity
        jointleg = 0.01 : 0.01 : 0.05;
        yi = -1:2./(nleg-1):1;
        xi = ones(nleg,1);
        for i = 1 : nleg
            yii = mainleg(i) * maxcirclesize * sin(thi)+yi(i);
            plot([xi(i) - 0.1 xi(i) + 0.1],[yi(i) yi(i)],'-','Color',...
                 [99, 189, 179]./255,'LineWidth',maxlinewidth*jointleg(i));
            text(ax,xi(i)-0.075,min(yii)-0.075,num2str(jointleg(i)),'fontsize',12);
        end
        set(ax,'XTick',[],'YTick',[]);
    else
        th2 = 0:pi/99.5:2*pi;
        th = [th2(51:200) th2(1:50)]; clear th2;

        xunit = 1 * cos(th);
        yunit = 1 * sin(th);

        plot(ax,xunit,yunit,'-','Color',[225, 18, 49]./255,'LineWidth',3);axis equal; hold on;

        xpara = xunit(1:floor(length(xunit)/npara):end);
        ypara = yunit(1:floor(length(xunit)/npara):end);
        xpara = xpara(1:npara);
        ypara = ypara(1:npara);

        [sortmain,ind] = sort(allmain,'descend');
        % Plot joint sensitivity first
        for i = 1 : 11
            for j = 1 : 11
                if i ~= j && alljoint(ind(i),ind(j)) > minjoint
                    plot(ax,[xpara(i) xpara(j)],[ypara(i) ypara(j)],'-','Color',[99, 189, 179]./255,'LineWidth',maxlinewidth.*alljoint(ind(i),ind(j)));
                end
            end
        end



        k = 1;
        for i = ind
            xi = allmain(i) * maxcirclesize * cos(thi)+xpara(k);
            yi = allmain(i) * maxcirclesize * sin(thi)+ypara(k);
            plot(ax,xi,yi,'k-','LineWidth',3);axis equal; hold on;
            fill(ax,xi,yi,[248, 187, 0]./255);
            if k*floor((npts+100)/npara) > npts
                text(ax,xi(k*floor((npts+100)/npara)-npts)*1.075, ...
                        yi(k*floor((npts+100)/npara)-npts)*1.075, ...
                        num2str(i),'FontSize',12);
            else
                text(ax,xi(k*floor((npts+100)/npara))*1.075, ...
                        yi(k*floor((npts+100)/npara))*1.075, ...
                        num2str(i),'FontSize',12);
            end

            %scatter(xpara(k),ypara(k),sz(i),'o','MarkerFaceColor',[248, 187, 0]./255,'MarkerEdgeColor','k');
            k = k + 1;
        end


        ylim([-1.4 1.4]);
        xlim([-1.4 1.4]);
        set(ax,'XTick',[],'YTick',[]);
    end
end
