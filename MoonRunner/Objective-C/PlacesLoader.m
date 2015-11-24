//
//  PlacesLoader.m
//  Around Me
//
//  Created by jdistler on 06.02.13.
//  Copyright (c) 2013 Jean-Pierre Distler. All rights reserved.
//

#import "PlacesLoader.h"

#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import <Foundation/NSJSONSerialization.h>

#import "Place.h"

NSString * const apiURL = @"https://maps.googleapis.com/maps/api/place/";
NSString * const apiKey = @"AIzaSyBvA5w2_DGlIDP3gjvwuxS3ShYY77mDELc";

@interface PlacesLoader ()

@property (nonatomic, strong) SuccessHandler successHandler;
@property (nonatomic, strong) ErrorHandler errorHandler;
@property (nonatomic, strong) NSMutableData *responseData;

@end


@implementation PlacesLoader

+ (PlacesLoader *)sharedInstance {
	static PlacesLoader *instance = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		instance = [[PlacesLoader alloc] init];
	});
	
	return instance;
}

- (void)loadPOIsForLocation:(CLLocation *)location radius:(int)radius successHandler:(SuccessHandler)handler errorHandler:(ErrorHandler)errorHandler {
	_responseData = nil;
	_successHandler = handler;
	_errorHandler = errorHandler;
	CLLocationDegrees latitude = [location coordinate].latitude;
	CLLocationDegrees longitude = [location coordinate].longitude;
	
	NSMutableString *uri = [NSMutableString stringWithString:apiURL];
	[uri appendFormat:@"nearbysearch/json?location=%f,%f&rankby=distance&sensor=true&types=point_of_interest|establishment&key=%@", latitude, longitude, apiKey];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[uri stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0f];
	
	[request setHTTPShouldHandleCookies:YES];
	[request setHTTPMethod:@"GET"];
	
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	NSLog(@"Starting connection: %@ for request: %@", connection, request);
}

- (void)loadDetailInformation:(Place *)location successHanlder:(SuccessHandler)handler errorHandler:(ErrorHandler)errorHandler {
	_responseData = nil;
	_successHandler = handler;
	_errorHandler = errorHandler;
	
	NSMutableString *uri = [NSMutableString stringWithString:apiURL];
	[uri appendFormat:@"details/json?reference=%@&sensor=true&key=%@", [location reference], apiKey];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[uri stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0f];
	
	[request setHTTPShouldHandleCookies:YES];
	[request setHTTPMethod:@"GET"];
	
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];

	NSLog(@"Starting connection: %@ for request: %@", connection, request);
}

#pragma mark - NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	if(!_responseData) {
		_responseData = [NSMutableData dataWithData:data];
	} else {
		[_responseData appendData:data];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	id object = [NSJSONSerialization JSONObjectWithData:_responseData options:NSJSONReadingAllowFragments error:nil];
	
	if(_successHandler) {
		_successHandler(object);
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if(_errorHandler) {
		_errorHandler(error);
	}
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

@end
