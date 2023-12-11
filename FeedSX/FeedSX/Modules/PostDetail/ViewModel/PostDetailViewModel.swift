//
//  PostDetailViewModel.swift
//  LMFeedUI
//
//  Created by Pushpendra Singh on 10/04/23.
//

import Foundation
import LikeMindsFeed

protocol PostDetailViewModelDelegate: AnyObject {
    func didReceiveComments()
    func didReceiveCommentsReply(withCommentId commentId: String, withBatchFirstReplyId replyId: String)
    func insertAndScrollToRecentComment(_ indexPath: IndexPath)
    func didReceivedMemberState()
    func reloadSection(_ indexPath: IndexPath)
    func didReceivedEditResponse(_ indexPath: IndexPath)
}

final class PostDetailViewModel: BaseViewModel {
    var comments: [PostDetailDataModel.Comment] = []
    var postDetail: PostFeedDataView?
    private var commentCurrentPage: Int = 1
    var commentPageSize: Int = 10
    private var repliesCurrentPage1: Int = 1
    var isCommentLoading: Bool = false
    var isCommentRepliesLoading: Bool = false
    weak var delegate: PostDetailViewModelDelegate?
    var postId: String = ""
    var taggedUsers: [TaggedUser] = []
    var replyOnComment: PostDetailDataModel.Comment?
    var editingComment: PostDetailDataModel.Comment?
    
    func notifyObjectChanges() {
        NotificationCenter.default.post(name: .refreshHomeFeedDataObject, object: postDetail)
    }
    
    func postComment(text: String) {
        let parsedTaggedUserText = TaggedRouteParser.shared.editAnswerTextWithTaggedList(text: text, taggedUsers: self.taggedUsers)
        if let replyOnComment = self.replyOnComment {
            self.postCommentsReply(commentId: replyOnComment.commentId, comment: parsedTaggedUserText)
        } else {
            self.postCommentOnPost(parsedTaggedUserText)
        }
    }
    
    func editComment(comment: String, section: Int?, row: Int?) {
        let parsedTaggedUserText = TaggedRouteParser.shared.editAnswerTextWithTaggedList(text: comment, taggedUsers: self.taggedUsers)
        if let editingComment = self.editingComment,
           let postId = editingComment.postId {
            self.editComment(postId: postId, commentId: editingComment.commentId, comment: parsedTaggedUserText, section: section, row: row)
            self.editingComment = nil
        }
    }
    
    func repliesCount(section: Int) -> Int {
        let comment = comments[section]
        if comment.replies.count > 0 {
            return comment.replies.count >= comment.commentCount ? comment.replies.count : comment.replies.count + 1
        } else {
            return 0
        }
    }
    
    func pullToRefreshData() {
        commentCurrentPage = 1
        getPostDetail()
    }
    
    func getPostDetail() {
        guard !self.isCommentLoading else { return }
        let request = GetPostRequest.builder()
            .postId(postId)
            .page(commentCurrentPage)
            .pageSize(commentPageSize)
            .build()
        self.isCommentLoading = true
        LMFeedClient.shared.getPost(request) {[weak self] response in
            if response.success == false {
                self?.postErrorMessageNotification(error: response.errorMessage)
            }
            guard let postDetails = response.data?.post, let users =  response.data?.users else {
                self?.isCommentLoading = false
                return
            }
            
            let topics = response.data?.topics?.compactMap { $0.value } ?? []
            self?.postDetail = PostFeedDataView(post: postDetails, user: users[postDetails.uuid ?? ""], topics: topics)
            if let replies = postDetails.replies, replies.count > 0 {
                if (self?.commentCurrentPage ?? 1) > 1 {
                    self?.comments.append(contentsOf: replies.compactMap({.init(comment: $0, user: users[$0.uuid ?? ""])}))
                } else {
                    self?.comments =  replies.compactMap({.init(comment: $0, user: users[$0.uuid ?? ""])})
                }
                self?.commentCurrentPage += 1
            }
            self?.delegate?.didReceiveComments()
            self?.isCommentLoading = false
        }
    }
    
    func getCommentReplies(commentId: String) {
        guard !self.isCommentRepliesLoading else { return }
        guard let selectedComment = self.comments.filter({$0.commentId == commentId}).first else {return}
        self.isCommentRepliesLoading = true
        let repliesCurrentPage = (selectedComment.replies.count/5) + 1
        let request = GetCommentRequest.builder()
            .postId(postId)
            .commentId(commentId)
            .page(repliesCurrentPage)
            .pageSize(5)
            .build()
        LMFeedClient.shared.getComment(request) {[weak self] response in
            if response.success == false {
                self?.postErrorMessageNotification(error: response.errorMessage)
            }
            guard let comment = response.data?.comment, let users =  response.data?.users else {
                self?.isCommentRepliesLoading = false
                return
            }
            if repliesCurrentPage > 1 {
                selectedComment.replies.append(contentsOf: comment.replies?.compactMap({.init(comment: $0, user: users[$0.uuid ?? ""])}) ?? [])
            } else {
                selectedComment.replies = comment.replies?.compactMap({.init(comment: $0, user: users[$0.uuid ?? ""])}) ?? []
            }
            self?.delegate?.didReceiveCommentsReply(withCommentId: commentId, withBatchFirstReplyId: comment.replies?.first?.id ?? "")
            self?.isCommentRepliesLoading = false
        }
    }
    
    private func postCommentOnPost(_ comment: String) {
        let request = AddCommentRequest.builder()
            .postId(self.postId)
            .text(comment)
            .tempId("\(Date().millisecondsSince1970.intValue)")
            .build()
        self.postCommentOnPostUpdateLoacally(request: request)
        LMFeedClient.shared.addComment(request) { [weak self] response in
            if response.success == false {
                self?.postErrorMessageNotification(error: response.errorMessage)
            }
            guard let comment = response.data?.comment, let users =  response.data?.users else {
                return
            }
            LMFeedAnalytics.shared.track(eventName: LMFeedAnalyticsEventName.Comment.onPost, eventProperties: ["post_id": self?.postId ?? "", "comment_id": comment.id ?? ""])
            let postComment = PostDetailDataModel.Comment(comment: comment, user: users[comment.uuid ?? ""])
            if let indexOfComment = self?.comments.firstIndex(where: {$0.tempId == postComment.tempId}) {
                self?.comments[indexOfComment] = postComment
                self?.delegate?.reloadSection(IndexPath(row: NSNotFound, section: 0))
            } else {
                self?.postDetail?.commentCount += 1
                self?.comments.insert(postComment, at: 0)
                self?.delegate?.insertAndScrollToRecentComment(IndexPath(row: NSNotFound, section: 1))
            }
            self?.notifyObjectChanges()
        }
    }
    
    private func postCommentOnPostUpdateLoacally(request: AddCommentRequest) {
        let jsonEncoder = JSONEncoder()
        guard let jsonData = try? jsonEncoder.encode(request) else {
            print("Unable to endcode request..")
            return
        }
        // Decode
        let jsonDecoder = JSONDecoder()
        guard let comment = try? jsonDecoder.decode(LikeMindsFeed.Comment.self, from: jsonData) else {
            print("Unable to decode request..")
            return
        }
        
        let postComment = PostDetailDataModel.Comment(comment: comment, user: LocalPrefrerences.getUserData())
        postComment.createdAt = (postComment.tempId ?? "").intValue
        self.postDetail?.commentCount += 1
        self.comments.insert(postComment, at: 0)
        self.delegate?.insertAndScrollToRecentComment(IndexPath(row: NSNotFound, section: 1))
    }
    
    private func postCommentsReply(commentId: String, comment: String) {
        let request = ReplyCommentRequest.builder()
            .postId(postId)
            .commentId(commentId)
            .text(comment)
            .tempId("\(Date().millisecondsSince1970.intValue)")
            .build()
        self.postCommentsReplyUpdateLoacally(request: request, commentId: commentId)
        LMFeedClient.shared.replyComment(request) { [weak self] response in
            if response.success == false {
                self?.postErrorMessageNotification(error: response.errorMessage)
            }
            guard let comment = response.data?.comment, let users =  response.data?.users else {
                return
            }
            LMFeedAnalytics.shared.track(eventName: LMFeedAnalyticsEventName.Comment.reply, eventProperties: ["post_id": self?.postId ?? "", "comment_reply_id": comment.id ?? "", "comment_id": commentId])
            let postComment = PostDetailDataModel.Comment(comment: comment, user: users[comment.uuid ?? ""])
            if let replyCommentIndex = self?.replyOnComment?.replies.firstIndex(where: {$0.tempId == postComment.tempId}) {
                self?.replyOnComment?.replies[replyCommentIndex] = postComment
                self?.replyOnComment = nil
                guard let section = self?.comments.firstIndex(where:{$0.commentId == commentId}) else {
                    self?.delegate?.didReceiveCommentsReply(withCommentId: commentId, withBatchFirstReplyId: comment.replies?.first?.id ?? "")
                    return
                }
                self?.delegate?.reloadSection(IndexPath(row: replyCommentIndex, section: section+1))
            } else {
                self?.replyOnComment?.replies.insert(postComment, at: 0)
                self?.replyOnComment?.commentCount += 1
                self?.replyOnComment = nil
                guard let section = self?.comments.firstIndex(where:{$0.commentId == commentId}) else {
                    self?.delegate?.didReceiveCommentsReply(withCommentId: commentId, withBatchFirstReplyId: comment.replies?.first?.id ?? "")
                    return
                }
                self?.delegate?.insertAndScrollToRecentComment(IndexPath(row: 0, section: section+1))
            }
        }
    }
    
    private func postCommentsReplyUpdateLoacally(request: ReplyCommentRequest, commentId: String) {
        let jsonEncoder = JSONEncoder()
        guard let jsonData = try? jsonEncoder.encode(request) else {
            print("Unable to endcode request..")
            return
        }
        // Decode
        let jsonDecoder = JSONDecoder()
        guard let comment = try? jsonDecoder.decode(LikeMindsFeed.Comment.self, from: jsonData) else {
            print("Unable to decode request..")
            return
        }
        let postComment = PostDetailDataModel.Comment(comment: comment, user: LocalPrefrerences.getUserData())
        postComment.createdAt = (postComment.tempId ?? "").intValue
        self.replyOnComment?.replies.insert(postComment, at: 0)
        self.replyOnComment?.commentCount += 1
        guard let section = self.comments.firstIndex(where:{$0.commentId == commentId}) else {
            self.delegate?.didReceiveCommentsReply(withCommentId: commentId, withBatchFirstReplyId: comment.replies?.first?.id ?? "")
            return
        }
        self.delegate?.insertAndScrollToRecentComment(IndexPath(row: 0, section: section+1))
    }
    
    func likePost(postId: String) {
        let request = LikePostRequest.builder()
            .postId(postId)
            .build()
        LMFeedClient.shared.likePost(request) {[weak self] response in
            if response.success {
                self?.notifyObjectChanges()
            } else {
                let isLike = !(self?.postDetail?.isLiked ?? false)
                self?.postDetail?.isLiked = isLike
                self?.postDetail?.likedCount += isLike ? 1 : -1
                self?.delegate?.reloadSection(IndexPath(row: 0, section: 0))
                self?.postErrorMessageNotification(error: response.errorMessage)
            }
        }
    }
    
    func likeComment(postId: String, commentId: String, section: Int?, row: Int?) {
        let request = LikeCommentRequest.builder()
            .postId(postId)
            .commentId(commentId)
            .build()
        LMFeedClient.shared.likeComment(request) { [weak self] response in
            if response.success {
//                self?.notifyObjectChanges()
            } else {
                if let section = section, var comment = self?.comments[section] {
                    var tmpRow: Int = 0
                    if let row = row {
                        comment =  comment.replies[row]
                        tmpRow = row
                    }
                    let isLike = !(comment.isLiked)
                    comment.isLiked = isLike
                    comment.likedCount += isLike ? 1 : -1
                    self?.delegate?.reloadSection(IndexPath(row: tmpRow, section: section))
                }
                self?.postErrorMessageNotification(error: response.errorMessage)
            }
        }
    }

    func savePost(postId: String) {
        let request = SavePostRequest.builder()
            .postId(postId)
            .build()
        LMFeedClient.shared.savePost(request) { [weak self] response in
            if response.success {
                self?.notifyObjectChanges()
            } else {
                self?.postDetail?.isSaved = !(self?.postDetail?.isSaved ?? false)
                self?.delegate?.reloadSection(IndexPath(row: 0, section: 0))
                self?.postErrorMessageNotification(error: response.errorMessage)
            }
        }
    }
    
    func pinUnpinPost(postId: String) {
        let request = PinPostRequest.builder()
            .postId(postId)
            .build()
        LMFeedClient.shared.pinPost(request) {[weak self] response in
            if response.success {
                self?.postDetail?.isPinned = !(self?.postDetail?.isPinned ?? false)
                self?.postDetail?.updatePinUnpinMenu()
                self?.delegate?.reloadSection(IndexPath(row: 0, section: 0))
                self?.notifyObjectChanges()
            } else {
                self?.postErrorMessageNotification(error: response.errorMessage)
            }
        }
    }
    
    func editComment(postId: String, commentId: String, comment: String, section: Int?, row: Int?) {
        let request = EditCommentRequest.builder()
            .postId(postId)
            .commentId(commentId)
            .text(comment)
            .build()
        LMFeedClient.shared.editComment(request) {[weak self] response in
            if response.success {
                guard let comment = response.data?.comment, let users =  response.data?.users else {
                    return
                }
                let postComment = PostDetailDataModel.Comment(comment: comment, user: users[comment.uuid ?? ""])
                guard let section = section else  {
                    return
                }
                if let row = row {
                    self?.comments[section].replies[row] = postComment
                    self?.delegate?.didReceivedEditResponse(IndexPath(row: row, section: section + 1))
                } else {
                    self?.comments[section] = postComment
                    self?.delegate?.didReceivedEditResponse(IndexPath(row: NSNotFound, section: section))
                }
            } else {
                self?.postErrorMessageNotification(error: response.errorMessage)
            }
        }
    }
    
    func getMemberState() {
        LMFeedClient.shared.getMemberState() { [weak self] result in
            print(result)
            if result.success,
               let memberState = result.data {
                LocalPrefrerences.saveObject(memberState, forKey: LocalPreferencesKey.memberStates)
            } else {
                print(result.errorMessage ?? "")
            }
            self?.delegate?.didReceivedMemberState()
        }
    }
    
    func hasRightForCommentOnPost() -> Bool {
        if self.isAdmin() { return true }
        guard let rights = LocalPrefrerences.getMemberStateData()?.memberRights,
              let right = rights.filter({$0.state == .commentOrReplyOnPost}).first else {
            return true
        }
        return right.isSelected ?? true
    }
    
    func isAdmin() -> Bool {
        guard let member = LocalPrefrerences.getMemberStateData()?.member else { return false }
        return member.state == 1
    }
    
    func isOwnPost() -> Bool {
        guard let member = LocalPrefrerences.getMemberStateData()?.member, let post = self.postDetail else { return false }
        return post.postByUser?.uuid == member.clientUUID
    }
    
    func isOwnComment(section: Int) -> Bool {
        guard let member = LocalPrefrerences.getMemberStateData()?.member  else { return false }
        let comment = self.comments[section]
        return comment.user.uuid == member.clientUUID
    }
    
    func isOwnReply(section: Int, row: Int) -> Bool {
        guard let member = LocalPrefrerences.getMemberStateData()?.member  else { return false }
        let comment = self.comments[section].replies[row]
        return comment.user.uuid == member.clientUUID
    }
    
    func totalCommentsCount() -> String {
        let count = (self.postDetail?.commentCount) ?? 0
        switch count {
        case 0:
            return "0 comments"
        case 1:
            return "1 comment"
        default:
            return "\(count) comments"
        }
    }
}
