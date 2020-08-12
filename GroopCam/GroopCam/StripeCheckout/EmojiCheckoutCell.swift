

import UIKit

class EmojiCheckoutCell: UITableViewCell {
    let detailLabel: UILabel
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        detailLabel = UILabel()
        detailLabel.font = UIFont.systemFont(ofSize: 13)
        detailLabel.textColor = .stripeDarkBlue

        super.init(style: style, reuseIdentifier: reuseIdentifier)
        installConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func installConstraints() {
       
        NSLayoutConstraint.activate([
           detailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
           detailLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            ])
    }
    
    public func configure(with product: QuantityObject, numberFormatter: NumberFormatter) {
        detailLabel.text = product.printableObject.post.id
        detailLabel.text = "A post from" + product.printableObject.post.groupName
        
    }
}
