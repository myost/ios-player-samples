//
//  ViewController.m
//  BasicPulsetvOSPlayer
//
//  Created by Carlos Ceja on 2/14/20.
//  Copyright © 2020 Carlos Ceja. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Pulse_tvOS/Pulse.h>
#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>
#import <BrightcovePulse/BrightcovePulse.h>

#import "ViewController.h"


static NSString * const kServicePolicyKey = @"insertyourservicepolicykeyhere";
static NSString * const kAccountID = @"insertyouraccountidhere";
static NSString * const kVideoID = @"insertyourvideoidhere";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPulsePlaybackSessionDelegate>

@property (nonatomic, weak) IBOutlet UIView *videoContainer;

@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) id<BCOVPlaybackSessionProvider> pulseSessionProvider;

@property (nonatomic, strong) BCOVTVPlayerView *playerView;
@property (nonatomic, strong) BCOVVideo *video;

@end


@implementation ViewController

- (void)viewDidLoad
{
    
    [OOPulse logDebugMessages:YES];
    [super viewDidLoad];
    
    [self setupPlayerView];
    [self setupPlaybackController];
    [self requestVideo];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark Misc

- (void)requestVideo
{
    BCOVPlaybackService *playbackService = [[BCOVPlaybackService alloc] initWithAccountId:kAccountID policyKey:kServicePolicyKey];
    
    __weak typeof(self) weakSelf = self;
    
    [playbackService findVideoWithVideoID:kVideoID parameters:nil completion:^(BCOVVideo *video, NSDictionary *jsonResponse, NSError *error) {
        
        if (video)
        {
            [weakSelf.playbackController setVideos:@[ video ] ];
        }
        else
        {
             NSLog(@"PlayerViewController Debug - Error retrieving video");
        }
        
    }];
}

- (void)setupPlayerView
{
    BCOVTVPlayerViewOptions *options = [[BCOVTVPlayerViewOptions alloc] init];
    options.presentingViewController = self;
    
    self.playerView = [[BCOVTVPlayerView alloc] initWithOptions:options];
    self.playerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.videoContainer addSubview:self.playerView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.playerView.topAnchor constraintEqualToAnchor:self.videoContainer.topAnchor],
        [self.playerView.rightAnchor constraintEqualToAnchor:self.videoContainer.rightAnchor],
        [self.playerView.leftAnchor constraintEqualToAnchor:self.videoContainer.leftAnchor],
        [self.playerView.bottomAnchor constraintEqualToAnchor:self.videoContainer.bottomAnchor],
    ]];
}

- (void)setupPlaybackController
{
    BCOVPlayerSDKManager *manager = BCOVPlayerSDKManager.sharedManager;
    
    NSString *pulseHost = @"http://pulse-demo.videoplaza.tv";

    // See http://pulse-sdks.videoplaza.com/ios_2/latest/Classes/OOContentMetadata.html
    OOContentMetadata *contentMetadata = [OOContentMetadata new];
    
    // See http://pulse-sdks.videoplaza.com/ios_2/latest/Classes/OORequestSettings.html
    OORequestSettings *requestSettings = [OORequestSettings new];
    
    // See http://pulse-sdks.videoplaza.com/ios_2/latest/Enums/OOSeekMode.html
    requestSettings.seekMode = PLAY_ALL_ADS; // PLAY_ALL_ADS;
    
    NSDictionary *pulseProperties =
    @{
        kBCOVPulseOptionPulsePlaybackSessionDelegateKey: self,
        kBCOVPulseOptionPulsePersistentIdKey: [NSUUID.UUID UUIDString]
    };
    
    self.pulseSessionProvider = [manager createPulseSessionProviderWithPulseHost:pulseHost
                                                                 contentMetadata:contentMetadata
                                                                 requestSettings:requestSettings
                                                                     adContainer:self.playerView.contentOverlayView
                                                                  companionSlots:@[]
                                                         upstreamSessionProvider:nil
                                                                         options:pulseProperties];
    
    self.playbackController = [manager createPlaybackControllerWithSessionProvider:self.pulseSessionProvider
                                                                      viewStrategy:nil];

    self.playbackController.autoPlay = YES;
    self.playbackController.autoAdvance = YES;
    self.playbackController.delegate = self;
    
    self.playerView.playbackController = self.playbackController;
}


#pragma mark BCOVPlaybackControllerDelegate

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController Debug - Advanced to new session.");
}

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    NSLog(@"Event: %@", lifecycleEvent.eventType);
}


#pragma mark BCOVPulsePlaybackSessionDelegate

- (id<OOPulseSession>)createSessionForVideo:(BCOVVideo *)video withPulseHost:(NSString *)pulseHost contentMetdata:(OOContentMetadata *)contentMetadata requestSettings:(OORequestSettings *)requestSettings
{
    if (!pulseHost) return nil;
    
     // Override the content metadata.
    contentMetadata.category = self.videoItem.category;
    contentMetadata.tags     = self.videoItem.tags;
    contentMetadata.flags    = self.videoItem.flags;
    
    // Override the request settings.
    requestSettings.linearPlaybackPositions = self.videoItem.midrollPositions;
    
    return [OOPulse sessionWithContentMetadata:contentMetadata requestSettings:requestSettings];
}


#pragma mark UI

// Preferred focus for tvOS 10+
- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments
{
    return (@[ self.playerView.controlsView ?: self ]);
}

@end
