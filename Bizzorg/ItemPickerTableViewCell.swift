//
//  ItemPickerTableViewCell.swift
//  Bizzorg
//
//  Created by Jordan Field on 24/09/2016.
//  Copyright © 2016 Jordan Field. All rights reserved.
//

import UIKit

/**
 Class used by the to-do and schedule modify views to pick between a list of
 options.
 
 UI links
 ========
 pickerView
 
 Properties
 ==========
 updateDelegate - Like the date picker cell, the class calls functions on this
 object once the user has selected an item.
 options - A list of possible items the user can select. the Titleizable
 protocol ensures that a suitable name comes up in the picker view.
 selectedOption - The item that the picker view currently has as selected.
 */
class ItemPickerTableViewCell: UITableViewCell,
  UIPickerViewDataSource,
  UIPickerViewDelegate {
  
  @IBOutlet weak var pickerView: UIPickerView!
  var updateDelegate: ItemPickerTableViewCellDelegate?
  var options: [Titleizable] = [] {
    //If the user changes the options of the picker view, reload the sections
    //so that the new options are displayed.
    didSet {
      executeUiChange {
        self.pickerView.reloadAllComponents()
      }
    }
  }
  var selectedOption: Titleizable?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    //As the date picker view cell, set the picker view data source and delegate
    //to this class.
    pickerView.dataSource = self
    pickerView.delegate = self
  }
  
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }
  
  //The number of rows of the picker view will be the same as the length of the
  //options list.
  func pickerView(_ pickerView: UIPickerView,
                  numberOfRowsInComponent component: Int) -> Int {
    return options.count
  }
  
  //Set the title of each option of the table view. This is where the
  //Titleizable protocol comes in, as the protocol ensures the type supplied
  //will always have a title property, regardless of the actual type of the
  //object.
  func pickerView(_ pickerView: UIPickerView,
                  titleForRow row: Int, forComponent component: Int) -> String? {
    return options[row].title
  }
  
  //Use this function to move the selected option into the selectedOption
  //variable and initialise the update delegate to make the nessecary changes.
  func pickerView(_ pickerView: UIPickerView,
                  didSelectRow row: Int, inComponent component: Int) {
    selectedOption = options[row]
    updateDelegate?.pickerViewDidSelect(self)
  }
}
