//
//  main.m
//  S3Sync
//
//  Created by Chris Hulbert on 3/10/2014.
//  Copyright (c) 2014 Chris Hulbert. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AFAmazonS3Manager.h"
#import "ListObjectsParser.h"
#import "S3Object.h"
#import "LocalFile.h"
#import "SyncContext.h"
#import "ReadConfigOperation.h"
#import "ScanLocalFilesOperation.h"
#import "CreateS3ManagerOperation.h"
#import "GetObjectListOperation.h"
#import "FinishedOperation.h"
#import "ComparingOperation.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        // Make the shared context.
        SyncContext *context = [[SyncContext alloc] init];
        
        // Make the operations.
        NSOperation *readConfig = [[ReadConfigOperation alloc] initWithContext:context];
        NSOperation *scanLocal = [[ScanLocalFilesOperation alloc] initWithContext:context dependencies:@[readConfig]];
        NSOperation *createS3 = [[CreateS3ManagerOperation alloc] initWithContext:context dependencies:@[readConfig]];
        NSOperation *getS3List = [[GetObjectListOperation alloc] initWithContext:context dependencies:@[createS3]];
        NSOperation *compare = [[ComparingOperation alloc] initWithContext:context dependencies:@[scanLocal, getS3List]];
        NSOperation *finished = [[FinishedOperation alloc] initWithContext:context dependencies:@[compare]];

        // Start it all off!
        [context.queue addOperations:@[readConfig, scanLocal, createS3, getS3List, finished]
                   waitUntilFinished:NO];
        
//        // Get the list of objects
//        // TODO use marker to get > 1000 of them.
//        NSLog(@"Getting object list from S3");
//        [context.s3Manager GET:@"/" parameters:nil success:^(AFHTTPRequestOperation *operation, NSXMLParser *responseObject) {
//            NSLog(@"Parsing objects");
//            ListObjectsParser *listObjects = [ListObjectsParser parse:responseObject];
//            NSLog(@"isTruncated: %@", listObjects.isTruncated ? @"Yes" : @"No");
//            NSLog(@"objects[%lu]: %@", (unsigned long)listObjects.objects.count ,listObjects.objects);
//            
//            #warning TODO Do something if it's truncated.
//            if (listObjects.isTruncated) {
//                NSLog(@"Can't handle truncated yet!");
//                exit(1);
//            }
//            
//            // Compare now.
//            NSMutableDictionary *s3ObjectIndex = [NSMutableDictionary dictionary];
//            for (S3Object *object in listObjects.objects) {
//                s3ObjectIndex[object.key] = object;
//            }
//            int filesSame=0, filesMissing=0, filesDiffSize=0, filesDiffHash=0;
//            long long sizeOfWork=0;
//            for (LocalFile *local in context.localFiles) {
//                S3Object *remote = s3ObjectIndex[local.relativePath];
//                if (!remote) {
//                    NSLog(@"Remote file missing: %@", local.relativePath);
//                    filesMissing++;
//                    sizeOfWork += local.size;
//                } else if (remote.size != local.size) {
//                    NSLog(@"File sizes are different: %@; local: %lld; remote: %lld", local.relativePath, local.size, remote.size);
//                    filesDiffSize++;
//                    sizeOfWork += local.size;
//                } else if (![remote.etag isEqualToString:local.md5Etag]) {
//                    NSLog(@"Hashes are different: %@", local.relativePath);
//                    filesDiffHash++;
//                    sizeOfWork += local.size;
//                } else {
//                    NSLog(@"Files are the same: %@", local.relativePath);
//                    filesSame++;
//                }
//            }
//            NSLog(@"Same files: %d, Missing: %d; Diff size: %d; Diff hash: %d; Bytes to do: %lld", filesSame, filesMissing, filesDiffSize, filesDiffHash, sizeOfWork);
//            
////            todo compare, show how many are different (lots!), how many match
//            
//            shouldKeepRunning = NO;
//        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//            NSLog(@"Error: %@", error);
//            shouldKeepRunning = NO;
//        }];
//        
//        // Get the file using url loading mechanisms to get the mime type.
//        NSMutableURLRequest *fileRequest = [NSMutableURLRequest requestWithURL:[NSURL fileURLWithPath:@"/Users/chris/car.jpg"]];
//        fileRequest.cachePolicy = NSURLCacheStorageNotAllowed;
//        NSURLResponse *fileResponse = nil;
//        NSError *fileError = nil;
//        NSData *data = [NSURLConnection sendSynchronousRequest:fileRequest returningResponse:&fileResponse error:&fileError];
//        
//        // Build the un-authed request.
//        NSURL *url = [context.s3Manager.baseURL URLByAppendingPathComponent:@"somefolder/subfolder/car.jpg"];
//        NSMutableURLRequest *originalRequest = [[NSMutableURLRequest alloc] initWithURL:url];
//        originalRequest.HTTPMethod = @"PUT";
//        originalRequest.HTTPBody = data;
//        [originalRequest setValue:base64Md5 forHTTPHeaderField:@"Content-MD5"];
//        [originalRequest setValue:fileResponse.MIMEType forHTTPHeaderField:@"Content-Type"];
//        
//        // Sign it.
//        NSURLRequest *request = [s3Manager.requestSerializer requestBySettingAuthorizationHeadersForRequest:originalRequest error:nil];
//
//        // Upload it.
////        AFHTTPRequestOperation *operation = [s3Manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
////            NSLog(@"Upload Complete");
//////            shouldKeepRunning = NO;
////        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
////            NSLog(@"Error: %@", error);
//////            shouldKeepRunning = NO;
////        }];
////        [s3Manager.operationQueue addOperation:operation];
//
//        #warning TODO Would be nice to use the multipart upload (not multipart form!) if the file is >5MB:
//        // http://docs.aws.amazon.com/AmazonS3/latest/API/mpUploadInitiate.html
//        
        // Run the run loop.
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        while (!context.shouldFinishRunning && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    }
    return 0;
}
