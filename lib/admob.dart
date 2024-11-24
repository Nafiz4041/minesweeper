import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

final List<String> testDeviceIds = [
  "a32c5b41-837a-4ccb-a49f-85a7f10ddb8a",//zaman
  "154dc959-1866-4f8a-8585-32c2c0f556a0",//nafiz emulator
];

const int maxFailedLoadAttempts = 3;
//add request
final AdRequest request = AdRequest(
  keywords: <String>['foo', 'bar'],
  contentUrl: 'http://foo.com/bar.html',
  nonPersonalizedAds: true,
);

//intialize admob here
void createRewardedInterstitialAd() {
  RewardedInterstitialAd.load(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5354046379'
          : 'ca-app-pub-3940256099942544/6978759866',
      request: request,
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          print('$ad loaded.');
          rewardedInterstitialAd = ad;
          numRewardedInterstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('RewardedInterstitialAd failed to load: $error');
          rewardedInterstitialAd = null;
          numRewardedInterstitialLoadAttempts += 1;
          if (numRewardedInterstitialLoadAttempts < maxFailedLoadAttempts) {
            createRewardedInterstitialAd();
          }
        },
      ));
}

void showRewardedInterstitialAd() {
  if (rewardedInterstitialAd == null) {
    print('Warning: attempt to show rewarded interstitial before loaded.');
    return;
  }
  rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
    onAdShowedFullScreenContent: (RewardedInterstitialAd ad) =>
        print('$ad onAdShowedFullScreenContent.'),
    onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
      print('$ad onAdDismissedFullScreenContent.');
      ad.dispose();
      createRewardedInterstitialAd();
    },
    onAdFailedToShowFullScreenContent:
        (RewardedInterstitialAd ad, AdError error) {
      print('$ad onAdFailedToShowFullScreenContent: $error');
      ad.dispose();
      createRewardedInterstitialAd();
    },
  );

  rewardedInterstitialAd!.setImmersiveMode(true);
  rewardedInterstitialAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
    print('$ad with reward $RewardItem(${reward.amount}, ${reward.type})');
  });
  rewardedInterstitialAd = null;
}

RewardedInterstitialAd? rewardedInterstitialAd;
int numRewardedInterstitialLoadAttempts = 0;
