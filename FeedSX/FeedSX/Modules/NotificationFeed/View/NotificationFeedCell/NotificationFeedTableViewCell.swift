//
//  NotificationFeedTableViewCell.swift
//  LMFeedUI
//
//  Created by Pushpendra Singh on 22/05/23.
//

import UIKit

protocol NotificationFeedTableViewCellDelegate: AnyObject {
    func menuButtonClicked(_ cell: UITableViewCell)
}

class NotificationFeedTableViewCell: UITableViewCell {
    
    static let nibName: String = "NotificationFeedTableViewCell"
    static let bundle = Bundle(for: NotificationFeedTableViewCell.self)
    weak var delegate: NotificationFeedTableViewCellDelegate?
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var docIconImageView: UIImageView!
    @IBOutlet weak var notificationDetailLabel: LMLabel!
    @IBOutlet weak var timeLabel: LMLabel!
    @IBOutlet weak var moreMenuButton: LMButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        self.moreMenuButton.addTarget(self, action: #selector(didMenuButtonClicked), for: .touchUpInside)
        self.moreMenuButton.isHidden = true
        self.profileImageView.makeCircleView()
        self.docIconImageView.superview?.makeCircleView()
        self.docIconImageView.superview?.backgroundColor = LMBranding.shared.buttonColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setupNotificationFeedCell(dataView: NotificationFeedDataView) {
        self.notificationDetailLabel.attributedText = TaggedRouteParser.shared.getTaggedParsedAttributedString(with: dataView.activity.activityText, andPrefix: "", forTextView: false, withTextColor: ColorConstant.likeTextColor, withHilightFont: LMBranding.shared.font(16, .medium), withHighlightedColor: ColorConstant.textBlackColor, isShowLink: false)
        
        self.contentView.backgroundColor =  (dataView.isRead) ? .white : ColorConstant.notificationFeedColor
        timeLabel.text = Date(milliseconds: Double(dataView.activity.updatedAt ?? 0)).timeAgoDisplay()
        setTypeOfPostActivity(dataView: dataView)
        let profilePlaceHolder = UIImage.generateLetterImage(with: dataView.user?.name ?? "") ?? UIImage()
        guard let url = dataView.user?.imageUrl?.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) else {
            profileImageView.image = profilePlaceHolder
            return
        }
        profileImageView.kf.setImage(with: URL(string: url), placeholder: profilePlaceHolder)
    }
    
    func setTypeOfPostActivity(dataView: NotificationFeedDataView) {
        if let attachment = dataView.activity.activityEntityData?.attachments?.first {
            docIconImageView.superview?.isHidden = false
            var attachmentTypePlaceHolder = ""
            if (attachment.attachmentType == .image) { attachmentTypePlaceHolder = ImageIcon.photoIcon }
            if (attachment.attachmentType == .video) { attachmentTypePlaceHolder = ImageIcon.video }
            if (attachment.attachmentType == .doc) { attachmentTypePlaceHolder = ImageIcon.docIcon }
            if (attachment.attachmentType == .link) { attachmentTypePlaceHolder = ImageIcon.linkIcon }
            docIconImageView.image = UIImage(systemName: attachmentTypePlaceHolder)
        } else {
            docIconImageView.superview?.isHidden = true
        }
    }
    
    @objc func didMenuButtonClicked() {
        print("Menu button clicked")
        self.delegate?.menuButtonClicked(self)
    }
    
}
