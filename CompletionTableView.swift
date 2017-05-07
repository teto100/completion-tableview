//
//  CompletionTableView..swift
//  
//
//  Created by Antonio Mendoza Ochoa on 7/05/17.
//  Copyright © 2017 . All rights reserved.
//

import Foundation
import UIKit

class CompletionTableView : UITableView, UITableViewDelegate, UITableViewDataSource{
    var relatedTextField : UITextField?
    var searchInArray : [String]!
    var tableCellIdentifier : String?
    var inView : UIView!
    
    var maxResultsToShow : Int = 5
    var maxSelectedElements : Int = 1
    var showSelected : Bool = false
    var resultsArray : [String] = []
    var selectedElements : [String] = []
    var completionsRegex : [String] = ["^#@"]
    var completionCellForRowAtIndexPath : ((_ tableView: CompletionTableView?, _ indexPath: IndexPath?) -> UITableViewCell?)? = nil
    var completionDidSelectRowAtIndexPath : ((_ tableView: CompletionTableView?, _ indexPath: IndexPath?) -> Void)? = nil
    
    init(relatedTextField: UITextField, inView: UIView, searchInArray: [String], tableCellNibName: String?, tableCellIdentifier: String?){
        self.relatedTextField = relatedTextField
        self.searchInArray = searchInArray
        self.tableCellIdentifier = tableCellIdentifier
        self.inView = inView
        let customFrame = CGRect(x: self.relatedTextField!.frame.origin.x, y: self.relatedTextField!.frame.origin.y + self.relatedTextField!.frame.height, width: self.relatedTextField!.frame.width, height: 0)
        super.init(frame: customFrame, style: UITableViewStyle.plain)
        self.rowHeight = 44.0
        
        if tableCellNibName != nil {
            self.register(UINib(nibName: tableCellNibName!, bundle: nil), forCellReuseIdentifier: tableCellIdentifier!)
            if self.tableCellIdentifier == nil {
                fatalError("Identifier must be set when nib name is not nil")
            }
            let tmpCell: UITableViewCell? = self.dequeueReusableCell(withIdentifier: self.tableCellIdentifier!)
            if (tmpCell) == nil {
                fatalError("No such object exists in the reusable-cell queue")
            }
            self.rowHeight = tmpCell!.frame.height
        }
        
        self.separatorStyle = UITableViewCellSeparatorStyle.none
        self.layer.cornerRadius = 5.0
        self.delegate = self
        self.dataSource = self
        self.bounces = false
        self.inView.addSubview(self)
        self.relatedTextField!.addTarget(self, action: #selector(self.onRelatedTextFieldEditingChanged), for: .editingChanged)
        self.relatedTextField!.addTarget(self, action: #selector(self.onRelatedTextFieldEndEditing), for: .editingDidEnd)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    func onRelatedTextFieldEditingChanged(sender: UITextField){
        self.tryCompletion(withValue: sender.text!, animated: true)
    }
    
    func onRelatedTextFieldEndEditing(sender: UITextField){
        self.hide(animated: true)
        self.relatedTextField!.text = ""
    }
    
    func tryCompletion(withValue: String, animated: Bool){
        if withValue.isEmpty {
            self.hide(animated: true)
            return
        }
        
        self.resultsArray.removeAll(keepingCapacity: false)
        var maxResultsReached = false
        for regexString in self.completionsRegex {
            let pattern = regexString.replacingOccurrences(of: "#@", with: withValue)
            let regex = try! NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            for entry in self.searchInArray {
                if self.resultsArray.count >= self.maxResultsToShow && self.maxResultsToShow != 0 {
                    maxResultsReached = true
                    break
                }
                let matches = regex.matches(in: entry, range: NSRange(location: 0, length: entry.characters.count))
                if matches.count > 0 && !self.resultsArray.contains(entry) && (self.showSelected ? true : !self.resultsArray.contains(entry) ){
                    self.resultsArray.append(entry)
                }
            }
            
            if maxResultsReached {
                break
            }
        }
        
        self.reloadData()
        self.inView.bringSubview(toFront: self)
        self.show(animated: animated)
    }
    
    func selectElement(element: String, maxSelectedElementsReached: (() -> Void)?) -> Bool{
        let tmpArray = NSArray(array: self.selectedElements)
        if tmpArray.index(of: element) != NSNotFound {
            return true
        }
        if self.selectedElements.count >= self.maxSelectedElements && self.maxSelectedElements != 0 {
            if maxSelectedElementsReached != nil {
                maxSelectedElementsReached!()
            }
            return false
        }
        self.selectedElements.append(element)
        return true
    }
    
    func elementIsSelected(element: String) -> Bool{
        return self.selectedElements.contains(element)
    }
    
    func deselectElement(element: String){
        let tmpArray = NSArray(array: self.selectedElements)
        let indexToRemove = tmpArray.index(of: element)
        if indexToRemove == NSNotFound {
            return
        }
        self.selectedElements.remove(at: indexToRemove)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return self.resultsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.completionCellForRowAtIndexPath == nil {
            let cell : UITableViewCell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "Identifier")
            
            cell.textLabel!.text = self.resultsArray[indexPath.row] as String
            return cell
        }
        return self.completionCellForRowAtIndexPath!(tableView as? CompletionTableView, indexPath)!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.completionDidSelectRowAtIndexPath != nil {
            self.completionDidSelectRowAtIndexPath!(tableView as? CompletionTableView, indexPath)
        }

        //CUSTOM TABLE CELL MY CASE EmpresasCell
        let cell = tableView.cellForRow(at: indexPath) as! EmpresasCell
        self.relatedTextField?.text = cell.lblNombreEmpresa.text
        self.hide(animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func show(animated: Bool){
        var newRect = self.frame
        newRect.size.height = self.rowHeight * CGFloat(self.resultsArray.count)
        
        if !animated {
            self.frame = newRect
            return
        }
        
        UIView.animate(withDuration: 0.25, animations: {() -> Void in
            self.frame = newRect
        })
    }
    
    func hide(animated: Bool){
        let originRect = CGRect(x: self.relatedTextField!.frame.origin.x, y: self.relatedTextField!.frame.origin.y + self.relatedTextField!.frame.height, width: self.relatedTextField!.frame.width, height: self.frame.height)
        let finalRect = CGRect(x: originRect.origin.x, y: originRect.origin.y, width: originRect.width, height: 0)
        
        if !animated {
            self.frame = finalRect
            return
        }
        
        UIView.animate(withDuration: 0.25, animations: {() -> Void in
            self.frame = finalRect
        })
    }
}
