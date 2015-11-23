//
//  ScoreboardViewController.swift
//  MoonRunner
//
//  Created by Rebecca Hubeny on 11/22/15.
//  Copyright © 2015 Zedenem. All rights reserved.
//

import UIKit
import Foundation

class ScoreBoardViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var scoreTable: UITableView!
    var DBscores = ["","","","","","","","","",""]
    let noteKey = "notificationKey"
    
    func timeFormatter(totalSeconds: Int)->String {
        let seconds = totalSeconds % 60
        let minutes = (totalSeconds / 60) % 60
        return String.localizedStringWithFormat("%02dmins%02dsecs", minutes, seconds)
    }
    
    func parseJSON(message: String) {
        let messageArray = message.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "[]"))
        if (messageArray.count > 1){
            var scores = messageArray[1].componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: ","))
            for i in 0..<scores.count{
                scores[i] = scores[i].stringByReplacingOccurrencesOfString("{\"score\":\"", withString: "")
                scores[i] = scores[i].stringByReplacingOccurrencesOfString("\"}", withString: "")
            }
            for i in 0..<scores.count{
                self.DBscores[i] = scores[i]
            }
        }
    }
    
    func requestScores() {
        //let url = "http://www.ucmario.eu.pn"
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "http://www.ucmario.eu.pn")!) {(data, response, error) in
            if(error != nil){
                
            } else {
                let message = NSString(data: data!, encoding: NSUTF8StringEncoding)
                var JSONinfo = [NSObject:AnyObject]()
                JSONinfo["message"] = message
                
                NSNotificationCenter.defaultCenter().postNotificationName(self.noteKey, object: self, userInfo: JSONinfo)
            }
        }
        
        task!.resume()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Top 10 Runs"
        
        scoreTable.dataSource = self
        scoreTable.delegate = self
        scoreTable.separatorStyle = UITableViewCellSeparatorStyle.None
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "handleJSON:",
            name: noteKey,
            object: nil)
        
        requestScores()
    }
    
    func handleJSON(notification: NSNotification){
        let JSONinfo : [NSObject : AnyObject] = notification.userInfo!
        
        let message = JSONinfo["message"] as! String!
        
        parseJSON(message)
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            dispatch_async(dispatch_get_main_queue()) {
                // update UI
                self.scoreTable.reloadData()
            }
        }
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) ->   UITableViewCell {
        let cell = UITableViewCell()
        let label = UILabel(frame: CGRect(x:0, y:0, width:200, height:25))
        
        let score = DBscores[indexPath.row]
        
        if (score == ""){
            label.text = score
        } else {
            label.text = timeFormatter(Int(score)!)
        }
        label.textColor = UIColor.blackColor()
        cell.addSubview(label)
        cell.backgroundColor = UIColor.whiteColor()
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return scoreTable.frame.size.height / 10;
    }
    
}