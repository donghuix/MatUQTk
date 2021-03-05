function h = plot_val(ytrain_pc,ytrain,yval_pc,yval)
%This function is to plot validation of surrogate
h(1) = scatter(ytrain,ytrain_pc,72,'s','MarkerFaceColor','b', ...
                                       'MarkerEdgeColor','b', ...
                                       'MarkerFaceAlpha',0.4); hold on; grid on;
h(2) = scatter(yval,yval_pc,72,'o','MarkerFaceColor','r', ...
                                   'MarkerEdgeColor','r', ...
                                   'MarkerFaceAlpha',0.4);

l1 = min([min(ytrain) min(ytrain_pc) min(yval) min(yval_pc)]);
l2 = max([max(ytrain) max(ytrain_pc) max(yval) max(yval_pc)]);
xlim([l1 l2]); ylim([l1 l2]);
plot([l1 l2],[l1 l2],'k-','LineWidth',2);

set(gca,'FontSize',13);
xlabel('Model','FontSize',15,'FontWeight','bold');
ylabel('Surrogate','FontSize',15,'FontWeight','bold');

leg = legend('Training','Valiating');
leg.FontSize = 15;
leg.FontWeight = 'bold';
leg.Location = 'best';

end

