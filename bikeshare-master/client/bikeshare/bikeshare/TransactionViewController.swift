//
//  TransactionViewController.swift
//  bikeshare
//
//  Created by houlianglv on 5/12/16.
//  Copyright © 2016 team O. All rights reserved.
//

import UIKit

class TransactionViewController: UIViewController {

    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var ownerLabel: UILabel!

    var transction: AnyObject?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.modelLabel.text = self.transction!["bike"]!!["model"] as? String
        self.ownerLabel.text = self.transction!["bike"]!!["owner"]!!["username"] as? String
        self.userLabel.text = self.transction!["user"]!!["username"] as? String
        self.fromLabel.text = self.transction!["from_date"]!! as? String
        self.toLabel.text = self.transction!["to_date"]!! as? String
        self.statusLabel.text = self.transction!["status"] as? String
        self.priceLabel.text = String(self.transction!["unitprice"]!! as! Double)

    }
    
    @IBAction func onCompleteTapped(sender: AnyObject) {
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
