//
//  PastRunsViewController.swift
//  MoonRunner
//
//  Created by Santo Chen on 11/22/15.
//  Copyright © 2015 Zedenem. All rights reserved.
//

import UIKit
import CoreData

class PastRunsViewController: UIViewController, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    var run = [NSManagedObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Past Runs"
        tableView.registerClass(UITableViewCell.self,
            forCellReuseIdentifier: "runData")
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //1
        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let fetchRequest = NSFetchRequest(entityName: "Run")
        
        //3
        do {
            let results = try managedContext!.executeFetchRequest(fetchRequest)
            run = results as! [NSManagedObject]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    func timeFormatter(totalSeconds: Int)->String {
        let seconds = totalSeconds % 60
        let minutes = (totalSeconds / 60) % 60
        return String.localizedStringWithFormat("%02dmins%02dsecs", minutes, seconds)
    }
    
    func tableView(tableView: UITableView,
        numberOfRowsInSection section: Int) -> Int {
            return run.count
    }
    
    func tableView(tableView: UITableView,
        cellForRowAtIndexPath
        indexPath: NSIndexPath) -> UITableViewCell {
            
            let cell = tableView.dequeueReusableCellWithIdentifier("runData")
            cell?.textLabel?.font = UIFont(name:"MarioLuigiTwo", size:22)
            let oneRun = run[indexPath.row]
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .ShortStyle
            // dateLabel.text = dateFormatter.stringFromDate(run.timestamp)
            var displayText = String.localizedStringWithFormat("%d%@", (oneRun.valueForKey("coins") as? Int)!, "/15 in ")
            displayText += timeFormatter((oneRun.valueForKey("duration") as? Int)!)
            displayText += " on " + dateFormatter.stringFromDate((oneRun.valueForKey("timestamp") as? NSDate)!)
            
            cell!.textLabel!.text = displayText
            return cell!
    }

}
