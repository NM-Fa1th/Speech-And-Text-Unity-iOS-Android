//
//  SpeechRecorderViewController.m
//  SpeechToText
//
#import "SpeechRecorderViewController.h"
#import <Speech/Speech.h>

@interface SpeechRecorderViewController ()
{
    
    // Speech recognize
    SFSpeechRecognizer *speechRecognizer;
    SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
    SFSpeechRecognitionTask *recognitionTask;
    // Record speech using audio Engine
    AVAudioInputNode *inputNode;
    AVAudioEngine *audioEngine;
	
	NSString * LanguageCode=@"ko-KR";
    
}
@end

@implementation SpeechRecorderViewController


- (void)InitSpeech{
    
    audioEngine = [[AVAudioEngine alloc] init];
    
    NSLocale *local =[[NSLocale alloc] initWithLocaleIdentifier:@"ko-KR"];
    speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:local];
    
    for (NSLocale *locate in [SFSpeechRecognizer supportedLocales]) {
        NSLog(@"%@", [locate localizedStringForCountryCode:locate.countryCode]);
    }
    // Check Authorization Status
    // Make sure you add "Privacy - Microphone Usage Description" key and reason in Info.plist to request micro permison
    // And "NSSpeechRecognitionUsageDescription" key for requesting Speech recognize permison
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        //The callback may not be called on the main thread. Add an operation to the main queue to update the record button's state.
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status) {
                case SFSpeechRecognizerAuthorizationStatusAuthorized: {
                    NSLog(@"SUCCESS");
                    break;
                }
                case SFSpeechRecognizerAuthorizationStatusDenied: {
					NSLog(@"User denied access to speech recognition");
                    break;
                }
                case SFSpeechRecognizerAuthorizationStatusRestricted: {
					NSLog(@"User denied access to speech recognition");
                    break;
                }
                case SFSpeechRecognizerAuthorizationStatusNotDetermined: {
					NSLog(@"User denied access to speech recognition");
                    break;
                }
            }
        });
        
    }];
}
- (void)SettingSpeech: (const char *) _language 
{	
	LanguageCode = [NSString stringWithUTF8String:_language];
}
// recording
- (void)startRecording {
    if (!audioEngine.isRunning) {
        if (recognitionTask) {
            [recognitionTask cancel];
            recognitionTask = nil;
        }
        		
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryRecord mode:AVAudioSessionModeMeasurement options:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
        [session setActive:TRUE withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
        
        inputNode = audioEngine.inputNode;
        
        recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
        recognitionRequest.shouldReportPartialResults = NO;
        AVAudioFormat *format = [inputNode outputFormatForBus:0];
        
        [inputNode installTapOnBus:0 bufferSize:1024 format:format block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
            [recognitionRequest appendAudioPCMBuffer:buffer];
        }];
        [audioEngine prepare];
        NSError *error1;
        [audioEngine startAndReturnError:&error1];
        NSLog(@"errorAudioEngine.description: %@", error1.description);
    }
}

- (void)stopRecording {
    if (audioEngine.isRunning) {
        
        recognitionTask =[speechRecognizer recognitionTaskWithRequest:recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
            if (result != nil) {
                NSString *transcriptText = result.bestTranscription.formattedString;
                [self CallbackSpeechToText: [transcriptText UTF8String]];
                [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];            }
            else {
                [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
                recognitionTask = nil;
                recognitionRequest = nil;
				UnitySendMessage("SpeechToText", "CallbackSpeechToText", "Null");
            }
        }];
        // make sure you release tap on bus else your app will crash the second time you record.
        [inputNode removeTapOnBus:0];
        [audioEngine stop];
        [recognitionRequest endAudio];
    }
}

@end
extern "C"{
    ViewController *vc = [[ViewController alloc] init];    
    void _TAG_startRecording(){
        [vc startRecording];
    }
    void _TAG_InitSpeech(){
        [vc InitSpeech];
    }
    void _TAG_stopRecording(){
        [vc stopRecording];
    }  
	void _TAG_SettingSpeech(const char * _language){
        [su SettingSpeech:_language pitchSpeak:_pitch rateSpeak:_rate];
    } 	
}
