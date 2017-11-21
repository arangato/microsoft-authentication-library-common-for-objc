//------------------------------------------------------------------------------
//
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
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import "NSDictionary+MSIDTestUtil.h"

@implementation NSDictionary (MSIDTestUtil)

- (BOOL)compareAndPrintDiff:(NSDictionary *)dictionary
{
    return [self compareAndPrintDiff:dictionary dictionaryDescription:@"dictionary"];
}

- (BOOL)compareAndPrintDiff:(NSDictionary *)dictionary
      dictionaryDescription:(NSString *)description
{
    BOOL fSame = YES;
    
    for (NSString *key in self)
    {
        id myVal = self[key];
        id otherVal = dictionary[key];
        if ([myVal isKindOfClass:[MSIDTestIgnoreSentinel class]] || [otherVal isKindOfClass:[MSIDTestIgnoreSentinel class]])
        {
            continue;
        }
        
        if (!otherVal)
        {
            NSLog(@"\"%@\" : \"%@\" missing from %@.", key, myVal, description);
            fSame = NO;
        }
        else if (![myVal isKindOfClass:[MSIDTestRequireValueSentinel class]] && ![myVal isEqual:otherVal])
        {
            NSLog(@"\"%@\" in %@ does not match. actual: \"%@\" expected: \"%@\"", key, description, otherVal, myVal);
            fSame = NO;
        }
    }
    
    for (NSString *key in dictionary)
    {
        if ([dictionary[key] isKindOfClass:[MSIDTestIgnoreSentinel class]])
        {
            continue;
        }
        
        if (!self[key])
        {
            NSLog(@"@\"%@\" : @\"%@\" in %@, not found in expected", key, dictionary[key], description);
            fSame = NO;
        }
    }
    
    return fSame;
}

@end

@implementation MSIDTestRequireValueSentinel

static MSIDTestRequireValueSentinel *s_requiredSentinel = nil;

+ (void)initialize
{
    s_requiredSentinel = [MSIDTestRequireValueSentinel new];
}

+ (instancetype)sentinel
{
    return s_requiredSentinel;
}

@end

@implementation MSIDTestIgnoreSentinel

static MSIDTestIgnoreSentinel *s_ignoreSentinel = nil;

+ (void)initialize
{
    s_ignoreSentinel = [MSIDTestIgnoreSentinel new];
}

+ (instancetype)sentinel
{
    return s_ignoreSentinel;
}

@end
