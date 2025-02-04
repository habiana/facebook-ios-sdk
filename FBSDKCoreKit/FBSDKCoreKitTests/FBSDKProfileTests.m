// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <OCMock/OCMock.h>

@import TestTools;

#import <XCTest/XCTest.h>

#import "FBSDKCoreKit.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKProfile.h"
#import "FBSDKProfile+Internal.h"
#import "FBSDKTestCase.h"

@interface FBSDKSettings (Testing)
+ (void)resetFacebookClientTokenCache;
@end

@interface FBSDKProfile (Testing)
+ (void)resetCurrentProfileCache;
+ (void)loadProfileWithToken:(FBSDKAccessToken *)token
                  completion:(FBSDKProfileBlock)completion
                graphRequest:(id<FBSDKGraphRequest>)request;
@end

@interface FBSDKProfileTests : FBSDKTestCase

@end

@implementation FBSDKProfileTests
{
  FBSDKProfile *_profile;
  NSString *_sdkVersion;
  CGSize _validNonSquareSize;
  CGSize _validSquareSize;
  NSString *_validClientToken;
}

NSString *const accessTokenKey = @"access_token";
NSString *const pictureModeKey = @"type";
NSString *const widthKey = @"width";
NSString *const heightKey = @"height";

- (void)setUp
{
  [super setUp];

  _sdkVersion = @"100";
  _profile = SampleUserProfiles.valid;
  _validClientToken = @"Foo";
  _validSquareSize = CGSizeMake(100, 100);
  _validNonSquareSize = CGSizeMake(10, 20);

  [self stubGraphAPIVersionWith:_sdkVersion];
  [self resetCaches];
}

- (void)tearDown
{
  [self resetCaches];
  _profile = nil;

  [super tearDown];
}

- (void)resetCaches
{
  [FBSDKProfile resetCurrentProfileCache];
  [FBSDKSettings reset];
}

// MARK: - Creating Image URL

- (void)testCreatingImageURL
{
  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeNormal size:_validSquareSize];

  NSString *expectedPath = [NSString stringWithFormat:@"/%@/%@/picture", _sdkVersion, _profile.userID];
  XCTAssertEqualObjects(
    url.path,
    expectedPath,
    "Should add the graph api version and the identifier of the current user when creating a url for for fetching a profile image"
  );
}

- (void)testCreatingImageURLWithNoAccessTokenNoClientToken
{
  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeNormal size:_validSquareSize];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"normal"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"100"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"100"],
                               ]];

  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should add the expected query items to a url when creating a url for fetching a profile image"
  );
}

- (void)testCreatingImageURLWithClientTokenNoAccessToken
{
  [self stubClientTokenWith:_validClientToken];

  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeNormal size:_validSquareSize];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"normal"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"100"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"100"],
    [[NSURLQueryItem alloc] initWithName:accessTokenKey value:_validClientToken],
                               ]];

  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should use the current client token as the 'access token' when there is no true access token available"
  );
}

- (void)testCreatingImageURLWithAccessTokenNoClientToken
{
  [self stubCurrentAccessTokenWith:SampleAccessTokens.validToken];

  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeNormal size:_validSquareSize];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"normal"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"100"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"100"],
    [[NSURLQueryItem alloc] initWithName:accessTokenKey value:SampleAccessTokens.validToken.tokenString],
                               ]];

  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should use the current client token as the 'access token' when there is no true access token available"
  );
}

- (void)testCreatingImageURLWithAccessTokenAndClientToken
{
  [self stubCurrentAccessTokenWith:SampleAccessTokens.validToken];
  [self stubClientTokenWith:_validClientToken];

  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeNormal size:_validSquareSize];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"normal"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"100"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"100"],
    [[NSURLQueryItem alloc] initWithName:accessTokenKey value:SampleAccessTokens.validToken.tokenString],
                               ]];

  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should use the current access token as the 'access_token' parameter when available"
  );
}

- (void)testCreatingEnumWithSmallMode
{
  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeSmall size:_validNonSquareSize];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"small"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"10"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"20"],
                               ]];

  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should add the expected query items to a url when creating a url for fetching a profile image"
  );
}

- (void)testCreatingEnumWithAlbumMode
{
  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeAlbum size:_validNonSquareSize];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"album"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"10"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"20"],
                               ]];

  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should add the expected query items to a url when creating a url for fetching a profile image"
  );
}

- (void)testCreatingEnumWithLargeMode
{
  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeLarge size:_validNonSquareSize];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"large"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"10"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"20"],
                               ]];

  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should add the expected query items to a url when creating a url for fetching a profile image"
  );
}

- (void)testCreatingEnumWithSquareMode
{
  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeSquare size:_validNonSquareSize];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"square"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"10"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"20"],
                               ]];

  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should add the expected query items to a url when creating a url for fetching a profile image"
  );
}

- (void)testCreatingImageURLWithUnknownMode
{
  NSURL *url = [_profile imageURLForPictureMode:400 size:_validSquareSize];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"normal"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"100"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"100"],
                               ]];

  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "The picture mode for an invalid enum value should default to 'normal'"
  );
}

// MARK: - Size Validations

- (void)testCreatingImageURLWithNoSize
{
  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeNormal size:CGSizeZero];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"normal"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"0"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"0"],
                               ]];

  XCTAssertNotNil(url, "Should not create a url for fetching a profile picture with zero size but it will");
  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should add the expected query items to a url when creating a url for fetching a profile image"
  );
}

- (void)testCreatingSquareImageURLWithNonSquareSize
{
  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeSquare size:_validNonSquareSize];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"square"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"10"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"20"],
                               ]];

  XCTAssertNotNil(url, "Should not create a url for a square image with non-square size but it will");
  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should add the expected query items to a url when creating a url for fetching a profile image"
  );
}

- (void)testCreatingSquareImageURLWithNegativeSize
{
  NSURL *url = [_profile imageURLForPictureMode:FBSDKProfilePictureModeSquare size:CGSizeMake(-10, -10)];
  NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];

  NSSet *expectedQueryItems = [NSSet setWithArray:@[
    [[NSURLQueryItem alloc] initWithName:pictureModeKey value:@"square"],
    [[NSURLQueryItem alloc] initWithName:widthKey value:@"-10"],
    [[NSURLQueryItem alloc] initWithName:heightKey value:@"-10"],
                               ]];

  XCTAssertNotNil(url, "Should not create a url for a square image with a negative size but it will");
  XCTAssertEqualObjects(
    [NSSet setWithArray:components.queryItems],
    expectedQueryItems,
    "Should add the expected query items to a url when creating a url for fetching a profile image"
  );
}

// MARK: - Profile Loading

- (void)testGraphPathForProfileLoadWithLinkPermission
{
  id profileMock = OCMClassMock([FBSDKProfile class]);
  FBSDKAccessToken *token = [SampleAccessTokens createWithPermissions:@[@"user_link"]];
  NSString *graphPath = @"me?fields=id,first_name,middle_name,last_name,name,link";
  __block BOOL graphRequestMethodInvoked = false;
  OCMStub([profileMock loadProfileWithToken:OCMOCK_ANY completion:OCMOCK_ANY graphRequest:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained FBSDKGraphRequest *request;
    [invocation getArgument:&request atIndex:4];
    graphRequestMethodInvoked = true;
    XCTAssertEqualObjects(request.graphPath, graphPath);
  });
  OCMStub([profileMock loadProfileWithToken:OCMOCK_ANY completion:OCMOCK_ANY]).andForwardToRealObject();
  [FBSDKProfile loadProfileWithToken:token completion:nil];
  XCTAssertTrue(graphRequestMethodInvoked);
}

- (void)testGraphPathForProfileLoadWithoutLinkPermission
{
  id profileMock = OCMClassMock([FBSDKProfile class]);
  NSString *graphPath = @"me?fields=id,first_name,middle_name,last_name,name";
  __block BOOL graphRequestMethodInvoked = false;
  OCMStub([profileMock loadProfileWithToken:OCMOCK_ANY completion:OCMOCK_ANY graphRequest:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained FBSDKGraphRequest *request;
    [invocation getArgument:&request atIndex:4];
    graphRequestMethodInvoked = true;
    XCTAssertEqualObjects(request.graphPath, graphPath);
  });
  OCMStub([profileMock loadProfileWithToken:OCMOCK_ANY completion:OCMOCK_ANY]).andForwardToRealObject();
  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken completion:nil];
  XCTAssertTrue(graphRequestMethodInvoked);
}

- (void)testGraphPathForProfileLoadWithEmailPermission
{
  id profileMock = OCMClassMock([FBSDKProfile class]);
  FBSDKAccessToken *token = [SampleAccessTokens createWithPermissions:@[@"email"]];
  NSString *graphPath = @"me?fields=id,first_name,middle_name,last_name,name,email";
  __block BOOL graphRequestMethodInvoked = false;
  OCMStub([profileMock loadProfileWithToken:OCMOCK_ANY completion:OCMOCK_ANY graphRequest:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained FBSDKGraphRequest *request;
    [invocation getArgument:&request atIndex:4];
    graphRequestMethodInvoked = true;
    XCTAssertEqualObjects(request.graphPath, graphPath);
  });
  OCMStub([profileMock loadProfileWithToken:OCMOCK_ANY completion:OCMOCK_ANY]).andForwardToRealObject();
  [FBSDKProfile loadProfileWithToken:token completion:nil];
  XCTAssertTrue(graphRequestMethodInvoked);
}

- (void)testGraphPathForProfileLoadWithoutEmailPermission
{
  id profileMock = OCMClassMock([FBSDKProfile class]);
  NSString *graphPath = @"me?fields=id,first_name,middle_name,last_name,name";
  __block BOOL graphRequestMethodInvoked = false;
  OCMStub([profileMock loadProfileWithToken:OCMOCK_ANY completion:OCMOCK_ANY graphRequest:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained FBSDKGraphRequest *request;
    [invocation getArgument:&request atIndex:4];
    graphRequestMethodInvoked = true;
    XCTAssertEqualObjects(request.graphPath, graphPath);
  });
  OCMStub([profileMock loadProfileWithToken:OCMOCK_ANY completion:OCMOCK_ANY]).andForwardToRealObject();
  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken completion:nil];
  XCTAssertTrue(graphRequestMethodInvoked);
}

- (void)testGraphPathForProfileLoadWithFriendsPermission
{
  id profileMock = OCMClassMock([FBSDKProfile class]);
  FBSDKAccessToken *token = [SampleAccessTokens createWithPermissions:@[@"user_friends"]];
  NSString *graphPath = @"me?fields=id,first_name,middle_name,last_name,name,friends";
  __block BOOL graphRequestMethodInvoked = false;
  OCMStub([profileMock loadProfileWithToken:OCMOCK_ANY completion:OCMOCK_ANY graphRequest:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained FBSDKGraphRequest *request;
    [invocation getArgument:&request atIndex:4];
    graphRequestMethodInvoked = true;
    XCTAssertEqualObjects(request.graphPath, graphPath);
  });
  OCMStub([profileMock loadProfileWithToken:OCMOCK_ANY completion:OCMOCK_ANY]).andForwardToRealObject();
  [FBSDKProfile loadProfileWithToken:token completion:nil];
  XCTAssertTrue(graphRequestMethodInvoked);
}

- (void)testLoadingProfile
{
  id result = @{
    @"id" : SampleUserProfiles.valid.userID,
    @"first_name" : SampleUserProfiles.valid.firstName,
    @"middle_name" : SampleUserProfiles.valid.middleName,
    @"last_name" : SampleUserProfiles.valid.lastName,
    @"name" : SampleUserProfiles.valid.name,
    @"link" : SampleUserProfiles.valid.linkURL,
    @"email" : SampleUserProfiles.valid.email,
    @"friends" : @{@"data" : @[
      @{
        @"name" : @"user1",
        @"id" : SampleUserProfiles.valid.friendIDs[0],
      },
      @{
        @"name" : @"user2",
        @"id" : SampleUserProfiles.valid.friendIDs[1],
      }
    ]}
  };
  [self stubGraphRequestWithResult:result error:nil connection:nil];

  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^(FBSDKProfile *profile, NSError *error) {
                            XCTAssertEqualObjects(profile.firstName, SampleUserProfiles.valid.firstName);
                            XCTAssertEqualObjects(profile.middleName, SampleUserProfiles.valid.middleName);
                            XCTAssertEqualObjects(profile.lastName, SampleUserProfiles.valid.lastName);
                            XCTAssertEqualObjects(profile.name, SampleUserProfiles.valid.name);
                            XCTAssertEqualObjects(profile.userID, SampleUserProfiles.valid.userID);
                            XCTAssertEqualObjects(profile.linkURL, SampleUserProfiles.valid.linkURL);
                            XCTAssertEqualObjects(profile.email, SampleUserProfiles.valid.email);
                            XCTAssertEqualObjects(profile.friendIDs, SampleUserProfiles.valid.friendIDs);
                          } graphRequest:self.graphRequestMock];
}

- (void)testLoadingProfileWithInvalidLink
{
  id result = @{
    @"id" : SampleUserProfiles.valid.userID,
    @"first_name" : SampleUserProfiles.valid.firstName,
    @"middle_name" : SampleUserProfiles.valid.middleName,
    @"last_name" : SampleUserProfiles.valid.lastName,
    @"name" : SampleUserProfiles.valid.name,
    @"link" : @"   ",
    @"email" : SampleUserProfiles.valid.email
  };
  [self stubGraphRequestWithResult:result error:nil connection:nil];

  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^(FBSDKProfile *profile, NSError *error) {
                            XCTAssertNil(profile.linkURL);
                          } graphRequest:self.graphRequestMock];
}

- (void)testProfileNilWithNilAccessToken
{
  id result = @{
    @"id" : SampleUserProfiles.valid.userID,
    @"first_name" : SampleUserProfiles.valid.firstName,
    @"middle_name" : SampleUserProfiles.valid.middleName,
    @"last_name" : SampleUserProfiles.valid.lastName,
    @"name" : SampleUserProfiles.valid.name
  };
  [self stubGraphRequestWithResult:result error:nil connection:nil];

  [FBSDKProfile loadProfileWithToken:nil completion:^(FBSDKProfile *profile, NSError *error) {
                                           XCTAssertNil(profile);
                                         } graphRequest:self.graphRequestMock];
}

- (void)testLoadingProfileWithNoFriends
{
  id result = @{
    @"id" : SampleUserProfiles.valid.userID,
    @"first_name" : SampleUserProfiles.valid.firstName,
    @"middle_name" : SampleUserProfiles.valid.middleName,
    @"last_name" : SampleUserProfiles.valid.lastName,
    @"name" : SampleUserProfiles.valid.name,
    @"link" : SampleUserProfiles.valid.linkURL,
    @"email" : SampleUserProfiles.valid.email,
    @"friends" : @{@"data" : @[]}
  };
  [self stubGraphRequestWithResult:result error:nil connection:nil];

  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^(FBSDKProfile *profile, NSError *error) {
                            XCTAssertNotNil(profile);
                            XCTAssertNil(profile.friendIDs);
                          } graphRequest:self.graphRequestMock];
}

- (void)testLoadingProfileWithInvalidFriends
{
  id result = @{
    @"id" : SampleUserProfiles.valid.userID,
    @"first_name" : SampleUserProfiles.valid.firstName,
    @"middle_name" : SampleUserProfiles.valid.middleName,
    @"last_name" : SampleUserProfiles.valid.lastName,
    @"name" : SampleUserProfiles.valid.name,
    @"link" : SampleUserProfiles.valid.linkURL,
    @"email" : SampleUserProfiles.valid.email,
    @"friends" : @"   "
  };
  [self stubGraphRequestWithResult:result error:nil connection:nil];

  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^(FBSDKProfile *profile, NSError *error) {
                            XCTAssertNotNil(profile);
                            XCTAssertNil(profile.friendIDs);
                          } graphRequest:self.graphRequestMock];
}

- (void)testProfileNotRefreshedIfNotStale
{
  [FBSDKProfile setCurrentProfile:SampleUserProfiles.valid];
  id result = @{
    @"id" : SampleUserProfiles.valid.userID,
    @"first_name" : @"firstname",
    @"middle_name" : @"middlename",
    @"last_name" : @"lastname",
    @"name" : @"name"
  };
  [self stubGraphRequestWithResult:result error:nil connection:nil];

  [FBSDKProfile loadProfileWithToken:nil
                          completion:^(FBSDKProfile *_Nullable profile, NSError *_Nullable error) {
                            XCTAssertEqualObjects(profile.firstName, SampleUserProfiles.valid.firstName);
                            XCTAssertEqualObjects(profile.middleName, SampleUserProfiles.valid.middleName);
                            XCTAssertEqualObjects(profile.lastName, SampleUserProfiles.valid.lastName);
                            XCTAssertEqualObjects(profile.name, SampleUserProfiles.valid.name);
                            XCTAssertEqualObjects(profile.userID, SampleUserProfiles.valid.userID);
                            XCTAssertEqualObjects(profile.linkURL, SampleUserProfiles.valid.linkURL);
                            XCTAssertEqualObjects(profile.email, SampleUserProfiles.valid.email);
                          } graphRequest:self.graphRequestMock];
}

- (void)testLoadingProfileWithLimitedProfileWithoutToken
{
  FBSDKProfile *expected = SampleUserProfiles.validLimited;
  [FBSDKProfile setCurrentProfile:expected];
  TestGraphRequest *request = [TestGraphRequest new];
  [FBSDKProfile loadProfileWithToken:nil
                          completion:^(FBSDKProfile *profile, NSError *error) {
                            XCTAssertEqualObjects(
                              profile,
                              expected,
                              "Should return the current profile synchronously"
                            );
                          }
                        graphRequest:request];
  XCTAssertEqual(
    request.startCallCount,
    0,
    "Should not fetch a profile if there is no access token"
  );
}

- (void)testLoadingProfileWithLimitedProfileWithToken
{
  [FBSDKProfile setCurrentProfile:SampleUserProfiles.validLimited];
  TestGraphRequest *request = [TestGraphRequest new];
  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^(FBSDKProfile *profile, NSError *error) {
                            XCTFail("Should not invoke the completion");
                          }
                        graphRequest:request];
  XCTAssertEqual(
    request.startCallCount,
    1,
    "Should fetch a profile if it is limited and there is an access token"
  );
}

- (void)testLoadingProfileWithExpiredNonLimitedProfileWithToken
{
  FBSDKProfile *expected = [SampleUserProfiles createValidWithIsExpired:YES];
  [FBSDKProfile setCurrentProfile:expected];
  TestGraphRequest *request = [TestGraphRequest new];
  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^(FBSDKProfile *profile, NSError *error) {
                            XCTFail("Should not invoke the completion");
                          }
                        graphRequest:request];
  XCTAssertEqual(
    request.startCallCount,
    1,
    "Should fetch a profile if it is expired and there is an access token"
  );
}

- (void)testLoadingProfileWithCurrentlyLoadingProfile
{
  FBSDKProfile *expected = [SampleUserProfiles createValidWithIsExpired:YES];
  [FBSDKProfile setCurrentProfile:expected];
  TestGraphRequest *request = [TestGraphRequest new];
  TestGraphRequestConnection *connection = [TestGraphRequestConnection new];
  request.stubbedConnection = connection;
  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^(FBSDKProfile *profile, NSError *error) { XCTFail("Should not invoke the completion"); }
                        graphRequest:request];
  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^(FBSDKProfile *profile, NSError *error) { XCTFail("Should not invoke the completion"); }
                        graphRequest:request];
  XCTAssertEqual(
    connection.cancelCallCount,
    1,
    "Should cancel an existing connection if a new connection is started before it completes"
  );
}

- (void)testProfileParseBlockInvokedOnSuccessfulGraphRequest
{
  id result = @{};
  [self stubGraphRequestWithResult:result error:nil connection:nil];

  __block BOOL parseBlockInvoked = false;

  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^void (FBSDKProfile *profile, NSError *error) {}
                        graphRequest:self.graphRequestMock
                          parseBlock:^void (id parseResult, FBSDKProfile **profileRef) {
                            parseBlockInvoked = true;
                          }];
  XCTAssertTrue(parseBlockInvoked);
}

- (void)testProfileParseBlockShouldHaveNonNullPointer
{
  id result = @{};
  [self stubGraphRequestWithResult:result error:nil connection:nil];

  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                          completion:^void (FBSDKProfile *profile, NSError *error) {}
                        graphRequest:self.graphRequestMock
                          parseBlock:^void (id parseResult, FBSDKProfile **profileRef) {
                            XCTAssertTrue(profileRef != NULL);
                          }];
}

- (void)testProfileParseBlockReturnsNilIfResultIsEmpty
{
  id result = @{};
  [self stubGraphRequestWithResult:result error:nil connection:nil];

  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken completion:nil graphRequest:self.graphRequestMock];
  XCTAssertNil(FBSDKProfile.currentProfile);
}

- (void)testProfileParseBlockReturnsNilIfResultHasNoId
{
  id result = @{
    @"first_name" : @"firstname",
    @"middle_name" : @"middlename",
    @"last_name" : @"lastname",
    @"name" : @"name"
  };
  [self stubGraphRequestWithResult:result error:nil connection:nil];

  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken completion:nil graphRequest:self.graphRequestMock];
  XCTAssertNil(FBSDKProfile.currentProfile);
}

- (void)testProfileParseBlockReturnsNilIfResultHasEmptyId
{
  id result = @{
    @"id" : @"",
    @"first_name" : @"firstname",
    @"middle_name" : @"middlename",
    @"last_name" : @"lastname",
    @"name" : @"name"
  };
  [self stubGraphRequestWithResult:result error:nil connection:nil];

  [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken completion:nil graphRequest:self.graphRequestMock];
  XCTAssertNil(FBSDKProfile.currentProfile);
}

- (void)testLoadProfileWithRandomData
{
  for (int i = 0; i < 100; i++) {
    NSDictionary *result = @{
      @"id" : SampleUserProfiles.valid.userID,
      @"first_name" : SampleUserProfiles.valid.firstName,
      @"middle_name" : SampleUserProfiles.valid.middleName,
      @"last_name" : SampleUserProfiles.valid.lastName,
      @"name" : SampleUserProfiles.valid.name,
      @"link" : SampleUserProfiles.valid.linkURL,
      @"email" : SampleUserProfiles.valid.email,
      @"friends" : @{@"data" : @[
        @{
          @"name" : @"user1",
          @"id" : SampleUserProfiles.valid.friendIDs[0],
        },
        @{
          @"name" : @"user2",
          @"id" : SampleUserProfiles.valid.friendIDs[1],
        }
      ]}
    };
    NSDictionary *randomizedResult = [Fuzzer randomizeWithJson:result];
    [self stubGraphRequestWithResult:randomizedResult error:nil connection:nil];

    __block BOOL completed = NO;
    [FBSDKProfile loadProfileWithToken:SampleAccessTokens.validToken
                            completion:^(FBSDKProfile *_Nullable profile, NSError *_Nullable error) {
                              completed = YES;
                            } graphRequest:self.graphRequestMock];

    XCTAssert(completed, @"Completion handler should be invoked synchronously");
  }
}

- (void)testEncoding
{
  NSURL *linkURL = [NSURL URLWithString:@"www.example.com"];
  NSURL *imageURL = [NSURL URLWithString:@"www.example.com/image"];
  NSDate *date = [NSDate date];
  NSArray *friendIDS = @[@123, @456];

  FBSDKTestCoder *coder = [FBSDKTestCoder new];
  _profile = [[FBSDKProfile alloc] initWithUserID:@"userID"
                                        firstName:@"firstName"
                                       middleName:@"middleName"
                                         lastName:@"lastName"
                                             name:@"name"
                                          linkURL:linkURL
                                      refreshDate:date
                                         imageURL:imageURL
                                            email:@"email"
                                        friendIDs:friendIDS
                                        isLimited:YES];

  [_profile encodeWithCoder:coder];

  XCTAssertEqualObjects(
    coder.encodedObject[@"userID"],
    @"userID",
    "Should encode the expected user identifier"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"firstName"],
    @"firstName",
    "Should encode the expected first name"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"middleName"],
    @"middleName",
    "Should encode the expected middle name"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"lastName"],
    @"lastName",
    "Should encode the expected last name"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"name"],
    @"name",
    "Should encode the expected name"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"linkURL"],
    linkURL,
    "Should encode the expected link URL"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"refreshDate"],
    date,
    "Should encode the expected refresh date"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"imageURL"],
    imageURL,
    "Should encode the expected image URL"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"email"],
    @"email",
    "Should encode the expected email address"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"friendIDs"],
    friendIDS,
    "Should encode the expected list of friend identifiers"
  );
  XCTAssertEqualObjects(
    coder.encodedObject[@"isLimited"],
    @YES,
    "Should encode the expected 'isLimited' value as an object"
  );
}

- (void)testDecodingEntryWithMethodName
{
  FBSDKTestCoder *coder = [FBSDKTestCoder new];
  _profile = [[FBSDKProfile alloc] initWithCoder:coder];

  XCTAssertEqualObjects(
    coder.decodedObject[@"userID"],
    NSString.class,
    "Should decode a string for the userID key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"firstName"],
    NSString.class,
    "Should decode a string for the firstName key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"middleName"],
    NSString.class,
    "Should decode a string for the middleName key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"lastName"],
    NSString.class,
    "Should decode a string for the lastName key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"name"],
    NSString.class,
    "Should decode a string for the name key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"linkURL"],
    NSURL.class,
    "Should decode a url for the linkURL key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"refreshDate"],
    NSDate.class,
    "Should decode a date for the refreshDate key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"imageURL"],
    NSURL.class,
    "Should decode a url for the imageURL key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"email"],
    NSString.class,
    "Should decode a string for the email key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"friendIDs"],
    NSArray.class,
    "Should decode an array for the friendIDs key"
  );
  XCTAssertEqualObjects(
    coder.decodedObject[@"isLimited"],
    @"decodeBoolForKey",
    "Should decode a bool for the isLimited key"
  );
}

@end
