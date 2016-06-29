//
//  FilterViewController.swift
//  bikeshare
//
//  Created by houlianglv on 5/11/16.
//  Copyright © 2016 team O. All rights reserved.
//

import UIKit

class FilterViewController: UIViewController {

    //outlets
    @IBOutlet weak var fromDatePicker: UIDatePicker!
    @IBOutlet weak var toDatePicker: UIDatePicker!
    @IBOutlet weak var fromDateLabel: UILabel!
    @IBOutlet weak var toDateLabel: UILabel!

    var fromDate:NSDate = NSDate()
    var toDate:NSDate = NSDate().dateByAddingTimeInterval(21600)

    var onDataAvailable : ((data: String) -> ())?

    //send data back to main view
    func sendData(data: String) {
        self.onDataAvailable?(data: data)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(animated: Bool) {
        self.fromDateLabel.text = self.processDateToString(fromDate)
        self.fromDatePicker.date = fromDate
        self.toDateLabel.text = self.processDateToString(toDate)
        self.toDatePicker.date = toDate
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    //actions
    @IBAction func onCancelTapped(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func onConfirmTapped(sender: UIButton) {
        //build the parameter and send to the main view
        self.sendData(fromDateLabel.text! + "*" + toDateLabel.text!)
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func onFromDateValueChanged(sender: UIDatePicker) {
        if fromDatePicker.date.compare(toDatePicker.date) == NSComparisonResult.OrderedDescending {
            showAlert()
            fromDatePicker.date = fromDate
            return
        }
        self.fromDate = fromDatePicker.date
        self.fromDateLabel.text = self.processDateToString(self.fromDate)
    }

    @IBAction func onToDateValueChanged(sender: UIDatePicker) {
        if fromDatePicker.date.compare(toDatePicker.date) == NSComparisonResult.OrderedDescending {
            showAlert()
            toDatePicker.date = toDate
            return
        }
        self.toDate = toDatePicker.date
        self.toDateLabel.text = self.processDateToString(self.toDate)
    }

    func showAlert(){
        //Create the AlertController
        let actionSheetController: UIAlertController = UIAlertController(title: "Alert", message: "End Date cannot be earlier than From Date", preferredStyle: .Alert)
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "OK", style: .Cancel) { action -> Void in }
        actionSheetController.addAction(cancelAction)
        //Present the AlertController
        self.presentViewController(actionSheetController, animated: true, completion: nil)
    }

    private func processDateToString(date: NSDate) -> String{
        let RFC3339DateFormatter = NSDateFormatter()
        RFC3339DateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        RFC3339DateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: -14400)

        return RFC3339DateFormatter.stringFromDate(date)
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
