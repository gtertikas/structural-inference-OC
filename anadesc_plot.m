%% plots descriptives
% plots according to doplot

colors= cbrewer('qual','Set1',10);

%% doplot1
if doplot(1) ==1 && rundoplot(1)==1
    
    figure
    % -------- switches:
    % need to change it into file length/ mbs
    subplot(3,1,1)
    qname = {'exp'};
    bar(1:size(switchNR,2), mean(switchNR));hold all;
    errorbar(1:size(switchNR,2), mean(switchNR), getSE(switchNR),'k');
    for isub = 1:length(s.subID)
       plot(1+rand/10, switchNR(isub,:),'o','LineWidth',2);hold all; 
    end
    set_default_fig_properties(gca,gcf);hold all;
    set(gca,'box','off');
    set(gca,'XTick',1:length(qname));
    set(gca,'XTickLabel', qname,'FontSize',14);
    xtickangle(30)
    ylabel('nr switches')
    
    
    
    subplot(3,1,2)
    
   
        bar(1:size(acceptR,2), 0.5-mean(acceptR));hold all;
        errorbar(1:size(acceptR,2), 0.5-mean(acceptR),getSE(acceptR));
        for isub = 1:length(s.subID)
            plot(1:size(acceptR,2)+rand/10, 0.5-acceptR(isub,:),'o');
        end
   
    set_default_fig_properties(gca,gcf);hold all;
    set(gca,'box','off');
    set(gca,'XTick',1:length(blockn));
    set(gca,'XTickLabel', blockn,'FontSize',14);
    xtickangle(30)
    ylabel('0.5 - % accept')
    
    subplot(3,1,3)
    

        bar(1:size(binarypay,2), mean(binarypay));hold all;
        errorbar(1:size(binarypay,2), mean(binarypay),getSE(binarypay));
        for isub = 1:size(s.subID)
            plot(1:size(binarypay,2)+rand/10, binarypay(isub,:),'o');
        end
    
    set_default_fig_properties(gca,gcf);hold all;
    set(gca,'box','off');
    set(gca,'XTick',1:length(blockn));
    set(gca,'XTickLabel', blockn,'FontSize',14);
    xtickangle(30)
    ylabel('% payoff')
   
    
    
    
end

%% doplot2: reversal accross all trials

if doplot(2) ==1 && rundoplot(2)==1
    
    close all;
        qname = {'prac1:full FB';'prac2:partial';'exp:partial'};
  figure
  subcount=1;
    for ip = 1:length(phase.FB)
         subplot(3, 3,subcount)
        title(qname{ip});hold all;
        plot(phase.FB{ip});hold all;
        plot(find(phase.switchY{ip}==1),1,'ro','LineWidth',2);
        
        set_default_fig_properties(gca,gcf);hold all;
        set(gca,'box','off');
        ylabel('% accuracy')
        
        ylim([0 1])
        subcount=subcount+1;
    end
    
    
    
    
    % -------
   
    plt=[];sn ={'implicit';'explicit'};
    for is = 1:2
         subplot(3, 3,subcount)
        title(sn{is});hold all;
        plt{is} = plot(phase.allch_acc{6}.stim(:,is),'LineWidth',1);hold all;
        
        set_default_fig_properties(gca,gcf);hold all;
        set(gca,'box','off');
        ylabel('% accuracy')
        subcount=subcount+1;
    end
    
     % -------
  
     subplot(3, 3,subcount)
    title('hidden');hold all;
    plt{is} = plot(phase.allch_acc{6}.hid ,'LineWidth',1);hold all;
    
    set_default_fig_properties(gca,gcf);hold all;
    set(gca,'box','off');
    ylabel('% accuracy')
     subcount=subcount+1;
 % -------
    subplot(3, 3,subcount)
    for ip =1:3
        plt{ip} = plot(1:3, phase.stimacc_phase(ip,:),'Color',colors(ip,:),'LineWidth',2);hold all;
    end
    
    set_default_fig_properties(gca,gcf);hold all;
    set(gca,'box','off');
    ylabel('% accuracy')
    legend([plt{:}],{'prac1';'prac2';'exp'})
    ylim([0 1])
    set(gca,'XTick',1:3);
    set(gca,'XTickLabel', {'implicit';'explicit';'hidden'},'FontSize',14);
    subcount=subcount+1;
    
end


%% doplot 3: plot reversals averaged across 4 choices


if doplot(3) ==1 && rundoplot(3)==1
    
    % ---- 1. payoff for each phase
    figure
    plt=[];
    for ip =1:3
        for isub = 1:length(s.subID)
            varsub{ip}(isub,:) =  phasesub{isub}.phase.stimacc_phase(ip,:);
            
            
        end
        
        plt{ip}=plot(1:3, mean(varsub{ip}),'LineWidth',4); hold all;
        errorbar(1:3, mean(varsub{ip}), getSE(varsub{ip}),'k')
        %for isub = 1:length(s.subID)
        %   plot(1:3, varsub{ip}(isub,:),'o','LineWidth',2)
        %end
        set_default_fig_properties(gca,gcf);hold all;
        set(gca,'box','off');
        ylabel('% accuracy')
        
        ylim([0 1])
        set(gca,'XTick',1:3);
        set(gca,'XTickLabel', {'implicit';'explicit';'hidden'},'FontSize',14);
        xlim([0.8 3.1])
    end
    legend([plt{:}],{'prac1';'prac2';'exp'})
    
    % --- reversal for each sub averaged across 4 choices
    
    
    
    figure
    
    for isub = 1:length(s.subID)
        
        
        curpay =  phasesub{isub}.avg{end}.avgpayoff;
        avgpaysub(isub) = mean(curpay);
        cursw  = phasesub{isub}.avg{end}.avgswitch;
        subplot(round(length(s.subID)/2),round(length(s.subID)/2),isub)
        title(['sub: ' num2str(isub)]);hold all;
        plot(curpay);hold all;
        plot(cursw,'ko');
        set_default_fig_properties(gca,gcf);hold all;
        set(gca,'box','off');
        ylabel('payoff')
        
    end
    
    
    % --- plot payoff according to reversal
    
    preconf=[];postconf=[];
    for isub=1:length(s.subID)
        curpay =  phasesub{isub}.avg{end}.avgpayoff;
        cursw  =  phasesub{isub}.avg{end}.avgswitch;
        curim  = phasesub{isub}.avg{end}.avgallFB;
        if s.sub{isub}.choice4==1
          curconf =  phasesub{isub}.avg{end}.avgallconf;
        else
            curconf=[];
        end
        
        swidx = find(cursw==1);preidx=[];postidx=[];
        for is = 1:length(swidx)
               preidx = [preidx; swidx(is)-4:swidx(is)-1 ];
               postidx = [postidx; swidx(is):swidx(is)+3 ] ;      
        end
        
        swnr(isub) = size(postidx,1);
        var=[];var=curpay(postidx(:,3:4));
        post_imp_mean(isub) = mean(var(:));
        pre_exp_mean(isub) = mean(mean(curpay(preidx(:,1:2))));
        
        prepay(isub,:) = mean(curpay(preidx));
        postpay(isub,:) = mean(curpay(postidx));  
        
        if numel(curconf)>0
        preconf= [preconf; mean(curconf(preidx))];
        postconf= [postconf ;mean(curconf(postidx))];
     
        
        
        
        
        end
        
        post_meanim{isub} =mean(curpay(postidx(:,3:end))');
        
        
    end
    

    figure
    plt=[];
    plt{1}=plot(1:4, mean(prepay),'LineWidth',3);hold all;
    for isub =1:length(s.subID)
        plot(1:4+rand/10, prepay(isub,:),'o');hold all;
    end
    errorbar(1:4, mean(prepay), getSE(prepay),'k');hold all;
    plt{2}=plot(5:8, mean(postpay),'LineWidth',3);hold all;
    for isub =1:length(s.subID)
        plot(5:8+rand/10, postpay(isub,:),'o');hold all;
    end
    errorbar(5:8, mean(postpay), getSE(postpay),'k')
    set_default_fig_properties(gca,gcf);hold all;
    set(gca,'box','off');
    ylabel('payoff')
    legend([plt{:}],{'preMB';'postMB'})
    xlim([0.8 8.1])
    
    colors= cbrewer('div','RdGy',length(s.subID));

    figure
    vars = [mean(prepay(:,1:2)')' mean(prepay(:,3:4)')' mean(postpay(:,1:2)')' mean(postpay(:,3:4)')'];
    for ivar =1:size(vars,2)
    bar(ivar, mean(vars(:,ivar)),'FaceColor','k');hold all;
    errorbar(ivar, mean(vars(:,ivar)),getSE(vars(:,ivar)),'k');
    for isub =1:length(s.subID)
        plot(ivar+rand/5, vars(isub,ivar),'o','Color',colors(isub,:),'LineWidth',4);
    end
    end
    set_default_fig_properties(gca,gcf);hold all;
    set(gca,'box','off');
    set(gca,'XTick',1:4);
    set(gca,'XTickLabel', {'preEX';'preIM';'postEX';'postIM'},'FontSize',14);
    ylabel('performance')
    
    
    
    
    
    
%     figure
%     plt=[];
%     plt{1}=plot(1:4, mean(preconf),'LineWidth',3);hold all;
%     for isub =1:length(preconf)
%         plot(1:4+rand/10, preconf(isub,:),'o');hold all;
%     end
%     errorbar(1:4, mean(preconf), getSE(preconf),'k');hold all;
%     
%     plt{2}=plot(5:8, mean(postconf),'LineWidth',3);hold all;
%     for isub =1:length(postconf)
%         plot(5:8+rand/10, postconf(isub,:),'o');hold all;
%     end
%     errorbar(5:8, mean(postconf), getSE(postconf),'k')
%     set_default_fig_properties(gca,gcf);hold all;
%     set(gca,'box','off');
%     ylabel('confidence')
%     legend([plt{:}],{'preMB';'postMB'})
%     xlim([0.8 8.1])
%     
    
    figure
    subplot(2,1,1)
    bar(1,mean(swnr));hold all;
    errorbar(1,mean(swnr),getSE(swnr'),'k')
    for isub =1:length(s.subID)
       plot(1+rand/5, swnr(isub),'ko','Linewidth',1) 
    end
    ylabel('nr switches')
    set_default_fig_properties(gca,gcf);hold all;
    set(gca,'box','off');
    
    subplot(2,1,2)
    hist(swnr,10)
    set_default_fig_properties(gca,gcf);hold all;
    set(gca,'box','off');
    ylabel('frequency')
    
    % ---
   
    colors= cbrewer('qual','Accent',7);
    figure
    title('post-switch first MB');hold all;
    %for isub =1:length(s.subID)-10
    for isub =1:7
        plot(post_meanim{isub}+rand/5,'Color',colors(isub,:),'LineWidth',2);hold all;
        set_default_fig_properties(gca,gcf);hold all;
        set(gca,'box','off');
        ylabel('accuracy');
        xlabel('nr of switches')
    end
    
    figure
    [r ,p]= corrcoef(post_imp_mean, swnr);
    title(['corr:' num2str(r(2)) ';pval:' num2str(p(2))]);hold all;
    plot(post_imp_mean, swnr,'ko')
    set_default_fig_properties(gca,gcf);hold all;
    set(gca,'box','off');
    ylabel('nr switches');
    xlabel('perf implicit post switch')
    ylim([0 6])
    xlim([0 1])
    
    overallperf = swnr/6.*post_imp_mean;
    keyboard
    figure
    title('switchNr/6 x performance implicit post switch');hold all;
    bar(1,mean(overallperf));hold all;
    errorbar(1,mean(overallperf),getSE(overallperf'),'k')
    for isub =1:length(s.subID)
       plot(1+rand/5, overallperf(isub),'ko','Linewidth',1) 
    end
    ylabel('overall perf')
    set_default_fig_properties(gca,gcf);hold all;
    set(gca,'box','off');
    
    for isub =1:length(s.subID)
        slider(isub) = s.sub{isub}.info.perf_slider(1);
    end
    
    
    figure
    subplot(3,1,1)
    [r ,p]= corrcoef(swnr, slider);
    title(['corr:' num2str(r(2)) ';pval:' num2str(p(2))]);hold all;
    plot(swnr, slider,'ko')
    set_default_fig_properties(gca,gcf);hold all;
    set(gca,'box','off');
   
    xlabel('nr switches');
    ylabel('slider: subj perf')
    
    subplot(3,1,2)
    [r ,p]= corrcoef(post_imp_mean, slider);
    title(['corr:' num2str(r(2)) ';pval:' num2str(p(2))]);hold all;
    plot(post_imp_mean, slider,'ko')
    set_default_fig_properties(gca,gcf);hold all;
    set(gca,'box','off');
    xlim([0 1])
    xlabel('postS_implicit perf');
    ylabel('slider: subj perf')
    
    subplot(3,1,3)
    [r ,p]= corrcoef(overallperf, slider);
    title(['corr:' num2str(r(2)) ';pval:' num2str(p(2))]);hold all;
    plot(overallperf, slider,'ko')
    set_default_fig_properties(gca,gcf);hold all;
    set(gca,'box','off');
    xlim([0 1])
    xlabel('overall perf measure');
    ylabel('slider: subj perf')
    
    
    
    
    
    % save performance variables:
    s.perf.overall = overallperf;
    s.perf.nrsw    = swnr;
    s.perf.imppostsw = post_imp_mean;
    
        
        
end







