//
//  AWS.swift
//  DrawPad
//
//  Created by Andrew Morgan on 07/11/2019.
//  Copyright © 2019 MongoDB Inc. All rights reserved.
//

import Foundation
import StitchCore
import StitchAWSService
import StitchCoreAWSService
import MongoSwift

class AWS {
  static var uploadToS3: Bool = true
  
  static func uploadImage(image: Data, email imageName: String, tag: String) -> String {
    if !uploadToS3 {
      print("Skip S3")
      return ""
    }
    
    // MyAwsService is the name of the aws service you created in
    // the stitch UI, and it is configured with a rule
    // that allows the PutObject action on the s3 API
    let aws = stitch.serviceClient(fromFactory: awsServiceClientFactory, withName: "AWS")
    var url: String = ""
    var imageBSON: Binary
    
    do {
      imageBSON = try Binary(data: image, subtype: .generic)
    } catch {
      print("Failed to convert the image to BSON")
      return url
    }
    
    // These are the arguments specifically for s3 service PutObject function
    let args: Document = [
      "Bucket": Constants.S3_BUCKET_NAME,
       "Key": "\(imageName)-\(tag)",
       "ACL": "public-read",
       "ContentType": "image/jpeg",
       "Body": imageBSON,
       // or "Body": Binary.init(...)
    ]
    let semaphore = DispatchSemaphore(value: 0)
    do {
      let request = try AWSRequestBuilder()
         .with(service: "s3")
         .with(action: "PutObject")
        .with(region: Constants.AWS_REGION) // this is optional
         .with(arguments: args) // depending on the service and action, this may be optional as well
        .build()

      aws.execute(request: request) { (result: StitchResult<Document>) in
        switch result {
        case .success(let awsResult):
          print("Executed AWS request \(awsResult)")
          url = "https://\(Constants.S3_BUCKET_NAME).s3.amazonaws.com/\(imageName)-\(tag)"
          semaphore.signal()
         case .failure(let awsFailure):
          print ("Failed to execute AWS request: \(awsFailure)")
          semaphore.signal()
         }
      }
    } catch {
      print("Failed so send AWS S3 request")
      semaphore.signal()
    }
    semaphore.wait()
    return url
  }
}
