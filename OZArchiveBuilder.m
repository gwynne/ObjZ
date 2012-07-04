//
//  OZArchiveBuilder.m
//  IPADropper
//
//  Created by Gwynne Raskind on 7/2/12.
//  Copyright (c) 2012 Abby's LLC. All rights reserved.
//

#import "OZArchiveBuilder.h"
#import "zip.h"
#import "OZMemoryIO.h"

@implementation OZArchiveBuilder
{
	zipFile			_zipper;
	NSMutableData	*_memory;
}

@synthesize baseURL = _baseURL, data = _memory;

+ (OZArchiveBuilder *)archiveBuilderWithURL:(NSURL *)url overwrite:(BOOL)overwrite
{
	return [[self alloc] initWithURL:url overwrite:overwrite];
}

+ (OZArchiveBuilder *)archiveBuilderWithPath:(NSString *)path overwrite:(BOOL)overwrite
{
	return [[self alloc] initWithPath:path overwrite:overwrite];
}

+ (OZArchiveBuilder *)archiveBuilderAppendingToData:(NSMutableData *)data overwrite:(BOOL)overwrite
{
	return [[self alloc] initAppendingToData:data overwrite:overwrite];
}

+ (OZArchiveBuilder *)archiveBuilderInMemory
{
	return [[self alloc] init];
}

- (id)initWithURL:(NSURL *)url overwrite:(BOOL)overwrite
{
	return [self initWithPath:url.path overwrite:overwrite];
}

- (id)initWithPath:(NSString *)path overwrite:(BOOL)overwrite
{
	if ((self = [super init]))
	{
		if (!(_zipper = zipOpen64(path.UTF8String, overwrite ? APPEND_STATUS_CREATE : APPEND_STATUS_ADDINZIP)))
			return nil;
		_memory = nil;
	}
	return self;
}

- (id)initAppendingToData:(NSMutableData *)data overwrite:(BOOL)overwrite
{
	if ((self = [super init]))
	{
		_memory = data;
		if (!(_zipper = zipOpen2_64((__bridge void *)data, overwrite ? APPEND_STATUS_CREATE : APPEND_STATUS_ADDINZIP, NULL, &OZ_NSData_rw_functions)))
			return nil;
	}
	return self;
}

- (id)init
{
	return [self initAppendingToData:[NSMutableData data] overwrite:NO];
}

- (BOOL)closeAndReturnError:(NSError **)error
{
	if (!_zipper)
		return NO;
	
	int		result = zipClose(_zipper, NULL);
	
	if (result != ZIP_OK && error)
		*error = [NSError errorWithDomain:@"OZArchiveBuilder" code:result userInfo:nil];
	return result == ZIP_OK ? YES : NO;
}

- (BOOL)addContentsOfDirectory:(NSURL *)directory andReturnError:(NSError **)error // replicates directory structure as much as possible
{
	NSError						* __block internalError = nil;
	NSDirectoryEnumerator		*enumerator = [[NSFileManager defaultManager]
		enumeratorAtURL:directory includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLContentModificationDateKey, nil]
		options:0 errorHandler:^ BOOL (NSURL *url, NSError *blockError) {
			internalError = blockError;
			return NO;
		}];
	
	for (NSURL *itemURL in enumerator)
	{
		if (![self addContentsOfURL:itemURL andReturnError:error])
			return NO;
	}
	
	return YES;
}

- (BOOL)addContentsOfURL:(NSURL *)url andReturnError:(NSError **)error // URL must not be a directory
{
	return [self addContentsOfPath:url.path andReturnError:error];
}

- (NSString *)pathRelativeToZipBase:(NSString *)inputPath
{
	NSString		*base = _baseURL ? _baseURL.path : inputPath.stringByDeletingLastPathComponent;
	
	return [inputPath substringFromIndex:[inputPath commonPrefixWithString:base options:NSLiteralSearch].length];
}

- (BOOL)addContentsOfPath:(NSString *)path andReturnError:(NSError **)error // path must not refer to a directory
{
	NSData			*data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:error];
	
	return data ? [self addData:data withFilePath:[self pathRelativeToZipBase:path] andReturnError:error] : NO;
}

- (BOOL)addData:(NSData *)data withFilePath:(NSString *)path andReturnError:(NSError **)error
{
	return [self addData:data
				 withFilePath:path
				 withModificationDate:[NSDate date]
				 withInternalAttributes:0
				 withExternalAttributes:0
				 withComment:nil
				 withExtraField:nil
				 withMethod:OZCompressionDeflate
				 withLevel:Z_DEFAULT_COMPRESSION
				 withStrategy:Z_DEFAULT_STRATEGY
				 withPassword:nil
				 withFlags:0
				 andReturnError:error];
}

// This is the most primitive routine for adding data to the archive. Most of
//	these parameters aren't useful, and will be filled in automatically when
//	using the convenience routines above.
- (BOOL)addData:(NSData *)data
		withFilePath:(NSString *)path
		withModificationDate:(NSDate *)date
		withInternalAttributes:(uint16_t)internalFA
		withExternalAttributes:(uint32_t)externalFA
		withComment:(NSString *)comment
		withExtraField:(NSData *)extraField
		withMethod:(OZCompressionMethod)method
		withLevel:(int)level
		withStrategy:(int)strategy
		withPassword:(NSString *)password
		withFlags:(uint16_t)flags
		andReturnError:(NSError **)error
{
	return NO;
}

@end
