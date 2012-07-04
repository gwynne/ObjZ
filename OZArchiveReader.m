//
//  OZArchiveReader.m
//  IPADropper
//
//  Created by Gwynne Raskind on 6/30/12.
//  Copyright (c) 2012 Abby's LLC. All rights reserved.
//

#import "OZArchiveReader.h"
#import "unzip.h"
#import "OZMemoryIO.h"

@interface NSDateComponents (OZZipDateInitialization)

- (id)initWithZipDate:(tm_unz)date;

@end

@implementation NSDateComponents (OZZipDateInitialization)

- (id)initWithZipDate:(tm_unz)date
{
	if ((self = [self init]))
	{
		self.year = date.tm_year;
		self.month = date.tm_mon;
		self.day = date.tm_mday;
		self.hour = date.tm_hour;
		self.minute = date.tm_min;
		self.second = date.tm_sec;
	}
	return self;
}

@end

@interface OZArchivedFile ()

- (id)initWithArchive:(OZArchiveReader *)archive withCurrentFileOfUnzipper:(unzFile)unzipper;

@property(nonatomic,weak,readwrite)		OZArchiveReader			*archive;
@property(nonatomic,assign,readwrite)	uint16_t				compressorVersion, minDecompressorVersion, flags, diskNumberStart, internalAttributes;
@property(nonatomic,assign,readwrite)	OZCompressionMethod		method;
@property(nonatomic,assign,readwrite)	NSDate					*lastModificationDate;
@property(nonatomic,assign,readwrite)	uint32_t				CRC, externalAttributes;
@property(nonatomic,assign,readwrite)	uint64_t				compressedSize, expandedSize;
@property(nonatomic,copy,readwrite)		NSString				*path, *comment;
@property(nonatomic,strong,readwrite)	NSData					*extraField;

@end

@implementation OZArchivedFile
{
	unzFile _unzipper;
}

@synthesize archive = _archive, compressorVersion = _compressorVersion, minDecompressorVersion = _minDecompressorVersion, flags = _flags,
			diskNumberStart = _diskNumberStart, internalAttributes = _internalAttributes, method = _method,
			lastModificationDate = _lastModificationDate, CRC = _CRC, externalAttributes = _externalAttributes, compressedSize = _compressedSize,
			expandedSize = _expandedSize, path = _path, comment = _comment, extraField = _extraField;

- (id)initWithArchive:(OZArchiveReader *)archive withCurrentFileOfUnzipper:(unzFile)unzipper
{
	if ((self = [super init]))
	{
		_archive = archive;
		_unzipper = unzipper;
		
		unz_file_info64		info;
		
		if (unzGetCurrentFileInfo64(_unzipper, &info, NULL, 0, NULL, 0, NULL, 0) != UNZ_OK)
			return nil;
		
		NSMutableData		*fileName = [NSMutableData dataWithLength:info.size_filename + 1],
							*extraField = [NSMutableData dataWithLength:info.size_file_extra + 1],
							*comment = [NSMutableData dataWithLength:info.size_file_comment + 1];
		
		if (unzGetCurrentFileInfo64(_unzipper, &info, fileName.mutableBytes, info.size_filename, extraField.mutableBytes,
									info.size_file_extra, comment.mutableBytes, info.size_file_comment) == UNZ_OK)
		{
			_path = [[NSString alloc] initWithData:fileName encoding:NSUTF8StringEncoding];
			_extraField = extraField;
			_comment = [[NSString alloc] initWithData:comment encoding:NSUTF8StringEncoding];
		}
		else
			return nil;
		
		_compressorVersion = info.version;
		_minDecompressorVersion = info.version_needed;
		_flags = info.flag;
		_diskNumberStart = info.disk_num_start;
		_internalAttributes = info.internal_fa;
		_method = info.compression_method == Z_DEFLATED ? OZCompressionDeflate :
					(info.compression_method == Z_BZIP2ED ? OZCompressionBzip2 : OZCompressionUnknown);
		_lastModificationDate = [[NSCalendar currentCalendar] dateFromComponents:[[NSDateComponents alloc] initWithZipDate:info.tmu_date]];
		_CRC = info.crc;
		_externalAttributes = info.external_fa;
		_compressedSize = info.compressed_size;
		_expandedSize = info.uncompressed_size;
	}
	return self;
}

- (NSData *)fetchContentsWithPassword:(NSString *)password
{
	if (unzOpenCurrentFilePassword(_unzipper, password ? password.UTF8String : NULL) != UNZ_OK)
		return nil;

	NSMutableData			*data = [NSMutableData dataWithLength:self.expandedSize];
	
	if (unzReadCurrentFile(_unzipper, data.mutableBytes, data.length) != (int)data.length)
		data = nil;
	unzCloseCurrentFile(_unzipper);
	
	return data;
}

@end

@implementation OZArchiveReader
{
	unzFile		_unzipper;
}

+ (OZArchiveReader *)readerWithURL:(NSURL *)url
{
	return [[self alloc] initWithURL:url];
}

+ (OZArchiveReader *)readerWithPath:(NSString *)path
{
	return [[self alloc] initWithPath:path];
}

+ (OZArchiveReader *)readerWithData:(NSData *)data
{
	return [[self alloc] initWithData:data];
}

- (id)initWithURL:(NSURL *)url
{
	return [self initWithPath:url.path];
}

- (id)initWithPath:(NSString *)path
{
	if ((self = [super init]))
	{
		_unzipper = unzOpen64(path.UTF8String);
		if (!_unzipper)
			return nil;
	}
	return self;
}

- (id)initWithData:(NSData *)data
{
	if ((self = [super init]))
	{
		_unzipper = unzOpen2_64((__bridge void *)data, &OZ_NSData_rw_functions);
		if (!_unzipper)
			return nil;
	}
	return self;
}

- (void)dealloc
{
	if (_unzipper)
		unzClose(_unzipper);
}

- (uint64_t)entryCount
{
	unz_global_info64	info = { 0, 0 };
	
	if (unzGetGlobalInfo64(_unzipper, &info) != UNZ_OK)
		return UINT64_MAX;
	return info.number_entry;
}

- (NSString *)globalComment
{
	unz_global_info64	info = { 0, 0 };
	
	if (unzGetGlobalInfo64(_unzipper, &info) != UNZ_OK)
		return nil;
	
	char				*buf = calloc(info.size_comment + 1, sizeof(char));
	NSString			*result = nil;
	
	if (unzGetGlobalComment(_unzipper, buf, info.size_comment) == UNZ_OK)
		result = [NSString stringWithUTF8String:buf];
	free(buf);
	return result;
}

- (void)enumerateArchiveContentsWithBlock:(BOOL (^)(OZArchivedFile *file, NSError *error))block
{
	int		result = 0;
	
	if ((result = unzGoToFirstFile(_unzipper)) != UNZ_OK)
	{
		block(nil, [NSError errorWithDomain:@"OZArchiveReader" code:result userInfo:nil]);
		return;
	}
	
	BOOL	cont = YES;
	
	do
	{
		OZArchivedFile	*file = [[OZArchivedFile alloc] initWithArchive:self withCurrentFileOfUnzipper:_unzipper];
		
		if (file)
			cont = block(file, nil);
		else
			cont = block(nil, [NSError errorWithDomain:@"OZArchiveReader" code:UNZ_PARAMERROR userInfo:nil]);
	} while (cont && (result = unzGoToNextFile(_unzipper)) == UNZ_OK);
	
	if (result != UNZ_END_OF_LIST_OF_FILE)
		block(nil, [NSError errorWithDomain:@"OZArchiveReader" code:result userInfo:nil]);
}

- (OZArchivedFile *)fileWithPath:(NSString *)pathInArchive caseSensitive:(BOOL)cs
{
	int		result = 0;
	
	if ((result = unzLocateFile(_unzipper, pathInArchive.UTF8String, cs ? 1 : 2)) != UNZ_OK)
		return nil;
	return [[OZArchivedFile alloc] initWithArchive:self withCurrentFileOfUnzipper:_unzipper];
}

@end
