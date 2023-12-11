//
//  CommentHeaderViewCell.swift
//  LMFeedUI
//
//  Created by Pushpendra Singh on 09/04/23.
//

import UIKit

protocol CommentHeaderViewCellDelegate: AnyObject {
    func didTapActionButton(withActionType actionType: CellActionType, section: Int?)
}

class CommentHeaderViewCell: UITableViewHeaderFooterView {

    static let reuseIdentifier: String = String(describing: CommentHeaderViewCell.self)
    weak var delegate: CommentHeaderViewCellDelegate?
    var section: Int?
    
    let commentHeaderStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis  = .vertical
        sv.alignment = .fill
        sv.distribution = .fill
        sv.spacing = 0
        sv.translatesAutoresizingMaskIntoConstraints = false;
        return sv
    }()
    
    let usernameAndCaptionStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis  = .vertical
        sv.alignment = .fill
        sv.distribution = .fill
        sv.spacing = 0
        sv.translatesAutoresizingMaskIntoConstraints = false;
        return sv
    }()
    
    let usernameAndBadgeStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis  = .horizontal
        sv.alignment = .center
        sv.distribution = .fill
        sv.spacing = 8
        sv.translatesAutoresizingMaskIntoConstraints = false;
        return sv
    }()
    
    let badgeImageView: UIImageView = {
        let imageSize = 18.0
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageSize, height: imageSize))
        imageView.image = UIImage(systemName: "person.circle")
        imageView.isHidden = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setSizeConstraint(width: imageSize, height: imageSize)
        imageView.drawCornerRadius(radius: CGSize(width: imageSize, height: imageSize))
        return imageView
    }()
    
    let usernameLabel: LMLabel = {
        let label = LMPaddedLabel()
        label.paddingLeft = 0
        label.paddingRight = 0
        label.paddingTop = 10
        label.paddingBottom = 10
        label.font = LMBranding.shared.font(14, .bold)
        label.text = ""
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var badgeSpaceView: UIView = {
        let uiView = UIView()
        uiView.translatesAutoresizingMaskIntoConstraints = false
        return uiView
    }()
    
    let commentAndMoreStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis  = .horizontal
        sv.alignment = .center
        sv.distribution = .fill
        sv.spacing = 8
        sv.translatesAutoresizingMaskIntoConstraints = false;
        return sv
    }()
    
    var commentLabel: LMTextView = {
        let label = LMTextView(frame: .zero)
        label.isEditable = false
        label.isScrollEnabled = false
        label.font = LMBranding.shared.font(14, .regular)
        label.tintColor = LMBranding.shared.textLinkColor
        label.textContainer.lineFragmentPadding = 0
        label.textContainerInset = .zero
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var spaceView: UIView = {
        let uiView = UIView()
        uiView.translatesAutoresizingMaskIntoConstraints = false
        return uiView
    }()
    
    let moreImageView: UIImageView = {
        let menuImageSize = 30.0
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: menuImageSize, height: menuImageSize))
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        imageView.image = UIImage(systemName: ImageIcon.moreIcon)
        imageView.tintColor = ColorConstant.likeTextColor
        imageView.contentMode = .center
        imageView.preferredSymbolConfiguration = .init(pointSize: 20, weight: .light, scale: .large)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let likeAndReplyStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis  = .horizontal
        sv.alignment = .center
        sv.distribution = .fill
        sv.spacing = 5
        sv.translatesAutoresizingMaskIntoConstraints = false;
        return sv
    }()
    
    let likeStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis  = .horizontal
        sv.alignment = .center
        sv.distribution = .fill
        sv.spacing = 0
        sv.translatesAutoresizingMaskIntoConstraints = false;
        return sv
    }()
    
    let likeImageView: UIImageView = {
        let imageSize = 20.0
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        imageView.image = UIImage(systemName: ImageIcon.likeIcon)
        imageView.tintColor = ColorConstant.likeTextColor
        imageView.contentMode = .center
        imageView.preferredSymbolConfiguration = .init(pointSize: 15, weight: .light, scale: .medium)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let likeCountLabel: LMLabel = {
        let label = LMPaddedLabel()
        label.paddingLeft = 0
        label.paddingRight = 5
        label.paddingTop = 10
        label.paddingBottom = 10
        label.textColor = ColorConstant.likeTextColor
        label.font = LMBranding.shared.font(12, .regular)
        label.text = "Like"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let deviderLabel: LMLabel = {
        let label = LMPaddedLabel()
        label.paddingRight = 8
        label.font = LMBranding.shared.font(16, .regular)
        label.text = "|"
        label.textColor = ColorConstant.likeTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let replyStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis  = .horizontal
        sv.alignment = .center
        sv.distribution = .fill
        sv.spacing = 0
        sv.translatesAutoresizingMaskIntoConstraints = false;
        return sv
    }()
    
    let replyLabel: LMLabel = {
        let label = LMPaddedLabel()
        label.paddingLeft = 0
        label.paddingRight = 4
        label.paddingTop = 10
        label.paddingBottom = 10
        label.textColor = ColorConstant.likeTextColor
        label.font = LMBranding.shared.font(12, .regular)
        label.text = "Reply"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let replyCountLabel: LMLabel = {
        let label = LMPaddedLabel()
        label.paddingLeft = 0
        label.paddingRight = 0
        label.paddingTop = 10
        label.paddingBottom = 10
        label.textColor = LMBranding.shared.buttonColor
        label.font = LMBranding.shared.font(12, .regular)
        label.text = ""
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var replyAndTimeSpaceView: UIView = {
        let uiView = UIView()
        uiView.translatesAutoresizingMaskIntoConstraints = false
        return uiView
    }()
    
    let timeLabel: LMLabel = {
        let label = LMLabel()
        label.textColor = ColorConstant.likeTextColor
        label.font = LMBranding.shared.font(12, .regular)
        label.text = ""
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    weak var comment: PostDetailDataModel.Comment?
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        commonInit()
        setupActions()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
        setupActions()
    }
    
    func commonInit() -> Void {
        contentView.backgroundColor = .white
        contentView.addSubview(commentHeaderStackView)
        usernameAndCaptionStackView.addArrangedSubview(usernameAndBadgeStackView)
        usernameAndBadgeStackView.addArrangedSubview(usernameLabel)
        usernameAndBadgeStackView.addArrangedSubview(badgeImageView)
        usernameAndBadgeStackView.addArrangedSubview(badgeSpaceView)
        badgeSpaceView.widthAnchor.constraint(greaterThanOrEqualToConstant: 5).isActive = true
        commentAndMoreStackView.addArrangedSubview(commentLabel)
        commentAndMoreStackView.addArrangedSubview(spaceView)
        spaceView.widthAnchor.constraint(greaterThanOrEqualToConstant: 10).isActive = true
        commentAndMoreStackView.addArrangedSubview(moreImageView)
        usernameAndCaptionStackView.addArrangedSubview(commentAndMoreStackView)
        commentHeaderStackView.addArrangedSubview(usernameAndCaptionStackView)
        likeStackView.addArrangedSubview(likeImageView)
        likeStackView.addArrangedSubview(likeCountLabel)
        likeAndReplyStackView.addArrangedSubview(likeStackView)
        likeAndReplyStackView.addArrangedSubview(deviderLabel)
        replyStackView.addArrangedSubview(replyLabel)
        replyStackView.addArrangedSubview(replyCountLabel)
        likeAndReplyStackView.addArrangedSubview(replyStackView)
        likeAndReplyStackView.addArrangedSubview(replyAndTimeSpaceView)
        replyAndTimeSpaceView.widthAnchor.constraint(greaterThanOrEqualToConstant: 5).isActive = true
        likeAndReplyStackView.addArrangedSubview(timeLabel)
        commentHeaderStackView.addArrangedSubview(likeAndReplyStackView)
        let g = contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            commentHeaderStackView.topAnchor.constraint(equalTo: g.topAnchor),
            commentHeaderStackView.leadingAnchor.constraint(equalTo: g.leadingAnchor),
            commentHeaderStackView.trailingAnchor.constraint(equalTo: g.trailingAnchor),
            commentHeaderStackView.bottomAnchor.constraint(equalTo: g.bottomAnchor)
        ])
        
        likeImageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        likeImageView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        moreImageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        moreImageView.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
    
    private func setupActions() {
        let likeCountsTapGesture = LMTapGesture(target: self, action: #selector(self.likeCountsTapped(sender:)))
        let likeTapGesture = LMTapGesture(target: self, action: #selector(self.likeTapped(sender:)))
        let replyTapGesture = LMTapGesture(target: self, action: #selector(self.replyTapped(sender:)))
        let replyCountTapGesture = LMTapGesture(target: self, action: #selector(self.replyCountTapped(sender:)))
        let moreActionTapGesture = LMTapGesture(target: self, action: #selector(self.moreTapped(sender:)))
        moreImageView.isUserInteractionEnabled = true
        moreImageView.addGestureRecognizer(moreActionTapGesture)
        likeImageView.isUserInteractionEnabled = true
        likeImageView.addGestureRecognizer(likeTapGesture)
        likeCountLabel.isUserInteractionEnabled = true
        likeCountLabel.addGestureRecognizer(likeCountsTapGesture)
        replyCountLabel.isUserInteractionEnabled = true
        replyCountLabel.addGestureRecognizer(replyCountTapGesture)
        replyLabel.isUserInteractionEnabled = true
        replyLabel.addGestureRecognizer(replyTapGesture)
    }
    
    func setupDataView(comment: PostDetailDataModel.Comment) {
        self.comment = comment
        self.usernameLabel.text = comment.user.name
        self.commentLabel.attributedText = TaggedRouteParser.shared.getTaggedParsedAttributedString(with: comment.text ?? "", forTextView: false, withFont: LMBranding.shared.font(14, .regular))
        self.likeCountLabel.text = comment.likeCounts()
        self.replyCountLabel.text = comment.repliesCounts()
        let postTime = Date(timeIntervalSince1970: TimeInterval(comment.createdAt)).timeAgoDisplayShort()
        let postTimeWithEdited = comment.isEdited ? "Edited \(SpecialCharString.centerDot) \(postTime)" : postTime
        self.timeLabel.text = postTimeWithEdited
        likeDataView()
    }
    
    @objc private func likeTapped(sender: LMTapGesture) {
        guard let commentId = self.comment?.commentId,
        !commentId.isEmpty else { return }
        let isLike = !(self.comment?.isLiked ?? false)
        self.comment?.isLiked = isLike
        self.comment?.likedCount += isLike ? 1 : -1
        delegate?.didTapActionButton(withActionType: .like, section: self.section)
        likeDataView()
    }
    
    func likeDataView() {
        likeCountLabel.text = self.comment?.likeCounts()
        if comment?.isLiked ?? true {
            likeImageView.image = UIImage(systemName: ImageIcon.likeFillIcon)
            likeImageView.tintColor = .red
        } else {
            likeImageView.image = UIImage(systemName: ImageIcon.likeIcon)
            likeImageView.tintColor = .darkGray
        }
    }
    
    @objc private func replyTapped(sender: LMTapGesture) {
        delegate?.didTapActionButton(withActionType: .comment, section: self.section)
    }
    
    @objc private func replyCountTapped(sender: LMTapGesture) {
        delegate?.didTapActionButton(withActionType: .commentCount, section: self.section)
    }
    
    @objc private func likeCountsTapped(sender: LMTapGesture) {
        delegate?.didTapActionButton(withActionType: .likeCount, section: self.section)
    }
    
    @objc private func moreTapped(sender: LMTapGesture) {
        delegate?.didTapActionButton(withActionType: .more, section: self.section)
    }
}
