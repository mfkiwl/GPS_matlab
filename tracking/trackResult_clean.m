function trackResult = trackResult_clean(trackResult)
% ������ٽ���еĿհ׿ռ�

n = trackResult.n;

trackResult.dataIndex(n:end,:)    = [];
trackResult.ts0(n:end,:)          = [];
trackResult.remCodePhase(n:end,:) = [];
trackResult.codeFreq(n:end,:)     = [];
trackResult.remCarrPhase(n:end,:) = [];
trackResult.carrFreq(n:end,:)     = [];
trackResult.I_Q(n:end,:)          = [];
trackResult.disc(n:end,:)         = [];
trackResult.bitStartFlag(n:end,:) = [];
trackResult.CN0(n:end,:)          = [];
trackResult.carrAcc(n:end,:)      = [];
trackResult.strength(n:end,:)     = [];

end