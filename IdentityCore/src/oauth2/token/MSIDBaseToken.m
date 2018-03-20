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

#import "MSIDBaseToken.h"
#import "MSIDUserInformation.h"
#import "MSIDAADTokenResponse.h"
#import "MSIDTelemetryEventStrings.h"
#import "MSIDClientInfo.h"
#import "MSIDRequestParameters.h"

@implementation MSIDBaseToken

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDBaseToken *item = [[self.class allocWithZone:zone] init];
    item->_authority = _authority;
    item->_clientId = _clientId;
    item->_uniqueUserId = _uniqueUserId;
    item->_clientInfo = _clientInfo;
    item->_additionaServerlInfo = _additionaServerlInfo;
    item->_username = _username;
    
    return item;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }
    
    if (![object isKindOfClass:self.class])
    {
        return NO;
    }
    
    return [self isEqualToItem:(MSIDBaseToken *)object];
}

- (NSUInteger)hash
{
    NSUInteger hash = [super hash];
    hash = hash * 31 + self.authority.hash;
    hash = hash * 31 + self.clientId.hash;
    hash = hash * 31 + self.uniqueUserId.hash;
    hash = hash * 31 + self.clientInfo.rawClientInfo.hash;
    hash = hash * 31 + self.additionaServerlInfo.hash;
    hash = hash * 31 + self.username.hash;
    hash = hash * 31 + self.tokenType;
    return hash;
}

- (BOOL)isEqualToItem:(MSIDBaseToken *)item
{
    if (!item)
    {
        return NO;
    }
    
    BOOL result = YES;
    result &= (!self.authority && !item.authority) || [self.authority.absoluteString isEqualToString:item.authority.absoluteString];
    result &= (!self.clientId && !item.clientId) || [self.clientId isEqualToString:item.clientId];
    result &= (!self.uniqueUserId && !item.uniqueUserId) || [self.uniqueUserId isEqualToString:item.uniqueUserId];
    result &= (!self.clientInfo && !item.clientInfo) || [self.clientInfo.rawClientInfo isEqualToString:item.clientInfo.rawClientInfo];
    result &= (!self.additionaServerlInfo && !item.additionaServerlInfo) || [self.additionaServerlInfo isEqualToDictionary:item.additionaServerlInfo];
    result &= (!self.username && !item.username) || [self.username isEqualToString:item.username];
    result &= (self.tokenType == item.tokenType);
    
    return result;
}

#pragma mark - Token type

- (MSIDTokenType)tokenType
{
    return MSIDTokenTypeOther;
}

- (BOOL)supportsTokenType:(MSIDTokenType)tokenType
{
    return tokenType == self.tokenType;
}

#pragma mark - Cache

- (instancetype)initWithTokenCacheItem:(MSIDTokenCacheItem *)tokenCacheItem
{
    self = [super init];
    
    if (self)
    {
        if (!tokenCacheItem)
        {
            return nil;
        }
        
        if (![self supportsTokenType:tokenCacheItem.tokenType])
        {
            MSID_LOG_ERROR(nil, @"Trying to initialize with a wrong token type");
            return nil;
        }
        
        _authority = tokenCacheItem.authority;
        
        if (!_authority)
        {
            MSID_LOG_ERROR(nil, @"Trying to initialize token when missing authority field");
            return nil;
        }
        
        _clientId = tokenCacheItem.clientId;
        
        if (!_clientId)
        {
            MSID_LOG_ERROR(nil, @"Trying to initialize token when missing clientId field");
            return nil;
        }
        
        _clientInfo = tokenCacheItem.clientInfo;
        _additionaServerlInfo = tokenCacheItem.additionalInfo;
        _username = tokenCacheItem.username;
        _uniqueUserId = tokenCacheItem.uniqueUserId;
        _additionalClientInfo = tokenCacheItem.additionalClientInfo;
    }
    
    return self;
}

- (MSIDTokenCacheItem *)tokenCacheItem
{
    MSIDTokenCacheItem *cacheItem = [[MSIDTokenCacheItem alloc] init];
    cacheItem.tokenType = self.tokenType;
    cacheItem.authority = self.authority;
    cacheItem.clientId = self.clientId;
    cacheItem.clientInfo = self.clientInfo;
    cacheItem.additionalInfo = self.additionaServerlInfo;
    cacheItem.username = self.username;
    cacheItem.uniqueUserId = self.uniqueUserId;
    cacheItem.additionalClientInfo = self.additionalClientInfo;
    return cacheItem;
}

#pragma mark - Token response

- (instancetype)initWithTokenResponse:(MSIDTokenResponse *)response
                              request:(MSIDRequestParameters *)requestParams
{
    if (!response
        || !requestParams)
    {
        return nil;
    }
    
    if (!(self = [super init]))
    {
        return nil;
    }
    
    [self fillTokenFromResponse:response
                        request:requestParams];
    
    return self;
}

#pragma mark - Fill item

- (void)fillTokenFromResponse:(MSIDTokenResponse *)response
                      request:(MSIDRequestParameters *)requestParams
{
    // Fill from request
    _authority = requestParams.authority;
    _clientId = requestParams.clientId;
    _additionaServerlInfo = [NSMutableDictionary dictionary];
    _username = response.idTokenObj.username;
    
    // Fill in client info and spe info
    if ([response isKindOfClass:[MSIDAADTokenResponse class]])
    {
        MSIDAADTokenResponse *aadTokenResponse = (MSIDAADTokenResponse *)response;
        _clientInfo = aadTokenResponse.clientInfo;
        _uniqueUserId = _clientInfo.userIdentifier;
        [_additionaServerlInfo setValue:aadTokenResponse.speInfo
                           forKey:MSID_SPE_INFO_CACHE_KEY];
    }
    else
    {
        _uniqueUserId = response.idTokenObj.userId;
    }
}

#pragma mark - Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"(authority=%@ clientId=%@ tokenType=%@ uniqueUserId=%@ clientInfo=%@)",
            _authority, _clientId, [MSIDTokenTypeHelpers tokenTypeAsString:self.tokenType], _uniqueUserId, _clientInfo];
}

@end
