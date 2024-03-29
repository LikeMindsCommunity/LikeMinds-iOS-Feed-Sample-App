//
//  CreatePostViewModel.swift
//  LMFeedUI
//
//  Created by Pushpendra Singh on 04/04/23.
//

import Foundation
import PDFKit
import LikeMindsFeed
import AVFoundation

protocol CreatePostViewModelDelegate: AnyObject {
    func reloadCollectionView()
    func reloadActionTableView()
    func showError(errorMessage: String?)
    func showHideTopicView(topics: [TopicViewCollectionCell.ViewModel])
}

class TaggedUser {
    var user: TaggingUser
    var range: NSRange
    init(_ user: TaggingUser, range: NSRange) {
        self.user = user
        self.range = range
    }
}

class TaggingUser {
    var name: String?
    var id: String
    
    init(name: String?, id: String?) {
        self.name = name
        self.id = id ?? ""
    }
}

struct TopicFeedDataModel {
    let title: String
    let topicID: String
    var isEnabled: Bool
}

final class CreatePostViewModel: BaseViewModel {
    var imageAndVideoAttachments: [PostFeedDataView.ImageVideo] = []
    var documentAttachments: [PostFeedDataView.Attachment] = []
    var linkAttatchment: PostFeedDataView.LinkAttachment?
    let attachmentUploadTypes: [AttachmentUploadType] = [.image, .video, .document]
    var currentSelectedUploadeType: CreatePostViewModel.AttachmentUploadType = .unknown
    weak var delegate: CreatePostViewModelDelegate?
    var postCaption: String?
    var taggedUsers: [TaggedUser] = []
    
    private var isShowTopicFeed = false
    var selectedTopics: [TopicFeedDataModel] = []
    private var selectedTopicIds: [String] {
        selectedTopics.map {
            $0.topicID
        }
    }
    enum AttachmentUploadType: String {
        case document = "Attach Files"
        case image = "Add Photo"
        case video = "Add Video"
        case link
        case dontAttachOgTag
        case unknown
    }
    
    func getTopics() {
        let request = TopicFeedRequest.builder()
            .setEnableState(true)
            .build()
        
        LMFeedClient.shared.getTopicFeed(request) { [weak self] response in
            self?.isShowTopicFeed = !(response.data?.topics?.isEmpty ?? true)
            self?.setupTopicFeed()
        }
    }
    
    func updateSelectedTopics(with data: [TopicFeedDataModel]) {
        self.selectedTopics = data
        setupTopicFeed()
    }
    
    func addDocumentAttachment(fileUrl: URL) {
        guard let docData = try? Data(contentsOf: fileUrl) else { return }
        try? docData.write(to: fileUrl)
        var attachment = PostFeedDataView.Attachment(attachmentUrl: fileUrl.path, attachmentType: "PDF", attachmentSize: 0, numberOfPages: 0)
        if let pdf = CGPDFDocument(fileUrl as CFURL) {
            print("number of page: \(pdf.numberOfPages)")
            attachment.numberOfPages = pdf.numberOfPages
        }
        if let attr = try? FileManager.default.attributesOfItem(atPath: fileUrl.relativePath) {
            attachment.attachmentSize = attr[.size] as? Int
        }
        if let image = generatePdfThumbnail(of: CGSize(width: 100, height: 100), for: fileUrl, atPage: 0){
            attachment.thumbnailImage = image
        }
        self.documentAttachments.append(attachment)
        self.delegate?.reloadCollectionView()
    }
    
    func addImageVideoAttachment(fileUrl: URL, type: AttachmentUploadType) {
        var attachment = PostFeedDataView.ImageVideo(fileType: type == .image ? .image : .video)
        attachment.url = fileUrl.absoluteString
        attachment.type = fileUrl.pathExtension
        if let attr = try? FileManager.default.attributesOfItem(atPath: fileUrl.relativePath) {
            attachment.size = attr[.size] as? Int
            if let size = attachment.size, (size/1000) > 100000 {
                return
            }
        }
        if type == .image {
            attachment.thumbnailImage = UIImage(contentsOfFile: fileUrl.path)
        } else {
            attachment.thumbnailImage = generateVideoThumbnail(forUrl: fileUrl)
        }
        self.imageAndVideoAttachments.append(attachment)
    }
    
    func generatePdfThumbnail(of thumbnailSize: CGSize , for documentUrl: URL, atPage pageIndex: Int) -> UIImage? {
        let pdfDocument = PDFDocument(url: documentUrl)
        let pdfDocumentPage = pdfDocument?.page(at: pageIndex)
        return pdfDocumentPage?.thumbnail(of: thumbnailSize, for: PDFDisplayBox.trimBox)
    }
    
    func generateVideoThumbnail(forUrl url: URL) -> UIImage? {
        let asset: AVAsset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60), actualTime: nil)
            return UIImage(cgImage: thumbnailImage)
        } catch let error {
            print(error)
        }
        return nil
    }
    
    func parseMessageForLink(message: String) {
        guard let link = message.detectedFirstLink, currentSelectedUploadeType != .dontAttachOgTag else {
            self.linkAttatchment = nil
            self.delegate?.reloadCollectionView()
            return
        }
        decodeUrl(stringUrl: link)
    }
    
    func verifyOgTagsAndCreatePost(message: String, completion: (() -> Void)?) {
        guard let link = message.detectedFirstLink else {
            self.linkAttatchment = nil
            completion?()
            return
        }
        let request = DecodeUrlRequest.builder()
            .link(link)
            .build()
        LMFeedClient.shared.decodeUrl(request) {[weak self] response in
            print(response)
            if response.success, let ogTags = response.data?.oGTags {
                self?.currentSelectedUploadeType = .link
                self?.linkAttatchment = .init(title: ogTags.title, linkThumbnailUrl: ogTags.image, description: ogTags.description, url: ogTags.url)
            } else {
                self?.linkAttatchment = nil
            }
            completion?()
        }
    }
    
    func decodeUrl(stringUrl: String) {
        let request = DecodeUrlRequest.builder()
            .link(stringUrl)
            .build()
        LMFeedClient.shared.decodeUrl(request) {[weak self] response in
            print(response)
            if response.success, let ogTags = response.data?.oGTags {
                self?.currentSelectedUploadeType = .link
                self?.linkAttatchment = .init(title: ogTags.title, linkThumbnailUrl: ogTags.image, description: ogTags.description, url: ogTags.url)
            } else {
                self?.linkAttatchment = nil
            }
            self?.delegate?.reloadCollectionView()
        }
    }
    
    func createPost(_ text: String?) {
        let parsedTaggedUserPostText = TaggedRouteParser.shared.editAnswerTextWithTaggedList(text: text, taggedUsers: self.taggedUsers)
        let filePath = "files/post/\(LocalPrefrerences.getUserData()?.clientUUID ?? "user")/"
        if !imageAndVideoAttachments.isEmpty {
            var imageVideoAttachments: [AWSFileUploadRequest] = []
            var index = 0
            for attachedItem in self.imageAndVideoAttachments {
                guard let fileUrl = attachedItem.url else { continue }
                let fileType: UploaderType = attachedItem.fileType == .image ? .image : .video
                let item = AWSFileUploadRequest(fileUrl: fileUrl, awsFilePath: filePath, fileType: fileType, index: index, name: attachedItem.url?.components(separatedBy: "/").last ?? "attache_\(Date().millisecondsSince1970)")
                item.thumbnailImage = attachedItem.thumbnailImage
                imageVideoAttachments.append(item)
                index += 1
            }
            CreatePostOperation.shared.createPostWithAttachment(attachments: imageVideoAttachments, postCaption: parsedTaggedUserPostText, topics: selectedTopicIds)
        } else if !documentAttachments.isEmpty {
            var documentAttachments: [AWSFileUploadRequest] = []
            var index = 0
            for attachedItem in self.documentAttachments {
                guard let fileUrl = attachedItem.attachmentUrl else { continue }
                let fileType: UploaderType = .file
                let item = AWSFileUploadRequest(fileUrl: fileUrl, awsFilePath: filePath, fileType: fileType, index: index, name: attachedItem.attachmentUrl?.components(separatedBy: "/").last ?? "attache_\(Date().millisecondsSince1970)")
                item.thumbnailImage = attachedItem.thumbnailImage
                item.documentNumberOfPages = attachedItem.numberOfPages
                item.documentAttachmentSize = attachedItem.attachmentSize
                documentAttachments.append(item)
                index += 1
            }
            CreatePostOperation.shared.createPostWithAttachment(attachments: documentAttachments, postCaption: parsedTaggedUserPostText, topics: selectedTopicIds)
        } else if self.linkAttatchment != nil {
            self.createPostWithLinkAttachment(postCaption: parsedTaggedUserPostText)
        } else if !parsedTaggedUserPostText.isEmpty {
            self.createPostWithOutAttachment(postCaption: parsedTaggedUserPostText)
        }
    }
}

private extension CreatePostViewModel {
    func createPostWithLinkAttachment(postCaption: String?) {
        guard let linkAttatchment = self.linkAttatchment else { return }
        let attachmentMeta = AttachmentMeta()
            .ogTags(.init()
                .image(linkAttatchment.linkThumbnailUrl ?? "")
                .title(linkAttatchment.title ?? "")
                .description(linkAttatchment.description ?? "")
                .url(linkAttatchment.url ?? ""))
        let attachmentRequest = Attachment()
            .attachmentType(.link)
            .attachmentMeta(attachmentMeta)
        let addPostRequest = AddPostRequest.builder()
            .text(postCaption)
            .attachments([attachmentRequest])
            .addTopics(selectedTopicIds)
            .build()
        CreatePostOperation.shared.createPost(request: addPostRequest)
    }
    
    func createPostWithOutAttachment(postCaption: String?) {
        let addPostRequest = AddPostRequest.builder()
            .text(postCaption)
            .addTopics(selectedTopicIds)
            .build()
        CreatePostOperation.shared.createPost(request: addPostRequest)
    }
    
    func setupTopicFeed() {
        if !isShowTopicFeed {
            delegate?.showHideTopicView(topics: [])
            return
        }
        
        var transformedCells: [TopicViewCollectionCell.ViewModel] = selectedTopics.map {
            .init(image: nil, title: $0.title)
        }
        
        transformedCells.append(.init(image: transformedCells.isEmpty ? ImageIcon.plusIcon : ImageIcon.editIcon, title: transformedCells.isEmpty ? "Select Topics" : nil, isEditCell: true))
        
        delegate?.showHideTopicView(topics: transformedCells)
    }
}
