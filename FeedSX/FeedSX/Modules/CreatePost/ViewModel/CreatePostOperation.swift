//
//  PostCreateOperation.swift
//  LMFeedUI
//
//  Created by Pushpendra Singh on 26/05/23.
//

import Foundation
import LikeMindsFeed
import UIKit
import AVFoundation

class CreatePostOperation {
    
    static let shared = CreatePostOperation()
    var attachmentList: [AWSFileUploadRequest]?
    let dispatchGroup = DispatchGroup()
    private init(){}
    
    private func postMessageForCompleteCreatePost(with error: String?) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .postCreationCompleted, object: error)
        }
    }
    
    private func postMessageForCreatingPost(with object: Any? = nil) {
        DispatchQueue.main.async {[weak self] in
            let attachment = self?.attachmentList?.first
            NotificationCenter.default.post(name: .postCreationStarted, object: attachment?.thumbnailImage)
        }
    }
    
    func createPost(request: AddPostRequest) {
        postMessageForCreatingPost()
        LMFeedClient.shared.addPost(request) { [weak self] response in
            self?.attachmentList = nil
            self?.postMessageForCompleteCreatePost(with: response.errorMessage)
        }
    }
    
    func createPostWithAttachment(attachments:  [AWSFileUploadRequest], postCaption: String?, topics: [String]) {
        self.attachmentList = attachments
        guard attachments.count > 0 else { return }
        postMessageForCreatingPost()
        for attachment in attachments {
            dispatchGroup.enter()
            switch attachment.fileType {
            case .image:
                guard let url = URL(string: attachment.fileUrl),
                      let data = try? Data(contentsOf:url),
                      let image = UIImage(data: data)
                else {
                    print("Unable to upload image.. \(attachment.fileUrl)")
                    return
                }
                AWSUploadManager.sharedInstance.awsUploader(uploaderType: .image, filePath: attachment.awsFilePath, image: image, thumbNailUrl: nil,index: attachment.index) { (progress) in
                    print("Image - \(attachment.index) upload progress...\(progress)")
                } completion: {[weak self] (imageResponse,thumbnailUrl, error, nil)  in
                    print(imageResponse)
                    attachment.awsUploadedUrl = (imageResponse as? String) ?? ""
                    self?.dispatchGroup.leave()
                }
            case .video:
                guard let url = URL(string: attachment.fileUrl)
                else {
                    print("Unable to upload video.. \(attachment.fileUrl)")
                    return
                }
                AWSUploadManager.sharedInstance.awsUploader(uploaderType: .video, filePath: attachment.awsFilePath, path: url.path , thumbNailUrl: nil, index: attachment.index ) { (progress) in
                    print("video - \(attachment.index) upload progress...\(progress)")
                } completion: {[weak self] (videoResponse, thumbnailUrl, error, nil)  in
                    print(videoResponse)
                    attachment.awsUploadedUrl = (videoResponse as? String) ?? ""
                    self?.dispatchGroup.leave()
                }
            case .file:
                AWSUploadManager.sharedInstance.awsUploader(uploaderType: .file, filePath: attachment.awsFilePath, path: attachment.fileUrl, thumbNailUrl: nil, index: attachment.index ) { (progress) in
                    print("file - \(attachment.index) upload progress...\(progress)")
                } completion: {[weak self] (fileResponse, thumbnailUrl, error, nil)  in
                    print(fileResponse)
                    attachment.awsUploadedUrl = (fileResponse as? String) ?? ""
                    self?.dispatchGroup.leave()
                }
            default:
                break
            }
        }
        self.dispatchGroup.notify(queue: DispatchQueue.global()) { [weak self] in
            guard let attachmentList = self?.attachmentList else {return}
            if attachmentList.count > 0 {
                var attachments: [Attachment] = []
                for attachedItem in attachmentList {
                    switch attachedItem.fileType {
                    case .image:
                        guard let imageAttachment = self?.imageAttachmentData(attachment: attachedItem) else { continue }
                        attachments.append(imageAttachment)
                    case .video:
                        guard let videoAttachment = self?.videoAttachmentData(attachment: attachedItem) else { continue }
                        attachments.append(videoAttachment)
                    case .file:
                        guard let docAttachment = self?.fileAttachmentData(attachment: attachedItem) else { continue }
                        attachments.append(docAttachment)
                    default:
                        break
                    }
                }
                guard attachments.count == attachmentList.count else {
                    self?.postMessageForCompleteCreatePost(with: "Oops! Somthing went wrong!\nPlease try again later.")
                    return
                }
                let addPostRequest = AddPostRequest.builder()
                    .text(postCaption)
                    .attachments(attachments)
                    .addTopics(topics)
                    .build()
                LMFeedClient.shared.addPost(addPostRequest) { [weak self] response in
                    print("Post Creation with attachment done....")
                    self?.attachmentList = nil
                    self?.postMessageForCompleteCreatePost(with: response.errorMessage)
                }
            }
        }
    }
    
    func imageAttachmentData(attachment: AWSFileUploadRequest) -> Attachment? {
        guard let awsUrl = attachment.awsUploadedUrl, !awsUrl.isEmpty else { return nil}
        var size: Int?
        if let attr = try? FileManager.default.attributesOfItem(atPath: attachment.fileUrl) {
            size = attr[.size] as? Int
        }
        let attachmentMeta = AttachmentMeta()
            .attachmentUrl(awsUrl)
            .size(size ?? 0)
            .name(attachment.name)
        let attachmentRequest = Attachment()
            .attachmentType(.image)
            .attachmentMeta(attachmentMeta)
        return attachmentRequest
    }
    
    func fileAttachmentData(attachment: AWSFileUploadRequest) -> Attachment? {
        var size: Int? = attachment.documentAttachmentSize
        var numberOfPages: Int? = attachment.documentNumberOfPages
        guard let awsUrl = attachment.awsUploadedUrl, !awsUrl.isEmpty, let fileUrl = URL(string: attachment.fileUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else { return nil }
        if numberOfPages == nil, let pdf = CGPDFDocument(fileUrl as CFURL) {
            print("number of page: \(pdf.numberOfPages)")
            numberOfPages = pdf.numberOfPages
        }
        if size == nil, let attr = try? FileManager.default.attributesOfItem(atPath: fileUrl.relativePath) {
            size = attr[.size] as? Int
        }
        let attachmentMeta = AttachmentMeta()
            .attachmentUrl(awsUrl)
            .size(size ?? 0)
            .name(attachment.name)
            .pageCount(numberOfPages ?? 0)
            .format("pdf")
        let attachmentRequest = Attachment()
            .attachmentType(.doc)
            .attachmentMeta(attachmentMeta)
        return attachmentRequest
    }
    
    func videoAttachmentData(attachment: AWSFileUploadRequest) -> Attachment? {
        guard let awsUrl = attachment.awsUploadedUrl, !awsUrl.isEmpty, let url = URL(string: attachment.fileUrl) else { return nil}
        var size: Int?
        if let attr = try? FileManager.default.attributesOfItem(atPath: attachment.fileUrl) {
            size = attr[.size] as? Int
        }
        let asset = AVAsset(url: url)
        let duration = asset.duration
        let durationTime = CMTimeGetSeconds(duration)
        let attachmentMeta = AttachmentMeta()
            .attachmentUrl(awsUrl)
            .size(size ?? 0)
            .name(attachment.name)
            .duration(Int(durationTime))
        let attachmentRequest = Attachment()
            .attachmentType(.video)
            .attachmentMeta(attachmentMeta)
        return attachmentRequest
    }
    
}
