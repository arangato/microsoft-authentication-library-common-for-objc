// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MSIDChallengeHandler.h"
#import "MSIDClientTLSHandler.h"
#import "MSIDCertAuthHandler.h"
#import "MSIDWPJChallengeHandler.h"

@implementation MSIDClientTLSHandler

+ (void)load
{
    [MSIDChallengeHandler registerHandler:self authMethod:NSURLAuthenticationMethodClientCertificate];
}

+ (void)resetHandler { }

+ (BOOL)handleChallenge:(NSURLAuthenticationChallenge *)challenge
                webview:(WKWebView *)webview
                context:(id<MSIDRequestContext>)context
      completionHandler:(ChallengeCompletionHandler)completionHandler
{
    NSString *host = challenge.protectionSpace.host;
    
    MSID_LOG_NO_PII(MSIDLogLevelInfo, nil, context, @"Attempting to handle client TLS challenge");
    MSID_LOG_PII(MSIDLogLevelInfo, nil, context, @"Attempting to handle client TLS challenge. host: %@", host);
    
    // See if this is a challenge for the WPJ cert.
    if ([MSIDWPJChallengeHandler handleChallenge:challenge
                                         webview:webview
                                         context:context
                               completionHandler:completionHandler])
    {
        return [self handleWPJChallenge:challenge context:context completionHandler:completionHandler];
    }
#if TARGET_OS_IPHONE
    return NO;
#else
    return [self handleCertAuthChallenge:challenge webview:webview context:context completionHandler:completionHandler];
#endif
}

+ (BOOL)isWPJChallenge:(NSArray *)distinguishedNames
{
    
    for (NSData *distinguishedName in distinguishedNames)
    {
        NSString *distinguishedNameString = [[[NSString alloc] initWithData:distinguishedName encoding:NSASCIIStringEncoding] lowercaseString];
        if ([distinguishedNameString containsString:[kMSIDProtectionSpaceDistinguishedName lowercaseString]])
        {
            return YES;
        }
    }
    
    return NO;
}

+ (BOOL)handleWPJChallenge:(NSURLAuthenticationChallenge *)challenge
                   context:(id<MSIDRequestContext>)context
         completionHandler:(ChallengeCompletionHandler)completionHandler
{
    MSIDRegistrationInformation *info = [MSIDWorkPlaceJoinUtil getRegistrationInformation:context urlChallenge:challenge];
    if (!info)
    {
        MSID_LOG_INFO(context, @"Device is not workplace joined");
        MSID_LOG_INFO_PII(context, @"Device is not workplace joined. host: %@", challenge.protectionSpace.host);
        
        // In other cert auth cases we send Cancel to ensure that we continue to get
        // auth challenges, however when we do that with WPJ we don't get the subsequent
        // enroll dialog *after* the failed clientTLS challenge.
        //
        // Using DefaultHandling will result in the OS not handing back client TLS
        // challenges for another ~60 seconds, behavior that looks broken in the
        // user CBA case, but here is masked by the user having to enroll their
        // device.
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        return YES;
    }
    
    // If it is not WPJ challenge, it has to be CBA.
    return [MSIDCertAuthHandler handleChallenge:challenge
                                        webview:webview
                                        context:context
                              completionHandler:completionHandler];
}

@end
